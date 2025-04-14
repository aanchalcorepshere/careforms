import { LightningElement, track, api} from 'lwc';

export default class DocCollectionPublic extends LightningElement {
    currentFileName = '';
    currentDescription = '';
    currentFile;
    currentFileUploadName = '';
    currentDocType = '';
    @track docList = [];
    error;
    @api existingDocuments;

    connectedCallback(){
        if(this.existingDocuments && this.existingDocuments.length){
            this.docList = JSON.parse(JSON.stringify(this.existingDocuments));

            this.dispatchEvent(new CustomEvent('docsupload',
            {
                bubbles: true, composed: true, detail: this.docList
            }));
        }
    }
    
    get noFileUploaded(){
        return this.docList.length == 0;
    }

    handleInput(event){
        let inputName = event.target.name;
        let inputValue = event.target.value;
        console.log('inputName >> ',inputName);
        if(inputName == 'filename'){
            this.currentFileName = inputValue;
        }else if(inputName == 'description'){
            this.currentDescription = inputValue;
        }
    }

    handleUploadFile(event){
        //const file = event.target.files[0];
        let file = event.target.files[0];
        let reader = new FileReader();
        reader.onload = e => {
            var fileContents = reader.result.split(',')[1]
            this.currentFile = fileContents;
            //this.filesData.push({'fileName':file.name, 'fileContent':fileContents});
        };
        reader.readAsDataURL(file);
        this.currentFileUploadName = file.name;
        this.currentDocType = file.type;
    }

    handleUploadButton(){
        let enteriesValid = this.validateEnteries();
        if(enteriesValid){
            let doc = {};
            doc.fileName = this.currentFileName;
            doc.description = this.currentDescription;
            doc.fileContent = this.currentFile;
            doc.fileUploadName = this.currentFileUploadName;
            if(this.currentDocType == 'application/pdf'){
                doc.fileTypeIcon = 'doctype:pdf';
            }else if(this.currentDocType == 'text/plain'){
                doc.fileTypeIcon = 'doctype:txt';
            }else if(this.currentDocType == 'image/jpeg' || this.currentDocType == 'image/png'){
                doc.fileTypeIcon = 'doctype:image';
            }
            doc.index = this.docList.length+1;
            this.docList.push(doc);
            this.currentFileName = '';
            this.currentDescription = '';
            this.currentFile = undefined;
            this.currentFileUploadName = '';
            this.currentDocType == ''

            this.dispatchEvent(new CustomEvent('docsupload',{
                detail: this.docList
            }));
        }
    }

    validateEnteries(){
        let valid = true;
        if(!this.currentFileName.length){
            valid = false;
            this.error = 'Enter file name.';
        }if(!this.currentFile){
            valid = false;
            this.error = 'Please upload file.';
        }else{
            this.error = undefined;
        }

        return valid;
    }

    handleDelete(event){
        let deleteIndex = event.currentTarget.dataset.id;
        this.docList.splice(deleteIndex-1,1);
        this.resetIndex();
    }

    resetIndex(){
        if(this.docList.length){
            let index = 1;
            this.docList.forEach(doc => {
                doc.index = index;
                index++;
            })
        }
    }
}