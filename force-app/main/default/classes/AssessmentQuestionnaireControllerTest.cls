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
       Assessment__c assessmentTestData=TestFactory.createAssessment(null, 'Test Assessment',true);
        List<Question__c> quesList = new List<Question__c>();
        Question__c ques1=TestFactory.createQuestion(null,null,'Radio Box',false);
        Question__c ques2=TestFactory.createQuestion(null,null,'Picklist',false);
        Question__c ques3=TestFactory.createQuestion(null,null,'Text',false);
        ques1.Question_Text__c='Poor appetite or overeating?';
        ques2.Question_Text__c='Feeling tired or having little';
        ques3.Question_Text__c='What is your occupation?';
        quesList.add(ques1);
        quesList.add(ques2);
        quesList.add(ques3);
        insert quesList;
        List<Answer__c> ansList = new List<Answer__c>();
        Answer__c ans1=TestFactory.createAnswer(null,'Not at all',true,false);
        Answer__c ans2=TestFactory.createAnswer(null,'Several Days',true,false);
        Answer__c ans3=TestFactory.createAnswer(null,'More than half the days',true,false);
        Answer__c ans4=TestFactory.createAnswer(null,'Nearly every day',true,false);
        ansList.add(ans1);
        ansList.add(ans2);
        ansList.add(ans3);
        ansList.add(ans4);
        insert ansList;
        List<Question_Answer_Option__c> qaoList = new List<Question_Answer_Option__c>();
        Question_Answer_Option__c qao1=TestFactory.createQuestionAnswerOption(ans1.Id,ques1.Id,null,'Poor appetite or overeating?',false);
        Question_Answer_Option__c qao2=TestFactory.createQuestionAnswerOption(ans2.Id,ques1.Id,null,'Poor appetite or overeating?',false);
        Question_Answer_Option__c qao3=TestFactory.createQuestionAnswerOption(ans3.Id,ques1.Id,null,'Poor appetite or overeating?',false);
        Question_Answer_Option__c qao4=TestFactory.createQuestionAnswerOption(ans4.Id,ques1.Id,null,'Poor appetite or overeating?',false);
        Question_Answer_Option__c qao5=TestFactory.createQuestionAnswerOption(ans1.Id,ques2.Id,null,'Feeling tired or having little',false);
        Question_Answer_Option__c qao6=TestFactory.createQuestionAnswerOption(ans2.Id,ques2.Id,null,'Feeling tired or having little',false);
        Question_Answer_Option__c qao7=TestFactory.createQuestionAnswerOption(ans3.Id,ques2.Id,null,'Feeling tired or having little',false);
        Question_Answer_Option__c qao8=TestFactory.createQuestionAnswerOption(ans4.Id,ques2.Id,null,'Feeling tired or having little',false);
        qaoList.add(qao1);
        qaoList.add(qao2);
        qaoList.add(qao3);
        qaoList.add(qao4);
        qaoList.add(qao5);
        qaoList.add(qao6);
        qaoList.add(qao7);
        qaoList.add(qao8);
        insert qaoList;
        List<Assessment_Question__c> aqList = new List<Assessment_Question__c>();
        Assessment_Question__c assessQues1=TestFactory.createAssessmentQuestion(null, ques1.Id, assessmentTestData.Id, 'Client_Service__c|test_field__c', true, 1, 1, 'General', 'Default Section', false);
		assessQues1.Score__c = qao1.Id+'|10;'+qao2.Id+'|20;'+qao3.Id+'|30;'+qao4.Id+'|40';
        aqList.add(assessQues1);
        Assessment_Question__c assessQues2=TestFactory.createAssessmentQuestion(null, ques2.Id, assessmentTestData.Id, null, true, null, null, 'Dependent', null, false);
        assessQues2.Dependent_Sequence__c = 'A';
        assessQues2.Score__c = qao5.Id+'|10;'+qao6.Id+'|20;'+qao7.Id+'|30;'+qao8.Id+'|40';
        aqList.add(assessQues2);
        Assessment_Question__c assessQues3=TestFactory.createAssessmentQuestion(null, ques3.Id, assessmentTestData.Id, null, true, null, null, 'Dependent', null, false);
        assessQues3.Dependent_Sequence__c = 'i';
        aqList.add(assessQues3);
        insert aqList;
        List<Dependent_Question__c> depQuesList = new List<Dependent_Question__c>();
        Dependent_Question__c depQues1=TestFactory.createDependentQuestion(assessmentTestData.Id, assessQues2.Id, assessQues1.Id, qao1.Id,null,false);
        depQuesList.add(depQues1);
        Dependent_Question__c depQues2=TestFactory.createDependentQuestion(assessmentTestData.Id, assessQues3.Id, assessQues2.Id, qao5.Id,null,false);
        depQuesList.add(depQues2);
        insert depQuesList;
        Outcome__c outcomeASTestData=TestFactory.createOutcome(null, 'Test Outcome Assigned Service',assessmentTestData.Id,false);
  //      outcomeASTestData.Record_Id__c=asTestData.Id;
        outcomeASTestData.Status__c='Draft';
        outcomeASTestData.Assessment_Date__c=system.today();
        insert outcomeASTestData;
        Scoring__c score = TestFactory.createScoring( null, assessmentTestData.Id, 0, 50, 'Green', 'Green Status' , true );
    }
    
    static testMethod void testDraftSaveResponses(){
        List<Assessment_Question__c> assessQuesList = [select Id, Sequence__c, Dependent_Sequence__c from Assessment_Question__c];
        List<Question_Answer_Option__c> quesAnsList = [select Id from Question_Answer_Option__c];
   //     Referral__c ref = [select Id from Referral__c limit 1];
   //     Client__c client = [select Id from Client__c limit 1];
        Assessment__c assessment = [select Id, Name from Assessment__c limit 1];
        Outcome__c outcome = [select Id, Draft_Responses__c from Outcome__c limit 1];
        
        AssessmentQuestionnaireController.saveDraftResponses(null, assessment.Id, assessment.Name, System.today(), 'Assessment__c', '', null);
        System.assertNotEquals(null, outcome, 'Outcome should not be null');
    }
    /*
    static testMethod void  testGetRefASStatus(){
 //       Referral__c ref = [select Id from Referral__c limit 1];
  //      AssessmentQuestionnaireController.getRefASStatus(ref.Id, 'Referral__c');
    } */
    
    static testMethod void testSaveResponses(){
    	List<Assessment_Question__c> assessQuesList = [select Id, Sequence__c, Dependent_Sequence__c from Assessment_Question__c];
        List<Question_Answer_Option__c> quesAnsList = [select Id from Question_Answer_Option__c];
 //       Referral__c ref = [select Id from Referral__c limit 1];
//        Client__c client = [select Id from Client__c limit 1];
        Assessment__c assessment = [select Id, Name from Assessment__c limit 1];
        Outcome__c outcome = [select Id, Draft_Responses__c from Outcome__c limit 1];
        
        //assert statement
        System.assertNotEquals(assessment, null, 'Assessment record should exist.');
        System.assertNotEquals(outcome, null, 'Outcome record should exist.');
        
        String parentAssessQues;
        String childAssessQues;
        String grandChildAssessQues;
        for(Assessment_Question__c aq:assessQuesList){
            if(aq.Sequence__c != null && aq.Sequence__c == 1){
                parentAssessQues = aq.Id;
            }else if(String.isNotBlank(aq.Dependent_Sequence__c) && aq.Dependent_Sequence__c == 'A'){
                childAssessQues = aq.Id;
            }else if(String.isNotBlank(aq.Dependent_Sequence__c) && aq.Dependent_Sequence__c == 'i'){
                grandChildAssessQues = aq.Id;
            }
        }
        
		String jsonStr = '[{"sequence":"1","sectionSequence":1,"section":"Default Section","response":"Not at all","required":false,"quesText":"Poor appetite or overeating?","quesId":"'+parentAssessQues+'","quesAnsList":[{"value":"'+quesAnsList[0].Id+'|Not at all","label":"Not at all"},{"value":"'+quesAnsList[1].Id+'|Several Days","label":"Several Days"},{"value":"'+quesAnsList[2].Id+'|More than half the days","label":"More than half the days"},{"value":"'+quesAnsList[3].Id+'|Nearly every day","label":"Nearly every day"}],"parent":null,"level":"level1","isText":false,"isRadio":true,"isNumber":false,"isCombobox":false,"isCheckbox":false,"grandParent":null,"fieldUpdate":"","dataType":"Radio Box","assessmentQuesId":"'+parentAssessQues+'","responseId":"'+quesAnsList[0].Id+'","selectedValue":"'+quesAnsList[0].Id+'|Not at all","dependentQuestions":[{"sequence":"A","sectionSequence":null,"section":null,"response":"Not at all","required":false,"quesText":"Feeling tired or having little","quesId":"'+childAssessQues+'","quesAnsList":[{"value":"'+quesAnsList[4].Id+'|Not at all","label":"Not at all"},{"value":"'+quesAnsList[5].Id+'|Several Days","label":"Several Days"},{"value":"'+quesAnsList[6].Id+'|More than half the days","label":"More than half the days"},{"value":"'+quesAnsList[7].Id+'|Nearly every day","label":"Nearly every day"}],"parent":"'+parentAssessQues+'","level":"level2","isText":false,"isRadio":false,"isNumber":false,"isCombobox":true,"isCheckbox":false,"grandParent":null,"fieldUpdate":"","dataType":"Picklist","assessmentQuesId":"'+childAssessQues+'","selectedValue":"'+quesAnsList[4].Id+'|Not at all","dependentDependentQuestions":[{"sequence":"i","sectionSequence":null,"section":null,"response":"Software Engineer","required":false,"quesText":"What is your occupation?","quesId":"'+grandChildAssessQues+'","quesAnsList":null,"parent":"'+childAssessQues+'","level":"level3","isText":true,"isRadio":false,"isNumber":false,"isCombobox":false,"isCheckbox":false,"grandParent":"'+parentAssessQues+'","fieldUpdate":"","dataType":"Text","assessmentQuesId":"'+grandChildAssessQues+'","selectedValue":"Software Engineer"}]}]}]';
        //jsonStr = jsonStr.escapeHtml4();
        System.debug('jsonStr >> '+jsonStr);
        outcome.Draft_Responses__c = jsonStr;
        update outcome;
        Assessment__c assessments = [select Id, Name from Assessment__c limit 1];
        Outcome__c outcomes = [select Id, Draft_Responses__c from Outcome__c limit 1];
        System.assertNotEquals(outcomes.Draft_Responses__c, null, 'Draft_Responses__c should be updated in Outcome.');
        AssessmentQuestionnaireController.saveResponses(null, 'Account',assessments.Id, assessments.Name, outcomes.Draft_Responses__c, System.today(), null);
       
    }
    
    static testMethod void testgetAssessments()
    {
        Outcome__c outData=[Select id, Record_Id__c from Outcome__c Limit 1];
        Assessment__c assessData=[Select id from Assessment__c Limit 1];
        String jsonResponse = AssessmentQuestionnaireController.getAssessments(null);
        
        try{
            System.debug('getAssessments JSON Response >> ' + jsonResponse);
            List<Map<String, String>> assessments = (List<Map<String, String>>) JSON.deserializeUntyped(jsonResponse);
            System.assertNotEquals(null, assessments, 'Response should not be null');
            System.assertEquals(1, assessments.size(), 'Should return one active assessment');
            
        } catch(Exception e){
            System.debug('Error while processing assessments: ' + e.getMessage());
            
        }
       
        
        AssessmentQuestionnaireController.getDraftAssessments(outData.Record_Id__c);
        AssessmentQuestionnaireController.getAssessmentDetails(assessData.Id);
        AssessmentQuestionnaireController.getDraftAssessmentDetails(outData.Id);
    }
    static testMethod void testcheckLookupOnOutcomeObject()
    {
     //   Outcome__c outData=[Select id, Record_Id__c from Outcome__c Limit 1];
     //   Assessment__c assessData=[Select id from Assessment__c Limit 1];
       String response = AssessmentQuestionnaireController.checkLookupOnOutcomeObject('Outcome__c');
        system.debug('response recieved >>' + response);
       System.assertEquals('has lookup', response, 'The method should return "has lookup" for valid fields.'); 
        
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
        Assessment__c assessData=[Select id from Assessment__c Limit 1];
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
    static testMethod void testGetDependentQuestions()
    {
        Assessment_Question__c assqueData=[select Id from Assessment_Question__c where Type__c='General' limit 1];
        Question_Answer_Option__c qaoData=[select id from Question_Answer_Option__c Limit 1];
        String result = AssessmentQuestionnaireController.getDependentQuestions('Demo',assqueData.Id,qaoData.Id,'Level 1');
        system.debug('result>>>>' + result);
        System.assertNotEquals(result, null, 'Result should not be null');
        System.assert(result.contains(assqueData.Id), 'Result should contain assessment question ID');
       // System.assert(result.contains(qaoData.Id), 'Result should contain question answer option ID');
    }
}