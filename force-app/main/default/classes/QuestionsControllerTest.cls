@isTest
public with sharing class QuestionsControllerTest {
    
    @testSetup static void setupMaster(){
        Question_Bank__c qbTestData=testFactory.createQuestionBank('Test Question',null,true);
        Question__c quesTestData=testFactory.createQuestion(qbTestData.Id,null,'Radio Box',false);
        quesTestData.Question_Text__c='Test Question';
        quesTestData.Answer_Options__c='AnsOption1|AnsOption2';
        quesTestData.Active__c=true;
        insert quesTestData;

        Answer__c ansTestData=testFactory.createAnswer(null,'Test Answer',true,true);
        Question_Answer_Option__c qaoTestData=testFactory.createQuestionAnswerOption(ansTestData.Id,quesTestData.Id,null,null,true);
    }

    static testMethod void testGetAllQuestions()
    {
        List<Question__c> quesList= new List<Question__c>();
        quesList=QuestionsController.getAllQuestions(true);
        Integer quesCount=quesList.size();
        system.assertEquals(quesCount,1);

        List<Question_Answer_Option__c> qaoList= new List<Question_Answer_Option__c>();
        Question__c ques=[select id, name from Question__c limit 1];
        qaoList=QuestionsController.getAnswerOptions(ques.Id);
        Integer qaoCount=qaoList.size();
        system.assertEquals(qaoCount,1);
        
        QuestionsController.deleteQuestion(ques.Id);
    }
}