import { LightningElement, track, api } from 'lwc';

export default class CustomFormInputField extends LightningElement {
    @api field;
    @api sectionIndex;
    @api pageIndex;
    @api sectionIsMulti = false;
    @api recordIndex;
    @api isSummary = false;
    @api fieldErrors = {};
    objectNameForCopy;
    @api isPrefillFieldsForm;

    handleOnLoad() {
       if(!this.field.fieldData.hasOnLoadRun && (this.isPrefillFieldsForm)){
            let val;
            val = this.template.querySelector('.thecopyfield').value;
            if (this.field.fieldData.dataType === "BOOLEAN") {
                val =
                    val === true || val === "true" || val === "True"
                        ? "true"
                        : "false";
            }
            //console.log('val>>>> ',val);
            this.dispatchEvent(new CustomEvent('valueupdate',
            {
                bubbles: true, composed: true,detail: {
                    pageIndex:this.pageIndex,
                    sectionIndex:this.sectionIndex,
                    field : this.field,
                    value : val,
                    sectionIsMulti : this.sectionIsMulti,
                    recordIndex : this.recordIndex
                }
            }))
      }
    }

    /**
     * BOOLEAN: lightning-input-field expects boolean `value`; strings like "false" are truthy and show checked.
     */
    get inputValueForField() {
        if (!this.field || !this.field.fieldData) {
            return "";
        }
        const fd = this.field.fieldData;
        if (fd.dataType === "BOOLEAN") {
            return this.coerceBooleanModelToPrimitive(fd.inputValue, fd.defaultValue);
        }
        return fd.inputValue;
    }

    coerceBooleanModelToPrimitive(inputValue, defaultValue) {
        if (
            inputValue === "" ||
            inputValue === undefined ||
            inputValue === null
        ) {
            return defaultValue === "true";
        }
        if (typeof inputValue === "boolean") {
            return inputValue;
        }
        const s = String(inputValue).trim().toLowerCase();
        return s === "true" || s === "1";
    }

    get label(){
        return this.field.fieldData.customlabel == ""?this.field.fieldData.fieldName:this.field.fieldData.customlabel;
    }


    get isSummaryAndSignature(){
        if(this.field && this.field.fieldData && this.field.fieldData.fieldApi){
            return (this.isSummary && this.field.fieldData.fieldApi.toUpperCase().startsWith("SG_"));
        }
    }

    get objectName(){
        if(this.field.fieldData.objectName){
            if(this.field.fieldData.objectName.indexOf('|') !== -1){
                return this.field.fieldData.objectName.substring(0,this.field.fieldData.objectName.indexOf('|'));
            }else{
                return this.field.fieldData.objectName;
            }
        }
    }

    get fieldSequence(){
        return this.field.fieldIndex+1;
    }

    handleChange(event){
        let val =
            event.detail && event.detail.value !== undefined
                ? event.detail.value
                : event.target.value;
        if (this.field.fieldData.dataType === "BOOLEAN") {
            val =
                val === true || val === "true" || val === "True"
                    ? "true"
                    : "false";
        }

        this.dispatchEvent(new CustomEvent('valueupdate',
        {
            bubbles: true, composed: true,detail: {
                pageIndex:this.pageIndex,
                sectionIndex:this.sectionIndex,
                field : this.field,
                value : val,
                sectionIsMulti : this.sectionIsMulti,
                recordIndex : this.recordIndex
            }
        }))
    }

    handleKeyPress(event) {
        let input_number = event.keyCode;
        //console.log('input_number >> ',input_number);
        if(input_number == 13){
            event.preventDefault();
        }
    } 

    get fieldName(){
        return this.pageIndex+'_'+this.sectionIndex+'_'+this.field.fieldIndex;
    }

    get fieldKey() {
        if (this.recordIndex != null && this.recordIndex !== undefined && this.recordIndex !== '') {
            return `${this.pageIndex}-${this.sectionIndex}-${this.recordIndex}-${this.field.fieldIndex}`;
        }
        return `${this.pageIndex}-${this.sectionIndex}-${this.field.fieldIndex}`;
    }

    get errorInfo() {
        return this.fieldErrors && this.fieldErrors[this.fieldKey];
    }

    get fieldErrorClass() {
        return this.errorInfo ? 'slds-has-error' : '';
    }

    @api
    scrollToError(errorKey) {
        if (this.fieldKey !== errorKey) {
            return;
        }
        const target = this.template.querySelector('.slds-has-error');
        if (!target) {
            return;
        }
        target.scrollIntoView({ behavior: 'smooth', block: 'center' });
        target.classList.add('field-error-highlight');
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            target.classList.remove('field-error-highlight');
        }, 1500);
    }
}