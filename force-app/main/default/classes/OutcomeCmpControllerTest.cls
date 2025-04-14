@isTest
public with sharing class OutcomeCmpControllerTest {
    @testSetup static void setupMaster(){
    //    Account accTestData=TestFactory.createAccount('ACDHS', 'Service Provider',true);
    /*    Service__c serviceTestData=TestFactory.createService('Test Service',null,true);
        SP_Service__c spserviceTestData=TestFactory.createSPService(accTestData.Id,serviceTestData.Id,null,true);
        Referral__c refTestData=TestFactory.createReferral('New', null, true);
        Client_Service__c asTestData = TestFactory.createClientService(spserviceTestData.Id,refTestData.Id,null,true);*/
        Assessment__c assessmentTestData=TestFactory.createAssessment(null, 'Test Assessment',true);
        Outcome__c outcomeASTestData=TestFactory.createOutcome(null, 'Test Outcome Assigned Service',assessmentTestData.Id,false);
     //   outcomeASTestData.Record_Id__c=asTestData.Id;
        outcomeASTestData.Assessment_Date__c=system.today();
        insert outcomeASTestData;
        Outcome__c outcomeRefTestData=TestFactory.createOutcome(null, 'Test Outcome Referral',assessmentTestData.Id,false);
  //      outcomeRefTestData.Record_Id__c=refTestData.Id;
        outcomeRefTestData.Status__c='Pending';
        outcomeRefTestData.Assessment_Date__c=system.today();
        insert outcomeRefTestData;

        Question_Bank__c qbTestData=TestFactory.createQuestionBank('Test Question',null,true);
        Question__c quesTestData=TestFactory.createQuestion(qbTestData.Id,null,'Radio Box',false);
        quesTestData.Question_Text__c='Test Question';
        quesTestData.Answer_Options__c='AnsOption1|AnsOption2';
        insert quesTestData;
        //Answer__c ansTestData=TestFactory.createAnswer();
        Assessment_Question__c ansQuesTestData=TestFactory.createAssessmentQuestion(null, quesTestData.Id, assessmentTestData.id, 'field Updation', false, 1, 1, 'General', 'Complaint Information', true);
        Response__c resposeTestData1=TestFactory.createResponse(null,assessmentTestData.Id,outcomeRefTestData.Id,false);
        resposeTestData1.Assessment_Question__c=ansQuesTestData.Id;
        resposeTestData1.Sequence__c='1';
        insert resposeTestData1;

        Response__c resposeTestData2=TestFactory.createResponse(null,assessmentTestData.Id,outcomeRefTestData.Id,false);
        resposeTestData2.Assessment_Question__c=ansQuesTestData.Id;
        resposeTestData2.Sequence__c='20';
        insert resposeTestData2;
        Response__c resposeTestData3=TestFactory.createResponse(null,assessmentTestData.Id,outcomeRefTestData.Id,false);
        resposeTestData3.Assessment_Question__c=ansQuesTestData.Id;
        resposeTestData3.Sequence__c='300';
        insert resposeTestData3;

        outcomeRefTestData.Status__c='Complete';

        update outcomeRefTestData;
    }

    static testMethod void testGetOutcomes()
    {
        Outcome__c outcomeTest= [select id, name, Record_Id__c, Status__c from Outcome__c where name=:'Test Outcome Referral' limit 1];
        List <Outcome__c> outcomeList= new List<Outcome__c>();
        outcomeList=OutcomeCmpController.getOutcomes(outcomeTest.Record_Id__c);
        Integer outcomeCount=outcomeList.size();
        system.assertEquals(outcomeCount, 1);
    }
    static testMethod void testGetOutcomeDetails()
    {
        Outcome__c outcomeASTest= [select id, name, Record_Id__c from Outcome__c where name='Test Outcome Assigned Service' limit 1];
        OutcomeCmpController.OutcomeDetailsWrapper result = OutcomeCmpController.getOutcomeDetails(outcomeASTest.Id,'Account');
        System.assertNotEquals(null, result, 'The result should not be null');

    //    Outcome__c outcomeRefTest= [select id, name, Record_Id__c from Outcome__c where name='Test Outcome Referral' limit 1];
    //    OutcomeCmpController.getOutcomeDetails(outcomeRefTest.Id,'caresp__Outcome__c');
    }
    static testMethod void testGetResponses()
    {
        Outcome__c outcomeRefTest= [select id, name, Record_Id__c from Outcome__c where name='Test Outcome Referral' limit 1];
        List<OutcomeCmpController.QuestionsWrapper> result = OutcomeCmpController.getResponses(outcomeRefTest.Id);
        System.assertNotEquals(null, result, 'The response list should not be null');
        
    }
}