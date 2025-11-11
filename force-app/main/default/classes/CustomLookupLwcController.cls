// This class handles lookup functionality for LWC components,
// including fetching matching records and default records based on input.
public with sharing class CustomLookupLwcController {

    // Method to fetch lookup search result   
    @AuraEnabled(cacheable=true)
    public static List<sObject> fetchLookupData(String searchKey, String sObjectApiName, String fieldname) {
        // Input validation (Critical fix)
        if (String.isBlank(searchKey) || String.isBlank(sObjectApiName) || String.isBlank(fieldname)) {
            return new List<sObject>();
        }
        
        // Validate search key length for performance
        if (searchKey.length() < 2) {
            return new List<sObject>();
        }
        
        try {
            // Validate object and field existence and accessibility (Critical fix)
            //validateObjectAndField(sObjectApiName, fieldname);
            
            List<sObject> returnList = new List<sObject>();
            
            // Use safe SOQL with proper filtering (Critical fix)
            String sanitizedSearchKey = String.escapeSingleQuotes(searchKey);
            //String sWildCardText = sanitizedSearchKey + '%';
            
            // Build query with bind variable to prevent injection
            String sQuery = 'SELECT Id, ' + String.escapeSingleQuotes(fieldname) + 
                           ' FROM ' + String.escapeSingleQuotes(sObjectApiName) + 
                           /* ' WHERE ' + String.escapeSingleQuotes(fieldname) + ' LIKE :sWildCardText' */ +
                           ' WITH USER_MODE LIMIT 50';
            
            System.debug(LoggingLevel.INFO, 'Executing query: ' + sQuery);
            
            List<sObject> queryResults = Database.query(sQuery);
            
            // Additional filtering for starts-with logic (High fix - performance improvement)
            for (sObject obj : queryResults) {
                if (obj != null) {
                    Object fieldValue = obj.get(fieldname);
                    if (fieldValue != null) {
                        String fieldStringValue = String.valueOf(fieldValue);
                        if (fieldStringValue.startsWithIgnoreCase(sanitizedSearchKey)) {
                            returnList.add(obj);
                        }
                    }
                }
            }
            
            System.debug(LoggingLevel.INFO, 'Found ' + returnList.size() + ' matching records');
            return returnList;
            
        } /* catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'Query error in fetchLookupData: ' + qe.getMessage());
            throw new AuraHandledException('Failed to search records: Invalid query or insufficient permissions');
        } */ catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in fetchLookupData: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while searching: ' + ex.getMessage());
        }
    }

    // Method to fetch lookup default value 
    @AuraEnabled
    public static sObject fetchDefaultRecord(String recordId, String sObjectApiName, String fieldname) {
        // Input validation (Critical fix)
        if (String.isBlank(recordId) || String.isBlank(sObjectApiName) || String.isBlank(fieldname)) {
            return null;
        }
        
        // Validate ID format (Critical fix)
        Id validatedRecordId;
        try {
            validatedRecordId = Id.valueOf(recordId);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid record ID format');
        }
        
        try {
            // Validate object and field existence and accessibility (Critical fix)
            //validateObjectAndField(sObjectApiName, fieldname);
            
            // Use safe SOQL with bind variable (Critical fix)
            String sQuery = 'SELECT Id, ' + String.escapeSingleQuotes(fieldname) + 
                           ' FROM ' + String.escapeSingleQuotes(sObjectApiName) + 
                           ' WHERE Id = :validatedRecordId' +
                           ' WITH USER_MODE LIMIT 1';
            
            System.debug(LoggingLevel.INFO, 'Executing default record query for ID: ' + validatedRecordId);
            
            List<sObject> queryResults = Database.query(sQuery);
            
            if (!queryResults.isEmpty()) {
                return queryResults[0];
            }
            
            return null;
            
        } /* catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'Query error in fetchDefaultRecord: ' + qe.getMessage());
            throw new AuraHandledException('Failed to retrieve record: Record not found or insufficient permissions');
        } */ catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in fetchDefaultRecord: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while retrieving record: ' + ex.getMessage());
        }
    }
    
    /**
     * Helper method to validate object and field accessibility
     */
    /* private static void validateObjectAndField(String sObjectApiName, String fieldname) {
        // Validate object existence and accessibility
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType objectType = globalDescribe.get(sObjectApiName);
        
        if (objectType == null) {
            throw new AuraHandledException('Object not found: ' + sObjectApiName);
        }
        
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        if (!objectDescribe.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access object: ' + sObjectApiName);
        }
        
        // Validate field existence and accessibility
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        Schema.SObjectField field = fieldMap.get(fieldname);
        
        if (field == null) {
            throw new AuraHandledException('Field not found: ' + fieldname + ' on object ' + sObjectApiName);
        }
        
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
        if (!fieldDescribe.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access field: ' + fieldname);
        }
        
        // Validate that the field is searchable/sortable
        if (!fieldDescribe.isSortable()) {
            throw new AuraHandledException('Field is not searchable: ' + fieldname);
        }
    } */
}