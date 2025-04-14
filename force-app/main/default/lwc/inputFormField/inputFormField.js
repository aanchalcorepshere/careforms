import { LightningElement, track, api } from 'lwc';

export default class InputFormField extends LightningElement {
    @api field;
    @api sectionIndex;
    @api pageIndex;
    @api sectionIsMulti = false;
    @api recordIndex;
    @api isSummary = false;

    connectedCallback(){
        if(this.field.fieldData.dataType == 'BOOLEAN'){
            console.log('default val >> '+this.field.fieldData.defaultValue);
        }   
    }

    get label(){
        return this.field.fieldData.customlabel == ""?this.field.fieldData.fieldName:this.field.fieldData.customlabel;
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

    /* @api
    handleSubmit(){
        let recEditForm = this.template.querySelector('lightning-record-edit-form');

        this.dispatchEvent(new CustomEvent('recorddata',
        {
            detail: recEditForm
        }));
    } */

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

    get fieldName(){
        return this.pageIndex+'_'+this.sectionIndex+'_'+this.field.fieldIndex;
    }

    handleKeyDown(event){
        let input_key = event.keyCode;
        console.log('input_key >> '+input_key);
        if(input_key == 13){
            event.preventDefault();
        }
    }
}