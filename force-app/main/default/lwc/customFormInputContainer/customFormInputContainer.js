import {
    LightningElement,
    track,
    wire,
    api
}
from "lwc";
import {
    loadStyle
}
from "lightning/platformResourceLoader";
import {
    getRecord,
    getFieldValue
}
from "lightning/uiRecordApi";
import fetchFormData from "@salesforce/apex/FormsController.fetchFormData";
import saveObjectStructure from "@salesforce/apex/FormsHelper.saveObjectStructure";
import stepProgressCss from "@salesforce/resourceUrl/stepProgressCss";
import uploadFiles from "@salesforce/apex/FileUploadMultiController.uploadFiles";
import attachPrintJsonToRecord from "@salesforce/apex/FormsHelper.attachPrintJsonToRecord";
import saveSignature from "@salesforce/apex/SignatureController.saveSignature";
import isGuest from "@salesforce/user/isGuest";
import createDependentFormsTrackerRecord from "@salesforce/apex/FormsHelper.createDependentFormsTrackerRecord";
import deleteDependentFormsTrackerRecord from "@salesforce/apex/FormsHelper.deleteDependentFormsTrackerRecord";
import getTrackerRecordStatus from "@salesforce/apex/FormsHelper.getTrackerRecordStatus";
import moveJsonsAndDeleteTrackerRecords from "@salesforce/apex/FormsHelper.moveJsonsAndDeleteTrackerRecords";
import ORG_URL from "@salesforce/label/c.Org_URL";
//import processRecords from "@salesforce/apex/TestInsertRecords.processRecords";

//import NAME_FIELD from '@salesforce/schema/Application_Staging__c.Name';

//const fields = [NAME_FIELD];

export default class CustomFormInputContainer extends LightningElement {
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
    isPDFOnly;
    signaturePageText;
    requiresTextOnSignaturePage = false;
    primaryRecordId;
    referralId;
    referralName;
    referralLink;
    uploadedDocuments;
    isDraftSave = false;
    isGuestUser = isGuest;
    savedPrintJsonWithDateTime;
    signatureSaved = false;
    parentFormJSId;
    orgUrl = ORG_URL;

    // Public API surface for subscriber LWCs embedding this component
    @api isApplicationForm = false;
    @api isCreateApplication = false;
    @api isPrefillFieldsForm = false;
    @api primaryObjectForPrefill;
    @api isDependentForm = false;
    @api trackerRecordId;
    isConfirmationBox = false;

    @api recordId;

    hasSummary = false;
    hasDocUpload = false;
    needSignature = false;
    needPDF = false;
    @track services;

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
        this.addEventListener("valueupdate", this.updateValue.bind(this));
    }

    connectedCallback() {
        console.log("is prefill >> ", this.isPrefillFieldsForm);
        console.log("record Id >> ", this.recordId);
        console.log("trackerRecordId >> ", this.trackerRecordId);
        if (!this.isDependentForm) {
            this.parentFormJSId = Math.random().toString(36).slice(2);
        }
    }

    /* @wire(getRecord, { recordId: '$primaryRecordId', fields })
      primaryRecord; */

    @wire(fetchFormData, {
        formId: "$formId"
    })
    wiredJsons(result) {
        if (result.data) {
            this.setFormData(result);
        }
        else if (result.error) {
            console.error("Error >> ", JSON.stringify(result.error));
        }
    }

    setFormData(result) {
        //console.log('result >> '+JSON.stringify(result));
        this.formName = result.data.formName;
        this.confirmationMessage = result.data.confirmationMessage;
        this.hasSummary = result.data.hasSummary;
        this.hasDocUpload = result.data.requiresDocUpload;
        this.needSignature = result.data.requiresSignature;
        this.requiresTextOnSignaturePage = result.data.requiresTextOnSignaturePage;
        this.signaturePageText = result.data.signaturePageText;
        this.needPDF = result.data.generatePDF;
        if (!this.isDependentForm) {
            this.isPDFOnly = result.data.pdfOnly;
        }
        else {
            this.isPDFOnly = true;
        }
        //console.log('this.isPDFOnly >> '+this.isPDFOnly);
        this.objectStructure = JSON.parse(result.data.objectStructure);
        this.rules = result.data.rules ? JSON.parse(result.data.rules) : undefined;
        let fieldsToBeHidden = [];
        if (this.rules) {
            this.rules.forEach((rule) => {
                if (rule.dependentType == "field") {
                    fieldsToBeHidden.push(rule.secondaryField);
                }
            });
            this.rules.forEach((eachRule) => {
                eachRule.isPassed = false;
            });
        }
        let pageDataRaw = JSON.parse(result.data.pageData);

        pageDataRaw.forEach((page) => {
            let dependentForms = [];
            if (page.pageIndex == 0) {
                page.className = "active";
                page.current = true;
                page.isDocUpload = false;
                page.isSummary = false;
                page.isSignature = false;
                page.isFormPage = true;
            }
            else {
                page.className = "";
                page.current = false;
                page.isDocUpload = false;
                page.isSummary = false;
                page.isSignature = false;
                page.isFormPage = true;
            }
            if (page.sections) {
                page.sections.forEach((section) => {
                    if (!section.isSectionMulti) {
                        if (section.fields) {
                            section.fields.forEach((field) => {
                                if (
                                    fieldsToBeHidden.includes(field.fieldData.fieldUniqueName)
                                ) {
                                    field.fieldData.hide = true;
                                }
                                else {
                                    field.fieldData.hide = false;
                                }
                                //implementing dependent forms
                                if (this.rules && this.rules.length) {
                                    this.rules.forEach((rule) => {
                                        if (
                                            rule.primaryField == field.fieldData.fieldUniqueName &&
                                            rule.dependentType == "form"
                                        ) {
                                            let dependentForm = {};
                                            let formNameId = rule.secondaryField.split("|");
                                            dependentForm.formName = formNameId[0];
                                            dependentForm.formId = formNameId[1];
                                            dependentForm.primaryField = rule.primaryField;
                                            dependentForm.primaryFieldValueForForm = rule.value;
                                            dependentForm.operatorForForm = rule.operator;
                                            dependentForm.requiredFlagForForm = rule.required;
                                            dependentForm.showFlagForForm = false;
                                            dependentForm.submitted = false;
                                            dependentForm.formLink =
                                                this.orgUrl +
                                                "lightning/n/Additional_Form_Launcher?c__dependentFormId=" +
                                                formNameId[1] +
                                                "&c__parentJSId=" +
                                                this.parentFormJSId +
                                                "&c__isDependentForm=true";
                                            dependentForms.push(dependentForm);
                                            console.log(
                                                "dependentForm >> " + JSON.stringify(dependentForm)
                                            );
                                        }
                                    });
                                }
                            });
                        }
                    }
                    else {
                        if (section.fields) {
                            let tempFields = [];
                            section.fields.forEach((field) => {
                                tempFields.push(field);
                            });
                            section.fields = [];
                            let recordData = {
                                recordIndex: 1,
                                recordFields: tempFields
                            };
                            section.fields.push(recordData);
                        }
                    }
                });
            }
            page.dependentForms = dependentForms;
        });

        if (this.needSignature) {
            let signaturePage = {};
            signaturePage.current = false;
            signaturePage.className = "";
            signaturePage.pageIndex = pageDataRaw.length;
            signaturePage.pageName = "Signature";
            signaturePage.isDocUpload = false;
            signaturePage.isSummary = false;
            signaturePage.isSignature = true;
            signaturePage.isFormPage = false;
            pageDataRaw.push(signaturePage);
        }

        if (this.hasDocUpload) {
            let docUploadPage = {};
            docUploadPage.current = false;
            docUploadPage.className = "";
            docUploadPage.pageIndex = pageDataRaw.length;
            docUploadPage.pageName = "Document(s) Upload";
            docUploadPage.isDocUpload = true;
            docUploadPage.isSummary = false;
            docUploadPage.isSignature = false;
            docUploadPage.isFormPage = false;
            pageDataRaw.push(docUploadPage);
        }

        if (this.hasSummary) {
            let summaryPage = {};
            summaryPage.current = false;
            summaryPage.className = "";
            summaryPage.pageIndex = pageDataRaw.length;
            summaryPage.pageName = "Summary";
            summaryPage.isDocUpload = false;
            summaryPage.isSummary = true;
            summaryPage.isSignature = false;
            summaryPage.isFormPage = false;
            pageDataRaw.push(summaryPage);
        }

        if (this.isPrefillFieldsForm) {
            this.populateRecordIds(JSON.parse(JSON.stringify(pageDataRaw)));
        }
        else {
            this.pageData = JSON.parse(JSON.stringify(pageDataRaw));
        }
        console.log("this.pageData >> " + JSON.stringify(this.pageData));
    }

    populateRecordIds(pageData) {
        console.log("yep I am here");
        if (pageData && pageData.length) {
            pageData.forEach((page) => {
                if (page.sections && page.sections.length) {
                    page.sections.forEach((section) => {
                        if (section.fields && section.fields.length) {
                            if (!section.isSectionMulti) {
                                section.fields.forEach((field) => {
                                    if (field && field.isField) {
                                        if (
                                            field.fieldData.objectName == this.primaryObjectForPrefill
                                        ) {
                                            field.fieldData.recordId = this.recordId;
                                        }
                                    }
                                });
                            }
                        }
                    });
                }
            });
        }
        this.pageData = JSON.parse(JSON.stringify(pageData));
        //console.log('this.pageData >> '+JSON.stringify(this.pageData));
    }

    get firstPage() {
        if (this.pageData[0] && this.pageData[0].current) {
            return this.pageData[0].current;
        }
    }

    get lastPage() {
        if (
            this.pageData[this.pageData.length - 1] &&
            this.pageData[this.pageData.length - 1].current
        ) {
            return this.pageData[this.pageData.length - 1].current;
        }
    }

    sleep(ms) {
        return new Promise((res) => setTimeout(res, ms));
    }

    loadAllData() {
        let setTimeoutVar = setTimeout(() => {
            let currentPagePos = this.pageData.findIndex((page) => page.current);
            if (currentPagePos != this.pageData.length - 1) {
                this.isLoading = true;
                console.log("STARTED..." + currentPagePos);
                console.log("Page..." + this.pageData.length - 1);
                this.pageData[currentPagePos].className = "completed";
                this.pageData[currentPagePos].current = false;
                this.pageData[currentPagePos + 1].className = "active";
                this.pageData[currentPagePos + 1].current = true;
            }
            else {
                this.pageData.forEach((page) => {
                    if (page.pageIndex == 0) {
                        page.className = "active";
                        page.current = true;
                        if (page.pageName == "Document(s) Upload") {
                            page.isDocUpload = true;
                        }
                        else {
                            page.isDocUpload = false;
                            page.isFormPage = true;
                        }
                        if (page.pageName == "Summary") {
                            page.isSummary = true;
                        }
                        else {
                            page.isSummary = false;
                            page.isFormPage = true;
                        }
                        if (page.pageName == "Signature") {
                            page.isSignature = true;
                        }
                        else {
                            page.isSignature = false;
                            page.isFormPage = true;
                        }
                    }
                    else {
                        page.className = "";
                        page.current = false;
                        if (page.pageName == "Document(s) Upload") {
                            page.isDocUpload = true;
                        }
                        else {
                            page.isDocUpload = false;
                            page.isFormPage = true;
                        }
                        if (page.pageName == "Summary") {
                            page.isSummary = true;
                        }
                        else {
                            page.isSummary = false;
                            page.isFormPage = true;
                        }
                        if (page.pageName == "Signature") {
                            page.isSignature = true;
                        }
                        else {
                            page.isSignature = false;
                            page.isFormPage = true;
                        }
                    }
                });
                this.isLoading = false;
                clearTimeout(setTimeoutVar);
                return;
            }
            if (
                this.pageData[currentPagePos] &&
                this.pageData[currentPagePos].length
            ) {
                this.pageData[currentPagePos].forEach((page) => {
                    if (page.sections && page.sections.length) {
                        page.sections.forEach((section) => {
                            if (section.fields && section.fields.length) {
                                if (!section.isSectionMulti) {
                                    section.fields.forEach((field) => {
                                        if (field && field.isField) {
                                            field.fieldData.hasOnLoadRun = true;
                                        }
                                    });
                                }
                                else {
                                    section.fields.forEach((record) => {
                                        if (record && record.recordFields) {
                                            record.recordFields.forEach((field) => {
                                                if (field && field.isField) {
                                                    field.fieldData.hasOnLoadRun = true;
                                                }
                                            });
                                        }
                                    });
                                }
                            }
                        });
                    }
                });
            }
            this.loadAllData();
        }, 1000);
    }

    async handleNavigation(event) {
        let buttonName = event.target.name;

        if (buttonName == "next") {
            let currentPagePos = this.pageData.findIndex((page) => page.current);
            let isCurrentPageReqDepFormsCompleted = true;
            if (this.pageData[currentPagePos].dependentForms) {
                await this.updateDependentFormStatus();
                this.pageData[currentPagePos].dependentForms.forEach((eachForm) => {
                    console.log("eachForm.submitted >> " + eachForm.submitted);
                    if (
                        eachForm.showFlagForForm &&
                        eachForm.requiredFlagForForm &&
                        !eachForm.submitted
                    ) {
                        isCurrentPageReqDepFormsCompleted = false;
                        this.error =
                            "Complete and submit the additional form by clicking the link below.";
                    }
                });
            }
            let isCurrentPageValid = false;
            isCurrentPageValid = this.validatePage(currentPagePos);
            if (isCurrentPageValid && isCurrentPageReqDepFormsCompleted) {
                this.error = undefined;
                this.pageData[currentPagePos].className = "completed";
                this.pageData[currentPagePos].current = false;
                this.pageData[currentPagePos + 1].className = "active";
                this.pageData[currentPagePos + 1].current = true;
            }
        }
        else if (buttonName == "previous") {
            let currentPagePos = this.pageData.findIndex((page) => page.current);
            this.pageData[currentPagePos].className = "";
            this.pageData[currentPagePos].current = false;
            this.pageData[currentPagePos - 1].className = "active";
            this.pageData[currentPagePos - 1].current = true;
        }
    }

    async updateDependentFormStatus() {
        /* await getTrackerRecordStatus({
                parentJSId: this.parentFormJSId
            })
            .then((result) => {
                console.log("result >> " + JSON.stringify(result));
                if (result && result.length != 0) {
                    this.pageData.forEach((page) => {
                        if (page.dependentForms && page.dependentForms.length != 0) {
                            page.dependentForms.forEach((form) => {
                                if (
                                    result.findIndex((x) => x.Id == form.trackerRecordId) != -1
                                ) {
                                    form.submitted = true;
                                    console.log("form.submitted >> " + form.submitted);
                                    console.log(
                                        "form.trackerRecordId >> " + form.trackerRecordId
                                    );
                                }
                                else {
                                    form.submitted = false;
                                }
                            });
                        }
                    });
                    //this.pageData = JSON.parse(JSON.stringify(this.pageData));
                }
            })
            .catch((error) => {
                this.error = JSON.stringify(error);
                console.log(JSON.stringify(error));
            }); */
    }

    updateValue(event) {
        /* console.log('sectionIsMulti >> ',event.detail.sectionIsMulti);
            console.log('pageIndex >> ',event.detail.pageIndex);
            console.log('sectionIndex >> ',event.detail.sectionIndex);
            console.log('recordIndex >> ',event.detail.recordIndex);
            console.log('fieldIndex >> ',event.detail.field.fieldIndex);
            console.log('fieldApi >> ',event.detail.field.fieldApi); */
        console.log("value >> ", event.detail.value);
        let controllingFieldObject;
        let recordIndex;
        let controllingFieldApi;
        let controllingFieldValue;

        //console.log('event.detail.sectionIsMulti >> ',event.detail.sectionIsMulti);

        if (!event.detail.sectionIsMulti) {
            this.pageData[event.detail.pageIndex].sections[
                    event.detail.sectionIndex
                ].fields[event.detail.field.fieldIndex].fieldData.inputValue =
                event.detail.value;
            //this.pageData[event.detail.pageIndex].sections[event.detail.sectionIndex].fields[event.detail.field.fieldIndex].fieldData.hasOnLoadRun = true;

            controllingFieldObject =
                this.pageData[event.detail.pageIndex].sections[
                    event.detail.sectionIndex
                ].fields[event.detail.field.fieldIndex].fieldData.objectName;
            controllingFieldApi =
                this.pageData[event.detail.pageIndex].sections[
                    event.detail.sectionIndex
                ].fields[event.detail.field.fieldIndex].fieldData.fieldApi;
            controllingFieldValue =
                this.pageData[event.detail.pageIndex].sections[
                    event.detail.sectionIndex
                ].fields[event.detail.field.fieldIndex].fieldData.inputValue;

            if (this.rules && this.rules.length) {
                this.showFieldsOnCondition(
                    this.pageData[event.detail.pageIndex].sections[
                        event.detail.sectionIndex
                    ].fields[event.detail.field.fieldIndex].fieldData.fieldUniqueName,
                    this.pageData[event.detail.pageIndex].sections[
                        event.detail.sectionIndex
                    ].fields[event.detail.field.fieldIndex].fieldData.inputValue
                );
            }
        }
        else {
            /* console.log('<< this.pageData >> ',JSON.stringify(this.pageData)); */
            this.pageData[event.detail.pageIndex].sections[
                event.detail.sectionIndex
            ].fields[event.detail.recordIndex - 1].recordFields[
                event.detail.field.fieldIndex
            ].fieldData.inputValue = event.detail.value;

            //this.pageData[event.detail.pageIndex].sections[event.detail.sectionIndex].fields[event.detail.recordIndex-1].recordFields[event.detail.field.fieldIndex].fieldData.hasOnLoadRun = true;

            controllingFieldObject =
                this.pageData[event.detail.pageIndex].sections[
                    event.detail.sectionIndex
                ].fields[event.detail.recordIndex - 1].recordFields[
                    event.detail.field.fieldIndex
                ].fieldData.objectName;
            controllingFieldApi =
                this.pageData[event.detail.pageIndex].sections[
                    event.detail.sectionIndex
                ].fields[event.detail.recordIndex - 1].recordFields[
                    event.detail.field.fieldIndex
                ].fieldData.fieldApi;
            controllingFieldValue =
                this.pageData[event.detail.pageIndex].sections[
                    event.detail.sectionIndex
                ].fields[event.detail.recordIndex - 1].recordFields[
                    event.detail.field.fieldIndex
                ].fieldData.inputValue;
            recordIndex = event.detail.recordIndex;
        }

        this.updateControllingFieldValue(
            recordIndex,
            controllingFieldObject,
            controllingFieldApi,
            controllingFieldValue
        );

        console.log("page data >> ", JSON.stringify(this.pageData));
    }

    updateControllingFieldValue(recIndex, fieldObject, fieldApi, fieldValue) {
        //console.log('recIndex >> ',recIndex);
        //console.log('fieldObject >> ',fieldObject);
        this.pageData.forEach((page) => {
            if (page.sections && page.sections.length) {
                page.sections.forEach((section) => {
                    section.fields.forEach((field) => {
                        if (!section.isSectionMulti) {
                            if (
                                field.fieldData.objectName == fieldObject &&
                                field.fieldData.controllingField == fieldApi
                            ) {
                                field.fieldData.controllingFieldValue = fieldValue;
                            }
                        }
                        else {
                            if (field.recordIndex === recIndex) {
                                field.recordFields.forEach((recField) => {
                                    if (
                                        recField.fieldData.objectName == fieldObject &&
                                        recField.fieldData.controllingField == fieldApi
                                    ) {
                                        recField.fieldData.controllingFieldValue = fieldValue;
                                    }
                                });
                            }
                        }
                    });
                });
            }
        });

        /* console.log('this.pageData >> ',JSON.stringify(this.pageData)); */
    }

    validatePage(currentPagePos) {
        let valid = true;
        let householdFields = [];
        let pageName = this.pageData[currentPagePos].pageName;
        if (pageName == "Signature") {
            if (!this.signatureData || this.signatureData.length == 0) {
                valid = false;
                this.error = "Please sign to proceed.";
            }
        }
        else if (pageName == "Document(s) Upload") {
            if (!this.uploadedDocuments || this.uploadedDocuments.length == 0) {
                valid = false;
                this.error = "Please upload at least 1 document to proceed.";
            }
        }
        else {
            if (
                this.pageData[currentPagePos].sections &&
                this.pageData[currentPagePos].sections.length
            ) {
                this.pageData[currentPagePos].sections.forEach((section) => {
                    if (!section.isSectionMulti) {
                        if (section.fields.length) {
                            section.fields.forEach((field) => {
                                if (valid) {
                                    if (field.isField) {
                                        field.fieldData.hasOnLoadRun = true;
                                        if (field.fieldData.dataType != "BOOLEAN") {
                                            let ss = field.fieldData.required;
                                            let kk = !field.fieldData.hide;
                                            let vv;

                                            //console.log("value  >> ",field.fieldData.inputValue);
                                            //console.log("type of  >> ",typeof field.fieldData.inputValue);
                                            if (field.fieldData.inputValue) {
                                                if (
                                                    typeof field.fieldData.inputValue == "number" &&
                                                    (field.fieldData.inputValue != null ||
                                                        field.fieldData.inputValue == 0)
                                                ) {
                                                    vv = "has value";
                                                }
                                                else if (
                                                    (typeof field.fieldData.inputValue == "string" &&
                                                        field.fieldData.inputValue.trim() !== "") ||
                                                    field.fieldData.inputValue == 0
                                                ) {
                                                    vv = "has value";
                                                }
                                                else if (
                                                    typeof field.fieldData.inputValue == "object" &&
                                                    field.fieldData.inputValue.length
                                                ) {
                                                    vv = "has value";
                                                }
                                            }

                                            if (field.fieldData.inputValue === 0) {
                                                vv = "has value";
                                            }
                                            // console.log('ss >> ',ss);
                                            // console.log('vv >> ',vv);
                                            if (kk && ss && vv !== "has value") {
                                                valid = false;
                                                this.error = "Please complete all the required fields.";
                                            }
                                        }
                                        else {
                                            if (field.fieldData.inputValue == "") {
                                                var isTrueSet = field.fieldData.defaultValue === "true";
                                                field.fieldData.inputValue == isTrueSet;
                                            }
                                        }

										if (field.fieldData.isQuestion && field.fieldData.dataType == 'PHONE') {
											if(field.fieldData.inputValue && field.fieldData.inputValue.length > 0){
												console.log('Phone >> '+field.fieldData.inputValue);
												let isCorrectFormat = this.isPhone(field.fieldData.inputValue);
												console.log(isCorrectFormat);
												if (!isCorrectFormat) {
													valid = false;
													this.error = "Please enter the phone number in correct format i.e. 111-222-3333";
												}
											}
										}
                                    }
                                }
                            });
                        }
                    }
                    else {
                        if (section.fields && section.fields.length) {
                            section.fields.forEach((record) => {
                                if (record.recordFields.length) {
                                    householdFields = [];
                                    record.recordFields.forEach((field) => {
                                        if (valid) {
                                            if (field.isField) {
                                                field.fieldData.hasOnLoadRun = true;
                                                if (field.fieldData.dataType != "BOOLEAN") {
                                                    let ss = field.fieldData.required;
                                                    let vv;

                                                    if (field.fieldData.inputValue) {
                                                        console.log(
                                                            "&&&& >>" + typeof field.fieldData.inputValue
                                                        );
                                                        if (
                                                            typeof field.fieldData.inputValue == "number" &&
                                                            (field.fieldData.inputValue != null ||
                                                                field.fieldData.inputValue == 0)
                                                        ) {
                                                            vv = "has value";
                                                        }
                                                        else if (
                                                            typeof field.fieldData.inputValue == "string" &&
                                                            field.fieldData.inputValue.trim() !== ""
                                                        ) {
                                                            vv = "has value";
                                                        }
                                                        else if (
                                                            typeof field.fieldData.inputValue == "object" &&
                                                            field.fieldData.inputValue.length
                                                        ) {
                                                            vv = "has value";
                                                        }
                                                    }
                                                    if (ss && vv !== "has value") {
                                                        valid = false;
                                                        this.error =
                                                            "Please complete all the required fields.";
                                                    }
                                                }
                                                else {
                                                    if (field.fieldData.inputValue == "") {
                                                        var isTrueSet =
                                                            field.fieldData.defaultValue === "true";
                                                        field.fieldData.inputValue == isTrueSet;
                                                    }
                                                }

												if (field.fieldData.isQuestion && field.fieldData.dataType == 'PHONE') {
													if(field.fieldData.inputValue && field.fieldData.inputValue.length > 0){
														console.log('Phone >> '+field.fieldData.inputValue);
														let isCorrectFormat = this.isPhone(field.fieldData.inputValue);
														console.log(isCorrectFormat);
														if (!isCorrectFormat) {
															valid = false;
															this.error = "Please enter the phone number in correct format i.e. 111-222-3333";
														}
													}
												}
                                            }
                                        }
                                        else {
                                            valid = false;
                                        }
                                    });
                                    /* if(this.isCreateApplication){
                                                          if(!householdFields.includes('Client__c')){
                                                              valid = false;
                                                              this.error = 'Please select/create client for each member.';
                                                          }    
                                                          //valid = true;
                                                      } */
                                }
                            });
                        }
                    }
                });
            }
        }
        return valid;
    }

    handleAddRow(event) {
        let currentPagePos = event.detail.pageIndex;
        let currentSectionPos = event.detail.sectionIndex;

        let sectionFieldsLength =
            this.pageData[currentPagePos].sections[currentSectionPos].fields.length;
        console.log("sectionFieldsLength >> " + sectionFieldsLength);
        let tempRecord = JSON.parse(
            JSON.stringify(
                this.pageData[currentPagePos].sections[currentSectionPos].fields[
                    sectionFieldsLength - 1
                ]
            )
        );
        tempRecord.recordIndex = sectionFieldsLength + 1;
        if (tempRecord.recordFields) {
            tempRecord.recordFields.forEach((field) => {
                field.fieldData.inputValue = "";
                field.fieldData.recordId = "";
                field.fieldData.identifier = tempRecord.recordIndex;
                if (field.fieldData.controllingFieldValue) {
                    field.fieldData.controllingFieldValue = undefined;
                }
            });
        }
        this.pageData[currentPagePos].sections[currentSectionPos].fields.push(
            tempRecord
        );

        //console.log('page data after add row >> ',JSON.stringify(this.pageData));
    }

    handleDeleteRow(event) {
        let currentPagePos = event.detail.pageIndex;
        let currentSectionPos = event.detail.sectionIndex;
        let currentRecordPos = event.detail.recordIndex;

        if (
            this.pageData[currentPagePos].sections[currentSectionPos].fields.length >
            1
        ) {
            this.pageData[currentPagePos].sections[currentSectionPos].fields.splice(
                currentRecordPos - 1,
                1
            );
        }
        this.refreshIndexes();
    }

    refreshIndexes() {
        let i = 0;
        this.pageData.forEach((page) => {
            page.pageIndex = i++;
            if (page.sections) {
                let j = 0;
                page.sections.forEach((section) => {
                    section.sectionIndex = j;
                    section.sectionClass = "section" + j++;
                    if (!section.isSectionMulti) {
                        if (section.fields) {
                            let k = 0;
                            section.fields.forEach((field) => {
                                field.fieldIndex = k;
                                field.fieldClass = "field" + k++;
                            });
                        }
                    }
                    else {
                        if (section.fields) {
                            let k = 1;
                            section.fields.forEach((record) => {
                                record.recordIndex = k;
                                if (record.recordFields) {
                                    let l = 0;
                                    record.recordFields.forEach((field) => {
                                        field.fieldIndex = l;
                                        field.fieldClass = "field" + l++;
                                    });
                                }
                                k++;
                            });
                        }
                    }
                });
            }
        });
    }

    handleDraftSave() {
        this.isDraftSave = true;
        this.openFromDraft = true;
        this.handleSubmit();
    }

    async confirmSubmit() {
        let currentPagePos = this.pageData.findIndex((page) => page.current);
        let isCurrentPageReqDepFormsCompleted = true;
        this.error = undefined;
        if (this.pageData[currentPagePos].dependentForms) {
            await this.updateDependentFormStatus(currentPagePos);
            this.pageData[currentPagePos].dependentForms.forEach(async (eachForm) => {
                console.log("eachForm from submit >> " + eachForm.submitted);
                if (
                    eachForm.showFlagForForm &&
                    eachForm.requiredFlagForForm &&
                    !eachForm.submitted
                ) {
                    isCurrentPageReqDepFormsCompleted = false;
                    this.error =
                        "Complete and submit the additional form by clicking the link below.";
                }
                else if (eachForm.showFlagForForm && eachForm.submitted) {
                    eachForm.submitted = true;
                }
            });
        }
        let isCurrentPageValid = false;
        isCurrentPageValid = this.validatePage(currentPagePos);
        if (isCurrentPageValid && isCurrentPageReqDepFormsCompleted) {
            this.isConfirmationBox = true;
        }
    }

    handleNo() {
        this.isConfirmationBox = false;
    }

    handleSubmit() {
        this.isConfirmationBox = false;
        this.error = undefined;
        
        // Prepare form data structures
        this.prepareFormData();
        
        // Log prepared data
        console.log('primary final >> ', JSON.stringify(this.primaryObjectStructure));
        console.log('children final >> ', JSON.stringify(this.childrenObjectStructure));
        console.log('parents >> ', JSON.stringify(this.parentsObjectStructure));
        console.log('grandchildren >> ', JSON.stringify(this.grandChildrenObjectStructure));
        console.log('questionsResponses >> ', JSON.stringify(this.questionsResponses));

        // If there's an error, dispatch event and return
        if (this.error) {
            this.dispatchFormSubmittedEvent(null, false);
            return;
        }

        // Route to appropriate save method
        if (!this.isPDFOnly) {
            this.saveFormData();
        } else {
            this.savePDFOnlyForm();
        }
    }

    prepareFormData() {
        // Initialize data structures
        [
            this.primaryObjectStructure,
            this.parentsObjectStructure,
            this.childrenObjectStructure,
            this.grandChildrenObjectStructure
        ] = this.createData();

        // Reset questions responses
        this.questionsResponses = [];

        // Process page data and populate structures
        this.pageData.forEach((page) => {
            if (page.sections && page.sections.length) {
                page.sections.forEach((section) => {
                    if (!section.isSectionMulti) {
                        this.processSingleSectionFields(section);
                    } else {
                        this.processMultiSectionFields(section);
                    }
                });
            }
        });
    }

    processSingleSectionFields(section) {
        if (section.fields && section.fields.length) {
            section.fields.forEach((field) => {
                this.processField(field);
            });
        }
    }

    processMultiSectionFields(section) {
        if (section.fields && section.fields.length) {
            section.fields.forEach((record) => {
                if (record.recordFields && record.recordFields.length) {
                    record.recordFields.forEach((field) => {
                        this.processField(field, record.recordIndex);
                    });
                }
            });
        }
    }

    processField(field, recordIndex) {
        if (!field.fieldData) {
            return;
        }

        const fieldData = field.fieldData;
        const objectName = fieldData.objectName;

        // Skip hidden or formula fields
        if (fieldData.hide || fieldData.isFormulaField) {
            return;
        }

        // Process primary object fields
        if (objectName === this.primaryObjectStructure.objectName) {
            this.addFieldToStructure(this.primaryObjectStructure, fieldData);
            
            // Add record ID if present
            if (fieldData.recordId && fieldData.recordId.length) {
                if (this.primaryObjectStructure.fieldValue.findIndex(
                    (x) => x.fieldApi === "Id"
                ) === -1) {
                    this.primaryObjectStructure.fieldValue.push({
                        fieldApi: "Id",
                        inputValue: fieldData.recordId
                    });
                }
            }
        }

        // Process parent object fields
        if (this.parentsObjectStructure && this.parentsObjectStructure.length) {
            this.parentsObjectStructure.forEach((parent) => {
                if (objectName === parent.objectName) {
                    this.addFieldToStructure(parent, fieldData);
                }
            });
        }

        // Process child object fields
        if (this.childrenObjectStructure && this.childrenObjectStructure.length) {
            this.childrenObjectStructure.forEach((child) => {
                if (objectName === child.objectName) {
                    const fieldValue = {
                        fieldApi: fieldData.fieldApi,
                        inputValue: fieldData.inputValue
                    };
                    if (recordIndex !== undefined) {
                        fieldValue.recordIdentifier = recordIndex;
                    } else if (fieldData.identifier) {
                        fieldValue.recordIdentifier = parseInt(
                            fieldData.identifier.charAt(fieldData.identifier.length - 1)
                        );
                    }
                    child.fieldValue.push(fieldValue);
                }
            });
        }

        // Process grandchild object fields
        if (this.grandChildrenObjectStructure && this.grandChildrenObjectStructure.length) {
            this.grandChildrenObjectStructure.forEach((grandchild) => {
                if (objectName === grandchild.objectName) {
                    this.addFieldToStructure(grandchild, fieldData);
                }
            });
        }

        // Process question responses
        if (objectName === "Question") {
            const questionData = {
                fieldApi: fieldData.fieldApi,
                inputValue: typeof fieldData.inputValue === "string" 
                    ? [fieldData.inputValue] 
                    : fieldData.inputValue
            };
            this.questionsResponses.push(questionData);
        }
    }

    addFieldToStructure(structure, fieldData) {
        structure.fieldValue.push({
            fieldApi: fieldData.fieldApi,
            inputValue: fieldData.inputValue
        });
    }

    saveFormData() {
        this.isLoading = true;
        const params = {
            parentObjectList: JSON.stringify(this.parentsObjectStructure),
            primaryObjectList: JSON.stringify(this.primaryObjectStructure),
            childObjectsList: JSON.stringify(this.childrenObjectStructure),
            grandChildObjectList: JSON.stringify(this.grandChildrenObjectStructure),
            questionObjectsList: JSON.stringify(this.questionsResponses),
            formId: this.formId,
            isVerifyApplication: false
        };

        saveObjectStructure({ params: JSON.stringify(params) })
            .then((result) => {
                this.isLoading = false;
                console.log("result - ", JSON.stringify(result));
                this.dataSaved = result.isSuccess;
                
                if (!this.dataSaved) {
                    this.error = result.errorMessage;
                    this.dispatchFormSubmittedEvent(null, false);
                } else {
                    this.primaryRecordId = result.primaryRecordId;
                    
                    if (!this.isDraftSave) {
                        this.handleSuccessfulSave();
                    } else {
                        // Draft save - dispatch event with recordId
                        this.dispatchFormSubmittedEvent(this.primaryRecordId, true);
                    }
                }
            })
            .catch((error) => {
                this.isLoading = false;
                console.log("error >> ", JSON.stringify(error));
                this.error = JSON.stringify(error);
                this.dispatchFormSubmittedEvent(null, false);
            });
    }

    handleSuccessfulSave() {
        this.movePrintFilesAndDeleteTrackerRecords(this.primaryRecordId);
        this.error = undefined;

        // Handle PDF attachment if needed
        if (this.needPDF && this.pageData && this.pageData.length) {
            this.attachPDFAndComplete();
        } else {
            // No PDF needed - handle signature and documents, then dispatch event
            this.handleSignatureAndDocuments()
                .then(() => {
                    this.dispatchFormSubmittedEvent(this.primaryRecordId, true);
                })
                .catch((error) => {
                    console.error("Error in handleSignatureAndDocuments: ", error);
                    this.dispatchFormSubmittedEvent(this.primaryRecordId, true);
                });
        }
    }

    attachPDFAndComplete() {
        attachPrintJsonToRecord({
            jsonData: JSON.stringify(this.pageData),
            recordId: this.primaryRecordId,
            formId: this.formId
        })
        .then((r) => {
            if (r) {
                this.savedPrintJsonWithDateTime = r;
                console.log("this.savedPrintJsonWithDateTime >> " + this.savedPrintJsonWithDateTime);
                
                // Handle signature if needed
                if (this.needSignature && this.signatureData && this.signatureData.length) {
                    this.saveSignatureAndComplete(this.primaryRecordId, this.savedPrintJsonWithDateTime);
                } else {
                    // No signature needed - handle documents and dispatch event
                    this.handleDocumentsUpload()
                        .then(() => {
                            this.dispatchFormSubmittedEvent(this.primaryRecordId, true);
                        })
                        .catch((error) => {
                            console.error("Error in handleDocumentsUpload: ", error);
                            this.dispatchFormSubmittedEvent(this.primaryRecordId, true);
                        });
                }
            } else {
                // PDF attachment returned no result - still dispatch event
                this.handleDocumentsUpload()
                    .then(() => {
                        this.dispatchFormSubmittedEvent(this.primaryRecordId, true);
                    })
                    .catch((error) => {
                        console.error("Error in handleDocumentsUpload: ", error);
                        this.dispatchFormSubmittedEvent(this.primaryRecordId, true);
                    });
            }
        })
        .catch((e) => {
            this.error = JSON.stringify(e);
            console.error(JSON.stringify(e));
            // Even on error, dispatch event
            this.dispatchFormSubmittedEvent(this.primaryRecordId, false);
        });
    }

    saveSignatureAndComplete(recordId, signatureTitle) {
        let convertedDataURI = this.signatureData.replace(
            /^data:image\/(png|jpg);base64,/,
            ""
        );
        
        saveSignature({
            signElement: convertedDataURI,
            recId: recordId,
            signatureTitle: signatureTitle
        })
        .then((result) => {
            this.signatureData = undefined;
            this.error = undefined;
            
            // Handle documents upload, then dispatch event
            this.handleDocumentsUpload()
                .then(() => {
                    this.dispatchFormSubmittedEvent(recordId, true);
                })
                .catch((error) => {
                    console.error("Error in handleDocumentsUpload: ", error);
                    this.dispatchFormSubmittedEvent(recordId, true);
                });
        })
        .catch((error) => {
            console.log("signature error >> ", JSON.stringify(error));
            this.error = JSON.stringify(error);
            // Even on signature error, dispatch event
            this.handleDocumentsUpload()
                .then(() => {
                    this.dispatchFormSubmittedEvent(recordId, false);
                })
                .catch((docError) => {
                    console.error("Error in handleDocumentsUpload: ", docError);
                    this.dispatchFormSubmittedEvent(recordId, false);
                });
        });
    }

    handleSignatureAndDocuments() {
        return new Promise((resolve) => {
            const promises = [];
            
            // Handle signature if needed
            if (this.needSignature && this.signatureData && this.signatureData.length) {
                let convertedDataURI = this.signatureData.replace(
                    /^data:image\/(png|jpg);base64,/,
                    ""
                );
                promises.push(
                    saveSignature({
                        signElement: convertedDataURI,
                        recId: this.primaryRecordId,
                        signatureTitle: this.savedPrintJsonWithDateTime || new Date().toISOString()
                    }).then(() => {
                        this.signatureData = undefined;
                    }).catch((error) => {
                        console.error("Signature save error: ", error);
                        // Continue even if signature fails
                    })
                );
            }
            
            // Handle documents upload
            promises.push(this.handleDocumentsUpload());
            
            Promise.allSettled(promises).then(() => {
                resolve();
            });
        });
    }

    handleDocumentsUpload() {
        return new Promise((resolve) => {
            if (this.hasDocUpload && this.uploadedDocuments && this.uploadedDocuments.length) {
                console.log('Inside Doc Upload');
                uploadFiles({
                    recordId: this.primaryRecordId,
                    filedata: JSON.stringify(this.uploadedDocuments)
                })
                .then((result) => {
                    console.log(result);
                    if (result && result === "success") {
                        this.uploadedDocuments = [];
                    }
                    this.error = undefined;
                    resolve();
                })
                .catch((error) => {
                    console.error("error >> ", JSON.stringify(error));
                    this.error = JSON.stringify(error);
                    // Resolve anyway to continue flow
                    resolve();
                });
            } else {
                resolve();
            }
        });
    }

    savePDFOnlyForm() {
        let recId;
        if (this.isDependentForm) {
            recId = this.trackerRecordId;
        } else {
            recId = this.recordId;
        }
        
        console.log("recId >> " + recId);
        
        if (!this.isDependentForm) {
            this.movePrintFilesAndDeleteTrackerRecords(recId);
        }
        
        attachPrintJsonToRecord({
            jsonData: JSON.stringify(this.pageData),
            recordId: recId,
            formId: this.formId
        })
        .then((r) => {
            if (r) {
                this.savedPrintJsonWithDateTime = r;
                
                if (this.signatureData && this.signatureData.length) {
                    this.saveSignatureForPDFOnly(recId, this.savedPrintJsonWithDateTime);
                } else {
                    this.dataSaved = true;
                    this.dispatchFormSubmittedEvent(recId, true);
                }
            } else {
                // No result from attachPrintJsonToRecord - still dispatch event
                this.dispatchFormSubmittedEvent(recId, false);
            }
        })
        .catch((e) => {
            this.error = JSON.stringify(e);
            console.error(JSON.stringify(e));
            // Even on error, dispatch event
            this.dispatchFormSubmittedEvent(recId, false);
        });
    }

    saveSignatureForPDFOnly(recId, signatureTitle) {
        let convertedDataURI = this.signatureData.replace(
            /^data:image\/(png|jpg);base64,/,
            ""
        );
        
        saveSignature({
            signElement: convertedDataURI,
            recId: recId,
            signatureTitle: signatureTitle
        })
        .then((result) => {
            this.signatureData = undefined;
            this.error = undefined;
            this.dataSaved = true;
            this.dispatchFormSubmittedEvent(recId, true);
        })
        .catch((error) => {
            console.log("signature error >> ", JSON.stringify(error));
            this.error = JSON.stringify(error);
            // Even on signature error, dispatch event
            this.dispatchFormSubmittedEvent(recId, false);
        });
    }

    dispatchFormSubmittedEvent(recordId, isSuccess) {
        const eventDetail = {
            recordId: recordId,
            isSuccess: isSuccess,
            isDraftSave: this.isDraftSave,
            error: this.error
        };
        
        console.log("=== FORM SUBMITTED EVENT DISPATCHED ===");
        console.log("Event Details:", JSON.stringify(eventDetail, null, 2));
        console.log("Record ID:", recordId);
        console.log("Is Success:", isSuccess);
        console.log("Is Draft Save:", this.isDraftSave);
        console.log("Is PDF Only:", this.isPDFOnly);
        console.log("Error:", this.error || "None");
        console.log("========================================");
        
        this.dispatchEvent(
            new CustomEvent("formsubmitted", {
                detail: eventDetail
            })
        );
        
        console.log("formsubmitted event dispatched successfully");
    }

    movePrintFilesAndDeleteTrackerRecords(recId) {
        let trackerRecordIds = [];
        if (this.pageData && this.pageData.length) {
            this.pageData.forEach((eachPage) => {
                if (eachPage.dependentForms && eachPage.dependentForms.length) {
                    eachPage.dependentForms.forEach((eachForm) => {
                        trackerRecordIds.push(eachForm.trackerRecordId);
                    });
                }
            });
        }
        console.log("recId >> " + recId);
        console.log("trackerRecordIds >> " + JSON.stringify(trackerRecordIds));
        /* moveJsonsAndDeleteTrackerRecords({
                primaryRecordId: recId,
                trackerRecordIds: trackerRecordIds
            })
            .then((result) => {
                if (result == "Done") {
                    console.log("DONE");
                }
            })
            .catch((error) => {
                this.error = JSON.stringify(error);
            }); */
    }

    showFieldsOnCondition(primaryFieldName, inputValue) {
        // console.log('primaryFieldName - ',primaryFieldName, 'inputValue - ',inputValue);
        if (this.rules) {
            this.rules.forEach((eachRule) => {
                var showSecondaryField = false;
                var secondaryFieldUniqueName = "";
                if (
                    eachRule.primaryField != null &&
                    eachRule.primaryField != "" &&
                    eachRule.primaryField != undefined &&
                    eachRule.primaryField == primaryFieldName
                ) {
                    var primaryFieldValue = eachRule.value;
                    secondaryFieldUniqueName = eachRule.secondaryField;
                    // console.log('old primaryFieldValue - ',primaryFieldValue, typeof primaryFieldValue, ' | inputValue - ',inputValue, typeof inputValue);
                    if (
                        typeof inputValue === "string" &&
                        typeof primaryFieldValue === "string"
                    ) {
                        if (
                            inputValue.match(/\d+/g) == null &&
                            primaryFieldValue.match(/\d+/g) == null
                        ) {
                            primaryFieldValue = primaryFieldValue.toLowerCase();
                            inputValue = inputValue.toLowerCase();
                        }
                        else if (
                            inputValue.match(/\d+/g) != null &&
                            primaryFieldValue.match(/\d+/g) != null &&
                            eachRule.operator !== "contains"
                        ) {
                            primaryFieldValue = Number(primaryFieldValue);
                            inputValue = Number(inputValue);
                        }
                    }

                    // if(typeof inputValue === 'string' && inputValue.match(/\d+/g) == null){
                    //     inputValue = inputValue.toLowerCase();
                    // }
                    // else
                    // if(typeof inputValue === 'string' && inputValue.match(/\d+/g) != null && eachRule.operator !== 'contains'){
                    //     inputValue = Number(inputValue);
                    // }

                    // if(typeof primaryFieldValue === 'string' && primaryFieldValue.match(/\d+/g) == null){
                    //     primaryFieldValue = primaryFieldValue.toLowerCase();
                    // }
                    // else
                    // if(typeof primaryFieldValue === 'string' && primaryFieldValue.match(/\d+/g) != null && eachRule.operator !== 'contains'){
                    //     primaryFieldValue = Number(primaryFieldValue);
                    // }

                    // console.log('new primaryFieldValue - ',primaryFieldValue, typeof primaryFieldValue, ' | inputValue - ',inputValue, typeof inputValue);
                    // console.log('operator - ',eachRule.operator);
                    switch (eachRule.operator) {
                        case "equals":
                            if (primaryFieldValue === inputValue) {
                                showSecondaryField = true;
                            }
                            break;
                        case "contains":
                            if (inputValue.includes(primaryFieldValue)) {
                                showSecondaryField = true;
                            }
                            break;
                        case "islessthanequalto":
                            if (inputValue <= primaryFieldValue) {
                                showSecondaryField = true;
                            }
                            break;
                        case "isgreaterthanequalto":
                            if (inputValue >= primaryFieldValue) {
                                showSecondaryField = true;
                            }
                            break;
                        case "islessthan":
                            if (inputValue < primaryFieldValue) {
                                showSecondaryField = true;
                            }
                            break;
                        case "isgreaterthan":
                            if (inputValue > primaryFieldValue) {
                                showSecondaryField = true;
                            }
                            break;
                        case "isnotequalto":
                            if (primaryFieldValue !== inputValue) {
                                showSecondaryField = true;
                            }
                            break;
                    }
                }
                if (
                    secondaryFieldUniqueName != "" &&
                    eachRule.isPassed !== showSecondaryField
                ) {
                    // console.log('reached - ', secondaryFieldUniqueName, showSecondaryField);
                    var updateSecondaryFieldHideProperty = false;
                    var otherDependantRules = false;
                    this.rules.forEach((eachAnotherRule) => {
                        if (
                            secondaryFieldUniqueName === eachAnotherRule.secondaryField &&
                            primaryFieldName !== eachAnotherRule.primaryField
                        ) {
                            otherDependantRules = true;
                            // console.log('eachAnotherRule.isPassed - ', eachAnotherRule.isPassed, ' eachRule.isPassed - ',eachRule.isPassed);

                            if (
                                (showSecondaryField && !eachRule.isPassed) ||
                                (!showSecondaryField &&
                                    eachRule.isPassed &&
                                    !eachAnotherRule.isPassed)
                            ) {
                                updateSecondaryFieldHideProperty = true;
                            }
                            // console.log('updateSecondaryFieldHideProperty - ', updateSecondaryFieldHideProperty);
                        }
                    });
                    // console.log('checked dependant rules -- otherDependantRules - ', otherDependantRules, ' updateSecondaryFieldHideProperty - ',updateSecondaryFieldHideProperty);
                    if (
                        !otherDependantRules ||
                        (otherDependantRules && updateSecondaryFieldHideProperty)
                    ) {
                        this.updatePageJson(secondaryFieldUniqueName, showSecondaryField);
                        //this.updatePageJson(secondaryFieldUniqueName, showSecondaryField);
                    }
                    eachRule.isPassed = showSecondaryField;
                }
            });
        }
    }

    updatePageJson(fieldName, hideOrShowField) {
        this.pageData.forEach((eachPage) => {
            if (eachPage.dependentForms) {
                eachPage.dependentForms.forEach((eachForm) => {
                    if (fieldName.includes(eachForm.formId)) {
                        eachForm.showFlagForForm = hideOrShowField;
                        if (hideOrShowField) {
                            /* createDependentFormsTrackerRecord({
                                    parentFormJSId: this.parentFormJSId,
                                    parentFormId: this.formId,
                                    dependentFormId: eachForm.formId,
                                    required: eachForm.requiredFlagForForm
                                })
                                .then((result) => {
                                    //eachForm.formLink = eachForm.formLink+'&c__trackerRecordId='+result;
                                    console.log("form link >> " + eachForm.formLink);
                                    let updatedFormLink = eachForm.formLink;
                                    updatedFormLink =
                                        updatedFormLink + "&c__trackerRecordId=" + result;
                                    eachForm.formLink = updatedFormLink;
                                    eachForm.trackerRecordId = result;
                                    console.log("updated form link >> " + eachForm.formLink);
                                })
                                .catch((error) => {
                                    this.error = JSON.stringify(error);
                                }); */
                        }
                        else {
                            /* deleteDependentFormsTrackerRecord({
                                    parentFormJSId: this.parentFormJSId,
                                    parentFormId: this.formId,
                                    dependentFormId: eachForm.formId,
                                    required: eachForm.requiredFlagForForm
                                })
                                .then((result) => {
                                    console.log("tracker record deleted");
                                    eachForm.formLink = eachForm.formLink.substring(
                                        0,
                                        eachForm.formLink.lastIndexOf("&")
                                    );
                                    eachForm.trackerRecordId = undefined;
                                    console.log("eachForm.formLink >> " + eachForm.formLink);
                                })
                                .catch((error) => {
                                    this.error = JSON.stringify(error);
                                }); */
                        }
                    }
                });
            }
            if (eachPage.sections && eachPage.sections.length) {
                eachPage.sections.forEach((eachSection) => {
                    if (!eachSection.isSectionMulti) {
                        eachSection.fields.forEach((eachField) => {
                            if (
                                eachField.fieldData.fieldUniqueName != null &&
                                eachField.fieldData.fieldUniqueName != "" &&
                                eachField.fieldData.fieldUniqueName != undefined &&
                                eachField.fieldData.fieldUniqueName == fieldName
                            ) {
                                eachField.fieldData.hide = !hideOrShowField;
                                //console.log('condition reached, hide field? - ',eachField.fieldData.hide);
                            }
                        });
                    }
                });
            }
        });
    }

    getFieldJson(insertIndex, objectName, fieldName, inputVal) {
        return {
            fieldIndex: insertIndex,
            isLabelEdit: false,
            fieldClass: "field" + insertIndex,
            customlabel: "",
            isField: true,
            isRichTextBox: false,
            fieldData: {
                customlabel: "",
                dataType: "nodatatype",
                fieldApi: fieldName,
                fieldName: fieldName,
                fieldUniqueName: objectName + "::" + fieldName,
                identifier: 1,
                inputValue: inputVal,
                isDependentPicklist: false,
                isLabelEdit: false,
                isNotNillable: false,
                isQuestion: false,
                objectName: objectName,
                required: false,
                hide: true,
                hasOnLoadRun: true
            }
        };
    }

    createData() {
        let primary = {};
        let parents = [];
        let children = [];
        let grandchildren = [];

        primary.objectName = this.objectStructure.selectedValue;
        primary.recordType = this.objectStructure.selectedRecordType ?
            this.objectStructure.selectedRecordType :
            "";
        primary.parents = [];
        primary.fieldValue = [];

        if (this.objectStructure.relatedList.length) {
            this.objectStructure.relatedList.forEach((related) => {
                if (related.type === "Lookup(Parent)") {
                    let parent = {};
                    //parent.objectName = related.selectedValue.substring(0,related.selectedValue.indexOf('|'));
                    parent.objectName = related.selectedValue;
                    parent.recordType = related.selectedRecordType ?
                        related.selectedRecordType :
                        "";
                    parent.childFieldApi = related.selectedValue.substring(
                        related.selectedValue.indexOf("|") + 1,
                        related.selectedValue.length
                    );
                    parent.fieldValue = [];
                    primary.parents.push({
                        parentApi: parent.objectName,
                        parentFieldApi: related.selectedValue.substring(
                            related.selectedValue.indexOf("|") + 1,
                            related.selectedValue.length
                        ),
                        parentId: ""
                    });
                    parents.push(parent);
                }
                else {
                    let child = {
                        objectName: "",
                        parents: [],
                        fieldValue: []
                    };
                    //child.objectName = related.selectedValue.substring(0,related.selectedValue.indexOf('|'));
                    child.objectName = related.selectedValue;
                    child.recordType = related.selectedRecordType ?
                        related.selectedRecordType :
                        "";
                    child.parents.push({
                        parentApi: primary.objectName,
                        parentFieldApi: related.selectedValue.substring(
                            related.selectedValue.indexOf("|") + 1,
                            related.selectedValue.length
                        )
                    });

                    if (related.relatedList.length) {
                        related.relatedList.forEach((relatedOfRelated) => {
                            if (relatedOfRelated.type === "Lookup(Parent)") {
                                let parentOfChild = {};
                                //parentOfChild.objectName = relatedOfRelated.selectedValue.substring(0,relatedOfRelated.selectedValue.indexOf('|'));
                                parentOfChild.objectName = relatedOfRelated.selectedValue;
                                parentOfChild.recordType = relatedOfRelated.selectedRecordType ?
                                    relatedOfRelated.selectedRecordType :
                                    "";
                                parentOfChild.childFieldApi =
                                    relatedOfRelated.selectedValue.substring(
                                        relatedOfRelated.selectedValue.indexOf("|") + 1,
                                        relatedOfRelated.selectedValue.length
                                    );
                                parentOfChild.fieldValue = [];
                                child.parents.push({
                                    parentApi: parentOfChild.objectName,
                                    parentFieldApi: relatedOfRelated.selectedValue.substring(
                                        relatedOfRelated.selectedValue.indexOf("|") + 1,
                                        relatedOfRelated.selectedValue.length
                                    ),
                                    parentId: ""
                                });
                                parents.push(parentOfChild);
                            }
                            else {
                                let childOfChild = {
                                    objectName: "",
                                    parents: [],
                                    fieldValue: []
                                };
                                //childOfChild.objectName = relatedOfRelated.selectedValue.substring(0,relatedOfRelated.selectedValue.indexOf('|'));
                                childOfChild.objectName = relatedOfRelated.selectedValue;
                                childOfChild.recordType = relatedOfRelated.selectedRecordType ?
                                    relatedOfRelated.selectedRecordType :
                                    "";
                                childOfChild.parents.push({
                                    parentApi: child.objectName,
                                    parentFieldApi: relatedOfRelated.selectedValue.substring(
                                        relatedOfRelated.selectedValue.indexOf("|") + 1,
                                        relatedOfRelated.selectedValue.length
                                    ),
                                    parentId: ""
                                });
                                grandchildren.push(childOfChild);
                            }
                        });
                    }

                    children.push(child);
                }
            });
        }

        return [primary, parents, children, grandchildren];
    }

    openFileUpdoad() {
        this.openFileUploadModal = true;
        this.isUploadFiles = true;
    }

    openSignatureUpdoad() {
        this.openFileUploadModal = true;
        this.isUploadSignature = true;
    }

    closeModal() {
        this.openFileUploadModal = false;
        this.isUploadFiles = false;
        this.isUploadSignature = false;
    }

    handleUploadFiles(event) {
        this.filesData = event.detail;
        //console.log('this.filesData >> ',JSON.stringify(this.filesData));
        this.filesButtonLabel = "Files Uploaded";
        this.closeModal();
    }

    handleSignature(event) {
        this.signatureData = event.detail;
        console.log("signatureData >> ", JSON.stringify(this.signatureData));
        this.signatureButtonLabel = "Signed";
        //this.closeModal();
    }

    resetFileUpdoad() {
        this.filesData = undefined;
        this.filesButtonLabel = "Upload Files";
    }

    resetSignatureUpdoad() {
        this.signatureData = undefined;
        this.signatureButtonLabel = "Sign Form";
    }

    handleDocuments(event) {
        this.uploadedDocuments = event.detail;
        //console.log('this.uploadedDocuments >> ',JSON.stringify(this.uploadedDocuments));
    }

    handleEditPage(event) {
        let editPageIndex = event.detail;
        let currentPagePos = this.pageData.findIndex((page) => page.current);
        this.pageData[currentPagePos].className = "";
        this.pageData[currentPagePos].current = false;
        this.pageData[editPageIndex].className = "active";
        this.pageData[editPageIndex].current = true;
    }

    isValidSfId(str) {
        if (typeof str !== "string" || str.length !== 18) {
            return false;
        }

        let upperCaseToBit = (char) => (char.match(/[A-Z]/) ? "1" : "0");
        let binaryToSymbol = (digit) =>
            digit <= 25 ?
            String.fromCharCode(digit + 65) :
            String.fromCharCode(digit - 26 + 48);

        let parts = [
            str.slice(0, 5).split("").reverse().map(upperCaseToBit).join(""),
            str.slice(5, 10).split("").reverse().map(upperCaseToBit).join(""),
            str.slice(10, 15).split("").reverse().map(upperCaseToBit).join("")
        ];

        let check = parts.map((str) => binaryToSymbol(parseInt(str, 2))).join("");

        return check === str.slice(-3);
    }

    isNumeric(str) {
        if (typeof str != "string") return false; // we only process strings!
        return (
            !isNaN(str) && // use type coercion to parse the _entirety_ of the string (`parseFloat` alone does not do this)...
            !isNaN(parseFloat(str))
        ); // ...and ensure strings of whitespace fail
    }

	isPhone(phoneNumber){
		const phoneNumberRegex = /^\d{3}-\d{3}-\d{4}$/;

		if (phoneNumberRegex.test(phoneNumber)) {
			return true;
		} else {
			return false;
		}
	}

    topFunction() {
        let containerChoosen = this.template.querySelector(".theTop");
        containerChoosen.scrollIntoView();
    }
}