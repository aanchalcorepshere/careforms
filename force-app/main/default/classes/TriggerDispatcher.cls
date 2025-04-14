/**
 * @description  This class runs the appropriate methods on the trigger handler based on the current trigger context.
 */
public with sharing class TriggerDispatcher {
  public static Boolean isActive;
  public static String handlerName;
  /*
    Call this method from your trigger, passing in an instance of a trigger handler which implements ITriggerHandler.
    This method will fire the appropriate methods on the handler depending on the trigger context.
  */
  public static void Run(String objApiName)
  {
    
    getInfo(objApiName);

    Type customType = Type.forName(handlerName);
    ITriggerHandler handler = (ITriggerHandler)customType.newInstance();
    
    if(isActive == true){
      switch on Trigger.operationType {
        when BEFORE_INSERT {
          handler.BeforeInsert(Trigger.new);
        } 
        when BEFORE_UPDATE {
          handler.BeforeUpdate(Trigger.newMap, Trigger.oldMap);
        } 
        when BEFORE_DELETE {
          handler.BeforeDelete(Trigger.oldMap);
        } 
        when AFTER_INSERT {
          handler.AfterInsert(Trigger.newMap);
        } 
        when AFTER_UPDATE {
          handler.AfterUpdate(Trigger.newMap, Trigger.oldMap);
        } 
        when AFTER_DELETE {
          handler.AfterDelete(Trigger.oldMap);
        } 
        when AFTER_UNDELETE {
          handler.AfterUndelete(Trigger.oldMap);
        }
      }
    }
  }

  public static void getInfo(String objApiName){
    List<Trigger_Setting__mdt> settings = [select Id, isActive__c, Helper_Class__c from Trigger_Setting__mdt where Object_Name__c =: objApiName WITH SECURITY_ENFORCED];
    if(settings != null && settings.size()>0)
    {
      isActive = settings[0].isActive__c;
      handlerName = settings[0].Helper_Class__c;
    }
  }
}