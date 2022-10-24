public class ReadMetadataApi extends MetadataService {
    private String metadataType;
    private List<String> fullNames;

    public ReadMetadataApi(String sessionId, String metadataType, List<String> fullNames) {
        this.sessionId = sessionId;
        this.metadataType = metadataType;
        this.fullNames = fullNames;
    }

    protected override String getSOAPBody() {
        String body = '';
        body += '<soapenv:Body xmlns="http://soap.sforce.com/2006/04/metadata">';
        body += '<readMetadata>';
        body += '<type>' + this.metadataType + '</type>';
        for (String fullName: this.fullNames) {
            body += '<fullNames>' + fullName + '</fullNames>';
        }
        body += '</readMetadata>';
        body += '</soapenv:Body>';
        return body;
    }
}
