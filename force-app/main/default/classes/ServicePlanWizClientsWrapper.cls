public with sharing class ServicePlanWizClientsWrapper
{
    @AuraEnabled public String clientId {get; set;}
    @AuraEnabled public String goalFilterField {get; set;}
    @AuraEnabled public String clientName {get; set;}
    @AuraEnabled public Date clientDOB {get; set;}
    @AuraEnabled public String cDisplayName {get; set;}
    @AuraEnabled public Boolean isDischarged {get; set;}
    @AuraEnabled public String style {get; set;}
    @AuraEnabled public List<Goals> listGoals {get; set;}
    @AuraEnabled public Map<String, Object> attributes; // added by sg 
    

    public ServicePlanWizClientsWrapper()
    {
        this.attributes = new Map<String, Object>();
    }



     public Class PlanWrapper{
        @AuraEnabled Public String planType {get;set;}
        @AuraEnabled Public String planStartDate {get;set;}
        @AuraEnabled Public String planEndDate {get;set;}
        @AuraEnabled Public String assignedServiceName {get;set;}
        @AuraEnabled Public String serviceName {get;set;}
        @AuraEnabled Public String planName {get;set;}
        @AuraEnabled Public String planStatus {get;set;}
        @AuraEnabled Public String planAcceptedDate {get;set;}
        @AuraEnabled Public String planDescription {get;set;}
        @AuraEnabled Public String clientStrengths {get;set;}
        @AuraEnabled Public String planVersion {get;set;}
        @AuraEnabled Public String parentPlanName {get;set;}
        @AuraEnabled Public String progressStatus {get;set;}
        @AuraEnabled Public List<ClientWrapper> clients {get;set;}
    }

    public Class ClientWrapper{
        /*@AuraEnabled Public String clientName {get;set;}
        @AuraEnabled Public String clientDob {get;set;}
        @AuraEnabled Public List<Goals> goals {get;set;}*/
        @AuraEnabled public Map<String, Object> attributes;
    }


    public class Goals
    {
        @AuraEnabled public String goalId {get; set;}
        @AuraEnabled public String clientId {get; set;}
        @AuraEnabled public String planId {get; set;}
        @AuraEnabled public String goalName {get; set;}
        @AuraEnabled public String description {get; set;}
        @AuraEnabled public String startDate {get; set;}
        @AuraEnabled public String targetDate {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public String goalType {get; set;}
        @AuraEnabled public String domain {get; set;}
        @AuraEnabled public Boolean isDeleteGoal {get; set;}
        @AuraEnabled public String clientGoalId {get; set;}
        @AuraEnabled public List<Steps> listSteps {get; set;}
    }




    public class Steps
    {
        @AuraEnabled public String stepId {get; set;}
        @AuraEnabled public String goalId {get; set;}
        @AuraEnabled public String stepName {get; set;}
        @AuraEnabled public String description {get; set;}
        @AuraEnabled public String startDate {get; set;}
        @AuraEnabled public String targetDate {get; set;}
        @AuraEnabled public String assignedTo {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public Boolean isDeleteStep {get; set;}
        @AuraEnabled public Boolean isActionableStep {get; set;}
        @AuraEnabled public String clientGoalStepId {get; set;}
        @AuraEnabled public String typeOfAction {get; set;} // Added By Anubhav
    }


    /*added by sg*/
    public ServicePlanWizClientsWrapper put(String key, Object value)
    {
        attributes.put(key, value);
        return this;
    }

     /*added by sg end*/
}