/*
*   Asset Loader with queue
*   for ActionScript 3.0
*   loads files to Loader class and data to URLVariables class
*   based on original AssetLoader class AS2 version by Ryan Quigley
*
*   @author     Arbie Almeida
*   @version    1.0.1
*
*   --VERSION HISTORY--
*   10.21.08 (1.0.0) - first version
*    1.20.09 (1.0.1) - 'next slot' check set to non-number for queue loop cutoff
*/
/*
##### USAGE #####

::standard initialization, adding to queue and load start::
    import AssetLoader;
    var asset_loader:AssetLoader = new AssetLoader(param_obj:Object);
    asset_loader.addURLVariables(url_variables:URLVariables, url:String);
    asset_loader.addLoader(my_loader:Loader, url:String);
    asset_loader.start();

    --parameter Object properties optional--
    param_obj.method:String             - accepts constants AssetLoader.PRIMARY_THEN_PARALLEL or AssetLoader.SLOTS for which loading method to use.
    param_obj.onComplete:Function       - Function called after all items in queue have loaded completely.
    param_obj.onCompleteParams:Array    - Array of variables to pass to onComplete as arguments upon calling.
    
::with callbacks per item::
    asset_loader.addLoader(my_loader, url, event_obj:Object);
    asset_loader.addURLVariables(url_variables, url, event_obj:Object);

    --Loader type event Object optional properties--
    NOTE: all event Functions require corresponding (Event) class as first parameter of Function.
    param_obj.onComplete:Function       - callback function called after image, called when Loader event (Event.COMPLETE) event is dispatched.
    param_obj.onLoadProgress:Function   - function called on every (ProgressEvent.PROGRESS) event is dispatched.
    param_obj.onLoadError:Function      - callback function when error occurs during load, called when Loader event (IOErrorEvent.IO_ERROR) event is dispatched.
    
    --Loader non-event optional properties--
    param_obj.checkPolicyFile:Boolean             - sets whether to check for cross-domain policy file when loading files from external domain.
    
    --URLVariable type event Object optional properties--
    param_obj.onComplete:Function       - callback function called when URLVariable data has loaded successfully.
    param_obj.onCompleteParams:Array    - Array of variables to pass to OnComplete as arguments upon calling.
    
::AssetLoader instance modifiers::
    asset_loader.setSlots(new_slot_count:Number);   - changes amount of loading slots to use.
    asset_loader.setMethod(new_method:String);      - changes queue loading method. Use constants AssetLoader.PRIMARY_THEN_PARALLEL or AssetLoader.SLOTS.
    asset_loader.stop();                            - manually stops loading and clears loading queue.
    
::single item load without instance declaration::
    --for Loader--
    AssetLoader.loadLoader(my_loader:Loader, url:String, event_obj:Object);
    --for URLVariables--
    AssetLoader.loadURLVariables(url_vars:URLVariables, url:String, event_obj:Object);
*/

package ee.utils
{
    import flash.display.*;
    import flash.net.*;
    import flash.events.*;
    import flash.system.LoaderContext;
    
    public class AssetLoader 
    {
        //static variables
        public static var PRIMARY_THEN_PARALLEL:String = "primary_then_parallel";
        public static var SLOTS:String = "slots";
        
        private static var TYPE_LOADER:String = "type_loader";
        private static var TYPE_URLVARIABLES:String = "type_urlvariables";
        
        //definable variables
        private var _arguments_obj:Object;
        private var _max_slots:Number = 0;
        
        private var _onComplete:Function;
        private var _onCompleteParams:Array;
        
        //functional variables
        private var _method:String;
        private var _used_slots:Number = 0;
        
        private var _queue_a:Array;
        
        private var _num_remaining:Number = 0;
        private var _num_total:Number = 0;
        
        private var _is_loading:Boolean = false;
        
        public function AssetLoader(arg_obj:Object = null)
        {
            if(arg_obj != null) {
                _arguments_obj = arg_obj;
                
                _onComplete = (arg_obj.onComplete != null ? arg_obj.onComplete : null);
                _onCompleteParams = (arg_obj.onCompleteParams != null ? arg_obj.onCompleteParams : new Array());

                setSlots(arg_obj.slots);
                setMethod(arg_obj.method || SLOTS);
            } else {
                setSlots(0);
                setMethod(SLOTS);
            }
            
            _queue_a = new Array();
        }
        
        public function setMethod(method_type:String):void
        {
            if(method_type == PRIMARY_THEN_PARALLEL) {
                _method = method_type;
            } else {
                _method = SLOTS;
            }
        }
        
        public function setSlots(num_slots:Number):void
        {
            if(isNaN(num_slots) || num_slots < 1) {
                num_slots = 3;
            }
            _max_slots = num_slots;
        }
        
        private function reprioritize():void
        {
            if(_method == PRIMARY_THEN_PARALLEL) {
                if(_num_remaining == (_num_total - 1)) {
                    setSlots(3);
                } else if (_num_remaining == _num_total) {
                    setSlots(1);
                }
             } else if(_method == SLOTS) {
                 return;
            }
        }
        
        public function addLoader(p_loader:Loader, p_url:String, send_vars:Object = null):void
        {
            var p_vars:Object = (send_vars != null ? send_vars : new Object());
            var p_priority:Number = 5;
            if((p_vars.priority != null) && (!isNaN(p_vars.priority))) {
                p_priority = p_vars.priority;
            }
            
            _queue_a.push({
                type:       TYPE_LOADER,
                url:        p_url,
                target:     p_loader,
                isLoading:  false,
                priority:   p_priority,
                vars:       p_vars
            });
        }
        
        public function addURLVariables(p_uv:URLVariables, p_url:String, send_vars:Object = null):void
        {
            var p_vars:Object = (send_vars != null ? send_vars : new Object());
            var p_priority:Number = 5;
            if((p_vars.priority != null) && (!isNaN(p_vars.priority))) {
                p_priority = p_vars.priority;
            }
            
            _queue_a.push({
                type:       TYPE_URLVARIABLES,
                url:        p_url,
                target:     p_uv,
                isLoading:  false,
                priority:   p_priority,
                vars:       p_vars,
                loaded:     false
            });
        }
        
        public function start():void
        {
            if(!_is_loading) {
                _is_loading = true;
                _num_total = _num_remaining = _queue_a.length;
                if(_num_remaining < _max_slots) {
                    setSlots(_num_remaining);
                }
                loadNext();
            }
        }
        
        private function loadNext():void
        {
            if(_is_loading) {
                if(_num_remaining > 0) {
                    
                    reprioritize();
                    
                    if(_used_slots < _max_slots) {
                        var $next_slot:Number;
                        var $next_slot_priority:Number = -1;
                        for(var n:Number = 0; n < _num_total; n++) {
                            var s_o:Object = _queue_a[n];
                            if((s_o != null) && (!s_o.isLoading) && (($next_slot_priority == -1) || (s_o.priority < $next_slot_priority))) {
                                $next_slot = n;
                                $next_slot_priority = s_o.priority;
                            }
                        }
                        if(!isNaN($next_slot) && (_queue_a[$next_slot] != null)) {
                            var q_o:Object = _queue_a[$next_slot];
                            trace("...AssetLoader :: loading " + $next_slot + ", url: " + q_o.url + ", target: " + q_o.target + " target class: " + q_o.target.constructor);
                            switch(q_o.type) {
                                case TYPE_LOADER:
                                    var $load_ctx:LoaderContext = new LoaderContext();
                                    if(q_o.vars.checkPolicyFile != null) {
                                        $load_ctx.checkPolicyFile = q_o.vars.checkPolicyFile;
                                    }
                                    if(q_o.vars.onLoadProgress != null) {
                                        q_o.target.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, q_o.vars.onLoadProgress);
                                    }
                                    if(q_o.vars.onComplete != null) {
                                        q_o.target.contentLoaderInfo.addEventListener(Event.COMPLETE, q_o.vars.onComplete);
                                    }
                                    if(q_o.vars.onLoadError != null) {
                                        q_o.target.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, q_o.vars.onLoadError);
                                    }
                                    
                                    q_o.target.contentLoaderInfo.addEventListener(Event.COMPLETE, doneLoadingAsset);
                                    q_o.target.load(new URLRequest(q_o.url), $load_ctx);
                                    
                                    break;
                                case TYPE_URLVARIABLES:
                                    var $url_loader:URLLoader = new URLLoader();
                                    //$url_loader.dataFormat = URLLoaderDataFormat.VARIABLES;
                                    var $onload_func:Function = function(event:Event):void {
                                        q_o.target.decode($url_loader.data);
                                        q_o.loaded = true;
                                        doneLoadingAsset(event);
                                    }
                                    
                                    $url_loader.addEventListener(Event.COMPLETE, $onload_func);
                                    $url_loader.load(new URLRequest(q_o.url));
                                    break;
                                default:
                            }
                            q_o.isLoading = true;
                            _used_slots++;
                        }
                        
                        if(_num_remaining != _used_slots) {
                            loadNext();
                        }
                    }
                } else {
                    doneLoading();
                    stop();
                }
            }
        }
        
        private function doneLoading():void
        {
            if(_onComplete != null) {
                _onComplete.apply(null, _onCompleteParams);
            }
        }
        
        public function stop():void
        {
            if(_is_loading) {
                for(var n:Number = (_num_total - 1); n >= 0; --n) {
                    if(_queue_a[n] != null) {
                        delete _queue_a[n];
                    }
                }
                _is_loading = false;
            }   
        }
        
        private function doneLoadingAsset(event:Event):void
        {
            for(var n:Number = (_num_total - 1); n >= 0; --n) {
                if(_queue_a[n] != null) {
                    var q_o:Object = _queue_a[n];
                    switch(event.target.constructor) {
                        case LoaderInfo: 
                            if(q_o.target == event.target.loader) {
                                q_o.isLoading = false;
                                q_o.target.contentLoaderInfo.removeEventListener(Event.COMPLETE, doneLoadingAsset);
                                if(q_o.vars.onComplete != null) {
                                    q_o.target.contentLoaderInfo.removeEventListener(Event.COMPLETE, q_o.vars.onComplete);
                                }
                                freeQueueSlot(n);
                            }
                            break;
                        
                        case URLLoader:
                            if(q_o.loaded == true) {
                                q_o.isLoading = false;
                                if(q_o.vars.onComplete != null) {
                                    if(q_o.vars.onCompleteParams != null) {
                                        q_o.vars.onComplete.apply(null, q_o.vars.onCompleteParams); 
                                    } else {
                                        q_o.vars.onComplete();
                                    }
                                }
                                freeQueueSlot(n);
                            }
                            break;
                    }
                }
            }
        }
        
        private function freeQueueSlot(slot:Number):void
        {
            delete _queue_a[slot];
            _used_slots--;
            _num_remaining--;
            loadNext();
        }
        
        public static function loadLoader(p_loader:Loader, p_url:String, send_vars:Object = null):AssetLoader
        {
            var al:AssetLoader = new AssetLoader();
            al.addLoader(p_loader, p_url, send_vars);
            al.start();
            return al;
        }
        
        public static function loadURLVariables(p_uv:URLVariables, p_url:String, send_vars:Object = null):AssetLoader
        {
            var al:AssetLoader = new AssetLoader();
            al.addURLVariables(p_uv, p_url, send_vars);
            al.start();
            return al;
        }
    }
}