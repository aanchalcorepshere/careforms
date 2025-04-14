import { LightningElement, api, wire } from 'lwc';
import getTaskRecord from '@salesforce/apex/ExecuteTaskController.getTaskRecord';
import markTaskCompleted from '@salesforce/apex/ExecuteTaskController.markTaskCompleted';

//const FIELDS = ['Task.Subject', 'Task.Type', 'Task.Task_Sub_Type__c'];

export default class ExecuteTaskContainer extends LightningElement {
    openModal = false;
    taskType;
    taskSubType;
    taskSubject;
    task;
    taskCompleted = false;
    showClientSelection=false;
    isCalledFromOtherComponent=true;
    clientId;
    clientName;


    @api recordId;
    @api objectApiName;

    @wire(getTaskRecord, { recordId: '$recordId'})
    wiredRecord({ error, data }) {
        if (error) {
            console.log('error >> ',JSON.stringify(error));
        } else if (data) {
            console.log('data >> ',JSON.stringify(data));
            this.task = data;
            if(this.task.completedFlag){
                this.taskCompleted = true;
            }else{
                this.taskSubject = this.task.subject;
                this.taskType = this.task.type;
                this.taskSubType = this.task.taskSubType;
                if(this.task.clientInfo){
                    let clientInfo = this.task.clientInfo.split('#');
                    this.clientId = clientInfo[0];
                    this.clientName = clientInfo[1];
                }
            }
        }
    }
    
    handleClick(){
        this.openModal = true;
    }

    closeModal(){
        this.openModal = false;
    }

    get showTaskExecuter(){
        return (this.taskType == 'Assessment' || this.taskType == 'Document Collection')
    }

    get typeAssessment(){
        return this.taskType == 'Assessment';
    }

    get typeDocCollection(){
        return this.taskType == 'Document Collection';
    }

    handleSubmitAssessment(){
        console.log('Responses submitted');
        this.openModal = false;
        this.taskCompleted = true;
        markTaskCompleted({taskId : this.task.taskId})
        .then(result => {
            window.location.reload();
        })
        .catch(error => {

        })
    }

    handleModalSubmit(){
        this.openModal = false;
        this.taskCompleted = true;
        markTaskCompleted({taskId : this.task.taskId})
        .then(result => {
            window.location.reload();
        })
        .catch(error => {

        })
    }
}