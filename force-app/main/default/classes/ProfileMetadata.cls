public  class ProfileMetadata {
    private static final Double API_VERSION = 55.0;

    public static void updateProfileMetadataRecords() {
        Map<Id, ProfileProperties> currentProfiles = getCurrentProfiles();
        Map<Id, ProfileProperties> savedProfiles = getSavedProfiles();

        deleteAllXmlAttachments();

        processDeletedProfiles(currentProfiles, savedProfiles);
        processNewProfiles(currentProfiles, savedProfiles);
        processExistingProfiles(currentProfiles, savedProfiles);
    }

    /**
     * returns List<String> list of encoded Profile names whose Last_Saved_Datetime < Last_Modified_Datetime
     */
    public static List<String> getProfilesToUpdate() {
        List<String> profilesToUpdate = new List<String>();
        for (Profile_Metadata__c profile: [SELECT Encoded_FullName__c,
                                                  Last_Saved_Datetime__c, Last_Modified_Datetime__c
                                             FROM Profile_Metadata__c]) {
            if (profile.Last_Saved_Datetime__c == null || profile.Last_Saved_Datetime__c < profile.Last_Modified_Datetime__c) {
                profilesToUpdate.add(profile.Encoded_FullName__c);
            }
        }
        return profilesToUpdate;
    }

    public static Boolean persistProfile(Profile profile) {
        system.debug('heap 4: ' + Limits.getHeapSize());
        String jsonProfile = JSON.serialize(profile, true); // true = suppress Object nulls
        system.debug(jsonProfile.length());
        system.debug('heap 5: ' + Limits.getHeapSize());
        
        List<String> chunkedJson = new List<String>();
        do {
            chunkedJson.add(jsonProfile.left(JSON_CHUNK_SIZE));
            jsonProfile = jsonProfile.length() < JSON_CHUNK_SIZE ? '' : jsonProfile.substring(JSON_CHUNK_SIZE);
            system.debug('heap 6: ' + Limits.getHeapSize());
        } while (jsonProfile.length() > 0);

        List<Profile_Metadata_Part__b> parts = new List<Profile_Metadata_Part__b>();
        Integer chunkNumber = 0;
        for (String chunk: chunkedJson) {
            Profile_Metadata_Part__b part = new Profile_Metadata_Part__b();
                part.Full_Name__c = profile.fullName;
                part.Chunk_Number__c = chunkNumber;
                part.Chunk__c = chunkedJson[chunkNumber];
            parts.add(part);
            chunkNumber++;
        }

        List<Database.SaveResult> results = Database.insertImmediate(parts);
        Boolean success = true;
        for (Database.SaveResult result: results) {
            if (!result.isSuccess()) {
                success = false;
                for (Database.Error e: result.getErrors()) {
                    System.debug('Error inserting BigObject records: ' + e.getStatusCode() + ': ' + e.getMessage());
                }
            }
        }

        return success;
    }

    public static void persistLastSavedDatetimes(Map<String, Datetime> lastSavedDatetimes) {
        List<Profile_Metadata__c> records = [SELECT Id, Encoded_FullName__c, Last_Saved_Datetime__c
                                               FROM Profile_Metadata__c
                                              WHERE Encoded_FullName__c IN :lastSavedDatetimes.keySet()];
        for (Profile_Metadata__c record: records) {
            record.Last_Saved_Datetime__c = lastSavedDatetimes.get(record.Encoded_FullName__c);
        }
        update records;
    }

    public static void markTooBig(List<String> encodedFullNames) {
        List<Profile_Metadata__c> profiles = [SELECT Id, Is_Too_Large_To_Process__c
                                                FROM Profile_Metadata__c
                                               WHERE Encoded_FullName__c IN :encodedFullNames];

        if (profiles.size() != encodedFullNames.size()) {
            system.debug('requested: ' + encodedFullNames + '; received: ' + profiles);
            return;
        }

        for (Profile_Metadata__c profile: profiles) {
            profile.Is_Too_Large_To_Process__c = true;
        }

        update profiles;
    }

    private static void processDeletedProfiles(Map<Id, ProfileProperties> currentProfiles, Map<Id, ProfileProperties> savedProfiles) {
        Set<Id> deletedIds = savedProfiles.keySet().clone();
        deletedIds.removeAll(currentProfiles.keySet());

        if (deletedIds.isEmpty()) return;

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
            ProfileProperties currentProfile = currentProfiles.get(newId);
            Profile_Metadata__c profile = new Profile_Metadata__c();
                profile.Profile_Id__c = newId;
                profile.Last_Modified_Datetime__c = currentProfile.lastModifiedDatetime;
                profile.Name = currentProfile.fullName;
                profile.Encoded_FullName__c = currentProfile.encodedFullName;
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
            ProfileProperties currentProfile = currentProfiles.get(profile.Profile_Id__c);
            profile.Name = currentProfile.fullName;
            profile.Encoded_FullName__c = currentProfile.encodedFullName;
            profile.Last_Modified_Datetime__c = currentProfiles.get(profile.Profile_Id__c).lastModifiedDatetime;
            profile.Is_Deleted__c = false;
        }
        update profiles;
    }

    private static void deleteAllXmlAttachments() {

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
                profile.encodedFullName = file.fullName;
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

        List<Profile_Metadata__c> profiles = [SELECT Id, Name, Encoded_FullName__c, Profile_Id__c, Is_Deleted__c, 
                                                     Last_Saved_Datetime__c, Last_Modified_Datetime__c
                                                FROM Profile_Metadata__c];
        
        for (Profile_Metadata__c p: profiles) {
            ProfileProperties profile = new ProfileProperties();
                profile.profileMetadataId = p.Id;
                profile.profileId = p.Profile_Id__c;
                profile.fullName = p.Name;
                profile.encodedFullName = p.Encoded_FullName__c;
                profile.lastSavedDatetime = p.Last_Saved_Datetime__c;
                profile.lastModifiedDatetime = p.Last_Modified_Datetime__c;
                profile.isDeleted = p.Is_Deleted__c;
            savedProfiles.put(profile.profileId, profile);
        }
        return savedProfiles;
    }

    class ProfileProperties {
        Id profileMetadataId;
        String fullName;
        String encodedFullName;
        Id profileId;
        Boolean isDeleted;
        Datetime lastSavedDatetime;
        Datetime lastModifiedDatetime;
    }
}
