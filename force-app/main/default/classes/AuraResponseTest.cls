@isTest
private class AuraResponseTest {
    
    @isTest
    static void testConstructor() {
        Boolean isSuccess = true;
        String message = 'Success message';
        String response = 'Success response';
        String objectApiName = 'Account';
        Account acc = new Account(Name = 'Test Account');
        SObject sObjectDetails = acc;
        String fieldApiName = 'Name';
        String grandChildObjectApiName = 'OpportunityLineItem';
        String childObjectApiName = 'Opportunity';
        String primaryObjectApiName = 'Account';
        String parentObjectApiName = '';
         // Add this line
        List<SObject> listSObjectDetails = new List<SObject>{acc};
        
        // Act
        AuraResponse auraResponse = new AuraResponse(
            isSuccess, message, response, objectApiName, sObjectDetails, 
            fieldApiName, grandChildObjectApiName, childObjectApiName, 
            primaryObjectApiName, parentObjectApiName); // Update this line 
        
        
        
        // Assert
        System.assertEquals(isSuccess, auraResponse.isSuccess);
        System.assertEquals(message, auraResponse.message);
        System.assertEquals(response, auraResponse.response);
        System.assertEquals(objectApiName, auraResponse.objectApiName);
        System.assertEquals(sObjectDetails, auraResponse.sObjectDetails);
        System.assertEquals(fieldApiName, auraResponse.fieldApiName);
        System.assertEquals(grandChildObjectApiName, auraResponse.grandChildObjectApiName);
        System.assertEquals(childObjectApiName, auraResponse.childObjectApiName);
        System.assertEquals(primaryObjectApiName, auraResponse.primaryObjectApiName);
        System.assertEquals(parentObjectApiName, auraResponse.parentObjectApiName);
        //System.assertEquals(listSObjectDetails, auraResponse.listSObjectDetails); 
    }
}