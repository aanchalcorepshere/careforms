public with sharing class TaskTemplateController {
    @AuraEnabled
    public static string createTaskTemplate(caresp__Task_Template__c taskTemplate){
        if (Schema.sObjectType.caresp__Task_Template__c.isCreateable()) { // check  added by sg
             taskTemplate = (caresp__Task_Template__c)Security.stripInaccessible(AccessType.CREATABLE, new List<caresp__Task_Template__c>{taskTemplate}).getRecords()[0];
             Insert as user taskTemplate;

        }
        return taskTemplate.Id;
    }
    
    @AuraEnabled
    public static List<caresp__Task_Detail__c> createTaskDetails(List<caresp__Task_Detail__c> taskDetailRecs){
        if (Schema.sObjectType.caresp__Task_Detail__c.isCreateable()) { // check  added by sg
             taskDetailRecs  = (List<caresp__Task_Detail__c>)Security.stripInaccessible(AccessType.CREATABLE, taskDetailRecs).getRecords();
             Insert as user taskDetailRecs;
        }
        return taskDetailRecs;
    }
    
    @AuraEnabled
    public static string updateTaskDetails(List<caresp__Task_Detail__c> taskDetailRecs){
        if (Schema.sObjectType.caresp__Task_Detail__c.isUpdateable()) { // check  added by sg
             taskDetailRecs = (List<caresp__Task_Detail__c>)Security.stripInaccessible(AccessType.UPDATABLE, taskDetailRecs ).getRecords();

            update as user taskDetailRecs;
        }
        return 'done';
    }
}