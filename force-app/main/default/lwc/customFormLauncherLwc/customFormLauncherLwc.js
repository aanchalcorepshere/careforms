import { LightningElement, api, wire } from 'lwc';
import getFormsFeatureGate from '@salesforce/apex/FormsFeatureUtil.getFormsFeatureGate';
import getFormsForPrimaryObject from '@salesforce/apex/FormsHelper.getFormsForPrimaryObject';
//import getClientAndEmails from '@salesforce/apex/FormsHelper.getClientAndEmails';
//import sendFormToClient from '@salesforce/apex/FormsHelper.sendFormToClient';
import { CurrentPageReference } from 'lightning/navigation';
/* import getUserInfo from '@salesforce/apex/userDetails.getUserInfo';
import checkUserAccess from '@salesforce/apex/CheckAccessUtil.checkAccessOnRecord'; */
import USER_ID from '@salesforce/user/Id';
import { getApexErrorMessage } from 'c/formsErrorUtils';

export default class CustomFormLauncherLwc extends LightningElement {
    @api recordId;
    @api objectApiName;
    loggedInUserID = USER_ID;
    formsOptions;
    selectedForm;
    selectedFormLabel;
    isObjectListView;
    showCombobox = false;
    userProfile;
    userTitle;
    error;
    formLauncher = true;
    isPrefillFieldsForm;
    sendFormClicked = false;
    recipientValue;
    clientsOptionSelected = false;
    otherOptionSelected = false;
    selectedClient;
    clientsList;

    featureGateReady = false;
    formsFeatureGate;
    pageRef;

    @wire(getFormsFeatureGate)
    wiredFeatureGate(result) {
        const { data, error } = result;
        if (data) {
            this.formsFeatureGate = data;
            this.featureGateReady = true;
            this.tryLoadFormsForObject();
        } else if (error) {
            this.formsFeatureGate = {
                formsEnabled: false,
                unavailableMessage:
                    'Unable to verify Forms availability. Please refresh the page or contact your administrator.'
            };
            this.featureGateReady = true;
        }
    }

    tryLoadFormsForObject() {
        if (
            !this.featureGateReady ||
            !this.formsFeatureGate ||
            this.formsFeatureGate.formsEnabled === false ||
            !this.pageRef ||
            !this.objectApiName
        ) {
            return;
        }
        getFormsForPrimaryObject({ objectApiName: this.objectApiName })
            .then((result) => {
                if (result && result.length) {
                    this.formsOptions = JSON.parse(JSON.stringify(result));
                    this.showCombobox = true;
                    this.error = undefined;
                } else {
                    this.error = 'No forms are available for this Object.';
                }
            })
            .catch((error) => {
                this.error = getApexErrorMessage(error);
            });
    }

    get recipientOptions(){
        return [
            {label:'Client(s)', value:'clients'},
            {label:'Other', value:'other'}
        ];
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        this.pageRef = currentPageReference;
        this.tryLoadFormsForObject();
    }

    get featureGateLoading() {
        return !this.featureGateReady;
    }

    get showFormsUnavailable() {
        return (
            this.featureGateReady &&
            this.formsFeatureGate &&
            this.formsFeatureGate.formsEnabled === false
        );
    }

    get showLauncherShell() {
        return (
            this.featureGateReady &&
            this.formsFeatureGate &&
            this.formsFeatureGate.formsEnabled === true
        );
    }

    get formsUnavailableMessage() {
        return this.formsFeatureGate ? this.formsFeatureGate.unavailableMessage : '';
    }

    connectedCallback(){
        console.log('objectapiname => '+this.objectApiName);
        /* getClientAndEmails({recordId:this.recordId,objectApi:this.objectApiName})
        .then(result => {
            this.clientsList = JSON.parse(JSON.stringify(result));
        })
        .catch(error => {
            this.error = JSON.stringify(error);
        }) */
    }

    handleChange(event){
        this.selectedForm = event.detail.value;
        this.selectedFormLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
        console.log('selectedForm > '+this.selectedForm);
        console.log('selectedFormLabel > '+this.selectedFormLabel);
    }

    handleSubmit(){
        if(this.selectedForm){
            this.isPrefillFieldsForm = this.selectedFormLabel.includes('(Prefill Fields)');
            this.formLauncher = false;
            /* let isPrefillFieldsForm = this.selectedFormLabel.includes('(Prefill Fields)');
            let launchFormUrl;
            if(this.objectApiName == 'Form__c'){
                launchFormUrl = '/c/CustomFormAuraApp.app?isPrefillFieldsForm=false&primaryObjectForPrefill='+this.objectApiName+'&recordId='+this.selectedForm+'&formId='+this.selectedForm;
            }else{
                launchFormUrl = '/c/CustomFormAuraApp.app?isPrefillFieldsForm='+isPrefillFieldsForm+'&primaryObjectForPrefill='+this.objectApiName+'&recordId='+this.recordId+'&formId='+this.selectedForm;
            }
            console.log('launchFormUrl > '+launchFormUrl);
            window.open(launchFormUrl, '_blank'); */
        }else{
            this.error = 'Select a Form.';
        }
    }

    handleSendForm(){
        if(this.selectedForm){
            this.sendFormClicked = true;
            this.error = undefined;
        }else{
            this.error = 'Select a Form.';
        }
    }

    handleRecipientSelection(event){
        if(event.detail.value == 'clients'){
            this.clientsOptionSelected = true;
            this.otherOptionSelected = false;
            this.selectedClient = undefined;
        }else if(event.detail.value == 'other'){
            this.otherOptionSelected = true;
            this.clientsOptionSelected = false;
            //this.template.querySelector('lightning-input').value = '';
        }
    }

    handleClientSelection(event){
        if(event.target.name == 'clients'){
            let temp = event.target.value.split('#');
            this.selectedClient = temp[1];
        }else{
            this.selectedClient = event.target.value;
        }
    }

    /* handleSendSubmit(){
        let allWell = true;
        let thisError;
        if(!this.clientsOptionSelected || this.otherOptionSelected){
            allWell = false;
            thisError = 'Select a Client or enter an email address in Other to electronically send the Form.';
        }  
        if(this.otherOptionSelected){
            allWell = this.template.querySelector('lightning-input').checkValidity();
            if(!allWell){
                thisError = 'Enter Email for other individual to electronically send the Form.';
            }
        }else if(this.clientsOptionSelected){
            if(!this.selectedClient){
                allWell = false;
                thisError = 'Select a client name.';
            }
        }
        if(allWell){
            this.error = undefined;
            sendFormToClient({emailId:this.selectedClient,formId:this.selectedForm,recordId:this.recordId, objectApi:this.objectApiName})
            .then(result => {
                console.log('result  >> '+JSON.stringify(result));
                this.dispatchEvent(new CustomEvent('closequickactionsend',{
                    detail: {data: 'close form'}
                }));
            })
            .catch(error => {
                this.error = JSON.stringify(error);
            })

        }else{
            this.error = thisError;
        }
    } */

    handleSubmitForm(event){
        const detail = event && event.detail ? event.detail : {};
        const isSuccess = detail.isSuccess === true;
        const hasError = detail.error && String(detail.error).trim().length > 0;

        console.log('event from launcher lwc', JSON.stringify(detail));

        // Close quick action only when the save call succeeded.
        // On backend validation errors, keep the form open so user can correct data.
        if (isSuccess) {
            this.dispatchEvent(new CustomEvent('closequickaction',{
                detail: {data: 'close form'}
            }));
        } else if (hasError) {
            // Keep launcher shell hidden and allow child component to show the backend error banner.
            this.error = undefined;
        }
    }

    handleCancel(){
        console.log('cancel event from launcher lwc');
        this.dispatchEvent(new CustomEvent('closequickactioncancel',{
            detail: {data: 'close form'}
        }));
    }
}