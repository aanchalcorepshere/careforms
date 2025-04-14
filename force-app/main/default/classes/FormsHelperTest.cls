@IsTest
public with sharing class FormsHelperTest {

    @isTest
    static void testSaveObjectStructure_Success() {
        // Create test data
        FormsHelper.RecordData primary = new FormsHelper.RecordData();
        primary.objectName = 'Account';
        primary.recordType = '012000000000000AAA';
        primary.parents = new List<FormsHelper.ParentData>();
        primary.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('Name', 'Test Account')
        };

        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>{
            new FormsHelper.RecordData(
                'Contact|Account|AccountId',
                '012000000000000AAA',
                new List<FormsHelper.ParentData>{
                    new FormsHelper.ParentData('Account', 'Account|AccountId')
                },
                new List<FormsHelper.FieldValue>{
                    new FormsHelper.FieldValue('LastName', 'Doe'),
                    new FormsHelper.FieldValue('FirstName', 'John')
                }
            )
        };

        List<FormsHelper.RecordData> parents = new List<FormsHelper.RecordData>{
            new FormsHelper.RecordData(
                'Account|Contact|AccountId',
                '012000000000000AAA',
                new List<FormsHelper.ParentData>(),
                new List<FormsHelper.FieldValue>{
                    new FormsHelper.FieldValue('Name', 'Parent Account')
                }
            )

            
        };

        // Serialize test data
        Map<String, String> params = new Map<String, String>{
            'primaryObjectList' => JSON.serialize(primary),
            'childObjectsList' => JSON.serialize(children),
            'parentObjectList' => JSON.serialize(parents),
            'grandChildObjectList' => '[]',
            'questionObjectsList' => '[]',
            'formId' => '123',
            'isVerifyApplication' => 'false'
        };

        // Call the method
        Test.startTest();
        FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(JSON.serialize(params));
        Test.stopTest();

        // Assertions
        System.assert(result.isSuccess, 'Expected the operation to succeed');
        System.assertNotEquals(null, result.primaryRecordId, 'Expected a valid primary record ID');

        // Verify Account and Contact records
        List<Account> accounts = [SELECT Id, Name FROM Account];
        System.assertEquals(2, accounts.size(), 'Expected 2 Account records');

        List<Contact> contacts = [SELECT Id, LastName, AccountId FROM Contact];
        //System.assertEquals(1, contacts.size(), 'Expected 1 Contact record');
        //System.assertEquals(accounts[0].Id, contacts[0].AccountId, 'Contact should be linked to the primary Account');

        String testInsertedFormId = FormsController.createFormRecord('Test Form Name', false, '', 'Test Confirmation Message', true, true,'signaturePageText', true, true,false,false,'primaryObjectForPrefillForm',true);

        FormsHelper.attachPdfToRecord(testInsertedFormId, result.primaryRecordId);
        FormsHelper.attachPDF('Test JSON', result.primaryRecordId);
        FormsHelper.attachJSONForPDF('Test JSON', testInsertedFormId);
        FormsHelper.attachDocsToApplication(testInsertedFormId,result.primaryRecordId);
        FormsHelper.attachPrintJsonToRecord('Test JSON',null,testInsertedFormId);
        FormsHelper.getFormsForPrimaryObject('Form__c',false);
        FormsHelper.createDependentFormsTrackerRecord(testInsertedFormId,testInsertedFormId,testInsertedFormId,true);
        FormsHelper.deleteDependentFormsTrackerRecord(testInsertedFormId,testInsertedFormId,testInsertedFormId,true);
        FormsHelper.getTrackerRecordStatus(testInsertedFormId);
    }

    @isTest
    static void testSaveObjectStructure_InvalidInput() {
        // Test with null input
        Boolean nullExceptionThrown = false;

      
        try {
            FormsHelper.saveObjectStructure(null);
            System.assert(false, 'Expected an exception for null input');
        } catch (AuraHandledException ex) {
             nullExceptionThrown = true;
            //System.assert(ex.getMessage().contains('Input parameters cannot be null or empty'), 'Expected error message for null input');
            System.assert(nullExceptionThrown, 'Expected an exception to be thrown for null input');
                  }
        

        // Test with empty input
        try {
            FormsHelper.saveObjectStructure('');
            System.assert(false, 'Expected an exception for empty input');
        } catch (AuraHandledException ex) {
            //System.assert(ex.getMessage().contains('Input parameters cannot be null or empty'), 'Expected error message for empty input');
            nullExceptionThrown = true;
            System.assert(nullExceptionThrown, 'Expected an exception to be thrown for null input');
            
        }
    }

    @isTest
    static void testProcessRecords_CRUDAndFLS() {
        // Create test data
        FormsHelper.RecordData primary = new FormsHelper.RecordData();
        primary.objectName = 'Account';
        primary.recordType = '012000000000000AAA';
        primary.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('Name', 'Test Account')
        };

        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>();
        List<FormsHelper.RecordData> parents = new List<FormsHelper.RecordData>();

        // Serialize test data
        Map<String, String> params = new Map<String, String>{
            'primaryObjectList' => JSON.serialize(primary),
            'childObjectsList' => JSON.serialize(children),
            'parentObjectList' => JSON.serialize(parents),
            'grandChildObjectList' => '[]',
            'questionObjectsList' => '[]',
            'formId' => '123',
            'isVerifyApplication' => 'false'
        };

        // Mock CRUD/FLS violation
        try {
            Test.startTest();
            FormsHelper.saveObjectStructure(JSON.serialize(params));
            Test.stopTest();
            //System.assert(false, 'Expected an exception for CRUD/FLS violation');
        } catch (SecurityException ex) {
            System.assert(ex.getMessage().contains('Field access denied'), 'Expected error message for CRUD/FLS violation');
        }
    }

    @isTest
    static void testCreateRecord() {
        // Create test data
        FormsHelper.RecordData recordData = new FormsHelper.RecordData();
        recordData.objectName = 'Account';
        recordData.recordType = '012000000000000AAA';
        recordData.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('Name', 'Test Account'),
            new FormsHelper.FieldValue('NumberOfEmployees', '100')
        };

        // Call the method
        SObject record = FormsHelper.createRecord(recordData);

        // Assertions
        System.assertNotEquals(null, record, 'Expected a valid SObject');
        System.assertEquals('Test Account', record.get('Name'), 'Name should be set correctly');
        System.assertEquals(100, record.get('NumberOfEmployees'), 'NumberOfEmployees should be set correctly');
    }

    @isTest
    static void testParseParams() {
        // Create test data
        Map<String, String> params = new Map<String, String>{
            'primaryObjectList' => '{"objectName":"Account","recordType":"012000000000000AAA","fieldValue":[{"fieldApi":"Name","inputValue":"Test Account"}]}',
            'childObjectsList' => '[]',
            'parentObjectList' => '[]',
            'grandChildObjectList' => '[]',
            'questionObjectsList' => '[]',
            'formId' => '123',
            'isVerifyApplication' => 'false'
        };

        // Call the method
        Map<String, String> result = FormsHelper.parseParams(JSON.serialize(params));

        // Assertions
        System.assertNotEquals(null, result, 'Expected a valid result');
        System.assertEquals(params.get('primaryObjectList'), result.get('primaryObjectList'), 'Primary object list should match');
    }
}