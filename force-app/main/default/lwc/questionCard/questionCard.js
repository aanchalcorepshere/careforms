import { LightningElement, api } from 'lwc';

export default class QuestionCard extends LightningElement {
    @api assQuesId;
    @api quesText;
    @api quesSequence;
    @api ansOps;
    @api level;
    @api isText;
    @api isSignature;
    @api isNumber;
    @api isCheckbox;
    @api isRadio;
    @api isCombobox;
    @api isLongText;
    @api isDate;
    @api isCurrency;
    @api isPhone;
    @api grandParent;
    @api parent;
    @api isSubmit;
    @api response;
    @api isRequired;
    textValue;
    longTextValue;
    numberValue;
    radioValue;
    checkboxValue;
    comboboxValue;
    checkboxValue=[];
    localAnsOps;
    @api isOutcomeView = false;

    connectedCallback(){
        console.log("Response # ", this.response);
        this.localAnsOps = JSON.parse(JSON.stringify(this.ansOps));
        if(this.response){
            if(this.isText) this.textValue = this.response;
            if(this.isSignature) this.textValue = this.response;
            if(this.isLongText) this.longTextValue = this.response;
           
            if (this.isDate) {
            const parsedDate = Date.parse(this.response);
            if (!isNaN(parsedDate)) {
                this.dateValue = this.response;
            } else {
                console.error("Invalid date response:", this.response);
                this.dateValue = null; // Clear invalid date
            }
        }
            if(this.isRadio) {
                this.radioValue = this.response;
                if(this.localAnsOps && this.localAnsOps.length){
                    this.localAnsOps.forEach(ans => {
                        if(ans.label == this.radioValue){
                            ans.class = true;
                        }else{
                            ans.class = false;
                        }
                    })
                }
            }
            if(this.isCombobox) this.comboboxValue = this.response;
            if(this.isNumber) this.numberValue = this.response;
            if(this.isCheckbox) this.checkboxValue = this.response;
            console.log("comboboxValue # ", this.comboboxValue);
            //added by sg
            if(this.isDate) this.numberValue = this.response;
            if(this.isCurrency) this.numberValue = this.response;
            if(this.isPhone) this.textValue = this.response;
            //added end
        }
        
    }

    get options(){
        return this.localAnsOps;
    }

    handleResponse(event){
        let response = '';
        if(this.isText || this.isNumber || this.isSignature){
            response = event.target.value;
        }else{
            console.log("event.target >>>> ",JSON.stringify(event.target.label));
            response = event.target.value;
        }
        if (this.isDate && isNaN(Date.parse(response))) {
            event.target.setCustomValidity('Invalid date format.');
            event.target.reportValidity();
        return;
        } else {
            event.target.setCustomValidity('');
            event.target.reportValidity();
                }

        this.dispatchEvent(new CustomEvent('updateresponse', {
            detail: {
                'level':this.level,
                'assQuesId': this.assQuesId,
                'selectedValues' : response,
                'grandParent' : this.grandParent,
                'parent' : this.parent,
                'quesSequence' : this.quesSequence,
                'isText' : this.isText,
                'isNumber' : this.isNumber,
                'isRadio' : this.isRadio,
                'isCheckbox' : this.isCheckbox,
                'isCombobox' : this.isCombobox,
                'isLongText' : this.isLongText,
                'isSignature' : this.isSignature,
                'isDate' : this.isDate,
                'isCurrency' : this.isCurrency,
                'isPhone' : this.isPhone,
            }
        }));
    }
}