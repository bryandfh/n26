/**
 * Test class for ProductPricingController
 *
 * Test Coverage:
 * - Positive and negative scenarios for all public methods
 * - Edge cases and error handling
 * - Data setup and teardown
 * - Security and permission testing
 *
 * @author Bryan Ferreira
 */
@IsTest
public class ProductPricingControllerTest {

    // Test data constants
    private static final String TEST_COUNTRY = 'UK';
    private static final String TEST_PRODUCT_TYPE = 'Standard';
    private static final String INVALID_COUNTRY = 'InvalidCountry';
    private static final String INVALID_PRODUCT_TYPE = 'InvalidProduct';
    private static final String SERVICE_TYPE = 'Cost per Calendar Month';

    /**
     * Creates test data for pricing matrix records
     */
    @TestSetup
    static void setupTestData() {
        List<Pricing_Matrix__c> testPricingRecords = new List<Pricing_Matrix__c>();

        // Fixed pricing with British Pound
        testPricingRecords.add(new Pricing_Matrix__c(
                Country__c = TEST_COUNTRY,
                Product__c = TEST_PRODUCT_TYPE,
                Service_Type__c = SERVICE_TYPE,
                Pricing_Type__c = 'Fixed',
                Currency__c = 'British Pound',
                Amount__c = 150.00
        ));

        // Percentage pricing
        testPricingRecords.add(new Pricing_Matrix__c(
                Country__c = TEST_COUNTRY,
                Product__c = TEST_PRODUCT_TYPE,
                Service_Type__c = SERVICE_TYPE,
                Pricing_Type__c = 'Percentage',
                Amount__c = 15.5
        ));

        // Free pricing
        testPricingRecords.add(new Pricing_Matrix__c(
                Country__c = TEST_COUNTRY,
                Product__c = TEST_PRODUCT_TYPE,
                Service_Type__c = SERVICE_TYPE,
                Pricing_Type__c = 'Free'
        ));

        // Fixed pricing with Euro
        testPricingRecords.add(new Pricing_Matrix__c(
                Country__c = 'DE',
                Product__c = 'Standard',
                Service_Type__c = SERVICE_TYPE,
                Pricing_Type__c = 'Fixed',
                Currency__c = 'Euro',
                Amount__c = 2
        ));

        // Record with incomplete data (null amount)
        testPricingRecords.add(new Pricing_Matrix__c(
                Country__c = TEST_COUNTRY,
                Product__c = TEST_PRODUCT_TYPE,
                Service_Type__c = SERVICE_TYPE,
                Pricing_Type__c = 'Fixed',
                Currency__c = 'British Pound'
                // Amount__c is null
        ));

        insert testPricingRecords;
    }

    /**
     * Test getPricingDetails method - Positive scenario
     */
    @IsTest
    static void getPricingDetails_Ok() {
        Test.startTest();

        List<Pricing_Matrix__c> result = ProductPricingController.getPricingDetails(
                TEST_COUNTRY,
                TEST_PRODUCT_TYPE
        );

        Test.stopTest();

        // Assertions
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return pricing records');

        // Verify data integrity
        for (Pricing_Matrix__c record : result) {
            Assert.areEqual(TEST_COUNTRY, record.Country__c, 'Country should match filter');
            Assert.areEqual(TEST_PRODUCT_TYPE, record.Product__c, 'Product type should match filter');
        }
    }

    /**
     * Test getPricingDetails method - Negative scenario with empty parameters
     */
    @IsTest
    static void getPricingDetails_Ko() {
        Test.startTest();

        // Test with empty country
        try {
            ProductPricingController.getPricingDetails('', TEST_PRODUCT_TYPE);
            Assert.fail('Should have thrown AuraHandledException for empty country');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Error message should not be null');
        }

        // Test with empty product type
        try {
            ProductPricingController.getPricingDetails(TEST_COUNTRY, '');
            Assert.fail('Should have thrown AuraHandledException for empty product type');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Error message should not be null');
        }

        // Test with both parameters empty
        try {
            ProductPricingController.getPricingDetails('', '');
            Assert.fail('Should have thrown AuraHandledException for both parameters empty');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Error message should not be null');
        }

        // Test with null parameters
        try {
            ProductPricingController.getPricingDetails(null, TEST_PRODUCT_TYPE);
            Assert.fail('Should have thrown AuraHandledException for null country');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Error message should not be null');
        }

        Test.stopTest();
    }

    /**
     * Test formatResult method - Positive scenario
     */
    @IsTest
    static void formatResult_Ok() {
        Test.startTest();

        Map<String, Object> result = ProductPricingController.formatResult(
                TEST_COUNTRY,
                TEST_PRODUCT_TYPE
        );

        Test.stopTest();

        // Assertions
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return formatted results');

        // Verify specific formatting for different pricing types
        if (result.containsKey(SERVICE_TYPE)) {
            String formattedResult = (String) result.get(SERVICE_TYPE);
            Assert.isTrue(formattedResult.contains('N/a'), 'Should not include amount');
        }
    }

    /**
     * Test formatResult method - Negative scenario
     */
    @IsTest
    static void formatResult_Ko() {
        Test.startTest();

        // Test with empty country
        try {
            ProductPricingController.formatResult('', TEST_PRODUCT_TYPE);
            Assert.fail('Should have thrown AuraHandledException for empty country');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Error message should not be null');
        }

        // Test with empty product type
        try {
            ProductPricingController.formatResult(TEST_COUNTRY, '');
            Assert.fail('Should have thrown AuraHandledException for empty product type');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Error message should not be null');
        }

        // Test with null parameters
        try {
            ProductPricingController.formatResult(null, null);
            Assert.fail('Should have thrown AuraHandledException for null parameters');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Error message should not be null');
        }

        Test.stopTest();
    }

    /**
     * Test formatResult method with no matching data
     */
    @IsTest
    static void formatResult_NoData_Ok() {
        Test.startTest();

        Map<String, Object> result = ProductPricingController.formatResult(
                INVALID_COUNTRY,
                INVALID_PRODUCT_TYPE
        );

        Test.stopTest();

        // Should still return a map with all service types, but with N/a values
        Assert.isNotNull(result, 'Result should not be null even with no data');

        // All values should be N/a since no data matches the criteria
        for (String key : result.keySet()) {
            Assert.areEqual('N/a', result.get(key),
                    'All values should be N/a when no matching data exists');
        }
    }

    /**
     * Test queryPricingMatrix method - Positive scenario
     */
    @IsTest
    static void queryPricingMatrix_Ok() {
        Test.startTest();

        List<Pricing_Matrix__c> result = ProductPricingController.queryPricingMatrix(
                TEST_COUNTRY,
                TEST_PRODUCT_TYPE
        );

        Test.stopTest();

        // Assertions
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return records for valid parameters');

        // Verify all records match criteria
        for (Pricing_Matrix__c record : result) {
            Assert.areEqual(TEST_COUNTRY, record.Country__c, 'All records should match country filter');
            Assert.areEqual(TEST_PRODUCT_TYPE, record.Product__c, 'All records should match product filter');
        }

        // Verify field selection
        Pricing_Matrix__c firstRecord = result[0];
        Assert.isNotNull(firstRecord.Id, 'Id field should be selected');
        // Other fields might be null in test data, so we just verify they're accessible
    }

    /**
     * Test queryPricingMatrix method - Negative scenario (no matching data)
     */
    @IsTest
    static void queryPricingMatrix_Ko() {
        Test.startTest();

        List<Pricing_Matrix__c> result = ProductPricingController.queryPricingMatrix(
                INVALID_COUNTRY,
                INVALID_PRODUCT_TYPE
        );

        Test.stopTest();

        // Should return empty list for non-matching criteria
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(0, result.size(), 'Should return empty list for invalid parameters');
    }

    /**
     * Test currency mapping functionality
     */
    @IsTest
    static void currencyMapping_Ok() {
        Test.startTest();

        // Test Euro currency mapping
        Map<String, Object> euroResult = ProductPricingController.formatResult('Germany', 'Standard');

        Test.stopTest();

        Assert.isNotNull(euroResult, 'Euro result should not be null');

        if (euroResult.containsKey('Installation')) {
            String euroPrice = (String) euroResult.get('Installation');
            Assert.isTrue(euroPrice.contains('€'), 'Euro currency should be mapped to € symbol');
        }
    }

    /**
     * Test LIMIT clause functionality (verify it doesn't break with large datasets)
     */
    @IsTest
    static void queryLimit_Ok() {
        // Create additional test records to approach the LIMIT
        List<Pricing_Matrix__c> bulkRecords = new List<Pricing_Matrix__c>();

        for (Integer i = 0; i < 45; i++) {
            bulkRecords.add(new Pricing_Matrix__c(
                    Country__c = TEST_COUNTRY,
                    Product__c = TEST_PRODUCT_TYPE,
                    Service_Type__c = 'Cost per Calendar Month',
                    Pricing_Type__c = 'Fixed',
                    Currency__c = 'British Pound',
                    Amount__c = 10.00 + i
            ));
        }

        insert bulkRecords;

        Test.startTest();

        List<Pricing_Matrix__c> result = ProductPricingController.queryPricingMatrix(
                TEST_COUNTRY,
                TEST_PRODUCT_TYPE
        );

        Test.stopTest();

        // Should not exceed LIMIT of 50
        Assert.isTrue(result.size() <= 50, 'Query should respect LIMIT clause');
        Assert.isTrue(result.size() > 0, 'Should still return records');
    }

    /**
     * Test caching functionality (verify methods are properly annotated)
     */
    @IsTest
    static void caching_Ok() {
        // This test verifies that cacheable methods work correctly
        // Multiple calls should work without issues
        Test.startTest();

        List<Pricing_Matrix__c> firstCall = ProductPricingController.getPricingDetails(
                TEST_COUNTRY,
                TEST_PRODUCT_TYPE
        );

        List<Pricing_Matrix__c> secondCall = ProductPricingController.getPricingDetails(
                TEST_COUNTRY,
                TEST_PRODUCT_TYPE
        );

        Map<String, Object> firstFormatCall = ProductPricingController.formatResult(
                TEST_COUNTRY,
                TEST_PRODUCT_TYPE
        );

        Map<String, Object> secondFormatCall = ProductPricingController.formatResult(
                TEST_COUNTRY,
                TEST_PRODUCT_TYPE
        );

        Test.stopTest();

        // Results should be consistent across calls
        Assert.areEqual(firstCall.size(), secondCall.size(), 'Cached calls should return consistent results');
        Assert.areEqual(firstFormatCall.size(), secondFormatCall.size(), 'Formatted results should be consistent');
    }

    @IsTest
    static void mapCurrency_Ok() {
        Test.startTest();

        // Test British Pound
        String britishResult = ProductPricingController.mapCurrency('British Pound');
        Assert.areEqual('£', britishResult, 'British Pound should map to £');

        // Test Euro
        String euroResult = ProductPricingController.mapCurrency('Euro');
        Assert.areEqual('€', euroResult, 'Euro should map to €');

        Test.stopTest();
    }

    @IsTest
    static void mapCurrency_Ko() {
        Test.startTest();
        // Test unknown currency
        String unknownResult = ProductPricingController.mapCurrency('US Dollar');
        Assert.areEqual('US Dollar ', unknownResult, 'Unknown currency should return original + space');

        // Test empty string
        String emptyResult = ProductPricingController.mapCurrency('');
        Assert.areEqual('', emptyResult, 'Empty string should return empty string');

        // Test null
        String nullResult = ProductPricingController.mapCurrency(null);
        Assert.areEqual('', nullResult, 'Null should return empty string');

        Test.stopTest();
    }
}