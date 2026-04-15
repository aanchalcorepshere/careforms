import { LightningElement, wire, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getFormsFeatureGate from "@salesforce/apex/FormsFeatureUtil.getFormsFeatureGate";
import getPrintJson from "@salesforce/apex/FormsController.getPrintJson";
import { getApexErrorMessage } from "c/formsErrorUtils";

export default class FormsPrintUtil extends LightningElement {
  @api recordId;
  @api formId;
  @api objectApi;
  @api isApplication = false;
  pageData;
  forPrint = true;
  error;
  signatureImgSrc;
  formResult;
  isLoading = false;
  signatureText;

  featureGateReady = false;
  formsFeatureGate;
  _printLoadKey;

  @wire(getFormsFeatureGate)
  wiredFeatureGate(result) {
    const { data, error } = result;
    if (data) {
      this.formsFeatureGate = data;
      this.featureGateReady = true;
      this.tryLoadPrintJson();
    } else if (error) {
      this.formsFeatureGate = {
        formsEnabled: false,
        unavailableMessage:
          "Unable to verify Forms availability. Please refresh the page or contact your administrator."
      };
      this.featureGateReady = true;
    }
  }

  renderedCallback() {
    this.tryLoadPrintJson();
  }

  tryLoadPrintJson() {
    if (
      !this.featureGateReady ||
      !this.formsFeatureGate ||
      this.formsFeatureGate.formsEnabled === false ||
      !this.recordId ||
      !this.formId
    ) {
      return;
    }
    const key = `${this.recordId}_${this.formId}`;
    if (this._printLoadKey === key) {
      return;
    }
    this._printLoadKey = key;
    this.isLoading = true;
    getPrintJson({ recordId: this.recordId, printJsonTitle: this.formId })
      .then((result) => {
        if (result.pageData) {
          this.pageData = JSON.parse(result.pageData);
          if (result.signature) {
            this.signatureImgSrc =
              "/sfc/servlet.shepherd/version/download/" + result.signature;
            if (result.signatureText) {
              this.signatureText = result.signatureText;
            }
          }
          this.isLoading = false;
        } else {
          this.error = "Form print data not available for this record.";
          this.isLoading = false;
        }
      })
      .catch((error) => {
        this.error = getApexErrorMessage(error);
        this.isLoading = false;
      });
  }

  handlePrint() {
    window.print();
  }

  get featureGateLoading() {
    return !this.featureGateReady;
  }

  get showFormsUnavailable() {
    return (
      this.featureGateReady &&
      this.formsFeatureGate &&
      this.formsFeatureGate.formsEnabled === false
    );
  }

  get showPrintShell() {
    return (
      this.featureGateReady &&
      this.formsFeatureGate &&
      this.formsFeatureGate.formsEnabled === true
    );
  }

  get formsUnavailableMessage() {
    return this.formsFeatureGate ? this.formsFeatureGate.unavailableMessage : "";
  }

  get isApplication() {
    return this.objectApi == "Referral__c";
  }
}