/**
 * Copyright (c) 2012, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

/**
 * This is a dummy test class to obtain 100% coverage for the generated WSDL2Apex code, it is not a funcitonal test class
 **/ 
@isTest  
private class MetadataServiceTest
{    
    /**
     * Dummy Metadata API web service mock class (see MetadataCreateJobTest.cls for a better example)
     **/
	private class WebServiceMockImpl implements WebServiceMock 
	{
		public void doInvoke(
			Object stub, Object request, Map<String, Object> response,
			String endpoint, String soapAction, String requestName,
			String responseNS, String responseName, String responseType) 
		{
            if (request instanceof MetadataService.readMetadata_element)
                response.put('response_x', new MetadataService.readMetadataResponse_element());
			// if(request instanceof MetadataService.retrieve_element)
			// 	response.put('response_x', new MetadataService.retrieveResponse_element());
			// else if(request instanceof MetadataService.checkDeployStatus_element)
			// 	response.put('response_x', new MetadataService.checkDeployStatusResponse_element());
			// else if(request instanceof MetadataService.listMetadata_element)
			// 	response.put('response_x', new MetadataService.listMetadataResponse_element());
			// else if(request instanceof MetadataService.checkRetrieveStatus_element)
			// 	response.put('response_x', new MetadataService.checkRetrieveStatusResponse_element());
			// else if(request instanceof MetadataService.describeMetadata_element)
			// 	response.put('response_x', new MetadataService.describeMetadataResponse_element());
			// else if(request instanceof MetadataService.deploy_element)
			// 	response.put('response_x', new MetadataService.deployResponse_element());
            // else if(request instanceof MetadataService.updateMetadata_element)
            //     response.put('response_x', new MetadataService.updateMetadataResponse_element());
            // else if(request instanceof MetadataService.renameMetadata_element)
            //     response.put('response_x', new MetadataService.renameMetadataResponse_element());
            // else if(request instanceof  MetadataService.cancelDeploy_element)
            //     response.put('response_x', new MetadataService.cancelDeployResponse_element());
            // else if(request instanceof  MetadataService.deleteMetadata_element)
            //     response.put('response_x', new MetadataService.deleteMetadataResponse_element());
            // else if(request instanceof  MetadataService.upsertMetadata_element)
            //     response.put('response_x', new MetadataService.upsertMetadataResponse_element());
            // else if(request instanceof  MetadataService.createMetadata_element)
            //     response.put('response_x', new MetadataService.createMetadataResponse_element());
            // else if(request instanceof  MetadataService.deployRecentValidation_element)
            //     response.put('response_x', new MetadataService.deployRecentValidationResponse_element());
            // else if(request instanceof MetadataService.describeValueType_element)
            //     response.put('response_x', new MetadataService.describeValueTypeResponse_element());
            // else if(request instanceof MetadataService.checkRetrieveStatus_element)
            //     response.put('response_x', new MetadataService.checkRetrieveStatusResponse_element());
			return;
		}
	}    
		
	@IsTest
	private static void coverGeneratedCodeCRUDOperations()
	{	
    	// Null Web Service mock implementation
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        MetadataService metaDataService = new MetadataService();
        // Invoke operations     
        Test.startTest();    
        MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
        Test.stopTest();
	}
	
	@IsTest
    private static void coverGeneratedCodeFileBasedOperations1()
    {    	
    	// Null Web Service mock implementation
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        MetadataService metaDataService = new MetadataService();
        // Invoke operations    
        Test.startTest();     
        MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
        // metaDataPort.retrieve(null);
        // metaDataPort.checkDeployStatus(null, false);
        // metaDataPort.listMetadata(null, null);
        // metaDataPort.describeMetadata(null);
        // metaDataPort.deploy(null, null);
        // metaDataPort.checkDeployStatus(null, false);
        // metaDataPort.updateMetadata(null);
        // metaDataPort.renameMetadata(null, null, null);
        // metaDataPort.cancelDeploy(null);
        metadataPort.readMetadata(null, null);
        Test.stopTest();
    }
        
	@IsTest
    private static void coverGeneratedCodeTypes()
    {    	       
        // Reference types
        Test.startTest();
        new MetadataService();
        new MetadataService.Profile();
        new MetadataService.ProfileObjectPermissions();
        new MetadataService.ProfileLayoutAssignment();
        new MetadataService.ProfileApexClassAccess();
        new MetadataService.ProfileApplicationVisibility();
        new MetadataService.ProfileTabVisibility();
        new MetadataService.ProfileLoginIpRange();
        new MetadataService.ProfileRecordTypeVisibility();
        new MetadataService.ProfileFieldLevelSecurity();
        new MetadataService.ProfileLoginHours();
        new MetadataService.ProfileApexPageAccess();
        new MetadataService.ProfileExternalDataSourceAccess();
        new MetadataService.ProfileUserPermission();
        new MetadataService.ReadProfileResult();
        new MetadataService.readProfileResponse_element();
        new MetadataService.ProfileCustomPermissions();
        new MetadataService.ProfileActionOverride();
        new MetadataService.ReadProfileResult().getRecords();
        new MetadataService.readProfileResponse_element().getResult();
        Test.stopTest();
    } 
}