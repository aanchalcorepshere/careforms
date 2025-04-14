import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getClients from '@salesforce/apex/PlanWizController.getClientsDynamically'; //change by shudhanshu
import createGoalAndStepPlanTemp from '@salesforce/apex/PlanWizController.createGoalStepTemp'; //change by shudhanshu
import deleteGoal from '@salesforce/apex/PlanWizController.deleteGoal';
import deleteStep from '@salesforce/apex/PlanWizController.deleteStep';
import getTaskRecord from '@salesforce/apex/PlanWizController.getTaskRecord';
import { NavigationMixin } from 'lightning/navigation'; // Added By Anubhav


//export default class ServicePlanWizShowClients extends LightningElement {
export default class PlanWizShowClients extends NavigationMixin(LightningElement) {

    @api recordId; @api planId; @api planActive; @api planStartDate; @api objectApiName
    @api childId;
    @api planTempId;
    @api defaultDateValues;
    error;
    isGoalNStepTempCreated = false;
    @track listClients = []; getClientsResult;
    isModalOpen = false; isLoading = false; openHHGoalModal = false;
    activeClientId; activeGoalId;
    activeSections = []; @api forPrint = false; @api profileName;


    constructor() {
        super();
    }
    connectedCallback() {

        if (this.planTempId) {
            this.createGoalAndStepPlanTemp();
            

        }

    }


    createGoalAndStepPlanTemp() {
        const params = {
            asID: this.recordId,
            planId: this.planId,
            objectApiName: this.objectApiName,
            planTempId: this.planTempId,
            defaultDateValues: this.defaultDateValues
        };
        

        createGoalAndStepPlanTemp({params: JSON.stringify(params)})
            .then(result => {
                this.isGoalNStepTempCreated = result;
                console.log(' this.isGoalNStepTempCreated>>> ' +  this.isGoalNStepTempCreated);
                 console.log(' this.planId>>> ' +  this.planId);

            })
            .catch(error => {
                this.error = error;
                console.log('## asID: ' + this.recordId);
                console.log('## planId: ' + this.planId);
                console.error('## getClients error: ', error);
            });

    }


    @wire(getClients, { asID: '$recordId', planId: '$planId', objectApiName: '$objectApiName', isGoalNStepTempCreated: '$isGoalNStepTempCreated' })
    wiredGetClients(result) {
        try{
        console.log('## recordId: ' + this.recordId);
        console.log('## planId: ' + this.planId);
        console.log('## planId: ' + JSON.stringify(result));
        this.getClientsResult = result;
        if (result.data) {
            console.log('## clients: ' + JSON.stringify(result.data));
            this.listClients = result.data;
            console.log('clients for print>>' + this.listClients);
            if (this.forPrint && !this.profileName.includes('Read Only')) {
                console.log('this.forPrint for print>>' + this.forPrint);
                result.data.forEach(rec => {
                    this.activeSections.push(rec.attributes.clientName);
                });
               /* setTimeout(() => {
                    window.print();
                }, 1000);*/
            }
        }
        else if (result.error) {
            this.error = result.error;
            console.log('## asID: ' + this.recordId);
            console.log('## planId: ' + this.planId);
            console.log('## wiredGetClients error: ' + JSON.stringify(result.error));
        }
        }
        catch(error)
        {
            console.error('Error occurred in wiredGetClients of planWizShowClients :: ' + JSON.stringify(error));

        }
    }
    //Added By Anubhav
    callGetTaskRecord(stepId) {
        console.log('stepId: ' + stepId);
        getTaskRecord({ stepId: stepId })
            .then(result => {
                this.taskRecordId = result;
                console.log('Task Record Id:', this.taskRecordId);
                if (this.taskRecordId === null || this.taskRecordId === '') {
                    this.handleEditGoal(event);
                } else {
                    this.openModalOrNavigate(this.taskRecordId);
                }
            })
            .catch(error => {
                console.error('Error:', error);
            });
    }

    // openModalOrNavigate(taskRecordId) {
    //     window.open('/' + taskRecordId, "_blank");
    // }

    openModalOrNavigate(taskRecordId) {
        console.log('navigationMix');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: taskRecordId,
                objectApiName: 'Task',
                actionName: 'view',
            },
        });
    }
    // End


    openGoalsModal(event) {
        //console.log('## event: ' + JSON.stringify(event.target.name));
        this.activeClientId = event.target.name;
        this.childId = event.target.name;
        this.isModalOpen = true;
    }

    closeGoalsModal() {
        this.activeClientId = null;
        this.activeGoalId = null;
        this.isModalOpen = false;
        this.refreshCR(false);
        const refreshPlanEvt = new CustomEvent('refreshplanfields');
        this.dispatchEvent(refreshPlanEvt);
    }

    refreshCR(isDelete) {
        let pId = this.planId;
        if (!isDelete) {
            this.isLoading = true;
            setTimeout(() => {
                this.planId = null;
                this.listClients = [];
                refreshApex(this.getClientsResult);
                this.planId = pId;
                this.isLoading = false;
            }, 1000);
        }
        else refreshApex(this.getClientsResult);
    }

    handleEditGoal(event) {
        console.log('## event: ' + JSON.stringify(event.target.name));
        const listID = event.target.name.split('#');
        const clientId = listID[0];
        const goalId = listID[1];
        this.activeGoalId = goalId;
        this.activeClientId = clientId;
        this.childId = clientId
        this.isModalOpen = true;
        console.log('this.activeGoalId >>>>' + this.activeGoalId + 'this.activeClientId>>>>' + this.activeClientId + 'this.childId>>>' + this.childId);
    }

    handleDeleteGoal(event) {
        const listID = event.target.name.split('#');
        console.log('listID>>>' + listID);
        this.processListClients(true, listID);
    }

    handleDeleteGoalNo(event) {
        const listID = event.target.name.split('#');
        this.processListClients(false, listID);
    }

    processListClients(deleteGoalValue, listID) {
        try {
            const clientId = listID[0];
            const goalId = listID[1];
            console.log('goalId>>> ' + goalId);
            // Deep cloning of array
            let listofClients = JSON.parse(JSON.stringify(this.listClients));
            console.log('listofClients>>>' + JSON.stringify(this.listClients));



            if (listofClients?.length > 0) {
                let currentClient = listofClients.find(c => {
                    return c.attributes && c.attributes.Id === clientId
                });
                if (currentClient.attributes.listGoals?.length > 0) {
                    let currentGoal = currentClient.attributes.listGoals.find(g => g.goalId == goalId);
                    currentGoal.isDeleteGoal = deleteGoalValue;
                }

                this.listClients = [...listofClients];
            }

        } catch (error) {
            console.error('An error occurred in processListClients: ', error.message, '\nStack trace:', error.stack);
        }
    }


    handleDeleteGoalYes(event) {
        deleteGoal({ goalId: event.target.name })
            .then((result) => {
                console.log('#### deleteGoal return: ' + JSON.stringify(result));
                this.showToast('Success!', 'Goal was Successfully Deleted!', 'success');
                this.refreshCR(true);
            })
            .catch((error) => {
                this.error = error;
            });
    }

    handleDeleteStep(event) {
        const listID = event.target.name.split('#');
        this.processListClientsStep(true, listID);
    }
    //Added By Anubhav
    handleAtionnableTaskStep(event) {
        try {
            const listID = event.target.name.split('#');
            console.log('listID = >' + listID);
            const stepId = listID[2];
            console.log('stepId = >' + stepId);
            this.callGetTaskRecord(stepId);
            //this.processListClientsStep(true, listID);
        } catch (error) {
            console.error('An error occurred in handleAtionnableTaskStep: ', error.message, '\nStack trace:', error.stack);
        }
    }
    //End
    handleDeleteStepNo(event) {
        const listID = event.target.name.split('#');
        this.processListClientsStep(false, listID);
    }

    processListClientsStep(deleteStepValue, listID) {
        try {
            console.log('in processListClientsStep');
            const clientId = listID[0];
            const goalId = listID[1];
            const stepId = listID[2];
            let listofClients = JSON.parse(JSON.stringify(this.listClients)); // deep cloning of array
            console.log('listofClients>>>' + JSON.stringify(listofClients));
            if (listofClients?.length > 0) {
                let currentClient = listofClients.find(c => {
                    return c.attributes && c.attributes.Id === clientId
                });
                if (currentClient.attributes.listGoals?.length > 0) {
                    let currentGoal = currentClient.attributes.listGoals.find(g => g.goalId == goalId);
                    let currentStep = currentGoal.listSteps.find(s => s.stepId == stepId);
                    currentStep.isDeleteStep = deleteStepValue;
                    console.log('currentStep.isDeleteStep>>>' + currentStep.isDeleteStep);
                }
                this.listClients = [...listofClients];
            }
        } catch (error) {
            console.error('Error processing list clients step:', error.message);
        }
    }


    handleDeleteStepYes(event) {
        deleteStep({ stepId: event.target.name })
            .then((result) => {
                console.log('#### deleteStep return: ' + JSON.stringify(result));
                this.showToast('Success!', 'Step was Successfully Deleted!', 'success');
                this.refreshCR(true);
            })
            .catch((error) => {
                this.error = error;
            });
    }

    handleHHGoal() {
        this.openHHGoalModal = true;
    }

    closeHHGoalsModal() {
        this.openHHGoalModal = false;
        this.refreshCR(false);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}