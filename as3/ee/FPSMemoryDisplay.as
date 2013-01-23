/*
*   FPSMemoryDisplay
*   for ActionScript 3.0
*   displays Flash player frames-per-second and memory statistics
*
*   @author     Arbie Almeida
*   @version    1.0.0
*
*   --VERSION HISTORY--
*   6.17.09 (1.0.0) - first version
*/
/*
##### USAGE #####

::instantiate a FPSMemoryDisplay, inherits Sprite class::
    var fmdisplay:FPSMemoryDisplay = new FPSMemoryDisplay();
    addChild(fmdisplay);
    
::start and stop measurement::
    fmdisplay.start();
    fmdisplay.stop();
    
::set text display color, display text background/border::
    fmdisplay.textColor = $color:Number;
    fmdisplay.useBorder = $border:Boolean;
*/

package ee
{
    import flash.display.Sprite;
    import flash.text.*;
    import flash.events.*;
    import flash.utils.Timer;
    import flash.system.System;
    
    public class FPSMemoryDisplay extends Sprite
    {
        private const _byte_to_mb:Number = 1048576;
        
        private var _text_color:Number = 0x000000;
        private var _use_border:Boolean = false;
        
        private var _fps_txt:TextField;
        private var _lowest_fps:int = 0; 
        private var _highest_fps:int = 0;
        private var _stage_fps:int = 0;
        
        private var _frame_lapse:int = 0;
        private var _total_time:int = 0;
        private var _timer:Timer;
        
        private var _lowest_memory:Number = 0;
        private var _highest_memory:Number = 0;
        
        public function FPSMemoryDisplay()
        {
            _fps_txt = new TextField();
            _fps_txt.height = 130;
            _fps_txt.width = 130;
            _fps_txt.multiline = true;
            _fps_txt.wordWrap = true;
            _fps_txt.mouseEnabled = false;
            
            addChild(_fps_txt);
            
            _timer = new Timer(1000, 0);
            
            addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
        }
        
        private function onStageAdd($evt:Event):void
        {
            _stage_fps = this.stage.frameRate;
            _lowest_fps = _stage_fps;
            _lowest_memory = _highest_memory = Number((System.totalMemory / _byte_to_mb).toFixed(3));
        }
        
        public function start():void
        {
            _frame_lapse = _total_time = 0;
            _timer.addEventListener(TimerEvent.TIMER, onTimer);
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
            _timer.start();
        }
        
        public function stop():void
        {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            _timer.removeEventListener(TimerEvent.TIMER, onTimer);
            _fps_txt.appendText("\nUpdates stopped, seconds displayed: " + _total_time);
        }
        
        private function onEnterFrame($evt:Event):void
        {
            _frame_lapse++;
        }
        
        private function onTimer($evt:TimerEvent):void
        {
            if(_frame_lapse < _lowest_fps) {
                _lowest_fps = _frame_lapse;
            }
            if(_frame_lapse > _highest_fps) {
                _highest_fps = _frame_lapse;
            }
            
            var $current_mem:Number = Number((System.totalMemory / _byte_to_mb).toFixed(3));
            
            if($current_mem < _lowest_memory) {
                _lowest_memory = $current_mem;
            }
            if($current_mem > _highest_memory) {
                _highest_memory = $current_mem;
            }
            
            
            var $msg:String = _frame_lapse + " fps\nlowest fps:   " + _lowest_fps + "\npeak fps:      " + _highest_fps + "\nstage base:   " + _stage_fps;
            $msg += "\n\n" + $current_mem + " Mbytes usage.\n" + "Lowest memory: " + _lowest_memory + "\n" + "Peak memory:    " + _highest_memory;
            _fps_txt.text = $msg;
            _frame_lapse = 0;
            $evt.updateAfterEvent();
            _total_time++;
        }
        
        public function get textColor():Number
        {
            return _text_color;
        }
        
        public function set textColor($color:Number):void
        {
            _text_color = $color;
            _fps_txt.textColor = _text_color;
        }
        
        public function get useBorder():Boolean
        {
            return _use_border;
        }
        
        public function set useBorder($use:Boolean):void
        {
            _use_border = $use;
            _fps_txt.border = _fps_txt.background = _use_border;
        }
    }
}