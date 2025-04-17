/* Test_Factory Class to Insert Records to be used in Test Classes */
@isTest
public with sharing class testFactory{
    public static Id getDefaultRT(Schema.DescribeSObjectResult dsr){
        Id rtID;
        for (Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()){
            if (rti.isDefaultRecordTypeMapping()){
                rtId = rti.getRecordTypeId();
            }
        }
        return rtId;
    }

    //Create Question Bank
    public static caresp__Question_Bank__c createQuestionBank(String questionText, String rtName, Boolean create ){
        Id qusBankRTId;
        if (rtName != null && rtName != '')
        {
            qusBankRTId = Schema.SObjectType.caresp__Question_Bank__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            qusBankRTId = testFactory.getDefaultRT(caresp__Question_Bank__c.SObjectType.getDescribe());
        }
        caresp__Question_Bank__c questionBank = new caresp__Question_Bank__c();
        questionBank.caresp__Question_Text__c = questionText;
        //questionBank.RecordTypeId     = qusBankRTId;
        
        if (create) insert questionBank;
        return questionBank;
    }
    //Create Question
    public static caresp__Question__c createQuestion(String questionBankId, String rtName, String questionDtype, Boolean create){
        Id qusRTId;
        if (rtName != null && rtName != ''){
            qusRTId = Schema.SObjectType.caresp__Question__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        } else{
            qusRTId = testFactory.getDefaultRT(caresp__Question__c.SObjectType.getDescribe());
        }
        caresp__Question__c question = new caresp__Question__c();
        question.caresp__Question_Data_type__c = questionDtype;
        if (questionBankId != null && questionBankId != ''){
            question.caresp__Question_Bank__c = questionBankId;
        }
        //question.RecordTypeId     = qusRTId;

        if (create)
            insert question;
        return question;
    }

    //create Answer
    public static caresp__Answer__c createAnswer(string rtName, String ansText, Boolean isActive, Boolean create){
        Id ansRTId;
        if (rtName != null && rtName != ''){
            ansRTId = Schema.SObjectType.caresp__Answer__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        } else{
            ansRTId = testFactory.getDefaultRT(caresp__Answer__c.SObjectType.getDescribe());
        }

        caresp__Answer__c ans = new caresp__Answer__c();
        //ans.RecordTypeId = ansRTId;
        ans.caresp__Answer_Text__c = ansText;
        ans.caresp__Active__c = isActive;

        if (create)
            insert ans;
        return ans;
    }

    // Create Question Answer Option
    public static caresp__Question_Answer_Option__c createQuestionAnswerOption(String answerId, String questionId, String rtName, String questionText, Boolean create){
        Id qusAnsOpRTId;
        if (rtName != null && rtName != ''){
            qusAnsOpRTId = Schema.SObjectType.caresp__Question_Answer_Option__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        } else{
            qusAnsOpRTId = testFactory.getDefaultRT(caresp__Question_Answer_Option__c.SObjectType.getDescribe());
        }
        caresp__Question_Answer_Option__c questionAnswerOptn = new caresp__Question_Answer_Option__c();
        questionAnswerOptn.caresp__Answer__c = answerId;
        questionAnswerOptn.caresp__Question__c = questionId;
        questionAnswerOptn.caresp__Question_Text__c = questionText;
        

        if (create)
            insert questionAnswerOptn;
        return questionAnswerOptn;
    }

    //Create Response
    public static caresp__Response__c createResponse( String rtName, String assessmentId, String outcomeId, Boolean create ){
        Id respRTId;
        if (rtName != null && rtName != '')
        {
            respRTId = Schema.SObjectType.caresp__Response__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            respRTId = TestFactory.getDefaultRT(caresp__Response__c.SObjectType.getDescribe());
        }
        caresp__Response__c response = new caresp__Response__c();
        if(assessmentId !=null && assessmentId != '')
        {
        response.caresp__Assessment__c = assessmentId;
        }
        if(outcomeId != null && outcomeId != '')
        {
            response.caresp__Outcome__c = outcomeId;
        }
        //response.RecordTypeId = respRTId;
        if (create) insert response;
        return response;
    }
    
    //create Assessment
    public static caresp__Assessment__c createAssessment(String rtName, String name, Boolean create){
        Id assessRTId;
        if (rtName != null && rtName != '')
        {
            assessRTId = Schema.SObjectType.caresp__Assessment__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            assessRTId = TestFactory.getDefaultRT(caresp__Assessment__c.SObjectType.getDescribe());
        }
        
        caresp__Assessment__c assessment = new caresp__Assessment__c();
        //assessment.RecordTypeId = assessRTId;
        assessment.Name = name;
        
        if (create) insert assessment;
        return assessment;
    }

    //create Outcome
    public static caresp__Outcome__c createOutcome(String rtName, String name, Id assessId, Boolean create){
        Id outRTId;
        if (rtName != null && rtName != '')
        {
            outRTId = Schema.SObjectType.caresp__Outcome__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            outRTId = TestFactory.getDefaultRT(caresp__Outcome__c.SObjectType.getDescribe());
        }
        
        caresp__Outcome__c outcome = new caresp__Outcome__c();
        //outcome.RecordTypeId = outRTId;
        outcome.Name = name;
        outcome.caresp__Assessment__c = assessId;
        
        if (create) insert outcome;
        return outcome;
    }

    //Create Account
    public static Account createAccount (String name, String rtName, Boolean create)
    {
        Id accRTId;
        if (rtName != null && rtName != '')
        {
            accRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            accRTId = TestFactory.getDefaultRT(Account.SObjectType.getDescribe());
        }
        Account acc = new Account();
        acc.Name = name;
        if (create) insert acc;
        return acc; 
    }
    
    //Create Contact
    public static Contact createContact (String lastName, string title, String rtName, ID accountId, Boolean create)
    {
        Id conRTId;
        if (rtName != null && rtName != '')
        {
            conRTId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            conRTId = TestFactory.getDefaultRT(Contact.SObjectType.getDescribe());
        }
        Contact con = new Contact();
        con.LastName = lastName;
        con.Title=title;
        con.Email='test@test.com';
        con.Phone='1234567890';
        con.AccountId = accountId;
        //con.RecordTypeId = conRTId;
        if (create) insert con;
        return con;
    }

    //create Assessment Question
    public static caresp__Assessment_Question__c createAssessmentQuestion(String rtName, Id questionId, Id assessmentId, String fieldUpdate, Boolean required, Integer sequence, Integer secSequence, String type, String section, Boolean create){
        Id assessQuesRTId;
        if (rtName != null && rtName != '')
        {
            assessQuesRTId = Schema.SObjectType.caresp__Assessment_Question__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            assessQuesRTId = TestFactory.getDefaultRT(caresp__Assessment_Question__c.SObjectType.getDescribe());
        }
        
        caresp__Assessment_Question__c assessmentQues = new caresp__Assessment_Question__c();
        //assessmentQues.RecordTypeId = assessQuesRTId;
        assessmentQues.caresp__Assessment__c = assessmentId;
        assessmentQues.caresp__Question__c = questionId;
        assessmentQues.caresp__sequence__c = sequence; 
        assessmentQues.caresp__Section_Sequence__c = secSequence;
        assessmentQues.caresp__Required__c = required;
        assessmentQues.caresp__Type__c = type;
        assessmentQues.caresp__Field_Update__c = fieldUpdate;
        assessmentQues.caresp__Section__c = section;
        
        if (create) insert assessmentQues;
        return assessmentQues;
    }

    //Create Dependent Question
    public static caresp__Dependent_Question__c createDependentQuestion(String assessId, String dependentAssessmentQuesId, String parentAssessmentQuesId, String questionAnsOptId,String rtName,Boolean create ){
        Id dqRTId;
        if (rtName != null && rtName != '')
        {
            dqRTId = Schema.SObjectType.caresp__Dependent_Question__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            dqRTId = TestFactory.getDefaultRT(caresp__Dependent_Question__c.SObjectType.getDescribe());
        }
        caresp__Dependent_Question__c depQues = new caresp__Dependent_Question__c();
        depQues.caresp__Assessment__c=assessId;
        depQues.caresp__Dependent_Question__c=dependentAssessmentQuesId;
        depQues.caresp__Parent_Question__c=parentAssessmentQuesId;
        depQues.caresp__Question_Answer_Option__c=questionAnsOptId;
        //response.RecordTypeId = respRTId;
        if (create) insert depQues;
        return depQues;
    }

    //Create Scoring records
    public static caresp__Scoring__c createScoring(String rtName, String assessmentId, Integer minScore, Integer maxScore, String color, String status, Boolean create){
        Id respRTId;
        if (rtName != null && rtName != '')
        {
            respRTId = Schema.SObjectType.caresp__Scoring__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            respRTId = TestFactory.getDefaultRT(caresp__Scoring__c.SObjectType.getDescribe());
        }
        caresp__Scoring__c scoringRec    = new caresp__Scoring__c();
        
        if(assessmentId !=null && assessmentId != '')
        {
            scoringRec.caresp__Assessment__c     = assessmentId;
        }
        if(minScore != null)
        {
            scoringRec.caresp__Min_Score__c  = minScore;
        }
        if(maxScore != null)
        {
            scoringRec.caresp__Max_Score__c  = maxScore;
        }
        if(String.isNotBlank(status))
        {
            scoringRec.caresp__Status__c  = status;
        }
        //response.RecordTypeId = respRTId;
        if (create) insert scoringRec;
        return scoringRec;
    }
    
    
    //create test class user
    Public static User getTestClassUser()
    {
         Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            Alias = 'sysadmin',
            Email = 'sysadmin@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'sysadmin.' + DateTime.now().getTime() + '@example.com'
        );
        insert adminUser;
        
        
        List<String> permSetNames = new List<String>{
            'Assessment_Module_Admin',
                'Forms_Module_Admin',
                'Plans_Module_Admin'
                };
                    
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        
        for (PermissionSet ps : [
            SELECT Id, Name FROM PermissionSet WHERE Name IN :permSetNames
        ]) {
            psaList.add(new PermissionSetAssignment(
                AssigneeId = adminUser.Id,
                PermissionSetId = ps.Id
            ));
        }
        
        if (!psaList.isEmpty()) {
            insert psaList;
            System.debug('Permission sets assigned successfully');
        } else {
            System.debug('No matching permission sets found');
        }
        return adminUser;
    }
    
  
}