@isTest
private class FileUploadMultiControllerTest {
    @isTest static void testUploadFilesSuccess() {
        // Test the success scenario with valid data
        Test.startTest();
        Question_Bank__c questionBank = TestFactory.createQuestionBank('Demo question bank', null, true);
        String fileData = '[{"fileCategory":"SSN Card","notes":"plan docs notes","expiration":"2023-03-22","fileContent":"VGhpcyBpcyBhIHRlc3QgY29udGVudC4=",'
                        + '"fileUploadName":"Rules.txt","fileTypeIcon":"doctype:txt","index":1}]';
        String result = FileUploadMultiController.uploadFiles(questionBank.Id, fileData);
        Test.stopTest();
        System.assertEquals('success', result);
    }

    @isTest static void testUploadFilesBlankRecordId() {
        // Test scenario where recordId is blank - should throw exception
        Test.startTest();
        String fileData = '[{"fileCategory":"SSN Card","notes":"plan docs notes","expiration":"2023-03-22","fileContent":"VGhpcyBpcyBhIHRlc3QgY29udGVudC4=",'
                        + '"fileUploadName":"Rules.txt","fileTypeIcon":"doctype:txt","index":1}]';
        try {
            String result = FileUploadMultiController.uploadFiles('', fileData);
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected record ID validation message');
        }
        Test.stopTest();
    }

    @isTest static void testUploadFilesInvalidFileData() {
        // Test scenario where fileData is invalid JSON
        Test.startTest();
        Question_Bank__c questionBank = TestFactory.createQuestionBank('Demo question bank', null, true);
        String fileData = 'invalid json data';
        try {
            FileUploadMultiController.uploadFiles(questionBank.Id, fileData);
            System.assert(false, 'Expected exception was not thrown');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'Expected AuraHandledException');
        }
        Test.stopTest();
    }

    @isTest static void testUploadFilesMissingRequiredFields() {
        // Test scenario where required fields are missing
        Test.startTest();
        Question_Bank__c questionBank = TestFactory.createQuestionBank('Demo question bank', null, true);
        String fileData = '[{"fileCategory":"SSN Card","notes":"plan docs notes","fileContent":"VGhpcyBpcyBhIHRlc3QgY29udGVudC4=",'
                        + '"fileUploadName":"Rules.txt"}]'; // Missing expiration
        String result = FileUploadMultiController.uploadFiles(questionBank.Id, fileData);
        Test.stopTest();
        System.assertEquals('success', result); // Ensures optional fields don't break logic
    }

    @isTest static void testUploadFilesExceptionHandling() {
        // Test exception handling with invalid recordId
        Test.startTest();
        String fileData = '[{"fileCategory":"SSN Card","notes":"plan docs notes","expiration":"2023-03-22","fileContent":"VGhpcyBpcyBhIHRlc3QgY29udGVudC4=",'
                        + '"fileUploadName":"Rules.txt","fileTypeIcon":"doctype:txt","index":1}]';
        try {
            FileUploadMultiController.uploadFiles(null, fileData); // Null recordId to force exception
            System.assert(false, 'Expected exception was not thrown');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'Expected AuraHandledException');
        }
        Test.stopTest();
    }

    @isTest
    static void testUploadFiles_additionalValidationPaths() {
        Question_Bank__c qb = TestFactory.createQuestionBank('QB validation', null, true);
        String validFile =
            '[{"fileCategory":"Cat","notes":"n","expiration":"2030-01-01","fileContent":"VGhpcyBpcyBhIHRlc3QgY29udGVudC4=",'
            + '"fileUploadName":"Doc.txt","fileTypeIcon":"doctype:txt","index":1}]';

        Boolean invalidIdFormatFailed = false;
        try {
            FileUploadMultiController.uploadFiles('001XXXXXXXXXXXXXXX', validFile);
        } catch (AuraHandledException e) {
            invalidIdFormatFailed = true;
        }

        Boolean emptyFileListFailed = false;
        try {
            FileUploadMultiController.uploadFiles(qb.Id, '[]');
        } catch (AuraHandledException e) {
            emptyFileListFailed = true;
        }

        Boolean badExtensionFailed = false;
        String badExt =
            '[{"fileCategory":"Cat","notes":"n","fileContent":"VGhpcyBpcyBhIHRlc3QgY29udGVudC4=",'
            + '"fileUploadName":"virus.exe"}]';
        try {
            FileUploadMultiController.uploadFiles(qb.Id, badExt);
        } catch (AuraHandledException e) {
            badExtensionFailed = true;
        }

        Boolean tooManyFailed = false;
        List<Map<String, Object>> many = new List<Map<String, Object>>();
        for (Integer i = 0; i < 101; i++) {
            many.add(
                new Map<String, Object>{
                    'fileCategory' => 'Cat',
                    'notes' => 'n',
                    'fileContent' => 'VGhpcyBpcyBhIHRlc3QgY29udGVudC4=',
                    'fileUploadName' => 'f' + i + '.txt'
                }
            );
        }
        try {
            FileUploadMultiController.uploadFiles(qb.Id, JSON.serialize(many));
        } catch (AuraHandledException e) {
            tooManyFailed = true;
        }

        System.assert(invalidIdFormatFailed && emptyFileListFailed && badExtensionFailed && tooManyFailed);
    }
}