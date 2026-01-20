import { LightningElement, wire, track, api } from 'lwc';
import getOutcomeDetails from '@salesforce/apex/OutcomeCmpController.getOutcomeDetails';

export default class OutcomeDetails extends LightningElement {

    @api outcomeId;
    @api objectName;
    @track outcome;
    percentScore;
    assessmentDate;
    recordLink;
    clientLink;
    sfObjectName;
    recordName;
    additionalLookupLabel = 'Client'; // Default label

    @wire(getOutcomeDetails,{outcomeId : '$outcomeId', objName:'$objectName'})
    wiredOutcomes(result){
        this.wiredOutcomesData = result;
        if(result.data){
            console.log('Outcome Data >> '+JSON.stringify(result.data));
            this.outcome = JSON.parse(JSON.stringify(result.data));
            this.percentScore = this.percentage(this.outcome.totalScore, this.outcome.totalMaxScore);
            this.assessmentDate = this.outcome.assessmentDate ? this.format(this.outcome.assessmentDate) : null;
            
            // Set record link and name - prioritize associatedRecordName
            if(this.outcome.associatedRecordName && this.outcome.associatedRecordId) {
                // Use Associated Record if available
                this.recordLink = '/' + this.outcome.associatedRecordId;
                this.recordName = this.outcome.associatedRecordName;
            } else if(this.outcome.recordId) {
                // Fallback to the related record from the dynamic field
                this.recordLink = '/' + this.outcome.recordId;
                // recordName will be set by lightning-input-field onchange handler
            }
            
            if(this.outcome.clientId){
                this.clientLink = '/'+this.outcome.clientId;
            }
            
            // Set additional lookup label from metadata (defaults to 'Client' if not provided)
            if(this.outcome.additionalLookupLabel){
                this.additionalLookupLabel = this.outcome.additionalLookupLabel;
            }
            
            console.log('this.outcome > ',JSON.stringify(this.outcome));
            console.log('recordName: ', this.recordName);
            console.log('recordLink: ', this.recordLink);
            console.log('additionalLookupLabel: ', this.additionalLookupLabel);
        }else if(result.error){
            console.error('ERROR : ',JSON.stringify(result.error));
        }
    }

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

    get objName(){
        return this.outcome.caresp__Object__c=='caresp__Referral__c'?'Referral':'Assigned Service';
    }

    get hasClient(){
        return this.outcome && this.outcome.clientId && this.outcome.clientName;
    }

    handleOnLoad(event) {
        if(event && event.detail && event.detail.value) {
            this.recordName = event.detail.value;
            console.log('this.recordName >> '+this.recordName);
        }
    }

    percentage(partialValue, totalValue) {
        return (100 * partialValue) / totalValue;
    } 
}