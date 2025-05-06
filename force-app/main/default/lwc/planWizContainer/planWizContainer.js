import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import submitPlan from '@salesforce/apex/PlanWizController.submitPlan';
import getPlanTemplates from '@salesforce/apex/PlanTemplateUtil.getPlanTemplates';
import getPlan from '@salesforce/apex/PlanWizController.getPlan';
import { NavigationMixin } from 'lightning/navigation';
import createNewVersion from '@salesforce/apex/PlanWizController.createNewVersion';
import userId from '@salesforce/user/Id';
//import ID_FIELD from '@salesforce/schema/Client_Service__c.Id';
import getParentObjRec from '@salesforce/apex/PlanWizController.getParentObjRec';
import checkGoals from '@salesforce/apex/PlanWizController.checkGoals';
import getUserDetails from '@salesforce/apex/PlanWizController.getUserDetails';
import PLANID_FIELD from '@salesforce/schema/Plan__c.Id';
//import getSPModules from '@salesforce/apex/IntakeWizardController.getModules';
import PLANTYPE_FIELD from '@salesforce/schema/Plan__c.Plan_Type_Txt__c';
import PLANFIELDBLUEPRINT_FIELD from '@salesforce/schema/Plan__c.Field_Blueprint_JSON__c';
import PLANPARENTCHILD_FIELD from '@salesforce/schema/Plan__c.Parent_Child_Name__c';
import VERSION_FIELD from '@salesforce/schema/Plan__c.Plan_Version__c';
import portalURL from '@salesforce/label/c.Portal_URL';
import getImperativePlan from '@salesforce/apex/PlanWizController.getImperativePlan';
import getMetadataInfo from '@salesforce/apex/PlanWizController.getMetadataInfo';
import SIGNATUREDATE_FIELD from "@salesforce/schema/Plan__c.Plan_Signed_Date__c";
//import getPlanStatus from "@salesforce/apex/RequestSignatureForPlanController.getPlanStatus";
//import createSignatureRequestURL from "@salesforce/apex/RequestSignatureForPlanController.createSignatureRequestURL";
//import updateRequestSignatureDetails from "@salesforce/apex/RequestSignatureForPlanController.updateRequestSignatureDetails";
import getPlanDraft from '@salesforce/apex/PlanWizController.getPlanDraft';



export default class PlanWizContainer extends NavigationMixin(LightningElement) {
    @api objectApiName; @api recordId; //Assigned Service ID
    @api forPrint = false; showStatus = true;
    @track metadataInformation = {};
    @track planTemplateData = {};
    @track planJSONToStore = {};
    isLoading = false;
    selectedPlanType;
    @track parentRecordData;
    @track defaultDateValues = {};
    selectedPlanTypeId;
    isFormError = false;
    planFilterField = '';
    parentChildRelName = '';
    isPlanTemDataFound = false;
    error;
    message;
    user_id = userId;
    allGood = true; planExists = false; newVersionDisabled = true; openHHGoalModal = false; isActive = false; newVersionPlanModal = false; wirecCSDataRunOnce = false;
    fromPlan = false; @api notCurrent = false; hasAccess = true;
    planRecordId = '';
    planType = ''; goalType = 'Goals';
    spsName; spsId;
    isInitial = false; isDraft = false; isSubmit = false;
    planStartDate;
    planSignDate;
    printURL; profileName;
    progressStatusVal;
    runWiredPlanData = 'no';
    /* ------------------------------------ */
    @api forClientSignature = false;
    isSignEmailModal = false;
    isSignDateFilled = false;
    selectType = true;
    @track optionsPlanType = [];
    isService = false; isCase = false;
    optionsPlanDraft = [];
    isPermanencyPlan = false;
    isSafetyPlan = false;
    clientENoticesOptOut = false;



    connectedCallback() {
        console.log('objectApiName>>> ' + this.objectApiName);
        console.log('planRecordId>>> ' + this.planRecordId);
        console.log('recId>>> ' + this.recordId);
        if (this.objectApiName == 'caresp__Plan__c') {
            this.fromPlan = true;
            this.selectType = false;
            this.planRecordId = this.recordId;


        }
        /* else if(this.objectApiName == 'Client_Service__c')
         {
             this.getSPModules();
     
         }*/
        if (this.planRecordId == undefined) {
            this.planRecordId = null;
        }
        this.fetchMetadataInfo(this.objectApiName, this.planRecordId);
        this.fetchRecordData();


    }



    getPlanTemplates() {
        this.isLoading = true;
        console.log('in  getPlanTemplates ');
        console.log('in  getPlanTemplates parentChildRelName' + this.parentChildRelName);

        getPlanTemplates({ parentChildRelName: this.parentChildRelName })
            .then(data => {
                console.log('in  getPlanTemplates data' + JSON.stringify(data));
                let planTypes = [];
                for (let [key, value] of Object.entries(data)) {
                    planTypes.push({ label: value.templateName, value: key, parentDateField: value.parentDateField, noOfDaysToAdd: value.noOfDaysToAdd, sectionInformations: value.sectionInformations });
                }
                this.optionsPlanType = [...planTypes];
                console.log('optionsPlanType>>>' + JSON.stringify(this.optionsPlanType));
                this.isLoading = false;
            })
            .catch(error => {
                console.error('## getPlanTemplates error: ', JSON.stringify(this.getErrorMessage(error)));
                this.isLoading = false;
            });
    }


    fetchRecordData() {
        this.isLoading = true;
        console.log('this.objectApiName>> ' + this.objectApiName);
        console.log('this.recordId>> ' + this.recordId);

        getParentObjRec({ parentObjName: this.objectApiName, recordId: this.recordId })
            .then(result => {
                this.parentRecordData = result;
                console.log('Record Data:', JSON.stringify(this.parentRecordData));
                this.isLoading = false;
            })
            .catch(error => {
                console.error('error occured in fetchRecordData>>> ' + JSON.stringify(error));
                this.isLoading = false;
            });
    }

    handlePlanTypeChange(event) {
        try {
            this.isLoading = true;

            this.selectedPlanTypeId = event.target.value;
            var selectedPlanTempData = this.optionsPlanType.find(option => option.value === event.target.value);
            console.log('selectedPlanTempData>>>> ' + JSON.stringify(selectedPlanTempData));
            this.planType = selectedPlanTempData.label;
            const parentDateField = selectedPlanTempData.parentDateField;
            const noOfDaysToAdd = selectedPlanTempData.noOfDaysToAdd || 0;
            this.planTemplateData = selectedPlanTempData.sectionInformations;
            if (this.planTemplateData) {
                this.planJSONToStore = this.planTemplateData;
                this.isPlanTemDataFound = true;

                console.log('this.planTemplateData>>>> ' + JSON.stringify(this.planTemplateData));
                console.log('parentDateField>>>> ' + parentDateField);
                console.log('this.parentRecordData>>> ' + JSON.stringify(this.parentRecordData));
                const parentDateValue = this.parentRecordData[parentDateField];
                console.log('parentDateValue>>>> ' + parentDateValue);

                // Step 4: Calculate the start date and end date
                if (parentDateValue) {


                    // Start date: parentDateValue + noOfDaysToAdd
                    const startDate = new Date(parentDateValue);
                    startDate.setDate(startDate.getDate() + noOfDaysToAdd);

                    // End date: today's date + noOfDaysToAdd
                    const endDate = new Date();
                    endDate.setDate(endDate.getDate() + noOfDaysToAdd);

                    // Step 5: Add these dates to the defaultDateValues object
                    this.defaultDateValues = {
                        startDate: startDate.toISOString().split('T')[0], // Format as YYYY-MM-DD
                        endDate: endDate.toISOString().split('T')[0],// Format as YYYY-MM-DD
                        goalStepStartDate: startDate.toISOString().split('T')[0],
                        goalStepTargetDate: endDate.toISOString().split('T')[0]
                    };


                }
                console.log('defaultDateValues>>>> ' + JSON.stringify(this.defaultDateValues));
                this.prepareJSONUIRender('draft');
            }
            this.selectType = false;
            this.planExists = false;
            this.isLoading = false;
            this.handlePlanSpecificFields();
            // this.getGoalStepTempData();
        }
        catch (error) {
            console.error('Error in handlePlanTypeChange :: ' + this.getErrorMessage(error));
            this.isLoading = false;
        }

    }

    handlePlanSpecificFields() {
        if (this.planType == 'Permanency Plan') {
            this.isPermanencyPlan = true;
        }
        else if (this.planType == 'Safety Plan') {
            this.isSafetyPlan = true;
        }
    }

    fetchMetadataInfo(objectApiName, planRecordId) {
        this.isLoading = true;
        console.log('objectApiName>>>', objectApiName);
        console.log('planRecordId>>>', planRecordId);
        getMetadataInfo({ parentObjAPIName: objectApiName, planId: planRecordId })
            .then(data => {
                console.log('data>>>', JSON.stringify(data));
                this.metadataInformation.goalFilterFieldName = data.goalFilterFieldName;
                this.metadataInformation.childObjName = data.childObjName;
                this.metadataInformation.planFilterFieldName = data.planFilterFieldName;
                this.planFilterField = data.planFilterFieldName;
                this.metadataInformation.label = data.label;
                this.parentChildRelName = data.label;
                this.getPlanTemplates();
                this.isLoading = false;

            })
            .catch(error => {
                console.error('## fetchMetadataInfo error: ', JSON.stringify(error));
                this.isLoading = false;
            });
    }

    @wire(getUserDetails, { userId: '$user_id' })
    wiredUserDetails(result) {
        if (result.data) {

            if (result.data.Profile != null && result.data.Profile != undefined) {
                this.profileName = result.data.Profile.Name;
            }
            else {
                this.profileName = 'System Administrator';
            }

            if (this.profileName.includes('Read Only')) {
                this.forPrint = true;
            }
        }
        else if (result.error) {
            this.error = result.error;
            console.log('#### error wiredUserDetails: ' + JSON.stringify(result.error));
        }
    }


    /*getSPModules () {
           getSPModules({asId: this.recordId, moduleName: 'Service Planning'})
           .then((result) => {
               console.log('result getSPModules :: ' + result);
               if (result[0] == 'Service Planning is not enabled for this Service.')
               {
                   console.log('in error getSPModules>>> ');
                   this.showToast('Error!', result[0], 'error');
                   this.handleCancel(false);
               }
               //else this.updateLastModDate();
           })
           .catch((error) => {
               this.error = error;
               console.log('#### error getSPModules: ' + JSON.stringify(error));
           });
       }*/

    @wire(getPlan, { asID: '$recordId', fromPlan: '$fromPlan', planId: '$planRecordId' })
    wiredGetPlan(result) {
        if (result.data) {
            this.planRecordId = result.data.Id;
            if (result.data.caresp__Field_Blueprint_JSON__c != undefined) {
                this.planTemplateData = JSON.parse(result.data.caresp__Field_Blueprint_JSON__c);
                this.isPlanTemDataFound = true;
                this.planExists = true;
                this.planType = result.data.caresp__Plan_Type_F__c;
                console.log('planExists in getPlan>>>' + this.planExists);
                this.planStartDate = result.data.caresp__Plan_Start_Date__c;
                this.isSignDateFilled = !(result.data.caresp__Plan_Signed_Date__c == null || result.data.caresp__Plan_Signed_Date__c == undefined || result.data.caresp__Plan_Signed_Date__c == "");
                this.prepareJSONUIRender(result.data.caresp__Plan_Status__c);
            }


        }
        else if (result.error) {
            this.showToast('Error!', result.error, 'error');
            console.log('## wiredGetPlan error: ' + JSON.stringify(result.error));
            this.isLoading = false;
        }
        console.log('## notCurrent: ' + this.notCurrent);
    }

    @wire(getPlanDraft, { recordId: '$recordId', objectApiName: '$objectApiName', planObjFilterField: '$planFilterField', parentChildRelName: '$parentChildRelName', currentDateTime: Date().toString() })
    wiredRecords({ data, error }) {
        if (data) {
            console.log('data=>' + JSON.stringify(data));
            this.optionsPlanDraft = data.map(item => ({
                label: item.planDetails,
                value: item.planId,
                planType: item.planType
            }));
        } else if (error) {
            console.error('Error fetching records', error);
        }
    }

    prepareJSONUIRender(status) {
        console.log('this.isSignDateFilled in prepare json >>>' + this.isSignDateFilled);
        try {
            let updatedPlanTemplateData = this.planTemplateData.map(section => {
                let updatedFieldBlueprints = section.fieldBlueprints.map(field => {
                    let updatedField = { ...field };

                    if (updatedField.value == 'caresp__Plan_Version_F__c' || updatedField.value == 'caresp__Parent_Plan_F__c') {
                        if (!this.planExists) {
                            return null;
                        } else {
                            if (updatedField.value == 'caresp__Parent_Plan_F__c') {
                                updatedField.isHyperLink = true;
                            } else {
                                updatedField.isHyperLink = false;
                            }
                        }
                    }

                    if (status === 'Accepted - New' || status === 'Not Current') {
                        if (updatedField.value === 'caresp__Plan_Signed_Date__c' && this.forPrint) {
                            return null;
                        }
                        this.isActive = true;
                        this.newVersionDisabled = false;
                        if (status === 'Not Current') {
                            this.notCurrent = true;
                        }
                        updatedField.isSignDateField = updatedField.value === 'caresp__Plan_Signed_Date__c' && !this.notCurrent;
                        updatedField.isReadOnly = updatedField.value == 'caresp__Plan_Signed_Date__c' ? (this.notCurrent ? true : this.isSignDateFilled) : true;
                    } else {
                        if (updatedField.value == 'caresp__Plan_Start_Date__c' || updatedField.value == 'caresp__Plan_End_Date__c') {
                            updatedField.defaultVal = updatedField.value == 'Plan_Start_Date__c' ? this.defaultDateValues.startDate : this.defaultDateValues.endDate;

                        }

                        updatedField.isReadOnly = this.forPrint ? true : updatedField.isReadOnly;
                        if (updatedField.value === 'caresp__Plan_Signed_Date__c') {
                            return null;
                        }
                    }

                    updatedField.isMandatory = this.forPrint ? false : updatedField.isMandatory;

                    console.log('Updated Field:', updatedField);

                    return updatedField; // Return the updated field instead of filtering it out
                }).filter(field => field !== null); // Filter out null fields

                let updatedSection = { ...section, fieldBlueprints: updatedFieldBlueprints };

                console.log('Updated Section:', updatedSection);

                return updatedSection;
            });

            this.planTemplateData = updatedPlanTemplateData;
            console.log('updatedPlanTemplateData>>> ' + JSON.stringify(this.planTemplateData));
        } catch (error) {
            console.error('error occurred in prepareJSONUIRender>>> ' + error);
        }
    }








    handleInputFieldChange(event) {
        const fieldName = event.target.fieldName; // get the field name
        const fieldValue = event.detail.value; // get the field value
        console.log('fieldValue plan sign date>>' + fieldValue);

        console.log('Field Name: ' + fieldName);
        console.log('Field Value: ' + fieldValue);
        if (!this.forPrint) {
            if (fieldName == 'caresp__Plan_Signed_Date__c') {
                this.planSignDate = fieldValue;

            }
            else if (fieldName == 'caresp__Plan_Start_Date__c') {
                this.planStartDate = fieldValue;
                this.defaultDateValues.startDate = fieldValue;

            }
            else if (fieldName == 'caresp__Plan_End_Date__c') {
                this.defaultDateValues.endDate = fieldValue;

            }

        }

    }



    /*updateLastModDate() {
        const fields = {};
       // fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[LASTMOD_FIELD.fieldApiName] = userId;
        var today = new Date();
        var presentdate;
        if (this.isDstObserved) presentdate = new Date(today.toISOString().replace("Z", "-00:00")).toISOString().replace(".000", "");
        else presentdate = new Date(today.toISOString().replace("Z", "-01:00")).toISOString().replace(".000", "");
        fields[LASTMODTIME_FIELD.fieldApiName] = presentdate;
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => { })
            .catch(error => {
                console.log('## error in update: ' + JSON.stringify(error.body.message));
            });
    
        this.wirecCSDataRunOnce = true;
    }*/

    stdTimezoneOffset() {
        var jan = new Date(this.getFullYear(), 0, 1);
        var jul = new Date(this.getFullYear(), 6, 1);
        return Math.max(jan.getTimezoneOffset(), jul.getTimezoneOffset());
    }

    isDstObserved() {
        return this.getTimezoneOffset() < this.stdTimezoneOffset();
    }

    handleCancel(reload) {
        try {
            if (!this.fromPlan) {
                if (reload) {
                    location.reload();
                }
                else {
                    this.recordId = '';
                    const closeLwc = new CustomEvent('close');
                    this.dispatchEvent(closeLwc);
                }
            }
        } catch (error) {
            console.error('Error in handleCancel:', error);
        }
    }


    handleFormSuccess(event) {
        this.isLoading = true;
        this.isFormError = false;
        if (this.isInitial) {
            this.isInitial = false;
            this.planExists = true;
            console.log('planExists in handleFormSuccess>>>' + this.planExists);
            this.planRecordId = event.detail.id;
            const fields = {};
            fields[PLANID_FIELD.fieldApiName] = event.detail.id
            fields[VERSION_FIELD.fieldApiName] = 'Version 1';
            fields[PLANTYPE_FIELD.fieldApiName] = this.planType;
            fields[PLANFIELDBLUEPRINT_FIELD.fieldApiName] = JSON.stringify(this.planJSONToStore);
            fields[this.metadataInformation.planFilterFieldName] = this.recordId;
            fields[PLANPARENTCHILD_FIELD.fieldApiName] = this.metadataInformation.label;

            console.log('fields>>>>' + JSON.stringify(fields));

            const recordInput = { fields };
            updateRecord(recordInput)
                .then(() => {
                    this.planTemplateData = this.planJSONToStore;
                    this.prepareJSONUIRender('draft');
                    this.showToast('Success!', 'Initial Plan Details Successfully Saved!', 'success');
                    this.isLoading = false;

                })
                .catch(error => {
                    this.showToast('Error!', JSON.stringify(error.body.message), 'error');
                    console.log('## error in update: ' + JSON.stringify(error.body.message));
                    this.isLoading = false;
                });

        }
        if (this.isDraft) {
            this.isDraft = false;
            this.showToast('Success!', 'Plan Successfully Saved as Draft!', 'success');
            this.isLoading = false;
            this.navigateToRecordViewPage(this.planRecordId);
        }
        if (this.isSubmit && !this.isFormError) {
            submitPlan({ asId: this.recordId, planId: this.planRecordId, objApiName: this.objectApiName })
                .then((result) => {
                    this.isSubmit = false;
                    this.showToast('Success!', 'Plan is Successfully Submitted!', 'success');
                    setTimeout(() => {
                        this.navigateToRecordViewPage(this.planRecordId);
                    }, 3000); // 5000 milliseconds = 5 seconds

                    console.log('#### submitPlan return: ' + JSON.stringify(result));
                })
                .catch((error) => {
                    this.error = error;
                    console.log('## error in handleSubmit: ' + JSON.stringify(error));
                    this.isLoading = false;
                });
            // window.location.reload();


        }
    }

    handlePlanDraftSelectChange(event) {
        this.selectType = false;
        this.planRecordId = event.detail.value;
        this.planExists = true;
        console.log('planExists in handlePlanDraftSelectChange>>>' + this.planExists);
        const selectedOption = this.optionsPlanDraft.find(option => option.value === event.detail.value);
        this.planType = selectedOption ? selectedOption.planType : null;
        this.handlePlanSpecificFields();
    }






    handleFormError(event) {
        const errorMessage = event.detail ? event.detail.detail : 'Unknown error occurred';
        this.showToast('Error!', errorMessage, 'error');
        this.isFormError = true;
        console.error('error in handleFormError' + JSON.stringify(event.detail));
    }

    handleSavePlanDetails(event) {
        this.isInitial = true;
    }

    handleSaveAsDraft() {
        this.isDraft = true;
        this.template.querySelector('lightning-record-edit-form').submit();




    }

    handleSubmit() {
        if (this.planRecordId) {
            checkGoals({ planId: this.planRecordId })
                .then((res) => {
                    if (res) {
                        this.isSubmit = true;
                        let allFieldsValid = this.validateInputs();
                        if (allFieldsValid) {
                            this.template.querySelector('lightning-record-edit-form').submit();

                        }
                        else {
                            this.showToast('Error!', 'Complete mandatory fields.', 'error');
                        }

                    }
                    else {
                        this.showToast('Error!', 'At least one goal must be added before submitting.', 'error');
                    }
                })
                .catch((error) => {
                    this.error = error;
                    console.log('## error:' + JSON.stringify(error.message));
                });
        }


    }

    validateInputs() {
        try {
            let allFieldsValid = true;
            this.template.querySelectorAll('lightning-input-field').forEach(element => {
                const fieldApiName = element.fieldName;

                let fieldConfig = null;
                for (const section of this.planTemplateData) {
                    fieldConfig = section.fieldBlueprints.find(field => field.value === fieldApiName);
                    if (fieldConfig) break;
                }

                if (fieldConfig && fieldConfig.isMandatory && !element.value) {
                    allFieldsValid = false;
                    element.reportValidity();
                }
            });
            return allFieldsValid;
        }
        catch (error) {
            console.error('error occured in validateInputs>>' + error);
            return false;

        }

    }

    handleNewVersion() {
        this.newVersionPlanModal = true;
    }

    handleCancelPlanModal() {
        this.newVersionPlanModal = false;
    }

    createNewVersion() {
        this.isLoading = true;
        createNewVersion({ planId: this.planRecordId, planObjFilterField: this.planFilterField, goalFieldFilterName: this.metadataInformation.goalFilterFieldName, recordId: this.recordId })
            .then((result) => {
                console.log('#### createNewVersion return: ' + JSON.stringify(result));
                this.planRecordId = result;
                this.showToast('Success!', 'New Version of the Plan is Successfully Created!', 'success');
                this.newVersionPlanModal = false;
                if (!this.fromPlan) location.reload();
                else {
                    var newPlanURL;
                    newPlanURL = '/' + this.planRecordId;
                    console.log('newPlanURL>>>' + newPlanURL);
                    window.open(newPlanURL, "_self");
                }
            })
            .catch((error) => {
                this.error = error;
                console.log('## error:' + JSON.stringify(error));
                this.isLoading = false;

            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handlePrint() {

        this.printURL = '/caresp/PlanPrint.app?recordId=' + this.planRecordId + '&objectApiName=caresp__Plan__c';

        window.open(this.printURL, "_blank");
    }



    handlePrintPlans() {
        window.print();
    }
    refreshPlanFields() {
        console.log('## reset');
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach(field => {
            field.reset();
        });
        this.getLatestStatus();
        this.showStatus = false;
        setTimeout(() => {
            this.showStatus = true;
        }, 2000);
    }

    getLatestStatus() {
        getImperativePlan({ planId: this.planRecordId })
            .then((result) => {
                console.log('#### getImperativePlan return: ' + JSON.stringify(result));
                this.progressStatusVal = result;
            })
            .catch((error) => {
                this.error = error;
            });
    }

    handleStartDateChange(event) {
        console.log('## ev: ' + event.detail.value);
        this.planStartDate = event.detail.value;
    }




    /*--------------------------------------------E-signature--------------------------------------------------------*/
    handleSignDateChange(event) {
        console.log("## ev: " + event.detail.value);
        this.planSignDate = event.detail.value;
    }
    //UST-00268
    /*handleRequestSignature() {
        console.log("this.planRecordId >> " + this.planRecordId);
        getPlanStatus({ planId: this.planRecordId })
            .then((result) => {
                this.planStatus = result;
                if (
                    this.planStatus == "Draft" ||
                    this.planStatus == "Not Current"
                ) {
                    const toastEve = new ShowToastEvent({
                        mode: "dismissable",
                        variant: "error",
                        title: "Error",
                        message:
                            "Draft/ Not Current Plans cannot be electronically signed until the Plan is finalized. Finalize the Plan before requesting electronic signature(s)."
                    });
                    this.dispatchEvent(toastEve);
                } else if (this.planStatus == "Accepted - New") {
                    this.isSignEmailModal = true;
                    console.log("<< here >> ");
                    console.log('clientENoticesOptOut >> ' + this.clientENoticesOptOut);
                    //  console.log('primaryClientId >> ' + this.primaryClientId);
                    console.log('planRecordId >> ' + this.planRecordId);
    
                }
            })
            .catch((error) => {
                this.error = error;
            });
    }*///commented for later purpose
    //UST - 00379
    saveSignatureDate() {
        const fields = {};
        fields[PLANID_FIELD.fieldApiName] = this.planRecordId;
        fields[SIGNATUREDATE_FIELD.fieldApiName] = this.planSignDate;
        const recordInput = { fields };
        if (
            this.planSignDate == null ||
            this.planSignDate == undefined ||
            this.planSignDate == ""
        ) {
            const toastEve = new ShowToastEvent({
                mode: "dismissable",
                variant: "error",
                title: "Error",
                message: "Please enter Signature Date."
            });
            this.dispatchEvent(toastEve);
        } else {
            updateRecord(recordInput)
                .then(() => {
                    const toastEve = new ShowToastEvent({
                        mode: "dismissable",
                        variant: "success",
                        title: "Success",
                        message: "Signature Date successfully Saved."
                    });
                    this.dispatchEvent(toastEve);
                    location.reload();
                })
                .catch((error) => {
                    const toastEve = new ShowToastEvent({
                        mode: "dismissable",
                        variant: "error",
                        title: "Error",
                        message: "Signature Date cannot be greater than today's date."
                    });
                    this.dispatchEvent(toastEve);
                    console.log(
                        "## error in update: " + JSON.stringify(error.body.message)
                    );
                });
        }
    }

    /*handleSendEmail(event) {
        createSignatureRequestURL({
            toEmailAddressList: event.detail.emailList,
            planId: this.planRecordId
        })
            .then((result) => {
                console.log('in handleSendEmail result >> ' + result);
                console.log('result >> ' + JSON.stringify(result));
                if (result.isSuccess) {
                    console.log('result.url >> ' + result.url);
                    updateRequestSignatureDetails({
                        planId: this.planRecordId,
                        urlString: result.url
                    })
                        .then((result1) => {
                            console.log('result1>>> ' + result1);
                            if (result1 == "done") {
                                const toastEve = new ShowToastEvent({
                                    mode: "dismissable",
                                    variant: "success",
                                    title: "Success",
                                    message:
                                        "Request for Signature successfully sent to client."
                                });
                                this.dispatchEvent(toastEve);
                            }
                        })
                        .catch((error1) => {
                            this.error = error1;
                        });
                } else {
                    const toastEve = new ShowToastEvent({
                        mode: "dismissable",
                        variant: "error",
                        title: "Error",
                        message:
                            result.error
                    });
                    this.dispatchEvent(toastEve);
    
                }
            })
            .catch((error) => {
                this.error = error;
            });
    
    }*///commented for later purpose

    handleCloseEmail() {
        this.isSignEmailModal = false;

    }


    navigateToRecordViewPage(recId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                actionName: 'view',
            },
        });
    }
}