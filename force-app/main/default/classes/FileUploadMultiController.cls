public with sharing class FileUploadMultiController {
    
    @AuraEnabled
    public static String uploadFiles(String recordId, String filedata) {
        try {
            if(String.isNotBlank(recordId)) {
                List<FileDataWP> files = (List<FileDataWP>) JSON.deserialize(filedata, List<FileDataWP>.class);
              //  System.debug(files);

                List<ContentVersion> cvList = new List<ContentVersion>();
                for(FileDataWP file : files) {
                    ContentVersion conVer = new ContentVersion();
                    conVer.ContentLocation = 'S'; // S = Salesforce, E = External Files
                    conVer.VersionData = EncodingUtil.base64Decode(file.fileContent);
                    conVer.Title = file.fileUploadName;
                    conVer.caresp__Master_PickList__c = file.masterPicklistName;
                    conVer.caresp__Document_Category__c = file.fileCategory;
                    conVer.caresp__Notes__c = file.notes;

                    if(String.isNotBlank(file.expiration)){
                        conVer.caresp__Expiration_Date__c = Date.valueOf(file.expiration);
                    }
                    conVer.caresp__Upload_Date__c = System.today();
                    conVer.Origin = 'H';//C-Content Origin. H-Chatter Origin.
                    conVer.PathOnClient = file.fileCategory+'.'+file.fileUploadName.substringAfter('.');
                    cvList.add(conVer);
                }
                 cvList = (List<ContentVersion>)Security.stripInaccessible(AccessType.CREATABLE, cvList).getRecords();
                 Insert as user cvList;
              //   System.debug('cvList: '+cvList);
                //Insert cvList;

                List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
                for(ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cvList WITH SECURITY_ENFORCED]) {
                    ContentDocumentLink conDocLink = New ContentDocumentLink();
                    conDocLink.LinkedEntityId = recordId;
                    conDocLink.ContentDocumentId = cv.ContentDocumentId;
                    conDocLink.Visibility = 'AllUsers';
                    conDocLink.shareType = 'V'; // V = Viewer, C = Collaborator, I = Inferred
                    cdList.add(conDocLink);
                }
                Insert Security.stripInaccessible(AccessType.CREATABLE, cdList).getRecords();
              //  System.debug('cdList: '+cdList);
                //Insert cdList;        
            } else {
                return 'record Id is Blank';
            }
            return 'success';
        } catch (Exception ex) {
          //  System.debug(ex.getMessage() + ' -> ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class FileDataWP {
        public String fileCategory;
        public String notes;
        public String fileContent;
        public String expiration;
        public String fileUploadName;
        public String fileTypeIcon;
        public Integer index;
        public String masterPicklistName;
    }
}