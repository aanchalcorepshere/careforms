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
        var date = new Date(inputDate);
        var date = new Date(inputDate);
        if (!isNaN(date.getTime())) {
            var day = date.getDate().toString();
            var month = (date.getMonth() + 1).toString();
            // Months use 0 index.

            return (month[1] ? month : '0' + month[0]) + '/' +
            (day[1] ? day : '0' + day[0]) + '/' + 
            date.getFullYear();
        }
    }

    @wire(getOutcomes,{recordId : '$recordId'})
    wiredOutcomes(result){
        this.wiredOutcomesData = result;
        if(result.data){
            this.outcomeList = JSON.parse(JSON.stringify(result.data));
            console.log('this.outcomeList >> '+JSON.stringify(this.outcomeList));
            let seq = 1;
            if(this.outcomeList && this.outcomeList.length){
                this.outcomeList.forEach(outcome => {
                    outcome.Name = (seq++)+'. '+outcome.Name;
                    outcome.url = +'/c/OutcomeApp.app?outcomeId='+outcome.Id;
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
                    outcome.clientUrl = '/'+outcome.caresp__Client__c;
                    outcome.createdbyUrl = '/'+outcome.CreatedBy.Id;
                    outcome.lastmodifiedbyUrl = '/'+outcome.LastModifiedBy.Id;
                    var date = new Date(outcome.LastModifiedDate);
                    console.log(date.toDateString());
                })
            }else{
                this.isNoOutcomes = true;
            }
            //console.log('this.outcomeList > ',JSON.stringify(this.outcomeList));
        }else if(result.error){
            console.error('ERROR : ',JSON.stringify(result.error));
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