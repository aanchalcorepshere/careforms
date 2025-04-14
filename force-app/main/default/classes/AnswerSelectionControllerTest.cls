@isTest
public with sharing class AnswerSelectionControllerTest {

    @testSetup static void setupMaster(){
        Answer__c ansTestData=testFactory.createAnswer(null, 'Test Answer',true,true);
        Answer__c ansTestData2=testFactory.createAnswer(null, 'Test Answer2',true,true);
    }

    static testMethod void testGetActiveAnswers()
    {
        List<Answer__c> ansList = new List<Answer__c>();
        //Search term as null
        ansList=AnswerSelectionController.getActiveAnswers(null);
        Integer listSize=ansList.size();
        system.assertEquals(listSize, 2);

        //Providing search term
        ansList=AnswerSelectionController.getActiveAnswers('Test Answer2');
        listSize=ansList.size();
        system.assertEquals(listSize, 1);

    }

    
}