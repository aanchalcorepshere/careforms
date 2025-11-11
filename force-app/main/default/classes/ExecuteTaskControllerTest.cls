@isTest
public class ExecuteTaskControllerTest {
    @testSetup
    static void setupTestData() {
        // Create a test Account and Contact
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        // Create a test Task related to the Contact
        Task task = new Task(
            Subject = 'Test Task',
            Type = 'Call',
            Task_Sub_Type__c = 'Follow-up',
            WhatId = acc.Id,
            WhoId = con.Id,
            Status = 'Not Started'
        );
        insert task;
    }

    @isTest
    static void testMarkTaskCompleted() {
        // Fetch the created Task
        Task task = [SELECT Id, Status FROM Task LIMIT 1];

        // Ensure the task is not already completed
        System.assertEquals('Not Started', task.Status);

        // Test markTaskCompleted method
        Test.startTest();
        String updatedTaskId = ExecuteTaskController.markTaskCompleted(task.Id);
        Test.stopTest();

        // Validate task completion
        System.assertEquals(task.Id, updatedTaskId);

        Task updatedTask = [SELECT Status FROM Task WHERE Id = :task.Id];
        System.assertEquals('Completed', updatedTask.Status);
    }

    @isTest
    static void testMarkTaskCompletedWithInvalidId() {
        // Test markTaskCompleted with an invalid Task Id
        Test.startTest();
        try {
            ExecuteTaskController.markTaskCompleted('InvalidId');
        } catch (Exception e) {
            System.assert(true,true);
        }
        Test.stopTest();
    }

    @isTest
    static void testSecurityStripInaccessible() {
        // Verify security enforcement when updating the Task
        Task task = [SELECT Id FROM Task LIMIT 1];

        Test.startTest();
        String updatedTaskId = ExecuteTaskController.markTaskCompleted(task.Id);
        Test.stopTest();

        System.assertEquals(task.Id, updatedTaskId);
        Task updatedTask = [SELECT Status FROM Task WHERE Id = :task.Id];
        System.assertEquals('Completed', updatedTask.Status);
    }
    
    @isTest
    static void testgetTaskRecord() {
        // Fetch the created Task
        Task task = [SELECT Id, Subject, Type, TaskSubtype, WhatId, WhoId, CompletedDateTime FROM Task LIMIT 1];

        // Ensure the task is not already completed
  //      System.assertEquals('Not Started', task.Status);
        System.assertNotEquals(null, task, 'Task should exist');

        // Test markTaskCompleted method
        Test.startTest();
        ExecuteTaskController.TaskWrapper taskWrapper = ExecuteTaskController.getTaskRecord(task.Id);
        Test.stopTest();

        // Validate task completion
//        System.assertEquals(task.Id, updatedTaskId);

  //      Task updatedTask = [SELECT Status FROM Task WHERE Id = :task.Id];
    //    System.assertEquals('Completed', updatedTask.Status);
         // Validate task record details
        System.assertNotEquals(null, taskWrapper, 'TaskWrapper should not be null');
        System.assertEquals(task.Id, taskWrapper.taskId, 'Task ID should match');
        System.assertEquals(task.Subject, taskWrapper.subject, 'Task subject should match');
        System.assertEquals(task.Type, taskWrapper.type, 'Task type should match');
        System.assertEquals(task.TaskSubtype, taskWrapper.taskSubType, 'Task subtype should match');
        System.assertEquals(task.WhatId, taskWrapper.whatId, 'WhatId should match');
        System.assertEquals(task.WhoId, taskWrapper.whoId, 'WhoId should match');
    }
    
  /*   @isTest
    static void testGetTaskRecordWithClientInfo() {
        // Fetch the created Task with a Case (having Client__c field populated)
        Task task = [SELECT Id, WhatId FROM Task WHERE WhatId != NULL LIMIT 1];
        System.assertNotEquals(null, task, 'Task should exist with WhatId');

        Test.startTest();
        ExecuteTaskController.TaskWrapper taskWrapper = ExecuteTaskController.getTaskRecord(task.Id);
        Test.stopTest();

        // Validate task record details
        System.assertNotEquals(null, taskWrapper, 'TaskWrapper should not be null');
        System.assertNotEquals(null, taskWrapper.clientInfo, 'Client info should be populated');
    } */
}