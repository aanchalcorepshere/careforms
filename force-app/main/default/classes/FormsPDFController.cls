// This controller class is used to fetch and parse PDF form data from a ContentVersion record,
// and store it in properties for further use in Visualforce or LWC components.
public with sharing class FormsPDFController {

    public String jsonString {get;set;}
    public List<ParsePageData.PageData> pageDataFromLwc {get;set;}
    public String theString {get;set;}
    public Integer pageLength {get;set;}

    // Constructor that retrieves ContentVersion data based on a title parameter, parses it into page data,
    // and initializes relevant properties.
    public FormsPDFController() {
        
        String title = (string)System.currentPageReference().getParameters().get('theTitle');
        //String title = UserInfo.getUserId()+'_a0z5e000001ujBEAAY';
        Blob jsonData = [select Id, Title, VersionData from ContentVersion  where Title =: title AND IsLatest = true WITH SECURITY_ENFORCED limit 1].VersionData;
        this.pageDataFromLwc = ParsePageData.parse(jsonData.toString()).pageData;
        this.theString = String.valueOf(this.pageDataFromLwc);
        System.debug(LoggingLevel.Error ,'this.pageName >> '+this.pageDataFromLwc[0].pageName);
        System.debug(LoggingLevel.Error ,'this.theString >> '+this.theString);
    }
}