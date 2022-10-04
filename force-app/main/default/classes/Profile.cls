public class Profile {
    
    public String fullName;
    public Boolean custom;
    public String description;
    public String userLicense;
    public ActionOverride[] profileActionOverrides;
    public ApexClassAccess[] classAccesses;
    public ApexPageAccess[] pageAccesses;
    public ApplicationVisibility[] applicationVisibilities;
    public CategoryGroupVisibility[] categoryGroupVisibilities;
    public CustomPermissions[] customPermissions;
    public ExternalDataSourceAccess[] externalDataSourceAccesses;
    public FieldLevelSecurity[] fieldPermissions;
    public LayoutAssignment[] layoutAssignments;
    public LoginHours loginHours;
    public LoginIpRange[] loginIpRanges;
    public ObjectPermissions[] objectPermissions;
    public RecordTypeVisibility[] recordTypeVisibilities;
    public TabVisibility[] tabVisibilities;
    public UserPermission[] userPermissions;

    public Profile(MetadataService.Profile profile) {
        this.fullName = profile.fullName;
        this.custom = profile.custom;
        this.description = profile.description;
        this.userLicense = profile.userLicense;
        
        if (profile.profileActionOverrides != null) {
            this.profileActionOverrides = new List<actionOverride>();
            for (MetadataService.ProfileactionOverride actionOverride: profile.profileActionOverrides) {
                this.profileActionOverrides.add(new actionOverride(actionOverride));
            }
        }
        if (profile.classAccesses != null) {
            this.classAccesses = new List<ApexClassAccess>();
            for (MetadataService.ProfileApexClassAccess classAccess: profile.classAccesses) {
                this.classAccesses.add(new ApexClassAccess(classAccess));
            }
        }
        if (profile.pageAccesses != null) {
            this.pageAccesses = new List<ApexPageAccess>();
            for (MetadataService.ProfileApexPageAccess pageAccess: profile.pageAccesses) {
                this.pageAccesses.add(new ApexPageAccess(pageAccess));
            }
        }
        if (profile.applicationVisibilities != null) {
            this.applicationVisibilities = new List<ApplicationVisibility>();
            for (MetadataService.ProfileApplicationVisibility appVisibility: profile.applicationVisibilities) {
                this.applicationVisibilities.add(new ApplicationVisibility(appVisibility));
            }
        }
        if (profile.categoryGroupVisibilities != null) {
            this.categoryGroupVisibilities = new List<CategoryGroupVisibility>();
            for (MetadataService.ProfileCategoryGroupVisibility groupVisibility: profile.categoryGroupVisibilities) {
                this.categoryGroupVisibilities.add(new CategoryGroupVisibility(groupVisibility));
            }
        }
        if (profile.customPermissions != null) {
            this.customPermissions = new List<CustomPermissions>();
            for (MetadataService.ProfileCustomPermissions customPermission: profile.customPermissions) {
                this.customPermissions.add(new CustomPermissions(customPermission));
            }
        }
        if (profile.externalDataSourceAccesses != null) {
            this.externalDataSourceAccesses = new List<externalDataSourceAccess>();
            for (MetadataService.ProfileexternalDataSourceAccess externalDataSourceAccess: profile.externalDataSourceAccesses) {
                this.externalDataSourceAccesses.add(new externalDataSourceAccess(externalDataSourceAccess));
            }
        }
        if (profile.fieldPermissions != null) {
            this.fieldPermissions = new List<FieldLevelSecurity>();
            for (MetadataService.ProfileFieldLevelSecurity fieldPermission: profile.fieldPermissions) {
                this.fieldPermissions.add(new FieldLevelSecurity(fieldPermission));
            }
        }
        if (profile.layoutAssignments != null) {
            this.layoutAssignments = new List<LayoutAssignment>();
            for (MetadataService.ProfileLayoutAssignment layoutAssignment: profile.layoutAssignments) {
                this.layoutAssignments.add(new LayoutAssignment(layoutAssignment));
            }
        }
        if (profile.loginHours != null) {
            this.loginHours = new LoginHours(profile.loginHours);
        }
        if (profile.loginIpRanges != null) {
            this.loginIpRanges = new List<LoginIpRange>();
            for (MetadataService.ProfileLoginIpRange loginIpRange: profile.loginIpRanges) {
                this.loginIpRanges.add(new LoginIpRange(loginIpRange));
            }
        }
        if (profile.objectPermissions != null) {
            this.objectPermissions = new List<ObjectPermissions>();
            for (MetadataService.ProfileObjectPermissions objectPermission: profile.objectPermissions) {
                this.objectPermissions.add(new ObjectPermissions(objectPermission));
            }
        }
        if (profile.recordTypeVisibilities != null) {
            this.recordTypeVisibilities = new List<RecordTypeVisibility>();
            for (MetadataService.ProfileRecordTypeVisibility recordTypeVisibility: profile.recordTypeVisibilities) {
                this.recordTypeVisibilities.add(new RecordTypeVisibility(recordTypeVisibility));
            }
        }
        if (profile.tabVisibilities != null) {
            this.tabVisibilities = new List<TabVisibility>();
            for (MetadataService.ProfileTabVisibility tabVisibility: profile.tabVisibilities) {
                this.tabVisibilities.add(new TabVisibility(tabVisibility));
            }
        }
        if (profile.userPermissions != null) {
            this.userPermissions = new List<UserPermission>();
            for (MetadataService.ProfileUserPermission userPermission: profile.userPermissions) {
                this.userPermissions.add(new UserPermission(userPermission));
            }
        }
    }

    public class ActionOverride {
        public String actionName;
        public String content;
        public String formFactor;
        public String pageOrSobjectType;
        public String recordType;
        public String type_x;

        ActionOverride(MetadataService.ProfileActionOverride actionOverride) {
            this.actionName = actionOverride.actionName;
            this.content = actionOverride.content;
            this.formFactor = actionOverride.formFactor;
            this.pageOrSobjectType = actionOverride.pageOrSobjectType;
            this.recordType = actionOverride.recordType;
            this.type_x = actionOverride.type_x;
        }
    }
    public class ApexClassAccess {
        public String apexClass;
        public Boolean enabled;

        ApexClassAccess(MetadataService.ProfileApexClassAccess classAccess) {
            this.apexClass = classAccess.apexClass;
            this.enabled = classAccess.enabled;
        }
    }
    public class ApexPageAccess {
        public String apexPage;
        public Boolean enabled;

        ApexPageAccess(MetadataService.ProfileApexPageAccess pageAccess) {
            this.apexPage = pageAccess.apexPage;
            this.enabled = pageAccess.enabled;
        }
    }
    public class ApplicationVisibility {
        public String application;
        public Boolean default_x;
        public Boolean visible;

        ApplicationVisibility(MetadataService.ProfileApplicationVisibility appVisibility) {
            this.application = appVisibility.application;
            this.default_x = appVisibility.default_x;
            this.visible = appVisibility.visible;
        }
    }
    public class CategoryGroupVisibility {
        public String[] dataCategories;
        public String dataCategoryGroup;
        public String visibility;

        CategoryGroupVisibility(MetadataService.ProfileCategoryGroupVisibility groupVisibility) {
            this.dataCategories = groupVisibility.dataCategories;
            this.dataCategoryGroup = groupVisibility.dataCategoryGroup;
            this.visibility = groupVisibility.visibility;
        }
    }
    public class CustomPermissions {
        public Boolean enabled;
        public String name;

        CustomPermissions(MetadataService.ProfileCustomPermissions customPermission) {
            this.enabled = customPermission.enabled;
            this.name = customPermission.name;
        }
    }
    public class ExternalDataSourceAccess {
        public Boolean enabled;
        public String externalDataSource;

        ExternalDataSourceAccess(MetadataService.ProfileExternalDataSourceAccess extAccess) {
            this.enabled = extAccess.enabled;
            this.externalDataSource = extAccess.externalDataSource;
        }
    }
    public class FieldLevelSecurity {
        public Boolean editable;
        public String field;
        public Boolean readable;

        FieldLevelSecurity(MetadataService.ProfileFieldLevelSecurity fieldSecurity) {
            this.editable = fieldSecurity.editable;
            this.field = fieldSecurity.field;
            this.readable = fieldSecurity.readable;
        }
    }
    public class LayoutAssignment {
        public String layout;
        public String recordType;

        LayoutAssignment(MetadataService.ProfileLayoutAssignment layoutAssignment) {
            this.layout = layoutAssignment.layout;
            this.recordType = layoutAssignment.recordType;
        }
    }
    public class LoginHours {
        public String fridayEnd;
        public String fridayStart;
        public String mondayEnd;
        public String mondayStart;
        public String saturdayEnd;
        public String saturdayStart;
        public String sundayEnd;
        public String sundayStart;
        public String thursdayEnd;
        public String thursdayStart;
        public String tuesdayEnd;
        public String tuesdayStart;
        public String wednesdayEnd;
        public String wednesdayStart;

        LoginHours(MetadataService.ProfileLoginHours loginHours) {
            this.fridayEnd = loginHours.fridayEnd;
            this.fridayStart = loginHours.fridayStart;
            this.mondayEnd = loginHours.mondayEnd;
            this.mondayStart = loginHours.mondayStart;
            this.saturdayEnd = loginHours.saturdayEnd;
            this.saturdayStart = loginHours.saturdayStart;
            this.sundayEnd = loginHours.sundayEnd;
            this.sundayStart = loginHours.sundayStart;
            this.thursdayEnd = loginHours.thursdayEnd;
            this.thursdayStart = loginHours.thursdayStart;
            this.tuesdayEnd = loginHours.tuesdayEnd;
            this.tuesdayStart = loginHours.tuesdayStart;
            this.wednesdayEnd = loginHours.wednesdayEnd;
            this.wednesdayStart = loginHours.wednesdayStart;
        }
    }
    public class LoginIpRange {
        public String description;
        public String endAddress;
        public String startAddress;

        LoginIpRange(MetadataService.ProfileLoginIpRange ipRange) {
            this.description = ipRange.description;
            this.endAddress = ipRange.endAddress;
            this.startAddress = ipRange.startAddress;
        }
    }
    public class ObjectPermissions {
        public Boolean allowCreate;
        public Boolean allowDelete;
        public Boolean allowEdit;
        public Boolean allowRead;
        public Boolean modifyAllRecords;
        public String object_x;
        public Boolean viewAllRecords;

        ObjectPermissions(MetadataService.ProfileObjectPermissions objectPermission) {
            this.allowCreate = objectPermission.allowCreate;
            this.allowDelete = objectPermission.allowDelete;
            this.allowEdit = objectPermission.allowEdit;
            this.allowRead = objectPermission.allowRead;
            this.modifyAllRecords = objectPermission.modifyAllRecords;
            this.object_x = objectPermission.object_x;
            this.viewAllRecords = objectPermission.viewAllRecords;
        }
    }
    
    public class RecordTypeVisibility {
        public Boolean default_x;
        public Boolean personAccountDefault;
        public String recordType;
        public Boolean visible;

        RecordTypeVisibility(MetadataService.ProfileRecordTypeVisibility recordTypeVisibility) {
            this.default_x = recordTypeVisibility.default_x;
            this.personAccountDefault = recordTypeVisibility.personAccountDefault;
            this.recordType = recordTypeVisibility.recordType;
            this.visible = recordTypeVisibility.visible;
        }
    }
    public class TabVisibility {
        public String tab;
        public String visibility;

        TabVisibility(MetadataService.ProfileTabVisibility tabVisibility) {
            this.tab = tabVisibility.tab;
            this.visibility = tabVisibility.visibility;
        }
    }
    public class UserPermission {
        public Boolean enabled;
        public String name;

        UserPermission(MetadataService.ProfileUserPermission userPermission) {
            this.enabled = userPermission.enabled;
            this.name = userPermission.name;
        }
    }
}
