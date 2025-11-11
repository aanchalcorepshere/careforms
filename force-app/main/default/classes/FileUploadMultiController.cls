/**
 * @class FileUploadMultiController
 * @description This class handles the uploading of multiple files and linking them to a record.
 */
public with sharing class FileUploadMultiController {
    
    // Define allowed file extensions for security
    private static final Set<String> ALLOWED_FILE_EXTENSIONS = new Set<String>{
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'rtf',
        'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'svg'
    };
    
    // Define maximum file size (5MB in bytes)
    private static final Integer MAX_FILE_SIZE = 5 * 1024 * 1024;
    
    /**
     * @method uploadFiles
     * @description Uploads files to Salesforce, creates ContentVersion records, and links them to the specified record.
     */
    @AuraEnabled
    public static String uploadFiles(String recordId, String filedata) {
        // Input validation (Critical fix)
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Record ID cannot be null or empty');
        }
        
        if (String.isBlank(filedata)) {
            throw new AuraHandledException('File data cannot be null or empty');
        }
        
        // Validate record ID format (Critical fix)
        Id validatedRecordId;
        try {
            validatedRecordId = Id.valueOf(recordId);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid record ID format');
        }
        
        try {
            // Parse JSON with error handling
            List<FileDataWP> files;
            try {
                files = (List<FileDataWP>) JSON.deserialize(filedata, List<FileDataWP>.class);
            } catch (JSONException je) {
                throw new AuraHandledException('Invalid file data format: ' + je.getMessage());
            }
            
            if (files == null || files.isEmpty()) {
                throw new AuraHandledException('No files provided for upload');
            }
            
            // Validate file count (governor limit protection)
            if (files.size() > 100) {
                throw new AuraHandledException('Too many files. Maximum 100 files allowed per upload.');
            }

            List<ContentVersion> cvList = new List<ContentVersion>();
            
            for (FileDataWP file : files) {
                // Validate individual file data (Critical fix)
                validateFileData(file);
                
                ContentVersion conVer = new ContentVersion();
                conVer.ContentLocation = 'S'; // S = Salesforce, E = External Files
                
                // Safe base64 decoding with validation (Critical fix)
                Blob fileBlob;
                try {
                    fileBlob = EncodingUtil.base64Decode(file.fileContent);
                } catch (Exception be) {
                    throw new AuraHandledException('Invalid file content encoding for file: ' + file.fileUploadName);
                }
                
                // Validate file size (Critical fix)
                if (fileBlob.size() > MAX_FILE_SIZE) {
                    throw new AuraHandledException('File size too large for file: ' + file.fileUploadName + '. Maximum size is 5MB.');
                }
                
                if (fileBlob.size() == 0) {
                    throw new AuraHandledException('File is empty: ' + file.fileUploadName);
                }
                
                conVer.VersionData = fileBlob;
                conVer.Title = String.isNotBlank(file.fileUploadName) ? 
                    file.fileUploadName.left(255) : 'Untitled';
                conVer.caresp__Master_PickList__c = String.isNotBlank(file.masterPicklistName) ? 
                    file.masterPicklistName.left(255) : null;
                conVer.caresp__Document_Category__c = String.isNotBlank(file.fileCategory) ? 
                    file.fileCategory.left(255) : null;
                conVer.caresp__Notes__c = String.isNotBlank(file.notes) ? 
                    file.notes.left(32000) : null;

                // Safe date parsing (High fix)
                if (String.isNotBlank(file.expiration)) {
                    try {
                        conVer.caresp__Expiration_Date__c = Date.valueOf(file.expiration);
                    } catch (Exception de) {
                        throw new AuraHandledException('Invalid expiration date format for file: ' + file.fileUploadName);
                    }
                }
                
                conVer.caresp__Upload_Date__c = System.today();
                conVer.Origin = 'H'; // C-Content Origin. H-Chatter Origin.
                
                // Safe file extension handling
                String fileExtension = getFileExtension(file.fileUploadName);
                String pathOnClient = String.isNotBlank(file.fileCategory) ? 
                    file.fileCategory + '.' + fileExtension : 
                    file.fileUploadName;
                conVer.PathOnClient = pathOnClient.left(500);
                
                cvList.add(conVer);
            }
            
            // Consistent security model (High fix)
            List<ContentVersion> insertableVersions = Security.stripInaccessible(AccessType.CREATABLE, cvList).getRecords();
            if (!insertableVersions.isEmpty()) {
                Database.insert(insertableVersions, AccessLevel.USER_MODE);
            }

            // Create document links
            List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
            List<ContentVersion> insertedVersions = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id IN :insertableVersions 
                WITH USER_MODE
                LIMIT 10000
            ];
            
            for (ContentVersion cv : insertedVersions) {
                if (cv.ContentDocumentId != null) {
                    ContentDocumentLink conDocLink = new ContentDocumentLink();
                    conDocLink.LinkedEntityId = validatedRecordId;
                    conDocLink.ContentDocumentId = cv.ContentDocumentId;
                    conDocLink.Visibility = 'AllUsers';
                    conDocLink.shareType = 'V'; // V = Viewer, C = Collaborator, I = Inferred
                    cdList.add(conDocLink);
                }
            }
            
            if (!cdList.isEmpty()) {
                List<ContentDocumentLink> insertableLinks = Security.stripInaccessible(AccessType.CREATABLE, cdList).getRecords();
                Database.insert(insertableLinks, AccessLevel.USER_MODE);
            }
            
            return 'success';
            
        } catch (DmlException de) {
            System.debug(LoggingLevel.ERROR, 'DML error in uploadFiles: ' + de.getMessage());
            throw new AuraHandledException('Failed to upload files: ' + de.getDmlMessage(0));
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in uploadFiles: ' + ex.getMessage());
            throw new AuraHandledException('File upload failed: ' + ex.getMessage());
        }
    }
    
    /**
     * Validates individual file data for security and integrity
     */
    private static void validateFileData(FileDataWP file) {
        if (file == null) {
            throw new AuraHandledException('File data is null');
        }
        
        if (String.isBlank(file.fileContent)) {
            throw new AuraHandledException('File content is required');
        }
        
        if (String.isBlank(file.fileUploadName)) {
            throw new AuraHandledException('File name is required');
        }
        
        // Validate file extension (Critical security fix)
        String fileExtension = getFileExtension(file.fileUploadName);
        if (!ALLOWED_FILE_EXTENSIONS.contains(fileExtension.toLowerCase())) {
            throw new AuraHandledException('File type not allowed: ' + fileExtension + '. Allowed types: ' + String.join(new List<String>(ALLOWED_FILE_EXTENSIONS), ', '));
        }
        
        // Basic file name security validation
        if (file.fileUploadName.contains('..') || file.fileUploadName.contains('/') || file.fileUploadName.contains('\\')) {
            throw new AuraHandledException('Invalid file name: ' + file.fileUploadName);
        }
    }
    
    /**
     * Safely extracts file extension from filename
     */
    private static String getFileExtension(String filename) {
        if (String.isBlank(filename)) {
            return '';
        }
        
        if (filename.contains('.')) {
            return filename.substringAfterLast('.').toLowerCase();
        }
        
        return '';
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