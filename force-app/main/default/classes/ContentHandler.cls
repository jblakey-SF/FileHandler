public with sharing class ContentHandler {

    public static void execute(List<contentDocumentLink> deletedcontentDocumentLinks) {
        // Map to hold deleted ContentDocumentLink records by ID
        List<Id> linkedEntityIds = new List<Id>();
        List<Id> deletedContentDocumentLinksIds = new List<Id>();
        for (contentDocumentLink cdl : deletedcontentDocumentLinks) {
            deletedContentDocumentLinksIds.add(cdl.Id);
            linkedEntityIds.add(cdl.LinkedEntityId);
        }

        // Query related Appointment__c records
        List<Appointment__c> appointments = [
            SELECT Id, File_Attachment_Classification__c 
            FROM Appointment__c 
            WHERE Id IN :linkedEntityIds
        ];

        // Query non-deleted ContentDocumentLinks
        List<contentDocumentLink> nonDeletedContentLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId 
            FROM contentDocumentLink 
            WHERE LinkedEntityId IN :linkedEntityIds 
            AND Id NOT IN :deletedContentDocumentLinksIds
        ];

        // Pass data to the update method
        updateAppointmentRecordCategory(deletedContentDocumentLinksIds, appointments, nonDeletedContentLinks);
    }

    private static void updateAppointmentRecordCategory(
        List<Id> deletedcontentDocumentLinksIds,
        List<Appointment__c> appointments,
        List<contentDocumentLink> nonDeletedContentLinks
    ) {
       

        Map<Id, String> contentVersionCategories = new Map<Id, String>();
        for (ContentVersion cv : [
            SELECT ContentDocumentId, Category__c 
            FROM ContentVersion 
            WHERE ContentDocumentId IN :deletedcontentDocumentLinksIds
        ]) {
            contentVersionCategories.put(cv.ContentDocumentId, cv.Category__c);
        }

        // This will be use to determine what catagory belong to which appointment based on the LinkedEnityId
        Map<Id, Set<String>> remainingCategoriesByAppointment = new Map<Id, Set<String>>();
        for (contentDocumentLink cdl : nonDeletedContentLinks) {
            if (!remainingCategoriesByAppointment.containsKey(cdl.LinkedEntityId)) {
                remainingCategoriesByAppointment.put(cdl.LinkedEntityId, new Set<String>{contentVersionCategories.get(cdl.ContentDocumentId)});
            }
            if (contentVersionCategories.containsKey(cdl.ContentDocumentId)) {
                remainingCategoriesByAppointment.get(cdl.LinkedEntityId).add(contentVersionCategories.get(cdl.ContentDocumentId));
            }
        }

        // Chekcing to see if the File Attachment field is Null, if not null, it will add the contents of the field into a list. 
        List<Appointment__c> appointmentsToUpdate = new List<Appointment__c>();
        for (Appointment__c appointment : appointments) {
            Set<String> currentCategories = new Set<String>();
            if (appointment.File_Attachment_Classification__c != null) {
                currentCategories.addAll(appointment.File_Attachment_Classification__c.split(';'));
            }

            // Remove deleted categories from list
            Set<String> categoriesToKeep = remainingCategoriesByAppointment.get(appointment.Id);
            System.debug(remainingCategoriesByAppointment);
            Boolean catagoriesAreDiffrenet =  currentCategories.equals(remainingCategoriesByAppointment);
            System.debug(catagoriesAreDiffrenet);
           

            //Check isCatagories to keep equals current catagories to keep
            //Create an empty list of apts to update
            //If catagories are different, update attachment catagoires to the apts to equals current catagores and add it to a list of apts to update
            
            if (catagoriesAreDiffrenet == false) {

               // appointment.File_Attachment_Classification__c = String.join(new List<String>(remainingCategoriesByAppointment.get(appointment.Id)), ',');
               appointment.File_Attachment_Classification__c = remainingCategoriesByAppointment.get(appointment.Id).toString();
 
               appointmentsToUpdate.add(appointment);


            } else {
                currentCategories.clear();
            }

        }

        // Update the appointments in bulk
        if (!appointmentsToUpdate.isEmpty()) {
            update appointmentsToUpdate;
        }
    }
}
