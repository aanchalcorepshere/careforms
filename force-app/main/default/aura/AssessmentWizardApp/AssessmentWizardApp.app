<aura:application extends="force:slds" implements="lightning:isUrlAddressable" access = 'global'>
    <aura:handler name="init" value="{!this}" action="{!c.doInit}"/>
        <aura:attribute name="isEdit" type="Boolean" default="false"/>
        <aura:attribute name="editAssessmentId" type="String" default=""/>
        <c:assessmentWizardContainer isEdit="{!v.isEdit}" editAssessmentId="{!v.editAssessmentId}"></c:assessmentWizardContainer>
</aura:application>