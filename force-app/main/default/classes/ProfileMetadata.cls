public  class ProfileMetadata {
    private static final Integer FIELD_PERMISSIONS_COUNT_LOWER_LIMIT = 18000;
    private static final Integer MAX_CHUNK_SIZE = 10; // readMetadata() can read 10 max records
    private static final Double API_VERSION = 55.0;
    private static final Integer JSON_CHUNK_SIZE = 130000;

    public static void updateProfileMetadataRecords() {
        Map<Id, ProfileProperties> currentProfiles = getCurrentProfiles();
        Map<Id, ProfileProperties> savedProfiles = getSavedProfiles();

        processDeletedProfiles(currentProfiles, savedProfiles);
        processNewProfiles(currentProfiles, savedProfiles);
        processExistingProfiles(currentProfiles, savedProfiles);
        deleteAllPersistedRecords();
    }

    /**
     * @returns List<List<String> where the total FieldPermissions count in each subarray
     *                            is guaranteed to be less than FIELD_PERMISSIONS_COUNT_UPPER_LIMIT
     * 
    */
    public static List<List<String>> getDynamicChunks() {
        Map<Id, String> profilesToUpdate = getProfilesToUpdate();
        Map<Id, Integer> fieldPermissionsCountByProfile = getFieldPermissionsCountByProfileId();

        List<List<String>> dynamicChunks = new List<List<String>>();
        Integer totalCount = 0;
        List<String> fullNames = new List<String>();
        for (Id profileId: fieldPermissionsCountByProfile.keySet()) {
            Integer count = fieldPermissionsCountByProfile.get(profileId);
            String fullName = profilesToUpdate.get(profileId);

            // push the name to the current chunk if it doesn't exceed the size limit; go to the next profile
            if (totalCount + count <= FIELD_PERMISSIONS_COUNT_LOWER_LIMIT && fullNames.size() < MAX_CHUNK_SIZE) {
                totalCount += count;
                fullNames.add(fullName);
                continue;
            } 
            
            // this chunk is full; push the chunk to the list and reset for the next chunk
            if (!fullNames.isEmpty()) {
                dynamicChunks.add(fullNames);
                totalCount = 0;
                fullNames = new List<String>();
            }

            // if the profile that pushed it over the limit is "big", make it its own chunk
            // otherwise, push the "small" profile to the just-reinitialized chunk
            if (count > FIELD_PERMISSIONS_COUNT_LOWER_LIMIT) {
                dynamicChunks.add(new List<String>{ fullName });
            } else {
                totalCount += count;
                fullNames.add(fullName);
            }
        }

        // handle any remaining
        if (!fullNames.isEmpty()) dynamicChunks.add(fullNames);

        return dynamicChunks;
    }

    public void persistProfile(MetadataService.Profile rawProfile) {
        Profile profile = new Profile(rawProfile);
        String jsonProfile = JSON.serialize(profile, true); // true = suppress Object nulls
        List<String> chunkedJson = chunkString(jsonProfile, JSON_CHUNK_SIZE);
        
        List<Profile_Metadata_Part__b> parts = new List<Profile_Metadata_Part__b>();
        Integer chunkNumber = 0;
        for (String chunk: chunkedJson) {
            Profile_Metadata_Part__b part = new Profile_Metadata_Part__b;
                part.Full_Name__c = profile.fullName;
                part.Chunk_Number__c = chunkNumber;
                part.Chunk__c = chunkedJson[chunkNumber];
            parts.add(part);
            chunkNumber++;
        }

        List<Database.SaveResult> results = Database.insertImmediate(parts);
        Boolean success = true;
        for (Database.DeleteResult result: results) {
            if (!result.isSuccess()) {
                success = false;
                for (Database.Error e: result.getErrors()) {
                    System.debug('Error inserting BigObject records: ' + e.getStatusCode() + ': ' + e.getMessage());
                }
            }
        }

        if (success) {
            Profile_Metadata__c record = [SELECT Id, Last_Saved_Datetime__c
                                            FROM Profile_Metadata__c
                                           WHERE Name = :profile.fullName];
            record.Last_Saved_Datetime__c = Datetime.now();
            update record;
        }
    }

    public void markTooBig(List<String> fullNames) {
        List<Profile_Metadata__c> profiles = [SELECT Id, Is_Too_Large_To_Process__c
                                                FROM Profile_Metadata__c
                                               WHERE Name IN :fullNames];

        if (profiles.size() != fullNames.size()) {
            system.debug('requested: ' + fullNames + '; received: ' + profiles);
            return;
        }

        for (Profile_Metadata__c profile: profiles) {
            profile.Is_Too_Large_To_Process__c = true;
        }

        update.profiles;
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
        Set<Id> newIds = currentProfiles.keySet().clone();
        newIds.removeAll(savedProfiles.keySet());
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

    /**
     * returns Map<Id, String> where Id is a Profile Id whose Last_Saved_Datetime < Last_Modified_Datetime
     *                           and String is the Profiles fullName
     */
    private static Map<Id, String> getProfilesToUpdate() {
        Map<Id, String> profileIdsToUpdate = new Map<Id, String>();
        for (Profile_Metadata__c profile: [SELECT Profile_Id__c, Name,
                                                  Last_Saved_Datetime__c, Last_Modified_Datetime__c
                                             FROM Profile_Metadata__c]) {
            if (profile.Last_Saved_Datetime__c == null || profile.Last_Saved_Datetime__c < profile.Last_Modified_Datetime__c) {
                profileIdsToUpdate.put(profile.Profile_Id__c, profile.Name);
            }
        }
        return profileIdsToUpdate;
    }

    private static void deleteAllPersistedRecords() {
        List<Profile_Metadata_Part__b> parts = new List<Profile_Metadata_Part__b>();
        parts.addAll([SELECT Full_Name__c, Chunk_Number__c FROM Profile_Metadata_Part__b]);
        List<Database.DeleteResult> results = Database.deleteImmediate(parts);
        for (Database.DeleteResult result: results) {
            if (!result.isSuccess()) {
                for (Database.Error e: result.getErrors()) {
                    System.debug('Error deleting BigObject records: ' + e.getStatusCode() + ': ' + e.getMessage());
                }
            }
        }
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
                profile.fullName = EncodingUtil.urlDecode(file.fullName, 'UTF-8');
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

    private List<String> chunkString(String s, Integer chunkSize) {
        List<String> chunkedString = new List<String>();
        do {
            chunkedString.add(s.left(chunkSize));
            s = s.length() < chunkSize ? '' : s.substring(chunkSize);
        } while (s.length() > 0);
        return chunkedString;
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
