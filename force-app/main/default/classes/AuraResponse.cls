public with sharing class AuraResponse {
    @AuraEnabled 
    public Boolean isSuccess{get; set;}
    @AuraEnabled 
    public String message{get; set;}
    @AuraEnabled 
    public String response{get; set;}
    @AuraEnabled 
    public String objectApiName{get; set;}
    @AuraEnabled 
    public SObject sObjectDetails{get; set;}
    //added by sg
    @AuraEnabled 
    public List<SObject> listSObjectDetails{get; set;}
    @AuraEnabled 
    public String fieldApiName{get; set;}
    @AuraEnabled 
    public String grandChildObjectApiName{get; set;}
    @AuraEnabled 
    public String childObjectApiName{get; set;}
    @AuraEnabled 
    public String primaryObjectApiName{get; set;}
    @AuraEnabled 
    public String parentObjectApiName{get; set;}
    
    public AuraResponse(Boolean isSuccess, String message, String response, String objectApiName, SObject sObjectDetails, String fieldApiName, String grandChildObjectApiName, String childObjectApiName, String primaryObjectApiName, String parentObjectApiName){
    //, List<SObject> listSObjectDetails) {
        this.isSuccess = isSuccess;
        this.message   = message;
        this.response  = response;
        this.objectApiName  = objectApiName;
        this.sObjectDetails  = sObjectDetails;
        //added by sg
        this.listSObjectDetails = listSObjectDetails;
        this.fieldApiName  = fieldApiName;
        this.grandChildObjectApiName  = grandChildObjectApiName;
        this.childObjectApiName  = childObjectApiName;
        this.primaryObjectApiName  = primaryObjectApiName;
        this.parentObjectApiName  = parentObjectApiName;
    }
}