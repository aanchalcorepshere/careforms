import { LightningElement, wire, track, api } from 'lwc';
import getDependentQuestions from '@salesforce/apex/AssessmentQuestionnaireController.getDependentQuestions';
import getAssessments from '@salesforce/apex/AssessmentQuestionnaireController.getAssessments';
import saveResponses from '@salesforce/apex/AssessmentQuestionnaireController.saveResponses';
import { fireEvent } from 'c/pubsub';


export default class AssessmentLauncher extends LightningElement {
    @api recordId;
    @api objectName;
    @api questionsFromSectionHandler;
    @track questions;
    @track assessments;
    selectedAssessmentId;
    selectedAssessmentName;
    isLoading = false;
    isSelectAssessment = true;
    isLaunchAssessment = false;
    isSubmit = false;
    error;
    @api section;

    @wire(getAssessments,{objectName : '$objectName'})
    wiredQuestions({ error, data }) {
        if(data){
            console.log('data >> ',data);
            let tempData = JSON.parse(data);
            this.assessments = tempData;
            if(!this.assessments.length){
                this.dispatchEvent(new CustomEvent('cancelclick'));
                alert("No assessments have been created for this object !");
            }
        }else if(error){
            this.error = error;
        }
    }

    connectedCallback(){
        console.log("Record id ",this.recordId);
        console.log("objectName ",this.objectName);
        this.questions = JSON.parse(JSON.stringify(this.questionsFromSectionHandler))
        this.dispatchEvent(new CustomEvent('responses', {
            detail: {
                "section" : this.section,
                "questionsData" : this.questions
            }
        }));
    }

    handleResponse(event){
        let resp = event.detail;
        console.log('resp >>> ',JSON.stringify(resp));
        if(resp.level === 'level1'){
            this.questions.forEach(ques => {
                if(ques.assessmentQuesId === resp.assQuesId){
                    if(resp.isCheckbox){
                        let tempResp = '';
                        resp.selectedValues.forEach(val => {
                            tempResp = val.substr(val.indexOf('|')+1, val.length)+'|'+tempResp;
                        });
                        ques.response = tempResp.slice(0, -1);
                        ques.selectedValue = resp.selectedValues;
                    }else if(resp.isText || resp.isNumber || resp.isLongText){
                        ques.response = resp.selectedValues;
                        ques.selectedValue = resp.selectedValues;
                    }else{
                        ques.response = resp.selectedValues.substr(resp.selectedValues.indexOf('|')+1, resp.selectedValues.length);
                        ques.responseId = resp.selectedValues.substr(0, resp.selectedValues.indexOf('|'));
                        ques.selectedValue = resp.selectedValues;
                    }
                    console.log("checkbox resp >> ",ques.response);
                }
            });
        }else if(resp.level === 'level2'){
            let parent = this.questions.findIndex(q => q.assessmentQuesId === resp.parent);
            console.log("level2 parent >> ",parent);
            let subQues = this.questions[parent].dependentQuestions;
            subQues.forEach(ques => {
                if(ques.assessmentQuesId === resp.assQuesId){
                    if(resp.isCheckbox){
                        let tempResp = '';
                        resp.selectedValues.forEach(val => {
                            tempResp = val.substr(val.indexOf('|')+1, val.length)+'|'+tempResp;
                        });
                        ques.response = tempResp.slice(0, -1);
                        ques.selectedValue = resp.selectedValues;
                    }else if(resp.isText || resp.isNumber || resp.isLongText){
                        ques.response = resp.selectedValues;
                        ques.selectedValue = resp.selectedValues;
                    }else{
                        ques.response = resp.selectedValues.substr(resp.selectedValues.indexOf('|')+1, resp.selectedValues.length);
                        ques.selectedValue = resp.selectedValues;
                    }
                    console.log("checkbox resp >> ",ques.response);
                }
            });
            this.questions[parent].dependentQuestions = [...subQues];
        }else if(resp.level === 'level3'){
            let grandParent = this.questions.findIndex(q => q.assessmentQuesId === resp.grandParent);
            let parent = this.questions[grandParent].dependentQuestions.findIndex(q => q.assessmentQuesId === resp.parent);
            let subQues = this.questions[grandParent].dependentQuestions[parent].dependentDependentQuestions;
            subQues.forEach(ques => {
                if(ques.assessmentQuesId === resp.assQuesId){
                    if(resp.isCheckbox){
                        let tempResp = '';
                        resp.selectedValues.forEach(val => {
                            tempResp = val.substr(val.indexOf('|')+1, val.length)+'|'+tempResp;
                        });
                        ques.response = tempResp.slice(0, -1);
                        ques.selectedValue = resp.selectedValues;
                    }else if(resp.isText || resp.isNumber || resp.isLongText){
                        ques.response = resp.selectedValues;
                        ques.selectedValue = resp.selectedValues;
                    }else{
                        ques.response = resp.selectedValues.substr(resp.selectedValues.indexOf('|')+1, resp.selectedValues.length);
                        ques.selectedValue = resp.selectedValues;
                    }
                    console.log("checkbox resp >> ",ques.response);
                }
            });

            this.questions[grandParent].dependentQuestions[parent].dependentDependentQuestions = [...subQues];
        }
        if(resp.isRadio || resp.isCombobox){
            this.isLoading = true;
            let selectedAnsId = resp.selectedValues.substr(0, resp.selectedValues.indexOf('|'));
            console.log("selectedAnsId >> ",selectedAnsId);
            getDependentQuestions({grandParent:resp.parent,parent:resp.assQuesId,ansOp:selectedAnsId,level:resp.level })
            .then(result => {
                //console.log('result > ',result);
                if(result){
                    if(resp.level == "level1"){
                        let parentPos = this.questions.findIndex(ques => ques.assessmentQuesId == resp.assQuesId);
                        this.questions[parentPos].dependentQuestions = JSON.parse(result);
                    }else if(resp.level == "level2"){
                        let grandParentPos = this.questions.findIndex(ques => ques.assessmentQuesId == resp.parent);
                        console.log('grandParentPos >> ',grandParentPos);
                        let parentPos = this.questions[grandParentPos].dependentQuestions.findIndex(ques => ques.assessmentQuesId == resp.assQuesId);
                        console.log('parentPos >> ',parentPos);
                        this.questions[grandParentPos].dependentQuestions[parentPos].dependentDependentQuestions = JSON.parse(result);
                    }
                }
            })
            .catch(error => {
                this.error = error;
            });
            this.isLoading = false;
        }
        this.dispatchEvent(new CustomEvent('responses', {
            detail: {
                "section" : this.section,
                "questionsData" : this.questions
            }
        }));
    }
}