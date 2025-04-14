<aura:application extends="force:slds" implements="lightning:isUrlAddressable" access="global">
    <aura:attribute name="formId" type="String" default=""/>
    <aura:attribute name="recordId" type="String" default=""/>
    <aura:attribute name="isApplicationForm" type="Boolean" default=""/>
    <aura:attribute name="isCreateApplication" type="Boolean" default=""/>
    <aura:attribute name="isVerifyApplication" type="Boolean" default=""/>
    <c:inputFormContainer formId="{!v.formId}" recordId="{!v.recordId}" isApplicationForm="{!v.isApplicationForm}" isCreateApplication="{!v.isCreateApplication}" isVerifyApplication="{!v.isVerifyApplication}"></c:inputFormContainer>
</aura:application>