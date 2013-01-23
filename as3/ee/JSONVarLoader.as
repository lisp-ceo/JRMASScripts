/**
 * JSONVarLoader
 * load and decode JSON through
 * adapted to AS3 from AS2 version 
 * original by Ryan Quigley
 *
 * @author		Arbie Almeida
 * @version		1.0.0
 *
 * 12.05.08 (1.0.0) - First version
 * 4.10.09 (1.0.1)  - external interface absolute equality check
 */

package ee
{
    import flash.external.*;
    import flash.system.*;
    import flash.utils.*;
    import flash.events.TimerEvent;
    
    public class JSONVarLoader
    {
        public static var onCompleteFunc:Function;
        public static var onFailureFunc:Function;
        public static var js_vars_name:String;
        
        public static var instance:JSONVarLoader;
        
        public static var player_props:Object;
        
        public static function load($js_vars_name:String, $onCompleteFunc:Function, $onFailureFunc:Function = null):Boolean
        {
            JSONVarLoader.js_vars_name = $js_vars_name;
            JSONVarLoader.onCompleteFunc = $onCompleteFunc;
            JSONVarLoader.onFailureFunc = $onFailureFunc;
            
            player_props = JSONVarLoader.getPlayerProps();
            
            if(!ExternalInterface.available) {
                return false;   
            }
            
            // Taken from SiFR 3 - Copyright 2006 – 2008 Mark Wubben, <http://novemberborn.net/>
    		// Flash version older than 9,0,115 under IE incorrectly approach the Flash movie, breaking ExternalInterface.
    	    // sIFR has a workaround, but this workaround cannot be applied until the Flash movie has been added to the document,
    	    // which usually causes the ActionScript to run and set up ExternalInterface. Delaying for a couple milliseconds
    	    // gives the JavaScript time to set up the workaround.
            if((JSONVarLoader.player_props.platform == 'WIN') && (JSONVarLoader.player_props.version <= 9) && (JSONVarLoader.player_props.release < 115)) {
                var delay_timer:Timer = new Timer(200, 1);
                var timeout_func:Function = function(timer_evt:TimerEvent) {
                    JSONVarLoader.run();
                }
                delay_timer.addEventListener(TimerEvent.TIMER, timeout_func);
                delay_timer.start();
            } else {
                JSONVarLoader.run();
            }
            return true;
        }
        
        private static function run():void
        {
            var d:* = ExternalInterface.call('JSONVarLoader', JSONVarLoader.js_vars_name);
            
            if(d === null) {
                if(JSONVarLoader.onFailureFunc != null) {
                    JSONVarLoader.onFailureFunc();
                }
                return;
            }
            JSONVarLoader.onCompleteFunc(d);     
        }
        
        public static function getPlayerProps():Object
        {
            var obj:Object = new Object();
            
            var p:Array = Capabilities.version.split(' ');
            obj.platform = p[0];
            
            var o:Array = p[1].split(',');
            obj.version = Number(o[0]);
            obj.build = Number(o[1]);
            obj.release = Number(o[2]);
            
            return obj;
        }
    }
}