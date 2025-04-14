import { LightningElement, api, wire } from 'lwc';
import getFormsForPrimaryObject from '@salesforce/apex/FormsHelper.getFormsForPrimaryObject';
//import getClientAndEmails from '@salesforce/apex/FormsHelper.getClientAndEmails';
//import sendFormToClient from '@salesforce/apex/FormsHelper.sendFormToClient';
import { CurrentPageReference } from 'lightning/navigation';
/* import getUserInfo from '@salesforce/apex/userDetails.getUserInfo';
import checkUserAccess from '@salesforce/apex/CheckAccessUtil.checkAccessOnRecord'; */
import USER_ID from '@salesforce/user/Id';

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

    get recipientOptions(){
        return [
            {label:'Client(s)', value:'clients'},
            {label:'Other', value:'other'}
        ];
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
            getFormsForPrimaryObject({objectApiName:this.objectApiName})
            .then(result => {
                if(result && result.length){
                    this.formsOptions = JSON.parse(JSON.stringify(result));
                    this.showCombobox = true;
                    this.error = undefined
                }else{
                    this.error = 'No forms are available for this Object.';
                }
            })
            .catch(error => {
                this.error = JSON.stringify(error);
            })
       }
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

    handleSubmitForm(){
        console.log('event from launcher lwc');
        //this.dispatchEvent(new CustomEvent('formsubmitted'));
        this.dispatchEvent(new CustomEvent('closequickaction',{
            detail: {data: 'close form'}
        }));
    }

    handleCancel(){
        console.log('cancel event from launcher lwc');
        this.dispatchEvent(new CustomEvent('closequickactioncancel',{
            detail: {data: 'close form'}
        }));
    }
}