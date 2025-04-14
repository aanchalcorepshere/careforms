import { LightningElement, wire, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getPrintJson from "@salesforce/apex/FormsController.getPrintJson";

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

  connectedCallback() {
    console.log("isApplication >> " + this.isApplication);
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
        this.error = JSON.stringify(error);
        this.isLoading = false;
      });
  }

  handlePrint() {
    window.print();
  }

  get isApplication() {
    return this.objectApi == "Referral__c";
  }
}