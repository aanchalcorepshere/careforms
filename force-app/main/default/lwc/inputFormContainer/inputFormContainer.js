import { LightningElement, track, wire, api } from 'lwc';
import fetchFormData from '@salesforce/apex/FormsController.fetchFormData';
import saveObjectStructure from '@salesforce/apex/FormsHelper.saveObjectStructure';
import { loadStyle } from 'lightning/platformResourceLoader';
import stepProgressCss from '@salesforce/resourceUrl/stepProgressCss';
//import uploadFile from '@salesforce/apex/FileUploaderClass.uploadFile';
import uploadFiles from '@salesforce/apex/FileUploadMultiController.uploadFiles';
import saveSignature from '@salesforce/apex/SignatureController.saveSignature';
import attachPDF from '@salesforce/apex/FormsHelper.attachPDF';
import attachJSONForPDF from '@salesforce/apex/FormsHelper.attachJSONForPDF';
import attachPdfToRecord from '@salesforce/apex/FormsHelper.attachPdfToRecord';

export default class InputFormContainer extends LightningElement {

    primaryObjectStructure;
    parentsObjectStructure;
    childrenObjectStructure;
    grandChildrenObjectStructure;
    questionsResponses = [];
    filesData;
    signatureData;
    filesButtonLabel = "Upload Files";
    signatureButtonLabel = "Sign Form";
    openFileUploadModal = false;
    dataSaved = false;
    isLoading = false;
    isUploadFiles = false;
    isUploadSignature = false;
    primaryRecordId;
    uploadedDocuments;

    hasSummary = false;
    hasDocUpload = false;
    needSignature = false;
    needPDF = false


    @track objectStructure;
    @track pageData = [];
    @track rules;
    formName;
    confirmationMessage;
    progressStyle = stepProgressCss;
    error;

    @api formId;

    constructor() {
        super();
        Promise.all([loadStyle(this, this.progressStyle)]);
        this.addEventListener('valueupdate', this.updateValue.bind(this));
    }

    @wire(fetchFormData,{formId:'$formId'})
    wiredJsons (result) {
        if (result.data) {
            this.formName = result.data.formName;
            this.confirmationMessage = result.data.confirmationMessage;
            this.hasSummary = result.data.hasSummary;
            this.hasDocUpload = result.data.requiresDocUpload;
            this.needSignature = result.data.requiresSignature;
            this.needPDF = result.data.generatePDF;
            this.objectStructure = JSON.parse(result.data.objectStructure);
            this.rules = result.data.rules?JSON.parse(result.data.rules):undefined;
            let fieldsToBeHidden = [];
            if(this.rules){
                this.rules.forEach(rule => {
                    fieldsToBeHidden.push(rule.secondaryField);
                })
            }
            let pageDataRaw = JSON.parse(result.data.pageData);
            pageDataRaw.forEach(page => {
                if(page.pageIndex == 0) {
                    page.className = 'active';
                    page.current = true;
                    page.isDocUpload = false;
                    page.isSummary = false;
                    page.isSignature = false;
                    page.isFormPage = true;
                }else{
                    page.className = '';
                    page.current = false;
                    page.isDocUpload = false;
                    page.isSummary = false;
                    page.isSignature = false;
                    page.isFormPage = true;
                }
                if(page.sections){
                    page.sections.forEach(section => {
                        if(!section.isSectionMulti){
                            if(section.fields){
                                section.fields.forEach(field => {
                                    // if(fieldsToBeHidden.includes(field.fieldData.fieldApi)){
                                    if(fieldsToBeHidden.includes(field.fieldData.fieldUniqueName)){
                                        field.fieldData.hide = true;
                                    }else{
                                        field.fieldData.hide = false;
                                    }
                                })
                            }
                        }else{
                            if(section.fields){
                                let tempFields = [];
                                section.fields.forEach(field => {
                                    tempFields.push(field);
                                })
                                section.fields = [];
                                let recordData = {
                                    recordIndex : 1,
                                    recordFields : tempFields
                                }
                                section.fields.push(recordData);
                            }
                        }
                    })
                }
            })

            if(this.needSignature){
                let signaturePage = {};
                signaturePage.current = false;
                signaturePage.className = '';
                signaturePage.pageIndex = pageDataRaw.length;
                signaturePage.pageName = 'Signature';
                signaturePage.isDocUpload = false;
                signaturePage.isSummary = false;
                signaturePage.isSignature = true;
                signaturePage.isFormPage = false;
                pageDataRaw.push(signaturePage);
            }

            if(this.hasDocUpload){
                let docUploadPage = {};
                docUploadPage.current = false;
                docUploadPage.className = '';
                docUploadPage.pageIndex = pageDataRaw.length;
                docUploadPage.pageName = 'Document(s) Upload';
                docUploadPage.isDocUpload = true;
                docUploadPage.isSummary = false;
                docUploadPage.isSignature = false;
                docUploadPage.isFormPage = false;
                pageDataRaw.push(docUploadPage);
            }

            if(this.hasSummary){
                let summaryPage = {};
                summaryPage.current = false;
                summaryPage.className = '';
                summaryPage.pageIndex = pageDataRaw.length;
                summaryPage.pageName = 'Summary';
                summaryPage.isDocUpload = false;
                summaryPage.isSummary = true;
                summaryPage.isSignature = false;
                summaryPage.isFormPage = false;
                pageDataRaw.push(summaryPage);
            }

            this.pageData = JSON.parse(JSON.stringify(pageDataRaw));
            //console.log('this.pageData >> ',JSON.stringify(this.pageData));
        }
    }

    get firstPage(){
        if(this.pageData[0] && this.pageData[0].current){
            return this.pageData[0].current;
        }
    }

    get lastPage(){
        if(this.pageData[this.pageData.length-1] && this.pageData[this.pageData.length-1].current){
            return this.pageData[this.pageData.length-1].current;
        }
    }

    handleNavigation(event){
        let buttonName = event.target.name;

        if(buttonName == 'next'){
            let currentPagePos = this.pageData.findIndex(page => page.current);
            let isCurrentPageValid = false;
            isCurrentPageValid = this.validatePage(currentPagePos);
            console.log('isCurrentPageValid >> '+isCurrentPageValid);
            if(isCurrentPageValid){
                console.log('currentPagePos >> ',currentPagePos);
                this.pageData[currentPagePos].className='completed';
                this.pageData[currentPagePos].current=false;
                this.pageData[currentPagePos+1].className='active';
                this.pageData[currentPagePos+1].current=true;
            }else{
                alert("Please enter value for all required fields");
            }
        }else if(buttonName == 'previous'){
            let currentPagePos = this.pageData.findIndex(page => page.current);
            console.log('currentPagePos >> ',currentPagePos);
            this.pageData[currentPagePos].className='';
            this.pageData[currentPagePos].current=false;
            this.pageData[currentPagePos-1].className='active';
            this.pageData[currentPagePos-1].current=true;
        }
    }

    updateValue(event){
        console.log('sectionIsMulti >> ',event.detail.sectionIsMulti);
        console.log('pageIndex >> ',event.detail.pageIndex);
        console.log('sectionIndex >> ',event.detail.sectionIndex);
        console.log('recordIndex >> ',event.detail.recordIndex);
        console.log('fieldIndex >> ',event.detail.field.fieldIndex);
        console.log('value >> ',event.detail.value);
        let controllingFieldObject;
        let recordIndex;
        let controllingFieldApi;
        let controllingFieldValue;

        console.log('event.detail.sectionIsMulti >> ',event.detail.sectionIsMulti);

        if(!event.detail.sectionIsMulti){
            this.pageData[event.detail.pageIndex].sections[event.detail.sectionIndex].fields[event.detail.field.fieldIndex].fieldData.inputValue = event.detail.value;

            controllingFieldObject = this.pageData[event.detail.pageIndex].sections[event.detail.sectionIndex].fields[event.detail.field.fieldIndex].fieldData.objectName;
            controllingFieldApi = this.pageData[event.detail.pageIndex].sections[event.detail.sectionIndex].fields[event.detail.field.fieldIndex].fieldData.fieldApi;
            controllingFieldValue = this.pageData[event.detail.pageIndex].sections[event.detail.sectionIndex].fields[event.detail.field.fieldIndex].fieldData.inputValue;
        
            if(this.rules && this.rules.length){
                this.showFieldsOnCondition(this.pageData[event.detail.pageIndex].sections[event.detail.sectionIndex].fields[event.detail.field.fieldIndex].fieldData.fieldUniqueName,this.pageData[event.detail.pageIndex].sections[event.detail.sectionIndex].fields[event.detail.field.fieldIndex].fieldData.inputValue);
            }
        }else{
            console.log('<< this.pageData >> ',JSON.stringify(this.pageData));
            this.pageData[event.detail.pageIndex].sections[event.detail.sectionIndex].fields[event.detail.recordIndex-1].recordFields[event.detail.field.fieldIndex].fieldData.inputValue = event.detail.value;

            controllingFieldObject = this.pageData[event.detail.pageIndex].sections[event.detail.sectionIndex].fields[event.detail.recordIndex-1].recordFields[event.detail.field.fieldIndex].fieldData.objectName;
            controllingFieldApi = this.pageData[event.detail.pageIndex].sections[event.detail.sectionIndex].fields[event.detail.recordIndex-1].recordFields[event.detail.field.fieldIndex].fieldData.fieldApi;
            controllingFieldValue = this.pageData[event.detail.pageIndex].sections[event.detail.sectionIndex].fields[event.detail.recordIndex-1].recordFields[event.detail.field.fieldIndex].fieldData.inputValue;
            recordIndex = event.detail.recordIndex;
        }

        this.updateControllingFieldValue(recordIndex, controllingFieldObject, controllingFieldApi, controllingFieldValue);

        console.log("page data >> ",JSON.stringify(this.pageData));
    }

    updateControllingFieldValue(recIndex, fieldObject, fieldApi, fieldValue){
        console.log('recIndex >> ',recIndex);
        console.log('fieldObject >> ',fieldObject);
        this.pageData.forEach(page => { 
            if(page.sections && page.sections.length){
                page.sections.forEach(section => {
                    section.fields.forEach(field => {
                        if(!section.isSectionMulti){
                            if(field.fieldData.objectName == fieldObject && field.fieldData.controllingField == fieldApi){
                                field.fieldData.controllingFieldValue = fieldValue;
                            }
                        }else{
                            if(field.recordIndex === recIndex){
                                field.recordFields.forEach(recField => {
                                    if(recField.fieldData.objectName == fieldObject && recField.fieldData.controllingField == fieldApi){
                                        recField.fieldData.controllingFieldValue = fieldValue;
                                    }
                                })
                            }
                        }
                    })
                })
            }
        })

        console.log('this.pageData >> ',JSON.stringify(this.pageData));
    }

    validatePage(currentPagePos){
        let valid = true;
        if(this.pageData[currentPagePos].sections && this.pageData[currentPagePos].sections.length){
            this.pageData[currentPagePos].sections.forEach(section=>{
                if(!section.isSectionMulti){
                    if(section.fields.length){
                        section.fields.forEach(field => {
                            if(field.fieldData.dataType != 'BOOLEAN'){
                                let ss = field.fieldData.required;
                                let vv;
                                
                                console.log("value  >> ",field.fieldData.inputValue);
                                console.log("type of  >> ",typeof field.fieldData.inputValue);
                                if(typeof field.fieldData.inputValue == 'string' && field.fieldData.inputValue.trim() !== ''){
                                    vv = 'has value';
                                }else if(typeof field.fieldData.inputValue == 'object' && field.fieldData.inputValue.length){
                                    vv = 'has value';
                                }/* else if(typeof field.fieldData.inputValue == 'boolean'){
                                    vv = 'has value';
                                } */
                                console.log('ss >> ',ss);
                                console.log('vv >> ',vv);
                                if(ss && vv !== 'has value' ){
                                    valid = false;
                                } 
                            }else{
                                if(field.fieldData.inputValue == ""){
                                    var isTrueSet = (field.fieldData.defaultValue === 'true');
                                    field.fieldData.inputValue == isTrueSet;
                                }
                            }
                        })
                    }
                }else{
                    if(section.fields.length){
                        section.fields.forEach(record => {
                            if(record.recordFields.length){
                                record.recordFields.forEach(field => {
                                    if(field.fieldData.dataType != 'BOOLEAN'){
                                        let ss = field.fieldData.required;
                                        let vv;
                                        
                                        if(typeof field.fieldData.inputValue == 'string' && field.fieldData.inputValue.trim() !== ''){
                                            vv = 'has value';
                                        }else if(typeof field.fieldData.inputValue == 'object' && field.fieldData.inputValue.length){
                                            vv = 'has value';
                                        }/* else if(typeof field.fieldData.inputValue == 'boolean'){
                                            vv = 'has value';
                                        } */
                                        console.log('ss >> ',ss);
                                        console.log('vv >> ',vv);
                                        if(ss && vv !== 'has value' ){
                                            valid = false;
                                        } 
                                    }else{
                                        if(field.fieldData.inputValue == ""){
                                            var isTrueSet = (field.fieldData.defaultValue === 'true');
                                            field.fieldData.inputValue == isTrueSet;
                                        }
                                    }
                                })
                            }
                        })
                    }
                }
            })
        }
        return valid;
    }

    handleAddRow(event){

        let currentPagePos = event.detail.pageIndex;
        let currentSectionPos = event.detail.sectionIndex;

        let sectionFieldsLength = this.pageData[currentPagePos].sections[currentSectionPos].fields.length;
        let tempRecord = JSON.parse(JSON.stringify(this.pageData[currentPagePos].sections[currentSectionPos].fields[sectionFieldsLength-1]));
        tempRecord.recordIndex = sectionFieldsLength+1;
        if(tempRecord.recordFields){
            tempRecord.recordFields.forEach(field => {
                field.fieldData.inputValue = '';
                if(field.fieldData.controllingFieldValue){
                    field.fieldData.controllingFieldValue = undefined;
                }
            })
        }
        this.pageData[currentPagePos].sections[currentSectionPos].fields.push(tempRecord);

        //console.log('page data after add row >> ',JSON.stringify(this.pageData));
    }

    handleDeleteRow(event){
        let currentPagePos = event.detail.pageIndex;
        let currentSectionPos = event.detail.sectionIndex;
        let currentRecordPos = event.detail.recordIndex;

        if(this.pageData[currentPagePos].sections[currentSectionPos].fields.length > 1){
            this.pageData[currentPagePos].sections[currentSectionPos].fields.splice(currentRecordPos-1,1);
        }
        this.refreshIndexes();
    }

    refreshIndexes() {
        let i = 0;
        this.pageData.forEach(page => {
            page.pageIndex = i++;
            if (page.sections) {
                let j = 0;
                page.sections.forEach(section => {
                    section.sectionIndex = j;
                    section.sectionClass = "section" + j++;
                    if(!section.isSectionMulti){
                        if (section.fields) {
                            let k = 0;
                            section.fields.forEach(field => {
                                field.fieldIndex = k;
                                field.fieldClass = "field" + k++;
                            })
                        }
                    }else{
                        if (section.fields) {
                            let k = 1;
                            section.fields.forEach(record => {
                                record.recordIndex = k;
                                if(record.recordFields){
                                    let l = 0;
                                    record.recordFields.forEach(field => {
                                        field.fieldIndex = l;
                                        field.fieldClass = "field" + l++;
                                    })
                                }
                                k++;
                            })
                        }
                    }
                })
            }
        })
    }

    handleSubmit(){
        //this.generatePDF();
        let currentPagePos = this.pageData.findIndex(page => page.current);
        let isCurrentPageValid = false;
        isCurrentPageValid = this.validatePage(currentPagePos);
        console.log('isCurrentPageValid >> '+isCurrentPageValid);
        if(isCurrentPageValid){
            [this.primaryObjectStructure,this.parentsObjectStructure,this.childrenObjectStructure, this.grandChildrenObjectStructure] = this.createData();

            this.pageData.forEach(page => {
                if(page.sections && page.sections.length){
                    page.sections.forEach(section => {
                        if(!section.isSectionMulti){
                            if(section.fields && section.fields.length){
                                section.fields.forEach(field => {
                                    if(field.fieldData.objectName == this.primaryObjectStructure.objectName){
                                        let fieldValue ={};
                                        fieldValue.fieldApi = field.fieldData.fieldApi;
                                        fieldValue.inputValue = field.fieldData.inputValue;
                                        this.primaryObjectStructure.fieldValue.push(fieldValue);
                                    }
                                    if(this.parentsObjectStructure && this.parentsObjectStructure.length){
                                        this.parentsObjectStructure.forEach(parent => {
                                            if(field.fieldData.objectName == parent.objectName){
                                                let fieldValue ={};
                                                fieldValue.fieldApi = field.fieldData.fieldApi;
                                                fieldValue.inputValue = field.fieldData.inputValue;
                                                parent.fieldValue.push(fieldValue);
                                            }
                                        })
                                    }
                                    if(this.childrenObjectStructure && this.childrenObjectStructure.length){
                                        this.childrenObjectStructure.forEach(child => {
                                            if(field.fieldData.objectName == child.objectName){
                                                let fieldValue ={};
                                                fieldValue.fieldApi = field.fieldData.fieldApi;
                                                fieldValue.inputValue = field.fieldData.inputValue;
                                                fieldValue.recordIdentifier = field.fieldData.identifier?field.fieldData.identifier:undefined;
                                                child.fieldValue.push(fieldValue);
                                            }
                                        })
                                    }
                                    if(this.grandChildrenObjectStructure && this.grandChildrenObjectStructure.length){
                                        this.grandChildrenObjectStructure.forEach(grandchild => {
                                            if(field.fieldData.objectName == grandchild.objectName){
                                                let fieldValue ={};
                                                fieldValue.fieldApi = field.fieldData.fieldApi;
                                                fieldValue.inputValue = field.fieldData.inputValue;
                                                grandchild.fieldValue.push(fieldValue);
                                            }
                                        })
                                    }
                                    if(field.fieldData && field.fieldData.objectName == 'Question'){
                                        console.log('ques input >> ',JSON.stringify(field.fieldData.inputValue));
                                        let questionData ={};
                                        questionData.fieldApi = field.fieldData.fieldApi;
                                        questionData.inputValue = [];
                                        if(typeof field.fieldData.inputValue == 'string'){
                                            questionData.inputValue.push(field.fieldData.inputValue)
                                        }else{
                                            questionData.inputValue = field.fieldData.inputValue;
                                        }
                                        //questionData.inputValue = field.fieldData.inputValue;
                                        this.questionsResponses.push(questionData);
                                    }
                                })
                            }
                        }else{
                            if(section.fields && section.fields.length){
                                section.fields.forEach(record => {
                                    if(record.recordFields && record.recordFields.length){
                                        record.recordFields.forEach(field => {
                                            if(field.fieldData && field.fieldData.objectName == this.primaryObjectStructure.objectName){
                                                let fieldValue ={};
                                                fieldValue.fieldApi = field.fieldData.fieldApi;
                                                fieldValue.inputValue = field.fieldData.inputValue;
                                                this.primaryObjectStructure.fieldValue.push(fieldValue);
                                            }
                                            if(this.parentsObjectStructure && this.parentsObjectStructure.length){
                                                this.parentsObjectStructure.forEach(parent => {
                                                    if(field.fieldData.objectName == parent.objectName){
                                                        let fieldValue ={};
                                                        fieldValue.fieldApi = field.fieldData.fieldApi;
                                                        fieldValue.inputValue = field.fieldData.inputValue;
                                                        parent.fieldValue.push(fieldValue);
                                                    }
                                                })
                                            }
                                            if(this.childrenObjectStructure && this.childrenObjectStructure.length){
                                                this.childrenObjectStructure.forEach(child => {
                                                    if(field.fieldData.objectName == child.objectName){
                                                        let fieldValue ={};
                                                        fieldValue.fieldApi = field.fieldData.fieldApi;
                                                        fieldValue.inputValue = field.fieldData.inputValue;
                                                        fieldValue.recordIdentifier = record.recordIndex;
                                                        child.fieldValue.push(fieldValue);
                                                    }
                                                })
                                            }
                                            if(this.grandChildrenObjectStructure && this.grandChildrenObjectStructure.length){
                                                this.grandChildrenObjectStructure.forEach(grandchild => {
                                                    if(field.fieldData.objectName == grandchild.objectName){
                                                        let fieldValue ={};
                                                        fieldValue.fieldApi = field.fieldData.fieldApi;
                                                        fieldValue.inputValue = field.fieldData.inputValue;
                                                        grandchild.fieldValue.push(fieldValue);
                                                    }
                                                })
                                            }
                                        })
                                    }
                                })
                            }
                        }
                    })
                }
            })
            let pageDataForApex = {"pageData" : this.pageData};
            //this.generatePDF();
            console.log('primary >> ',JSON.stringify(this.primaryObjectStructure));
            console.log('parents >> ',JSON.stringify(this.parentsObjectStructure));
            console.log('children >> ',JSON.stringify(this.childrenObjectStructure));
            console.log('grandchildren >> ',JSON.stringify(this.grandChildrenObjectStructure));
            console.log('questionsResponses >> ',JSON.stringify(this.questionsResponses));
            this.isLoading = true;
            const params = {
                parentObjectList: JSON.stringify(this.parentsObjectStructure),
                primaryObjectList: JSON.stringify(this.primaryObjectStructure),
                childObjectsList: JSON.stringify(this.childrenObjectStructure),
                grandChildObjectList: JSON.stringify(this.grandChildrenObjectStructure),
                questionObjectsList: JSON.stringify(this.questionsResponses),
                formId: this.formId,
                isVerifyApplication: this.isVerifyApplication
            };
            
            saveObjectStructure({ params: JSON.stringify(params) })
                        .then(result => {
                console.log('result - ', JSON.stringify(result));
                this.dataSaved = result.isSuccess;
                if(!this.dataSaved){
                    let errorMessageArr = (result.message).split(',');
                    this.error = errorMessageArr[1];
                }else{
                    this.primaryRecordId = result.message;
                    if(this.needPDF && this.pageData && this.pageData.length){
                        this.generatePDF();
                    }
                    this.error = undefined;
                    if(this.hasDocUpload){
                        if(this.uploadedDocuments && this.uploadedDocuments.length){
                            uploadFiles({
                                recordId : result.message,
                                filedata : JSON.stringify(this.uploadedDocuments)
                            })
                            .then(result => {
                                console.log(result);
                                if(result && result == 'success') {
                                    this.uploadedDocuments = [];
                                } else {
                                    
                                }
                            }).catch(error => {
                                console.log('error >> ',JSON.stringify(error));
                                this.error = JSON.stringify(error);
                            })
                        }
                    }
                    if(this.needSignature){
                        if(this.signatureData && this.signatureData.length){
                            saveSignature({ signElement: this.signatureData, recId: result.message })
                        .then(result => {
                            this.signatureData = undefined;
                        })
                        .catch(error => {
                            console.log('error >> ',JSON.stringify(error));
                            this.error = JSON.stringify(error);
                        });
                        }
                    }
                }
                this.isLoading = false;
            })
            .catch(error => {
                console.log('error >> ',JSON.stringify(error));
                this.error = JSON.stringify(error);
            }) 
        }else{
            alert("Please enter value for all required fields");
        }
    }

    showFieldsOnCondition(primaryFieldName, inputValue){
        console.log('primaryFieldName - ',primaryFieldName);
        if(this.rules){
            this.rules.forEach(eachRule =>{
                var showSecondaryField = false;
                var secondaryFieldUniqueName = '';
                if(eachRule.primaryField != null && eachRule.primaryField != '' && 
                    eachRule.primaryField != undefined && eachRule.primaryField == primaryFieldName){
                    var primaryFieldValue = eachRule.value;
                    secondaryFieldUniqueName = eachRule.secondaryField;
                    console.log('old primaryFieldValue - ',primaryFieldValue, typeof primaryFieldValue, ' | inputValue - ',inputValue, typeof inputValue);
                    if(typeof inputValue === 'string' && typeof primaryFieldValue === 'string'){
                        if(inputValue.match(/\d+/g) == null && primaryFieldValue.match(/\d+/g) == null){
                            primaryFieldValue = primaryFieldValue.toLowerCase();
                            inputValue = inputValue.toLowerCase();
                        }
                        else if(inputValue.match(/\d+/g) != null && primaryFieldValue.match(/\d+/g) != null && eachRule.operator !== 'contains'){
                            primaryFieldValue = Number(primaryFieldValue);
                            inputValue = Number(inputValue);
                        }
                    } 
                    console.log('new primaryFieldValue - ',primaryFieldValue, typeof primaryFieldValue, ' | inputValue - ',inputValue, typeof inputValue);
                    console.log('operator - ',eachRule.operator);
                    switch(eachRule.operator){
                        case 'equals':
                            if(primaryFieldValue === inputValue){
                                showSecondaryField = true;
                            }                
                            break;
                        case 'contains':
                            if(inputValue.includes(primaryFieldValue)){
                                showSecondaryField = true;
                            }
                            break;
                        case 'islessthanequalto':
                            if(inputValue <= primaryFieldValue){
                                showSecondaryField = true;
                            }
                            break;
                        case 'isgreaterthanequalto':
                            if(inputValue >= primaryFieldValue){
                                showSecondaryField = true;
                            }
                            break;
                        case 'islessthan':
                            if(inputValue < primaryFieldValue){
                                showSecondaryField = true;
                            }
                            break;
                        case 'isgreaterthan':
                            if(inputValue > primaryFieldValue){
                                showSecondaryField = true;
                            }
                            break;
                        case 'isnotequalto':
                            if(primaryFieldValue !== inputValue){
                                showSecondaryField = true;
                            }
                            break;
                    }
                }
                if(secondaryFieldUniqueName != ''){
                    console.log('reached - ', secondaryFieldUniqueName, showSecondaryField);
                    this.updatePageJson(secondaryFieldUniqueName, showSecondaryField);
                }
            })
        }
    }
    updatePageJson(fieldName, hideOrShowField){
        this.pageData.forEach(eachPage =>{
            if(eachPage.sections && eachPage.sections.length){
                eachPage.sections.forEach(eachSection =>{
                    if(!eachSection.isSectionMulti){
                        eachSection.fields.forEach(eachField =>{
                            if(eachField.fieldData.fieldUniqueName != null && eachField.fieldData.fieldUniqueName != '' && 
                                eachField.fieldData.fieldUniqueName != undefined && eachField.fieldData.fieldUniqueName == fieldName){
                                eachField.fieldData.hide = !hideOrShowField;
                                console.log('condition reached, hide field? - ',eachField.fieldData.hide);
                            }
                        })
                    }
                })
            }
        })
    }

    createData(){
        let primary = {};
        let parents = [];
        let children = [];
        let grandchildren = [];
        
        primary.objectName = this.objectStructure.selectedValue;
        primary.recordType = this.objectStructure.selectedRecordType?this.objectStructure.selectedRecordType:'';
        primary.parents = [];
        primary.fieldValue = []
    
        console.log(primary.objectName);
    
        if(this.objectStructure.relatedList.length){
            this.objectStructure.relatedList.forEach(related=>{
                if(related.type === 'Lookup(Parent)'){
                    let parent = {};
                    //parent.objectName = related.selectedValue.substring(0,related.selectedValue.indexOf('|'));
                    parent.objectName = related.selectedValue;
                    parent.recordType = related.selectedRecordType?related.selectedRecordType:'';
                    parent.childFieldApi = related.selectedValue.substring(related.selectedValue.indexOf('|')+1, related.selectedValue.length);
                    parent.fieldValue = [];
                    primary.parents.push({
                        parentApi : parent.objectName,
                        parentFieldApi : related.selectedValue.substring(related.selectedValue.indexOf('|')+1, related.selectedValue.length),
                        parentId : ""
                    });
                    parents.push(parent);
                }else{
                    let child = {
                        objectName : "",
                        parents : [],
                        fieldValue : []
                    }
                    //child.objectName = related.selectedValue.substring(0,related.selectedValue.indexOf('|'));
                    child.objectName = related.selectedValue;
                    child.recordType = related.selectedRecordType?related.selectedRecordType:'';
                    child.parents.push({
                        parentApi : primary.objectName,
                        parentFieldApi : related.selectedValue.substring(related.selectedValue.indexOf('|')+1, related.selectedValue.length)
                    })
    
                    if(related.relatedList.length){
                        related.relatedList.forEach(relatedOfRelated=>{
                            if(relatedOfRelated.type === 'Lookup(Parent)'){
                                let parentOfChild = {};
                                //parentOfChild.objectName = relatedOfRelated.selectedValue.substring(0,relatedOfRelated.selectedValue.indexOf('|'));
                                parentOfChild.objectName = relatedOfRelated.selectedValue;
                                parentOfChild.recordType = relatedOfRelated.selectedRecordType?relatedOfRelated.selectedRecordType:'';
                                parentOfChild.childFieldApi = relatedOfRelated.selectedValue.substring(relatedOfRelated.selectedValue.indexOf('|')+1, relatedOfRelated.selectedValue.length);
                                parentOfChild.fieldValue = [];
                                child.parents.push({
                                    parentApi : parentOfChild.objectName,
                                    parentFieldApi : relatedOfRelated.selectedValue.substring(relatedOfRelated.selectedValue.indexOf('|')+1, relatedOfRelated.selectedValue.length),
                                    parentId : ""
                                });
                                parents.push(parentOfChild);
                            }else{
                                let childOfChild = {
                                    objectName : "",
                                    parents : [],
                                    fieldValue : []
                                }
                                //childOfChild.objectName = relatedOfRelated.selectedValue.substring(0,relatedOfRelated.selectedValue.indexOf('|'));
                                childOfChild.objectName = relatedOfRelated.selectedValue;
                                childOfChild.recordType = relatedOfRelated.selectedRecordType?relatedOfRelated.selectedRecordType:'';
                                childOfChild.parents.push({
                                    parentApi : child.objectName,
                                    parentFieldApi : relatedOfRelated.selectedValue.substring(relatedOfRelated.selectedValue.indexOf('|')+1, relatedOfRelated.selectedValue.length),
                                    parentId : ""
                                })
                                grandchildren.push(childOfChild);
                            }
                        })
                    }
    
                    children.push(child);
                }
            })
        }
    
        console.log('primary >> '+JSON.stringify(primary));
        console.log('parents >> '+JSON.stringify(parents));
        console.log('children >> '+JSON.stringify(children));

        return [primary,parents,children, grandchildren];
    
    }

    openFileUpdoad(){
        this.openFileUploadModal = true;
        this.isUploadFiles = true;
    }

    openSignatureUpdoad(){
        this.openFileUploadModal = true;
        this.isUploadSignature = true;
    }

    closeModal(){
        this.openFileUploadModal = false;
        this.isUploadFiles = false;
        this.isUploadSignature = false;
    }

    handleUploadFiles(event){
        this.filesData = event.detail;
        console.log('this.filesData >> ',JSON.stringify(this.filesData));
        this.filesButtonLabel = "Files Uploaded";
        this.closeModal();
    }

    handleSignature(event){
        this.signatureData = event.detail;
        console.log('signatureData >> ',JSON.stringify(this.signatureData));
        this.signatureButtonLabel = "Signed";
        this.closeModal();
    }

    resetFileUpdoad(){
        this.filesData = undefined;
        this.filesButtonLabel = "Upload Files";
    }

    resetSignatureUpdoad(){
        this.signatureData = undefined;
        this.signatureButtonLabel = "Sign Form";
    }


    generatePDF() {
        /* var vfWindow = this.template.querySelector("iframe").contentWindow;
        vfWindow.postMessage(JSON.stringify(this.pageData), this.vfRoot);
         */

        /* this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/apex/generateFormDataPDF'
            }
        }) */
        
        let pageDataForApex = {"pageData" : []};
        if(this.pageData && this.pageData.length){
            this.pageData.forEach(page => {
                let tempPage = {};
                tempPage.pageIndex = page.pageIndex;
                tempPage.pageName = page.pageName;
                tempPage.sections = [];
                if(page.sections){
                    page.sections.forEach(section => {
                        let tempSection = {}
                        tempSection.sectionIndex = section.sectionIndex;
                        tempSection.sectionName = section.sectionName;
                        tempSection.isSectionMulti = section.isSectionMulti?section.isSectionMulti:false;
                        tempSection.fields = [];
                        if(section.fields){
                            if(!section.isSectionMulti){
                                let tempRecord = {
                                    "recordIndex":1,
                                    "recordFields":[]
                                 };
                                section.fields.forEach(field => {
                                    let tempField = {};
                                    /* if(field.isField){
                                        tempField.fieldName = field.fieldData.customlabel !== ""?field.fieldData.customlabel : field.fieldData.fieldName;
                                        tempField.fieldIndex = field.fieldIndex;
                                        tempField.inputValue = field.fieldData.inputValue;
                                        tempRecord.recordFields.push(tempField);
                                    } */
                                    tempField.fieldIndex = field.fieldIndex;
                                    if(field.isField){
                                        tempField.fieldName = field.fieldData.customlabel !== ""?field.fieldData.customlabel : field.fieldData.fieldName;
                                        if(typeof field.fieldData.inputValue == 'object'){
                                            tempField.inputValue = JSON.stringify(field.fieldData.inputValue);
                                        }else{
                                            tempField.inputValue = field.fieldData.inputValue;
                                        }
                                        tempField.content = '';
                                    }else{
                                        tempField.fieldName = '';
                                        tempField.inputValue = '';
                                        tempField.content = field.content;
                                    }
                                    tempField.isField = field.isField;
                                    tempField.isRichTextBox = field.isRichTextBox;
                                    tempRecord.recordFields.push(tempField);
                                })
                                tempSection.fields.push(tempRecord);
                            }else{
                                section.fields.forEach(record => {
                                    let tempRecord = {};
                                    tempRecord.recordIndex = record.recordIndex;
                                    tempRecord.recordFields = [];
                                    if(record.recordFields && record.recordFields.length){
                                        record.recordFields.forEach(field => {
                                            let tempField = {};
                                            /* if(field.isField){
                                                tempField.fieldName = field.fieldData.customlabel !== ""?field.fieldData.customlabel : field.fieldData.fieldName;
                                                tempField.fieldIndex = field.fieldIndex;
                                                tempField.inputValue = field.fieldData.inputValue;
                                                tempRecord.recordFields.push(tempField);
                                            } */
                                            tempField.fieldIndex = field.fieldIndex;
                                            if(field.isField){
                                                tempField.fieldName = field.fieldData.customlabel !== ""?field.fieldData.customlabel : field.fieldData.fieldName;
                                                if(typeof field.fieldData.inputValue == 'object'){
                                                    tempField.inputValue = JSON.stringify(field.fieldData.inputValue);
                                                }else{
                                                    tempField.inputValue = field.fieldData.inputValue;
                                                }
                                                tempField.content = '';
                                            }else{
                                                tempField.fieldName = '';
                                                tempField.inputValue = '';
                                                tempField.content = field.content;
                                            }
                                            tempField.isField = field.isField;
                                            tempField.isRichTextBox = field.isRichTextBox;
                                            tempRecord.recordFields.push(tempField);
                                        })
                                    }
                                    tempSection.fields.push(tempRecord);
                                })
                            }
                        }
                        tempPage.sections.push(tempSection);
                    })
                }
                pageDataForApex.pageData.push(tempPage);
            })
        }
        console.log('pageDataForApex >> ',JSON.stringify(pageDataForApex));
        attachJSONForPDF({jsonString:JSON.stringify(pageDataForApex),formId:this.formId})
        .then(result => {
            attachPdfToRecord({formId : this.formId, parentId : this.primaryRecordId})
            .then(result1 => {
                alert('attached');
            })
            .catch(error1 => {
                this.error = JSON.stringify(error1);
                console.error('ERROR OCCURED  >> '+JSON.stringify(error1));
            })
        })
        .catch(error => {
            this.error = JSON.stringify(error);
            console.error('ERROR OCCURED  >> '+JSON.stringify(error));
        })
        /* attachPDF({jsonString : JSON.stringify(pageDataForApex), parentId : this.formId})
        .then(result => {
            console.log('PDF attached');
        })
        .catch(error => {
            this.error = JSON.stringify(error);
            console.error('ERROR OCCURED  >> '+JSON.stringify(error));
        }) */
        //window.open('/apex/generateFormDataPDF?pdfDetails='+JSON.stringify(pageDataForApex));
    }

    handleDocuments(event){
        this.uploadedDocuments = event.detail;
        console.log('this.uploadedDocuments >> ',JSON.stringify(this.uploadedDocuments));
    }

    handleEditPage(event){
        let editPageIndex = event.detail;
        let currentPagePos = this.pageData.findIndex(page => page.current);
        this.pageData[currentPagePos].className='';
        this.pageData[currentPagePos].current=false;
        this.pageData[editPageIndex].className='active';
        this.pageData[editPageIndex].current=true;
    }
}