package WebGUI::i18n::English::Asset_RSSFromParent;
use strict;

our $I18N =
{
 'assetName' => { message => 'RSS From Parent', lastUpdated => 1162257377 },

	'rss from parent title' => {
		message => 'RSS From Parent',
		lastUpdated => 1162257377
	},

	'rss from parent body' => {
		message => q|<p>The sole purpose of this Asset is to provide a base template for generating RSS Feeds.  Below are listed the basic template variables available to any valid RSS generating Asset.  Assets may provide additional or different variables.</p>|,
		lastUpdated => 1162257377
	},

	'title.parent' => {
		message => 'The title of the parent of this Asset',
		lastUpdated => 1162257377
	},

	'title.item' => {
		message => 'The title of this Asset',
		lastUpdated => 1162257377
	},

	'link' => {
		message => 'link',
		lastUpdated => 1162257377
	},

	'link.parent' => {
		message => 'The url of the parent of this Asset',
		lastUpdated => 1162257377
	},

	'link.item' => {
		message => 'The url of this Asset',
		lastUpdated => 1162257377
	},

	'description' => {
		message => 'description',
		lastUpdated => 1162257377
	},

	'description.parent' => {
		message => 'The description of the parent of this Asset',
		lastUpdated => 1162257377
	},

	'description.item' => {
		message => 'The description of this Asset',
		lastUpdated => 1162257377
	},

	'generator' => {
		message => 'A string that identifies that this RSS was generated by WebGUI and also by what version of WebGUI.',
		lastUpdated => 1162257377
	},

	'lastBuildDate' => {
		message => q|The date the parent's content was last modified in the proper format for RSS (RFC 822).|,
		lastUpdated => 1162257377
	},

	'webMaster' => {
		message => q|The company email address from the WebGUI Settings.|,
		lastUpdated => 1162257377
	},

	'docs' => {
		message => q|The URL http://blogs.law.harvard.edu/tech/rss, which links to the RSS 2.0 specification.|,
		lastUpdated => 1162257377
	},

	'item_loop' => {
		message => q|A loop containing information about all Assets below the parent.|,
		lastUpdated => 1162957711
	},

	'guid' => {
		message => q|An alias for link.  In RSS, guid is the unique identifier for this item.|,
		lastUpdated => 1162957711
	},

	'pubDate' => {
		message => q|The date this item was last modified in the proper format for RSS (RFC 822).|,
		lastUpdated => 1162958127
	},

};

1;