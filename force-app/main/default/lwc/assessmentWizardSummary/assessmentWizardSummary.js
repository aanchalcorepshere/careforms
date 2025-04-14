import { LightningElement, api } from 'lwc';

export default class AssessmentWizardSummary extends LightningElement {
    @api assessmentDetails;
    @api sectionsData;
    @api questionsData;
    @api fieldUpdateData;
    @api scoringData;
    @api isSubmit;

    handleEdit(event){
        let buttonName = event.target.name;
        this.dispatchEvent(new CustomEvent('editstep', {
            detail: buttonName
        }));
    }
}