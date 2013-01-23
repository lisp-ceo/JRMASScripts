/*
*   FLVPlayerEvent
*   for ActionScript 3.0
*   Event extension class used by FLVPlayer
*
*   @author     Arbie Almeida
*   @version    1.0.0
*
*   --VERSION HISTORY--
*   7.10.09 (1.0.0) - first version
*/
/*
##### USAGE #####

::Event types::
    FLVPlayerEvent.READY - dispatched when video metadata has been completely loaded
    FLVPlayerEvent.COMPLETE - dispatched when playhead has reached the end of the video 
    FLVPlayerEvent.ON_DELAY - dispatched when video delay has been started
*/

package ee.events
{
    import flash.events.Event;
    
    public class FLVPlayerEvent extends Event
    {
        public static var READY:String = "ready";
        public static var COMPLETE:String = "complete";
        public static var ON_DELAY:String = "on_delay";
        
        public function FLVPlayerEvent($type:String, $bubbles:Boolean = false, $cancelable:Boolean = false)
        {
            super($type, $bubbles, $cancelable);
        }
    }
}