@isTest
private class SignatureControllerTest {

    // Test method to verify signature saving functionality
    @isTest
    static void testSaveSignature() {
        // Create a test Question Bank record using a test factory
        Question_Bank__c questionBank = testFactory.createQuestionBank('Demo question bank', null, true);

        // Mock image data and title
        String testImageData = 'testData';
        String signatureTitle = 'DemoSignatureTitle';

        Test.startTest();
        // Call the method to save the signature
        SignatureController.saveSignature(testImageData, questionBank.Id, signatureTitle);
        Test.stopTest();

        // Verify that a ContentVersion was created
        Integer contentVersionCount = [SELECT COUNT() FROM ContentVersion];
        System.assertEquals(1, contentVersionCount, 'Expected one ContentVersion to be created');

        // Verify that a ContentDocumentLink links the document to the question bank
        Integer contentDocLinkCount = [
            SELECT COUNT() 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :questionBank.Id
        ];
        System.assertEquals(1, contentDocLinkCount, 'Expected one ContentDocumentLink to be created');
    }
}