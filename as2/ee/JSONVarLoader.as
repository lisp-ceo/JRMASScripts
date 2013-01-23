/**
 * JSONVarLoader
 * load and decode JSON through 
 *
 * @author		Ryan Quigley
 * @version		1.0.0
 *
 * 11.14.08 (1.0.0) - First version
 */

/*


TODO:
-

Usage:

import ee.JSONVarLoader;

Basic:

JSONVarLoader.load("img_vars", onCompleteFunc);

JSONVarLoader.load("img_vars", onCompleteFunc, onFailureFunc);

*/


import flash.external.*;

class ee.JSONVarLoader
{

	public static var onCompleteFunc:Function;
	public static var onFailureFunc:Function;
	public static var js_vars_name:Function;

	public static var instance:JSONVarLoader;

	public static var player_props:Object;
	
	
	public static function load($js_vars_name, $onCompleteFunc, $onFailureFunc):Boolean
	{
		JSONVarLoader.js_vars_name = $js_vars_name;
		JSONVarLoader.onCompleteFunc = $onCompleteFunc;
		JSONVarLoader.onFailureFunc = $onFailureFunc;
		
		JSONVarLoader.player_props = JSONVarLoader.getPlayerProps();

		if (!ExternalInterface.available) {
			return false;
		}

		// Taken from SiFR 3 - Copyright 2006 – 2008 Mark Wubben, <http://novemberborn.net/>
		// Flash version older than 9,0,115 under IE incorrectly approach the Flash movie, breaking ExternalInterface.
	    // sIFR has a workaround, but this workaround cannot be applied until the Flash movie has been added to the document,
	    // which usually causes the ActionScript to run and set up ExternalInterface. Delaying for a couple milliseconds
	    // gives the JavaScript time to set up the workaround.
		if(JSONVarLoader.player_props.platform == 'WIN' && JSONVarLoader.player_props.version <= 9 && JSONVarLoader.player_props.release < 115) {
			var interval;
			interval = setInterval(
				function() {
					clearInterval(interval);
					JSONVarLoader.run();
				}, 200);
			return;
	    } else {
			JSONVarLoader.run();
		}
		
		return true;
	}
	
	private static function run():Void
	{
		var d = ExternalInterface.call('JSONVarLoader', JSONVarLoader.js_vars_name);
		
		if (d === null) {
			if (JSONVarLoader.onFailureFunc) {
				JSONVarLoader.onFailureFunc();
			}
			return;
		}
		JSONVarLoader.onCompleteFunc(d);
	}
	
	public static function getPlayerProps():Object
	{
		var obj:Object = new Object();

		var p = System.capabilities.version.split(' ');
		obj.platform = p[0];

		var o = p[1].split(',');
		obj.version = Number(o[0]);
		obj.build = Number(o[1]);
		obj.release = Number(o[2]);

		return obj;
	}
}