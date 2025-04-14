@isTest
public with sharing class AssessmentTriggerHelperTest {
    @testSetup static void setupMaster(){
        Assessment__c assessmentTestData=TestFactory.createAssessment(null, 'Test Assessment',true);
      //  Assessment__c assessmentTestData2=TestFactory.createAssessment(null, 'Test Assessment2',true);
        Outcome__c outcomeTestData=TestFactory.createOutcome(null, 'Test Outcome1',assessmentTestData.Id,true);
    }
    static testMethod void testCheckAssessmentInUse(){
        
        try {
            Assessment__c assessmentData=[select id from Assessment__c limit 1];
        //    update assessmentData;
            delete assessmentData;
        } catch (Exception e) {
            system.assert(e.getMessage().contains('This Assessment cannot be deleted.'));
        }
 /*       Assessment__c assessmentData2=[select id from Assessment__c where name='Test Assessment2' limit 1];
        delete assessmentData2;
        undelete assessmentData2;*/
    }
}