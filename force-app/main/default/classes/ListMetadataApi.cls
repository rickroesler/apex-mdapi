public class ListMetadataApi extends SOAPApi {
    private String metadataType;

    public ListMetadataApi(String metadataType) {
        super();
        this.metadataType = metadataType;
    }

    public override String getSOAPBody() {
        String body = '';
        body += '<soapenv:Body xmlns="http://soap.sforce.com/2006/04/metadata">';
        body += '<listMetadata>';
        body += '<queries>';
        body += '<type>' + this.metadataType + '</type>';
        body += '</queries>';
        body += '</listMetadata>';
        body += '</soapenv:Body>';
        return body;
    }
}
