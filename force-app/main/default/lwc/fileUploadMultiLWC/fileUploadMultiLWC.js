import {LightningElement,api,track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import uploadFiles from '@salesforce/apex/FileUploadMultiController.uploadFiles'
const MAX_FILE_SIZE = 2097152;

export default class FileUploadMultiLWC extends LightningElement {

    //@api recordId;
    @track filesData = [];
    showSpinner = false;
    error;

    handleFileUploaded(event) {
        if (event.target.files.length > 0) {
            for(var i=0; i< event.target.files.length; i++){
                if (event.target.files[i].size > MAX_FILE_SIZE) {
                    this.showToast('Error!', 'error', 'File size exceeded the upload size limit.');
                    return;
                }
                let file = event.target.files[i];
                let reader = new FileReader();
                reader.onload = e => {
                    var fileContents = reader.result.split(',')[1]
                    this.filesData.push({'fileName':file.name, 'fileContent':fileContents});
                };
                reader.readAsDataURL(file);
            }
        }
    }

    uploadFiles() {
        this.error = undefined;
        if(this.filesData == [] || this.filesData.length == 0) {
            this.error = "A file must be uploaded to save."; return;
        }
        this.dispatchEvent(new CustomEvent('uploadfiles',
        {
            detail: JSON.stringify(this.filesData)
        }));
    }

    removeReceiptImage(event) {
        var index = event.currentTarget.dataset.id;
        this.filesData.splice(index, 1);
    }

    showToast(title, variant, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                variant: variant,
                message: message,
            })
        );
    }
}