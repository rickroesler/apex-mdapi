public with sharing class ProfileMetadata {
    
    private static final Map<String, String> FULL_NAME_MAP = new Map<String,String>{
        'Contract Manager' => 'ContractManager',
        'High Volume Customer Portal' => 'HighVolumePortal',
        'Marketing User' => 'MarketingProfile',
        'System Administrator' => 'Admin',
        'Platform Portal' => 'PlatformPortal'

    };
    public static Map<Id, Integer> getFieldPermissionsCountByProfile() {}

    public static Map<Id, Datetime> getAllProfilesLastModifiedDate() {}


}
