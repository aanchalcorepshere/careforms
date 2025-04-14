trigger PlanTemplateTrigger on Plan_Template__c (before insert, before update, before delete, after update, after insert,after delete, after undelete) {
    TriggerDispatcher.Run('Plan_Template__c');
    
}