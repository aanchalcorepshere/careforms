import { LightningElement, api, track } from 'lwc';
import getQuestionAnswerOptions from '@salesforce/apex/FormsController.getQuestionAnswerOptions';

export default class InputFormQuestion extends LightningElement {
    @api question;
    @api sectionIndex;
    @api pageIndex;
    @api sectionIsMulti = false;
    @api recordIndex;
    @api isSummary = false;
    @api fieldErrors = {};
    
    @track options = [];

    connectedCallback(){
        getQuestionAnswerOptions({quesId : this.question.fieldData.fieldApi})
        .then(result => {
            let quesAnsOpList = result;
            if(quesAnsOpList){
                quesAnsOpList.forEach(quesAnsOp => {
                    this.options.push({
                        label:quesAnsOp.caresp__Answer_Text__c,
                        value:quesAnsOp.caresp__Answer_Text__c});
                })
                //console.log('options >> ',JSON.stringify(this.options));
            }
        })
        .catch(error => {

        })
    }

    get isCombobox(){
        return this.question.fieldData.dataType == 'PICKLIST';
    }

    get isCheckbox(){
        return this.question.fieldData.dataType == 'CHECKBOX';
    }

    get isRadiobox(){
        return this.question.fieldData.dataType == 'RADIOBOX';
    }

    get isText(){
        return this.question.fieldData.dataType == 'STRING';
    }

    get isNumber(){
        return this.question.fieldData.dataType == 'INTEGER';
    }

    get gotOptions(){
        return this.options.length > 0;
    }

    handleResponse(event){
        let val = event.target.value;
        this.dispatchEvent(new CustomEvent('valueupdate',
        {
            bubbles: true, composed: true,detail: {
                pageIndex:this.pageIndex,
                sectionIndex:this.sectionIndex,
                field : this.question,
                sectionIsMulti : this.sectionIsMulti,
                recordIndex:this.recordIndex,
                value : val
            }
        }));
    }

    get fieldKey() {
        if (this.recordIndex != null && this.recordIndex !== undefined && this.recordIndex !== '') {
            return `${this.pageIndex}-${this.sectionIndex}-${this.recordIndex}-${this.question.fieldIndex}`;
        }
        return `${this.pageIndex}-${this.sectionIndex}-${this.question.fieldIndex}`;
    }

    get errorInfo() {
        return this.fieldErrors && this.fieldErrors[this.fieldKey];
    }

    get fieldErrorClass() {
        return this.errorInfo ? 'slds-has-error' : '';
    }
}