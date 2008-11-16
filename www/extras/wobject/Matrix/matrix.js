var myCompareTable;

YAHOO.util.Event.addListener(window, "load", function() {
    YAHOO.example.XHR_JSON = new function() {
        this.formatUrl = function(elCell, oRecord, oColumn, sData) {
            elCell.innerHTML = "<a href='" + oRecord.getData("ClickUrl") + "' target='_blank'>" + sData + "</a>";
        };

	this.formatCheckBox = function(elCell, oRecord, oColumn, sData) {
            elCell.innerHTML = "<input type='checkbox' name='listingId' value='" + sData + "'>";
        };

        var myColumnDefs = [
	    {key:"assetId",label:"",sortable:false,formatter:this.formatCheckBox},
            {key:"title", label:"Name", sortable:true, formatter:this.formatUrl},
            {key:"views", sortable:true},
            {key:"clicks", sortable:true},
            {key:"compares", sortable:true}
        ];

        this.myDataSource = new YAHOO.util.DataSource("?");
        this.myDataSource.responseType = YAHOO.util.DataSource.TYPE_JSON;
        this.myDataSource.connXhrMode = "queueRequests";
        this.myDataSource.responseSchema = {
            resultsList: "ResultSet.Result",
            fields: ["title","views","clicks","compares","assetId"]
        };

        this.myDataTable = new YAHOO.widget.DataTable("compareForm", myColumnDefs,
                this.myDataSource, {initialRequest:"func=getCompareFormData"});

	var oColumn = this.myDataTable.getColumn(3);
	this.myDataTable.hideColumn(oColumn); 


	var btnAddRows = new YAHOO.widget.Button("hidecolumn");
        btnAddRows.on("click", function(e) {

            //var oColumn = this.myDataTable.getColumn(3);
	    this.myDataTable.sortColumn(oColumn); 
        },this,true);


        var myCallback = function() {
            this.set("sortedBy", null);
            this.onDataReturnAppendRows.apply(this,arguments);
        };
	
    };
});

//function sort() {
//	myCompareTable.sortColumn()
//	var oColumn = myCompareTable.getColumn(3);
//	myCompareTable.hideColumn(oColumn); 
//}

function bla() {
        var callback1 = {
            success : myCallback,
            failure : myCallback,
            scope : this.myDataTable
        };
        this.myDataSource.sendRequest("func=getCompareFormData",
                callback1);

        var callback2 = {
            success : myCallback,
            failure : myCallback,
            scope : this.myDataTable
        };
        this.myDataSource.sendRequest("func=getCompareFormData",
                callback2);
}