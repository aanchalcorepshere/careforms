// Wrapper class used in Service Plan Wizard to hold client, goal, and plan data for UI rendering and interaction.
public with sharing class ServicePlanWizClientsWrapper {

    @AuraEnabled public String clientId { get; set; }
    @AuraEnabled public String goalFilterField { get; set; }
    @AuraEnabled public String clientName { get; set; }
    @AuraEnabled public Date clientDOB { get; set; }
    @AuraEnabled public String cDisplayName { get; set; }
    @AuraEnabled public Boolean isDischarged { get; set; }
    @AuraEnabled public String style { get; set; }
    @AuraEnabled public List<Goals> listGoals { get; set; }

    // Holds dynamic attributes related to the client
    @AuraEnabled public Map<String, Object> attributes; // added by sg

    // Constructor that initializes the attributes map
    public ServicePlanWizClientsWrapper() {
        this.attributes = new Map<String, Object>();
    }

    // Nested class representing plan details associated with a client
    public class PlanWrapper {
        @AuraEnabled public String planType { get; set; }
        @AuraEnabled public String planStartDate { get; set; }
        @AuraEnabled public String planEndDate { get; set; }
        @AuraEnabled public String assignedServiceName { get; set; }
        @AuraEnabled public String serviceName { get; set; }
        @AuraEnabled public String planName { get; set; }
        @AuraEnabled public String planStatus { get; set; }
        @AuraEnabled public String planAcceptedDate { get; set; }
        @AuraEnabled public String planDescription { get; set; }
        @AuraEnabled public String clientStrengths { get; set; }
        @AuraEnabled public String planVersion { get; set; }
        @AuraEnabled public String parentPlanName { get; set; }
        @AuraEnabled public String progressStatus { get; set; }
        @AuraEnabled public List<ClientWrapper> clients { get; set; }
    }

    // Nested class representing additional client-level dynamic data
    public class ClientWrapper {
        @AuraEnabled public Map<String, Object> attributes;
    }

    // Class representing an individual goal assigned to the client
    public class Goals {
        @AuraEnabled public String goalId { get; set; }
        @AuraEnabled public String clientId { get; set; }
        @AuraEnabled public String planId { get; set; }
        @AuraEnabled public String goalName { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String startDate { get; set; }
        @AuraEnabled public String targetDate { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String goalType { get; set; }
        @AuraEnabled public String domain { get; set; }
        @AuraEnabled public Boolean isDeleteGoal { get; set; }
        @AuraEnabled public String clientGoalId { get; set; }
        @AuraEnabled public List<Steps> listSteps { get; set; }
    }

    // Class representing an individual step under a goal
    public class Steps {
        @AuraEnabled public String stepId { get; set; }
        @AuraEnabled public String goalId { get; set; }
        @AuraEnabled public String stepName { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String startDate { get; set; }
        @AuraEnabled public String targetDate { get; set; }
        @AuraEnabled public String assignedTo { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Boolean isDeleteStep { get; set; }
        @AuraEnabled public Boolean isActionableStep { get; set; }
        @AuraEnabled public String clientGoalStepId { get; set; }
        @AuraEnabled public String typeOfAction { get; set; } // Added By Anubhav
    }

    // Adds a key-value pair to the attributes map and returns the wrapper instance (Fluent API).
    public ServicePlanWizClientsWrapper put(String key, Object value) {
        attributes.put(key, value);
        return this;
    }
}