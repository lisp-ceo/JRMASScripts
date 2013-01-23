/**
 * SiteUrls
 * load appropriate paths and set security permissions
 *
 * @author		Ryan Quigley
 * @version		1.0.1
 *
 * 04.10.08 (1.0.0) - First version
 * 04.11.08 (1.0.1) - LoadPolicyFile needed on fileserver for bitmap effects
 * 06.12.08 (1.1.0) - refactor ExternalInterface calls
 */

/*


TODO:
-

Usage:

import ee.SiteUrls;

Basic:

if you intend to test in the flash IDE (optional):
trace(SiteUrls.defineDevUrls('http://lissongallery.dev/')); // wrapped to prevent sync issues - DISABLE TRACE ON PRODUCTION SYNC

if you are using SWFAdress or similar and need early acccess to urls (before requesting them statically) (optional):
SiteUrls.forceSetup(); // use this 


otherwise:
SiteUrls.site
SiteUrls.assets
SiteUrls.files

can be used at will:
_data_loader.load(SiteUrls.site + "c_artists/");

AssetLoader.loadMovie(test_mc.i_mc, SiteUrls.files+eeV.home.filename);
*/


import flash.external.*;

class ee.SiteUrls
{
	private static var _using_dev_urls = false;		// allow html override, even if publishing with dev urls
	private static var _inited = false;		// only allow _setup to be fired once

	private static var _site = 'undefined';
	private static var _assets = 'undefined';
	private static var _files = 'undefined';

	private static var _available:Boolean = ExternalInterface.available;
	
	private static function _setup():Void
	{
		var urls = ExternalInterface.call('SiteUrls.getUrls');
		
		if (!urls) {
			trace("SiteUrls: ExternalInterface call failure");
			return;
		}

		SiteUrls._site = urls.site;
		SiteUrls._assets = urls.assets;
		SiteUrls._files = urls.files;
		
		SiteUrls._securityAllow();
	}
	
	private static function _securityAllow():Void
	{
		System.security.allowDomain(SiteUrls.extractUrl(SiteUrls._site));
		System.security.allowDomain(SiteUrls.extractUrl(SiteUrls._assets));
		System.security.allowDomain(SiteUrls.extractUrl(SiteUrls._files));

		// to allow bitmap effects
		//System.security.loadPolicyFile(SiteUrls.extractUrl(SiteUrls._files, true) + '/crossdomain.xml');

		// make sure we don't run this again
		SiteUrls._inited = true;
	}
	
	public static function forceSetup():Void
	{
		if (SiteUrls._inited === false) {
			SiteUrls._setup();
		}
	}
	
	public static function defineDevUrls(site, site_url):String
	{
		SiteUrls._using_dev_urls = true;

		SiteUrls._site = site_url;
		SiteUrls._assets = 'http://asset_server.dev/' + site + '/site/';
		SiteUrls._files = 'http://image_server.dev/' + site + '/';
		
		SiteUrls._securityAllow();

		trace("\n\n!!!DISABLE TRACING BEFORE SYNC!!!\n");

		return ''; // avoid an "undefined" on output
	}

	public static function get site():String
	{
		if (SiteUrls._inited === false) {
			SiteUrls._setup();
		}
		return _site;
	}
	public static function get assets():String
	{
		if (SiteUrls._inited === false) {
			SiteUrls._setup();
		}
		return _assets;
	}
	public static function get files():String
	{
		if (SiteUrls._inited === false) {
			SiteUrls._setup();
		}
		return _files;
	}

	private static function extractUrl(str:String, keep_URI:Boolean):String
	{
		if (str == '/') {
			return '/';
		}

		if (keep_URI === true) {
			var strPos:Number = str.indexOf('://');
			str = str.substr(0, str.indexOf('/', strPos+3));

		} else {
			if (str.indexOf('http://')) {
				str = str.substr(6);
			} else if (str.indexOf('https://')) {
				str = str.substr(7);
			}

			str = str.substr(0, str.indexOf('/'));
		}
		
		return str;
	}
}