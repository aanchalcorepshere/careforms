trigger AssessmentTrigger on Assessment__c (before insert, before update, before delete, after update, after insert,after delete, after undelete) {

    TriggerDispatcher.Run('Assessment__c');

}