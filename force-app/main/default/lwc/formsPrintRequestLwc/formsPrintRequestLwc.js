import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFormsFeatureGate from '@salesforce/apex/FormsFeatureUtil.getFormsFeatureGate';
import getFormsAvailableForPrint from '@salesforce/apex/FormsController.getFormsAvailableForPrint';
//import checkUserAccess from '@salesforce/apex/CheckAccessUtil.checkAccessOnRecord';
import USER_ID from '@salesforce/user/Id';
import { getApexErrorMessage } from 'c/formsErrorUtils';
//import APPLICATION_FORM from '@salesforce/label/c.Application_Form';

export default class FormsPrintRequestLwc extends LightningElement {
    @api recordId;
    @api objectApiName;
    loggedInUserID = USER_ID;
    formsList;
    selectedForm;
    hasAccess;
    error;
    //applicationForm = APPLICATION_FORM;

    featureGateReady = false;
    formsFeatureGate;
    _printListLoadStarted = false;

    @wire(getFormsFeatureGate)
    wiredFeatureGate(result) {
        const { data, error } = result;
        if (data) {
            this.formsFeatureGate = data;
            this.featureGateReady = true;
            this.tryLoadFormsForPrint();
        } else if (error) {
            this.formsFeatureGate = {
                formsEnabled: false,
                unavailableMessage:
                    'Unable to verify Forms availability. Please refresh the page or contact your administrator.'
            };
            this.featureGateReady = true;
        }
    }

    renderedCallback() {
        this.tryLoadFormsForPrint();
    }

    tryLoadFormsForPrint() {
        if (
            !this.featureGateReady ||
            !this.formsFeatureGate ||
            this.formsFeatureGate.formsEnabled === false ||
            !this.recordId ||
            this._printListLoadStarted
        ) {
            return;
        }
        this._printListLoadStarted = true;
        getFormsAvailableForPrint({ recordId: this.recordId })
            .then((result) => {
                let tempFormsList = JSON.parse(JSON.stringify(result));
                console.log('tempFormsList >> ' + JSON.stringify(tempFormsList));
                this.formsList = JSON.parse(JSON.stringify(tempFormsList));
                console.log('this.formsList >> ' + JSON.stringify(this.formsList));
            })
            .catch((error) => {
                this.error = getApexErrorMessage(error);
            });
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

    get showPrintShell() {
        return (
            this.featureGateReady &&
            this.formsFeatureGate &&
            this.formsFeatureGate.formsEnabled === true
        );
    }

    get formsUnavailableMessage() {
        return this.formsFeatureGate ? this.formsFeatureGate.unavailableMessage : '';
    }

    // connectedCallback(){
    //     checkUserAccess({ recId: this.recordId, userId: this.loggedInUserID})
    //     .then(result => {
    //         console.log('result >> ',JSON.stringify(result));
    //         if (result != undefined) {
    //             this.hasAccess = result;
    //             if(this.hasAccess){
    //                 this.error = undefined;
    //                 getFormsAvailableForPrint({recordId:this.recordId})
    //                 .then(result => {
    //                     let tempFormsList = JSON.parse(JSON.stringify(result));
    //                     console.log('tempFormsList >> '+JSON.stringify(tempFormsList));
    //                     /* tempFormsList.sort(function(x,y){
    //                         var xp = x.dateTimeVal.replace('');
    //                         var yp = y.dateTimeVal;
    //                         return xp == yp ? 0 : xp < yp ? 1 : -1;
    //                     }); */

    //                     this.formsList = JSON.parse(JSON.stringify(tempFormsList));
    //                     console.log('this.formsList >> '+JSON.stringify(this.formsList));
    //                 })
    //                 .catch(error => {
    //                     this.error = JSON.stringify(error);
    //                 })
    //             }else{
    //                 //this.error = 'You do not have access to print forms on this record.';
    //                 const toastEve = new ShowToastEvent({
    //                     mode: "dismissable",
    //                     variant: "error",
    //                     title: "No Access",
    //                     message: "You do not have access to print forms on this record."
    //                 });
    //                 this.dispatchEvent(toastEve);
    //                 const closeLwc = new CustomEvent('close');
    //                 this.dispatchEvent(closeLwc);
    //             }
    //         }
    //     })
    //     .catch(error => {
    //         this.error = JSON.stringify(error);
    //     })
    // }

    handleChange(event) {
        this.selectedForm = event.detail.value;
        console.log('selectedForm > ' + this.selectedForm);
    }

    handleSubmit() {
        if (this.selectedForm) {
            let formId = this.selectedForm.substring(0, this.selectedForm.indexOf('_'));
            console.log('formId >> ' + formId);
            this.dispatchEvent(new CustomEvent('formselection', {
                detail: {
                    data: this.selectedForm,
                    objectApi: this.objectApiName,
                    isApplication: this.applicationForm == formId ? true : false
                }
            }));
        } else {
            this.error = 'Select a Form.';
        }
    }
}