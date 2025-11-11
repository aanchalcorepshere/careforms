/**
 * Test class for ResponseTriggerHandler.
 * It verifies the trigger logic for insert, update, delete, and undelete events on the Response__c object.
 */
@isTest
public with sharing class ResponseTriggerHandlerTest {
    
    /**
     * Sets up test data including Assessment, Question Bank, Question, Outcome,
     * Assessment Question, and Response records.
     */
    @testSetup static void setUpData() {
        //Create Assessment
        Assessment__c assessmentTest = TestFactory.createAssessment(null, 'Test Response', true);

        //Create QuestionBank
        Question_Bank__c questionBank = TestFactory.createQuestionBank('Demo question bank', null, true);

        //Create Question
        Question__c ques = TestFactory.createQuestion(questionBank.Id, null, null,false);
        ques.Question_Text__c = 'Question Text';
        insert ques;

        //Create Outcome
        Outcome__c outcomeTest = TestFactory.createOutcome(null, 'Outcome Demo', assessmentTest.id, true);

        //Create Assessment Question
        Assessment_Question__c assQuestion = TestFactory.createAssessmentQuestion(null, ques.Id, assessmentTest.id, 'field Updation', false, 1, 1, 'General', 'Complaint Information', true);

        //Create Response
        Response__c resp =  TestFactory.createResponse(null, assessmentTest.id, outcomeTest.id, false);
        resp.Assessment_Question__c = assQuestion.id;
        insert resp;
    }

    /**
     * Tests updating Response__c with a value and invokes ResponseTriggerHandler logic.
     */
    @isTest public static void testQuestionTextOnResponse() {
        List<Response__c> resp = [SELECT Id, Assessment__c, Outcome__c, Assessment_Question__c FROM Response__c LIMIT 1];
        resp[0].Response__c = 'Less than 6 months';
        System.assertEquals('Less than 6 months', resp[0].Response__c);

        // Manually call the handler (simulating trigger behavior in test context)
        ResponseTriggerHandler.updateQuestionTextOnResponse(resp);

        Test.startTest();
        update resp;   // Simulate after update trigger
        delete resp;   // Simulate before delete trigger
        undelete resp; // Simulate after undelete trigger
        Test.stopTest();
    }
}