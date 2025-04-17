trigger AnswerTrigger on caresp__Answer__c (before insert, before update, before delete, after update, after insert,after delete, after undelete) 
{
	TriggerDispatcher.Run('caresp__Answer__c');
}