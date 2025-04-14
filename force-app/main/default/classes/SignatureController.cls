public with sharing class SignatureController {
    
    // Instance of the flow
    //public Flow.Interview.application flowObj{get; set;}

    /*public string getValueAppId(){
        return (String) flowObj.getVariableValue('AppiD');
    }*/
    @AuraEnabled
    public static void saveSignature(String signElement, String recId, String signatureTitle){
        //System.debug('AppiD'+(String) flowObj.getVariableValue('AppiD'));
        System.debug('signElement-->'+signElement);
        System.debug('recId-->'+recId);
        ContentVersion cVersion = new ContentVersion();
        cVersion.ContentLocation = 'S'; //S-Document is in Salesforce.
        cVersion.PathOnClient = signatureTitle+'_Signature' +'.png';//File name with extention
        cVersion.Origin = 'H';//C-Content Origin. H-Chatter Origin.
        cVersion.Title = signatureTitle+'_Signature-'+recId+'-'+System.now() +'.png';//Name of the file
        cVersion.VersionData = EncodingUtil.base64Decode(signElement);//File content
        cVersion.caresp__Upload_Date__c = System.today();//File upload date
        if (Schema.sObjectType.ContentVersion.isCreateable()) {// check added by sg
            
            Insert as user cVersion;
        }
        
        //Get the Uploaded doc ContentDocumentId
        Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id WITH SECURITY_ENFORCED].ContentDocumentId;
        
        //Insert ContentDocumentLink to share 
        ContentDocumentLink cDocLink = new ContentDocumentLink();
        cDocLink.ContentDocumentId = conDocument;
        cDocLink.LinkedEntityId = recId;
        cDocLink.ShareType = 'I';
        cDocLink.Visibility = 'AllUsers';
        cDocLink = (ContentDocumentLink)(Security.stripInaccessible(AccessType.CREATABLE, new List<ContentDocumentLink>{cDocLink}).getRecords())[0];
        Insert as user cDocLink;
    }
}