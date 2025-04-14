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
        //console.log("this.localEditData >> ",this.localEditData);
        if(this.localEditData){
            this.assessmentDetails = JSON.parse(this.localEditData.caresp__Assessment_Detail_JSON__c);
            if(this.localEditData.caresp__Section_JSON__c){
                this.sections = JSON.parse(this.localEditData.caresp__Section_JSON__c);
            }
            this.sectionData = JSON.parse(this.localEditData.caresp__Questions_JSON__c);
            if(this.localEditData.caresp__Scoring_JSON__c){
                this.scoringData = JSON.parse(this.localEditData.caresp__Scoring_JSON__c);
            }
            if(this.localEditData.caresp__Field_Update_JSON__c){
                this.fieldUpdate = JSON.parse(this.localEditData.caresp__Field_Update_JSON__c);
            }
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