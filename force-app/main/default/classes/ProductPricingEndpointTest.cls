/**
 * Test class for ProductPricingEndpoint REST API
 *
 * @author Bryan Ferreira
 */
@IsTest
public class ProductPricingEndpointTest {

    // Test data constants
    private static final String TEST_COUNTRY = 'UK';
    private static final String TEST_PRODUCT_TYPE = 'Standard';
    private static final String TEST_UUID = 'f5b102de-4e2d-4c02-b59c-1156008383f2';
    private static final String TEST_UUID_2 = 'a1b202de-4e2d-4c02-b59c-1156008383a1';
    private static final String NONEXISTENT_UUID = '99999999-4e2d-4c02-b59c-1156008383f2';

    @TestSetup
    static void setupTestData() {
        List<Contact> contacts = new List<Contact>();

        // Complete contact with all required fields
        contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Home_Country__c = TEST_COUNTRY,
                Product__c = TEST_PRODUCT_TYPE,
                UUID__c = TEST_UUID
        ));

        // Contact missing Product__c
        contacts.add(new Contact(
                FirstName = 'Incomplete',
                LastName = 'Contact',
                Home_Country__c = TEST_COUNTRY,
                Product__c = null,
                UUID__c = TEST_UUID_2
        ));

        insert contacts;

        // Create pricing data that will work with ProductPricingController
        List<Pricing_Matrix__c> testPricing = new List<Pricing_Matrix__c>();
        testPricing.add(new Pricing_Matrix__c(
                Country__c = TEST_COUNTRY,
                Product__c = TEST_PRODUCT_TYPE,
                Service_Type__c = 'Cost per Calendar Month',
                Pricing_Type__c = 'Fixed',
                Currency__c = 'British Pound',
                Amount__c = 150.00
        ));
        insert testPricing;
    }

    //Helper method to setup REST context
    private static void setupRestContext(String uuidParam) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        if (String.isNotBlank(uuidParam)) {
            req.addParameter('UUID__c', uuidParam);
        }

        RestContext.request = req;
        RestContext.response = res;
    }

    @IsTest
    static void getRecordByUUID_Ok() {
        Test.startTest();
        setupRestContext(TEST_UUID);
        ProductPricingEndpoint.getRecordByUUID();
        Test.stopTest();

        RestResponse res = RestContext.response;
        Assert.areEqual(200, res.statusCode, 'Should return 200 OK');
        Assert.areEqual('application/json', res.headers.get('Content-Type'), 'Content type should be JSON');

        // Parse response to verify structure
        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Assert.areEqual(true, responseMap.get('success'), 'Success should be true');
        Assert.isNotNull(responseMap.get('data'), 'Data should not be null');
    }

    //Test missing UUID parameter
    @IsTest
    static void getRecordByUUID_MissingUUID_Ko() {
        Test.startTest();
        setupRestContext(null); // No UUID parameter
        ProductPricingEndpoint.getRecordByUUID();
        Test.stopTest();

        RestResponse res = RestContext.response;
        Assert.areEqual(400, res.statusCode, 'Should return 400 Bad Request');

        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Assert.areEqual(false, responseMap.get('success'), 'Success should be false');
        Assert.areEqual('UUID__c parameter is required', responseMap.get('message'), 'Should show missing UUID message');
    }

    @IsTest
    static void getRecordByUUID_EmptyUUID_Ko() {
        Test.startTest();
        setupRestContext(''); // Empty string UUID
        ProductPricingEndpoint.getRecordByUUID();
        Test.stopTest();

        RestResponse res = RestContext.response;
        Assert.areEqual(400, res.statusCode, 'Should return 400 Bad Request for empty UUID');

        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Assert.areEqual(false, responseMap.get('success'), 'Success should be false');
    }


    @IsTest
    static void getRecordByUUID_NonexistentUUID_Ko() {
        Test.startTest();
        setupRestContext(NONEXISTENT_UUID);
        ProductPricingEndpoint.getRecordByUUID();
        Test.stopTest();

        RestResponse res = RestContext.response;
        Assert.areEqual(404, res.statusCode, 'Should return 404 Not Found');

        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Assert.areEqual(false, responseMap.get('success'), 'Success should be false');
        Assert.areEqual('No Contact was found with the provided UUID', responseMap.get('message'), 'Should show contact not found message');
    }

    @IsTest
    static void getRecordByUUID_IncompleteContact_Ko() {
        Test.startTest();
        setupRestContext(TEST_UUID_2); // Contact with missing Product__c
        ProductPricingEndpoint.getRecordByUUID();
        Test.stopTest();

        RestResponse res = RestContext.response;
        Assert.areEqual(400, res.statusCode, 'Should return 400 for incomplete contact data');

        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Assert.areEqual(false, responseMap.get('success'), 'Success should be false');
        Assert.areEqual('Contact must have both Home_Country__c and Product__c populated', responseMap.get('message'), 'Should show missing fields message');
    }

    @IsTest
    static void getRecordByUUID_NoPricingData_Ko() {
        // Create contact with country/product combination that has no pricing data
        Contact noPricingContact = new Contact(
                FirstName = 'No',
                LastName = 'Pricing',
                Home_Country__c = null,
                Product__c = null,
                UUID__c = 'no-uuid-test'
        );
        insert noPricingContact;

        Test.startTest();
        setupRestContext(noPricingContact.UUID__c);
        ProductPricingEndpoint.getRecordByUUID();
        Test.stopTest();

        RestResponse res = RestContext.response;
        Assert.areNotEqual(200, res.statusCode, 'Should not return OK');

        String responseBody = res.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Assert.areEqual(false, responseMap.get('success'), 'Success should be false');
    }

    @IsTest
    static void responseWrapper_Ok() {
        Test.startTest();

        // Test with complete data
        Map<String, Object> testData = new Map<String, Object>{'key' => 'value'};
        ProductPricingEndpoint.ResponseWrapper wrapper =
                new ProductPricingEndpoint.ResponseWrapper(true, 'Success', testData);

        Assert.areEqual(true, wrapper.success, 'Success should be true');
        Assert.areEqual('Success', wrapper.message, 'Message should match');
        Assert.isNotNull(wrapper.data, 'Data should not be null');

        // Test with null data
        ProductPricingEndpoint.ResponseWrapper nullWrapper =
                new ProductPricingEndpoint.ResponseWrapper(false, 'Error', null);

        Assert.areEqual(false, nullWrapper.success, 'Success should be false');
        Assert.areEqual('Error', nullWrapper.message, 'Message should match');
        Assert.isNull(nullWrapper.data, 'Data should be null');

        // Test with different data types
        List<String> listData = new List<String>{'item1', 'item2'};
        ProductPricingEndpoint.ResponseWrapper listWrapper =
                new ProductPricingEndpoint.ResponseWrapper(true, 'List data', listData);

        Assert.isNotNull(listWrapper.data, 'List data should not be null');

        Test.stopTest();
    }
}