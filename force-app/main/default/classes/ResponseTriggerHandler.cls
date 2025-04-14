public with sharing class ResponseTriggerHandler implements ITriggerHandler
{
	public void BeforeInsert(List<SObject> newItems)
    {
		updateQuestionTextOnResponse((List<Response__c>)newItems);        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {}  
    
    public void BeforeDelete(Map<Id, SObject> oldItems)
    {}
    
    public void AfterInsert(Map<Id, SObject> newItems)
    {
        
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {}
    
    public void AfterDelete(Map<Id, SObject> oldItems)
    {}
    
    public void AfterUndelete(Map<Id, SObject> oldItems)
    {}
    

    
    public static void updateQuestionTextOnResponse(List<caresp__Response__c>listResp)
    {
        List<String> asQuesIdList = new List<String>();
        for(caresp__Response__c resp:listResp){
            asQuesIdList.add(resp.caresp__Assessment_Question__c);
        }
        
        Map<Id, caresp__Assessment_Question__c> asQuesMap = new Map<Id, caresp__Assessment_Question__c>([select Id, Question__r.Question_Text__c from Assessment_Question__c where Id in :asQuesIdList WITH SECURITY_ENFORCED]);
    
        for(caresp__Response__c resp:listResp){
            if(asQuesMap.get(resp.caresp__Assessment_Question__c)!=null){
             	resp.caresp__Question_Text__c = asQuesMap.get(resp.caresp__Assessment_Question__c).caresp__Question__r.caresp__Question_Text__c;   
            }
        }
    }
    
    
}