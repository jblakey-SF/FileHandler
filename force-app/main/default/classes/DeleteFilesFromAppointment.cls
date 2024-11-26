@isTest
public class DeleteFilesFromAppointment {
    @isTest
    static void testDeletingFilesUpdateApt() {
        // Step 1: Create a Case (used for linking to an Appointment)
        Case newCase = new Case(Subject = 'Test Case');
        insert newCase;

        // Step 2: Create Appointments linked to the Case
        List<Appointment__c> appointments = new List<Appointment__c>();
        for (Integer i = 1; i <= 2; i++) {
            appointments.add(new Appointment__c(
                Consult_Case__c = newCase.Id,
                File_Attachment_Classification__c = 'MR'
            ));
        }
        insert appointments;

        // Step 3: Create a ContentVersion 
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert contentVersion;

        // Query ContentVersion to get the ContentDocumentId
        contentVersion = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion.Id
        ];
        Id contentDocumentId = contentVersion.ContentDocumentId;

        // Step 4: Link ContentDocument to the Appointments
        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        for (Appointment__c appointment : appointments) {
            documentLinks.add(new ContentDocumentLink(
                LinkedEntityId = appointment.Id,
                ContentDocumentId = contentDocumentId,
                ShareType = 'V'
            ));
        }
        insert documentLinks;

        // Step 5: Query the Appointment linked to the ContentDocumentLink
        List<Appointment__c> linkedAppointments = [
            SELECT Id, File_Attachment_Classification__c 
            FROM Appointment__c
            WHERE Id = :appointments[0].Id
        ];
        System.debug('Appointments: ' + linkedAppointments);

        // Step 6: Delete the ContentDocumentLink
        delete documentLinks;

        // Step 7: Query the ContentDocumentLink
        List<ContentDocumentLink> deletedContentDocumentLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId 
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
        ];
        System.debug('Deleted ContentDocumentLinks: ' + deletedContentDocumentLinks);

        // Step 8: Assert that the File_Attachment_Classification__c field was updated on the Appointment
       
        // Step 6: Test the execute method
        Test.startTest();
        ContentHandler.execute(deletedContentDocumentLinks);
        Test.stopTest();
        List<Appointment__c> appointmentClassificationUpdated = [
            SELECT Id, File_Attachment_Classification__c 
            FROM Appointment__c
            WHERE Id = :appointments[0].Id
        ];
        System.debug('Appointments: ' + appointmentClassificationUpdated);
        System.Assert.areEqual(null, appointmentClassificationUpdated[0].File_Attachment_Classification__c, 'The File_Attachment_Classification__c field should be blank as the ContentDocumentLinks were deleted');
        System.debug('Classification: ' + appointmentClassificationUpdated[0].File_Attachment_Classification__c);

        



        
    }
}
