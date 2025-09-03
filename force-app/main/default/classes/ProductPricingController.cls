/**
 * ProductPricingController - Handles pricing matrix data retrieval and formatting
 *
 * Notes:
 * - Uses cacheable methods to leverage Lightning platform caching
 * - Separates data retrieval from formatting for better maintainability
 * - Implements defensive programming with comprehensive error handling
 * - Uses WITH SECURITY_ENFORCED for FLS/CRUD compliance
 * - Performance Considerations: LIMIT 50 prevents runaway queries but may need adjustment based on data volume in the future
 *
 * @author Bryan Ferreira
 */
public with sharing class ProductPricingController {

    /**
     * Retrieves pricing matrix records for a specific country and product type
     * @param country The target country for pricing
     * @param productType The product type to filter by
     * @return List of Pricing_Matrix__c records matching the criteria
     * @throws AuraHandledException User friendly error for LWC
     */
    @AuraEnabled(Cacheable=true)
    public static List<Pricing_Matrix__c> getPricingDetails(String country, String productType) {
        try {
            // Input validation
            if (String.isEmpty(country) || String.isEmpty(productType)) {
                throw new AuraHandledException('Country and Product are required parameters.');
            }

            List<Pricing_Matrix__c> pricingDetails = queryPricingMatrix(country, productType);

            return pricingDetails;

        } catch (Exception e) {
            // Since its out of the scope I wont put a logger, but here would be a nice place to put a Nebula Logger
            // log entry and save it
            System.debug('Error in getPricingDetails: ' + e.getMessage());

            // Rethrow as AuraHandledException for LWC errors
            throw new AuraHandledException('Unable to retrieve pricing details: ' + e.getMessage());
        }
    }

    /**
     * Formats pricing data into a UI-friendly map structure. User for customProductDetail LWC
     * and ProductPricingEndpoint.cls
     *
     * @param country The target country for pricing
     * @param productType The product type to filter by
     * @return Map where keys are service types and values are formatted pricing strings
     * @throws AuraHandledException User friendly error for LWC
     */
    @AuraEnabled(Cacheable=true)
    public static Map<String, Object> formatResult(String country, String productType) {
        try {
            // Input validation
            if (String.isEmpty(country) || String.isEmpty(productType)) {
                throw new AuraHandledException('Country and Product are required parameters.');
            }

            // Retrieve raw pricing data
            List<Pricing_Matrix__c> pricingDetails = queryPricingMatrix(country, productType);

            // Create lookup map for O(1) access
            Map<String, Pricing_Matrix__c> pricingMap = new Map<String, Pricing_Matrix__c>();
            for (Pricing_Matrix__c pricing : pricingDetails) {
                if (pricing.Service_Type__c != null) {
                    pricingMap.put(pricing.Service_Type__c, pricing);
                }
            }

            // Get all possible service types from picklist metadata
            // This ensures UI displays all service types even if no pricing data exists
            List<String> serviceTypeValues = getServiceTypePicklistValues();

            Map<String, Object> resultMap = new Map<String, Object>();

            // Configuration constant. This could be a Custom Label, Custom Metadata, etc. Depending of what is used in the org.
            final String DEFAULT_EMPTY_VALUE = 'N/a';

            for (String serviceType : serviceTypeValues) {
                String value = DEFAULT_EMPTY_VALUE;

                // Lookup pricing data for current service type
                if (pricingMap.containsKey(serviceType)) {
                    Pricing_Matrix__c pricing = pricingMap.get(serviceType);

                    // Format based on pricing type
                    if (pricing.Pricing_Type__c == 'Fixed' && pricing.Currency__c != null && pricing.Amount__c != null){
                        value = mapCurrency(pricing.Currency__c) + ' ' + String.valueOf(pricing.Amount__c);
                    } else if (pricing.Pricing_Type__c == 'Percentage' && pricing.Amount__c != null){
                        value = String.valueOf(pricing.Amount__c) + '%';
                    } else if(pricing.Pricing_Type__c == 'Free'){
                        value = 'Free';
                    }
                    // If pricing type is unrecognized or data incomplete we use default
                }

                // Build final result structure
                resultMap.put(serviceType, value);
            }

            return resultMap;

        } catch (Exception e) {
            // Error handling for LWC.  Also a nice place to store a log ;)
            System.debug('Error in formatResult: ' + e.getMessage());
            throw new AuraHandledException('Unable to format pricing results: ' + e.getMessage());
        }
    }

    /**
     * Centralized query method for pricing matrix data
     *
     * @param country Filter parameter for country
     * @param productType Filter parameter for product type
     * @return List of matching Pricing_Matrix__c records
     */
    public static List<Pricing_Matrix__c> queryPricingMatrix(String country, String productType) {
        return [
                SELECT Id, Country__c, Product__c, Amount__c, Currency__c, Pricing_Type__c, Service_Type__c
                FROM Pricing_Matrix__c
                WHERE Country__c = :country
                AND Product__c = :productType
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 50
        ];
    }

    /**
     * Maps currency names to their corresponding symbols
     *
     * Maintenance Note: Consider replacing with Custom Metadata Type for easier internationalization support.
     *
     * @param currencyValue Currency name from the database
     * @return Currency symbol or formatted currency name
     */
    @TestVisible
    private static String mapCurrency(String currencyValue) {
        if (String.isEmpty(currencyValue)) {
            return '';
        }

        switch on currencyValue {
            when 'British Pound' {
                return '£';
            }
            when 'Euro' {
                return '€';
            }
            when else {
                // Fallback: return original value with space for consistent formatting
                return currencyValue + ' ';
            }
        }
    }

    /**
     * Retrieves active picklist values for Service_Type__c field.Automatically adapts to picklist changes without code deployment
     *
     * @return List<String> for Pricing_Matrix__c.Service_Type__c picklist values
     */
    private static List<String> getServiceTypePicklistValues() {
        List<String> picklistValues = new List<String>();

        try {
            // Schema introspection for dynamic picklist value retrieval
            Schema.DescribeFieldResult fieldResult = Pricing_Matrix__c.Service_Type__c.getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

            // Filter for active values only - inactive values won't appear in UI
            for (Schema.PicklistEntry entry : picklistEntries) {
                if (entry.isActive()) {
                    picklistValues.add(entry.getValue());
                }
            }
        } catch (Exception e) {
            // Soft error handling. Empty list will be return but the log should be store
            // Replace the system debug for a proper log
            System.debug('Error retrieving Service_Type__c picklist values: ' + e.getMessage());
        }

        return picklistValues;
    }
}