import { LightningElement, api, wire, track } from 'lwc';
import getCompatibleFieldsBoolPick from '@salesforce/apex/AssessmentWizardController.getCompatibleFieldsBoolPick';
import getFieldTypeAndValues from '@salesforce/apex/AssessmentWizardController.getFieldTypeAndValues';

export default class AssessmentWizardOnCompletionFieldUpdate extends LightningElement {
    @api objectName;
    @api isSubmit;
    @track fieldList;
    selectedField;
    fieldType;
    fieldValueList;
    @track fieldData={};
    isPicklist = false;
    isBoolean = false;
    selectedValue;
    error;
    @api existingFieldUpdate;
    

    get options() {
        return [
            { label: 'True', value: 'true' },
            { label: 'False', value: 'false' },
        ];
    }

    connectedCallback(){
        
        if(this.existingFieldUpdate && this.existingFieldUpdate.objectName==this.objectName){
            this.fieldData = JSON.parse(JSON.stringify(this.existingFieldUpdate));
        }else{
            let objList = [];
            objList.push(this.objectName);
            this.fieldData.objectName = this.objectName;
            getCompatibleFieldsBoolPick({objNames : objList})
            .then(result =>{
                let tempData = result;
                tempData.sort(function (a, b) {
                    return a.label.localeCompare(b.label);
                });

                tempData.forEach(data => {
                    var labelPos = data.label.indexOf('(');
                    data.label = data.label.substring(0, labelPos != -1 ? labelPos : data.label.length);
                })
                this.fieldData.fieldList = tempData;
            })
            .catch(error =>{
                this.error = error;
            })
        }
    }

    /* get isLoading() {
        return (!this.fieldList || this.existingFieldUpdate);
    } */

    handleChange(event){
        let targetname = event.target.name;
        if(targetname == 'fieldname'){
            this.fieldData.selectedField = event.target.value;
            if(this.fieldData.selectedField){
                getFieldTypeAndValues({fieldValue : this.fieldData.selectedField})
                .then(result => {
                    let dataFromApex = result;
                    this.fieldData.fieldType = dataFromApex.fieldType;
                    this.fieldData.fieldValueList = dataFromApex.fieldValueList;
                    if(this.fieldData.fieldType === 'PICKLIST'){
                        this.fieldData.isPicklist = true;
                        this.fieldData.isBoolean = false;
                    }else if(this.fieldData.fieldType === 'BOOLEAN'){
                        this.fieldData.isBoolean = true;
                        this.fieldData.isPicklist = false;
                    }
                    this.fieldData.selectedValue = undefined;
                })
                .catch(error => {
                    console.error("ERROR >> ",JSON.stringify(error));
                })
            }
        }else if(targetname == 'fieldvalue'){
            this.fieldData.selectedValue = event.target.value;
        }else if(targetname == 'radio'){
            this.fieldData.selectedValue = event.target.checked;
        }
        this.dispatchEvent(new CustomEvent('completionfieldupdate', {
            detail: this.fieldData
        }));
    }
}