const FALLBACK = "An unexpected error occurred. Please try again.";

/**
 * Extracts a single user-facing string from an LWC imperative/wire Apex error.
 */
export function getApexErrorMessage(error) {
    if (error == null) {
        return FALLBACK;
    }
    if (typeof error === "string") {
        return error;
    }
    if (error.body) {
        if (Array.isArray(error.body)) {
            return error.body
                .map((row) => row?.message || String(row))
                .filter(Boolean)
                .join("; ");
        }
        if (error.body.message != null) {
            if (Array.isArray(error.body.message)) {
                return error.body.message.filter(Boolean).join("; ");
            }
            if (typeof error.body.message === "string") {
                return error.body.message;
            }
        }
        if (error.body.pageErrors && error.body.pageErrors.length) {
            return error.body.pageErrors
                .map((e) => e?.message)
                .filter(Boolean)
                .join("; ");
        }
        const outputErrors = error.body.output?.errors;
        if (outputErrors && outputErrors.length) {
            return outputErrors
                .map((e) => e?.message)
                .filter(Boolean)
                .join("; ");
        }
    }
    if (error.message) {
        return error.message;
    }
    return FALLBACK;
}