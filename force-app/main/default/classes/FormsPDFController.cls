public with sharing class FormsPDFController {
    public String jsonString {get;set;}
    public List<ParsePageData.PageData> pageDataFromLwc {get;set;}
    public String theString {get;set;}
    public Integer pageLength {get;set;}

    public FormsPDFController() {
        
        String title = (string)System.currentPageReference().getParameters().get('theTitle');
        //String title = UserInfo.getUserId()+'_a0z5e000001ujBEAAY';
        Blob jsonData = [select Id, Title, VersionData from ContentVersion  where Title =: title AND IsLatest = true WITH SECURITY_ENFORCED limit 1].VersionData;
        this.pageDataFromLwc = ParsePageData.parse(jsonData.toString()).pageData;
        this.theString = String.valueOf(this.pageDataFromLwc);
        System.debug('this.pageName >> '+this.pageDataFromLwc[0].pageName);
        System.debug('this.theString >> '+this.theString);
    }
}