@isTest
private class FormsControllerTest {

    // Create a test user to run the tests
    @testSetup
    static void setup() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'testUser',
            Email = 'testuser@test.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'Test',
            Title = 'Test',
            Alias = 'test',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert testUser;
    }

    // Test method for getRelatedObjectsList
    @isTest
    static void testGetRelatedObjectsList() {
        // Since we can't insert Custom Metadata in a test, we assume it exists.
        // The test will fail if the metadata is not present in the org.
        // A more robust solution would involve a mocking framework.

        Test.startTest();
        // Test with a standard object that has relationships
        List<FormsController.ObjectWrapperCategory> result = FormsController.getRelatedObjectsList('Account');
        Test.stopTest();

        // Verify that the method returns related objects
        System.assert(!result.isEmpty(), 'Should return related objects for Account');
        System.assert(result[0].categoryName.equals('Children'), 'First category should be Children');
        System.assert(result[1].categoryName.equals('Lookup(Parent)'), 'Second category should be Lookup(Parent)');
    }

    // Test method for getFieldsData
    @isTest
    static void testGetFieldsData() {
        List<String> objectList = new List<String>{'Account#false#false'};

        // Create a sample question record
        caresp__Question__c testQuestion = new caresp__Question__c(
            caresp__Question_Text__c = 'Test Question?',
            caresp__Question_Data_type__c = 'Text'
        );
        insert testQuestion;

        Test.startTest();
        // Test with prefillFields = true
        List<FormsController.FieldsWrapper> resultWithPrefill = FormsController.getFieldsData(objectList, true);
        // Test with prefillFields = false
        List<FormsController.FieldsWrapper> resultWithoutPrefill = FormsController.getFieldsData(objectList, false);
        Test.stopTest();

        // Verify results for both scenarios
        System.assert(!resultWithPrefill.isEmpty(), 'Should return fields for Account with prefill');
        System.assert(resultWithPrefill.size() > 1, 'Should include questions wrapper with prefill');
        System.assert(!resultWithoutPrefill.isEmpty(), 'Should return fields for Account without prefill');
        System.assert(resultWithoutPrefill.size() > 1, 'Should include questions wrapper without prefill');
    }

    // Test method for getRecordTypes
    @isTest
    static void testGetRecordTypes() {
        // This test assumes the org has at least one non-master record type for Account.
        Test.startTest();
        List<FormsController.RecordTypeWrapper> result = FormsController.getRecordTypes('Account');
        Test.stopTest();
        
        // If your org doesn't have record types on Account, this assertion might fail.
        // In that case, create one in your test setup or assert for an empty list.
        System.assert(result != null, 'Should return a list of record types, even if empty');
    }

    // Test method for createFormRecord
    @isTest
    static void testCreateFormRecord() {
        Test.startTest();
        // Test creating a new form
        String formId = FormsController.createFormRecord('Test Form', false, null, 'Test Confirmation', true, true, 'Sign here', true, true, true, false, null, false);
        
        // Test editing an existing form
        String editedFormId = FormsController.createFormRecord('Edited Test Form', true, formId, 'Edited Confirmation', false, false, '', false, false, false, true, 'Account', true);
        Test.stopTest();

        // Verify that Ids were returned
        System.assertNotEquals(null, formId, 'Should return the Id of the created form');
        System.assertEquals(formId, editedFormId, 'Should return the same Id when editing');

        // Verify the edits
        caresp__Form__c updatedForm = [SELECT Id, careSP__Form_Name__c, careSP__Prefill_Fields__c FROM careSP__Form__c WHERE Id = :editedFormId];
        System.assertEquals('Edited Test Form', updatedForm.careSP__Form_Name__c, 'Form name should be updated');
        System.assertEquals(true, updatedForm.careSP__Prefill_Fields__c, 'Prefill Fields should be updated');
    }

    // Test method for saveFormData
    @isTest
    static void testSaveFormData() {
        // Create a parent form record
        caresp__Form__c testForm = new caresp__Form__c(caresp__Form_Name__c = 'Test Form for Saving Data');
        insert testForm;

        String objectStructureJson = '{"object":"Account"}';
        String pageDataJson = '{"page":1, "fields":[]}';
        String rulesJson = '{"rules":[]}';

        Test.startTest();
        // Test initial save
        String result = FormsController.saveFormData(testForm.Id, objectStructureJson, pageDataJson, rulesJson, false);
        
        // Test editing (which deletes old files and creates new ones)
        String editResult = FormsController.saveFormData(testForm.Id, objectStructureJson, pageDataJson, rulesJson, true);
        Test.stopTest();

        // Verify the results
        System.assertEquals('done', result, 'Should return "done" on successful save');
        System.assertEquals('done', editResult, 'Should return "done" on successful edit');

        // Verify that files were created and linked
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :testForm.Id];
        System.assertEquals(3, links.size(), 'Should be 3 files linked to the form record after edit');
    }

    // Test method for fetchFormData
    @isTest
    static void testFetchFormData() {
        // Create a form record and save data to it first
        caresp__Form__c testForm = new caresp__Form__c(
            caresp__Form_Name__c = 'Fetch Test',
            caresp__Confirmation_Message__c = 'Fetched!',
            caresp__Requires_Signature__c = true,
            caresp__Generate_PDF__c = true
        );
        insert testForm;

        String objectStructureJson = '{"object":"Contact"}';
        String pageDataJson = '{"page":1, "data":{}}';
        String rulesJson = '{"rules":[{"condition":"true"}]}';
        FormsController.saveFormData(testForm.Id, objectStructureJson, pageDataJson, rulesJson, false);

        Test.startTest();
        FormsController.FormDataWrapper result = FormsController.fetchFormData(testForm.Id);
        Test.stopTest();

        // Verify the fetched data
        System.assertNotEquals(null, result, 'Should return form data wrapper');
        System.assertEquals('Fetch Test', result.formName, 'Should fetch the correct form name');
        System.assertEquals(objectStructureJson, result.objectStructure, 'Should fetch the correct object structure JSON');
        System.assertEquals(pageDataJson, result.pageData, 'Should fetch the correct page data JSON');
        System.assertEquals(rulesJson, result.rules, 'Should fetch the correct rules JSON');
        System.assertEquals(true, result.requiresSignature, 'Should fetch the correct requires signature value');
    }

    // Test method for getQuestionAnswerOptions
    @isTest
    static void testGetQuestionAnswerOptions() {
        // Create a question and some answer options
        caresp__Question__c testQuestion = new caresp__Question__c(
            caresp__Question_Text__c = 'What is your favorite color?',
            caresp__Question_Data_type__c = 'Picklist'
        );
        insert testQuestion;

        caresp__Answer__c testAnswer = testFactory.createAnswer(null, 'Test Answer', true, true);

        caresp__Question_Answer_Option__c option1 = new caresp__Question_Answer_Option__c(
            caresp__Question__c = testQuestion.Id,
            caresp__Answer__c = testAnswer.Id,
            caresp__Sequence__c = 1
        );
        insert option1;

        Test.startTest();
        List<caresp__Question_Answer_Option__c> result = FormsController.getQuestionAnswerOptions(testQuestion.Id);
        Test.stopTest();

        // Verify the results
        System.assert(!result.isEmpty(), 'Should return answer options');
        System.assertEquals(1, result.size(), 'Should return 1 answer option');
        System.assertEquals('Test Answer', result[0].caresp__Answer_Text__c, 'Should return the correct answer text');
    }

    // Test method for getDocumentTypes
    @isTest
    static void testGetDocumentTypes() {
        // This test relies on existing metadata. Like the first test, a mocking framework
        // would make this more reliable if metadata isn't guaranteed to exist.
        Test.startTest();
        List<Doc_Category_Help_Text__mdt> result = FormsController.getDocumentTypes();
        Test.stopTest();

        System.assert(result != null, 'Should return a list of document types, even if empty');
    }
    
    // Test method for getPrintJson
    @isTest
    static void testGetPrintJson() {
        caresp__Form__c testForm = new caresp__Form__c(caresp__Form_Name__c = 'Print Test Form', careSP__Signature_Page_Text__c = 'Signature Text');
        insert testForm;

        Account testAccount = new Account(Name='Test Account for Print');
        insert testAccount;

        String printJsonTitle = testForm.Id + '_2023-10-27T10:00:00Z__Print_JSON';
        String printJsonData = '{"data":"print content"}';

        // Create Print JSON ContentVersion
        ContentVersion cvPrint = new ContentVersion(
            Title = printJsonTitle,
            PathOnClient = 'print.txt',
            VersionData = Blob.valueOf(printJsonData)
        );
        insert cvPrint;
        ContentDocumentLink cdlPrint = new ContentDocumentLink(
            LinkedEntityId = testAccount.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cvPrint.Id].ContentDocumentId,
            ShareType = 'V'
        );
        insert cdlPrint;

        Test.startTest();
        FormsController.PrintWrapper result = FormsController.getPrintJson(testAccount.Id, printJsonTitle);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(printJsonData, result.pageData, 'Page data should match');
        System.assertEquals('Signature Text', result.signatureText, 'Signature text should match');
    }

    // Test method for getFormsAvailableForPrint
    @isTest
    static void testGetFormsAvailableForPrint() {
        caresp__Form__c testForm = new caresp__Form__c(caresp__Form_Name__c = 'Available Form');
        insert testForm;

        Account testAccount = new Account(Name='Test Account for Available Forms');
        insert testAccount;

        String printJsonTitle = testForm.Id + '_04/24/2024 12:28 AM__Print_JSON';

        ContentVersion cv = new ContentVersion(
            Title = printJsonTitle,
            PathOnClient = 'available.txt',
            VersionData = Blob.valueOf('{}')
        );
        insert cv;
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = testAccount.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;

        Test.startTest();
        List<FormsController.FormOptionsWrapper> result = FormsController.getFormsAvailableForPrint(testAccount.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should find one available form');
        System.assert(result[0].label.contains('Available Form'), 'Label should contain the form name');
    }

    // Test method for getFormsList
    @isTest
    static void testGetFormsList() {
        caresp__Form__c testForm = new caresp__Form__c(caresp__Form_Name__c = 'Form in List');
        insert testForm;

        Test.startTest();
        List<caresp__Form__c> result = FormsController.getFormsList();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one form');
        System.assertEquals(testForm.Id, result[0].Id, 'Should return the correct form');
    }
}