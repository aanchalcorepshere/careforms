import { LightningElement, wire, track, api } from 'lwc';
import getOutcomeDetails from '@salesforce/apex/OutcomeCmpController.getOutcomeDetails';

export default class OutcomeDetails extends LightningElement {

    @api outcomeId;
    @api objectName;
    @track outcome;
    percentScore;
    assessmentDate;
    recordLink;
    sfObjectName;
    recordName;

    handleOnLoad() {
        this.recordName = this.template.querySelector('.thefield').value;
        console.log('this.recordName >> '+this.recordName);
     }

    @wire(getOutcomeDetails,{outcomeId : '$outcomeId', objName:'$objectName'})
    wiredOutcomes(result){
        this.wiredOutcomesData = result;
        if(result.data){
            console.log('Outcome Data >> '+JSON.stringify(result.data));
            this.outcome = JSON.parse(JSON.stringify(result.data));
            this.percentScore = this.percentage(this.outcome.totalScore, this.outcome.totalMaxScore);
            this.assessmentDate =  this.format(this.outcome.assessmentDate) ;
            this.recordLink = '/'+this.outcome.recordId;
            console.log('this.outcome > ',JSON.stringify(this.outcome));
        }else if(result.error){
            console.error('ERROR : ',JSON.stringify(result.error));
        }
    }

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

    get objName(){
        return this.outcome.caresp__Object__c=='caresp__Referral__c'?'Referral':'Assigned Service';
    }

    percentage(partialValue, totalValue) {
        return (100 * partialValue) / totalValue;
    } 
}