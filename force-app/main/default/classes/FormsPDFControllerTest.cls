@isTest
private class FormsPDFControllerTest {
    @isTest static void testFormsPDFController() {
        Question_Bank__c qbTestData=testFactory.createQuestionBank('Test Question',null,true);
        Question__c quesTestData=testFactory.createQuestion(qbTestData.Id,null,'Radio Box',false);
        // Test data setup
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Content';
        cv.pathonclient='Test';
        cv.VersionData = Blob.valueOf('{"pageData": [{"name": "Test Page 1", "sections": [{"sectionIndex" : 1, "sectionName": "Test Field 1", "isSectionMulti": true, "fields": [{"recordIndex":1, "recordFields": [{"fieldIndex":0,"fieldName": "test1","inputValue": "'+qbTestData.Id+'","content":"test","isField": true,"isRichTextBox":false},{"fieldIndex":1,"fieldName": "test2","inputValue": "null","content":"test","isField": true,"isRichTextBox":false}]}]}]}, {"name": "Test Page 2", "fields": [{"label": "Test Field 2", "value": "Test Value 2"}]}]}');
        insert cv;

        // Test the constructor
        Test.setCurrentPageReference(new PageReference('/apex/TestPage?theTitle=Test Content'));
        FormsPDFController controller = new FormsPDFController();
        List<ParsePageData.PageData> pageDataFromLwc = controller.pageDataFromLwc;
        system.assertNotEquals(0, pageDataFromLwc.size(), 'There should be one page data.');
        Integer pageLength = controller.pageLength;
        String theString = controller.theString;
        Integer pageIndex = pageDataFromLwc[0].pageIndex;
		String pageName = pageDataFromLwc[0].pageName;
		List<ParsePageData.Sections> sections = pageDataFromLwc[0].sections;
        Integer sectionIndex = sections[0].sectionIndex;
		String sectionName = sections[0].sectionName;
		Boolean isSectionMulti = sections[0].isSectionMulti;
		List<ParsePageData.Fields> fields = sections[0].fields;
         ParsePageData.Fields field = fields[0];
        System.assertEquals(1, field.recordIndex, 'Record index should be set correctly.');
        Integer recordIndex = fields[0].recordIndex;
		List<ParsePageData.RecordFields> recordFields = fields[0].recordFields;
        Integer fieldIndex = recordFields[0].fieldIndex;
		String fieldName = recordFields[0].fieldName;
		String inputValue = recordFields[0].inputValue;
		String content = recordFields[0].content;
		Boolean isField = recordFields[0].isField;
		Boolean isRichTextBox = recordFields[0].isRichTextBox;

    }
}