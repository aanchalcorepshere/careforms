import { LightningElement, track, api, wire } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getObjectFieldNames from '@salesforce/apex/PlanTemplateUtil.getObjectFieldNames';

const OPTION_FIELD = 'caresp__Plan__c';
const SAVE_REC_OBJECT_NAME = 'caresp__Plan_Template_Field_Blueprint__c';

export default class createPlanTempFieldBlueprint extends LightningElement {
    @track availableOptions = [];
    @track sectionName;
    @track selectedOptions = [];
    @api recordId;
    @api objectApiName;
    existingSectionsList = [];
    isSaveDisabled = true;
    optionLoaded = true;
    isLoading = false;
    @track recordFields = {
        caresp__Section_Name__c: '',
        caresp__Plan_Field_List__c: '',
        caresp__Plan_Template__c: '',
        caresp__isActive__c: false

        // Add more fields as necessary
    };


    constructor() {
        super();
    }

    connectedCallback() {
        console.log('obj Rec Id : ' + this.recordId);
        this.availableOptions = [];
        this.selectedOptions = [];
        this.getObjectFieldNames();

    }


    getObjectFieldNames() {
        getObjectFieldNames({ objName: OPTION_FIELD, parentRecId: this.recordId, dummyParam: Date.now() })
            .then(data => {
                this.availableOptions = data.listFieldName.map(item => ({
                    label: item.label + ' (' + item.value + ')',
                    value: item.value,
                    dataType: item.dataType,
                    isMandatory: item.isMandatory,
                    isEditable : item.isEditable,
                    isFormulaField : item.isFormulaField,
                    defaultValue: item.defaultValue,
                    isEditDisabled : item.isEditDisabled,
                    isReqDisabled: item.isReqDisabled
                }));
                this.existingSectionsList = data.setExistingSections;
                this.optionLoaded = true;
            })
            .catch(error => {
                console.error('Error occur in server call -->>getObjectFieldNames<<--' + JSON.stringify(this.getErrorMessage(error)));
            });
    }


    handleChange(event) {
        if (event.target.name === 'sectionName' && event.target.value != '') {
            this.recordFields.caresp__Section_Name__c = event.target.value;
            this.isSaveDisabled = false;

        }
        else {
            this.isSaveDisabled = true;

        }


    }


    handleSave(event) {
        try {
            this.isLoading = true;
            const multiSelectPicklist = this.template.querySelector('c-custom-multiselect-picklist');
            this.selectedOptions = multiSelectPicklist.getSelectedOptions();
            console.log('Selected Options while saving:', JSON.stringify(this.selectedOptions));
            const fields = { ...this.recordFields };
            fields.caresp__Plan_Field_List__c = JSON.stringify(this.selectedOptions);
            //this.getCommaSeparatedValues(this.selectedOptions);
            fields.caresp__isActive__c = true;
            fields.caresp__Plan_Template__c = this.recordId;
            if (!this.existingSectionsList.includes(fields.caresp__Section_Name__c)) {
                const recordInput = { apiName: SAVE_REC_OBJECT_NAME, fields };
                this.createFieldBluePrintRec(recordInput);
            }
            else {
                this.fireToastEvent('Error!', 'Record with this section name is already existing', 'error');
                this.isLoading = false;

            }


        }
        catch (error) {
            console.error('Error occured while saving record :' + JSON.stringify(this.getErrorMessage(error)));
        }
    }


    getCommaSeparatedValues(optionsArray) {
        try {
            const values = optionsArray.map(option => option.value);
            const commaSeparatedValues = values.join(',');
            return commaSeparatedValues;
        } catch (error) {
            console.error('Error parsing JSON string: ', JSON.stringify(this.getErrorMessage(error)));
            return '';
        }
    }



    createFieldBluePrintRec(recordInput) {
        createRecord(recordInput)
            .then(result => {
                const recordFieldsCopy = { ...this.recordFields };
                if (recordFieldsCopy && recordFieldsCopy.caresp__Section_Name__c) {
                    this.existingSectionsList = [...this.existingSectionsList, recordFieldsCopy.caresp__Section_Name__c];
                } else {
                    console.warn('caresp__Section_Name__c is undefined in recordFields');
                }
                this.fireToastEvent('Success', 'Record created successfully', 'success');
                this.isLoading = false;
                this.resetForm();
            })
            .catch(error => {
                console.log('Error Occurred in createFieldBluePrintRec : ' + JSON.stringify(this.getErrorMessage(error)));
                this.fireToastEvent('Error creating record', this.getErrorMessage(error), 'error');

            });
    }

    resetForm() {
        this.recordFields.caresp__Section_Name__c = '';
        this.recordFields.caresp__Plan_Field_List__c = '';
        this.recordFields.caresp__isActive__c = false;
        this.isSaveDisabled = true;
        this.availableOptions = this.availableOptions.filter(option => {
            return !this.selectedOptions.some(selectedOption => selectedOption.value === option.value);
        });
        this.selectedOptions = [];


    }

    fireToastEvent(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }


    handleCancel(event) {
        try {
            const closeLwc = new CustomEvent('close');
            this.dispatchEvent(closeLwc);
            window.location.reload()
        } catch (error) {
            console.error('Error in handleCancel:', this.getErrorMessage(error));
            // Optional: Handle the error or display a user-friendly message
        }
    }

    getErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        }
        if (error.message) {
            return error.message;
        }
        return 'An unknown error occurred';
    }
}