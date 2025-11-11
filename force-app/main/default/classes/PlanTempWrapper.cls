// Wrapper class used to represent a plan template structure,
// including its name, associated sections, and configuration settings.
public with sharing class PlanTempWrapper {

    @AuraEnabled
    Public String templateName {get; set;}
    
    @AuraEnabled 
    Public List<SectionInformation> sectionInformations {get; set;}
    
    @AuraEnabled
    Public String parentDateField {get; set;}
    
    @AuraEnabled
    Public Decimal noOfDaysToAdd {get; set;}
    
    // Inner class to hold section-specific information, including fields and section name.
    Public Class SectionInformation {
        @AuraEnabled Public String sectionName {get; set;}
        @AuraEnabled Public List<PicklistWrapper> fieldBlueprints {get; set;}
    }

    // Inner class to define the structure of individual picklist or field data,
    // including metadata like type, default value, and editability.
    Public class PicklistWrapper {
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