/**
 * Stage Alignment class
 * Positions movieclips on the stage
 *
 * @authors		Ryan Quigley, Arbie Almeida
 * @version		1.2.3
 *
 * 1.24.08 (1.0.0) - First version
 * 3.05.08 (1.0.1) - refactor fullscreen resizing to compute ratio per object
 * 6.11.08 (1.1.0) - add centering mode
 * 6.11.08 (1.1.1) - add TC and BC
 * 8.06.08 (1.2) - refactor, allowing registration of additional methods
 * 8.06.08 (1.2.1) - BL and BR were both using methodBottomRight
 * 8.06.08 (1.2.2) - add removeMovieClip method
 * 6.16.09 (1.2.3) - fullscreen mode anchor parameter
 */

/*

TODO:
-more modes

Usage:

import ee.utils.StageAlign;

Basic:
var stageAlign:StageAlign = StageAlign.getInstance();
stageAlign.addMovieClip(_menu.menu_mc, 'TL');
stageAlign.addMovieClip(_menu.menu_mc, 'TR');
stageAlign.addMovieClip(_menu.menu_mc, 'BL');
stageAlign.addMovieClip(_menu.menu_mc, 'BR');

stageAlign.addMovieClip(_menu.menu_mc, 'TC');
stageAlign.addMovieClip(_menu.menu_mc, 'BC');

stageAlign.addMovieClip(_menu.menu_mc, 'fullscreen');
stageAlign.addMovieClip(_menu.menu_mc, 'center');

stageAlign.addMovieClip(_menu.menu_mc, 'fullscreen', 'TL');

Advanced (custom registration):
function tester(mc_o:Object)
{
	mc_o.movieclip._height = Stage.height;
	var point:Object = {x:0, y:0};
	mc_o.movieclip._parent.globalToLocal(point);

	mc_o.movieclip._x = point.x;
	mc_o.movieclip._y = point.y;
}

var stageAlign:StageAlign = StageAlign.getInstance();

stageAlign.registerMethod('test_method', tester);

stageAlign.addMovieClip(test_mc, 'test_method');
stageAlign.addMovieClip(logo_mc, 'CL');

*/

class ee.utils.StageAlign
{
	private static var _instance:StageAlign = null;
	
	private var _movie_clips_a:Array = new Array();

	public static var _base_stage_width:Number;
	public static var _base_stage_height:Number;
	
	private var _registered_methods = new Array();

	private function StageAlign() {}
	
	public static function getInstance():StageAlign
	{
		if (_instance == null) {
			StageAlign._instance = new StageAlign();
			StageAlign._instance.setup();
		}
		
		return StageAlign._instance;
		
	}
	
	private function setup():Void
	{
		Stage.scaleMode = "showAll";
		
		// needs to be computed before switching scaleMode to noScale
		StageAlign._base_stage_width = Stage.width;
		StageAlign._base_stage_height = Stage.height;

		Stage.align = "TL";
		Stage.scaleMode = "noScale";
		Stage.addListener(this);
		
		registerMethod('fullscreen', methodFullscreen);
		registerMethod('center', methodCenter);
		registerMethod('TC', methodTopCenter);
		registerMethod('BC', methodBottomCenter);
		registerMethod('CL', methodCenterLeft);
		registerMethod('CR', methodCenterRight);
		registerMethod('TL', methodTopLeft);
		registerMethod('TR', methodTopRight);
		registerMethod('BL', methodBottomLeft);
		registerMethod('BR', methodBottomRight);
	}

	public function onResize ()
	{
		for(var i in _movie_clips_a) {
			_movie_clips_a[i].method_callback(_movie_clips_a[i]);
		}
	}
	
	public function addMovieClip(mc:MovieClip, method_type:String, full_align:String):Void
	{
		if (!_registered_methods[method_type]) {
			trace("StageAlign: method '"+method_type+"' does not exist.");
			return;
		}
		
		var mc_o = {};
		mc_o.movieclip = mc;
		mc_o.method_callback = _registered_methods[method_type];
		mc_o.ratio = mc._width / mc._height;
		
		if(method_type == 'fullscreen') {
		    switch(full_align) {
    		    case "TL":
    		        mc_o.align_x = null;
    		        mc_o.align_y = null;
    		        break;
    		    case "TC":
    		        mc_o.align_x = alignCenterX;
    		        break;
    		    case "TR":
    		        mc_o.align_x = alignRight;
    		        break;
    		    case "CL":
    		        mc_o.align_y = alignCenterY;
    		        break;
    		    case "CR":
    		        mc_o.align_x = alignRight;
    		        mc_o.align_y = alignCenterY;
    		        break;
    		    case "BL":
    		        mc_o.align_y = alignBottom;
    		        break;
    		    case "BC":
    		        mc_o.align_x = alignCenterX;
    		        mc_o.align_y = alignBottom;
    		        break;
    		    case "BR":
    		        mc_o.align_x = alignRight;
    		        mc_o.align_y = alignBottom;
    		        break;
    		    case undefined:
    		    case "center":
    		        mc_o.align_x = alignCenterX;
    		        mc_o.align_y = alignCenterY;
    		        break;
    		    default:
    		        trace("StageAlign: addMovieClip() - parameter value '" + full_align + "' invalid alignment constant.");
    		        return;
    		        break;
    		}
		}

		var point:Object = {x:mc._x, y:mc._y};
		mc._parent.localToGlobal(point);

		mc_o.x_offset = point.x;
		mc_o.y_offset = point.y;

		_movie_clips_a.push(mc_o);
		
		onResize();
	}
	
	public function removeMovieClip(mc:MovieClip):Void
	{
		for(var i in _movie_clips_a) {
			if (mc === _movie_clips_a[i].movieclip) {
				_movie_clips_a.splice(i, 1);
				return;
			}
		}
	}

	public function registerMethod(method_name:String, method_callback:Object):Void
	{
		if (_registered_methods[method_callback]) {
			trace("StageAlign: method '"+method_callback+"' already exists. Replacing.");
		}
		_registered_methods[method_name] = method_callback;
	}
	
	private static function methodFullscreen(mc:Object)
	{
		var w:Number = Stage.width;
		var h:Number = Stage.height;
		
		if (w/h > mc.ratio) {
			mc.movieclip._width = w;
			mc.movieclip._height = Math.floor(w / mc.ratio);
		} else {
			mc.movieclip._width = Math.floor(h * mc.ratio);
			mc.movieclip._height = h;
		}
		
		if(mc.align_x != undefined) {
		    mc.align_x(mc);
		}
		if(mc.align_y != undefined) {
		    mc.align_y(mc);
		}
	}

	private static function methodCenter(mc:Object)
	{
		mc.movieclip._x = Math.floor(Stage.width/2 - mc.movieclip._width/2);
		mc.movieclip._y = Math.floor(Stage.height/2 - mc.movieclip._height/2);
	}
	
	private static function methodTopCenter(mc:Object)
	{
		var point:Object = {x:0, y:mc.y_offset};
		mc.movieclip._parent.globalToLocal(point);

		mc.movieclip._x = Math.floor(Stage.width/2 - mc.movieclip._width/2);
		mc.movieclip._y = point.y;
	}
	
	private static function methodBottomCenter(mc:Object)
	{
		var point:Object = {x:0, y:Stage.height - StageAlign._base_stage_height + mc.y_offset};
		mc.movieclip._parent.globalToLocal(point);

		mc.movieclip._x = Math.floor(Stage.width/2 - mc.movieclip._width/2);
		mc.movieclip._y = point.y;
	}
	
	private static function methodCenterLeft(mc:Object)
	{
		var point:Object = {x:mc.x_offset, y:0};
		mc.movieclip._parent.globalToLocal(point);

		mc.movieclip._x = point.x;
		mc.movieclip._y = Math.floor(Stage.height/2 - mc.movieclip._height/2);
	}
	
	private static function methodCenterRight(mc:Object)
	{
		var point:Object = {x:Stage.width - StageAlign._base_stage_width + mc.x_offset, y:0};
		mc.movieclip._parent.globalToLocal(point);

		mc.movieclip._x = point.x;
		mc.movieclip._y = Math.floor(Stage.height/2 - mc.movieclip._height/2);
	}
	
	private static function methodTopLeft(mc:Object)
	{
		var point:Object = {x:mc.x_offset, y:mc.y_offset};
		mc.movieclip._parent.globalToLocal(point);

		mc.movieclip._x = point.x;
		mc.movieclip._y = point.y;
	}

	private static function methodTopRight(mc:Object)
	{
		var point:Object = {x:Stage.width - StageAlign._base_stage_width + mc.x_offset, y:mc.y_offset};
		mc.movieclip._parent.globalToLocal(point);

		mc.movieclip._x = point.x;
		mc.movieclip._y = point.y;
	}

	private static function methodBottomLeft(mc:Object)
	{
		var point:Object = {x:mc.x_offset, y:Stage.height - StageAlign._base_stage_height + mc.y_offset};
		mc.movieclip._parent.globalToLocal(point);

		mc.movieclip._x = point.x;
		mc.movieclip._y = point.y;
	}

	private static function methodBottomRight(mc:Object)
	{
		var point:Object = {x:Stage.width - StageAlign._base_stage_width + mc.x_offset, y:Stage.height - StageAlign._base_stage_height + mc.y_offset};
		mc.movieclip._parent.globalToLocal(point);

		mc.movieclip._x = point.x;
		mc.movieclip._y = point.y;
	}
	
	private static function alignCenterX(mc:Object)
	{
	    mc.movieclip._x = (Stage.width >> 1) - (mc.movieclip._width >> 1);
	}
	
	private static function alignRight(mc:Object)
	{
	    mc.movieclip._x = Stage.width - mc.movieclip._width;
	}
	
	private static function alignCenterY(mc:Object)
	{
	    mc.movieclip._y = (Stage.height >> 1) - (mc.movieclip._height >> 1);
	}
	
	private static function alignBottom(mc:Object)
	{
	    mc.movieclip._y = Stage.height - mc.movieclip._height;
	}
}