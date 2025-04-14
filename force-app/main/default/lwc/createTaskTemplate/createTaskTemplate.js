import { LightningElement, track, wire } from 'lwc';
import getObjectsList from '@salesforce/apex/ObjectInformationUtil.getObjectsList';
import getRecordTypes from '@salesforce/apex/ObjectInformationUtil.getRecordTypes';
import getUserReferenceFieldsData from '@salesforce/apex/ObjectInformationUtil.getUserReferenceFieldsData';
import getSubTypeOptions from '@salesforce/apex/ObjectInformationUtil.getSubTypeOptions';
import getPicklistValues from '@salesforce/apex/ObjectInformationUtil.getPicklistValues';
import createTaskTemplate from '@salesforce/apex/TaskTemplateController.createTaskTemplate';
import createTaskDetails from '@salesforce/apex/TaskTemplateController.createTaskDetails';
import updateTaskDetails from '@salesforce/apex/TaskTemplateController.updateTaskDetails';

export default class CreateTaskTemplate extends LightningElement {
    @track objectListAll;
    @track recordTypes;
    wiredObjectList;
    error;
    selectedRelatedObject;
    selectedRecordtype;
    templateName;
    description;

    @track tasks;

    /* @track tasks = [
        {
          "taskIndex" : 1,
          "subject" : {
            "label":"Task Name",
            "value":""
          },
          "controllingTask" : {
            "label":"Parent Task",
            "value":[]
          },
          "assignedTo" : {
            "label":"Assigned To",
            "value":[
            ]
          }
        }
    ]; */
    
    @wire(getObjectsList)
    wiredObjects (result) {
        this.wiredObjectList = result;
        if (result.data) {
            let objectList = JSON.parse(JSON.stringify(result.data));
            objectList.sort(this.sortObjectList);
            this.objectListAll = objectList;
        }
    }

    get isLoading(){
        return !this.objectListAll;
    }

    get gettingRecordTypes(){
        return !this.recordTypes;
    }

    get isDefaultOrNoRecordType(){
        return (this.recordTypes && this.recordTypes.length == 0);
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

    handleChange(event){
        this.error = undefined;
        if(event.target.name == 'templatename'){
            this.templateName = event.target.value;
        }else if(event.target.name == 'description'){
            this.description = event.target.value;
        }else if(event.target.name == 'relatedobject'){
            this.selectedRelatedObject = event.target.value;
            this.recordTypes = undefined;
            getRecordTypes({objectApiName:this.selectedRelatedObject})
            .then(result => {
                let rtList = JSON.parse(JSON.stringify(result));
                rtList.sort(this.sortObjectList);
                this.recordTypes = rtList;
            })
            .catch(error => {
                this.error = JSON.stringify(error);
                console.error('error >> '+JSON.stringify(error));
            })

            this.initiateTasks();

        }else if(event.target.name == 'recordtype'){
            this.selectedRecordtype = event.target.value;
        }
    }

    initiateTasks(){
        getUserReferenceFieldsData({objectList : [this.selectedRelatedObject]})
        .then(result => {
            let refFieldData = JSON.parse(JSON.stringify(result[0].fields));
            
            getPicklistValues({objName : 'caresp__Task_Detail__c', fieldName : 'caresp__Type__c'})
            .then(result => {
                this.tasks = [
                    {
                      "taskIndex" : 1,
                      "subject" : {
                        "label":"Task Name",
                        "value":""
                      },
                      "description" : {
                        "label":"Task Description",
                        "value":""
                      },
                      "taskType" : {
                        "label":"Task Type",
                        "options": JSON.parse(JSON.stringify(result)),
                        "value": ""
                      },
                      "taskSubType" : {
                        "label":"Task Sub-Type",
                        "options":[],
                        "value": ""
                      },
                      "controllingTask" : {
                        "label":"Parent Task",
                        "options":[],
                        "value": ""
                      },
                      "assignedTo" : {
                        "label":"Assigned To",
                        "options": refFieldData,
                        "value" : ""
                      }
                    }
                ];
            })
            .catch(error => {
                this.error = JSON.stringify(error);
                console.error('error >> '+JSON.stringify(error));
            })
        })
        .catch(error => {
            this.error = JSON.stringify(error);
            console.error('error >> '+JSON.stringify(error));
        })
    }

    handleAddRow(){
        let isValid = this.checkPreviousRows();
        if(isValid){
            this.error = undefined;
            let tasksLength = this.tasks.length;
            let lastRow = JSON.parse(JSON.stringify(this.tasks[tasksLength-1]));
            lastRow.taskIndex = lastRow.taskIndex+1;
            lastRow.subject.value = null;
            lastRow.description.value = null;
            lastRow.controllingTask.value = null;
            lastRow.taskType.value = null;
            lastRow.taskSubType.options = [];
            lastRow.taskSubType.value = null;
            lastRow.assignedTo.value = null;
            this.tasks.push(lastRow);
        }else{
            this.error = 'Please fill task names';
        }
    }

    handleTaskDelete(event){
        let taskIndex = event.detail;
        console.log('taskIndex >> ',taskIndex);
        this.tasks.splice(taskIndex-1, 1);
        this.updateControllingTasks();
        this.resetIndexing();
        this.error = undefined;
    }

    handleTaskUpdate(event){
        this.error = undefined;
        let taskIndex = event.detail.taskIndex;
        let taskInfoType = event.detail.type;
        let taskInfoValue = event.detail.value;
        let taskPos = this.tasks.findIndex(x => x.taskIndex == taskIndex);
        switch(taskInfoType){
            case "taskname":
                this.tasks[taskPos].subject.value = taskInfoValue;
                this.updateControllingTasks();
            break;
            case "description":
                this.tasks[taskPos].description.value = taskInfoValue;
            break;
            case "tasktype":
                    this.tasks[taskPos].taskType.value = taskInfoValue;
                    getSubTypeOptions({objName : this.selectedRelatedObject, type : taskInfoValue})
                    .then(result => {
                        //if(result && result.length){
                            this.tasks[taskPos].taskSubType.options = JSON.parse(JSON.stringify(result));
                        //}
                    })
                    .catch(error => {
                        this.error = JSON.stringify(error);
                        console.error('error >> '+JSON.stringify(error));
                    })
            break;
            case "tasksubtype":
                    this.tasks[taskPos].taskSubType.value = taskInfoValue;
            break;
            case "parenttask":
                    this.tasks[taskPos].controllingTask.value = taskInfoValue;
            break;
            case "assignedto":
                this.tasks[taskPos].assignedTo.value = taskInfoValue;
            break;
        }

        console.log('tasks >> '+JSON.stringify(this.tasks));
    }

    updateControllingTasks(){
        let taskNames = [];
        this.tasks.forEach(task => {
            taskNames.push({
                "label" : task.subject.value,
                "value" : task.subject.value
            })
        })
        this.tasks.forEach(task => {
            task.controllingTask.options = JSON.parse(JSON.stringify(taskNames));
        })
    }

    resetIndexing(){
        let index = 1;
        this.tasks.forEach(task => {
            task.taskIndex = index;
            index++;
        })
    }

    checkPreviousRows(){
        let retVal = true;
        if(this.tasks && this.tasks.length){
            this.tasks.forEach(task => {
                if((!task.subject.value || task.subject.value == '' || task.subject.value.length == 0) && retVal == true){
                    retVal = false;
                }
            });
        }
        return retVal;
    }

    isFormValid(){
        let allSet = true;
        let tasksValid = this.checkPreviousRows();
        if(!this.templateName || this.templateName.trim() == ''){
            this.error = 'Please enter task name.';
            allSet = false;
        }else if(!this.selectedRelatedObject || this.selectedRelatedObject.trim() == ''){
            this.error = 'Please select an object.';
            allSet = false;
        }else if(!this.selectedRecordtype || this.selectedRecordtype.trim() == ''){
            this.error = 'Please select record type.';
            allSet = false;
        }else if(!tasksValid){
            this.error = 'Please fill all the required fields for task details.';
            allSet = false;
        }else{
            this.error = undefined;
        }

        return allSet;
    }

    handleSubmit(){
        if(this.isFormValid()){
            let taskTemplate = { 'sobjectType': 'caresp__Task_Template__c' };
            taskTemplate.caresp__Template_Name__c = this.templateName;
            taskTemplate.caresp__Template_Description__c = this.description;
            taskTemplate.caresp__Related_Object__c = this.selectedRelatedObject;
            taskTemplate.caresp__Record_Type_Name__c = this.selectedRecordtype;

            if(taskTemplate){
                createTaskTemplate({taskTemplate : taskTemplate})
                .then(result => {
                    let taskTemplateId = result;
                    if(taskTemplateId){
                        let taskDetailRecords = [];
                        this.tasks.forEach(task => {
                            let taskDetail = { 'sobjectType': 'caresp__Task_Detail__c' };
                            taskDetail.caresp__Task_Name__c = task.subject.value;
                            taskDetail.caresp__Task_Description__c = task.description.value;
                            taskDetail.caresp__Type__c = task.taskType.value;
                            taskDetail.caresp__Sub_Type__c = task.taskSubType.value;
                            taskDetail.caresp__Task_Description__c = task.description.value;
                            taskDetail.caresp__Assigned_To__c = task.assignedTo.value;
                            taskDetail.caresp__Task_Template__c = taskTemplateId;
                            taskDetailRecords.push(taskDetail);
                        })
                        createTaskDetails({taskDetailRecs : taskDetailRecords})
                        .then(result => {
                            let taskDetailRecordForUpdate = [];
                            //console.log('details >> ',JSON.stringify(result));
                            this.tasks.forEach(task => {
                                let parentName = task.controllingTask.value;
                                let childName = task.subject.value;
                                console.log('parentName >> '+parentName);
                                console.log('childName >> '+childName);
                                if(parentName && parentName.length){
                                    console.log('here >>');
                                    let parentPos = result.findIndex(x => x.caresp__Task_Name__c == parentName);
                                    let childPos = result.findIndex(x => x.caresp__Task_Name__c == childName);
                                    console.log('parentPos >> '+parentPos);
                                    console.log('childPos >> '+childPos);
                                    let parentId = result[parentPos].Id;
                                    let childId = result[childPos].Id;
                                    let updateTaskDetail = { 'sobjectType': 'caresp__Task_Detail__c' };
                                    updateTaskDetail.caresp__Parent_Task__c = parentId;
                                    updateTaskDetail.Id = childId;
                                    taskDetailRecordForUpdate.push(updateTaskDetail);
                                }
                            })
                            if(taskDetailRecordForUpdate && taskDetailRecordForUpdate.length){
                                updateTaskDetails({taskDetailRecs : taskDetailRecordForUpdate})
                                .then(result => {
                                    if(result == 'done'){
                                        alert('All saved # ',taskTemplateId);
                                    }
                                })
                                .catch(error => {
                                    this.error = JSON.stringify(error);
                                    console.error('Error >> ',JSON.stringify(error));
                                })
                            }
                        })
                        .catch(error => {
                            this.error = JSON.stringify(error);
                            console.error('Error >> ',JSON.stringify(error));
                        })
                    }
                })
                .catch(error => {
                    this.error = JSON.stringify(error);
                    console.error('Error >> ',JSON.stringify(error));
                })
            }
        }
    }
}