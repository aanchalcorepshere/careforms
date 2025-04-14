public with sharing class CustomLookupLwcController {
    // Method to fetch lookup search result   
     @AuraEnabled(cacheable=true)
     public static list<sObject> fetchLookupData(string searchKey , string sObjectApiName, string fieldname) {    
         List < sObject > returnList = new List < sObject > ();
 
         string sWildCardText = '%' + searchKey + '%';
         string sQuery = 'Select Id, '+ String.escapeSingleQuotes(fieldname) +' From ' + String.escapeSingleQuotes(sObjectApiName);
         for (sObject obj: database.query(sQuery)) {
             String s = (String)obj.get(fieldname);
             System.debug('s >> '+s);
             if(s.startsWithIgnoreCase(searchKey)){
                returnList.add(obj);
             }
         }
         System.debug('returnList >> '+returnList);
         return returnList;
     }
     
     // Method to fetch lookup default value 
     @AuraEnabled
     public static sObject fetchDefaultRecord(string recordId , string sObjectApiName, String fieldname) {
         string sRecId = recordId;    
         string sQuery = 'Select Id, '+ String.escapeSingleQuotes(fieldname) +' From ' + String.escapeSingleQuotes(sObjectApiName) + ' Where Id = : sRecId LIMIT 1';
         for (sObject obj: database.query(sQuery)) {
             return obj;
         }
         return null;
     }
     
 }