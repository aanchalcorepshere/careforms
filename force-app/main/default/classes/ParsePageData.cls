public class ParsePageData {

	public class Fields {
		public Integer recordIndex {get;set;}
		public List<RecordFields> recordFields {get;set;}
	}

	public class Sections {
		public Integer sectionIndex {get;set;}
		public String sectionName {get;set;}
        public Integer columns {get;set;}
		public Boolean isSectionMulti {get;set;}
		public List<Fields> fields {get;set;}
	}

	public class PageData {
		public Integer pageIndex {get;set;}
		public String pageName {get;set;}
		public List<Sections> sections {get;set;}
	}

	public List<PageData> pageData {get;set;}

	public class RecordFields {
		public Integer fieldIndex {get;set;}
		public String fieldName {get;set;}
		public String inputValue {get;set;}
		public String content {get;set;}
		public Boolean isField {get;set;}
		public Boolean isRichTextBox {get;set;}
	}

	
	public static ParsePageData parse(String json) {
		return (ParsePageData) System.JSON.deserialize(json, ParsePageData.class);
	}
}