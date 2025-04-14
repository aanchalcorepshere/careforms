<aura:application extends="force:slds" implements="forceCommunity:availableForAllPageTypes" access="global">
    <aura:handler name="init" value="{!this}" action="{!c.doInit}" description=""/>
    <aura:attribute name="outcomeId" type="String"/>
    <aura:attribute name="objectName" type="String"/>

    <c:outcomeResultPage outcomeId="{!v.outcomeId}" objectName="{!v.objectName}"></c:outcomeResultPage>
</aura:application>