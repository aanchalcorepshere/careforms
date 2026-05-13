global without sharing class RequestSignatureForPlanController {
   /* public static Blob cryptoKey;
    public static Map<Id,String> encryptKey = new Map<Id,String>();
    public static string expMsg;

    @AuraEnabled
    public static String getPlanStatus(String planId) {
        try {
            return [SELECT Id, Plan_Status__c FROM Plan__c WHERE Id = :planId WITH SECURITY_ENFORCED].Plan_Status__c;
        } catch (Exception ex) {
            System.debug('Error in getPlanStatus: ' + ex.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static String getPlanData(String planId) {
        try {
            return [SELECT Id, Data_Json_for_Signature_Request__c FROM Plan__c WHERE Id = :planId WITH SECURITY_ENFORCED].Data_Json_for_Signature_Request__c;
        } catch (Exception ex) {
            System.debug('Error in getPlanData: ' + ex.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static LwcResponse createSignatureRequestURL(List<String> toEmailAddressList, String planId) {
        try {
            String encryptPlanId = processEncryption(planId);
            caresp__Dynamic_Plans_Custom_Settings__c dynamicPlansCustomSetting = caresp__Dynamic_Plans_Custom_Settings__c.getInstance();

            String requestSignatureSiteUrl = dynamicPlansCustomSetting.caresp__Signature_Request_Site_URL__c;
            String urlLink = requestSignatureSiteUrl + '?PlanId=' + encryptPlanId + '&linkCounter=1';

            String urlStringEnglish = '<a href="' + urlLink + '">Click here to review and sign the plan.</a>';
            String urlStringSpanish = '<a href="' + urlLink + '">Haga clic aqui para revisar y firmar el plan.</a>';

            return sendRequestSignatureEmail(urlLink, urlStringEnglish, urlStringSpanish, encryptPlanId, toEmailAddressList);
        } catch (Exception ex) {
            System.debug('Error in createSignatureRequestURL: ' + ex.getMessage());
            return new LwcResponse();
        }
    }

    public static LwcResponse sendRequestSignatureEmail(String urlLink, String urlStringEnglish, String urlStringSpanish, String planId, List<String> toEmailAddressList) {
        try {
            String decryptedPlanId = processDecryption(planId);
            LwcResponse resp = new LwcResponse();

            Plan__c planRec = [SELECT Id, Request_Signature_Link_Status__c FROM Plan__c WHERE Id = :decryptedPlanId WITH SECURITY_ENFORCED];
            if (planRec.Request_Signature_Link_Status__c == 'Signed') {
                resp.isSuccess = false;
                resp.error = 'Plan has already been signed. You cannot send another request.';
                return resp;
            } else {
                caresp__Dynamic_Plans_Custom_Settings__c dynamicPlansCustomSetting = caresp__Dynamic_Plans_Custom_Settings__c.getInstance();

                String requestSignatureEmailTemp = dynamicPlansCustomSetting.caresp__Signature_Email_Template_Name__c;
                EmailTemplate emailTemp = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName =: requestSignatureEmailTemp WITH SECURITY_ENFORCED LIMIT 1];
                String emailBody = emailTemp.Body.replace('#english_link#', '<br /><br />' + urlStringEnglish + '<br /><br />');

                List<Messaging.SingleEmailMessage> prepMailList = new List<Messaging.SingleEmailMessage>();
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setSubject(emailTemp.Subject);
                email.setHtmlBody(emailBody);

                if (!toEmailAddressList.isEmpty()) {
                    email.setToAddresses(toEmailAddressList);
                } else {
                    resp.isSuccess = false;
                    resp.error = 'The Client does not have a valid Email Address in their Client record. Update the Client record to proceed.';
                    return resp;
                }

                prepMailList.add(email);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(prepMailList);

                for (Messaging.SendEmailResult mr : results) {
                    if (mr.isSuccess()) {
                        resp.isSuccess = true;
                        resp.url = urlLink;
                    } else {
                        resp.isSuccess = false;
                        for (Messaging.SendEmailError err : mr.getErrors()) {
                            System.debug('SendEmailError: ' + err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
                return resp;
            }
        } catch (Exception ex) {
            System.debug('Error in sendRequestSignatureEmail: ' + ex.getMessage());
            System.debug('Stack Trace: ' + ex.getStackTraceString());

            return new LwcResponse();
        }
    }

    @AuraEnabled
    public static String updateRequestSignatureDetails(String planId, String urlString) {
        try {
            caresp__Dynamic_Plans_Custom_Settings__c settings = caresp__Dynamic_Plans_Custom_Settings__c.getInstance();
            String signatureLinkStatusSent = settings.caresp__Signature_Link_Status_Sent__c;
            caresp__Plan__c planRec = [SELECT Id, Request_Signature_Link_Status__c, Request_Signature_Counter__c, Request_Signature_Date__c, Request_Signature_URL__c FROM Plan__c WHERE Id = :planId WITH SECURITY_ENFORCED LIMIT 1 ];
            planRec.caresp__Request_Signature_Link_Status__c = signatureLinkStatusSent;
            planRec.caresp__Request_Signature_Counter__c = 1;
            planRec.caresp__Request_Signature_Date__c = System.now();
            planRec.caresp__Request_Signature_URL__c = urlString;

            Database.update(Security.stripInaccessible(AccessType.UPDATABLE, new List<caresp__Plan__c>{planRec}).getRecords(), true);
            return 'done';
        } catch (Exception ex) {
            System.debug('Error in updateRequestSignatureDetails: ' + ex.getMessage());
            return 'error';
        }
    }

    @AuraEnabled
    public static void markPlanSigned(String planId) {
        try {
            caresp__Dynamic_Plans_Custom_Settings__c settings = caresp__Dynamic_Plans_Custom_Settings__c.getInstance();
            String signatureLinkStatusSigned = settings.caresp__Signature_Link_Status_Signed__c;
            update as user (new caresp__Plan__c(Id = planId, caresp__Request_Signature_Link_Status__c = signatureLinkStatusSigned, caresp__Plan_Signed_Date__c = System.today()));
        } catch (Exception ex) {
            System.debug('Error in markPlanSigned: ' + ex.getMessage());
        }
    }

 @AuraEnabled
public static String getDecryptedPlanIdAndLinkCounter(String encryptedPlanId) {
    try {
        if (String.isNotBlank(encryptedPlanId)) {
            String planId = processDecryption(encryptedPlanId);
            System.debug('planId>>>> ' + planId);
            Plan__c planRec = [SELECT Id, Request_Signature_Counter__c, Request_Signature_Link_Status__c FROM Plan__c WHERE Id = :planId WITH SECURITY_ENFORCED LIMIT 1];
            System.debug('planRec>>>> ' + planRec);

            return planId + '#' + planRec.Request_Signature_Counter__c + '#' + planRec.Request_Signature_Link_Status__c;
        }
        return null;
    } catch (Exception ex) {
        System.debug('Error in getDecryptedPlanIdAndLinkCounter: ' + ex.getMessage());
        System.debug('Error occurred at line: ' + ex.getLineNumber());
        return null;
    }
}

    public static String processEncryption(String fields) {
        try {
            cryptoKey = getEncryptionDecryptionKey();
            Blob data = Blob.valueOf(fields);
            Blob encryptedData = Crypto.encryptWithManagedIV('AES128', cryptoKey, data);
            return EncodingUtil.base64Encode(encryptedData);
        } catch (Exception ex) {
            System.debug('Error in processEncryption: ' + ex.getMessage());
            System.debug('Stack Trace: ' + ex.getStackTraceString());

            return null;
        }
    }

    public static String processDecryption(String encryptedData) {
        try {
            Blob data = EncodingUtil.base64Decode(encryptedData);
            Blob privateKey = getEncryptionDecryptionKey();
            return Crypto.decryptWithManagedIV('AES128', privateKey, data).toString();
        } catch (Exception ex) {
            System.debug('Error in processDecryption: ' + ex.getMessage());
            System.debug('Stack Trace: ' + ex.getStackTraceString());

            return null;
        }
    }

    public static Blob getEncryptionDecryptionKey() {
        try {
            return [SELECT Body FROM StaticResource WHERE Name = 'Crypto_Key' WITH SECURITY_ENFORCED LIMIT 1].Body;
        } catch (Exception ex) {
            System.debug('Error in getEncryptionDecryptionKey: ' + ex.getMessage());
            return null;
        }
    }

    public class LwcResponse {
        @AuraEnabled public Boolean isSuccess { get; set; }
        @AuraEnabled public String error { get; set; }
        @AuraEnabled public String url { get; set; }
    } */
}