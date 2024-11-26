trigger FileContentTrigger on ContentDocumentLink (after delete) {
    List<ContentDocumentLink> deletedContentDocumentLinks = Trigger.old;
    ContentHandler.execute(deletedContentDocumentLinks);
}