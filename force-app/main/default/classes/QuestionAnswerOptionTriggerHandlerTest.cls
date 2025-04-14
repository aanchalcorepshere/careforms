@isTest
public with sharing class QuestionAnswerOptionTriggerHandlerTest {
    @testSetup static void setupMaster(){
        //Creating Question Bank
        Question_Bank__c questionBank = testFactory.createQuestionBank('Demo question bank', null, true);
        //Creating Question
        Question__c ques = testFactory.createQuestion(questionBank.Id, null, null,true);
        ques.Question_Text__c = 'Question';
        ques.Answer_Options__c = 'Answer option test';
        update ques;
        Question__c ques1 = testFactory.createQuestion(questionBank.Id, null, null,true);
        ques1.Question_Text__c = 'Question1';
        ques1.Answer_Options__c = 'Answer option test1';
        //ques1.Question_Type__c = 'General';
        update ques1;
        //Creating Answer 
        Answer__c ans = testFactory.createAnswer(null, 'Demo answer text', true, true);
        Answer__c ans1 = testFactory.createAnswer(null, 'Demo answer text1', true, true);
        //Create Question Answer option
        Question_Answer_Option__c questionAnswerOption = testFactory.CreateQuestionAnswerOption( ans.Id, ques.Id, null, null, true);
        Question_Answer_Option__c questionAnswerOption1 = testFactory.CreateQuestionAnswerOption( ans1.Id, ques.Id, null, null, true);


    }
    
    @isTest static void testUpdateQuestionBank()
    {
        Question_Answer_Option__c questionAnswerOptn = [Select Question__c, Answer__c from Question_Answer_Option__c limit 1];
        questionAnswerOptn.Score__c = 50;
        system.assertEquals(50, questionAnswerOptn.Score__c);
        test.startTest();
        update questionAnswerOptn;
        delete questionAnswerOptn;
        undelete questionAnswerOptn;
        test.stopTest();
    }
}