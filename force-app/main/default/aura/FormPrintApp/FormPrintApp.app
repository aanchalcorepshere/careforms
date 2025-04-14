<aura:application extends="force:slds" implements="lightning:isUrlAddressable" access = 'global'>
    <aura:html tag="style">
        @page { size: A4; margin: 25px; }
    </aura:html>
    <aura:attribute name="recordId" type="String" default=""/>
    <aura:attribute name="formId" type="String" default=""/>
    <aura:attribute name="objectApi" type="String" default=""/>
    <aura:attribute name="isApplication" type="Boolean" default=""/>
    <c:formsPrintUtil recordId="{!v.recordId}" formId="{!v.formId}" objectApi="{!v.objectApi}" isApplication="{!v.isApplication}"></c:formsPrintUtil>
</aura:application>