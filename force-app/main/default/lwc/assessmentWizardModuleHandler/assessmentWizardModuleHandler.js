import { LightningElement, api, track } from 'lwc';

export default class AssessmentWizardModuleHandler extends LightningElement {
    moduleToLoad;
    @api isAssessmentDetails;
    @api isQuestionSelection;
    @api isSortQuestions;
    @api isOnCompletion;
    @api isScoreTranslation;
    @api selectedQuestions;
    @api objectName;
    @api needScoring;
    @api isCreateSections;
    @api isSectionHandler;
    @api selectedSections;
    @api needSections;
    @api isSubmit;
    @api isEdit;
    //@api editAssessmentData;
    @track localEditData;

    //properties for data retention
    @track assessmentDetails;
    @track sections;
    @track sectionData;
    @track fieldUpdate;
    @track scoringData;


    connectedCallback(){
        this.isAssessmentDetails = true;
        /* if(this.isEdit){
            console.log("Edit Data >> ",JSON.stringify(this.editAssessmentData));
        } */
    }

    @api
    get editAssessmentData() {
        //console.log("this.localEditData >> ",JSON.stringify(this.localEditData));
        return this.localEditData;
    }

    set editAssessmentData(value) {
        this.localEditData = value;
        if (!this.localEditData) {
            return;
        }
        // Support namespaced and non-namespaced API names and guard JSON.parse calls
        const detail    = this.localEditData.caresp__Assessment_Detail_JSON__c ?? this.localEditData.Assessment_Detail_JSON__c;
        const sections  = this.localEditData.caresp__Section_JSON__c ?? this.localEditData.Section_JSON__c;
        const questions = this.localEditData.caresp__Questions_JSON__c ?? this.localEditData.Questions_JSON__c;
        const scoring   = this.localEditData.caresp__Scoring_JSON__c ?? this.localEditData.Scoring_JSON__c;
        const fieldUpd  = this.localEditData.caresp__Field_Update_JSON__c ?? this.localEditData.Field_Update_JSON__c;

        if (detail)    { this.assessmentDetails = JSON.parse(detail); }
        if (sections)  { this.sections = JSON.parse(sections); }
        if (questions) { this.sectionData = JSON.parse(questions); }
        if (scoring)   { this.scoringData = JSON.parse(scoring); }
        if (fieldUpd)  { this.fieldUpdate = JSON.parse(fieldUpd); }

        // Proactively sync parsed data back to container so validations see it
        if (this.assessmentDetails) {
            this.dispatchEvent(new CustomEvent('stepdata', {
                detail: { eventName: 'assessmentdetails', data: this.assessmentDetails }
            }));
        }
        if (this.sections) {
            this.dispatchEvent(new CustomEvent('stepdata', {
                detail: { eventName: 'sectiondetails', data: this.sections }
            }));
        }
        if (this.sectionData) {
            this.dispatchEvent(new CustomEvent('stepdata', {
                detail: { eventName: 'sectiondata', data: this.sectionData }
            }));
        }
        if (this.scoringData) {
            this.dispatchEvent(new CustomEvent('stepdata', {
                detail: { eventName: 'scoringdata', data: this.scoringData }
            }));
        }
        if (this.fieldUpdate) {
            this.dispatchEvent(new CustomEvent('stepdata', {
                detail: { eventName: 'completionfieldupdate', data: this.fieldUpdate }
            }));
        }
    }

    handleData(event){
        let eventType = event.type;
        switch(eventType){
            case "assessmentdetails":
                this.assessmentDetails = event.detail;
                break;
            case "sectiondetails":
                this.sections = event.detail;
                break;
            case "sectiondata":
                this.sectionData = event.detail;
                break;
            case "completionfieldupdate":
                this.fieldUpdate = event.detail;
                break;
            case "scoringdata":
                this.scoringData = event.detail;
                break;
        }
        this.dispatchEvent(new CustomEvent('stepdata', {
            detail: {
                'eventName': event.type,
                'data': event.detail
            }
        }));
    }

    handleEdit(event){
        this.dispatchEvent(new CustomEvent('editdata', {
            detail: event.detail
        }));
    }

    @api
    handleModules(module){
        let activeModule = module.findIndex(m => m.class == 'active');
        if(module[activeModule].name == 'Assessment Details'){
            this.isAssessmentDetails = true;
        }else{
            this.isAssessmentDetails = false;
        }
        if(module[activeModule].name == 'Sections'){
            this.isCreateSections = true;
        }else{
            this.isCreateSections = false;
        }
        if(module[activeModule].name == 'Questions'){
            this.isSectionHandler = true;
        }else{
            this.isSectionHandler = false;
        }
        if(module[activeModule].name == 'Field Update'){
            this.isOnCompletion = true;
        }else{
            this.isOnCompletion = false;
        }
        if(module[activeModule].name == 'Scoring'){
            this.isScoreTranslation = true;
        }else{
            this.isScoreTranslation = false;
        }
        if(module[activeModule].name == 'Summary'){
            this.isSummary = true;
        }else{
            this.isSummary = false;
        }
    }
}