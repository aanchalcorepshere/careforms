// Controller that saves a signature image as a file and links it to a given record via ContentDocumentLink.
public with sharing class SignatureController {

    // Saves a base64-encoded signature image to Salesforce and links it to the given record ID.
    @AuraEnabled
    public static void saveSignature(String signElement, String recId, String signatureTitle) {
        // Input validation (Critical/High fix)
        if (String.isBlank(signElement) || String.isBlank(recId) || String.isBlank(signatureTitle)) {
            throw new AuraHandledException('Required parameters are missing');
        }
        
        // Validate base64 format (High fix)
        try {
            EncodingUtil.base64Decode(signElement);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid signature data format');
        }
        
        // Validate record ID format and prevent SOQL injection (Critical fix)
        Id recordId;
        try {
            recordId = Id.valueOf(recId);
            // Additional security check - verify object is accessible
            if (!recordId.getSObjectType().getDescribe().isAccessible()) {
                throw new AuraHandledException('Insufficient permissions for the target record');
            }
        } catch (Exception e) {
            throw new AuraHandledException('Invalid record ID format or insufficient permissions');
        }
        
        // Sanitize signature title to prevent potential issues (High fix)
        signatureTitle = String.escapeSingleQuotes(signatureTitle).left(80);
        
        // Error handling wrapper (High fix)
        try {
            System.debug(LoggingLevel.Error ,'signElement --> ' + signElement);
            System.debug(LoggingLevel.Error ,'recId --> ' + recId);

            ContentVersion cVersion = new ContentVersion();
            cVersion.ContentLocation = 'S'; // 'S' = Document is stored in Salesforce
            cVersion.PathOnClient = signatureTitle + '_Signature.png'; // File name
            cVersion.Origin = 'H'; // 'H' = Chatter origin
            cVersion.Title = signatureTitle + '_Signature-' + recId + '-' + System.now() + '.png'; // File title
            cVersion.VersionData = EncodingUtil.base64Decode(signElement); // Decode base64 to binary
            cVersion.caresp__Upload_Date__c = System.today(); // Custom field for upload date

            // Check permissions for both objects (High fix)
            if (!Schema.sObjectType.ContentVersion.isCreateable() || 
                !Schema.sObjectType.ContentDocumentLink.isCreateable()) {
                throw new AuraHandledException('Insufficient permissions to create files');
            }

            // Use consistent security model (High fix)
            Database.insert(cVersion, AccessLevel.USER_MODE);

            // Get the ContentDocumentId for the uploaded file using user-mode enforcement
            Id conDocument = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :cVersion.Id 
                WITH USER_MODE
            ].ContentDocumentId;

            // Create and insert a ContentDocumentLink to share the file with the related record
            ContentDocumentLink cDocLink = new ContentDocumentLink();
            cDocLink.ContentDocumentId = conDocument;
            cDocLink.LinkedEntityId = recordId; // Use validated ID
            cDocLink.ShareType = 'I'; // Inferred permission
            cDocLink.Visibility = 'AllUsers';

            // Enforce field-level security before insert
            cDocLink = (ContentDocumentLink)(Security.stripInaccessible(
                AccessType.CREATABLE, 
                new List<ContentDocumentLink>{cDocLink}
            ).getRecords())[0];

            // Use consistent security model (High fix)
            Database.insert(cDocLink, AccessLevel.USER_MODE);
            
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'DML Error: ' + e.getMessage());
            throw new AuraHandledException('Failed to save signature: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unexpected error: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred while saving the signature');
        }
    }
}