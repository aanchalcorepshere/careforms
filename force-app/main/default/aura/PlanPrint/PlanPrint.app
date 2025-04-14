<aura:application extends="force:slds" implements="forceCommunity:availableForAllPageTypes" access="global">
    
    <aura:attribute name="recordId" type="String"/>
    <aura:attribute name="objectApiName" type="String"/>
    <aura:attribute name="print" type="Boolean" default="true"/>
    
	<c:planWizContainer recordId="{!v.recordId}" objectApiName="{!v.objectApiName}" forPrint="{!v.print}"></c:planWizContainer>
</aura:application>