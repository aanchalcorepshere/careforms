import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import saveGoal from '@salesforce/apex/PlanWizController.saveGoal';
import getSteps from '@salesforce/apex/PlanWizController.getSteps';
import saveStep from '@salesforce/apex/PlanWizController.saveStep';
import getGoal from '@salesforce/apex/PlanWizController.getGoal';
import getMetadataInfo from '@salesforce/apex/PlanWizController.getMetadataInfo';

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

    connectedCallback() {
        //console.log('recordId= = >'+this.recordId);
        //console.log('objectApiName== >'+this.objectApiName);
        this.clientName = (this.hhName != null && this.hhName != '' && this.hhName != undefined) ? this.hhName : null;
        console.log('## cb goalId:' + this.goalId);
        this.fetchMetadataInfo();
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

            if (data.fields.caresp__Status__c.value == 'Completed' || data.fields.caresp__Status__c.value == 'Discontinued') {
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

    dateValidationsInGoal() {
        let targetDate;
        let startDate;
        let todayDate = new Date();
        for (let i = 0; i < this.template.querySelectorAll('lightning-input-field').length; i++) {
            if (this.template.querySelectorAll('lightning-input-field')[i].name === "targetDate") targetDate = this.template.querySelectorAll('lightning-input-field')[i].value;
            else if (this.template.querySelectorAll('lightning-input-field')[i].name === "startDate") startDate = this.template.querySelectorAll('lightning-input-field')[i].value;
        }
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
        let fields = event.detail.fields;

        //Date Validations in Goal - START
        this.dateValidationsInGoal();
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
                let gId = (this.goalId != null) ? this.goalId : null;
                this.saveGoalData = {};
                this.saveGoalData.goalId = gId;
                this.saveGoalData.cName = fields.caresp__Client_Name__c;
                this.saveGoalData.status = fields.caresp__Status__c;
                this.saveGoalData.startDate = fields.caresp__Start_Date__c;
                this.saveGoalData.domain = fields.caresp__Domain__c;
                this.saveGoalData.reason = fields.caresp__Stuck_Reason__c;
                this.saveGoalData.targetDate = fields.caresp__Target_Date__c;
                this.saveGoalData.description = fields.caresp__Description__c;
                this.saveGoalData.planId = this.planId;
                this.saveGoalData.childId = this.clientId;
                this.saveGoalData.isHH = this.isHousehold;
                this.saveGoalData.goalFilterFieldName = this.metadataInformation.goalFilterFieldName;





                //console.log('## gId: ' + gId);
                saveGoal({ saveGoalData: this.saveGoalData })
                    .then((result) => {
                        console.log('#### saveGoal return: ' + JSON.stringify(result));
                        this.listGoalIds = result;
                        if (result.length == 1) //Individual Goal
                        {
                            this.goalId = result[0];
                        }

                        if (listSteps.length > 0) {
                            //console.log('## listSteps: ' + JSON.stringify(listSteps));
                            //console.log('## gIds: ' + JSON.stringify(this.listGoalIds));
                            saveStep({ listSteps: listSteps, listGoalIds: this.listGoalIds, objectApiName: this.objectApiName, recordId: this.recordId })
                                .then((result) => {
                                    console.log('#### saveStep return: ' + JSON.stringify(result));
                                })
                                .catch((error) => {
                                    console.log('error: ' + JSON.stringify(error));
                                    this.error = error;
                                });
                        }

                        this.showToast('Success!', 'Goal Details Successfully Saved!', 'success');
                        this.closeGoalsModal();
                    })
                    .catch((error) => {
                        console.log('## error: ' + JSON.stringify(error));
                        this.error = error;
                    });
            }
        }
    }

    saveAndNew() {
        this.allGood = true;
        //Date Validations in Goal - START
        this.dateValidationsInGoal();
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
                for (let i = 0; i < this.template.querySelectorAll('lightning-input-field').length; i++) {
                    if (this.template.querySelectorAll('lightning-input-field')[i].name === "status" ||
                        this.template.querySelectorAll('lightning-input-field')[i].name === "domain" ||
                        this.template.querySelectorAll('lightning-input-field')[i].name === "description") {
                        if (this.template.querySelectorAll('lightning-input-field')[i].value == null ||
                            this.template.querySelectorAll('lightning-input-field')[i].value == '') {
                            this.allGood = false;
                            this.message = 'Please enter all the required fields.';
                            break;
                        }
                    }

                    if (this.template.querySelectorAll('lightning-input-field')[i].name === "status") this.statusVal = this.template.querySelectorAll('lightning-input-field')[i].value;
                    else if (this.template.querySelectorAll('lightning-input-field')[i].name === "startDate") this.startDateVal = this.template.querySelectorAll('lightning-input-field')[i].value;
                    else if (this.template.querySelectorAll('lightning-input-field')[i].name === "domain") this.domainVal = this.template.querySelectorAll('lightning-input-field')[i].value;
                    else if (this.template.querySelectorAll('lightning-input-field')[i].name === "reason") this.reasonVal = this.template.querySelectorAll('lightning-input-field')[i].value;
                    else if (this.template.querySelectorAll('lightning-input-field')[i].name === "targetDate") this.targetDateVal = this.template.querySelectorAll('lightning-input-field')[i].value;
                    else if (this.template.querySelectorAll('lightning-input-field')[i].name === "description") this.descriptionVal = this.template.querySelectorAll('lightning-input-field')[i].value;
                }

                console.log('this.allGood : ' + this.allGood);
                if (this.allGood) {
                    debugger;
                    let fields = {
                        "caresp__Client_Name__c": this.clientName,
                        "caresp__Status__c": this.statusVal,
                        "caresp__Start_Date__c": this.startDateVal,
                        "caresp__Domain__c": this.domainVal,
                        "caresp__Stuck_Reason__c": this.reasonVal,
                        "caresp__Target_Date__c": this.targetDateVal,
                        "caresp__Description__c": this.descriptionVal
                    };



                    let gId = (this.goalId != null) ? this.goalId : null;
                    this.saveGoalData = {};
                    this.saveGoalData.goalId = gId;
                    this.saveGoalData.cName = fields.caresp__Client_Name__c;
                    this.saveGoalData.status = fields.caresp__Status__c;
                    this.saveGoalData.startDate = fields.caresp__Start_Date__c;
                    this.saveGoalData.domain = fields.caresp__Domain__c;
                    this.saveGoalData.reason = fields.caresp__Stuck_Reason__c;
                    this.saveGoalData.targetDate = fields.caresp__Target_Date__c;
                    this.saveGoalData.description = fields.caresp__Description__c;
                    this.saveGoalData.planId = this.planId;
                    this.saveGoalData.childId = this.clientId;
                    this.saveGoalData.isHH = this.isHousehold;
                    this.saveGoalData.goalFilterFieldName = this.metadataInformation.goalFilterFieldName;





                    console.log('saveGoalData : ' + this.saveGoalData);
                    console.log('listClientIds>>>' + this.clientList);

                    //saveGoal({goalId : gId, cName: fields.Client_Name__c, status: fields.Status__c, startDate: fields.Start_Date__c, domain: fields.Domain__c, reason: fields.Stuck_Reason__c, targetDate: fields.Target_Date__c, description: fields.Description__c, planId: this.planId, clientId: this.clientId, isHH : this.isHousehold, listClientIds : this.clientList})
                    saveGoal({ saveGoalData: this.saveGoalData, listClientIds: this.clientList }).then((result) => {
                        console.log('#### saveGoal return: ' + JSON.stringify(result));
                        this.listGoalIds = result;
                        if (result.length == 1) //Individual Goal
                        {
                            this.goalId = result[0];
                        }

                        if (listSteps.length > 0) {
                            saveStep({ listSteps: listSteps, listGoalIds: this.listGoalIds, objectApiName: this.objectApiName, recordId: this.recordId })
                                .then((result) => {
                                    console.log('#### saveStep return: ' + JSON.stringify(result));
                                })
                                .catch((error) => {
                                    console.log('error: ' + JSON.stringify(error));
                                    this.error = error;
                                });
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
        let oldListSteps = this.listSteps;
        this.maxStepsNum = this.maxStepsNum + 1;
        let newStep = { "caresp__Step_Num__c": (this.maxStepsNum), "caresp__Start_Date__c": this.planStartDate };
        oldListSteps.push(newStep);
        this.listSteps = [...oldListSteps];
        console.log('listSteps = >' + this.listSteps)
        this.disableGoalStatus = true;

    }
}