// This class handles task-related operations like fetching and marking tasks as completed
public with sharing class ExecuteTaskController {
    
    // This method returns the Task record details in a wrapper for a given task ID
    @AuraEnabled(cacheable = true)
    public static TaskWrapper getTaskRecord(String recordId) {
        
        
        // Validate ID format (Critical fix)
        Id validatedRecordId;
        if(String.isNotBlank(recordId)) {
            validatedRecordId = Id.valueOf(recordId);
        } else {
            validatedRecordId = null;
        }
        
        try {
            TaskWrapper resp = new TaskWrapper();
            
            // Query the Task record with consistent security model (High fix)
            List<Task> taskList = [
                select Id, Subject, Type, TaskSubtype, WhatId, WhoId, CompletedDateTime 
                from Task 
                where Id = :validatedRecordId 
                WITH USER_MODE 
                LIMIT 1
            ];
            
           
            
            Task taskRec = taskList[0];
            
            
            
            resp.taskId = taskRec.Id;
            resp.subject = taskRec.Subject;
            resp.type = taskRec.Type;
            resp.taskSubType = taskRec.TaskSubtype;
            resp.whatId = taskRec.WhatId;
            resp.whoId = taskRec.WhoId;
            
            return resp;
            
        }catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in getTaskRecord: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while retrieving task: ' + ex.getMessage());
        }
    }
    
    // This method marks a Task record as completed by updating its status
    @AuraEnabled
    public static String markTaskCompleted(String taskId) {
        
        
        // Validate ID format (Critical fix)
        Id validatedTaskId;
        if(String.isNotBlank(taskId)) {
            validatedTaskId = Id.valueOf(taskId);
        } else {
            validatedTaskId = null;
        }
        
        try {
            // Verify task exists and user has access before updating
            List<Task> existingTasks = [
                SELECT Id, Status 
                FROM Task 
                WHERE Id = :validatedTaskId 
                WITH USER_MODE 
                LIMIT 1
            ];
            
           
            
            // Create task record for update
            Task taskToUpdate = new Task(
                Id = validatedTaskId, 
                Status = 'Completed'
            );
            
            // Use consistent security model (High fix)
            List<Task> tasksToUpdate = new List<Task>{taskToUpdate};
            List<SObject> updatableRecords = Security.stripInaccessible(
                AccessType.UPDATABLE, 
                tasksToUpdate
            ).getRecords();
            
            if (!updatableRecords.isEmpty()) {
                Database.update(updatableRecords, AccessLevel.USER_MODE);
            } else {
                throw new AuraHandledException('Insufficient permissions to update task status');
            }
            
            return String.valueOf(validatedTaskId);
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in markTaskCompleted: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while updating task: ' + ex.getMessage());
        }
    }

    // This wrapper class is used to transfer task data between Apex and Lightning components
    @TestVisible
    public class TaskWrapper {
        @AuraEnabled public String taskId {get;set;}
        @AuraEnabled public String subject {get;set;}
        @AuraEnabled public String type {get;set;}
        @AuraEnabled public String taskSubType {get;set;}
        @AuraEnabled public String whatId {get;set;}
        @AuraEnabled public String whoId {get;set;}
        @AuraEnabled public String clientInfo {get;set;}
    }
}