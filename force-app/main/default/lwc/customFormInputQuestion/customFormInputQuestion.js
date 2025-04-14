import { LightningElement, api, track } from 'lwc';
import getQuestionAnswerOptions from '@salesforce/apex/FormsController.getQuestionAnswerOptions';

export default class CustomFormInputQuestion extends LightningElement {
    @api question;
    @api sectionIndex;
    @api pageIndex;
    @api sectionIsMulti = false;
    @api recordIndex;
    @api isSummary = false;
    allOptions;
    
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
                this.allOptions = JSON.parse(JSON.stringify(this.options));
                /* if(this.selectedPrimaryReason && this.selectedPrimaryReason.length){
                    this.filterSecondaryReasons(this.selectedPrimaryReason);
                } */
            }
        })
        .catch(error => {
            console.error('Some error happened while getting question record');
        })
    }

    /* @api
    filterSecondaryReasons(selectedPrimaryReason){
        if(this.question.fieldData.fieldName.includes('other concerns')){
            var newArray = this.allOptions.filter(function (el) {
                return el.label != selectedPrimaryReason;
            });
            this.options = JSON.parse(JSON.stringify(newArray));
        }
    } */

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

    get isTextArea(){
        return this.question.fieldData.dataType == 'TEXTAREA';
    }

    get isCurrency(){
        return this.question.fieldData.dataType == 'CURRENCY';
    }

    get isDate(){
        return this.question.fieldData.dataType == 'DATE';
    }

    get isPhone(){
        return this.question.fieldData.dataType == 'PHONE';
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
}