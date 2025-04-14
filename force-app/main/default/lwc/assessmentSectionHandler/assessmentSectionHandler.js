import { LightningElement, api, wire, track } from 'lwc';
import checkLookupOnOutcomeObject from '@salesforce/apex/AssessmentQuestionnaireController.checkLookupOnOutcomeObject';
import getQuestions from '@salesforce/apex/AssessmentQuestionnaireController.getQuestions';
import getAssessments from '@salesforce/apex/AssessmentQuestionnaireController.getAssessments';
import getDraftAssessments from '@salesforce/apex/AssessmentQuestionnaireController.getDraftAssessments';
import getAssessmentDetails from '@salesforce/apex/AssessmentQuestionnaireController.getAssessmentDetails';
import getDraftAssessmentDetails from '@salesforce/apex/AssessmentQuestionnaireController.getDraftAssessmentDetails';
import stepProgressCss from '@salesforce/resourceUrl/stepProgressCss';
import saveResponses from '@salesforce/apex/AssessmentQuestionnaireController.saveResponses';
import saveDraftResponses from '@salesforce/apex/AssessmentQuestionnaireController.saveDraftResponses';
import { loadStyle } from 'lightning/platformResourceLoader';
import userId from '@salesforce/user/Id';

export default class AssessmentSectionHandler extends LightningElement {
    @api recordId;
    @api objectName;
    @track questions;
    @track assessments;
    @track clients;
    @track draftAssessments;
    @track selectedDraftAssessment;
    @track selectedDraftOutcome;
    @track sections = [];
    selectedDraftOutcomeId;
    initialObject;
    referralId;
    uID=userId;
    selectedClient;
    hasSections = false;
    selectedAssessmentId;
    selectedAssessmentName;
    selectedAssessment;
    isLoading = false;
    isSelectAssessment = true;
    isLaunchAssessment = false;
    isAssessmentDetails = false;
    selectedDate;
    //isSubmit = false;
    error;
    progressStyle = stepProgressCss;
    userProfile;
    //pURL=portalURL;
    hidePrevious = true;
    refreshDraft = false;
    refreshAssessment = false;
    showAssessmentList = false;

    constructor() {
        super();
        Promise.all([loadStyle(this, this.progressStyle)]);
    }

    connectedCallback(){
        console.log('Assessment Section Handler');
        console.log('objName' + this.objectName);
        checkLookupOnOutcomeObject({objName : this.objectName})
        .then(result => {
            if(result){
                if(result.startsWith("No such column")){
                    this.error = 'Outcome object doesn\'t have lookup for '+this.objectName+'. Please create lookup field for '+this.objectName+' on Outcome (Outcome__c) object as '+this.objectName+'__c';
                }else{
                    getAssessments({ objectName: '$objectName' })
                    .then(assessmentResult => {
                        if(assessmentResult){
                            console.log('assessmentResult >> ', assessmentResult);
                            let tempData = JSON.parse(assessmentResult);
                            this.assessments = tempData;
                            if (!this.assessments.length) {
                                this.dispatchEvent(new CustomEvent('cancelclick'));
                                alert("No assessments have been created for this object !");
                            }else{
                                this.showAssessmentList = true;
                            }
                        }
                    })
                    .catch(error => {
                        this.error = JSON.stringify(error);
                        console.error('Error >> '+JSON.stringify(error));
                    })
                }
            }
        })
        .catch(error => {
            this.error = JSON.stringify(error);
            console.error('Error >> '+JSON.stringify(error));
        })
    }

    @wire(getDraftAssessments, { recordId: '$recordId' })
    wiredDraftAssessments({ error, data }) {
        if (data) {
            console.log('data >> ', JSON.stringify(data));
            let tempData = data;
            this.draftAssessments = tempData;
        } else if (error) {
            this.error = JSON.stringify(error);
        }
    }

    get showDraftArea() {
        return (this.draftAssessments && this.draftAssessments.length) ? true : false;
    }

    topFunction(){
        let containerChoosen = this.template.querySelector('.bringtotop');
        containerChoosen.scrollIntoView();
    }

    get isSubmit() {
        let activeIndex = this.sections.findIndex(x => x.class == 'active');
        if (activeIndex == this.sections.length - 1) {
            return true;
        } else {
            return false;
        }
    }

    get showPrevious() {
        if(this.hasSections){
            let activeIndex = this.sections.findIndex(x => x.class == 'active');
            if (activeIndex == 0) {
                return false;
            } else {
                return true;
            }
        }
    }

    handleChange(event) {
        let targetName = event.target.name;
        if (targetName == 'assessments') {
            this.selectedDraftOutcomeId = undefined;
            this.draftAssessments = JSON.parse(JSON.stringify(this.draftAssessments));
            this.refreshDraft = true;
            this.delayTimeout = setTimeout(() => {
                this.refreshDraft = false;
            }, 10);
            let temp = event.target.value;
            this.selectedAssessmentId = temp.substr(temp.indexOf('|') + 1, temp.length);
            this.selectedAssessmentName = temp.substr(0, temp.indexOf('|'));
            console.log("selectedAssessmentName >> " + this.selectedAssessmentName);
        } else if (targetName == 'select') {
            if(this.selectedAssessmentId){
                this.error = undefined;
                getAssessmentDetails({ assessmentId: this.selectedAssessmentId })
                .then(result => {
                    this.selectedAssessment = result;
                })
                .catch(error => {
                    this.error = JSON.stringify(error);
                })
                this.isSelectAssessment = false;
                this.isLaunchAssessment = false;
                this.isAssessmentDetails = true;
            }else{
                this.error = 'Select an Assessment.';
            }
        } else if (targetName == 'draftassessments') {
            this.selectedAssessmentId = undefined;
            this.assessments = JSON.parse(JSON.stringify(this.assessments));
            this.refreshAssessment = true;
            this.delayTimeout = setTimeout(() => {
                this.refreshAssessment = false;
            }, 10);
            this.selectedDraftOutcomeId = event.target.value;
        } else if (targetName == 'launchDraft') {
            if(this.selectedDraftOutcomeId){
                this.error = undefined;
                getDraftAssessmentDetails({ outcomeId: this.selectedDraftOutcomeId })
                .then(result => {
                    this.isDraft = true;
                    console.log("DRAFT DATA >> ", JSON.stringify(result));
                    this.selectedDraftAssessment = result.assessmentRec;
                    this.selectedAssessmentName = this.selectedDraftAssessment.Name;
                    this.selectedAssessmentId = this.selectedDraftAssessment.Id;
                    this.selectedAssessment = this.selectedDraftAssessment;
                    this.selectedDraftOutcome = result.outcomeRec;
                    this.selectedDraftOutcomeId = this.selectedDraftOutcome.Id;
                    this.selectedClient = this.selectedDraftOutcome.caresp__Client__c;
                    this.referralId = this.selectedDraftOutcome.caresp__Referral__c;
                    this.selectedDate = this.selectedDraftOutcome.caresp__Assessment_Date__c;
                    this.initialObject = this.selectedDraftOutcome.caresp__Init_Object__c;
                    this.sections = JSON.parse(this.selectedDraftOutcome.caresp__Draft_Responses__c);
                    let checkSections = this.sections.findIndex(x => x.sectionName == 'Default Section');
                    if (checkSections == -1) {
                        this.hasSections = true;
                    } else {
                        this.hasSections = false;
                    }
                    this.sections.forEach(section => {
                        if (section.sectionSequence == 1) {
                            section.class = "active";
                            section.flag = true;
                        } else {
                            section.class = "";
                            section.flag = false;
                        }
                    })
                    this.isSelectAssessment = false;
                    this.isLaunchAssessment = true;
                    this.isAssessmentDetails = false;
                })
                .catch(error => {
                    this.error = JSON.stringify(error);
                })
            }else{
                this.error = 'Select an Assessment.';
            }
        }

    }

    handleStart(event) {
        this.selectedDate = event.detail.selectedDate;
        //this.selectedClient = event.detail.selectedClient;
        if (this.selectedDate) {
            this.error = undefined;
            getQuestions({ assessmentId: this.selectedAssessmentId })
                .then(result => {
                    let tempData = JSON.parse(result);
                    this.questions = tempData;
                    console.log("this.questions ", JSON.stringify(this.questions));
                    let checkSections = this.questions.findIndex(x => x.section == 'Default Section');
                    console.log("checkSections ", checkSections);
                    if (checkSections == -1) {
                        this.hasSections = true;
                        this.questions.forEach(question => {
                            if (this.sections.findIndex(x => x.sectionName == question.section) == -1) {
                                let temp = {};
                                temp.sectionName = question.section;
                                temp.sectionSequence = question.sectionSequence;
                                temp.questionData = [];
                                temp.valid = false;
                                this.sections.push(temp);
                            }
                        })
                        this.sections.sort(function (a, b) {
                            return a.sectionSequence - b.sectionSequence;
                        }
                        );
                        this.sections.forEach(section => {
                            if (section.sectionSequence == 1) {
                                section.class = "active";
                                section.flag = true;
                            } else {
                                section.class = "";
                                section.flag = false;
                            }
                        })
                        this.sections.forEach(section => {
                            this.questions.forEach(question => {
                                if (question.sectionSequence == section.sectionSequence) {
                                    section.questionData.push(question);
                                }
                            })
                        })
                        console.log("this.sections >> ", JSON.stringify(this.sections));
                    } else {
                        this.hasSections = false;
                        this.sections = [];
                        let tempSection = {};
                        tempSection.sectionName = "Default";
                        tempSection.sectionSequence = 1;
                        tempSection.class = 'active';
                        tempSection.flag = true;
                        tempSection.questionData = this.questions;
                        this.sections.push(tempSection);
                    }
                    this.isSelectAssessment = false;
                    this.isLaunchAssessment = true;
                    this.isAssessmentDetails = false;
                })
                .catch(error => {
                    this.error = JSON.stringify(error);
                    console.log("Error ## ", JSON.stringify(error));
                })
        }else{
            this.error = "Assessment Date and Client must be selected."
        }
    }

    handleNav(event) {
        let buttonName = event.target.name;
        let activeIndex = this.sections.findIndex(x => x.class == 'active');
        if (buttonName == 'next') {
            this.handleValidations(this.sections[activeIndex]);
            if (activeIndex !== this.sections.length - 1 && this.sections[activeIndex].valid) {
                this.sections[activeIndex].class = 'completed';
                this.sections[activeIndex].flag = false;
                this.sections[activeIndex + 1].class = 'active';
                this.sections[activeIndex + 1].flag = true;
                this.topFunction();
            }
        } else {
            if (activeIndex !== 0) {
                this.sections[activeIndex].class = '';
                this.sections[activeIndex].flag = false;
                this.sections[activeIndex - 1].class = 'active';
                this.sections[activeIndex - 1].flag = true;
                this.topFunction();
            }
        }
    }

    handleDraft() {
        let confirmation = confirm('Are you sure you want to submit the Draft? \n You can complete the Assessment by clicking Launch Assessment again.');
        if (confirmation == true) {
            console.log('objName >>>>' +this.objectName);
            console.log('objName >>>>' +this.recordId);
            saveDraftResponses({ recordId: this.recordId, assessmentId: this.selectedAssessmentId, assessmentName: this.selectedAssessmentName, assessmentDate: this.selectedDate, objName: this.objectName, draftResponses: JSON.stringify(this.sections), draftOutcomeId: this.selectedDraftOutcomeId })
                .then(result => {
                     console.log('objName >>>>' +this.objectName);
                    alert("Draft Saved.");
                    location.reload();
                    //this.dispatchEvent(new CustomEvent('cancelclick'));
                })
                .catch(error => {
                    this.error = JSON.stringify(error);
                })
        }
    }

    handleResponses(event) {
        this.error = undefined;
        let activeSectionResponses = event.detail;
        let secPos = this.sections.findIndex(x => x.sectionName == activeSectionResponses.section);
        this.sections[secPos].questionData = activeSectionResponses.questionsData;
    }

    handleSubmit(event) {
        if (event.target.name === 'cancel') {
            this.dispatchEvent(new CustomEvent('cancelclick'));
        } if (event.target.name === 'submit') {
            let activeIndex = this.sections.findIndex(x => x.class == 'active');
            this.handleValidations(this.sections[activeIndex]);
            if (this.sections[activeIndex].valid) {
                let confirmation = confirm('Are you sure you want to submit the responses?');
                if (confirmation == true) {
                    let finalQuesList = [];
                    this.sections.forEach(section => {
                        section.questionData.forEach(ques => {
                            finalQuesList.push(ques);
                        })
                    })
                    console.log('responses >> ',JSON.stringify(finalQuesList));
                    saveResponses({ recordId: this.recordId, objName: this.objectName, assessmentId: this.selectedAssessmentId, assessmentName: this.selectedAssessmentName, responses: JSON.stringify(finalQuesList), assessmentDate: this.selectedDate, draftOutcomeId: this.selectedDraftOutcomeId })
                        .then(result => {
                            let outcomeId = result;
                            window.location.replace("/"+outcomeId);
                        })
                        .catch(error => {
                            this.error = JSON.stringify(error);
                        })
                }
            }
        }
    }

    handleValidations(activeSection) {
        let flag = false;
        var isIncorrectPhoneFormat = false;
        if (activeSection.questionData) {
            activeSection.questionData.forEach(ques => {
                if (!flag) {
                    if (ques.required && ques.response == "") {
                        flag = true;
                    } else if(ques.isPhone){
                        if(ques.response.length > 0){
                            isIncorrectPhoneFormat = this.isPhone(ques.response);
                            if(isIncorrectPhoneFormat){
                                flag = true;
                            }
                        }
                    } else {
                        flag = false;
                    }
                    if (ques.dependentQuestions) {
                        ques.dependentQuestions.forEach(dependent => {
                            if (dependent.required && dependent.response == "") {
                                flag = true;
                            } else if(dependent.isPhone){
                                if(dependent.response.length > 0){
                                    isIncorrectPhoneFormat = this.isPhone(dependent.response);
                                    if(isIncorrectPhoneFormat){
                                        flag = true;
                                    }
                                }
                            }else {
                                flag = false;
                            }
                            if (dependent.dependentDependentQuestions) {
                                dependent.dependentDependentQuestions.forEach(dependentDependent => {
                                    if (dependentDependent.required && dependentDependent.response == "") {
                                        flag = true;
                                    } else if(dependentDependent.isPhone && dependentDependent.response != ""){
                                        if(dependentDependent.response.length > 0){
                                            isIncorrectPhoneFormat = this.isPhone(dependentDependent.response);
                                            if(isIncorrectPhoneFormat){
                                                flag = true;
                                            }
                                        }
                                    }else {
                                        flag = false;
                                    }
                                })
                            }
                        })
                    }
                }
            })

            if (flag) {
                activeSection.valid = false;
                if(isIncorrectPhoneFormat){
                    this.error = "Please enter phone number in correct format i.e. 111-222-3333.";
                }else{
                    this.error = "Please answer all required questions.";
                }
                setTimeout(() => { this.error = undefined }, 3000);
            } else {
                activeSection.valid = true;
                this.error = undefined;
            }
            console.log("this.error >> ", this.error);
        }
    }

    isPhone(phoneNumber){
		const phoneNumberRegex = /^\d{3}-\d{3}-\d{4}$/;

		if (phoneNumberRegex.test(phoneNumber)) {
			return false;
		} else {
			return true;
		}
	}
}