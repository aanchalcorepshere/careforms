@isTest
public class ObjectInformationUtilTest {

    @isTest
    static void testGetObjectsList() {
        List<ObjectInformationUtil.ObjectWrapper> objectsList = ObjectInformationUtil.getObjectsList();
        System.assertNotEquals(0, objectsList.size()); 
        System.assertNotEquals(null, objectsList[0].label, 'Label should not be null');
        System.assertNotEquals(null, objectsList[0].value, 'Value should not be null');
    }

    @isTest
    static void testGetRecordTypes() {
        List<ObjectInformationUtil.OptionsWrapper> recordTypesList = ObjectInformationUtil.getRecordTypes('caresp__Question_Bank__c'); 
        System.assertNotEquals(0, recordTypesList.size());
        System.assertNotEquals(null, recordTypesList[0].label, 'Record type label should not be null');
        System.assertNotEquals(null, recordTypesList[0].value, 'Record type value should not be null');
    }

    @isTest
    static void testGetUserReferenceFieldsData() {
        List<String> objectList = new List<String>{ 'caresp__Question_Bank__c' }; 
        List<ObjectInformationUtil.FieldsWrapper> fieldsList = ObjectInformationUtil.getUserReferenceFieldsData(objectList);
        System.assertNotEquals(0, fieldsList.size(), 'Fields list should not be empty');
        System.assertEquals('caresp__Question_Bank__c', fieldsList[0].objectName, 'Object name should match');
    }

    @isTest
    static void testGetPicklistValues() {
        Question_Bank__c testQuesBank = TestFactory.createQuestionBank('Test Question Bank', '', true);
        Question__c testQuestion = TestFactory.createQuestion(testQuesBank.Id, '', 'Text', false);
        testQuestion.Question_Text__c='Test';
        testQuestion.Question_Type__c='General';
        insert testQuestion;
        List<ObjectInformationUtil.OptionsWrapper> picklistValuesList = ObjectInformationUtil.getPicklistValues('caresp__Question__c', 'caresp__Question_Type__c');
        System.assertNotEquals(0, picklistValuesList.size(), 'Picklist values list should not be empty');
        System.assertNotEquals(null, picklistValuesList[0].label, 'Picklist label should not be null');
        System.assertNotEquals(null, picklistValuesList[0].value, 'Picklist value should not be null');
    }
	@isTest
    static void testgetSubTypeOptions() {
       // List<String> objectList = new List<String>{ 'caresp__Question_Bank__c' }; 
        List<ObjectInformationUtil.OptionsWrapper> options = ObjectInformationUtil.getSubTypeOptions('caresp__Assessment__c',null);
        System.assertNotEquals(null, options, 'Options list should not be null');
        
    }
    @isTest
    static void testgetFieldsByPageLayout() {
       // List<String> objectList = new List<String>{ 'caresp__Question_Bank__c' }; 
        List<ObjectInformationUtil.OptionsWrapper> fieldsList = ObjectInformationUtil.getFieldsByPageLayout('caresp__Question_Bank__c','Question Bank Layout');
        System.assertNotEquals(null, fieldsList, 'Fields list should not be null');
        
    }

}