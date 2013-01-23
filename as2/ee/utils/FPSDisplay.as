/**
 * FPSDisplay
 * displays frames-per-second statistics of Flash player
 *
 * @author		Arbie Almeida
 * @version		1.0.0
 *
 * 06.17.09 (1.0.0) - First version
 */
/*
Usage:

import ee.utils.FPSDisplay;

Basic:
-create instance on Stage-
var fpsd:FPSDisplay = new FPSDisplay();

-modify MovieClip stage instance properties-
var parent_mc:MovieClip = fps_d.parent_mc;

NOTE: instance attaches to _root at next highest depth.

-start/stop FPS measurement-
fpsd.start();
fpsd.stop();

-change text display color, use text field background/border-
fpsd.textColor = color:Number;
fpsd.useBorder = use:Boolean;

*/

import ee.utils.Proxy;

class ee.utils.FPSDisplay
{
    private var _text_color:Number = 0x000000;
    private var _use_border:Boolean = false;
    
    private var _fps_txt:TextField;
    private var _lowest_fps:Number = 31; 
    private var _highest_fps:Number = 0;
    
    private var _frame_lapse:Number = 0;
    private var _total_time:Number = 0;
    private var _interval_id:Number = 0;
    private var _first_lapse:Boolean = false;
    
    public var parent_mc:MovieClip;
    
    public function FPSDisplay()
    {
        parent_mc = _root.createEmptyMovieClip("_fpsdisplay_mc", _root.getNextHighestDepth());
        _fps_txt = parent_mc.createTextField("_fps_txt", parent_mc.getNextHighestDepth(), 0, 0, 110, 70);
        _fps_txt.multiline = true;
        _fps_txt.wordWrap = true;
        _fps_txt.selectable = false;
    }
    
    public function start():Void
    {
        parent_mc.onEnterFrame = Proxy.create(this, frameUpdate);
        _interval_id = setInterval(this, "timerUpdate", 1000);
    }
    
    public function stop():Void
    {        
        clearInterval(_interval_id);
        delete parent_mc.onEnterFrame;
        _fps_txt.text += "\nUpdates stopped, seconds displayed: " + _total_time;
        _frame_lapse = _total_time = 0;
    }
    
    private function frameUpdate():Void
    {
        _frame_lapse++;
    }
    
    private function timerUpdate():Void
    {
        if(!_first_lapse) {
            _first_lapse = true;
            return;
        }
        
        if(_frame_lapse < _lowest_fps) {
            _lowest_fps = _frame_lapse;
        }
        if(_frame_lapse > _highest_fps) {
            _highest_fps = _frame_lapse;
        }
        
        var $msg:String = _frame_lapse + " fps\nlowest fps:   " + _lowest_fps + "\npeak fps:     " + _highest_fps;
        _fps_txt.text = $msg;
        _frame_lapse = 0;
        updateAfterEvent();
        _total_time++;
    }
    
    public function get textColor():Number
    {
        return _text_color;
    }
    
    public function set textColor($color:Number):Void
    {
        _text_color = $color;
        _fps_txt.textColor = _text_color;
    }
    
    public function get useBorder():Boolean
    {
        return _use_border;
    }
    
    public function set useBorder($use:Boolean):Void
    {
        _use_border = $use;
        _fps_txt.border = _fps_txt.background = _use_border;
    }
}