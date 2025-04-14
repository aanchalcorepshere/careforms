<aura:application extends="force:slds" implements="lightning:isUrlAddressable" access="global">
    <aura:handler name="init" value="{!this}" action="{!c.doInit}"/>
    <aura:attribute name="isEdit" type="Boolean" default="false"/>
    <aura:attribute name="editFormId" type="String" default=""/>
    <c:formsContainer isEdit="{!v.isEdit}" editFormId="{!v.editFormId}"></c:formsContainer>
</aura:application>