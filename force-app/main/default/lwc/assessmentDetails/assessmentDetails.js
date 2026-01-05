import { LightningElement, api, track } from 'lwc';
import getTodayDate from '@salesforce/apex/AssessmentQuestionnaireController.getTodayDate';

export default class AssessmentDetails extends LightningElement {
    @api assessment;
    @api clients;
    @track selectedDate;
    selectedClient;

    get hasClients() {
        return this.clients && Array.isArray(this.clients) && this.clients.length > 0;
    }

    connectedCallback(){
        //this.selectedDate = new Date().toISOString();
        getTodayDate()
        .then(result => {
            this.selectedDate = new Date().toISOString();
        })
        .catch(error => {
            this.error = JSON.stringify(error);
            console.error("Error >> ",JSON.stringify(error));
        })
    }

    handleDate(event){
        this.selectedDate = event.target.value;

        if(this.selectedDate > new Date().toISOString()){
            alert("Assessment Date cannot be greater than today's date.");
            this.selectedDate = new Date().toISOString();
        }
    }

    handleChange(event){
        this.selectedClient = event.target.value;
    }

    handleStart(){
        this.dispatchEvent(new CustomEvent('start', {
            detail: {
                "selectedDate" : this.selectedDate,
                "selectedClient" : this.selectedClient
            }
        }));
    }
}