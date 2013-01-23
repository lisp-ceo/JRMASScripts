/*
*   BitmapCopy
*   for ActionScript 3.0
*   copies graphics data of source MovieClip/Sprite to copying MovieClip/Sprite
*
*   @author     Arbie Almeida
*   @version    1.0.0
*
*   --VERSION HISTORY--
*   5.8.09 (1.0.0) - first version
*   5.8.09 (1.0.1) - variable correction
*   7.29.09 (1.0.2) - smoothing optional parameter
*/
/*
##### USAGE #####

::copies bitmap graphic data of source to copying, optionally clear the copying Sprite's current graphics::
    BitmapCopy.copyBitmapData(source:Sprite, copying:Sprite, clear:Boolean = false);        -set 'clear' to true to clear copying Sprite before redraw
    
    NOTE: Sprite is base parent class, can be used on any extension of class (MovieClip, etc.)
*/

package ee
{
     import flash.display.*;
     
     public class BitmapCopy
     {
         public static function copyBitmapData($source:*, $copying:*, $clear:Boolean = false, $smoothing:Boolean = true):void
         {
             if($clear) {
                 $copying.graphics.clear();
             }
             var $copy_bmp:BitmapData = new BitmapData(Math.ceil($source.width), Math.ceil($source.height), true, 0);
             $copy_bmp.draw($source);
             $copying.graphics.beginBitmapFill($copy_bmp, null, false, $smoothing);
             $copying.graphics.drawRect(0, 0, Math.ceil($source.width), Math.ceil($source.height));
             $copying.graphics.endFill();
         }
     }
}