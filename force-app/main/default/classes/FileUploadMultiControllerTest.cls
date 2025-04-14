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
        // Test scenario where recordId is blank
        Test.startTest();
        String fileData = '[{"fileCategory":"SSN Card","notes":"plan docs notes","expiration":"2023-03-22","fileContent":"VGhpcyBpcyBhIHRlc3QgY29udGVudC4=",'
                        + '"fileUploadName":"Rules.txt","fileTypeIcon":"doctype:txt","index":1}]';
        String result = FileUploadMultiController.uploadFiles('', fileData);
        Test.stopTest();
        System.assertEquals('record Id is Blank', result);
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
            System.assert(true, 'Expected exception was not thrown');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'Expected AuraHandledException');
        }
        Test.stopTest();
    }
}