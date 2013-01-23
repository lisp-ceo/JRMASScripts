/*
*   StageAlign
*   for ActionScript 3.0
*   pins DisplayObjects to set Stage locations on resize
*   based on original StageAlign class AS2 version by Ryan Quigley
*
*   @author     Arbie Almeida
*   @version    1.0.2
*
*   --VERSION HISTORY--
*   1.15.09 (1.0.0) - first version
*   4.10.09 (1.0.1) - bottom right method correction
*   6.16.09 (1.0.2) - fullscreen mode anchor parameter
*/
/*
##### USAGE #####

::IMPORTANT: Stage assigment must be made before any instances are retrieved::
::assign current Stage to StageAlign::
    StageAlign._stage = (this).stage;

::retrieve singleton instance of StageAlign::
    import StageAlign;
    var sa_instance:StageAlign = StageAlign.getInstance();
    
::register a DisplayObject to a locking method::
    var example_do:DisplayObject = new DisplayObject();
    sa_instance.addDisplayObject(example_do, StageAlign.FULLSCREEN);
    
::register a DisplayObject to a fullscreen mode with anchoring::
    sa_instance.addDisplayObject(example_do, StageAlign.FULLSCREEN, StageAlign.TOP_RIGHT);
    
::DEFAULT ALIGNMENT REGISTERS::
    StageAlign.FULLSCREEN;      - scales DisplayObject to fit either height or width of Stage.
    StageAlign.CENTER;          - keeps Display Object at relative center of Stage regardless of dimensions.
    StageAlign.TOP_LEFT;
    StageAlign.TOP_CENTER;
    StageAlign.TOP_RIGHT;
    StageAlign.CENTER_LEFT;
    StageAlign.CENTER_RIGHT;
    StageAlign.BOTTOM_LEFT;
    StageAlign.BOTTOM_CENTER;
    StageAlign.BOTTOM_RIGHT;
    
::register a new method to be called on Stage.onResize event::
    sa_instance.registerMethod(method_name:String, callback:Function);
    --IMPORTANT:new method Function must have Object as first optional parameter--
    function callback(data_o:Object = null):void { }
    
::retrieve base dimensions of Stage::
    var base_width:Number = StageAlign._base_stage_width;
    var base_height:Number = StageAlign._base_stage_height;
*/

package ee
{
    import flash.display.Stage;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.utils.getDefinitionByName;
    import flash.geom.Point;
    
    public class StageAlign
    {
        private static var _instance:StageAlign = null;
        public static var _stage:Stage;
        
        public static var FULLSCREEN:String = "fullscreen";
        public static var TOP_LEFT:String = "TL";
        public static var TOP_CENTER:String = "TC";
        public static var TOP_RIGHT:String = "TR";
        public static var CENTER_LEFT:String = "CL";
        public static var CENTER:String = "center";
        public static var CENTER_RIGHT:String = "CR";
        public static var BOTTOM_LEFT:String = "BL";
        public static var BOTTOM_CENTER:String = "BC";
        public static var BOTTOM_RIGHT:String = "BR";
        
        internal var _display_objects:Array = new Array();
        internal var _registered_methods:Array = new Array();
        
        public static var _base_stage_width:Number = 0;
        public static var _base_stage_height:Number = 0;
        public static var _active:Boolean = false;
        
        public function StageAlign() { }
        
        public static function getInstance():StageAlign
        {
            if(_instance == null) {
                StageAlign._instance = new StageAlign();
                StageAlign._instance.init();
            }
            return StageAlign._instance;
        }
        
        internal function init():void
        {
            _stage.scaleMode = StageScaleMode.SHOW_ALL;
            StageAlign._base_stage_width = _stage.stageWidth;
            StageAlign._base_stage_height = _stage.stageHeight;
            
            var $Align:Class = getDefinitionByName("flash.display.StageAlign") as Class;
            _stage.scaleMode = StageScaleMode.NO_SCALE;
            _stage.align = $Align.TOP_LEFT;
            _stage.addEventListener(Event.RESIZE, onStageResize);
            
            registerMethod(FULLSCREEN, methodFullscreen);
            registerMethod(TOP_LEFT, methodTopLeft);
            registerMethod(TOP_CENTER, methodTopCenter);
            registerMethod(TOP_RIGHT, methodTopRight);
            registerMethod(CENTER_LEFT, methodCenterLeft);
            registerMethod(CENTER, methodCenter);
            registerMethod(CENTER_RIGHT, methodCenterRight);
            registerMethod(BOTTOM_LEFT, methodBottomLeft);
            registerMethod(BOTTOM_CENTER, methodBottomCenter);
            registerMethod(BOTTOM_RIGHT, methodBottomRight);
        }
        
        internal function onStageResize($evt:Event):void
        {
            for(var i in _display_objects) {
                _display_objects[i].method_callback(_display_objects[i]);
            }
        }
        
        public function addDisplayObject($disp_obj:*, $method:String, $full_anchor:String = "center"):void
        {
            if(_registered_methods[$method] == undefined) {
                trace("ERROR: StageAlign.addObject() - method '" + $method + "' is not a registered method.");
                return;
            }
            
            var $a_obj:Object = new Object();
            $a_obj.display_object = $disp_obj;
            $a_obj.method_callback = _registered_methods[$method];
            $a_obj.ratio = $disp_obj.width / $disp_obj.height;
            $a_obj.globalToLocal = $disp_obj.parent.globalToLocal;
            
            var $glob_pt:Point = new Point($disp_obj.x, $disp_obj.y);
            $disp_obj.parent.localToGlobal($glob_pt);
            
            $a_obj.x_offset = $glob_pt.x;
            $a_obj.y_offset = $glob_pt.y;
            
            if($method == FULLSCREEN) {
                switch($full_anchor) {
                    case TOP_LEFT:
                        $a_obj.align_x = null;
                        $a_obj.align_y = null;
                        break;
                    case TOP_CENTER:
                        $a_obj.align_x = fullAlignCenterX;
                        break;
                    case TOP_RIGHT:
                        $a_obj.align_x = fullAlignRight;
                        break;
                    case CENTER_LEFT:
                        $a_obj.align_y = fullAlignCenterY;
                        break;
                    case CENTER:
                        $a_obj.align_y = fullAlignCenterY;
                        $a_obj.align_x = fullAlignCenterX;
                        break;
                    case CENTER_RIGHT:
                        $a_obj.align_y = fullAlignCenterY;
                        $a_obj.align_x = fullAlignRight;
                        break;
                    case BOTTOM_LEFT:
                        $a_obj.align_y = fullAlignBottom;
                        break;
                    case BOTTOM_CENTER:
                        $a_obj.align_x = fullAlignCenterX;
                        $a_obj.align_y = fullAlignBottom;
                        break;
                    case BOTTOM_RIGHT:
                        $a_obj.align_x = fullAlignRight;
                        $a_obj.align_y = fullAlignBottom;
                        break;
                    default:
                        trace("ERROR: StageAlign.addObject() - parameter value '" + $full_anchor + "' invalid alignment constant.");
                        return;
                        break;
                }
            }
            
            _display_objects.push($a_obj);
            
            onStageResize(new Event(Event.RESIZE));
        }
        
        public function registerMethod($method:String, $method_callback:Function):void
        {
            if(_registered_methods[$method] != undefined) {
                trace("WARNING: StageAlign.registerMethod() - method'" + $method + "' already exists. Passed method to overwrite.");
            }
            _registered_methods[$method] = $method_callback;
        }
        
        internal static function methodFullscreen($ref_obj:Object):void
        {
            var $w:Number = _stage.stageWidth;
            var $h:Number = _stage.stageHeight;
            
            var $disp_obj:* = $ref_obj.display_object;
            
            if(($w/$h) > $ref_obj.ratio) {
                $disp_obj.width = $w;
                $disp_obj.height = Math.floor($w / $ref_obj.ratio);
            } else {
                $disp_obj.height = $h;
                $disp_obj.width = Math.floor($h * $ref_obj.ratio);
            }
            
            if($ref_obj.align_x != null) {
                $ref_obj.align_x($ref_obj);
            }
            if($ref_obj.align_y != null) {
                $ref_obj.align_y($ref_obj);
            }
            //$disp_obj.x = ($w >> 1) - ($disp_obj.width >> 1);
            //$disp_obj.y = ($h >> 1) - ($disp_obj.height >> 1);
        }
        
        internal static function methodTopLeft($ref_obj:Object):void
        {
            setToNewPoint(new Point($ref_obj.x_offset, $ref_obj.y_offset), $ref_obj);
        }
        
        internal static function methodTopCenter($ref_obj:Object):void
        {
            setToNewPoint(new Point(0, $ref_obj.y_offset), $ref_obj);
            $ref_obj.display_object.x = (_stage.stageWidth >> 1) - ($ref_obj.display_object.width >> 1);
        }
        
        internal static function methodTopRight($ref_obj:Object):void
        {
            setToNewPoint(new Point(_stage.stageWidth - StageAlign._base_stage_width +$ref_obj.x_offset, $ref_obj.y_offset), $ref_obj);
        }
        
        internal static function methodCenterLeft($ref_obj:Object):void
        {
            setToNewPoint(new Point($ref_obj.x_offset, 0), $ref_obj);
            $ref_obj.display_object.y = (_stage.stageHeight >> 1) - ($ref_obj.display_object.height >> 1);
        }
        
        internal static function methodCenter($ref_obj:Object):void
        {
            $ref_obj.display_object.x = (_stage.stageWidth >> 1) - ($ref_obj.display_object.width >> 1);
            $ref_obj.display_object.y = (_stage.stageHeight >> 1) - ($ref_obj.display_object.height >> 1);
        }
        
        internal static function methodCenterRight($ref_obj:Object):void
        {
            setToNewPoint(new Point(_stage.stageWidth - StageAlign._base_stage_width +$ref_obj.x_offset, 0), $ref_obj);
            $ref_obj.display_object.y = (_stage.stageHeight >> 1) - ($ref_obj.display_object.height >> 1);
        }
        
        internal static function methodBottomLeft($ref_obj:Object):void
        {
            setToNewPoint(new Point($ref_obj.x_offset, _stage.stageHeight - StageAlign._base_stage_height + $ref_obj.y_offset), $ref_obj);
        }
        
        internal static function methodBottomCenter($ref_obj:Object):void
        {
            setToNewPoint(new Point(0, _stage.stageHeight - StageAlign._base_stage_height + $ref_obj.y_offset), $ref_obj);
            $ref_obj.display_object.x = (_stage.stageWidth >> 1) - ($ref_obj.display_object.width >> 1);
        }
        
        internal static function methodBottomRight($ref_obj:Object):void
        {
            setToNewPoint(new Point(_stage.stageWidth - StageAlign._base_stage_width +$ref_obj.x_offset, _stage.stageHeight - StageAlign._base_stage_height + $ref_obj.y_offset), $ref_obj);
        }
        
        internal static function setToNewPoint($point:Point, $ref_obj:Object):void
        {
            $ref_obj.globalToLocal($point);
            $ref_obj.display_object.x = $point.x;
            $ref_obj.display_object.y = $point.y;
        }
        
        internal static function fullAlignCenterY($ref_obj:Object):void
        {
            $ref_obj.display_object.y = (_stage.stageHeight >> 1) - ($ref_obj.display_object.height >> 1);
        }
        
        internal static function fullAlignBottom($ref_obj:Object):void
        {
            $ref_obj.display_object.y = _stage.stageHeight - $ref_obj.display_object.height;
        }
        
        internal static function fullAlignCenterX($ref_obj:Object):void
        {
            $ref_obj.display_object.x = (_stage.stageWidth >> 1) - ($ref_obj.display_object.width >> 1);
        }
        
        internal static function fullAlignRight($ref_obj:Object):void
        {
            $ref_obj.display_object.x = _stage.stageWidth - $ref_obj.display_object.width;
        }
    }
}