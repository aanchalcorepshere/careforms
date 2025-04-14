import { LightningElement, track, wire, api } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import QUESTION_OBJECT from '@salesforce/schema/Question__c';
import DATA_TYPE_FIELD from '@salesforce/schema/Question__c.Question_Data_type__c';
import QUESTION_CATEGORY_FIELD from '@salesforce/schema/Question__c.Question_Category__c';
import createQuestion from '@salesforce/apex/CreateNewQuestionCtrl.createQuestion';
import updateQuestion from '@salesforce/apex/CreateNewQuestionCtrl.updateQuestion';
import createAnsOptions from '@salesforce/apex/CreateNewQuestionCtrl.createAnsOptions';
import getQuestionData from '@salesforce/apex/CreateNewQuestionCtrl.getQuestionData';
import checkDuplicate from '@salesforce/apex/CreateNewQuestionCtrl.checkDuplicate';
import checkEditable from '@salesforce/apex/CreateNewQuestionCtrl.checkEditable';

export default class CreateNewQuestion extends LightningElement {

    @api isEdit = false;
    @api editRecId;
    editQuestionData;
    questionText;
    existingAnswers=[];
    isDependent = false;
    @track selectedAnswers = [];
    @track selectedDataType = '';
    //@api selDataType = '';
    @track selectedQuestionCategory;
    showLoadingSpinner=false;
    qbId;
    showButton = false;
    showLookup = true;
    selectedQuestion;
    showEditError = false;
    editWarning = 'Editing this Question Answer Option will update this QAO for all existing Assessments that are NOT used in a Draft/Completed Assessment';

    @wire(getObjectInfo, { objectApiName: QUESTION_OBJECT })
    objectInfo;
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: DATA_TYPE_FIELD})
    DataTypeValues;
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: QUESTION_CATEGORY_FIELD})
    QuestionCategoryValues;
    error = '';
    connectedCallback(){
        console.log('this.isEdit >> '+this.isEdit);
        if(this.isEdit){
            this.showLoadingSpinner = true;
            checkEditable({recId : this.editRecId})
            .then(result => {
                let isEditable = result;
                if(isEditable){
                    getQuestionData({recordId : this.editRecId})
                    .then(result => {
                        //console.log("result >> ",result);
                        this.editQuestionData = result;
                        this.selectedDataType = result.quesDataType;
                        //this.selDataType = result.quesDataType;
                        this.selectedQuestionCategory = JSON.parse(JSON.stringify(result.quesCategory));
                        console.log("result.quesCategory >> ",typeof result.quesCategory);
                        let catDataType = typeof result.quesCategory;
                        console.log("catDataType >> ",catDataType);
                        if(result.quesCategory && result.quesCategory.length){
                            if (catDataType != undefined){
                                if(catDataType == 'string'){
                                    this.selectedQuestionCategory = [];
                                    this.selectedQuestionCategory.push(result.quesCategory);
                                }else{
                                    this.selectedQuestionCategory = [];
                                    result.quesCategory.forEach(cat => {
                                        this.selectedQuestionCategory.push(cat);
                                    })
                                }
                            }
                        }
                        this.questionText = result.quesText;
                        this.isDependent = result.isDependent;
                        if(result.ansList && result.ansList.length){
                            result.ansList.forEach(data => {    
                                this.existingAnswers.push({
                                    order : data.caresp__Sequence__c,
                                    Id : data.caresp__Answer__c,
                                    caresp__Answer_Text__c : data.caresp__Answer_Text__c
                                });
                            });
                            this.selectedAnswers = this.existingAnswers;
                        }
                        this.showLoadingSpinner = false;
                    })
                    .catch(error => {
                        this.error = error;
                        console.log("ERROR OCCURED # "+error);
                        this.showLoadingSpinner = false;
                    })
                }else{
                    console.log("else condition");
                    this.dispatchEvent(new CustomEvent('editerror'));
                }
            })
            .catch(error => {
                this.error = JSON.stringify(error);
            })
        }
    }

    handleEditYes(){
        this.editWarning = undefined;
    }

    handleEditNo(){
        this.editWarning = undefined;
        const saveEvent = new CustomEvent("saveevent");
        this.dispatchEvent(saveEvent);
    }

    handleQuesText(event){
        this.showButton = true;
    }

    handleSuccess(event){
        this.showButton = false;
        this.qbId = "";
        this.showLookup = false;
        setTimeout(() => {this.showLookup = true}, 1000);
    }

    lookupRecord(event){
        this.selectedQuestion = event.detail.selectedRecord;
    }

    get ifEdit(){
        if(this.isEdit==="true"){
            return true;
        }
        else{
            return false;
        }
    }
    
    get quesWithAns(){
        if(this.selectedDataType==='Radio Box' || this.selectedDataType==='Checkbox' || this.selectedDataType==='Picklist'){
            return true;
        }else{
            return false;
        }
    }

    handleAnswersSelection(event){
        this.selectedAnswers = event.detail;
    }

    handleChange(event){
        if(event.target.name==='datatype'){
            this.selectedDataType = event.target.value;
        }else if(event.target.name==='questioncategory'){
            this.selectedQuestionCategory = event.target.value;
        }else if(event.target.name==='isdependent'){
            this.isDependent = event.target.checked;
        }
    }

    handleBlur(event){
        this.questionText = event.target.value;
    }

    handleSave(){
        if(!this.selectedDataType){
            this.error = "Please select Data Type.";
        }else if(!this.selectedQuestionCategory){
            this.error = "Please select Question Category.";
        }else if((this.selectedDataType==='Radio Box' || this.selectedDataType==='Checkbox'|| this.selectedDataType==='Picklist') && !this.selectedAnswers.length){
            this.error = "Please select Answer Options with selected Data Type.";
        }else if(!this.selectedQuestion || !this.selectedQuestion.Id){
            this.error = "Please search for one of existing questions and select one.";
        }else if(!this.selectedDataType){
            this.error = "Please select Data Type.";
        }else{
            let ansOpList = [];
            if(this.selectedAnswers && this.selectedAnswers.length){
                this.selectedAnswers.forEach(ans => {
                    ansOpList.push(ans.Id);
                })
            }

            console.log("ansOpList >> ",JSON.stringify(ansOpList));

            let inValid = false;
            checkDuplicate({quesBankId : this.selectedQuestion.Id, dataType : this.selectedDataType, ansOptions : ansOpList})
            .then(result => {
                inValid = result;
                console.log("inValid >> ",inValid);
                console.log("this.selectedQuestion >> ",JSON.stringify(this.selectedQuestion));
                if(inValid != 'Duplicate'){
                    this.showLoadingSpinner = true;
                    this.error = '';
                    let ques = { 'sobjectType': 'caresp__Question__c' };
                    ques.caresp__Question_Text__c = this.selectedQuestion.caresp__Question_Text__c;
                    ques.caresp__Question_Data_type__c = this.selectedDataType;
                    ques.caresp__Question_Category__c = this.selectedQuestionCategory;
                    //ques.Question_Bank__c = this.selectedQuestion.Id;
                    ques.caresp__Is_Dependent__c = this.isDependent;
                    ques.caresp__Active__c = true;
                    console.log("Ques >> ",JSON.stringify(ques));
                    console.log("selectedAnswers >> ",JSON.stringify(this.selectedAnswers));
                    //case - EDIT
                    console.log("this.isEdit >> ",this.isEdit);
                    if(this.isEdit){
                        console.log("this.editRecId >> ",this.editRecId);
                        ques.Id = this.editRecId;
                        updateQuestion({question: ques})
                        .then(result => {
                            let quesId = result;
                            let ansOptions=[];
                            if(this.selectedAnswers.length && (this.selectedDataType==='Radio Box' || this.selectedDataType==='Checkbox'|| this.selectedDataType==='Picklist')){
                                this.selectedAnswers.forEach(ans => {
                                    let ansOption = {'sobjectType':'caresp__Question_Answer_Option__c'}
                                    ansOption.caresp__Question__c = quesId;
                                    ansOption.caresp__Answer__c = ans.Id;
                                    ansOption.caresp__Sequence__c = ans.order;
                                    ansOptions.push(ansOption);
                                });
                                createAnsOptions({ansOptions : ansOptions, isEdit : this.isEdit})
                                .then(result => {
                                    const saveEvent = new CustomEvent("saveevent");
                                    this.dispatchEvent(saveEvent);
                                    this.showLoadingSpinner = false;
                                })
                                .catch(error => {
                                    console.log("Some Error Occured."+error);
                                    this.showLoadingSpinner = false;
                                })
                            }
                            else{
                                const saveEvent = new CustomEvent("saveevent");
                                this.dispatchEvent(saveEvent);
                                this.showLoadingSpinner = false;
                            }
                        })
                        .catch(error => {
                            console.log("Some Error Occured. # "+JSON.stringify(error));
                            this.showLoadingSpinner = false;
                        })
                    }
                    //case new question
                    else{
                        createQuestion({question: ques})
                        .then(result => {
                            let quesId = result;
                            let ansOptions=[];
                            this.selectedAnswers.forEach(ans => {
                                let ansOption = {'sobjectType':'caresp__Question_Answer_Option__c'}
                                ansOption.caresp__Question__c = quesId;
                                ansOption.caresp__Answer__c = ans.Id;
                                ansOption.caresp__Sequence__c = ans.order;
                                ansOptions.push(ansOption);
                            });
                            console.log("ANS OPTIONS # "+JSON.stringify(ansOptions));
                            if((this.selectedDataType==='Radio Box' || this.selectedDataType==='Checkbox' || this.selectedDataType==='Picklist') && ansOptions.length){
                                createAnsOptions({ansOptions : ansOptions, isEdit : this.isEdit})
                                .then(result => {
                                    const saveEvent = new CustomEvent("saveevent");
                                    this.dispatchEvent(saveEvent);
                                    this.showLoadingSpinner = false;
                                })
                                .catch(error => {
                                    console.log("Some Error Occured."+error);
                                    this.showLoadingSpinner = false;
                                })
                            }else{
                                const saveEvent = new CustomEvent("saveevent");
                                this.dispatchEvent(saveEvent);
                            }
                        }) 
                        .catch(error => {
                            console.log("Some Error Occured. # "+JSON.stringify(error));
                            this.showLoadingSpinner = false;
                        })
                        //this.showLoadingSpinner = false;
                    }
                }else{
                    this.error = "This Question Answer Option already exists.";
                }
            })
            .catch(error => {
                console.log("Error >> ",JSON.stringify(error));
                this.error = JSON.stringify(error);
            })
        }
        
    }

    handleCancel(){
        const saveEvent = new CustomEvent("saveevent");
        this.dispatchEvent(saveEvent);
    }
    get showLoadingSpinner(){
        return !this.answers.data && !this.answers.error
    }
    
}