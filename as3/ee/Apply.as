/*
*   Apply
*   for ActionScript 3.0
*   generates Function object that automatically calls a passed Function with given parameters
*   based on original Proxy class
*
*   @author     Arbie Almeida
*   @version    1.0.0
*
*   --VERSION HISTORY--
*   6.5.09 (1.0.0) - first version
*/
/*
##### USAGE #####

::creates a quick apply Function with optional parameters::
    Apply.create(call_func:Function, parameters:* ...);         -can be passed as many parameters as call_func accepts
*/

package ee
{
    public class Apply
    {
        public static function create($func:Function, ... $params):Function
        {
            var $send_func:Function = function() {
                $func.apply(null, $params);
            }
            return $send_func;
        } 
    }
}