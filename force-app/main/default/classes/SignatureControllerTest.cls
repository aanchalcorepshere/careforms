@isTest
private class SignatureControllerTest {
    @isTest static void testSaveSignature() {
        Question_Bank__c questionBank = testFactory.createQuestionBank('Demo question bank', null, true);
        String testImageData = 'testData';
        String signatureTitle = 'DemoSignatureTitle';
        Test.startTest();
        SignatureController.saveSignature(testImageData, questionBank.Id, signatureTitle);
        Test.stopTest();
        Integer contentVersionCount = [SELECT COUNT() FROM ContentVersion];
        System.assertEquals(1, contentVersionCount);
        Integer contentDocLinkCount = [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :questionBank.Id];
        System.assertEquals(1, contentDocLinkCount);
    }
}