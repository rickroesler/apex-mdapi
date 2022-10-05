public  class ProfileMetadata {
    private static final Integer FIELD_PERMISSIONS_COUNT_LOWER_LIMIT = 20000;
    private static final Integer FIELD_PERMISSIONS_COUNT_UPPER_LIMIT = 30000;
    private static final Double API_VERSION = 55.0;
    
    public static void updateProfileMetadataRecords() {
        Map<Id, ProfileProperties> currentProfiles = getCurrentProfiles();
        Map<Id, ProfileProperties> savedProfiles = getSavedProfiles();

        processDeletedProfiles(currentProfiles, savedProfiles);
        processNewProfiles(currentProfiles, savedProfiles);
        processExistingProfiles(currentProfiles, savedProfiles);
    }

    private static void processDeletedProfiles(Map<Id, ProfileProperties> currentProfiles, Map<Id, ProfileProperties> savedProfiles) {
        Set<Id> deletedIds = savedProfiles.keySet().clone();
        deletedIds.removeAll(currentProfiles.keySet());
        List<Profile_Metadata__c> profiles = [SELECT Id, Is_Deleted__c 
                                                FROM Profile_Metadata__c
                                               WHERE Profile_Id__c IN :deletedIds];
        for (Profile_Metadata__c profile: profiles) {
            profile.Is_Deleted__c = true;
        }
        update profiles;
    }

    private static void processNewProfiles(Map<Id, ProfileProperties> currentProfiles, Map<Id, ProfileProperties> savedProfiles) {
        // TODO: handle case where a new profile is created with the same fullName as a previously-deleted profile
        // make a list of fullnames of the new profiles
        // select saved profiles that are deleted with those fullnames
        // if there's a match handle those ids/fullnames separately
        system.debug(currentProfiles.keySet());
        system.debug(savedProfiles.keySet());
        Set<Id> newIds = currentProfiles.keySet().clone();
        newIds.removeAll(savedProfiles.keySet());
        system.debug(newIds);
        List<Profile_Metadata__c> profiles = new List<Profile_Metadata__c>();
        for (Id newId: newIds) {
            Profile_Metadata__c profile = new Profile_Metadata__c();
                profile.Profile_Id__c = newId;
                profile.Last_Modified_Datetime__c = currentProfiles.get(newId).lastModifiedDatetime;
                profile.Name = currentProfiles.get(newId).fullName;
                profile.Is_Deleted__c = false;
                profile.Last_Saved_Datetime__c = null;
            profiles.add(profile);
        }
        insert profiles;
    }

    private static void processExistingProfiles(Map<Id, ProfileProperties> currentProfiles, Map<Id, ProfileProperties> savedProfiles) {
        Set<Id> existingIds = currentProfiles.keySet().clone();
        existingIds.retainAll(savedProfiles.keySet());
        List<Profile_Metadata__c> profiles = [SELECT Id, Profile_Id__c, Last_Modified_Datetime__c, Is_Deleted__c 
                                                FROM Profile_Metadata__c
                                               WHERE Profile_Id__c IN :existingIds];
        for (Profile_Metadata__c profile: profiles) {
            profile.Name = currentProfiles.get(profile.Profile_Id__c).fullName;
            profile.Last_Modified_Datetime__c = currentProfiles.get(profile.Profile_Id__c).lastModifiedDatetime;
            profile.Is_Deleted__c = false;
        }
        update profiles;
    }

    public static List<List<String>> getDynamicChunks() {
        return null;
    }

    /**
     * returns Map<Id, Integer> where Id == Salesforce Profile Id
     *                             count == the number of FieldPermissions in the profile
     */
    private static Map<Id, Integer> getFieldPermissionsCountByProfileId() {
        Map<Id, Integer> fieldPermissionsCountByProfileId = new Map<Id, Integer>();
        for (AggregateResult result: [SELECT COUNT(Id) FieldPermissionsCount, Parent.ProfileId
                                        FROM FieldPermissions
                                       WHERE Parent.ProfileId != NULL
                                    GROUP BY Parent.ProfileId
                                    ORDER BY COUNT(Id) ASC]) {
            fieldPermissionsCountByProfileId.put((Id) result.get('ProfileId'), (Integer) result.get('FieldPermissionsCount'));
        }
        return fieldPermissionsCountByProfileId;
    }

    /**
     * returns Map<Id, ProfileMetadata> where Id == Salesforce Profile Id
     *                                        ProfileMetadata == record corresponding to an existing Profile
     */
    private static Map<Id, ProfileProperties> getCurrentProfiles() {
        Map<Id, ProfileProperties> currentProfiles = new Map<Id, ProfileProperties>();

        MetadataService.MetadataPort service = MetadataService.createService();
        MetadataService.ListMetadataQuery query = new MetadataService.ListMetadataQuery();
        query.type_x = 'Profile';
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>{ query };
        List<MetadataService.FileProperties> files = service.listMetadata(queries, API_VERSION); 

        for (MetadataService.FileProperties file: files) {
            ProfileProperties profile = new ProfileProperties();
                profile.profileId = file.id;
                profile.fullName = file.fullName;
                profile.lastModifiedDatetime = file.lastModifiedDate;
            currentProfiles.put(profile.profileId, profile);
        }
        return currentProfiles;
    }

    /**
     * returns Map<Id, ProfileMetadata> where Id == Salesforce Profile Id
     *                                        ProfileMetadata == a saved Profile_Metadata__c record
     */
    private static Map<Id, ProfileProperties> getSavedProfiles() {
        Map<Id, ProfileProperties> savedProfiles = new Map<Id, ProfileProperties>();

        List<Profile_Metadata__c> profiles = [SELECT Id, Name, Profile_Id__c, Is_Deleted__c, 
                                                     Last_Saved_Datetime__c, Last_Modified_Datetime__c
                                                FROM Profile_Metadata__c];
        
        for (Profile_Metadata__c p: profiles) {
            ProfileProperties profile = new ProfileProperties();
                profile.profileMetadataId = p.Id;
                profile.profileId = p.Profile_Id__c;
                profile.fullName = p.Name;
                profile.lastSavedDatetime = p.Last_Saved_Datetime__c;
                profile.lastModifiedDatetime = p.Last_Modified_Datetime__c;
                profile.isDeleted = p.Is_Deleted__c;
            savedProfiles.put(profile.profileId, profile);
        }
        return savedProfiles;
    }

    public static void saveAttachment(Id profileMetadataId, Id profileId, String jsonProfileMetadata) {
        Attachment attachment = new Attachment();
            attachment.Body = Blob.valueOf(jsonProfileMetadata);
            attachment.Name = String.valueOf(profileId + '.json');
            attachment.ParentId = '0012900000alyvlAAA'; 
        insert attachment;
    }

    class ProfileProperties {
        Id profileMetadataId;
        String fullName;
        Id profileId;
        Boolean isDeleted;
        Datetime lastSavedDatetime;
        Datetime lastModifiedDatetime;
    }
}
