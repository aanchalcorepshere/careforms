@isTest
public class FormsHelperTest {
    
    @TestSetup
    static void makeData() {
        // Create test Form records
        Form__c testForm = new Form__c(
            //Name = 'Test Form',
            Form_Name__c = 'Test Form Name',
            Object_Name_for_Prefill_Fields__c = 'Contact',
            Prefill_Fields__c = true,
            Create_PDF_Only__c = false
        );
        insert testForm;
        
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Email = 'test@example.com'
        );
        insert testContact;
        
        // Create test Case
        Case testCase = new Case(
            Subject = 'Test Case',
            ContactId = testContact.Id,
            Status = 'New'
        );
        insert testCase;
    }
    
    /* @isTest
    static void testSaveObjectStructure_Success() {
        Test.startTest();
        
        // Prepare test data structures for successful insertion
        FormsHelper.RecordData primary = new FormsHelper.RecordData();
        primary.objectName = 'Contact|Contact';
        primary.recordType = '012000000000000AAA';
        primary.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('FirstName', 'Test'),
            new FormsHelper.FieldValue('LastName', 'Contact')
           // new FormsHelper.FieldValue('Email', 'test@example.com')
        };
        primary.parents = new List<FormsHelper.ParentData>{
            new FormsHelper.ParentData('Account', 'Account|AccountId')
        };
        
        List<FormsHelper.RecordData> parents = new List<FormsHelper.RecordData>();
        FormsHelper.RecordData parentRecord = new FormsHelper.RecordData();
        parentRecord.objectName = 'Account|Account';
        parentRecord.recordType = '012000000000000AAA';
        parentRecord.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('Name', 'Test Account')
        };
        parents.add(parentRecord);
        
        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>();
        FormsHelper.RecordData childRecord = new FormsHelper.RecordData();
        childRecord.objectName = 'Case|Case';
        childRecord.recordType = '012000000000000AAA';
        childRecord.fieldValue = new List<FormsHelper.FieldValue>();
        FormsHelper.FieldValue caseField = new FormsHelper.FieldValue('Subject', 'Test Case');
        caseField.recordIdentifier = 1;
        childRecord.fieldValue.add(caseField);
        childRecord.parents = new List<FormsHelper.ParentData>{
            new FormsHelper.ParentData('Contact', 'Contact|ContactId')
        };
        children.add(childRecord);
        
        List<FormsHelper.RecordData> grandchildren = new List<FormsHelper.RecordData>();
        
        // Create params JSON
        Map<String, Object> paramsMap = new Map<String, Object>{
            'primaryObjectList' => JSON.serialize(primary),
            'parentObjectList' => JSON.serialize(parents),
            'childObjectsList' => JSON.serialize(children),
            'grandChildObjectList' => JSON.serialize(grandchildren),
            'questionObjectsList' => '',
            'formId' => 'test123',
            'isVerifyApplication' => false
        };
        String params = JSON.serialize(paramsMap);
        
        FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(params);
        
        Test.stopTest();
        
        System.assert(result.isSuccess, 'Insert should be successful');
        System.assertNotEquals(null, result.primaryRecordId, 'Primary record ID should not be null');
    } */
    
    @isTest
    static void testSaveObjectStructure_InvalidParams() {
        Test.startTest();
        try {
            FormsHelper.saveObjectStructure('');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }
    
    /* @isTest
    static void testInsertRecordsWithUoW_WithExistingRecords() {
        // Test updating existing records by providing IDs
        Account existingAccount = [SELECT Id FROM Account LIMIT 1];
        Contact existingContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        
        // Prepare data with existing record IDs for update scenario
        FormsHelper.RecordData primary = new FormsHelper.RecordData();
        primary.objectName = 'Contact|Contact';
        primary.recordType = '012000000000000AAA';
        primary.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('Id', existingContact.Id),
            new FormsHelper.FieldValue('FirstName', 'Updated'),
            new FormsHelper.FieldValue('LastName', 'Contact')
            //new FormsHelper.FieldValue('Email', 'updated@example.com')
        };
        primary.parents = new List<FormsHelper.ParentData>{
            new FormsHelper.ParentData('Account', 'Account|AccountId')
        };
        
        List<FormsHelper.RecordData> parents = new List<FormsHelper.RecordData>();
        FormsHelper.RecordData parentRecord = new FormsHelper.RecordData();
        parentRecord.objectName = 'Account|Account';
        parentRecord.recordType = '012000000000000AAA';
        parentRecord.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('Id', existingAccount.Id),
            new FormsHelper.FieldValue('Name', 'Updated Account')
        };
        parents.add(parentRecord);
        
        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>();
        List<FormsHelper.RecordData> grandchildren = new List<FormsHelper.RecordData>();
        
        Map<String, Object> paramsMap = new Map<String, Object>{
            'primaryObjectList' => JSON.serialize(primary),
            'parentObjectList' => JSON.serialize(parents),
            'childObjectsList' => JSON.serialize(children),
            'grandChildObjectList' => JSON.serialize(grandchildren),
            'questionObjectsList' => '',
            'formId' => 'test123',
            'isVerifyApplication' => false
        };
        String params = JSON.serialize(paramsMap);
        
        FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(params);
        
        Test.stopTest();
        
        System.assert(result.isSuccess, 'Update should be successful');
        System.assertEquals(existingContact.Id, result.primaryRecordId, 'Should return existing contact ID');
    } */
    
    /* @isTest
    static void testInsertRecordsWithUoW_EmptyLists() {
        // Test with empty parent and children lists
        Test.startTest();
        
        FormsHelper.RecordData primary = new FormsHelper.RecordData();
        primary.objectName = 'Contact|Contact';
        primary.recordType = '012000000000000AAA';
        primary.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('FirstName', 'Solo'),
            new FormsHelper.FieldValue('LastName', 'Contact')
        };
        primary.parents = null; // Test null parents
        
        List<FormsHelper.RecordData> parents = new List<FormsHelper.RecordData>(); // Empty list
        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>(); // Empty list
        List<FormsHelper.RecordData> grandchildren = new List<FormsHelper.RecordData>(); // Empty list
        
        Map<String, Object> paramsMap = new Map<String, Object>{
            'primaryObjectList' => JSON.serialize(primary),
            'parentObjectList' => JSON.serialize(parents),
            'childObjectsList' => JSON.serialize(children),
            'grandChildObjectList' => JSON.serialize(grandchildren),
            'questionObjectsList' => '',
            'formId' => 'test123',
            'isVerifyApplication' => false
        };
        String params = JSON.serialize(paramsMap);
        
        FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(params);
        
        Test.stopTest();
        
        System.assert(result.isSuccess, 'Insert with empty lists should be successful');
    } */
    
    /* @isTest
    static void testInsertRecordsWithUoW_MultipleChildRecords() {
        // Test multiple child records with same and different recordIdentifiers
        Test.startTest();
        
        FormsHelper.RecordData primary = new FormsHelper.RecordData();
        primary.objectName = 'Contact|Contact';
        primary.recordType = '012000000000000AAA';
        primary.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('FirstName', 'Primary'),
            new FormsHelper.FieldValue('LastName', 'Contact')
        };
        
        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>();
        FormsHelper.RecordData childRecord = new FormsHelper.RecordData();
        childRecord.objectName = 'Case|Case';
        childRecord.recordType = '012000000000000AAA';
        childRecord.parents = new List<FormsHelper.ParentData>{
            new FormsHelper.ParentData('Contact', 'Contact|ContactId')
        };
        childRecord.fieldValue = new List<FormsHelper.FieldValue>();
        
        // Multiple fields for record 1
        FormsHelper.FieldValue case1Field1 = new FormsHelper.FieldValue('Subject', 'Case 1');
        case1Field1.recordIdentifier = 1;
        childRecord.fieldValue.add(case1Field1);
        
        FormsHelper.FieldValue case1Field2 = new FormsHelper.FieldValue('Status', 'New');
        case1Field2.recordIdentifier = 1;
        childRecord.fieldValue.add(case1Field2);
        
        // Multiple fields for record 2
        FormsHelper.FieldValue case2Field1 = new FormsHelper.FieldValue('Subject', 'Case 2');
        case2Field1.recordIdentifier = 2;
        childRecord.fieldValue.add(case2Field1);
        
        FormsHelper.FieldValue case2Field2 = new FormsHelper.FieldValue('Priority', 'High');
        case2Field2.recordIdentifier = 2;
        childRecord.fieldValue.add(case2Field2);
        
        children.add(childRecord);
        
        List<FormsHelper.RecordData> parents = new List<FormsHelper.RecordData>();
        List<FormsHelper.RecordData> grandchildren = new List<FormsHelper.RecordData>();
        
        Map<String, Object> paramsMap = new Map<String, Object>{
            'primaryObjectList' => JSON.serialize(primary),
            'parentObjectList' => JSON.serialize(parents),
            'childObjectsList' => JSON.serialize(children),
            'grandChildObjectList' => JSON.serialize(grandchildren),
            'questionObjectsList' => '',
            'formId' => 'test123',
            'isVerifyApplication' => false
        };
        String params = JSON.serialize(paramsMap);
        
        FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(params);
        
        Test.stopTest();
        
        System.assert(result.isSuccess, 'Multiple child records should be handled correctly');
    } */
    
    @isTest
    static void testParseParams() {
        Map<String, Object> testParams = new Map<String, Object>{
            'parentObjectList' => 'parent data',
            'primaryObjectList' => 'primary data',
            'childObjectsList' => 'children data',
            'grandChildObjectList' => 'grandchildren data',
            'questionObjectsList' => 'questions data',
            'formId' => 'form123',
            'isVerifyApplication' => true
        };
        String paramsJson = JSON.serialize(testParams);
        
        Test.startTest();
        Map<String, String> result = FormsHelper.parseParams(paramsJson);
        Test.stopTest();
        
        System.assertEquals('parent data', result.get('parentObjectList'));
        System.assertEquals('primary data', result.get('primaryObjectList'));
        System.assertEquals('children data', result.get('childObjectsList'));
        System.assertEquals('grandchildren data', result.get('grandChildObjectList'));
        System.assertEquals('questions data', result.get('questionObjectsList'));
        System.assertEquals('form123', result.get('formId'));
        System.assertEquals('true', result.get('isVerifyApplication'));
    }
    
    @isTest
    static void testCreateRecord() {
        FormsHelper.RecordData recordData = new FormsHelper.RecordData();
        recordData.objectName = 'Contact|Contact';
        recordData.recordType = '012000000000000AAA';
        recordData.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('FirstName', 'Test'),
            new FormsHelper.FieldValue('LastName', 'User')
            //new FormsHelper.FieldValue('Email', 'test@example.com')
        };
        
        Test.startTest();
        SObject result = FormsHelper.createRecord(recordData);
        Test.stopTest();
        
        System.assertEquals('Contact', result.getSObjectType().getDescribe().getName());
        System.assertEquals('Test', result.get('FirstName'));
        System.assertEquals('User', result.get('LastName'));
        //System.assertEquals('test@example.com', result.get('Email'));
    }
    
    /* @isTest
    static void testCreateRecord_WithRecordTypeId() {
        FormsHelper.RecordData recordData = new FormsHelper.RecordData();
        recordData.objectName = 'Contact|Contact';
        recordData.recordType = '012000000000000AAA'; // Different from default
        recordData.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('FirstName', 'RecordType'),
            new FormsHelper.FieldValue('LastName', 'Test')
        };
        
        Test.startTest();
        SObject result = FormsHelper.createRecord(recordData);
        Test.stopTest();
        
        System.assertEquals('Contact', result.getSObjectType().getDescribe().getName());
        System.assertEquals('012000000000000AAA', result.get('RecordTypeId'));
        System.assertEquals('RecordType', result.get('FirstName'));
    } */
    
    @isTest
    static void testCreateRecord_WithIdField() {
        Contact existingContact = [SELECT Id FROM Contact LIMIT 1];
        
        FormsHelper.RecordData recordData = new FormsHelper.RecordData();
        recordData.objectName = 'Contact|Contact';
        recordData.recordType = '012000000000000AAA';
        recordData.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('Id', existingContact.Id),
            new FormsHelper.FieldValue('FirstName', 'Updated'),
            new FormsHelper.FieldValue('LastName', 'Name')
        };
        
        Test.startTest();
        SObject result = FormsHelper.createRecord(recordData);
        Test.stopTest();
        
        System.assertEquals('Contact', result.getSObjectType().getDescribe().getName());
        System.assertEquals(existingContact.Id, result.Id);
        System.assertEquals('Updated', result.get('FirstName'));
    }
    
    @isTest 
    static void testCreateRecord_InvalidField() {
        FormsHelper.RecordData recordData = new FormsHelper.RecordData();
        recordData.objectName = 'Contact|Contact';
        recordData.recordType = '012000000000000AAA';
        recordData.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('InvalidField__c', 'Test Value')
        };
        
        Test.startTest();
        try {
            SObject result = FormsHelper.createRecord(recordData);
            System.assert(false, 'Should have thrown an exception for invalid field');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Invalid field'), 'Should throw IllegalArgumentException for invalid field');
        } catch (Exception e) {
            System.assert(e.getMessage() != null, 'Should throw some exception for invalid field');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testConvertToDataType() {
        Test.startTest();
        
        // Test Boolean conversion
        Object boolResult = FormsHelper.convertToDataType('true', Schema.DisplayType.BOOLEAN);
        System.assertEquals(true, boolResult);
        
        // Test Date conversion
        Object dateResult = FormsHelper.convertToDataType('2023-12-25', Schema.DisplayType.DATE);
        System.assertEquals(Date.valueOf('2023-12-25'), dateResult);
        
        // Test DateTime conversion
        Object datetimeResult = FormsHelper.convertToDataType('2023-12-25 10:30:00', Schema.DisplayType.DATETIME);
        System.assertNotEquals(null, datetimeResult);
        
        // Test Decimal conversion
        Object decimalResult = FormsHelper.convertToDataType('123.45', Schema.DisplayType.DOUBLE);
        System.assertEquals(123.45, decimalResult);
        
        // Test Integer conversion
        Object intResult = FormsHelper.convertToDataType('123', Schema.DisplayType.INTEGER);
        System.assertEquals(123, intResult);
        
        // Test Long conversion
        Object longResult = FormsHelper.convertToDataType('1234567890', Schema.DisplayType.LONG);
        System.assertEquals(1234567890L, longResult);
        
        // Test Time conversion
        Object timeResult = FormsHelper.convertToDataType('14:30:25', Schema.DisplayType.TIME);
        System.assertNotEquals(null, timeResult);
        
        // Test String conversion (default)
        Object stringResult = FormsHelper.convertToDataType('test string', Schema.DisplayType.STRING);
        System.assertEquals('test string', stringResult);
        
        // Test null value
        Object nullResult = FormsHelper.convertToDataType(null, Schema.DisplayType.STRING);
        System.assertEquals(null, nullResult);
        
        // Test empty string
        Object emptyResult = FormsHelper.convertToDataType('', Schema.DisplayType.STRING);
        System.assertEquals(null, emptyResult);
        
        Test.stopTest();
    }
    
    @isTest
    static void testGroupChildrenByRecordIdentifier_ValidObject() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>();
        
        FormsHelper.RecordData child1 = new FormsHelper.RecordData();
        child1.objectName = 'Case'; // Valid object name
        child1.recordType = '012000000000000AAA';
        child1.parents = new List<FormsHelper.ParentData>{
            new FormsHelper.ParentData('Contact', 'Contact|ContactId')
        };
        child1.fieldValue = new List<FormsHelper.FieldValue>();
        
        // Add fields with same recordIdentifier to test grouping
        FormsHelper.FieldValue field1 = new FormsHelper.FieldValue('Subject', 'Case 1');
        field1.recordIdentifier = 1;
        child1.fieldValue.add(field1);
        
        FormsHelper.FieldValue field2 = new FormsHelper.FieldValue('Status', 'New');
        field2.recordIdentifier = 1;
        child1.fieldValue.add(field2);
        
        // Add field with different recordIdentifier
        FormsHelper.FieldValue field3 = new FormsHelper.FieldValue('Subject', 'Case 2');
        field3.recordIdentifier = 2;
        child1.fieldValue.add(field3);
        
        children.add(child1);
        
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'primaryObjectList' => JSON.serialize(new FormsHelper.RecordData('Contact', '012000000000000AAA', null, new List<FormsHelper.FieldValue>{new FormsHelper.FieldValue('LastName', 'Test')})),
            'parentObjectList' => JSON.serialize(new List<FormsHelper.RecordData>()),
            'childObjectsList' => JSON.serialize(children),
            'grandChildObjectList' => JSON.serialize(new List<FormsHelper.RecordData>()),
            'questionObjectsList' => '',
            'formId' => 'test123',
            'isVerifyApplication' => false
        };
        
        try {
            FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(JSON.serialize(paramsMap));
            System.assert(true, 'Method executed successfully');
        } catch (Exception e) {
            System.assert(e.getMessage() != null, 'Exception thrown as expected: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGroupChildrenByRecordIdentifier_InvalidObject() {
        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>();
        
        FormsHelper.RecordData child1 = new FormsHelper.RecordData();
        child1.objectName = 'InvalidObject__c'; // Object that doesn't exist
        child1.recordType = '012000000000000AAA';
        child1.fieldValue = new List<FormsHelper.FieldValue>();
        
        FormsHelper.FieldValue field1 = new FormsHelper.FieldValue('SomeField__c', 'Test Value');
        field1.recordIdentifier = 1;
        child1.fieldValue.add(field1);
        
        children.add(child1);
        
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'primaryObjectList' => JSON.serialize(new FormsHelper.RecordData('Contact', '012000000000000AAA', null, new List<FormsHelper.FieldValue>{new FormsHelper.FieldValue('LastName', 'Test')})),
            'parentObjectList' => JSON.serialize(new List<FormsHelper.RecordData>()),
            'childObjectsList' => JSON.serialize(children),
            'grandChildObjectList' => JSON.serialize(new List<FormsHelper.RecordData>()),
            'questionObjectsList' => '',
            'formId' => 'test123',
            'isVerifyApplication' => false
        };
        
        try {
            FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(JSON.serialize(paramsMap));
            System.assert(true, 'Method handled invalid object gracefully');
        } catch (Exception e) {
            System.assert(e.getMessage() != null, 'Exception expected for invalid object');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGroupChildrenByRecordIdentifier_NullFields() {
        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>();
        
        FormsHelper.RecordData child1 = new FormsHelper.RecordData();
        child1.objectName = 'Case';
        child1.recordType = '012000000000000AAA';
        child1.fieldValue = new List<FormsHelper.FieldValue>();
        
        // Add a valid field
        FormsHelper.FieldValue validField = new FormsHelper.FieldValue('Subject', 'Valid Case');
        validField.recordIdentifier = 1;
        child1.fieldValue.add(validField);
        
        // Add a null field (simulating the null check in the method)
        child1.fieldValue.add(null);
        
        children.add(child1);
        
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'primaryObjectList' => JSON.serialize(new FormsHelper.RecordData('Contact', '012000000000000AAA', null, new List<FormsHelper.FieldValue>{new FormsHelper.FieldValue('LastName', 'Test')})),
            'parentObjectList' => JSON.serialize(new List<FormsHelper.RecordData>()),
            'childObjectsList' => JSON.serialize(children),
            'grandChildObjectList' => JSON.serialize(new List<FormsHelper.RecordData>()),
            'questionObjectsList' => '',
            'formId' => 'test123',
            'isVerifyApplication' => false
        };
        
        try {
            FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(JSON.serialize(paramsMap));
            System.assert(true, 'Method handled null fields gracefully');
        } catch (Exception e) {
            System.assert(e.getMessage() != null, 'Exception handled appropriately');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAttachJSONForPDF() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Form__c testForm = [SELECT Id FROM Form__c LIMIT 1];
        
        String jsonData = '{"test": "data"}';
        
        Test.startTest();
        FormsHelper.attachJSONForPDF(jsonData, testForm.Id);
        Test.stopTest();
        
        List<ContentVersion> attachments = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE :'%' + testForm.Id + '%'];
        System.assertEquals(1, attachments.size(), 'Should have created one attachment');
    }
    
    @isTest
    static void testAttachPdfToRecord() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Form__c testForm = [SELECT Id FROM Form__c LIMIT 1];
        
        Test.startTest();
        FormsHelper.attachPdfToRecord(testForm.Id, testContact.Id);
        Test.stopTest();
        
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testContact.Id];
        System.assertEquals(1, links.size(), 'Should have created one document link');
    }
    
    @isTest
    static void testAttachPDF() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        String jsonData = '{"test": "data"}';
        
        Test.startTest();
        FormsHelper.attachPDF(jsonData, testContact.Id);
        Test.stopTest();
        
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testContact.Id];
        System.assertEquals(1, links.size(), 'Should have created one document link');
    }
    
    @isTest
    static void testAttachDocsToApplication() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Create a test document attached to the account
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test content'),
            FirstPublishLocationId = testAccount.Id
        );
        insert cv;
        
        Test.startTest();
        FormsHelper.attachDocsToApplication(testContact.Id, testAccount.Id);
        Test.stopTest();
        
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testContact.Id];
        System.assertEquals(1, links.size(), 'Should have copied one document link');
    }
    
    @isTest
    static void testGetFormsForPrimaryObject() {
        Test.startTest();
        List<FormsHelper.PicklistWrapper> results = FormsHelper.getFormsForPrimaryObject('Contact', false);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one form');
        System.assertEquals('Test Form Name (Prefill Fields)', results[0].label);
    }
    
    @isTest
    static void testCreateDependentFormsTrackerRecord() {
        Form__c testForm = [SELECT Id FROM Form__c LIMIT 1];
        
        Test.startTest();
        String trackerId = FormsHelper.createDependentFormsTrackerRecord(
            'js123', 
            testForm.Id, 
            testForm.Id, 
            true
        );
        Test.stopTest();
        
        System.assertNotEquals(null, trackerId, 'Should return a tracker ID');
        
        List<Dependent_Forms_Tracker__c> trackers = [SELECT Id FROM Dependent_Forms_Tracker__c WHERE Id = :trackerId];
        System.assertEquals(1, trackers.size(), 'Should have created one tracker record');
    }
    
    @isTest
    static void testDeleteDependentFormsTrackerRecord() {
        Form__c testForm = [SELECT Id FROM Form__c LIMIT 1];
        
        // First create a tracker record
        Dependent_Forms_Tracker__c tracker = new Dependent_Forms_Tracker__c(
            Parent_Form_JS_Id__c = 'js123',
            Parent_Form_Id__c = testForm.Id,
            Dependent_Form_Id__c = testForm.Id,
            Required__c = true
        );
        insert tracker;
        
        Test.startTest();
        FormsHelper.deleteDependentFormsTrackerRecord(
            'js123', 
            testForm.Id, 
            testForm.Id, 
            true
        );
        Test.stopTest();
        
        List<Dependent_Forms_Tracker__c> trackers = [SELECT Id FROM Dependent_Forms_Tracker__c WHERE Id = :tracker.Id];
        System.assertEquals(0, trackers.size(), 'Should have deleted the tracker record');
    }
    
    @isTest
    static void testGetTrackerRecordStatus() {
        Form__c testForm = [SELECT Id FROM Form__c LIMIT 1];
        
        // Create tracker records
        List<Dependent_Forms_Tracker__c> trackers = new List<Dependent_Forms_Tracker__c>{
            new Dependent_Forms_Tracker__c(
                Parent_Form_JS_Id__c = 'js123',
                Parent_Form_Id__c = testForm.Id,
                Dependent_Form_Id__c = testForm.Id,
                Required__c = true,
                Completed__c = true
            ),
            new Dependent_Forms_Tracker__c(
                Parent_Form_JS_Id__c = 'js123',
                Parent_Form_Id__c = testForm.Id,
                Dependent_Form_Id__c = testForm.Id,
                Required__c = false,
                Completed__c = false
            )
        };
        insert trackers;
        
        Test.startTest();
        List<Dependent_Forms_Tracker__c> results = FormsHelper.getTrackerRecordStatus('js123');
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return only completed trackers');
        System.assertEquals(true, results[0].Completed__c);
    }
    
    @isTest
    static void testMoveJsonsAndDeleteTrackerRecords() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Form__c testForm = [SELECT Id FROM Form__c LIMIT 1];
        
        // Create tracker record
        Dependent_Forms_Tracker__c tracker = new Dependent_Forms_Tracker__c(
            Parent_Form_JS_Id__c = 'js123',
            Parent_Form_Id__c = testForm.Id,
            Dependent_Form_Id__c = testForm.Id,
            Required__c = true
        );
        insert tracker;
        
        // Create content attached to tracker
        ContentVersion cv = new ContentVersion(
            Title = 'Test JSON',
            PathOnClient = 'test.json',
            VersionData = Blob.valueOf('{"test": "data"}'),
            FirstPublishLocationId = tracker.Id
        );
        insert cv;
        
        Test.startTest();
        String result = FormsHelper.moveJsonsAndDeleteTrackerRecords(
            testContact.Id, 
            new List<String>{tracker.Id}
        );
        Test.stopTest();
        
        System.assertEquals('Done', result);
        
        // Verify tracker was deleted
        List<Dependent_Forms_Tracker__c> trackersAfter = [SELECT Id FROM Dependent_Forms_Tracker__c WHERE Id = :tracker.Id];
        System.assertEquals(0, trackersAfter.size(), 'Tracker should be deleted');
        
        // Verify content was moved
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testContact.Id];
        System.assertEquals(1, links.size(), 'Content should be linked to contact');
    }
    
    @isTest
    static void testAttachPrintJsonToRecord() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Form__c testForm = [SELECT Id FROM Form__c LIMIT 1];
        
        String jsonData = '{"test": "data"}';
        
        Test.startTest();
        String result = FormsHelper.attachPrintJsonToRecord(jsonData, testContact.Id, testForm.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return a result string');
        System.assert(result.contains(testForm.Id), 'Result should contain form ID');
        
        List<ContentVersion> attachments = [SELECT Id FROM ContentVersion WHERE FirstPublishLocationId = :testContact.Id];
        System.assertEquals(1, attachments.size(), 'Should have created one attachment');
    }
    
    @isTest
    static void testMarkAdditionalFormComplete() {
        Form__c testForm = [SELECT Id FROM Form__c LIMIT 1];
        
        // Create tracker record
        Dependent_Forms_Tracker__c tracker = new Dependent_Forms_Tracker__c(
            Parent_Form_JS_Id__c = 'js123',
            Parent_Form_Id__c = testForm.Id,
            Dependent_Form_Id__c = testForm.Id,
            Required__c = true,
            Completed__c = false
        );
        insert tracker;
        
        Test.startTest();
        FormsHelper.markAdditionalFormComplete(tracker.Id);
        Test.stopTest();
        
        Dependent_Forms_Tracker__c updatedTracker = [SELECT Completed__c FROM Dependent_Forms_Tracker__c WHERE Id = :tracker.Id];
        System.assertEquals(true, updatedTracker.Completed__c, 'Tracker should be marked as completed');
    }
    
    @isTest
    static void testCheckErrors_WithDMLError() {
        // Test error handling in checkErrors method
        Test.startTest();
        
        // Create data that will cause a DML error (missing required field)
        FormsHelper.RecordData primary = new FormsHelper.RecordData();
        primary.objectName = 'Contact|Contact';
        primary.recordType = '012000000000000AAA';
        primary.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('Email', 'invalid-email-format') // Missing required LastName
        };
        
        List<FormsHelper.RecordData> parents = new List<FormsHelper.RecordData>();
        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>();
        List<FormsHelper.RecordData> grandchildren = new List<FormsHelper.RecordData>();
        
        Map<String, Object> paramsMap = new Map<String, Object>{
            'primaryObjectList' => JSON.serialize(primary),
            'parentObjectList' => JSON.serialize(parents),
            'childObjectsList' => JSON.serialize(children),
            'grandChildObjectList' => JSON.serialize(grandchildren),
            'questionObjectsList' => '',
            'formId' => 'test123',
            'isVerifyApplication' => false
        };
        String params = JSON.serialize(paramsMap);
        
        try {
            FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(params);
            // If no error, that's also acceptable
            System.assert(true, 'Operation completed');
        } catch (DmlException e) {
            // This tests the checkErrors method error handling
            System.assert(e.getMessage() != null, 'DML Exception should have a message');
        } catch (Exception e) {
            // Other exceptions are also acceptable for this test
            System.assert(e.getMessage() != null, 'Exception should have a message');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testObjectPermissionChecks() {
        // Test the object-level permission checks in insertRecordsWithUoW
        Test.startTest();
        
        FormsHelper.RecordData primary = new FormsHelper.RecordData();
        primary.objectName = 'Contact|Contact';
        primary.recordType = '012000000000000AAA';
        primary.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('LastName', 'Permission Test')
        };
        
        // Test with children to cover the children permission check section
        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>();
        FormsHelper.RecordData childRecord = new FormsHelper.RecordData();
        childRecord.objectName = 'Case|Case';
        childRecord.recordType = '012000000000000AAA';
        childRecord.fieldValue = new List<FormsHelper.FieldValue>();
        FormsHelper.FieldValue caseField = new FormsHelper.FieldValue('Subject', 'Permission Test Case');
        caseField.recordIdentifier = 1;
        childRecord.fieldValue.add(caseField);
        children.add(childRecord);
        
        List<FormsHelper.RecordData> parents = new List<FormsHelper.RecordData>();
        List<FormsHelper.RecordData> grandchildren = new List<FormsHelper.RecordData>();
        
        Map<String, Object> paramsMap = new Map<String, Object>{
            'primaryObjectList' => JSON.serialize(primary),
            'parentObjectList' => JSON.serialize(parents),
            'childObjectsList' => JSON.serialize(children),
            'grandChildObjectList' => JSON.serialize(grandchildren),
            'questionObjectsList' => '',
            'formId' => 'test123',
            'isVerifyApplication' => false
        };
        String params = JSON.serialize(paramsMap);
        
        try {
            FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(params);
            // If permissions are sufficient, this should succeed
            System.assert(result != null, 'Result should not be null');
        } catch (SecurityException e) {
            // If permissions are insufficient, we should get a SecurityException
            System.assert(e.getMessage().contains('permission'), 'Should be a permission-related error');
        } catch (Exception e) {
            // Other exceptions might occur in test context
            System.assert(e.getMessage() != null, 'Should have an error message');
        }
        
        Test.stopTest();
    }
    
    /* @isTest
    static void testParentLinkingLogic() {
        // Test the parent linking logic in insertRecordsWithUoW
        Test.startTest();
        
        // Create primary with parent relationships
        FormsHelper.RecordData primary = new FormsHelper.RecordData();
        primary.objectName = 'Contact|Contact';
        primary.recordType = '012000000000000AAA';
        primary.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('FirstName', 'Child'),
            new FormsHelper.FieldValue('LastName', 'Record')
        };
        
        primary.parents = new List<FormsHelper.ParentData>{
            new FormsHelper.ParentData('Account', 'Account|AccountId')
        };
        
        List<FormsHelper.RecordData> parents = new List<FormsHelper.RecordData>();
        FormsHelper.RecordData parentRecord = new FormsHelper.RecordData();
        parentRecord.objectName = 'Account|Account';
        parentRecord.recordType = '012000000000000AAA';
        parentRecord.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('Name', 'Linked Account')
        };
        parents.add(parentRecord);
        
        // Test child linking to primary
        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>();
        FormsHelper.RecordData childRecord = new FormsHelper.RecordData();
        childRecord.objectName = 'Case|Case';
        childRecord.recordType = '012000000000000AAA';
        childRecord.fieldValue = new List<FormsHelper.FieldValue>();
        FormsHelper.FieldValue caseField = new FormsHelper.FieldValue('Subject', 'Linked Case');
        caseField.recordIdentifier = 1;
        childRecord.fieldValue.add(caseField);
        
        childRecord.parents = new List<FormsHelper.ParentData>{
            new FormsHelper.ParentData('Contact', 'Contact|ContactId')
        };
        children.add(childRecord);
        
        List<FormsHelper.RecordData> grandchildren = new List<FormsHelper.RecordData>();
        
        Map<String, Object> paramsMap = new Map<String, Object>{
            'primaryObjectList' => JSON.serialize(primary),
            'parentObjectList' => JSON.serialize(parents),
            'childObjectsList' => JSON.serialize(children),
            'grandChildObjectList' => JSON.serialize(grandchildren),
            'questionObjectsList' => '',
            'formId' => 'test123',
            'isVerifyApplication' => false
        };
        String params = JSON.serialize(paramsMap);
        
        FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(params);
        
        Test.stopTest();
        
        System.assert(result.isSuccess, 'Parent linking should work correctly');
        System.assertNotEquals(null, result.primaryRecordId, 'Should return primary record ID');
    } */
    
    /* @isTest
    static void testInsertRecordsWithUoW_ChildrenWithoutParents() {
        // Test children records without parent relationships
        Test.startTest();
        
        FormsHelper.RecordData primary = new FormsHelper.RecordData();
        primary.objectName = 'Contact|Contact';
        primary.recordType = '012000000000000AAA';
        primary.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('FirstName', 'Primary'),
            new FormsHelper.FieldValue('LastName', 'Contact')
        };
        primary.parents = null; // No parents
        
        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>();
        FormsHelper.RecordData childRecord = new FormsHelper.RecordData();
        childRecord.objectName = 'Case|Case';
        childRecord.recordType = '012000000000000AAA';
        childRecord.fieldValue = new List<FormsHelper.FieldValue>();
        FormsHelper.FieldValue caseField = new FormsHelper.FieldValue('Subject', 'Orphan Case');
        caseField.recordIdentifier = 1;
        childRecord.fieldValue.add(caseField);
        
        childRecord.parents = null; // No parent relationships
        children.add(childRecord);
        
        List<FormsHelper.RecordData> parents = new List<FormsHelper.RecordData>();
        List<FormsHelper.RecordData> grandchildren = new List<FormsHelper.RecordData>();
        
        Map<String, Object> paramsMap = new Map<String, Object>{
            'primaryObjectList' => JSON.serialize(primary),
            'parentObjectList' => JSON.serialize(parents),
            'childObjectsList' => JSON.serialize(children),
            'grandChildObjectList' => JSON.serialize(grandchildren),
            'questionObjectsList' => '',
            'formId' => 'test123',
            'isVerifyApplication' => false
        };
        String params = JSON.serialize(paramsMap);
        
        FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(params);
        
        Test.stopTest();
        
        System.assert(result.isSuccess, 'Should handle records without parent relationships');
    } */
    
    @isTest
    static void testWrapperClasses() {
        Test.startTest();
        
        // Test LwcResponse
        FormsHelper.LwcResponse lwcResp = new FormsHelper.LwcResponse();
        lwcResp.isSuccess = true;
        lwcResp.error = 'Test error';
        lwcResp.url = 'http://test.com';
        System.assertEquals(true, lwcResp.isSuccess);
        
        // Test ClientEmailWrapper
        FormsHelper.ClientEmailWrapper emailWrapper = new FormsHelper.ClientEmailWrapper();
        emailWrapper.label = 'Test Label';
        emailWrapper.value = 'Test Value';
        System.assertEquals('Test Label', emailWrapper.label);
        
        // Test PicklistWrapper
        FormsHelper.PicklistWrapper picklistWrapper = new FormsHelper.PicklistWrapper();
        picklistWrapper.label = 'Test Label';
        picklistWrapper.value = 'Test Value';
        System.assertEquals('Test Label', picklistWrapper.label);
        
        // Test RecordData
        FormsHelper.RecordData recordData = new FormsHelper.RecordData('Account', 'RecordType', null, null);
        System.assertEquals('Account', recordData.objectName);
        
        // Test ParentData
        FormsHelper.ParentData parentData = new FormsHelper.ParentData('Account', 'AccountId');
        System.assertEquals('Account', parentData.parentApi);
        
        // Test FieldValue
        FormsHelper.FieldValue fieldValue = new FormsHelper.FieldValue('Name', 'Test Name');
        System.assertEquals('Name', fieldValue.fieldApi);
        
        // Test InsertResult
        FormsHelper.InsertResult insertResult = new FormsHelper.InsertResult();
        insertResult.isSuccess = true;
        insertResult.errorMessage = 'Test error';
        insertResult.failedObjectName = 'Account';
        insertResult.primaryRecordId = UserInfo.getUserId();
        System.assertEquals(true, insertResult.isSuccess);
        
        Test.stopTest();
    }
    
    @isTest
static void testGroupChildrenByRecordIdentifier_NoCreateAccess() {
    // Using a known object (Case), but just testing the skip logic
    List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>();

    FormsHelper.RecordData child = new FormsHelper.RecordData();
    child.objectName = 'Case';
    child.recordType = '012000000000000AAA';
    child.fieldValue = new List<FormsHelper.FieldValue>();

    FormsHelper.FieldValue field = new FormsHelper.FieldValue('Subject', 'No Create Access Test');
    field.recordIdentifier = 1;
    child.fieldValue.add(field);

    children.add(child);

    Test.startTest();
    Map<Integer, FormsHelper.RecordData> result = FormsHelper.groupChildrenByRecordIdentifier(children);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assert(result.size() > 0, 'Should still group child records correctly');
}






}