import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOutcomes from '@salesforce/apex/OutcomeCmpController.getOutcomes';
//import checkAccessOnRecord from '@salesforce/apex/CheckAccessUtil.checkAccessOnRecord';
//import getUserInfo from '@salesforce/apex/userDetails.getUserInfo';
import {refreshApex} from '@salesforce/apex';
//import ORG_URL from '@salesforce/label/c.Org_URL';
//import Portal_URL from '@salesforce/label/c.Portal_URL';
import USER_ID from '@salesforce/user/Id';

export default class OutcomeCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    message;
    hasAccess = false;
    userid = USER_ID;
    profileName;
    outcomeurl;

    @track outcomeList;
    isNoOutcomes = false;
    wiredOutcomesData;

    /* @wire(getUserInfo, { uId: '$userid'})
    wiredUserDetails (result) {
        if (result.data)
        {
            console.log('## User data: ' + JSON.stringify(result.data));
            //console.log('## forPrint: ' + this.forPrint);
            if (result.data.userProfile != null && result.data.userProfile != undefined) this.profileName = result.data.userProfile;
        }
        else if (result.error)
        {
            this.error = result.error;
            console.log('#### error wiredUserDetails: ' + JSON.stringify(result.error));
        }
    } */

    connectedCallback(){
        //this.register();
        /* checkAccessOnRecord({recId: this.recordId, userId:this.userid})
        .then(result=>{
            this.hasAccess = result;
            console.log('this.hasAccess >> '+this.hasAccess);
        })
        .catch(error=>{
            console.error(error);
        }) */
    }

    /* @api
    register(){
        window.console.log('event registered ');
        pubsub.register('simplevt', this.handleEvent.bind(this));
    } */

    format(inputDate) {
        // Check if inputDate is null, undefined, or empty
        if (!inputDate) {
            return null;
        }
        
        // Try to parse the date
        var date = new Date(inputDate);
        
        // Check if the date is valid
        if (!isNaN(date.getTime())) {
            var day = date.getDate().toString();
            var month = (date.getMonth() + 1).toString();
            // Months use 0 index.

            return (month[1] ? month : '0' + month[0]) + '/' +
            (day[1] ? day : '0' + day[0]) + '/' + 
            date.getFullYear();
        }
        
        // If date parsing failed, return the original value (might already be formatted)
        return inputDate;
    }

    @wire(getOutcomes,{recordId : '$recordId'})
    wiredOutcomes(result){
        this.wiredOutcomesData = result;
        if(result.data){
            // User has access if data is returned (WITH USER_MODE enforces sharing rules)
            this.hasAccess = true;
            this.outcomeList = JSON.parse(JSON.stringify(result.data));
            console.log('this.outcomeList >> '+JSON.stringify(this.outcomeList));
            let seq = 1;
            if(this.outcomeList && this.outcomeList.length){
                this.outcomeList.forEach(outcome => {
                    outcome.Name = (seq++)+'. '+outcome.Name;
                    outcome.url = +'/caresp/OutcomeApp.app?outcomeId='+outcome.Id;
                    //outcome.assessmentDate = this.format(outcome.Assessment_Date__c);
                    outcome.assessmentDate = outcome.AssessmentDate;
                    //console.log("this.profileName >> "+this.profileName);
                    outcome.assessmentUrl = '/'+outcome.caresp__Assessment__c;
                        outcome.isAssessmentAccessible = true;
                    /* if(this.profileName == 'System Administrator' || this.profileName == 'Internal Super User'){
                        outcome.assessmentUrl = '/'+outcome.Assessment__c;
                        outcome.isAssessmentAccessible = true;
                    }else{
                        outcome.isAssessmentAccessible = false;
                    } */
                    console.log("outcome.assessmentUrl>> ",outcome.assessmentUrl);
                    if (outcome.caresp__Client__c) {
                        outcome.clientUrl = '/'+outcome.caresp__Client__c;
                    }
                    // Normalize CreatedBy field names (handle both Name and name)
                    if (outcome.CreatedBy) {
                        if (outcome.CreatedBy.Id) {
                            outcome.createdbyUrl = '/'+outcome.CreatedBy.Id;
                        }
                        // Ensure Name field is accessible (handle both cases)
                        if (!outcome.CreatedBy.Name && outcome.CreatedBy.name) {
                            outcome.CreatedBy.Name = outcome.CreatedBy.name;
                        }
                    }
                    // Normalize LastModifiedBy field names (handle both Name and name)
                    if (outcome.LastModifiedBy) {
                        if (outcome.LastModifiedBy.Id) {
                            outcome.lastmodifiedbyUrl = '/'+outcome.LastModifiedBy.Id;
                        }
                        // Ensure Name field is accessible (handle both cases)
                        if (!outcome.LastModifiedBy.Name && outcome.LastModifiedBy.name) {
                            outcome.LastModifiedBy.Name = outcome.LastModifiedBy.name;
                        }
                    }
                    // Handle date formatting safely - editDate is already formatted from Apex
                    if (outcome.editDate) {
                        var date = new Date(outcome.editDate);
                        if (!isNaN(date.getTime())) {
                            console.log(date.toDateString());
                        } else {
                            // If parsing fails, use the formatted string as-is
                            console.log(outcome.editDate);
                        }
                    }
                })
            }else{
                this.isNoOutcomes = true;
            }
            //console.log('this.outcomeList > ',JSON.stringify(this.outcomeList));
        }else if(result.error){
            console.error('ERROR : ',JSON.stringify(result.error));
            // Check if error is access-related
            const errorMessage = result.error?.body?.message || result.error?.message || JSON.stringify(result.error);
            if (errorMessage && (
                errorMessage.toLowerCase().includes('access') || 
                errorMessage.toLowerCase().includes('insufficient access') ||
                errorMessage.toLowerCase().includes('permission')
            )) {
                this.hasAccess = false;
            } else {
                // For other errors, still show access (let the error be displayed elsewhere)
                this.hasAccess = true;
            }
        }
    }

    get isLoading(){
        return !this.wiredOutcomesData
    }

    handleClick(event){
        //event.stopPropagation();
        let outcomeId = event.currentTarget.dataset.outcomeId;
        this.outcomeurl = '/'+outcomeId;
        console.log(this.outcomeurl);
        window.open(this.outcomeurl,"_blank");
        /* if(this.profileName == "System Administrator" || this.profileName == "Internal Super User"){
            let outcomeId = event.currentTarget.dataset.outcomeId;
            this.outcomeurl = '/'+outcomeId;
            console.log(this.outcomeurl);
            window.open(this.outcomeurl,"_blank");
        }else {
            let outcomeId = event.currentTarget.dataset.outcomeId;
            let outcomeurl = Portal_URL+'/outcome/'+outcomeId;
            window.open(outcomeurl,"_blank");
        } */
    }

    handleEvent(event){
        window.console.log('event handled ',messageFromEvt);
        this.message = messageFromEvt ? JSON.stringify(messageFromEvt, null, '\t') : 'no message payload';
        refreshApex(this.wiredOutcomesData);
    }

}