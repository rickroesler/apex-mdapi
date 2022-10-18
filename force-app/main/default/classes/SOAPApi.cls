public abstract class SOAPApi {
    private static final Integer SOAP_TIMEOUT = 120000;
    protected String sessionId; // child classes MUST set this

    /**
     * returns the XML response to the SOAP request
     */
    public String executeRequest() {

        HttpRequest req = new HttpRequest();

        String endPoint = URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/m/54.0';
        req.setEndpoint(endPoint);
        req.setHeader('Authorization', 'Bearer ' + getSessionId());
        req.setHeader('Content-Type', 'text/xml');
        req.setHeader('Accept', '*/*');
        req.setHeader('SOAPAction', '""');
        req.setMethod('POST');
        req.setTimeout(SOAP_TIMEOUT);
        req.setBody(getSOAPEnvelope());

        // add a try/catch here
        // if token has expired, then use the refresh token to fetch a new OAuth token
        // retry with the new token (sessionId)
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
        header += '<sessionId>' + getSessionId() + '</sessionId>';
        // header += '<sessionId>' + '{!$Credential.OAuthToken}' + '</sessionId>';
        header += '</SessionHeader>';
        header += '</soapenv:Header>';
        return header;
    }

    protected abstract String getSOAPBody();

    // need a different way to get this: refresh token or Named Credential
    private String getSessionId() {
        return this.sessionId;
    }
}
