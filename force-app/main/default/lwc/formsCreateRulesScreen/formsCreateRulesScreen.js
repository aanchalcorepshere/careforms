import { LightningElement, track, api } from 'lwc';

export default class FormsCreateRulesScreen extends LightningElement {
    @track rules = [
        {
            ruleId: 'rid_1',
            ruleIndex: 0,
            ruleName: 'Rule 1',
            primaryField: '',
            secondaryField: '',
            value: '',
            operator: '',
            dependentType: '',
            required: false
        }
    ];

    @api pageData;
    @api existingRules;
    primaryFieldList = [];
    secondaryFieldList = [];
    nextRuleId = 2;

    newRuleId() {
        return `rid_${this.nextRuleId++}`;
    }

    ensureRuleIds() {
        this.rules.forEach((rule) => {
            if (rule.ruleId == null || rule.ruleId === '') {
                rule.ruleId = this.newRuleId();
            }
        });
        this.syncNextRuleIdFromRuleIds();
    }

    syncNextRuleIdFromRuleIds() {
        let maxSeq = 0;
        this.rules.forEach((rule) => {
            const match = /^rid_(\d+)$/.exec(String(rule.ruleId || ''));
            if (match) {
                maxSeq = Math.max(maxSeq, parseInt(match[1], 10));
            }
        });
        if (maxSeq > 0) {
            this.nextRuleId = Math.max(this.nextRuleId, maxSeq + 1);
        }
    }

    reindexRules() {
        this.rules.forEach((rule, idx) => {
            rule.ruleIndex = idx;
            rule.ruleName = `Rule ${idx + 1}`;
        });
    }

    connectedCallback() {
        let rawPrimaryFieldList = [];
        let rawSecondaryFieldList = [];
        this.pageData.forEach((page) => {
            page.sections.forEach((section) => {
                section.fields.forEach((field) => {
                    if (field.fieldData.fieldName) {
                        if (!field.fieldData.isQuestion) {
                            if (!section.isSectionMulti) {
                                this.primaryFieldList.push({
                                    label: field.fieldData.fieldUniqueName,
                                    value: field.fieldData.fieldUniqueName
                                });
                                rawPrimaryFieldList.push(field.fieldData.fieldUniqueName);
                                this.secondaryFieldList.push({
                                    label: field.fieldData.fieldUniqueName,
                                    value: field.fieldData.fieldUniqueName
                                });
                                rawSecondaryFieldList.push(field.fieldData.fieldUniqueName);
                            }
                        } else {
                            if (!section.isSectionMulti) {
                                this.primaryFieldList.push({
                                    label: field.fieldData.fieldName,
                                    value: field.fieldData.fieldUniqueName
                                });
                                rawPrimaryFieldList.push(field.fieldData.fieldUniqueName);
                                this.secondaryFieldList.push({
                                    label: field.fieldData.fieldName,
                                    value: field.fieldData.fieldUniqueName
                                });
                                rawSecondaryFieldList.push(field.fieldData.fieldUniqueName);
                            }
                        }
                    }
                });
            });
        });
        if (this.existingRules) {
            let tempExisingRules = JSON.parse(JSON.stringify(this.existingRules));
            let filteredRuleList = [];
            if (tempExisingRules && tempExisingRules.length) {
                tempExisingRules.forEach((rule) => {
                    if (rule.dependentType == 'field') {
                        if (
                            rawPrimaryFieldList.includes(rule.primaryField) &&
                            rawSecondaryFieldList.includes(rule.secondaryField)
                        ) {
                            filteredRuleList.push(rule);
                        }
                    } else {
                        if (rawPrimaryFieldList.includes(rule.primaryField)) {
                            filteredRuleList.push(rule);
                        }
                    }
                });
            }

            if (filteredRuleList && filteredRuleList.length) {
                this.rules = filteredRuleList;
            }
        }
        this.ensureRuleIds();
        this.reindexRules();
    }

    addRule() {
        this.rules.push({
            ruleId: this.newRuleId(),
            ruleIndex: 0,
            ruleName: '',
            primaryField: '',
            secondaryField: '',
            value: '',
            operator: '',
            dependentType: '',
            required: false
        });
        this.reindexRules();
    }

    handleDeleteRule(event) {
        const ruleId = event.detail.ruleId;
        if (this.rules.length !== 1) {
            const idx = this.rules.findIndex((r) => r.ruleId === ruleId);
            if (idx >= 0) {
                this.rules.splice(idx, 1);
                this.reindexRules();
            }
        } else {
            this.rules[0].primaryField = undefined;
            this.rules[0].secondaryField = undefined;
            this.rules[0].value = undefined;
            this.rules[0].operator = undefined;
            this.rules[0].dependentType = undefined;
            this.rules[0].required = false;
        }
    }

    updateRuleData(event) {
        const ruleId = event.detail.ruleId;
        const rulePos = this.rules.findIndex((r) => r.ruleId === ruleId);
        if (rulePos < 0) {
            return;
        }
        if (event.detail.primaryField) {
            this.rules[rulePos].primaryField = event.detail.primaryField;
        }
        if (event.detail.secondaryField) {
            this.rules[rulePos].secondaryField = event.detail.secondaryField;
        }
        if (event.detail.value) {
            this.rules[rulePos].value = event.detail.value;
        }
        if (event.detail.operator) {
            this.rules[rulePos].operator = event.detail.operator;
        }
        if (event.detail.dependentType) {
            this.rules[rulePos].dependentType = event.detail.dependentType;
        }

        this.rules[rulePos].required = event.detail.required;

        this.dispatchEvent(
            new CustomEvent('rulesupdate', {
                detail: this.rules
            })
        );
    }
}