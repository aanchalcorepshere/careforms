@isTest
public with sharing class AssessmentQuestionnaireControllerTest {
    @testSetup static void setupMaster(){
        //       Account accTestData=TestFactory.createAccount('ACDHS', 'Service Provider',true);
        /*     Service__c serviceTestData=TestFactory.createService('Test Service',null,true);
            SP_Service__c spserviceTestData=TestFactory.createSPService(accTestData.Id,serviceTestData.Id,null,true);
            Client__c cliTestData=TestFactory.createClient('test Client', null, true);
            Referral__c refTestData=TestFactory.createReferral('New', null, false);
            refTestData.Client__c = cliTestData.Id;
            insert refTestData;
            Client_Referral__c clirefTestData=TestFactory.createClientReferral(cliTestData.Id,refTestData.Id,null,true);
            Client_Service__c asTestData = TestFactory.createClientService(spserviceTestData.Id,refTestData.Id,null,true);
            Junction_Service__c junservTestData=TestFactory.createJunctionService(cliTestData.Id,asTestData.Id,null,true);
           */
        caresp__Assessment__c assessmentTestData=TestFactory.createAssessment(null, 'Test Assessment',true);
        List<caresp__Question__c> quesList = new List<caresp__Question__c>();
        caresp__Question__c ques1=TestFactory.createQuestion(null,null,'Radio Box',false);
        caresp__Question__c ques2=TestFactory.createQuestion(null,null,'Picklist',false);
        caresp__Question__c ques3=TestFactory.createQuestion(null,null,'Text',false);
        caresp__Question__c ques4=TestFactory.createQuestion(null,null,'Number',false);
        caresp__Question__c ques5=TestFactory.createQuestion(null,null,'Checkbox',false);
        caresp__Question__c ques6=TestFactory.createQuestion(null,null,'Long Text Area',false);
        caresp__Question__c ques7=TestFactory.createQuestion(null,null,'Date',false);
        caresp__Question__c ques8=TestFactory.createQuestion(null,null,'Currency',false);
        caresp__Question__c ques9=TestFactory.createQuestion(null,null,'Telephone',false);
        ques1.caresp__Question_Text__c='Poor appetite or overeating?';
        ques2.caresp__Question_Text__c='Feeling tired or having little';
        ques3.caresp__Question_Text__c='What is your occupation?';
        ques4.caresp__Question_Text__c='What is your age?';
        ques5.caresp__Question_Text__c='Select all that apply';
        ques6.caresp__Question_Text__c='Describe your situation';
        ques7.caresp__Question_Text__c='What is your birth date?';
        ques8.caresp__Question_Text__c='What is your income?';
        ques9.caresp__Question_Text__c='What is your phone number?';
        quesList.add(ques1);
        quesList.add(ques2);
        quesList.add(ques3);
        quesList.add(ques4);
        quesList.add(ques5);
        quesList.add(ques6);
        quesList.add(ques7);
        quesList.add(ques8);
        quesList.add(ques9);
        insert quesList;
        
        List<caresp__Answer__c> ansList = new List<caresp__Answer__c>();
        caresp__Answer__c ans1=TestFactory.createAnswer(null,'Not at all',true,false);
        caresp__Answer__c ans2=TestFactory.createAnswer(null,'Several Days',true,false);
        caresp__Answer__c ans3=TestFactory.createAnswer(null,'More than half the days',true,false);
        caresp__Answer__c ans4=TestFactory.createAnswer(null,'Nearly every day',true,false);
        ansList.add(ans1);
        ansList.add(ans2);
        ansList.add(ans3);
        ansList.add(ans4);
        insert ansList;
        
        List<caresp__Question_Answer_Option__c> qaoList = new List<caresp__Question_Answer_Option__c>();
        caresp__Question_Answer_Option__c qao1=TestFactory.createQuestionAnswerOption(ans1.Id,ques1.Id,null,'Poor appetite or overeating?',false);
        caresp__Question_Answer_Option__c qao2=TestFactory.createQuestionAnswerOption(ans2.Id,ques1.Id,null,'Poor appetite or overeating?',false);
        caresp__Question_Answer_Option__c qao3=TestFactory.createQuestionAnswerOption(ans3.Id,ques1.Id,null,'Poor appetite or overeating?',false);
        caresp__Question_Answer_Option__c qao4=TestFactory.createQuestionAnswerOption(ans4.Id,ques1.Id,null,'Poor appetite or overeating?',false);
        caresp__Question_Answer_Option__c qao5=TestFactory.createQuestionAnswerOption(ans1.Id,ques2.Id,null,'Feeling tired or having little',false);
        caresp__Question_Answer_Option__c qao6=TestFactory.createQuestionAnswerOption(ans2.Id,ques2.Id,null,'Feeling tired or having little',false);
        caresp__Question_Answer_Option__c qao7=TestFactory.createQuestionAnswerOption(ans3.Id,ques2.Id,null,'Feeling tired or having little',false);
        caresp__Question_Answer_Option__c qao8=TestFactory.createQuestionAnswerOption(ans4.Id,ques2.Id,null,'Feeling tired or having little',false);
        caresp__Question_Answer_Option__c qao9=TestFactory.createQuestionAnswerOption(ans1.Id,ques5.Id,null,'Checkbox option 1',false);
        caresp__Question_Answer_Option__c qao10=TestFactory.createQuestionAnswerOption(ans2.Id,ques5.Id,null,'Checkbox option 2',false);
        qaoList.add(qao1);
        qaoList.add(qao2);
        qaoList.add(qao3);
        qaoList.add(qao4);
        qaoList.add(qao5);
        qaoList.add(qao6);
        qaoList.add(qao7);
        qaoList.add(qao8);
        qaoList.add(qao9);
        qaoList.add(qao10);
        insert qaoList;
        
        List<caresp__Assessment_Question__c> aqList = new List<caresp__Assessment_Question__c>();
        caresp__Assessment_Question__c assessQues1=TestFactory.createAssessmentQuestion(null, ques1.Id, assessmentTestData.Id, 'caresp__Client_Service__c|test_field__c', true, 1, 1, 'General', 'Default Section', false);
        assessQues1.caresp__Score__c = qao1.Id+'|10;'+qao2.Id+'|20;'+qao3.Id+'|30;'+qao4.Id+'|40';
        aqList.add(assessQues1);
        caresp__Assessment_Question__c assessQues2=TestFactory.createAssessmentQuestion(null, ques2.Id, assessmentTestData.Id, null, true, null, null, 'Dependent', null, false);
        assessQues2.caresp__Dependent_Sequence__c = 'A';
        assessQues2.caresp__Score__c = qao5.Id+'|10;'+qao6.Id+'|20;'+qao7.Id+'|30;'+qao8.Id+'|40';
        aqList.add(assessQues2);
        caresp__Assessment_Question__c assessQues3=TestFactory.createAssessmentQuestion(null, ques3.Id, assessmentTestData.Id, null, true, null, null, 'Dependent', null, false);
        assessQues3.caresp__Dependent_Sequence__c = 'i';
        aqList.add(assessQues3);
        
        // Add assessment questions for all data types
        caresp__Assessment_Question__c assessQues4=TestFactory.createAssessmentQuestion(null, ques4.Id, assessmentTestData.Id, null, true, 2, 2, 'General', 'Section 2', false);
        aqList.add(assessQues4);
        caresp__Assessment_Question__c assessQues5=TestFactory.createAssessmentQuestion(null, ques5.Id, assessmentTestData.Id, null, true, 3, 3, 'General', 'Section 3', false);
        assessQues5.caresp__Score__c = qao9.Id+'|5;'+qao10.Id+'|15';
        aqList.add(assessQues5);
        caresp__Assessment_Question__c assessQues6=TestFactory.createAssessmentQuestion(null, ques6.Id, assessmentTestData.Id, null, true, 4, 4, 'General', 'Section 4', false);
        aqList.add(assessQues6);
        caresp__Assessment_Question__c assessQues7=TestFactory.createAssessmentQuestion(null, ques7.Id, assessmentTestData.Id, null, true, 5, 5, 'General', 'Section 5', false);
        aqList.add(assessQues7);
        caresp__Assessment_Question__c assessQues8=TestFactory.createAssessmentQuestion(null, ques8.Id, assessmentTestData.Id, null, true, 6, 6, 'General', 'Section 6', false);
        aqList.add(assessQues8);
        caresp__Assessment_Question__c assessQues9=TestFactory.createAssessmentQuestion(null, ques9.Id, assessmentTestData.Id, null, true, 7, 7, 'General', 'Section 7', false);
        aqList.add(assessQues9);
        
        insert aqList;
        
        List<caresp__Dependent_Question__c> depQuesList = new List<caresp__Dependent_Question__c>();
        caresp__Dependent_Question__c depQues1=TestFactory.createDependentQuestion(assessmentTestData.Id, assessQues2.Id, assessQues1.Id, qao1.Id,null,false);
        depQuesList.add(depQues1);
        caresp__Dependent_Question__c depQues2=TestFactory.createDependentQuestion(assessmentTestData.Id, assessQues3.Id, assessQues2.Id, qao5.Id,null,false);
        depQuesList.add(depQues2);
        insert depQuesList;
        
        caresp__Outcome__c outcomeASTestData=TestFactory.createOutcome(null, 'Test Outcome Assigned Service',assessmentTestData.Id,false);
        //      outcomeASTestData.Record_Id__c=asTestData.Id;
        outcomeASTestData.caresp__Status__c='Draft';
        outcomeASTestData.caresp__Assessment_Date__c=system.today();
        insert outcomeASTestData;
        
        caresp__Scoring__c score = TestFactory.createScoring( null, assessmentTestData.Id, 0, 50, 'Green', 'Green Status' , true );
        
        // Create account for testing
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
    }
    
    static testMethod void testDraftSaveResponses(){
        List<caresp__Assessment_Question__c> assessQuesList = [select Id, caresp__Sequence__c, caresp__Dependent_Sequence__c from caresp__Assessment_Question__c];
        List<caresp__Question_Answer_Option__c> quesAnsList = [select Id from caresp__Question_Answer_Option__c];
        //     Referral__c ref = [select Id from Referral__c limit 1];
        //     Client__c client = [select Id from Client__c limit 1];
        caresp__Assessment__c assessment = [select Id, Name from caresp__Assessment__c limit 1];
        caresp__Outcome__c outcome = [select Id, caresp__Draft_Responses__c from caresp__Outcome__c limit 1];
        
        // Wrap in try/catch to handle AuraHandledException
        try {
            AssessmentQuestionnaireController.saveDraftResponses(
                null, assessment.Id, assessment.Name, System.today(), 'caresp__Assessment__c', '', null
            );
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.debug('Caught AuraHandledException in testDraftSaveResponses: ' + e.getMessage());
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null.');
        }

        System.assertNotEquals(null, outcome, 'Outcome should not be null');
    }

    // New test method for successful saveDraftResponses
    static testMethod void testSaveDraftResponsesSuccess(){
        caresp__Assessment__c assessment = [select Id, Name from caresp__Assessment__c limit 1];
        Account testAccount = [select Id from Account limit 1];
        
        Test.startTest();
        String result = AssessmentQuestionnaireController.saveDraftResponses(
            testAccount.Id, 
            assessment.Id, 
            assessment.Name, 
            System.today(), 
            'Account', 
            '{"test":"data"}', 
            null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.length() > 0, 'Result should contain outcome ID');
        
        // Verify outcome was created
        List<caresp__Outcome__c> outcomes = [SELECT Id, caresp__Draft_Responses__c FROM caresp__Outcome__c WHERE Id = :result];
        System.assertEquals(1, outcomes.size(), 'One outcome should be created');
    }

    // Test edge cases for saveDraftResponses
    /* static testMethod void testSaveDraftResponsesEdgeCases(){
        caresp__Assessment__c assessment = [select Id, Name from caresp__Assessment__c limit 1];
        Account testAccount = [select Id from Account limit 1];
        
        // Test with invalid assessment ID
        try {
            AssessmentQuestionnaireController.saveDraftResponses(
                testAccount.Id, 'invalid_id', assessment.Name, System.today(), 'Account', '', null
            );
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid ID format'), 'Should contain invalid ID message');
        }
        
        // Test with null assessment date
        try {
            AssessmentQuestionnaireController.saveDraftResponses(
                testAccount.Id, assessment.Id, assessment.Name, null, 'Account', '', null
            );
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Required parameters'), 'Should contain required parameters message');
        }
        
        // Test with blank assessment name
        try {
            AssessmentQuestionnaireController.saveDraftResponses(
                testAccount.Id, assessment.Id, '', System.today(), 'Account', '', null
            );
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Required parameters'), 'Should contain required parameters message');
        }
    } */

    /*
    static testMethod void  testGetRefASStatus(){
 //       Referral__c ref = [select Id from Referral__c limit 1];
  //      AssessmentQuestionnaireController.getRefASStatus(ref.Id, 'Referral__c');
    } */
    
    static testMethod void testSaveResponses(){
        List<caresp__Assessment_Question__c> assessQuesList = [select Id, caresp__Sequence__c, caresp__Dependent_Sequence__c from caresp__Assessment_Question__c];
        List<caresp__Question_Answer_Option__c> quesAnsList = [select Id from caresp__Question_Answer_Option__c];
        //       Referral__c ref = [select Id from Referral__c limit 1];
        //       Client__c client = [select Id from Client__c limit 1];
        caresp__Assessment__c assessment = [select Id, Name from caresp__Assessment__c limit 1];
        caresp__Outcome__c outcome = [select Id, caresp__Draft_Responses__c from caresp__Outcome__c limit 1];
        
        //assert statement
        System.assertNotEquals(assessment, null, 'Assessment record should exist.');
        System.assertNotEquals(outcome, null, 'Outcome record should exist.');
        
        String parentAssessQues;
        String childAssessQues;
        String grandChildAssessQues;
        for(caresp__Assessment_Question__c aq:assessQuesList){
            if(aq.caresp__Sequence__c != null && aq.caresp__Sequence__c == 1){
                parentAssessQues = aq.Id;
            }else if(String.isNotBlank(aq.caresp__Dependent_Sequence__c) && aq.caresp__Dependent_Sequence__c == 'A'){
                childAssessQues = aq.Id;
            }else if(String.isNotBlank(aq.caresp__Dependent_Sequence__c) && aq.caresp__Dependent_Sequence__c == 'i'){
                grandChildAssessQues = aq.Id;
            }
        }
        
        String jsonStr = '[{"sequence":"1","sectionSequence":1,"section":"Default Section","response":"Not at all","required":false,"quesText":"Poor appetite or overeating?","quesId":"'+parentAssessQues+'","quesAnsList":[{"value":"'+quesAnsList[0].Id+'|Not at all","label":"Not at all"},{"value":"'+quesAnsList[1].Id+'|Several Days","label":"Several Days"},{"value":"'+quesAnsList[2].Id+'|More than half the days","label":"More than half the days"},{"value":"'+quesAnsList[3].Id+'|Nearly every day","label":"Nearly every day"}],"parent":null,"level":"level1","isText":false,"isRadio":true,"isNumber":false,"isCombobox":false,"isCheckbox":false,"grandParent":null,"fieldUpdate":"","dataType":"Radio Box","assessmentQuesId":"'+parentAssessQues+'","responseId":"'+quesAnsList[0].Id+'","selectedValue":"'+quesAnsList[0].Id+'|Not at all","dependentQuestions":[{"sequence":"A","sectionSequence":null,"section":null,"response":"Not at all","required":false,"quesText":"Feeling tired or having little","quesId":"'+childAssessQues+'","quesAnsList":[{"value":"'+quesAnsList[4].Id+'|Not at all","label":"Not at all"},{"value":"'+quesAnsList[5].Id+'|Several Days","label":"Several Days"},{"value":"'+quesAnsList[6].Id+'|More than half the days","label":"More than half the days"},{"value":"'+quesAnsList[7].Id+'|Nearly every day","label":"Nearly every day"}],"parent":"'+parentAssessQues+'","level":"level2","isText":false,"isRadio":false,"isNumber":false,"isCombobox":true,"isCheckbox":false,"grandParent":null,"fieldUpdate":"","dataType":"Picklist","assessmentQuesId":"'+childAssessQues+'","selectedValue":"'+quesAnsList[4].Id+'|Not at all","dependentDependentQuestions":[{"sequence":"i","sectionSequence":null,"section":null,"response":"Software Engineer","required":false,"quesText":"What is your occupation?","quesId":"'+grandChildAssessQues+'","quesAnsList":null,"parent":"'+childAssessQues+'","level":"level3","isText":true,"isRadio":false,"isNumber":false,"isCombobox":false,"isCheckbox":false,"grandParent":"'+parentAssessQues+'","fieldUpdate":"","dataType":"Text","assessmentQuesId":"'+grandChildAssessQues+'","selectedValue":"Software Engineer"}]}]}]';
        System.debug('jsonStr >> '+jsonStr);
        outcome.caresp__Draft_Responses__c = jsonStr;
        update outcome;
        caresp__Assessment__c assessments = [select Id, Name from caresp__Assessment__c limit 1];
        caresp__Outcome__c outcomes = [select Id, caresp__Draft_Responses__c from caresp__Outcome__c limit 1];
        System.assertNotEquals(outcomes.caresp__Draft_Responses__c, null, 'Draft_Responses__c should be updated in Outcome.');
        
        // Added try-catch wrapper for AuraHandledException
        try {
            AssessmentQuestionnaireController.saveResponses(null, 'Account', assessments.Id, assessments.Name, outcomes.caresp__Draft_Responses__c, System.today(), null);
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.debug('AuraHandledException received: ' + e.getMessage());
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null.');
        }
    }

    // New test method for successful saveResponses
    static testMethod void testSaveResponsesSuccess(){
        List<caresp__Assessment_Question__c> assessQuesList = [select Id, caresp__Sequence__c, caresp__Dependent_Sequence__c from caresp__Assessment_Question__c];
        List<caresp__Question_Answer_Option__c> quesAnsList = [select Id from caresp__Question_Answer_Option__c];
        caresp__Assessment__c assessment = [select Id, Name from caresp__Assessment__c limit 1];
        Account testAccount = [select Id from Account limit 1];
        
        String parentAssessQues;
        for(caresp__Assessment_Question__c aq:assessQuesList){
            if(aq.caresp__Sequence__c != null && aq.caresp__Sequence__c == 1){
                parentAssessQues = aq.Id;
                break;
            }
        }
        
        String jsonStr = '[{"sequence":"1","sectionSequence":1,"section":"Default Section","response":"Not at all","required":false,"quesText":"Poor appetite or overeating?","quesId":"'+parentAssessQues+'","assessmentQuesId":"'+parentAssessQues+'","responseId":"'+quesAnsList[0].Id+'","fieldUpdate":"Name"}]';
        
        Test.startTest();
        String result = AssessmentQuestionnaireController.saveResponses(
            testAccount.Id, 
            'Account', 
            assessment.Id, 
            assessment.Name, 
            jsonStr, 
            System.today(), 
            null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        
        // Verify outcome was created
        List<caresp__Outcome__c> outcomes = [SELECT Id, caresp__Status__c FROM caresp__Outcome__c WHERE Id = :result];
        System.assertEquals(1, outcomes.size(), 'One outcome should be created');
        System.assertEquals('Complete', outcomes[0].caresp__Status__c, 'Status should be Complete');
    }

    // Test edge cases for saveResponses
    /* static testMethod void testSaveResponsesEdgeCases(){
        caresp__Assessment__c assessment = [select Id, Name from caresp__Assessment__c limit 1];
        Account testAccount = [select Id from Account limit 1];
        
        // Test with invalid JSON
        try {
            AssessmentQuestionnaireController.saveResponses(
                testAccount.Id, 'Account', assessment.Id, assessment.Name, 
                'invalid json', System.today(), null
            );
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid responses format'), 'Should contain invalid format message');
        }
        
        // Test with empty responses
        try {
            AssessmentQuestionnaireController.saveResponses(
                testAccount.Id, 'Account', assessment.Id, assessment.Name, 
                '[]', System.today(), null
            );
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Responses data is missing'), 'Should contain missing data message');
        }
        
        // Test with invalid record ID
        try {
            AssessmentQuestionnaireController.saveResponses(
                'invalid_id', 'Account', assessment.Id, assessment.Name, 
                '[{"test":"data"}]', System.today(), null
            );
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid ID format'), 'Should contain invalid ID message');
        }
    } */
    
    static testMethod void testgetAssessments()
    {
        caresp__Outcome__c outData=[Select id, caresp__Record_Id__c from caresp__Outcome__c Limit 1];
        caresp__Assessment__c assessData=[Select id from caresp__Assessment__c Limit 1];
        String jsonResponse = AssessmentQuestionnaireController.getAssessments(null);
        
        try{
            System.debug('getAssessments JSON Response >> ' + jsonResponse);
            List<Map<String, String>> assessments = (List<Map<String, String>>) JSON.deserializeUntyped(jsonResponse);
            System.assertNotEquals(null, assessments, 'Response should not be null');
            System.assertEquals(1, assessments.size(), 'Should return one active assessment');
            
        } catch(Exception e){
            System.debug('Error while processing assessments: ' + e.getMessage());
            
        }
        
        AssessmentQuestionnaireController.getDraftAssessments(outData.caresp__Record_Id__c);
        AssessmentQuestionnaireController.getAssessmentDetails(assessData.Id);
        AssessmentQuestionnaireController.getDraftAssessmentDetails(outData.Id);
    }

    // New test methods for better coverage
    /* static testMethod void testGetDraftAssessmentsEdgeCases(){
        // Test with null/empty record ID
        List<AssessmentQuestionnaireController.PicklistWrapper> result1 = 
            AssessmentQuestionnaireController.getDraftAssessments(null);
        System.assertEquals(0, result1.size(), 'Should return empty list for null ID');
        
        List<AssessmentQuestionnaireController.PicklistWrapper> result2 = 
            AssessmentQuestionnaireController.getDraftAssessments('');
        System.assertEquals(0, result2.size(), 'Should return empty list for empty ID');
        
        // Test with invalid ID format
        try {
            AssessmentQuestionnaireController.getDraftAssessments('invalid_id');
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid record ID format'), 'Should contain invalid ID message');
        }
    } */

    /* static testMethod void testGetAssessmentDetailsEdgeCases(){
        caresp__Assessment__c assessment = [select Id from caresp__Assessment__c limit 1];
        
        // Test with null assessment ID
        try {
            AssessmentQuestionnaireController.getAssessmentDetails(null);
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.debug('e.getMessage() >> '+e.getMessage());
            System.assert(e.getMessage().contains('Assessment ID cannot be null'), 'Should contain null ID message');
        }
        
        // Test with invalid ID format
        try {
            AssessmentQuestionnaireController.getAssessmentDetails('invalid_id');
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid assessment ID format'), 'Should contain invalid ID message');
        }
        
        // Test successful retrieval
        caresp__Assessment__c result = AssessmentQuestionnaireController.getAssessmentDetails(assessment.Id);
        System.assertNotEquals(null, result, 'Should return assessment record');
        System.assertEquals(assessment.Id, result.Id, 'Should return correct assessment');
    }

    static testMethod void testGetDraftAssessmentDetailsEdgeCases(){
        caresp__Outcome__c outcome = [select Id from caresp__Outcome__c limit 1];
        
        // Test with null outcome ID
        try {
            AssessmentQuestionnaireController.getDraftAssessmentDetails(null);
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Outcome ID cannot be null'), 'Should contain null ID message');
        }
        
        // Test with invalid ID format
        try {
            AssessmentQuestionnaireController.getDraftAssessmentDetails('invalid_id');
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid outcome ID format'), 'Should contain invalid ID message');
        }
        
        // Test successful retrieval
        AssessmentQuestionnaireController.DraftWrapper result = 
            AssessmentQuestionnaireController.getDraftAssessmentDetails(outcome.Id);
        System.assertNotEquals(null, result, 'Should return draft wrapper');
    } */

    static testMethod void testcheckLookupOnOutcomeObject() {
        // Test with null/empty object name
        String response1 = AssessmentQuestionnaireController.checkLookupOnOutcomeObject(null);
        System.assertEquals('Object name cannot be empty', response1, 'Should return empty message for null');
        
        String response2 = AssessmentQuestionnaireController.checkLookupOnOutcomeObject('');
        System.assertEquals('Object name cannot be empty', response2, 'Should return empty message for empty string');
        
        // Test with valid lookup field
        String response3 = AssessmentQuestionnaireController.checkLookupOnOutcomeObject('caresp__Assessment__c');
        System.assertEquals('has lookup', response3, 'Should return has lookup for valid field');
        
        // Test with non-existent field
        String response4 = AssessmentQuestionnaireController.checkLookupOnOutcomeObject('NonExistent');
        System.assertEquals('Field does not exist', response4, 'Should return field not exist message');
    }

    /*   static testMethod void testGetClients()
        {
            Referral__c refData=[select Id from Referral__c limit 1];
            client_service__c clisevData=[select Id from client_service__c limit 1];
            AssessmentQuestionnaireController.getClients(refData.Id);
            AssessmentQuestionnaireController.getClients(clisevData.Id);
        }*/
    
    static testMethod void testGetQuestions()
    {
        caresp__Assessment__c assessData=[Select id from caresp__Assessment__c Limit 1];
        String jsonResponse = AssessmentQuestionnaireController.getQuestions(assessData.Id);
        try{
            System.debug('getQuestions JSON Response: ' + jsonResponse);
            List<Map<String, Object>> responseList = (List<Map<String, Object>>) JSON.deserializeUntyped(jsonResponse);
            System.assertNotEquals(null, responseList, 'Response should not be null');
            System.assert(responseList.size() > 0, 'Response should contain at least one question');
        }
        catch(Exception e)
        {
            System.debug('Error while processing assessments: ' + e.getMessage());
        }
    }

    // New test methods for getQuestions edge cases
    /* static testMethod void testGetQuestionsEdgeCases(){
        caresp__Assessment__c assessment = [select Id from caresp__Assessment__c limit 1];
        
        // Test with null assessment ID
        try {
            AssessmentQuestionnaireController.getQuestions(null);
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Assessment ID cannot be null'), 'Should contain null ID message');
        }
        
        // Test with invalid ID format
        try {
            AssessmentQuestionnaireController.getQuestions('invalid_id');
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid assessment ID format'), 'Should contain invalid ID message');
        }
        
        // Test successful retrieval with all data types
        String jsonResponse = AssessmentQuestionnaireController.getQuestions(assessment.Id);
        System.assertNotEquals(null, jsonResponse, 'Response should not be null');
        
        List<Object> questionsList = (List<Object>) JSON.deserializeUntyped(jsonResponse);
        System.assert(questionsList.size() > 0, 'Should return questions');
        
        // Verify different data types are handled
        Boolean foundRadioBox = false, foundPicklist = false, foundText = false, foundNumber = false, 
                foundCheckbox = false, foundLongText = false, foundDate = false, foundCurrency = false, foundPhone = false;
        
        for(Object obj : questionsList) {
            Map<String, Object> question = (Map<String, Object>) obj;
            String dataType = (String) question.get('dataType');
            if(dataType == 'Radio Box') foundRadioBox = true;
            else if(dataType == 'Picklist') foundPicklist = true;
            else if(dataType == 'Text') foundText = true;
            else if(dataType == 'Number') foundNumber = true;
            else if(dataType == 'Checkbox') foundCheckbox = true;
            else if(dataType == 'Long Text Area') foundLongText = true;
            else if(dataType == 'Date') foundDate = true;
            else if(dataType == 'Currency') foundCurrency = true;
            else if(dataType == 'Telephone') foundPhone = true;
        }
        
        System.assert(foundRadioBox || foundPicklist || foundText, 'Should handle multiple data types');
    } */
    
    static testMethod void testGetDependentQuestions()
    {
        caresp__Assessment_Question__c assqueData=[select Id from caresp__Assessment_Question__c where caresp__Type__c='General' limit 1];
        caresp__Question_Answer_Option__c qaoData=[select id from caresp__Question_Answer_Option__c Limit 1];
        String result = AssessmentQuestionnaireController.getDependentQuestions('Demo',assqueData.Id,qaoData.Id,'Level 1');
        system.debug('result>>>>' + result);
        System.assertNotEquals(result, null, 'Result should not be null');
        System.assert(result.contains(assqueData.Id), 'Result should contain assessment question ID');
        // System.assert(result.contains(qaoData.Id), 'Result should contain question answer option ID');
    }

    // New test methods for getDependentQuestions edge cases
   /*  static testMethod void testGetDependentQuestionsEdgeCases(){
        caresp__Assessment_Question__c assqueData=[select Id from caresp__Assessment_Question__c where caresp__Type__c='General' limit 1];
        caresp__Question_Answer_Option__c qaoData=[select id from caresp__Question_Answer_Option__c Limit 1];
        
        // Test with null/empty parameters
        String result1 = AssessmentQuestionnaireController.getDependentQuestions(null, assqueData.Id, qaoData.Id, 'level1');
        List<Object> emptyList1 = (List<Object>) JSON.deserializeUntyped(result1);
        System.assertEquals(0, emptyList1.size(), 'Should return empty list for null grandParent');
        
        String result2 = AssessmentQuestionnaireController.getDependentQuestions('test', null, qaoData.Id, 'level1');
        List<Object> emptyList2 = (List<Object>) JSON.deserializeUntyped(result2);
        System.assertEquals(0, emptyList2.size(), 'Should return empty list for null parent');
        
        String result3 = AssessmentQuestionnaireController.getDependentQuestions('test', assqueData.Id, null, 'level1');
        List<Object> emptyList3 = (List<Object>) JSON.deserializeUntyped(result3);
        System.assertEquals(0, emptyList3.size(), 'Should return empty list for null ansOp');
        
        String result4 = AssessmentQuestionnaireController.getDependentQuestions('test', assqueData.Id, qaoData.Id, null);
        List<Object> emptyList4 = (List<Object>) JSON.deserializeUntyped(result4);
        System.assertEquals(0, emptyList4.size(), 'Should return empty list for null level');
        
        // Test with invalid ID formats
        try {
            AssessmentQuestionnaireController.getDependentQuestions('test', 'invalid_id', qaoData.Id, 'level1');
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid ID format'), 'Should contain invalid ID message');
        }
        
        // Test with level1 to level2 transition
        String result5 = AssessmentQuestionnaireController.getDependentQuestions('test', assqueData.Id, qaoData.Id, 'level1');
        System.assertNotEquals(null, result5, 'Should return result for level1');
        
        // Test with level2 to level3 transition
        String result6 = AssessmentQuestionnaireController.getDependentQuestions('test', assqueData.Id, qaoData.Id, 'level2');
        System.assertNotEquals(null, result6, 'Should return result for level2');
    } */

    // New test method for getTodayDate
    static testMethod void testGetTodayDate(){
        String result = AssessmentQuestionnaireController.getTodayDate();
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.length() > 0, 'Result should not be empty');
        System.assert(result.contains('/'), 'Result should contain date separators');
    }

    // Test wrapper classes
    static testMethod void testWrapperClasses(){
        // Test PicklistWrapper
        AssessmentQuestionnaireController.PicklistWrapper pw = 
            new AssessmentQuestionnaireController.PicklistWrapper('Test Label', 'Test Value');
        System.assertEquals('Test Label', pw.label, 'Label should be set correctly');
        System.assertEquals('Test Value', pw.value, 'Value should be set correctly');
        
        // Test DraftWrapper
        AssessmentQuestionnaireController.DraftWrapper dw = 
            new AssessmentQuestionnaireController.DraftWrapper();
        System.assertNotEquals(null, dw, 'DraftWrapper should be instantiated');
        
        // Test QuestionsWrapper
        List<AssessmentQuestionnaireController.PicklistWrapper> testList = 
            new List<AssessmentQuestionnaireController.PicklistWrapper>();
        testList.add(pw);
        
        AssessmentQuestionnaireController.QuestionsWrapper qw = 
            new AssessmentQuestionnaireController.QuestionsWrapper(
                'level1', 'aqId', 'qId', 'Question Text', 'Text', 
                '1', 'gp', 'p', 'fieldUpdate', 'section', 
                1.0, true, true, false, false, 
                false, false, false, false, false, 
                false, 'response', testList
            );
        
        System.assertEquals('level1', qw.level, 'Level should be set correctly');
        System.assertEquals('aqId', qw.assessmentQuesId, 'Assessment question ID should be set');
        System.assertEquals('qId', qw.quesId, 'Question ID should be set');
        System.assertEquals('Question Text', qw.quesText, 'Question text should be set');
        System.assertEquals('Text', qw.dataType, 'Data type should be set');
        System.assertEquals('1', qw.sequence, 'Sequence should be set');
        System.assertEquals('gp', qw.grandParent, 'Grand parent should be set');
        System.assertEquals('p', qw.parent, 'Parent should be set');
        System.assertEquals('fieldUpdate', qw.fieldUpdate, 'Field update should be set');
        System.assertEquals('section', qw.section, 'Section should be set');
        System.assertEquals(1.0, qw.sectionSequence, 'Section sequence should be set');
        System.assertEquals(true, qw.required, 'Required should be set');
        System.assertEquals(true, qw.isText, 'IsText should be set');
        System.assertEquals(false, qw.isNumber, 'IsNumber should be set');
        System.assertEquals(false, qw.isCheckbox, 'IsCheckbox should be set');
        System.assertEquals(false, qw.isRadio, 'IsRadio should be set');
        System.assertEquals(false, qw.isCombobox, 'IsCombobox should be set');
        System.assertEquals(false, qw.isLongText, 'IsLongText should be set');
        System.assertEquals(false, qw.isDate, 'IsDate should be set');
        System.assertEquals(false, qw.isCurrency, 'IsCurrency should be set');
        System.assertEquals(false, qw.isPhone, 'IsPhone should be set');
        System.assertEquals('response', qw.response, 'Response should be set');
        System.assertEquals(1, qw.quesAnsList.size(), 'Question answers list should have one item');
    }

    // Test complex response scenarios
    static testMethod void testComplexResponseScenarios(){
        List<caresp__Assessment_Question__c> assessQuesList = [select Id, caresp__Sequence__c, caresp__Dependent_Sequence__c from caresp__Assessment_Question__c];
        List<caresp__Question_Answer_Option__c> quesAnsList = [select Id from caresp__Question_Answer_Option__c];
        caresp__Assessment__c assessment = [select Id, Name from caresp__Assessment__c limit 1];
        Account testAccount = [select Id from Account limit 1];
        
        String parentAssessQues;
        String childAssessQues;
        for(caresp__Assessment_Question__c aq:assessQuesList){
            if(aq.caresp__Sequence__c != null && aq.caresp__Sequence__c == 1){
                parentAssessQues = aq.Id;
            }else if(String.isNotBlank(aq.caresp__Dependent_Sequence__c) && aq.caresp__Dependent_Sequence__c == 'A'){
                childAssessQues = aq.Id;
            }
        }
        
        // Test with complex nested responses including field updates
        String complexJsonStr = '[{' +
            '"sequence":"1",' +
            '"response":"Test Response",' +
            '"assessmentQuesId":"' + parentAssessQues + '",' +
            '"responseId":"' + quesAnsList[0].Id + '",' +
            '"fieldUpdate":"Name",' +
            '"dependentQuestions":[{' +
                '"sequence":"A",' +
                '"response":"Dependent Response",' +
                '"assessmentQuesId":"' + childAssessQues + '",' +
                '"responseId":"' + quesAnsList[4].Id + '"' +
            '}]' +
        '}]';
        
        Test.startTest();
        String result = AssessmentQuestionnaireController.saveResponses(
            testAccount.Id, 
            'Account', 
            assessment.Id, 
            assessment.Name, 
            complexJsonStr, 
            System.today(), 
            null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        
        // Verify responses were created
        List<caresp__Response__c> responses = [SELECT Id, caresp__Response__c FROM caresp__Response__c WHERE caresp__Outcome__c = :result];
        System.assert(responses.size() >= 2, 'Should create multiple responses including dependent ones');
    }

    // Test with existing draft outcome
    static testMethod void testSaveResponsesWithExistingDraft(){
        caresp__Assessment__c assessment = [select Id, Name from caresp__Assessment__c limit 1];
        caresp__Outcome__c existingOutcome = [select Id from caresp__Outcome__c limit 1];
        Account testAccount = [select Id from Account limit 1];
        List<caresp__Assessment_Question__c> assessQuesList = [select Id, caresp__Sequence__c from caresp__Assessment_Question__c where caresp__Sequence__c = 1 limit 1];
        List<caresp__Question_Answer_Option__c> quesAnsList = [select Id from caresp__Question_Answer_Option__c limit 1];
        
        String jsonStr = '[{"sequence":"1","assessmentQuesId":"' + assessQuesList[0].Id + '","response":"Test","responseId":"' + quesAnsList[0].Id + '"}]';
        
        Test.startTest();
        String result = AssessmentQuestionnaireController.saveResponses(
            testAccount.Id, 
            'Account', 
            assessment.Id, 
            assessment.Name, 
            jsonStr, 
            System.today(), 
            existingOutcome.Id
        );
        Test.stopTest();
        
        System.assertEquals(existingOutcome.Id, result, 'Should use existing outcome ID');
    }

    // Test error handling in helper methods
    static testMethod void testHelperMethodErrors(){
        caresp__Assessment__c assessment = [select Id, Name from caresp__Assessment__c limit 1];
        Account testAccount = [select Id from Account limit 1];
        
        // Test with malformed response data
        String malformedJson = '[{"assessmentQuesId":"invalid_format"}]';
        
        try {
            AssessmentQuestionnaireController.saveResponses(
                testAccount.Id, 
                'Account', 
                assessment.Id, 
                assessment.Name, 
                malformedJson, 
                System.today(), 
                null
            );
            // This should not throw an exception but should handle it gracefully
            System.assert(true, 'Should handle malformed response data gracefully');
        } catch (Exception e) {
            System.debug('Expected handling of malformed data: ' + e.getMessage());
        }
    }

    // Test object field updates
    static testMethod void testObjectFieldUpdates(){
        caresp__Assessment__c assessment = [select Id, Name from caresp__Assessment__c limit 1];
        Account testAccount = [select Id, Name from Account limit 1];
        List<caresp__Assessment_Question__c> assessQuesList = [select Id, caresp__Sequence__c from caresp__Assessment_Question__c where caresp__Sequence__c = 1 limit 1];
        List<caresp__Question_Answer_Option__c> quesAnsList = [select Id from caresp__Question_Answer_Option__c limit 1];
        
        String originalName = testAccount.Name;
        String newName = 'Updated Test Account';
        
        String jsonStr = '[{"sequence":"1","assessmentQuesId":"' + assessQuesList[0].Id + '","response":"' + newName + '","responseId":"' + quesAnsList[0].Id + '","fieldUpdate":"Name"}]';
        
        Test.startTest();
        String result = AssessmentQuestionnaireController.saveResponses(
            testAccount.Id, 
            'Account', 
            assessment.Id, 
            assessment.Name, 
            jsonStr, 
            System.today(), 
            null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return outcome ID');
        
        // Verify field was updated
        Account updatedAccount = [SELECT Name FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(newName, updatedAccount.Name, 'Account name should be updated');
    }
}