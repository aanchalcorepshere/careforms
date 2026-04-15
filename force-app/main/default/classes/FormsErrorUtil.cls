/**
 * User-facing error strings for Forms Apex and LWC clients.
 * Avoids exposing raw DML prefixes and stack-oriented exception text.
 */
public with sharing class FormsErrorUtil {
    public static final String GENERIC_SAVE_MESSAGE =
        'A record could not be saved. Please review your entries and try again.';

    /**
     * Message safe to show in Aura/LWC from any server exception.
     */
    public static String messageForClient(Exception e) {
        if (e == null) {
            return GENERIC_SAVE_MESSAGE;
        }
        if (e instanceof AuraHandledException) {
            return e.getMessage();
        }
        if (e instanceof DmlException) {
            return userMessageFromDmlException((DmlException) e);
        }
        if (e instanceof SecurityException) {
            return e.getMessage() != null ? e.getMessage() : GENERIC_SAVE_MESSAGE;
        }
        if (e.getMessage() != null && !isLikelyInternalExceptionMessage(e.getMessage())) {
            return e.getMessage();
        }
        return GENERIC_SAVE_MESSAGE;
    }

    public static String userMessageFromDatabaseError(Database.Error err, String objectApiName) {
        if (err == null) {
            return GENERIC_SAVE_MESSAGE;
        }
        return buildUserMessage(err.getStatusCode(), err.getFields(), err.getMessage(), objectApiName);
    }

    public static String userMessageFromDmlException(DmlException dmx) {
        if (dmx == null || dmx.getNumDml() == 0) {
            return GENERIC_SAVE_MESSAGE;
        }
        // getDmlType returns StatusCode; getDmlStatusCode returns a String (name) — do not confuse.
        return buildUserMessage(
            dmx.getDmlType(0),
            fieldApiNamesFromDmlException(dmx, 0),
            dmx.getDmlMessage(0),
            null
        );
    }

    /**
     * Prefer getDmlFieldNames (API names); fall back to tokens from getDmlFields.
     */
    public static List<String> fieldApiNamesFromDmlException(DmlException dmx, Integer idx) {
        List<String> fromNames = dmx.getDmlFieldNames(idx);
        if (fromNames != null && !fromNames.isEmpty()) {
            return fromNames;
        }
        return fieldApiNamesFromDmlFieldTokens(dmx.getDmlFields(idx));
    }

    private static List<String> fieldApiNamesFromDmlFieldTokens(List<Schema.SObjectField> tokens) {
        List<String> apis = new List<String>();
        if (tokens == null) {
            return apis;
        }
        for (Schema.SObjectField tok : tokens) {
            if (tok != null) {
                apis.add(tok.getDescribe().getName());
            }
        }
        return apis;
    }

    private static Boolean isLikelyInternalExceptionMessage(String msg) {
        if (String.isBlank(msg)) {
            return true;
        }
        String lower = msg.toLowerCase();
        return lower.contains('unexpected token') || lower.contains('null pointer') || lower.contains('caused by:');
    }

    private static String buildUserMessage(
        System.StatusCode code,
        List<String> fields,
        String rawMessage,
        String objectApiName
    ) {
        String fieldPhrase = formatFieldListPhrase(fields, objectApiName);

        if (code == System.StatusCode.REQUIRED_FIELD_MISSING) {
            if (String.isBlank(fieldPhrase)) {
                return 'A required field is missing.';
            }
            if (fieldPhrase.contains(' and ')) {
                return fieldPhrase + ' are required.';
            }
            return fieldPhrase + ' is required.';
        }

        if (code == System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
            String cleaned = stripStatusCodePrefix(rawMessage, code);
            if (String.isNotBlank(cleaned)) {
                return cleaned;
            }
            return 'This record does not meet validation requirements.';
        }

        if (code == System.StatusCode.INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST) {
            String cleaned = stripStatusCodePrefix(rawMessage, code);
            if (String.isNotBlank(cleaned)) {
                return cleaned;
            }
            if (String.isNotBlank(fieldPhrase)) {
                return 'Choose a valid value for ' + fieldPhrase + '.';
            }
            return 'Choose a valid value for the selected field.';
        }

        if (code == System.StatusCode.DUPLICATE_VALUE || code == System.StatusCode.DUPLICATES_DETECTED) {
            String cleaned = stripStatusCodePrefix(rawMessage, code);
            return String.isNotBlank(cleaned) ? cleaned : 'A duplicate value was found.';
        }

        if (code == System.StatusCode.FIELD_INTEGRITY_EXCEPTION) {
            String cleaned = stripStatusCodePrefix(rawMessage, code);
            return String.isNotBlank(cleaned) ? cleaned : GENERIC_SAVE_MESSAGE;
        }

        if (code == System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY) {
            String cleaned = stripStatusCodePrefix(rawMessage, code);
            return String.isNotBlank(cleaned) ? cleaned : GENERIC_SAVE_MESSAGE;
        }

        if (code == System.StatusCode.INVALID_ID_FIELD) {
            return 'An invalid record identifier was supplied.';
        }

        if (code == System.StatusCode.STRING_TOO_LONG) {
            String cleaned = stripStatusCodePrefix(rawMessage, code);
            return String.isNotBlank(cleaned) ? cleaned : 'Text entered is too long for one of the fields.';
        }

        String fallback = stripStatusCodePrefix(rawMessage, code);
        return String.isNotBlank(fallback) ? fallback : GENERIC_SAVE_MESSAGE;
    }

    private static String stripStatusCodePrefix(String rawMessage, System.StatusCode code) {
        if (String.isBlank(rawMessage) || code == null) {
            return rawMessage;
        }
        String codeStr = String.valueOf(code);
        if (rawMessage.length() > codeStr.length() + 1 && rawMessage.substring(0, codeStr.length()).equalsIgnoreCase(codeStr)) {
            String sep = rawMessage.substring(codeStr.length(), codeStr.length() + 1);
            if (sep == ':' || sep == ',') {
                return rawMessage.substring(codeStr.length() + 1).trim();
            }
        }
        String prefixColon = codeStr + ':';
        if (rawMessage.startsWithIgnoreCase(prefixColon)) {
            return rawMessage.substring(prefixColon.length()).trim();
        }
        String prefixCommaSpace = codeStr + ', ';
        if (rawMessage.startsWithIgnoreCase(prefixCommaSpace)) {
            return rawMessage.substring(prefixCommaSpace.length()).trim();
        }
        return rawMessage.trim();
    }

    private static String formatFieldListPhrase(List<String> fields, String objectApiName) {
        if (fields == null || fields.isEmpty()) {
            return null;
        }
        List<String> labels = new List<String>();
        for (String api : fields) {
            if (String.isBlank(api)) {
                continue;
            }
            labels.add(fieldLabel(objectApiName, api));
        }
        if (labels.isEmpty()) {
            return null;
        }
        if (labels.size() == 1) {
            return labels[0];
        }
        if (labels.size() == 2) {
            return labels[0] + ' and ' + labels[1];
        }
        String tail = labels[labels.size() - 1];
        List<String> head = new List<String>();
        for (Integer i = 0; i < labels.size() - 1; i++) {
            head.add(labels[i]);
        }
        return String.join(head, ', ') + ', and ' + tail;
    }

    private static String fieldLabel(String objectApiName, String fieldApi) {
        if (String.isBlank(fieldApi)) {
            return fieldApi;
        }
        if (String.isBlank(objectApiName)) {
            return humanizeApiName(fieldApi);
        }
        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (!gd.containsKey(objectApiName)) {
                return humanizeApiName(fieldApi);
            }
            Map<String, Schema.SObjectField> fm = gd.get(objectApiName).getDescribe().fields.getMap();
            if (!fm.containsKey(fieldApi)) {
                return humanizeApiName(fieldApi);
            }
            return fm.get(fieldApi).getDescribe().getLabel();
        } catch (Exception e) {
            return humanizeApiName(fieldApi);
        }
    }

    private static String humanizeApiName(String api) {
        if (String.isBlank(api)) {
            return api;
        }
        String s = api.replace('__c', '').replace('__r', '');
        return s.replace('_', ' ');
    }
}