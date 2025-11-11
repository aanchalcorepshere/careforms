// Utility class used to model and parse dynamic page data structures
// from JSON into Apex objects, often used for UI page configurations.
public class ParsePageData {

	// Represents the entire page data structure containing pages, sections, and fields
public class Fields {
    // Represents a set of record fields within a record
    public Integer recordIndex {get;set;}
    public List<RecordFields> recordFields {get;set;}
}

// Represents a section inside a page, holding fields and layout info
public class Sections {
    public Integer sectionIndex {get;set;}
    public String sectionName {get;set;}
    public Integer columns {get;set;}
    public Boolean isSectionMulti {get;set;}
    public List<Fields> fields {get;set;}
}

// Represents a page containing multiple sections
public class PageData {
    public Integer pageIndex {get;set;}
    public String pageName {get;set;}
    public List<Sections> sections {get;set;}
}

// Collection of all page data in the document
public List<PageData> pageData {get;set;}

// Represents an individual field's details and its input/content
public class RecordFields {
    public Integer fieldIndex {get;set;}
    public String fieldName {get;set;}
    public String inputValue {get;set;}
    public String content {get;set;}
    public Boolean isField {get;set;}
    public Boolean isRichTextBox {get;set;}
}


	// Deserializes a JSON string into a ParsePageData object structure.
	public static ParsePageData parse(String json) {
		return (ParsePageData) System.JSON.deserialize(json, ParsePageData.class);
	}
}