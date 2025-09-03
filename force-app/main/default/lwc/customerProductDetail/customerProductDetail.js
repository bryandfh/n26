import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import formatResult from '@salesforce/apex/ProductPricingController.formatResult';

// Case fields
import CASE_CONTACT_ID_FIELD from '@salesforce/schema/Case.ContactId';

// Contact fields
import CONTACT_PRODUCT_FIELD from '@salesforce/schema/Contact.Product__c';
import CONTACT_HOME_COUNTRY_FIELD from '@salesforce/schema/Contact.Home_Country__c';

const CASE_FIELDS = [CASE_CONTACT_ID_FIELD];
const CONTACT_FIELDS = [CONTACT_PRODUCT_FIELD, CONTACT_HOME_COUNTRY_FIELD];

export default class CustomerProductDetail extends LightningElement {
    @api recordId; // Case record ID from the page context

    columns = [
        {
            label: 'Type',
            fieldName: 'Service_Type__c',
            type: 'text',
            hideDefaultActions: true
        },
        {
            label: 'Value',
            fieldName: 'formattedAmount',
            type: 'text',
            cellAttributes: { alignment: 'center' },
            hideDefaultActions: true
        }
    ];

    tableData = [];
    isLoading = true;
    error;
    contactId;
    contactData;
    formattedPricingData = {};

    // Get Case record data to retrieve ContactId
    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    caseRecord({ error, data }) {
        if (data) {
            this.contactId = getFieldValue(data, CASE_CONTACT_ID_FIELD);
        } else if (error) {
            this.error = error;
            this.isLoading = false;
            console.error('Error loading case record:', error);
        }
    }

    // Get Contact record data using the ContactId from Case
    @wire(getRecord, { recordId: '$contactId', fields: CONTACT_FIELDS })
    contactRecord({ error, data }) {
        if (data) {
            this.contactData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contactData = null;
            this.isLoading = false;
            console.error('Error loading contact record:', error);
        }
    }

    get contactProduct() {
        return this.contactData ? getFieldValue(this.contactData, CONTACT_PRODUCT_FIELD) : null;
    }

    get contactHomeCountry() {
        return this.contactData ? getFieldValue(this.contactData, CONTACT_HOME_COUNTRY_FIELD) : null;
    }

    // Load formatted pricing data when contact data is available
    @wire(formatResult, {
        country: '$contactHomeCountry',
        productType: '$contactProduct'
    })
    wiredFormattedPricing({ error, data }) {
        if (data) {
            this.formattedPricingData = data;
            this.error = undefined;
            this.buildTableData();
        } else if (error) {
            this.error = error;
            this.formattedPricingData = {};
            console.error('Error loading formatted pricing data:', error);
            this.buildTableData();
        }
    }

    buildTableData() {
        // Only build table data if we have all required data loaded
        if (!this.contactId || !this.contactData) {
            this.tableData = [];
            return;
        }

        this.isLoading = true;

        // Convert the formatted pricing data map to table data
        this.tableData = [];

        if (Object.keys(this.formattedPricingData).length > 0) {
            let index = 0;
            for (const [serviceType, formattedValue] of Object.entries(this.formattedPricingData)) {
                this.tableData.push({
                    id: `row-${index}`,
                    Service_Type__c: serviceType,
                    formattedAmount: formattedValue || 'N/A'
                });
                index++;
            }
        }

        // Sort data by Service Type
        this.tableData.sort((a, b) =>
            a.Service_Type__c.localeCompare(b.Service_Type__c)
        );

        this.isLoading = false;
    }
}