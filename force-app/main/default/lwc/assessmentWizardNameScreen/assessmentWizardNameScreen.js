import { LightningElement, wire, track, api } from 'lwc';
import getObjectNames from '@salesforce/apex/AssessmentWizardController.getObjectNames';

export default class AssessmentWizardNameScreen extends LightningElement {
    @track objectList;
    /* assessmentName='';
    objectName='';
    selectedQuestionSource='';
    isTemplate = false;
    needScoring = false;
    needSections = false;
    fieldUpdate = false;
    templateName; */
    error;
    @api isSubmit;
    //@api previousData;
    @track assessmentDetail={
        assessmentName : '',
        objectName : '',
        templateName : '',
        selectedQuestionSource : '',
        assessmentDescription : '',
        needScoring : false,
        needSections : false,
        active:true,
        fieldUpdate : false,
        isTemplate : false,
        isSourceTemplate : false
    };

    @track questionSource = [
        {
            label : 'Choose from Existing Template',
            value : 'existingTemplate',
        },
        {
            label : 'Choose from Question Library',
            value : 'questionLibrary',
        }
    ]

    @track templateList = [
        {
            label : 'PHQ-9 Questionnaire',
            value : 'template-id-01',
        },
        {
            label : 'CASV Questionnaire',
            value : 'template-id-02',
        }
    ]

    /* connectedCallback(){
        if(this.previousData){
            console.log("this.previousData >> ",JSON.stringify(this.previousData));
            this.assessmentDetail = JSON.parse(JSON.stringify(this.previousData));
            this.dispatchEvent(new CustomEvent('assessmentdetails', {
                detail: this.assessmentDetail
            }));
        }
    } */

    @api
    get previousData() {
        //console.log("this.localEditData >> ",JSON.stringify(this.localEditData));
        return this.assessmentDetail;
    }

    set previousData(value) {
        if(value){
            //console.log("this.previousData >> ",JSON.stringify(value));
            this.assessmentDetail = JSON.parse(JSON.stringify(value));
        }
        /* this.dispatchEvent(new CustomEvent('assessmentdetails', {
            detail: this.assessmentDetail
        })); */
    }

    @wire(getObjectNames)
    wiredObjects({ error, data }) {
        if(data){
            let tempData = JSON.parse(data);
            tempData.sort(function (a, b) {
                return a.label.localeCompare(b.label);
            });
            this.objectList = tempData;
        }else if(error){
            this.error = error;
        }
    }

    get isLoading() {
        return !(this.objectList || this.childObjectList);
    }

    handleChange(event){
        let inputname = event.target.name;
        if(inputname === 'assessmentname'){
            this.assessmentDetail.assessmentName = event.target.value;
        }else if(inputname === 'objectname'){
            this.assessmentDetail.objectName = event.target.value;
        }else if(inputname === 'questionsource'){
            this.assessmentDetail.selectedQuestionSource = event.detail.value;
            if(this.assessmentDetail.selectedQuestionSource === 'existingTemplate'){
                this.assessmentDetail.isSourceTemplate = true;
            }else{
                this.assessmentDetail.isSourceTemplate = false;
            }
        }else if(inputname === "assessmentdescription"){
            this.assessmentDetail.assessmentDescription = event.target.value;
        }else if(inputname === "scoring"){
            this.assessmentDetail.needScoring = event.target.checked;
        }else if(inputname === "needsections"){
            this.assessmentDetail.needSections = event.target.checked;
        }else if(inputname === "fieldupdate"){
            this.assessmentDetail.fieldUpdate = event.target.checked;
        }else if(inputname === "active"){
            this.assessmentDetail.active = event.target.checked;
        }else if(inputname === "templatename"){
            this.assessmentDetail.templateName = event.target.value;
        }else if(inputname === "istemplate"){
            this.assessmentDetail.isTemplate = event.target.checked;
            if(this.assessmentDetail.isTemplate){
                this.assessmentDetail.objectName = undefined;
                this.assessmentDetail.selectedQuestionSource = undefined;
                this.assessmentDetail.needScoring = false;
                this.assessmentDetail.fieldUpdate = false;
                this.assessmentDetail.templateName = undefined;
            }
        }

        this.dispatchEvent(new CustomEvent('assessmentdetails', {
            detail: this.assessmentDetail
        }));
    }
}