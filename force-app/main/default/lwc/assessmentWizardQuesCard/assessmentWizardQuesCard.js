import { LightningElement, api, track } from 'lwc';
//import getCompatibleFields from '@salesforce/apex/AssessmentWizardController.getCompatibleFields';

export default class AssessmentWizardQuesCard extends LightningElement {
    
    @api fieldList;
    @api isSubmit;
    @track localQues;
    isLoading = false;

    fieldname;
    required;

    /* @track objectNames = [
        {label : '--', value : ''},
        {label : 'Client', value : 'Client__c'},
        {label : 'Referral', value : 'Referral__c'},
        {label : 'Assigned Service', value : 'Client_Service__c'},
        {label : 'Client Service', value : 'Junction_Service__c'},
    ]; */

    connectedCallback() {
        console.log('fieldlist >> '+JSON.stringify(this.fieldList));
        console.log('level >> '+this.localQues.level);
    }

    @api
    get ques() {
        return this.localQues;
    }

    set ques(value) {
        //Set personObject property to our new updated person object
        this.localQues = JSON.parse(JSON.stringify(value));
        //this.localQues.objectnames = this.objectNames;
    }

    get dragDisable(){
        return !this.isSubmit;
    }

    get cardClass(){
        if(this.isSubmit){
            return (this.localQues.level+"summary");
        }else{
            return (this.localQues.level)
        }
    }

    get showFieldOptions(){
        if(this.localQues.level == 'level1'){
            return true;
        }else{
            return false;
        }
    }

    addCSS(className) {
        this.template.querySelector('[data-id="mainDiv"]').classList.add(className);
    }

    removeCSS(className) {
        this.template.querySelector('[data-id="mainDiv"]').classList.remove(className);
    }

    /* Drag events */

    handleDragStart() {
        this.addCSS('slds-drop-zone');
        this.dispatchEvent(new CustomEvent('startdrag', {
            detail: this.localQues
        }));
    }

    handleDragOver(event) {
        event.preventDefault();
        this.addCSS('over');
        this.addCSS('slds-drop-zone');
    }

    handleDrop(event) {
        event.preventDefault();
        event.stopPropagation();
        this.removeCSS('over');
        this.removeCSS('slds-drop-zone');
        this.dispatchEvent(new CustomEvent('itemdrop', {
            detail: this.localQues
        }));
    }

    handleDragEnter() {
        this.addCSS('over');
        this.addCSS('slds-drop-zone');
    }

    handleDragLeave() {
        this.removeCSS('over');
        this.removeCSS('slds-drop-zone');
    }

    handleDragEnd() {
        this.removeCSS('over');
        this.removeCSS('slds-drop-zone');
    }

    handleChange(event) {
        let targetName = event.target.name;
        
        if (targetName === 'fieldname') {
            this.localQues.fieldname = event.target.value;
        } else if (targetName === 'required') {
            this.localQues.required = event.target.checked;
        }

        console.log('this.localQues >> '+JSON.stringify(this.localQues));

        this.dispatchEvent(new CustomEvent('updatequestiondata', {
            detail: this.localQues
        }));
    }

    handleRemoveClick() {
        var confirmation = confirm("Are you sure you want to delete this question?\nPress OK to delete.");
        if (confirmation == true) {
            this.dispatchEvent(new CustomEvent('removeitem', {
                detail: this.localQues
            }));
        }
    }
}