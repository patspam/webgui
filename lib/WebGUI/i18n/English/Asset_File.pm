package WebGUI::i18n::English::Asset_File;

our $I18N = {
	'file add/edit title' => {
		message => q|File, Add/Edit|,
        	lastUpdated => 1106683494,
	},

	'file add/edit body' => {
                message => q|<P>File Assets are files on your site that are available for users to download. If you would like to have multiple files available, try using a FilePile Asset.</P>

<P>Since Files are Assets, so they have all the properties that Assets do.  Below are the properties that are specific to Image Assets:</P>

|,
		context => 'Describing file add/edit form specific fields',
		lastUpdated => 1119068839,
	},
	'file template title' => {
		message => q|File, Template|,
        	lastUpdated => 1109287565,
	},

	'file template body' => {
                message => q|<p>The following variables are available in File Templates:</p>

<P><b>fileIcon</b><br/>
The icon which describes the type of file.

<P><b>fileUrl</b><br/>
The URL to the file.

<P><b>controls</b><br/>
A toolbar for working with the file.

<P><b>filename</b><br/>
The name of the file.

<P><b>storageId</b><br/>
The internal storage ID used for the file.

<P><b>title</b><br/>
The title set for the file when it was uploaded, or the filename if none was entered.

<P><b>menuTitle</b><br/>
The menu title, displayed in navigations, set for the file when it was uploaded, or the filename if none was entered.

		|,
		context => 'Describing the file template variables',
		lastUpdated => 1130439830,
	},


	'current file' => {
		message => q|Current file|,
		context => q|label for File asset form|,
		lastUpdated => 1106762086
	},

	'current file description' => {
		message => q|If this Asset already contains a file, a link to the file with its associated icon will be shown.|,
		lastUpdated => 1119068809
	},


	'new file' => {
		message => q|New file to upload|,
		context => q|label for File asset form|,
		lastUpdated => 1106762088
	},

        'assetName' => {
                message => q|File|,
                context => q|label for Asset Manager, getName|,
                lastUpdated => 1128640132,
        },
                                                                                                                              
	'new file description' => {
		message => q|Enter the path to a file, or use the "Browse" button to find a file on your local hard drive that you would like to be uploaded.|,
		lastUpdated => 1119068745
	},


};

1;
