import { LightningElement, track, api } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getStepObjectFieldNames from '@salesforce/apex/PlanTemplateUtil.getStepObjectFieldNames';

const STEP_OBJECT_API_NAME = 'caresp__Step__c';
const BLUEPRINT_OBJECT_API_NAME = 'caresp__Step_Template_Field_Blueprint__c';
const PREDEFINED_STEP_BLUEPRINT_FIELDS = [
    {
        value: 'caresp__Description__c',
        label: 'Step Description',
        dataType: 'TEXTAREA'
    },
    {
        value: 'caresp__Status__c',
        label: 'Status',
        dataType: 'PICKLIST'
    }
];

export default class CreateStepTempFieldBlueprint extends LightningElement {

    /**
     * @description The Salesforce Record ID of the Step_Template__c record being configured.
     * @type {string}
     */
    @api recordId;

    /**
     * @description The API name of the object this component is placed on (Step_Template__c).
     * @type {string}
     */
    @api objectApiName;

    @track availableOptions = [];
    @track selectedOptions = [];

    existingSectionsList = [];
    isSaveDisabled = true;
    optionLoaded = false;
    isLoading = false;

    @track recordFields = {
        caresp__Section_Name__c: '',
        caresp__Step_Field_List__c: '',
        caresp__Step_Template__c: '',
        caresp__isActive__c: false
    };

    /** Screen record actions set @api recordId after the first paint; connectedCallback runs too early. */
    _stepFieldNamesLoadStarted = false;

    connectedCallback() {
        this.availableOptions = [];
        this.selectedOptions = [];
    }

    renderedCallback() {
        if (this.recordId && !this._stepFieldNamesLoadStarted) {
            this._stepFieldNamesLoadStarted = true;
            this.loadStepFieldNames();
        }
    }

    loadStepFieldNames() {
        this.isLoading = true;
        getStepObjectFieldNames({
            objName: STEP_OBJECT_API_NAME,
            parentRecId: this.recordId,
            dummyParam: String(Date.now())
        })
            .then(data => {
                const mappedOptions = data.listFieldName.map(item => ({
                    label: item.label + ' (' + item.value + ')',
                    value: item.value,
                    dataType: item.dataType,
                    isMandatory: item.isMandatory,
                    isEditable: item.isEditable,
                    isFormulaField: item.isFormulaField,
                    defaultValue: item.defaultValue,
                    isEditDisabled: item.isEditDisabled,
                    isReqDisabled: item.isReqDisabled,
                    isLocked: false
                }));
                this.selectedOptions = this.getMandatoryPredefinedFields(mappedOptions);
                this.availableOptions = mappedOptions.filter(
                    (opt) => !this.selectedOptions.some((sel) => sel.value === opt.value)
                );
                this.existingSectionsList = data.setExistingSections || [];
                this.optionLoaded = true;
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.fireToastEvent('Error', this.getErrorMessage(error), 'error');
            });
    }

    handleChange(event) {
        if (event.target.name === 'sectionName') {
            this.recordFields.caresp__Section_Name__c = event.target.value || '';
            this.isSaveDisabled = !(this.recordFields.caresp__Section_Name__c || '').trim();
        }
    }

    handleSave() {
        try {
            const trimmedSection = (this.recordFields.caresp__Section_Name__c || '').trim();
            if (!trimmedSection) {
                this.fireToastEvent('Error', 'Enter a section name before saving.', 'error');
                return;
            }
            this.isLoading = true;
            const multiSelectPicklist = this.template.querySelector('c-custom-multiselect-picklist');
            this.selectedOptions = this.ensurePredefinedFields(multiSelectPicklist.getSelectedOptions());

            const fields = { ...this.recordFields };
            fields.caresp__Section_Name__c = trimmedSection;
            fields.caresp__Step_Field_List__c = JSON.stringify(this.selectedOptions);
            fields.caresp__isActive__c = true;
            fields.caresp__Step_Template__c = this.recordId;

            if (this.existingSectionsList.includes(trimmedSection)) {
                this.fireToastEvent('Error', 'A blueprint with this section name already exists.', 'error');
                this.isLoading = false;
                return;
            }

            const recordInput = { apiName: BLUEPRINT_OBJECT_API_NAME, fields };
            createRecord(recordInput)
                .then(() => {
                    this.existingSectionsList = [...this.existingSectionsList, fields.caresp__Section_Name__c];
                    this.fireToastEvent('Success', 'Step Field Blueprint created successfully.', 'success');
                    this.isLoading = false;
                    this.resetForm();
                })
                .catch(error => {
                    this.fireToastEvent('Error', this.getErrorMessage(error), 'error');
                    this.isLoading = false;
                });
        } catch (error) {
            this.fireToastEvent('Error', this.getErrorMessage(error), 'error');
            this.isLoading = false;
        }
    }

    handleCancel() {
        try {
            this.dispatchEvent(new CustomEvent('close'));
            // eslint-disable-next-line no-restricted-globals
            location.reload();
        } catch (error) {
            this.fireToastEvent('Error', this.getErrorMessage(error), 'error');
        }
    }

    resetForm() {
        this.recordFields.caresp__Section_Name__c = '';
        this.recordFields.caresp__Step_Field_List__c = '';
        this.recordFields.caresp__isActive__c = false;
        this.isSaveDisabled = true;
        const preservedLocked = this.selectedOptions.filter((opt) => opt.isLocked);
        this.availableOptions = this.availableOptions.filter(opt =>
            !this.selectedOptions.some(sel => sel.value === opt.value)
        );
        this.selectedOptions = preservedLocked;
    }

    getMandatoryPredefinedFields(mappedOptions) {
        return PREDEFINED_STEP_BLUEPRINT_FIELDS.map((requiredField) => {
            const matchingOption = mappedOptions.find((opt) => opt.value === requiredField.value);
            const optionLabel = matchingOption ? matchingOption.label : `${requiredField.label} (${requiredField.value})`;
            const optionType = matchingOption ? matchingOption.dataType : requiredField.dataType;
            return {
                label: optionLabel,
                value: requiredField.value,
                dataType: optionType,
                isMandatory: true,
                isEditable: true,
                isFormulaField: false,
                defaultValue: null,
                isEditDisabled: false,
                isReqDisabled: true,
                isLocked: true
            };
        });
    }

    ensurePredefinedFields(selectedOptions) {
        const normalizedSelected = Array.isArray(selectedOptions) ? [...selectedOptions] : [];
        const existingValues = new Set(normalizedSelected.map((opt) => opt.value));
        this.selectedOptions
            .filter((opt) => opt.isLocked)
            .forEach((lockedOption) => {
                if (!existingValues.has(lockedOption.value)) {
                    normalizedSelected.push({ ...lockedOption });
                }
            });
        return normalizedSelected;
    }

    fireToastEvent(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    getErrorMessage(error) {
        if (error && error.body && error.body.message) return error.body.message;
        if (error && error.message) return error.message;
        return 'An unknown error occurred.';
    }
}