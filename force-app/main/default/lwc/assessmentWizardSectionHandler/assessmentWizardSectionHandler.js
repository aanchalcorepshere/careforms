import { LightningElement, api, track } from 'lwc';

export default class AssessmentWizardSectionHandler extends LightningElement {
    @api selectedSections;
    /* @api objectName;
    @api needScoring;
    @api needSections; */
    @api assessmentDetails;
    @api isSubmit;
    @track sectionData;
    currentSection;
    currentSectionSequence;
    @api existingSectionData;
    isModalOpen = false;
    questionList = [];
    localExistingData=[];

    connectedCallback() {
        let tempExistingData = [];
        if (!this.assessmentDetails.needSections) {
            this.sectionData = [
                {
                    secName: "Default Section",
                    serial: 1,
                    questionData : []
                }
            ];
        } else {
            this.sectionData = JSON.parse(JSON.stringify(this.selectedSections));
            this.sectionData.forEach(section => {
                section.questionData = []
            })
        }
        if (this.existingSectionData && this.existingSectionData.length) {
            this.existingSectionData.forEach(existingSection => {
                this.sectionData.forEach(section => {
                    if(section.secName == existingSection.secName){
                        section.questionData = existingSection.questionData;
                    }
                })
            })
        }
        this.dispatchEvent(new CustomEvent('sectiondata', {
            detail: this.sectionData
        }));
    }

    handleAddQuestions(event) {
        this.isModalOpen = true;
        this.currentSection = event.currentTarget.dataset.sectionName;
        this.currentSectionSequence = event.currentTarget.dataset.sectionSequence;
    }

    getQuestions() {
        let questions = this.template.querySelector('c-assessment-wizard-question-selection').onSubmit();

        this.isModalOpen = false;
        let sectionPos = this.sectionData.findIndex(x => x.secName == this.currentSection);
        let selectedQuestions = JSON.parse(JSON.stringify(this.sectionData[sectionPos].questionData));
        if (questions.length) {
            let seq = selectedQuestions.length+1;
            questions.forEach(ques => {
                let tempQues = {};
                tempQues.level = "level1";
                tempQues.parent = "none";
                tempQues.grandparent = "none";
                tempQues.quesId = ques.quesId;
                tempQues.quesText = ques.quesText;
                tempQues.dataType = ques.dataType;
                tempQues.quesAnsOptions = ques.ansOps;
                tempQues.sequence = seq;
                tempQues.sfSeq = seq++;
                tempQues.score = [];
                tempQues.section = this.currentSection;
                tempQues.sectionSequence = this.currentSectionSequence;
                tempQues.unique = this.currentSection+'_'+tempQues.level+'_'+ques.quesId+'_'+tempQues.sfSeq;
                tempQues.dependentAllowed = true;
                if (ques.quesAnsOpList) {
                    tempQues.dependentQuesData = [];
                    ques.quesAnsOpList.forEach(depQues => {
                        let tempDepQues = {};
                        tempDepQues.ansOpId = depQues.Id;
                        tempDepQues.ansOpText = depQues.caresp__Answer_Text__c;
                        tempDepQues.dependentQuesList = [];
                        tempDepQues.score = 0;
                        tempQues.dependentQuesData.push(tempDepQues);
                    });
                }
                //if(this.sectionData[sectionPos].questionData.findIndex(x => x.quesId == tempQues.quesId) == -1){
                    selectedQuestions.push(tempQues);
                    //console.log("tempQues >> ",JSON.stringify(tempQues));
                /* }else{
                    alert("Duplicate Question ! "+tempQues.quesText);
                } */
            })
        }
        this.sectionData[sectionPos].questionData = [...selectedQuestions];
        this.dispatchEvent(new CustomEvent('sectiondata', {
            detail: this.sectionData
        }));
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleAssessmentQuesDeletion(event){
        this.dispatchEvent(new CustomEvent('aqtobedeleted', {
            detail: event.detail
        }));
    }

    handleQuestions(event) {
        console.log("handleQuestions start");
        let quesData = event.detail.questions;
        console.log("quesData >> ",JSON.stringify(quesData));
        let section = '';
        section = event.detail.section;
        let sectionPos = this.sectionData.findIndex(x => x.secName == section);
        this.sectionData[sectionPos].questionData = quesData;
        this.dispatchEvent(new CustomEvent('sectiondata', {
            detail: this.sectionData
        }));
    }
}