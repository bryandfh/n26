/**
 * ProductPricingEndpoint - REST API endpoint for retrieving pricing data by Contact UUID
 *
 * API Endpoint: /services/apexrest/api/records/?UUID__c={UUID Value}
 * Method: GET
 * Response Format: {"success": boolean, "message": string, "data": object}
 *
 * @author Bryan Ferreira
 */
@RestResource(UrlMapping='/api/records/*')
global with sharing class ProductPricingEndpoint {

    /**
     * GET endpoint to retrieve pricing data for a Contact by UUID
     * Throws no exceptions because all errors handled internally
     * return void (writes directly to RestContext.response)
     */
    @HttpGet
    global static void getRecordByUUID() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Set response content type for JSON
        res.addHeader('Content-Type', 'application/json');

        try {
            // Extract UUID param
            // Expected format: /api/records/?UUID__c={UUID}
            String uuidValue = req.params.get('UUID__c');

            // Input validation
            if (String.isBlank(uuidValue)) {
                res.statusCode = 400; // Bad Request
                ResponseWrapper errorResponse = new ResponseWrapper(false, 'UUID__c parameter is required', null);
                res.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
                return;
            }

            // Query Contact record with required field
            List<Contact> records = [
                    SELECT UUID__c, Home_Country__c, Product__c
                    FROM Contact
                    WHERE UUID__c = :uuidValue
                    WITH SECURITY_ENFORCED
                    LIMIT 1
            ];

            // If Contact do not exist exit
            if (records.isEmpty()) {
                res.statusCode = 404; // Not Found
                ResponseWrapper errorResponse = new ResponseWrapper(false, 'No Contact was found with the provided UUID', null);
                res.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
                return;
            }

            Contact contactInformation = records[0];

            // Validate that Contact has required data
            if (String.isBlank(contactInformation.Home_Country__c) || String.isBlank(contactInformation.Product__c)) {
                res.statusCode = 400; // If not exit
                ResponseWrapper errorResponse = new ResponseWrapper(false, 'Contact must have both Home_Country__c and Product__c populated', null);
                res.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
                return;
            }

            // Delegate pricing logic to controller for separation of concerns
            Map<String, Object> pricingData;

            try {
                pricingData = ProductPricingController.formatResult(contactInformation.Home_Country__c, contactInformation.Product__c);
            } catch (AuraHandledException e) {
                // Handle the case where controller throws AuraHandledException
                res.statusCode = 404; // Not Found
                ResponseWrapper errorResponse = new ResponseWrapper(false, 'No pricing data found for the specified country and product', null);
                res.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
                return;
            }

            // Happy path
            res.statusCode = 200; // OK
            ResponseWrapper successResponse = new ResponseWrapper(true, 'Success', pricingData);
            res.responseBody = Blob.valueOf(JSON.serialize(successResponse));

        } catch (Exception e) {
            // Catch-all error handling for unexpected exceptions. Here would be a nice place to put a Nebula logger log
            // log entry and save it
            System.debug('Unexpected error in ProductPricingEndpoint: ' + e.getMessage());

            res.statusCode = 500; // Internal Server Error
            ResponseWrapper errorResponse = new ResponseWrapper(false, 'An unexpected error occurred. Please try again later.', null);
            res.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
        }
    }

    global class ResponseWrapper {
        global Boolean success;
        global String message;
        global Object data;

        /**
         * Constructor for ResponseWrapper
         *
         * @param success Boolean indicating if the operation was successful
         * @param message Descriptive message about the operation result
         * @param data Response payload - handles Map, List, primitives, or null
         */
        global ResponseWrapper(Boolean success, String message, Object data) {
            this.success = success;
            this.message = message;
            this.data = data;
        }
    }
}