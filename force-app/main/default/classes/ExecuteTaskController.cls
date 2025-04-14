public with sharing class ExecuteTaskController {
    @AuraEnabled(cacheable = true)
    public static TaskWrapper getTaskRecord(String recordId){
        
        TaskWrapper resp = new TaskWrapper();
        Task taskRec =  [select Id, Subject, Type, TaskSubtype, WhatId, WhoId, CompletedDateTime from Task where Id =: recordId WITH SECURITY_ENFORCED];
        
        /* if(taskRec.WhatId.getSObjectType().getDescribe().getName() == 'Case'){
List<Case> caseRec = [select Id, Client__c, Client__r.Full_Name__c from Case where Id =: taskRec.WhatId];
if(String.isNotBlank(caseRec[0].Client__c)) resp.clientInfo = caseRec[0].Client__c+'#'+caseRec[0].Client__r.Full_Name__c;
} */
        
        resp.taskId = taskRec.Id;
        resp.subject = taskRec.Subject;
        resp.type = taskRec.Type;
        resp.taskSubType = taskRec.TaskSubtype;
        resp.whatId = taskRec.WhatId;
        resp.whoId = taskRec.WhoId;
      //  resp.completedFlag = taskRec.CompletedDateTime;
        
        return resp;
    }
    
    @AuraEnabled
    public static string markTaskCompleted(String taskId){
        try{
        if (Schema.sObjectType.Task.isUpdateable()) { // check added by sg
            update Security.stripInaccessible(AccessType.UPDATABLE, new List<Task>{new Task(Id = taskId, Status='Completed')}).getRecords();

            //update (new Task(Id = taskId, Status='Completed'));
        }
        }catch (Exception e) {
            
        }
        
        return taskId;
    }
    @TestVisible
    class TaskWrapper{
        @AuraEnabled public String taskId {get;set;}
        @AuraEnabled public String subject {get;set;}
        @AuraEnabled public String type {get;set;}
        @AuraEnabled public String taskSubType {get;set;}
        @AuraEnabled public String whatId {get;set;}
        @AuraEnabled public String whoId {get;set;}
    //    @AuraEnabled public Boolean completedFlag {get;set;}
        @AuraEnabled public String clientInfo {get;set;}
    }
}