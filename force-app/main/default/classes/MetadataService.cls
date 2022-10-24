public abstract class MetadataService {
    public class MetadataServiceException extends Exception {}
    
    private static final Integer SOAP_TIMEOUT = 120000;
    private static final String SOAP_ENDPOINT = '/services/Soap/m/54.0'; // maybe make the version dynamic?
    private static final String INVALID_TOKEN = 'invalid_token';
    private static final String INVALID_SESSION_ID = 'INVALID_SESSION_ID';

    protected String sessionId; // child classes MUST set this

    /**
     * returns the XML response to the SOAP request
     */
    public String executeRequest() {
        String xml;

        HttpRequest req = new HttpRequest();

        String endPoint = URL.getSalesforceBaseUrl().toExternalForm() + SOAP_ENDPOINT;
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
        try {
            HttpResponse res;
            res = new Http().send(req);
            xml = res.getBody();
            system.debug(xml);
        } catch (CalloutException e) {
            throw new MetadataServiceException(e.getMessage());
        }

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
