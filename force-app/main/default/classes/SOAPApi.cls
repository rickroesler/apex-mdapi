public with sharing class SOAPApi {
    private static final Integer SOAP_TIMEOUT = 120000;
    private static final Set<String> SUPPORTED_METHODS = new Set<String>{ 'listMetadata', 'readMetadata' };
    private String sessionId;
    private String method;
    private String metadataType;
    private List<String> fullNames;

    public SOAPApi(String method, String metadataType) {
        this.sessionId = UserInfo.getSessionId();
        this.method = method; // check for valid method
        this.metadataType = metadataType;
        this.fullNames = new List<String>();
    }

    public SOAPApi(String method, String metadataType, List<String> fullNames) {
        this.sessionId = UserInfo.getSessionId();
        this.method = method; // check for valid method
        this.metadataType = metadataType;
        this.fullNames = fullNames;
    }

    /**
     * returns the XML response to the SOAP request
     */
    public String executeRequest() {

        HttpRequest req = new HttpRequest();

        // String endPoint = URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/m/54.0'; // + ElementsUtils.SF_API_VERSION;
        // req.setEndpoint(endPoint);
        // req.setHeader('Authorization', 'Bearer ' + this.sessionId);
        req.setEndpoint('callout:ElementsSoapApi/services/Soap/m/54.0');
        req.setHeader('Content-Type', 'text/xml');
        req.setHeader('Accept', '*/*');
        req.setHeader('SOAPAction', '""');
        req.setMethod('POST');
        req.setTimeout(SOAP_TIMEOUT);
        req.setBody(getSOAPEnvelope());

        Http http = new Http();
        HttpResponse res = http.send(req);
        String xml = res.getBody();
        system.debug(xml);
        return xml;
    }

    private String getSOAPEnvelope() {
        String envelope = '';
        envelope += '<?xml version="1.0" encoding="UTF-8"?>';
        envelope += '<soapenv:Envelope'; 
        envelope += '    xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"';
        envelope += '    xmlns:xsd="http://www.w3.org/2001/XMLSchema"';
        envelope += '    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
        envelope += getSOAPHeader();
        envelope += getSOAPBody();
        envelope += '</soapenv:Envelope>';
        return envelope;
    }

    private String getSOAPHeader() {
        String header = '';
        header += '<soapenv:Header xmlns="http://soap.sforce.com/2006/04/metadata">';
        header += '<SessionHeader>';
        // header += '<sessionId>' + this.sessionId + '</sessionId>';
        header += '<sessionId>' + '{!$Credential.OAuthToken}' + '</sessionId>';
        header += '</SessionHeader>';
        header += '</soapenv:Header>';
        return header;
    }

    private String getSOAPBody() {
        String body = '';

        body += '<soapenv:Body xmlns="http://soap.sforce.com/2006/04/metadata">';

        if (this.method == 'listMetadata') {
            body += '<listMetadata>';
            body += '<queries>';
            body += '<type>' + this.metadataType + '</type>';
            body += '</queries>';
            body += '</listMetadata>';
        }

        if (this.method == 'readMetadata') {
            body += '<readMetadata>';
            body += '<type>' + this.metadataType + '</type>';
            for (String fullName: this.fullNames) {
                body += '<fullNames>' + fullName + '</fullNames>';
            }
            body += '</readMetadata>';
        }

        body += '</soapenv:Body>';
        return body;
    }


}
