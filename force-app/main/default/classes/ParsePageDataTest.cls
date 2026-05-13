@IsTest
private class ParsePageDataTest {
    @IsTest
    static void parse_populatesSectionsAndFields() {
        String json =
            '{"pageData":[{"pageIndex":1,"pageName":"P1","sections":[{"sectionIndex":0,' +
            '"sectionName":"S1","columns":2,"isSectionMulti":true,"fields":[{"recordIndex":0,' +
            '"recordFields":[{"fieldIndex":0,"fieldName":"Name","inputValue":"x","content":"","isField":true,' +
            '"isRichTextBox":false}]}]}]}]}';

        Test.startTest();
        ParsePageData parsed = ParsePageData.parse(json);
        Test.stopTest();

        System.assertEquals(1, parsed.pageData.size());
        System.assertEquals(2, parsed.pageData[0].sections[0].columns);
        System.assertEquals(true, parsed.pageData[0].sections[0].isSectionMulti);
    }
}