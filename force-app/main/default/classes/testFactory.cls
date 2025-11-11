/* Test_Factory Class to Insert Records to be used in Test Classes */
// testFactory class – utility for creating test records across various objects
@isTest
public with sharing class testFactory {

    // getDefaultRT() – returns the default RecordTypeId for the given SObject describe result
    public static Id getDefaultRT(Schema.DescribeSObjectResult dsr){
        Id rtID;
        for (Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()){
            if (rti.isDefaultRecordTypeMapping()){
                rtId = rti.getRecordTypeId();
            }
        }
        return rtId;
    }

    // createQuestionBank() – creates and optionally inserts a Question Bank record
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

    // createQuestion() – creates and optionally inserts a Question record
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

    // createAnswer() – creates and optionally inserts an Answer record
    public static caresp__Answer__c createAnswer(String rtName, String ansText, Boolean isActive, Boolean create){
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

    // createQuestionAnswerOption() – creates and optionally inserts a Question Answer Option record
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

    // createResponse() – creates and optionally inserts a Response record
    public static caresp__Response__c createResponse(String rtName, String assessmentId, String outcomeId, Boolean create ){
        Id respRTId;
        if (rtName != null && rtName != '')
        {
            respRTId = Schema.SObjectType.caresp__Response__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            respRTId = testFactory.getDefaultRT(caresp__Response__c.SObjectType.getDescribe());
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

    // createAssessment() – creates and optionally inserts an Assessment record
    public static caresp__Assessment__c createAssessment(String rtName, String name, Boolean create){
        Id assessRTId;
        if (rtName != null && rtName != '')
        {
            assessRTId = Schema.SObjectType.caresp__Assessment__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            assessRTId = testFactory.getDefaultRT(caresp__Assessment__c.SObjectType.getDescribe());
        }

        caresp__Assessment__c assessment = new caresp__Assessment__c();
        //assessment.RecordTypeId = assessRTId;
        assessment.Name = name;

        if (create) insert assessment;
        return assessment;
    }

    // createOutcome() – creates and optionally inserts an Outcome record
    public static caresp__Outcome__c createOutcome(String rtName, String name, Id assessId, Boolean create){
        Id outRTId;
        if (rtName != null && rtName != '')
        {
            outRTId = Schema.SObjectType.caresp__Outcome__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            outRTId = testFactory.getDefaultRT(caresp__Outcome__c.SObjectType.getDescribe());
        }

        caresp__Outcome__c outcome = new caresp__Outcome__c();
        //outcome.RecordTypeId = outRTId;
        outcome.Name = name;
        outcome.caresp__Assessment__c = assessId;

        if (create) insert outcome;
        return outcome;
    }

    // createAccount() – creates and optionally inserts an Account record
    public static Account createAccount(String name, String rtName, Boolean create)
    {
        Id accRTId;
        if (rtName != null && rtName != '')
        {
            accRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            accRTId = testFactory.getDefaultRT(Account.SObjectType.getDescribe());
        }
        Account acc = new Account();
        acc.Name = name;
        if (create) insert acc;
        return acc; 
    }

    // createContact() – creates and optionally inserts a Contact record
    public static Contact createContact(String lastName, String title, String rtName, Id accountId, Boolean create)
    {
        Id conRTId;
        if (rtName != null && rtName != '')
        {
            conRTId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            conRTId = testFactory.getDefaultRT(Contact.SObjectType.getDescribe());
        }
        Contact con = new Contact();
        con.LastName = lastName;
        con.Title = title;
        con.Email = 'test@test.com';
        con.Phone = '1234567890';
        con.AccountId = accountId;
        //con.RecordTypeId = conRTId;
        if (create) insert con;
        return con;
    }

    // createAssessmentQuestion() – creates and optionally inserts an Assessment Question record
    public static caresp__Assessment_Question__c createAssessmentQuestion(String rtName, Id questionId, Id assessmentId, String fieldUpdate, Boolean required, Integer sequence, Integer secSequence, String type, String section, Boolean create){
        Id assessQuesRTId;
        if (rtName != null && rtName != '')
        {
            assessQuesRTId = Schema.SObjectType.caresp__Assessment_Question__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            assessQuesRTId = testFactory.getDefaultRT(caresp__Assessment_Question__c.SObjectType.getDescribe());
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

    // createDependentQuestion() – creates and optionally inserts a Dependent Question record
    public static caresp__Dependent_Question__c createDependentQuestion(String assessId, String dependentAssessmentQuesId, String parentAssessmentQuesId, String questionAnsOptId, String rtName, Boolean create){
        Id dqRTId;
        if (rtName != null && rtName != '')
        {
            dqRTId = Schema.SObjectType.caresp__Dependent_Question__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            dqRTId = testFactory.getDefaultRT(caresp__Dependent_Question__c.SObjectType.getDescribe());
        }
        caresp__Dependent_Question__c depQues = new caresp__Dependent_Question__c();
        depQues.caresp__Assessment__c = assessId;
        depQues.caresp__Dependent_Question__c = dependentAssessmentQuesId;
        depQues.caresp__Parent_Question__c = parentAssessmentQuesId;
        depQues.caresp__Question_Answer_Option__c = questionAnsOptId;
        //response.RecordTypeId = respRTId;
        if (create) insert depQues;
        return depQues;
    }

    // createScoring() – creates and optionally inserts a Scoring record
    public static caresp__Scoring__c createScoring(String rtName, String assessmentId, Integer minScore, Integer maxScore, String color, String status, Boolean create){
        Id respRTId;
        if (rtName != null && rtName != '')
        {
            respRTId = Schema.SObjectType.caresp__Scoring__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            respRTId = testFactory.getDefaultRT(caresp__Scoring__c.SObjectType.getDescribe());
        }
        caresp__Scoring__c scoringRec = new caresp__Scoring__c();

        if (assessmentId != null && assessmentId != '')
        {
            scoringRec.caresp__Assessment__c = assessmentId;
        }
        if (minScore != null)
        {
            scoringRec.caresp__Min_Score__c = minScore;
        }
        if (maxScore != null)
        {
            scoringRec.caresp__Max_Score__c = maxScore;
        }
        if (String.isNotBlank(status))
        {
            scoringRec.caresp__Status__c = status;
        }
        //response.RecordTypeId = respRTId;
        if (create) insert scoringRec;
        return scoringRec;
    }

    // getTestClassUser() – creates and returns a test User with admin profile and assigns permission sets
    public static User getTestClassUser()
    {
        // Query for System Administrator profile using USER_MODE
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' WITH USER_MODE LIMIT 1];
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

        // Query for permission sets to assign using USER_MODE
        List<PermissionSet> permSets = [SELECT Id, Name FROM PermissionSet WHERE Name IN :new List<String>{'Assessment_Module_Admin','Forms_Module_Admin','Plans_Module_Admin'} WITH USER_MODE];
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        for (PermissionSet ps : permSets) {
            psaList.add(new PermissionSetAssignment(
                AssigneeId = adminUser.Id,
                PermissionSetId = ps.Id
            ));
        }
        if (!psaList.isEmpty()) {
            insert psaList;
        }
        return adminUser;
    }

    // getParentObjConfigMdtPlans() – returns a Dynamic_Plan_Parent_Obj_Configuration__mdt record stub for testing
    public static Dynamic_Plan_Parent_Obj_Configuration__mdt getParentObjConfigMdtPlans(String parentObjName)
    {
        Dynamic_Plan_Parent_Obj_Configuration__mdt dummy = new Dynamic_Plan_Parent_Obj_Configuration__mdt(
            Label = parentObjName + '-Contact',
            caresp__Child_Filter_Field_API_Name__c = 'AccountId',
            caresp__Child_Obj_API_Name__c = 'Contact',
            caresp__Goal_s_Filter_Field_API_Name__c = 'caresp__Contact__c',
            caresp__Is_Junction_Exist__c = false,
            caresp__Is_Active__c = true,
            caresp__Parent_Obj_API_Name__c = parentObjName,
            caresp__Object_Fields_To_Display_List__c = 'Name-Title-Phone',
            caresp__Wrapper_Field_List__c = 'clientName,clientId',
            caresp__Obj_fields_for_wrapper_fields__c = 'Name,Id',
            caresp__Filter_Filed_Name_Plan_Obj__c = 'caresp__Placement_Agency_City__c'
        );
        return dummy;
    }
}