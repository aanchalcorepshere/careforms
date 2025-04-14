import { LightningElement, track, wire, api } from 'lwc';
import getResponses from '@salesforce/apex/OutcomeCmpController.getResponses';

export default class OutcomeQuestionnaire extends LightningElement {
    isSubmit = true;
    @api outcomeId;
    @track responses;
    error;
    hasSections=false;
    @track sections=[];

    @wire(getResponses, {outcomeId : '$outcomeId'})
    wiredResponses(result){
        this.wiredResponseData = result;
        if(result.data){
            this.responses = result.data;
            console.log("this.responses >> ",JSON.stringify(this.responses));
            this.error = undefined;
            let checkSections = this.responses.findIndex(x => x.section == 'Resonses');
            console.log("checkSections ",checkSections);
            if(checkSections == -1){
                this.hasSections = true;
                this.responses.forEach(response => {
                    if(this.sections.findIndex(x => x.sectionName == response.section) == -1){
                        let temp = {};
                        temp.sectionName = response.section;
                        temp.sectionSequence = response.sectionSequence;
                        temp.questionData = [];
                        this.sections.push(temp);
                    }
                })
                this.sections.sort(function(a,b){
                    return a.sectionSequence - b.sectionSequence;
                    }
                );
                this.sections.forEach(section => {
                    this.responses.forEach(response => {
                        console.log("Sec Seq # ",response.sectionSequence);
                        if((response.sectionSequence == section.sectionSequence)){
                            section.questionData.push(response);
                        }
                    })
                })
                console.log("this.sections # ",JSON.stringify(this.sections));
            }else{
                this.hasSections = false;
                this.sections = [];
                let tempSection = {};
                tempSection.sectionName = "Default";
                tempSection.sectionSequence = 1;
                tempSection.questionData = this.responses;
                this.sections.push(tempSection);
            }
        }else if(result.error){
            this.responses = undefined;
            this.error = result.error;
            console.error("ERROR # ",JSON.stringify(this.error));
        }
    }
}