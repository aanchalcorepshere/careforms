import { LightningElement, api, wire, track } from 'lwc';

import fetchLookupData from '@salesforce/apex/CustomLookupLwcController.fetchLookupData';
import fetchDefaultRecord from '@salesforce/apex/CustomLookupLwcController.fetchDefaultRecord';
import { refreshApex } from '@salesforce/apex';

const DELAY = 300; // dealy apex callout timing in miliseconds  
const NEW_QUES_DELAY = 1000; // dealy apex callout timing in miliseconds  

export default class CustomLookupLwc extends LightningElement {
    // public properties with initial default values 
    @api label = 'custom lookup label';
    @api placeholder = 'search...';
    @api iconName = 'standard:account';
    @api sObjectApiName = 'Account';
    @api fieldName = 'Name';
    @api defaultRecordId = '';
    @api isEdit;
    localEditData;
    //@api editQuestionData;
    createNew = false;
    newQuesId;
    newQuesText;
    quesError;

    // private properties 
    lstResult = []; // to store list of returned records   
    hasRecords = true;
    searchKey = ''; // to store input field value    
    isSearchLoading = false; // to control loading spinner  
    delayTimeout;
    wiredSearchResult;
    @track selectedRecord = {}; // to store selected lookup record in object formate 

    // initial function to populate default selected lookup record if defaultRecordId provided  
    connectedCallback() {
        if (this.defaultRecordId != '') {
            fetchDefaultRecord({ recordId: this.defaultRecordId, 'sObjectApiName': this.sObjectApiName, fieldname : this.fieldName })
                .then((result) => {
                    if (result != null) {
                        this.selectedRecord = result;
                        this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
                    }
                })
                .catch((error) => {
                    this.error = error;
                    this.selectedRecord = {};
                });
        }

        /* if(this.isEdit){
            console.log("this.editQuestionData >> ",JSON.stringify(this.editQuestionData));
            let newQues = {};
            newQues.Id = this.editQuestionData.Id;
            newQues.Question_Text__c = this.editQuestionData.quesText;
            newQues.Name = this.editQuestionData.quesText;
            this.lstResult.push(newQues);
            this.selectedRecord = this.lstResult.find(data => data.Id === this.newQuesId); // find selected record from list 
            this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function 
            this.handelSelectRecordHelper();
        } */
    }

    
    @api
    get editQuestionData() {
        return this.localEditData;
    }

    set editQuestionData(value) {
        if(value && Object.keys(value).length > 0){
            console.log("value2 >> ",JSON.stringify(value));
            this.localEditData = value;
            if(Object.keys(this.localEditData).length > 0){
                console.log("this.localEditData type of>> ",typeof this.localEditData);
                console.log("this.localEditData >> ",JSON.stringify(this.localEditData));
                let newQues = {};
                newQues.Id = this.localEditData.Id;
                newQues.caresp__Question_Text__c = this.localEditData.quesText;
                newQues.Name = this.localEditData.quesText;
                this.lstResult.push(newQues);
                console.log("this.lstResult >> ",JSON.stringify(this.lstResult));
                this.selectedRecord.Id = this.localEditData.Id;
                this.selectedRecord.caresp__Question_Text__c = this.localEditData.quesText;
                this.selectedRecord.Name = this.localEditData.quesText;
                console.log("this.selectedRecord >> ",JSON.stringify(this.selectedRecord));
                if(this.selectedRecord){
                    this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function 
                    this.handelSelectRecordHelper();
                }
            }
        }
    }

    renderedCallback(){
        
    }

    // wire function property to fetch search record based on user input
    @wire(fetchLookupData, { searchKey: '$searchKey', sObjectApiName: '$sObjectApiName',fieldname : '$fieldName' })
    searchResult(value) {
        this.wiredSearchResult = value;
        const { data, error } = value; // destructure the provisioned value
        this.isSearchLoading = false;
        if (data) {
            this.hasRecords = data.length == 0 ? false : true;
            this.lstResult = JSON.parse(JSON.stringify(data));
            if(this.lstResult && this.lstResult.length){
                this.lstResult.forEach(result => {
                    result.Name = result[this.fieldName];
                })
            }
        }
        else if (error) {
            console.log('(error---> ' + JSON.stringify(error));
        }
    };

    // update searchKey property on input field change  
    handleKeyChange(event) {
        // Debouncing this method: Do not update the reactive property as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchKey;
            this.newQuesText = searchKey;
        }, DELAY);
    }

    handleNewQues(){
        this.createNew = true;
    }

    handleSuccess(event){
        this.newQuesId = event.detail.id;
        console.log("newQuesId >> ",this.newQuesId);
        console.log("this.searchKey >> ",this.searchKey);
        let newQues = {};
        newQues.Id = this.newQuesId;
        newQues.caresp__Question_Text__c = this.newQuesText;
        newQues.Name = this.newQuesText;
        this.lstResult.push(newQues);
        this.createNew = false; // get selected record Id 
        this.selectedRecord = this.lstResult.find(data => data.Id === this.newQuesId); // find selected record from list 
        this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function 
        this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
    }

    handleNewQuesText(event){
        this.newQuesText = event.target.value;
        this.quesError = undefined;
    }

    closeModal(){
        this.createNew = false;
    }

    handleError(event){
        this.quesError = event.detail.detail;
    }

    // method to toggle lookup result section on UI 
    toggleResult(event) {
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch (whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
                break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');
                break;
        }
    }

    // method to clear selected lookup record  
    handleRemove() {
        this.searchKey = '';
        this.selectedRecord = {};
        this.lookupUpdatehandler(undefined); // update value on parent component as well from helper function 

        // remove selected pill and display input field again 
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-hide');
        searchBoxWrapper.classList.add('slds-show');

        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-show');
        pillDiv.classList.add('slds-hide');
    }

    // method to update selected record from search result 
    handelSelectedRecord(event) {
        var objId = event.target.getAttribute('data-recid'); // get selected record Id 
        this.selectedRecord = this.lstResult.find(data => data.Id === objId); // find selected record from list 
        this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function 
        this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
    }

    /*COMMON HELPER METHOD STARTED*/

    handelSelectRecordHelper() {
        this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');

        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-show');
        searchBoxWrapper.classList.add('slds-hide');

        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-hide');
        pillDiv.classList.add('slds-show');
    }

    // send selected lookup record to parent component using custom event
    lookupUpdatehandler(value) {
        const oEvent = new CustomEvent('lookupupdate',
            {
                'detail': { selectedRecord: value }
            }
        );
        this.dispatchEvent(oEvent);
    }


}