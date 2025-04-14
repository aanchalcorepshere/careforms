@isTest
public with sharing class ResponseTriggerHandlerTest {
    
    @testSetup static void setUpData() {
        //Create Assessment
        Assessment__c assessmentTest = TestFactory.createAssessment(null, 'Test Response', true);
        //create QuestionBank
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
    @isTest public static void testQuestionTextOnResponse() 
    {
        list<Response__c> resp = [Select id, Assessment__c,Outcome__c,Assessment_Question__c  from Response__c limit 1];
        resp[0].Response__c = 'Less than 6 months';
        system.assertEquals('Less than 6 months', resp[0].Response__c);
        ResponseTriggerHandler.updateQuestionTextOnResponse(resp);
        test.startTest();
        update resp;
        delete resp;
        undelete resp;
        test.stopTest();

    }
}