// Trigger to handle all DML events on caresp__Question_Bank__c object and delegate processing to TriggerDispatcher
trigger QuestionBankTrigger on caresp__Question_Bank__c (before insert, before update, before delete, after update, after insert, after delete, after undelete) 
{
	TriggerDispatcher.Run('caresp__Question_Bank__c');
}