import { LightningElement, wire, track, api } from 'lwc';
import getObjectsList from '@salesforce/apex/ObjectInformationUtil.getObjectsList';
import createFormRecord from '@salesforce/apex/FormsController.createFormRecord';
import saveFormData from '@salesforce/apex/FormsController.saveFormData';
import fetchFormData from '@salesforce/apex/FormsController.fetchFormData';

export default class FormsContainer extends LightningElement {
    
    @api isEdit = false;
    @api editFormId;
    formId;

    /* Initializing variables */
    @track objectListAll;
    @track pageData;
    @track filteredFields;

    isObjectStructure = true; //object structure component will be active on load
    isFormStructure = false;
    isRulesScreen = false;
    
    objectStructureData;
    rules;
    formName;
    confirmationMessage = false;
    requiresSignature = false;
    requiresTextOnSignaturePage = false;
    signaturePageText;
    requiresDocUpload = false;
    showSummary = false;
    createPDFOnly = false;
    generatePDF;
    prefillFields = false;
    formSaved = false;
    error; //error

    isLoading = false; //for toggling spinner

    //get all the objects from salesforce org.
    @wire(getObjectsList)
    wiredObjects (result) {
        if (result.data) {
            let objectList = JSON.parse(JSON.stringify(result.data));
            objectList.sort(this.sortObjectList);
            this.objectListAll = objectList;
        }
    }

    connectedCallback(){
        if(this.isEdit){
            fetchFormData({formId:this.editFormId})
            .then(result => {
                this.formName = result.formName;
                this.confirmationMessage = result.confirmationMessage;
                this.requiresSignature = result.requiresSignature;
                this.requiresTextOnSignaturePage = result.requiresTextOnSignaturePage;
                this.signaturePageText = result.signaturePageText;
                                this.requiresDocUpload = result.requiresDocUpload;
                this.showSummary = result.hasSummary;
                 this.createPDFOnly = result.pdfOnly;
                this.generatePDF = result.generatePDF;
                this.prefillFields = result.prefillFields;
                this.objectStructureData = JSON.parse(result.objectStructure);
                this.pageData = JSON.parse(result.pageData);
                this.rules = result.rules?JSON.parse(result.rules):undefined;
            })
            .catch(error => {

            })
        }
    }

    sortObjectList(a, b) {
        if (a.label < b.label) {
            return -1;
        }
        if (a.label > b.label) {
            return 1;
        }
        return 0;
    }

    get dataLoading(){
        return !this.objectListAll;
    }

    //handle navigation forward
    handleNavForward(){
        this.error = undefined;
        if(this.isObjectStructure){
            let valid = this.validateCurrentPage();  //validate current page
            if(valid){
                this.isObjectStructure = false;
                this.isFormStructure = true;
                this.isRulesScreen = false;
            }else{
                console.log('error >> ',this.error);
            }
        }else if(this.isFormStructure){
            this.isObjectStructure = false;
            this.isFormStructure = false;
            this.isRulesScreen = true;

        }
    }

    //hide back button on first screen
    get hideBack(){
        return this.isObjectStructure;
    }

    //hide forward button and show save button on last screen
    get hideForward(){
        return this.isRulesScreen;
    }

    //handle navigation backward
    handleNavBackward(){
        if(this.isRulesScreen){
            this.isObjectStructure = false;
            this.isFormStructure = true;
            this.isRulesScreen = false;
        }else if(this.isFormStructure){
            this.isObjectStructure = true;
            this.isFormStructure = false;
            this.isRulesScreen = false;
        }
    }

    //capture object struture on next
    handleObjectStructure(event){
        [this.formName, this.objectStructureData, this.confirmationMessage, this.requiresSignature, this.requiresTextOnSignaturePage, this.signaturePageText, this.requiresDocUpload, this.showSummary, this.generatePDF, this.prefillFields, this.createPDFOnly] = [event.detail[0], event.detail[1], event.detail[2], event.detail[3], event.detail[4], event.detail[5], event.detail[6], event.detail[7], event.detail[8], event.detail[9], event.detail[10]];
    }

    //capture form struture on next
    handlePagesData(event){
        /* console.log('pages>> ',JSON.stringify(event.detail)); */
        [this.pageData,this.filteredFields] = [event.detail[0],event.detail[1]];
    }

    //capture rules from rules screen
    handleRules(event){
        this.rules = event.detail;
    }

    get formLink(){
        return "/"+this.formId;
    }

    //save form
    handleSaveForm(event){
        let isFormValid = this.validateCurrentPage();
        if(isFormValid){
            this.error = undefined;
            this.isLoading = true;
            this.pageData.forEach(page => {
                if(page.sections){
                    page.sections.forEach(section => {
                        if(section.isSectionMulti){
                            section.initialFieldLength = section.fields.length;
                        }
                    })
                }
            })
            createFormRecord({formName:this.formName,isEdit:this.isEdit,recordId:this.editFormId, confirmationMessage:this.confirmationMessage, requiresSignature:this.requiresSignature, requiresTextOnSignaturePage:this.requiresTextOnSignaturePage, signaturePageText:this.signaturePageText, requiresDocUpload:this.requiresDocUpload, showSummary:this.showSummary, generatePDF:this.generatePDF, prefillFields:this.prefillFields, primaryObjectForPrefillForm:this.objectStructureData.selectedValue, isPDFOnly: this.createPDFOnly})
            .then(result => {
                this.formId = result;
                console.log('form id >> '+this.formId);
                saveFormData({recordId : this.formId, objectStructureJson:JSON.stringify(this.objectStructureData), pageDataJson:JSON.stringify(this.pageData), rulesJson:JSON.stringify(this.rules), isEdit: this.isEdit})
                .then(result => {
                    this.isLoading = false;
                    this.isObjectStructure = false;
                    this.isFormStructure = false;
                    this.isRulesScreen = false;
                    this.formSaved = true;
                })
                .catch(error => {
                    this.isLoading = false;
                })
            })
            .catch(error => {
                this.isLoading = false;
            })
        }else{
            this.error = "Please complete this missing fields in Rules or delete the rule.";
        }

    }

    //check if current page has valid entries
    validateCurrentPage(){
        let retVal = true;
        if(this.isObjectStructure){
            if(!this.formName || this.formName === ''){
                this.error = 'Please enter Form Name to proceed.';
                retVal = false;
            }else if(!this.confirmationMessage || this.confirmationMessage.length == 0){
                this.error = 'Please enter Confirmation Message.';
                return false;
            }else if(this.objectStructureData){
                if(this.objectStructureData.selectedValue == ''){
                    this.error = 'Please select Primary object.';
                    retVal = false;
                }
                if(this.objectStructureData.relatedList && retVal){
                    this.objectStructureData.relatedList.forEach(relatedLevel1 => {
                        if(retVal){
                            console.log('relatedLevel1.selectedValue >> ',relatedLevel1.selectedValue.length);
                            if(!relatedLevel1.selectedValue || relatedLevel1.selectedValue.length === 0){
                                this.error = 'Please select Related object or delete the level.';
                                retVal = false;
                            }else if(relatedLevel1.relatedList){
                                relatedLevel1.relatedList.forEach(relatedLevel2 => {
                                    if(retVal){
                                        if(!relatedLevel2.selectedValue || relatedLevel2.selectedValue.length === 0){
                                            this.error = 'Please select Related object or delete the level.';
                                            retVal = false;
                                        }
                                    }
                                })
                            }
                        }
                    })
                }
            }
        }else if(this.isRulesScreen){
            if(this.rules && this.rules.length){
                this.rules.forEach(rule => {
                    if(!this.isEmpty(rule.primaryField) && !this.isEmpty(rule.secondaryField) && !this.isEmpty(rule.value) && !this.isEmpty(rule.operator) && !this.isEmpty(rule.dependentType)){

                    }else if(this.isEmpty(rule.primaryField) && this.isEmpty(rule.secondaryField) && this.isEmpty(rule.value) && this.isEmpty(rule.operator) && this.isEmpty(rule.dependentType)){

                    }else{
                        retVal = false;
                    }
                })
            }
        }
        return retVal;
    }

    isEmpty(str) {
        return (!str || str.length === 0 );
    }

}