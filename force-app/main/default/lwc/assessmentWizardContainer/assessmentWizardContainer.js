import { api, LightningElement, track, wire } from 'lwc';
import stepProgressCss from '@salesforce/resourceUrl/stepProgressCss';
import { loadStyle } from 'lightning/platformResourceLoader';
import checkAssessmentNameDuplicate from '@salesforce/apex/AssessmentWizardController.checkAssessmentNameDuplicate';
import createAssessmentRecord from '@salesforce/apex/AssessmentWizardController.createAssessmentRecord';
import saveQuestions from '@salesforce/apex/AssessmentWizardController.saveQuestions';
import createScoringRecords from '@salesforce/apex/AssessmentWizardController.createScoringRecords';
import updateCompletionFieldData from '@salesforce/apex/AssessmentWizardController.updateCompletionFieldData';
import updateJsonData from '@salesforce/apex/AssessmentWizardController.updateJsonData';
import getEditJson from '@salesforce/apex/AssessmentWizardController.getEditJson';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
//import ORG_URL from '@salesforce/label/c.Org_URL';

export default class AssessmentWizardContainer extends NavigationMixin(LightningElement) {
    progressStyle = stepProgressCss;
    assessmentDetails;
    error;
    selectedQuestions=[];
    questionsList;
    scoringData;
    completionFieldData;
    sections;
    assessmentQuesToBeDeleted;
    @api editAssessmentId='';
    @api isEdit = false;
    @track editAssessmentData;
    currentPageReference;
    renderCmp = true;
    originalModules = [
        {
            name : "Assessment Details",
            class : "active",
            flag : true,
            valid : false
        },
        {
            name : "Questions",
            class : "",
            flag : true,
            valid : false
        },
        {
            name : "Summary",
            class : "",
            flag : true,
            valid : true
        }
    ];

    @track modules = [
        {
            name : "Assessment Details",
            class : "active",
            flag : true,
            valid : false
        },
        {
            name : "Questions",
            class : "",
            flag : true,
            valid : false
        },
        {
            name : "Summary",
            class : "",
            flag : true,
            valid : true
        }
    ]

    constructor () {
        super();
        Promise.all([loadStyle(this, this.progressStyle)]);
    }

    handleClose(){
        let confirmation = confirm('Are you sure you want to close? All unsaved changes will be lost.');
        if(confirmation){
            window.close();
        }
    }

    /* @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            const editVal = currentPageReference.state.c__isEdit;
            const recVal = currentPageReference.state.c__editAssessmentId;
            if (editVal) {
                this.isEdit=editVal;
                this.editAssessmentId=recVal;
                getEditJson({assessmentId:this.editAssessmentId})
                .then(result => {
                    this.editAssessmentData = result;
                    this.assessmentDetails = JSON.parse(this.editAssessmentData.Assessment_Detail_JSON__c);
                    this.handleAssessmentDetails(this.assessmentDetails);
                    if(this.editAssessmentData.Field_Update_JSON__c){
                        this.completionFieldData = JSON.parse(this.editAssessmentData.Field_Update_JSON__c);
                    }
                    this.questionsList = JSON.parse(this.editAssessmentData.Questions_JSON__c);
                    if(this.editAssessmentData.Section_JSON__c){
                        this.sections = JSON.parse(this.editAssessmentData.Section_JSON__c);
                    }
                    if(this.editAssessmentData.Scoring_JSON__c){
                        this.scoringData = JSON.parse(this.editAssessmentData.Scoring_JSON__c);
                    }
                })
                .catch(error => {
                    if(this.error){
                        this.error = JSON.stringify(error);
                        console.error("Error > ",JSON.stringify(error));    
                    }
                })
            }
        }   
    } */

    connectedCallback() {
        if(this.isEdit){
            getEditJson({assessmentId:this.editAssessmentId})
            .then(result => {
                this.editAssessmentData = result;
                console.log("editAssessmentData >> ",JSON.stringify(this.editAssessmentData));
                this.assessmentDetails = JSON.parse(this.editAssessmentData.Assessment_Detail_JSON__c);
                this.handleAssessmentDetails(this.assessmentDetails);
                if(this.editAssessmentData.Field_Update_JSON__c){
                    this.completionFieldData = JSON.parse(this.editAssessmentData.Field_Update_JSON__c);
                }
                this.questionsList = JSON.parse(this.editAssessmentData.Questions_JSON__c);
                console.log('this.questionsList >> ',JSON.stringify(this.questionsList));
                if(this.editAssessmentData.Section_JSON__c){
                    this.sections = JSON.parse(this.editAssessmentData.Section_JSON__c);
                    console.log("sections >> ",JSON.stringify(this.sections));
                }
                if(this.editAssessmentData.Scoring_JSON__c){
                    this.scoringData = JSON.parse(this.editAssessmentData.Scoring_JSON__c);
                }
            })
            .catch(error => {
                if(this.error){
                    this.error = JSON.stringify(error);
                    console.error("Error > ",JSON.stringify(error));    
                }
            })
        }
    }

    get firstPage(){
        if(this.modules[this.modules.findIndex(x => x.class == 'active')].name == 'Assessment Details'){
            return true;
        }else{
            return false;
        }
    }

    get isSubmit(){
        if(this.modules[this.modules.findIndex(x => x.class == 'active')].name == 'Summary'){
            return true;
        }else{
            return false;
        }
    }

    async handleNav(event){
        let buttonName = event.target.name;
        let activeModulePos = this.modules.findIndex(module => module.class==="active");
        this.modules[activeModulePos].valid = false;
        await this.handleValidations(this.modules[activeModulePos]);
        if(buttonName === "next" && activeModulePos!=this.modules.length-1){
            if(this.modules[activeModulePos].valid){
                this.modules[activeModulePos].class="completed";
                this.modules[activeModulePos+1].class="active";
            }
        }else if(buttonName === "previous" && activeModulePos!=0){
            this.error = undefined;
            this.modules[activeModulePos].class="";
            this.modules[activeModulePos-1].class="active";
        }
        this.template.querySelector("c-assessment-wizard-module-handler").handleModules(this.modules);
    }

    handleStepData(event){
        let step = event.detail.eventName;
        
        switch(step) {
            case "assessmentdetails":
                this.handleAssessmentDetails(event.detail.data);
                //console.log("Assessment Details >> ",JSON.stringify(event.detail.data));
                break;
            case "sectiondetails":
                this.handleSections(event.detail.data);
                //console.log("Section Details >> ",JSON.stringify(event.detail.data));
                break;
            case "scoringdata":
                this.handleScoring(event.detail.data);
                //console.log("Scoring Details >> ",JSON.stringify(event.detail.data));
                break;
            case "completionfieldupdate":
                this.handleCompletionFieldUpdate(event.detail.data);
                //console.log("Field Details >> ",JSON.stringify(event.detail.data));
                break;
            case "sectiondata":
                this.handleSectionData(event.detail.data);
                //console.log("Question Details >> ",JSON.stringify(event.detail.data));
                break;
            case "aqtobedeleted":
                this.handleAssessmentQuestionDeletion(event.detail.data);
        }
    }

    handleEditStep(event){
        this.modules[this.modules.findIndex(x => x.class=="active")].class="";
        switch(event.detail){
            case "editAssessmentDetails":
                this.modules[this.modules.findIndex(x => x.name=="Assessment Details")].class="active";
                break;
            case "editSections":
                this.modules[this.modules.findIndex(x => x.name=="Sections")].class="active";
                break;
            case "editQuestions":
                this.modules[this.modules.findIndex(x => x.name=="Questions")].class="active";
                break;
            case "editFieldUpdate":
                this.modules[this.modules.findIndex(x => x.name=="Field Update")].class="active";
                break;
            case "editScoring":
                this.modules[this.modules.findIndex(x => x.name=="Scoring")].class="active";
                break;
        }

       this.template.querySelector("c-assessment-wizard-module-handler").handleModules(this.modules);
    }

    async handleValidations(activeModule){
        switch(activeModule.name){
            case 'Assessment Details':
                if(this.assessmentDetails){
                    if(this.assessmentDetails.assessmentName == ''){
                        activeModule.valid = false;
                        this.error = 'Assessment Name cannot be blank';
                    }else{
                        //console.log('>> > >> >>> '+this.assessmentDetails.assessmentName)
                        await checkAssessmentNameDuplicate({assessmentName : this.assessmentDetails.assessmentName.trim(), assessmentId : this.editAssessmentId})
                        .then(result => {
                            let duplicate = result;
                            //console.log("result > ",result);
                            if(duplicate == 'Duplicate'){   
                                activeModule.valid = false;
                                this.error = 'This Assessment already exists.';
                            }else{
                                activeModule.valid = true;
                                this.error = undefined;
                            }
                        })
                        .catch(error => {
                            this.error = JSON.stringify(error);
                        })
                    }
                }else{
                    activeModule.valid = false;
                    this.error = 'Please fill all the required details';
                }
                break;

            case 'Sections':
                if(this.sections && this.sections.length){
                    if(this.sections.findIndex(x => x.secName == '') != -1){
                        activeModule.valid = false;
                        this.error = 'Section Name cannot be blank';
                    }else{
                        var valueArr = this.sections.map(function(item){ return item.secName });
                        var isDuplicate = valueArr.some(function(item, idx){ 
                            return valueArr.indexOf(item) != idx 
                        });
                        if(isDuplicate){
                            activeModule.valid = false;
                            this.error = 'Section Name cannot be same';
                        }else{
                            activeModule.valid = true;
                            this.error = undefined;
                        }
                    }
                }else{
                    activeModule.valid = false;
                    this.error = 'At least one Section is required.';
                }
                break;

            case 'Questions':
                let quesFlag = false;
                let objectFlag = false;
                if(this.questionsList){
                    this.questionsList.forEach(section => {
                        if(!quesFlag){
                            if(section.questionData.length){
                                quesFlag = false;
                                section.questionData.forEach(question => {
                                    if(question.objectname && question.objectname !== '--'){
                                        if(!question.fieldname || question.fieldname == '' || question.fieldname.length == 0){
                                            objectFlag = true;
                                        }else{
                                            objectFlag = false;
                                        }
                                    }
                                })
                            }else{
                                quesFlag = true;
                            }
                        }
                    })
                    if(quesFlag){
                        activeModule.valid = false;
                        this.error = 'Each section must have at least one question.';
                    }else{
                        if(objectFlag){
                            activeModule.valid = false;
                            this.error = 'Select a field to be updated or remove the Object selection to proceed.';
                        }else{
                            activeModule.valid = true;
                            this.error = undefined;
                        }
                    }
                }else{
                    activeModule.valid = false;
                    this.error = 'Each section must have at least one question.';
                }
                break;
            
            case "Field Update":
                if(this.completionFieldData){
                    if(!this.completionFieldData.selectedField){
                        activeModule.valid = false;
                        this.error = 'Please select field to be updated.';    
                    }else if(!this.completionFieldData.selectedValue || !this.completionFieldData.selectedValue){
                        activeModule.valid = false;
                        this.error = 'Please select value to be updated.';    
                    }else{
                        activeModule.valid = true;
                        this.error = undefined;    
                    }
                }else{
                    activeModule.valid = false;
                    this.error = 'Please select field to be updated.';
                }
                break;

            case "Scoring":
                let scoringFlag = false;
                let scoreError = '';
                if(this.scoringData){
                    let count = 1;
                    this.scoringData.forEach(score => {
                        if(!scoringFlag){
                            if(!score.minScore || score.minScore == ''){
                                scoringFlag = true;
                                scoreError = "Min Score cannot be blank (row number "+count+ ")";
                            }else if(!score.maxScore || score.maxScore == ''){
                                scoringFlag = true;
                                scoreError = "Max Score cannot be blank (row number "+count+ ")";
                            }else if(!score.color || score.color == ''){
                                scoringFlag = true;
                                scoreError = "Please select color (row number "+count+ ")";
                            }else if(!score.status || score.status == ''){
                                scoringFlag = true;
                                scoreError = "Status cannot be blank (row number "+count+ ")";
                            }
                            count++;
                        }

                        if(scoringFlag){
                            activeModule.valid = false;
                            this.error = scoreError;
                        }else{
                            activeModule.valid = true;
                            this.error = undefined;
                        }
                    })
                }else{
                    activeModule.valid = false;
                    this.error = 'At least one Score Definition is required.';
                }
                break;
        }
    }

    handleAssessmentQuestionDeletion(aqtobedeleted){
        if(aqtobedeleted.length){
            this.assessmentQuesToBeDeleted = aqtobedeleted;
        }
    }

    handleAssessmentDetails(assessmentdetails){
        this.error = undefined;
        this.assessmentDetails = assessmentdetails;
        if(this.assessmentDetails){
            if(this.assessmentDetails.needSections){
                if(this.modules.findIndex(x => x.name == "Sections") == -1){
                    let tempModule = {
                        name : "Sections",
                        flag : true,
                        class : "",
                        valid : false
                    };
                    
                    this.modules.splice(1, 0, tempModule);
                }
            }else{
                if(this.modules.findIndex(x => x.name == "Sections") != -1){
                    this.modules.splice(this.modules.findIndex(x => x.name == "Sections"), 1);
                }
            }
            if(this.assessmentDetails.needScoring){
                if(this.modules.findIndex(x => x.name == "Scoring") == -1){
                    let tempModule = {
                        name : "Scoring",
                        flag : true,
                        class : "",
                        valid : false
                    };
                    
                    this.modules.splice(this.modules.length-1, 0, tempModule);
                }
            }else{
                if(this.modules.findIndex(x => x.name == "Scoring") != -1){
                    this.modules.splice(this.modules.findIndex(x => x.name == "Scoring"), 1);
                }
            }
            if(this.assessmentDetails.fieldUpdate){
                if(this.modules.findIndex(x => x.name == "Field Update") == -1){
                    let tempModule = {
                        name : "Field Update",
                        flag : true,
                        class : "",
                        valid : false
                    };
                    
                    this.modules.splice(this.modules.length-1, 0, tempModule);
                }
            }else{
                if(this.modules.findIndex(x => x.name == "Field Update") != -1){
                    this.modules.splice(this.modules.findIndex(x => x.name == "Field Update"), 1);
                }
            }
        }
    }

    handleSections(sections){
        this.error = undefined;
        this.sections = sections;
    }

    handleScoring(scoringdata){
        this.error = undefined;
        this.scoringData = scoringdata;
    }

    handleCompletionFieldUpdate(fielddata){
        this.error = undefined;
        this.completionFieldData = fielddata;
    }

    handleSectionData(sectiondata){
        this.error = undefined;
        this.questionsList = sectiondata;
        console.log('this.questionsList >> '+JSON.stringify(this.questionsList));
    }

    handleSubmit(){
        let confirmation = confirm("Are you sure you want to submit?");
        if(confirmation == true){
            console.log("this.editAssessmentId >> ",this.editAssessmentId);
            createAssessmentRecord({assessmentName : this.assessmentDetails.assessmentName, description : this.assessmentDetails.assessmentDescription, active : this.assessmentDetails.active, editAssessmentId : this.editAssessmentId, objName:this.assessmentDetails.objectName})
            .then(result => {
                let assessmentId = result;
                console.log("assessmentId >> ",assessmentId);
                let finalQuesList = [];
                this.questionsList.forEach(section => {
                    section.questionData.forEach(ques => {
                        finalQuesList.push(ques);
                    })
                })
                console.log("finalQuesList >> ",JSON.stringify(finalQuesList));
                saveQuestions({assessmentId:assessmentId,quesData:JSON.stringify(finalQuesList), editAssessmentId : this.editAssessmentId, aqToBeDeleted : this.assessmentQuesToBeDeleted})
                .then(result => {
                    
                    let quesResult = JSON.parse(JSON.stringify(result));
                    let tempQuesList = JSON.parse(JSON.stringify(this.questionsList));
                    quesResult.forEach(savedQues => {
                        tempQuesList.forEach(section => {
                            section.questionData.forEach(ques => {
                                if(ques.unique == savedQues.unique_id__c){
                                    ques.aqId = savedQues.Id;
                                }
                                if(ques.dependentQuesData && ques.dependentQuesData.length){
                                    ques.dependentQuesData.forEach(depData => {
                                        console.log("2");
                                        if(depData.dependentQuesList && depData.dependentQuesList.length){
                                            depData.dependentQuesList.forEach(depQues => {
                                                console.log("3");
                                                if(depQues.unique == savedQues.unique_id__c){
                                                    depQues.aqId = savedQues.Id;
                                                }
                                                if(depQues.dependentQuesData && depQues.dependentQuesData.length){
                                                    depQues.dependentQuesData.forEach(depDepData => {
                                                        console.log("4");
                                                        if(depDepData.dependentQuesList && depDepData.dependentQuesList.length){
                                                            depDepData.dependentQuesList.forEach(depDepQues => {
                                                                console.log("5");
                                                                if(depDepQues.unique == savedQues.unique_id__c){
                                                                    depDepQues.aqId = savedQues.Id;
                                                                }
                                                            })
                                                        }
                                                    })
                                                } 
                                            })
                                        }
                                    })
                                }    
                            })
                        })
                    })
                    console.log("tempQuesList >> ",JSON.stringify(tempQuesList));
                    
                    let assessmentList = [];
                    if(this.questionsList){
                        let assessRec = { 'sobjectType': 'Assessment__c' };
                        assessRec.Id = assessmentId;
                        assessRec.Assessment_Detail_JSON__c = JSON.stringify(this.assessmentDetails);
                        assessRec.Questions_JSON__c = JSON.stringify(tempQuesList);
                        if(this.completionFieldData){
                            assessRec.Field_Update_JSON__c = JSON.stringify(this.completionFieldData);
                        }
                        if(this.scoringData){
                            assessRec.Scoring_JSON__c = JSON.stringify(this.scoringData);
                        }
                        if(this.sections){
                            assessRec.Section_JSON__c = JSON.stringify(this.sections);
                        }
                        console.log("assessRec >> ",JSON.stringify(assessRec));
                        assessmentList.push(assessRec);
                    }

                    if(assessmentList && assessmentList.length > 0){
                        updateJsonData({assessmentList : assessmentList})
                        .then(result => {
                            console.log("Saved");
                        })
                        .catch(error=>{
                            this.error = JSON.stringify(error);
                        })
                    }
                    if(this.assessmentDetails.fieldUpdate){
                        updateCompletionFieldData({assessmentId:assessmentId,field:this.completionFieldData.selectedField, fieldValue:this.completionFieldData.selectedValue})
                        .then(result=>{
                        })
                        .catch(error=>{
                            this.error = JSON.stringify(error);
                        })
                    }
                    if(this.scoringData && this.scoringData.length && this.assessmentDetails.needScoring){
                        let scoringList = [];
                        this.scoringData.forEach(score => {
                            let scoreRec = { 'sobjectType': 'Scoring__c' };
                            scoreRec.Assessment__c = assessmentId;
                            scoreRec.Min_Score__c = score.minScore;
                            scoreRec.Max_Score__c = score.maxScore;
                            scoreRec.Color__c = score.color;
                            scoreRec.Status__c = score.status;
                            scoringList.push(scoreRec)
                        })
                        createScoringRecords({scoringList : scoringList, editAssessmentId : this.editAssessmentId})
                        .then(result => {
                            var wizurl = '/'+assessmentId;
                            //window.open(wizurl,'_parent')
                            window.open('/lightning/r/caresp__Assessment__c/'+assessmentId+'/view', '_self');
                        })
                        .catch(error =>{
                            this.error = JSON.stringify(error);
                        })
                    }else{
                        var wizurl = '/'+assessmentId;
                        window.open('/lightning/r/caresp__Assessment__c/'+assessmentId+'/view', '_self');
                    }
                    
                })
                .catch(error => {
                    this.error = JSON.stringify(error);
                })
            })
            .catch(error => {
                this.error = JSON.stringify(error);
            })
        }
    }
}