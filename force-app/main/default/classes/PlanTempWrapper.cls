public with sharing class PlanTempWrapper {
    @AuraEnabled
    Public String templateName {get; set;}
    @AuraEnabled 
    Public List<SectionInformation> sectionInformations {get; set;}
    @AuraEnabled
    Public String parentDateField {get; set;}
    @AuraEnabled
    Public Decimal noOfDaysToAdd {get; set;}
    
    
    
    
    
    
    Public Class SectionInformation 
    {
        @AuraEnabled Public String sectionName {get; set;}
        @AuraEnabled Public List<PicklistWrapper> fieldBlueprints {get; set;}
        
    }
    
    Public class PicklistWrapper 
    {
        @AuraEnabled Public String label  {get; set;}
        @AuraEnabled Public String value  {get; set;}
        @AuraEnabled Public String dataType  {get; set;}
        @AuraEnabled Public Boolean isMandatory  {get; set;}
        @AuraEnabled public Boolean isEditable  {get; set;}
        @AuraEnabled public Boolean isReadOnly  {get; set;}
        @AuraEnabled public String defaultValue  {get; set;}
        @AuraEnabled public Boolean isEditDisabled  {get; set;}
        @AuraEnabled public Boolean isReqDisabled  {get; set;}
        @AuraEnabled public Boolean isFormulaField {get; set;}
        
    }




    
}