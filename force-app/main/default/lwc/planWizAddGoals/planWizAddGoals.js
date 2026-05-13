import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import saveGoal from '@salesforce/apex/PlanWizController.saveGoal';
import getSteps from '@salesforce/apex/PlanWizController.getSteps';
import saveStep from '@salesforce/apex/PlanWizController.saveStep';
import getGoal from '@salesforce/apex/PlanWizController.getGoal';
import getMetadataInfo from '@salesforce/apex/PlanWizController.getMetadataInfo';
import getBlueprintSectionsForPlan from '@salesforce/apex/PlanTemplateUtil.getBlueprintSectionsForPlan';

export default class PlanWizAddGoals extends LightningElement {
    message; error;
    allGood = true; renderCmp = true; disableAddStep = false; disableGoalStatus = false; isLoading = false;
    stepType = 'Action';
    @track saveGoalData = {};
    @api childIdGoalModal;
    @api recordId;
    @api clientId;
    @api planId;
    @api goalId = '';
    @api isHousehold;
    @api hhName;
    @api clientList;
    @api planStartDate;
    @api objectApiName
    clientName;
    statusVal;
    startDateVal;
    domainVal;
    reasonVal;
    targetDateVal;
    descriptionVal;
    asseVal; serVal;
    docVal;
    typeaction;
    clientFields = [];
    goalFields = ['caresp__Goal__c.caresp__Status__c', 'caresp__Goal__c.caresp__Start_Date__c', 'caresp__Goal__c.caresp__Domain__c', 'caresp__Goal__c.caresp__Stuck_Reason__c', 'caresp__Goal__c.caresp__Target_Date__c', 'caresp__Goal__c.caresp__Description__c'];
    @track listGoalIds = [];
    @track listSteps = [];
    maxStepsNum = 0;
    goal_ID;
    @track metadataInformation = {};
    @api actionableSelected;
    @api selectActionRadio;
    _attemptedBlueprintHydration = false;

    /**
     * @description Goal field blueprint sections from Goal_Template_Field_Blueprint__c.
     *              When provided, additional configurable fields are rendered in the Goal form.
     * @type {Array}
     */
    @api goalFieldBlueprints;

    /**
     * @description Step field blueprint sections from Step_Template_Field_Blueprint__c,
     *              passed through to planWizAddSteps child components.
     * @type {Array}
     */
    @api stepFieldBlueprints;

    /** Returns true when goal field blueprints have been configured for this template. */
    get hasGoalBlueprints() {
        return Array.isArray(this.goalFieldBlueprints) && this.goalFieldBlueprints.length > 0;
    }

    /** Flattened list of all blueprint fields across all goal sections. */
    get flatGoalBlueprintFields() {
        if (!this.hasGoalBlueprints) return [];
        return this.goalFieldBlueprints.reduce((acc, section) => {
            if (section && Array.isArray(section.fieldBlueprints)) {
                acc.push(...section.fieldBlueprints);
            }
            return acc;
        }, []);
    }

    /** Returns true when step field blueprints have been configured for this template. */
    get hasStepBlueprints() {
        return Array.isArray(this.stepFieldBlueprints) && this.stepFieldBlueprints.length > 0;
    }

    get isAddStepDisabled() {
        return this.disableAddStep || !this.hasStepBlueprints;
    }

    connectedCallback() {
        //console.log('recordId= = >'+this.recordId);
        //console.log('objectApiName== >'+this.objectApiName);
        this.clientName = (this.hhName != null && this.hhName != '' && this.hhName != undefined) ? this.hhName : null;
        console.log('## cb goalId:' + this.goalId);
        this.fetchMetadataInfo();
        this.hydrateBlueprintsFromPlanIfNeeded();
        if ((this.goalId == null || this.goalId == '' || this.goalId == undefined) && this.planStartDate != null && this.planStartDate != undefined) {
            this.startDateVal = this.planStartDate; //set Start Date from Plan
            this.disableGoalStatus = false;
            this.disableAddStep = false;
        }

        else {
            getGoal({ goalId: this.goalId })
                .then((result) => {
                    console.log('#### getGoal return: ' + JSON.stringify(result));
                    this.statusVal = result.caresp__Status__c;
                    this.startDateVal = result.caresp__Start_Date__c;
                    this.domainVal = result.caresp__Domain__c;
                    this.reasonVal = result.caresp__Stuck_Reason__c;
                    this.targetDateVal = result.caresp__Target_Date__c;
                    this.descriptionVal = result.caresp__Description__c;
                })
                .catch((error) => {
                    console.log('error getGoal: ' + JSON.stringify(error));
                    this.error = error;
                });
        }
        this.goal_ID = this.goalId;
    }

    hydrateBlueprintsFromPlanIfNeeded() {
        const hasGoalBlueprintProps = Array.isArray(this.goalFieldBlueprints) && this.goalFieldBlueprints.length > 0;
        if (hasGoalBlueprintProps || !this.planId || this._attemptedBlueprintHydration) {
            return;
        }

        this._attemptedBlueprintHydration = true;
        getBlueprintSectionsForPlan({ planId: this.planId })
            .then((wrapper) => {
                if (!wrapper) return;

                if ((!Array.isArray(this.goalFieldBlueprints) || this.goalFieldBlueprints.length === 0) &&
                    Array.isArray(wrapper.goalSectionInformations) &&
                    wrapper.goalSectionInformations.length > 0) {
                    this.goalFieldBlueprints = wrapper.goalSectionInformations;
                }

                if ((!Array.isArray(this.stepFieldBlueprints) || this.stepFieldBlueprints.length === 0) &&
                    Array.isArray(wrapper.stepSectionInformations) &&
                    wrapper.stepSectionInformations.length > 0) {
                    this.stepFieldBlueprints = wrapper.stepSectionInformations;
                }
            })
            .catch((error) => {
                console.log('hydrateBlueprintsFromPlanIfNeeded error: ' + JSON.stringify(error));
            });
    }



    /*added by sg*/
    fetchMetadataInfo() {
        getMetadataInfo({ parentObjAPIName: this.objectApiName, planId : this.planId })
            .then(data => {
                this.metadataInformation.goalFilterFieldName = data.goalFilterFieldName;
                this.metadataInformation.childObjName = data.childObjName;
                this.clientFields.push(this.metadataInformation.childObjName + '.Name');
                console.log('clientFields>>>>' + this.clientFields);
                console.log('childIdGoalModal>>>>' + this.childIdGoalModal);
            })
            .catch(error => {
                console.log('## wiredClientService error: ' + JSON.stringify(error));
            });
    }
    /*added by sg end*/

    /*added by sg/
    @wire(getMetadataInfo, { parentObjAPIName: '$objectApiName' })
    wiredMetadataInfo({ data, error }) {
        if (data) {
            this.metadataInformation.goalFilterFieldName = data.goalFilterFieldName;
            this.metadataInformation.childObjName = data.childObjName;
            this.clientFields.push(this.metadataInformation.childObjName + '.Name');
            console.log('clientFields>>>>' + this.clientFields);
            console.log('childIdGoalModal>>>>' + this.childIdGoalModal);

        }
        else if (error) {
            console.log('## wiredClientService error: ' + JSON.stringify(error));
        }
    }
    /*added by sg end*/



    @wire(getRecord, { recordId: '$clientId', fields: '$clientFields' })
    wiredClientService({ data, error }) {
        if (data) {
            this.clientName = data.fields.Name.value;
        }
        else if (error) {
            console.log('## wiredClientService error: ' + JSON.stringify(error));
        }
    }




    @wire(getRecord, { recordId: '$goalId', fields: '$goalFields' })
    wiredGoalService({ data, error }) {
        if (data) {
            //console.log('## fl: ' + JSON.stringify(data.fields));

            this.disableAddStep = false;
            // Only block adding steps when the goal is discontinued; "Completed" still allows further steps in the wizard.
            if (data.fields.caresp__Status__c.value == 'Discontinued') {
                this.disableAddStep = true;
            }

            this.getSteps();
        }
        else if (error) {
            console.log('## wiredGoalService error: ' + JSON.stringify(error));
        }
    }

    getSteps() {

        getSteps({ goalId: this.goal_ID })
            .then((result) => {
                let filteredStepList = [];
                this.maxStepsNum = result.length;
                this.listSteps = result;
                this.listSteps = [...this.listSteps];
                console.log('## listSteps: ' + JSON.stringify(this.listSteps));
                if (this.listSteps.length > 0) {
                    this.disableGoalStatus = true;
                }
            })
            .catch((error) => {
                this.error = error;
                this.listSteps = [];
                this.listSteps = [...this.listSteps];
                console.log('## getSteps error: ' + JSON.stringify(error));
            });
    }

    /* @wire(getSteps, {goalId : '$goal_ID'})
    //@wire(getSteps, {goalId : '$goalId'})
    wiredGetSteps (result) {
        console.log('## getting Steps');
        if (result.data)
        {
            this.maxStepsNum = result.data.length;
            this.listSteps = result.data;
            this.listSteps = [...this.listSteps];
            console.log('## listSteps: ' + JSON.stringify(this.listSteps));
            if (this.listSteps.length > 0)
            {
                this.disableGoalStatus = true;
            }
        }
        else if (result.error)
        {
            this.error = result.error;
            this.listSteps = [];
            this.listSteps = [...this.listSteps];
            console.log('## wiredGetSteps error: ' + JSON.stringify(result.error));
        }
    } */

    closeGoalsModal() {
        this.isLoading = true;
        this.goalId = null;
        this.goal_ID = null;
        this.renderCmp = false;
        setTimeout(() => {
            this.isLoading = false;
            const closeModalEvt = new CustomEvent('closegoalsmodal');
            this.dispatchEvent(closeModalEvt);
        }, 1000);
    }

    collectGoalFormFieldValues() {
        const fieldValues = {};
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach((fieldCmp) => {
            if (fieldCmp && fieldCmp.fieldName) {
                fieldValues[fieldCmp.fieldName] = fieldCmp.value;
            }
        });
        return fieldValues;
    }

    getGoalFieldValue(fieldValues, apiName, fallbackValue = null) {
        if (fieldValues && Object.prototype.hasOwnProperty.call(fieldValues, apiName)) {
            return fieldValues[apiName];
        }
        return fallbackValue;
    }

    buildGoalSaveData(fieldValues) {
        const gId = (this.goalId != null) ? this.goalId : null;
        const payload = {};
        payload.goalId = gId;
        payload.cName = this.getGoalFieldValue(fieldValues, 'caresp__Client_Name__c', this.clientName);
        payload.status = this.getGoalFieldValue(fieldValues, 'caresp__Status__c', this.statusVal);
        payload.startDate = this.getGoalFieldValue(fieldValues, 'caresp__Start_Date__c', this.startDateVal);
        payload.domain = this.getGoalFieldValue(fieldValues, 'caresp__Domain__c', this.domainVal);
        payload.reason = this.getGoalFieldValue(fieldValues, 'caresp__Stuck_Reason__c', this.reasonVal);
        payload.targetDate = this.getGoalFieldValue(fieldValues, 'caresp__Target_Date__c', this.targetDateVal);
        payload.description = this.getGoalFieldValue(fieldValues, 'caresp__Description__c', this.descriptionVal);
        payload.planId = this.planId;
        payload.childId = this.clientId;
        payload.isHH = this.isHousehold;
        payload.goalFilterFieldName = this.metadataInformation.goalFilterFieldName;

        // Capture blueprint-driven goal field values.
        this.flatGoalBlueprintFields.forEach((bp) => {
            if (bp && bp.value && Object.prototype.hasOwnProperty.call(fieldValues, bp.value)) {
                payload[bp.value] = fieldValues[bp.value];
            }
        });
        return payload;
    }

    dateValidationsInGoal(fieldValues) {
        const targetDate = this.getGoalFieldValue(
            fieldValues,
            'caresp__Target_Date__c',
            null
        );
        const startDate = this.getGoalFieldValue(
            fieldValues,
            'caresp__Start_Date__c',
            null
        );
        let todayDate = new Date();
        if ((targetDate != null && targetDate != undefined)) {
            if (new Date(targetDate) <= todayDate) {
                this.allGood = false;
                this.message = 'Target Date must be greater than today\'s date.';
            }
            else if ((startDate != null && startDate != undefined) && targetDate < startDate) {
                this.allGood = false;
                this.message = 'Target Date must be greater than the Start Date.';
            }
        }
    }

    handleSaveGoalDetails(event) {
        this.allGood = true;
        event.preventDefault();
        if (!this.hasGoalBlueprints) {
            this.allGood = false;
            this.message = 'No active Goal Template Field Blueprint is configured for this plan template.';
            return;
        }
        let fields = event.detail.fields || {};

        //Date Validations in Goal - START
        this.dateValidationsInGoal(fields);
        //Date Validations in Goal - END

        //Save Goal and Steps
        if (this.allGood) {
            //Validating Steps
            var listStepsReturn = [];
            var allGood = true;
            var allchildcmp = this.template.querySelectorAll('c-plan-wiz-add-steps');
            allchildcmp.forEach(function (ele) {
                listStepsReturn.push(ele.submitFromParent(this.listGoalIds));
            }, this);
            console.log('## listStepsReturn: ' + JSON.stringify(listStepsReturn));

            var listSteps = [];
            listStepsReturn.forEach(function (ele) {
                if (ele.Message == 'Not Good') {
                    allGood = false;
                }
                else if (ele.Message == 'Good') {
                    listSteps.push(ele.fields);
                }
            });

            if (allGood)    //Steps Validations Passed
            {
                this.saveGoalData = this.buildGoalSaveData(fields);
                saveGoal({ saveGoalData: this.saveGoalData })
                    .then((result) => {
                        console.log('#### saveGoal return: ' + JSON.stringify(result));
                        if (!Array.isArray(result) || result.length === 0) {
                            this.allGood = false;
                            this.message = 'Goal could not be saved. Please ensure required blueprint fields are configured and populated.';
                            return;
                        }
                        this.listGoalIds = result;
                        if (result.length == 1) //Individual Goal
                        {
                            this.goalId = result[0];
                        }

                        if (listSteps.length > 0) {
                            //console.log('## listSteps: ' + JSON.stringify(listSteps));
                            //console.log('## gIds: ' + JSON.stringify(this.listGoalIds));
                            saveStep({ listSteps: listSteps, listGoalIds: this.listGoalIds, objectApiName: this.objectApiName, recordId: this.recordId })
                                .then((stepSaveResult) => {
                                    console.log('#### saveStep return: ' + JSON.stringify(stepSaveResult));
                                    if (stepSaveResult === '0' || (stepSaveResult && String(stepSaveResult).startsWith('Error:'))) {
                                        this.allGood = false;
                                        this.message = 'Step details could not be saved. Please verify step field access and try again.';
                                        return;
                                    }
                                    this.showToast('Success!', 'Goal Details Successfully Saved!', 'success');
                                    this.closeGoalsModal();
                                })
                                .catch((error) => {
                                    console.log('error: ' + JSON.stringify(error));
                                    this.error = error;
                                    this.allGood = false;
                                    this.message = (error && error.body && error.body.message) ? error.body.message : 'Error saving Step.';
                                });
                            return;
                        }

                        this.showToast('Success!', 'Goal Details Successfully Saved!', 'success');
                        this.closeGoalsModal();
                    })
                    .catch((error) => {
                        console.log('## error: ' + JSON.stringify(error));
                        this.error = error;
                        this.allGood = false;
                        this.message = (error && error.body && error.body.message) ? error.body.message : 'Error saving Goal.';
                    });
            }
        }
    }

    saveAndNew() {
        this.allGood = true;
        if (!this.hasGoalBlueprints) {
            this.allGood = false;
            this.message = 'No active Goal Template Field Blueprint is configured for this plan template.';
            return;
        }
        const fields = this.collectGoalFormFieldValues();
        //Date Validations in Goal - START
        this.dateValidationsInGoal(fields);
        //Date Validations in Goal - END

        //Save Goal and Steps
        if (this.allGood) {
            //Validating Steps
            var listStepsReturn = [];
            var allGood = true;
            var allchildcmp = this.template.querySelectorAll('c-plan-wiz-add-steps');
            allchildcmp.forEach(function (ele) {
                listStepsReturn.push(ele.submitFromParent(this.listGoalIds));
            }, this);
            console.log('## listStepsReturn: ' + JSON.stringify(listStepsReturn));

            var listSteps = [];
            listStepsReturn.forEach(function (ele) {
                if (ele.Message == 'Not Good') {
                    allGood = false;
                }
                else if (ele.Message == 'Good') {
                    listSteps.push(ele.fields);
                }
            });

            if (allGood)    //Steps Validations Passed
            {
                this.allGood = true;

                // Preserve legacy local state values for backward-compatible defaults.
                this.statusVal = this.getGoalFieldValue(fields, 'caresp__Status__c', this.statusVal);
                this.startDateVal = this.getGoalFieldValue(fields, 'caresp__Start_Date__c', this.startDateVal);
                this.domainVal = this.getGoalFieldValue(fields, 'caresp__Domain__c', this.domainVal);
                this.reasonVal = this.getGoalFieldValue(fields, 'caresp__Stuck_Reason__c', this.reasonVal);
                this.targetDateVal = this.getGoalFieldValue(fields, 'caresp__Target_Date__c', this.targetDateVal);
                this.descriptionVal = this.getGoalFieldValue(fields, 'caresp__Description__c', this.descriptionVal);

                console.log('this.allGood : ' + this.allGood);
                if (this.allGood) {
                    this.saveGoalData = this.buildGoalSaveData(fields);
                    console.log('saveGoalData : ' + this.saveGoalData);
                    console.log('listClientIds>>>' + this.clientList);

                    //saveGoal({goalId : gId, cName: fields.Client_Name__c, status: fields.Status__c, startDate: fields.Start_Date__c, domain: fields.Domain__c, reason: fields.Stuck_Reason__c, targetDate: fields.Target_Date__c, description: fields.Description__c, planId: this.planId, clientId: this.clientId, isHH : this.isHousehold, listClientIds : this.clientList})
                    saveGoal({ saveGoalData: this.saveGoalData, listClientIds: this.clientList }).then((result) => {
                        console.log('#### saveGoal return: ' + JSON.stringify(result));
                        if (!Array.isArray(result) || result.length === 0) {
                            this.allGood = false;
                            this.message = 'Goal could not be saved. Please ensure required blueprint fields are configured and populated.';
                            return;
                        }
                        this.listGoalIds = result;
                        if (result.length == 1) //Individual Goal
                        {
                            this.goalId = result[0];
                        }

                        if (listSteps.length > 0) {
                            saveStep({ listSteps: listSteps, listGoalIds: this.listGoalIds, objectApiName: this.objectApiName, recordId: this.recordId })
                                .then((stepSaveResult) => {
                                    console.log('#### saveStep return: ' + JSON.stringify(stepSaveResult));
                                    if (stepSaveResult === '0' || (stepSaveResult && String(stepSaveResult).startsWith('Error:'))) {
                                        this.allGood = false;
                                        this.message = 'Step details could not be saved. Please verify step field access and try again.';
                                        return;
                                    }
                                    this.showToast('Success!', 'Goal Details Successfully Saved!', 'success');
                                    this.goalId = null;
                                    this.goal_ID = null;
                                    this.isLoading = true;
                                    this.renderCmp = false;
                                    this.listSteps = [];
                                    this.listSteps = [...this.listSteps];
                                    this.maxStepsNum = 0;
                                    this.allGood = true;
                                    setTimeout(() => {
                                        this.isLoading = false;
                                        this.renderCmp = true;
                                        this.statusVal = 'Not Started';
                                        this.startDateVal = this.planStartDate;
                                        this.domainVal = null;
                                        this.reasonVal = null;
                                        this.targetDateVal = null;
                                        this.descriptionVal = null;
                                        this.disableGoalStatus = false;
                                        this.disableAddStep = false;
                                    }, 1000);
                                })
                                .catch((error) => {
                                    console.log('error: ' + JSON.stringify(error));
                                    this.error = error;
                                    this.allGood = false;
                                    this.message = (error && error.body && error.body.message) ? error.body.message : 'Error saving Step.';
                                });
                            return;
                        }

                        this.showToast('Success!', 'Goal Details Successfully Saved!', 'success');
                        this.goalId = null;
                        this.goal_ID = null;
                        this.isLoading = true;
                        this.renderCmp = false;
                        this.listSteps = [];
                        this.listSteps = [...this.listSteps];
                        this.maxStepsNum = 0;
                        this.allGood = true;
                        setTimeout(() => {
                            this.isLoading = false;
                            this.renderCmp = true;
                            this.statusVal = 'Not Started';
                            this.startDateVal = this.planStartDate;
                            this.domainVal = null;
                            this.reasonVal = null;
                            this.targetDateVal = null;
                            this.descriptionVal = null;
                            this.disableGoalStatus = false;
                            this.disableAddStep = false;
                        }, 1000);
                    })
                        .catch((error) => {
                            console.log('## error: ' + JSON.stringify(error));
                            this.error = error;
                            this.allGood = false;
                            this.message = (error && error.body && error.body.message) ? error.body.message : 'Error saving Goal.';
                        });
                }
            }
        }
        // //Added By Anubhav
        // this.isLoading = true;
        // this.goalId = null;
        // this.goal_ID = null;
        // this.renderCmp = false;
        // setTimeout(() => {
        //     this.isLoading = false;
        //     const closeModalEvt = new CustomEvent('closegoalsmodal');
        //     this.dispatchEvent(closeModalEvt);
        // }, 1500);
        // //End
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleAddStep() {
        if (!this.hasGoalBlueprints) {
            this.allGood = false;
            this.message = 'No active Goal Template Field Blueprint is configured for this plan template.';
            return;
        }
        let oldListSteps = this.listSteps;
        this.maxStepsNum = this.maxStepsNum + 1;
        let newStep = { "caresp__Step_Num__c": (this.maxStepsNum), "caresp__Start_Date__c": this.planStartDate };
        oldListSteps.push(newStep);
        this.listSteps = [...oldListSteps];
        console.log('listSteps = >' + this.listSteps)
        this.disableGoalStatus = true;

    }
}