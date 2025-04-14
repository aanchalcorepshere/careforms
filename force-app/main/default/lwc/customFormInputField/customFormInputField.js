import { LightningElement, track, api } from 'lwc';

export default class CustomFormInputField extends LightningElement {
    @api field;
    @api sectionIndex;
    @api pageIndex;
    @api sectionIsMulti = false;
    @api recordIndex;
    @api isSummary = false;
    objectNameForCopy;
    @api isPrefillFieldsForm;

    handleOnLoad() {
       if(!this.field.fieldData.hasOnLoadRun && (this.isPrefillFieldsForm)){
            let val;
            val = this.template.querySelector('.thecopyfield').value;
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

    connectedCallback(){
        //console.log('isPrefillFieldsForm from field >> ',this.isPrefillFieldsForm);
        if(this.field.fieldData.dataType == 'BOOLEAN'){
            //console.log('default val >> '+this.field.fieldData.defaultValue);
            if(this.isApplicationForm){
                this.dispatchEvent(new CustomEvent('valueupdate',
                {
                    bubbles: true, composed: true,detail: {
                        pageIndex:this.pageIndex,
                        sectionIndex:this.sectionIndex,
                        field : this.field,
                        value : this.field.fieldData.defaultValue,
                        sectionIsMulti : this.sectionIsMulti,
                        recordIndex : this.recordIndex
                    }
                }))
            }
        }
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
        //let recEditForm = this.template.querySelector('lightning-input-field');
        let val = event.target.value;
        
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
}