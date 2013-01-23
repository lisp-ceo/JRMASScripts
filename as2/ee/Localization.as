/**
 * Localization
 * load appropriate paths and set security permissions
 *
 * @author		Ryan Quigley
 * @version		1.0.0
 *
 * 08.14.08 (1.0.0) - First version
 */

/*


TODO:
-

Usage:

import ee.Localization;

myLoc = ee.Localization.getInstance();
myLoc.load(SiteUrls.site + "c_locale", {onComplete:myFunction});

function myFunction()
{
	myLoc = ee.Localization.getInstance();
	myLoc.t("back_to_list");

	var korean_url:String = myLoc.getLocaleUrl("ko");
	var current_locale:String = myLoc.getCurrentLocale();
}

*/

import ee.utils.AssetLoader;
import ee.utils.Proxy;

class ee.Localization
{
	private static var _instance:Localization = null;

	private var _vars:Object
	private var _onComplete:Function;

	private var _locales:Object;
	private var _locale:String;

	private var _lv:LoadVars;

	private function Localization() {}
	
	public static function getInstance():Localization
	{
		if (_instance == null) {
			Localization._instance = new Localization();
		}
		
		return Localization._instance;
	}
	
	public function load(myUrl:String, p_vars:Object)
	{
		_vars = p_vars;

		_onComplete = p_vars.onComplete;

		_lv = new LoadVars();
		AssetLoader.loadLoadVars(_lv, myUrl, {onComplete:Proxy.create(this, doneLoading)});	
	}
	
	private function doneLoading():Void
	{
		if (_onComplete) {
			_onComplete();
		}
	}
	
	public function getCurrentLocale():String
	{
		if (_lv.locale_current) {
			return _lv.locale_current;

		} else {
			trace('ee.Localization: current locale not defined.');

			return '';
		}
	}

	public function getLocaleUrl(locale_identifier):String
	{
		if (_lv['locale_url_' + locale_identifier]) {
			return _lv['locale_url_' + locale_identifier];

		} else {
			trace('ee.Localization: locale identifier "' + locale_identifier + '" does not exist.');
		}
	}
	
	public function t(i:String):String
	{
		if (_lv[i]) {
			return _lv[i];

		} else {
			trace('ee.Localization: translation for "' + i + '" does not exist.');

			return "INVALID";
		}
	}
	
}