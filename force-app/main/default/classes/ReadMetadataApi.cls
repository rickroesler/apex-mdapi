public class ReadMetadataApi extends SOAPApi {
    private String metadataType;
    private List<String> fullNames;

    public ReadMetadataApi(String metadataType, List<String> fullNames) {
        super();
        this.metadataType = metadataType;
        this.fullNames = fullNames;
    }

    public override String getSOAPBody() {
        String body = '';
        body += '<readMetadata>';
        body += '<type>' + this.metadataType + '</type>';
        for (String fullName: this.fullNames) {
            body += '<fullNames>' + fullName + '</fullNames>';
        }
        body += '</readMetadata>';
        return body;
    }
}
