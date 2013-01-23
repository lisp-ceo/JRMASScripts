/*
*   FLVPlayer
*   for ActionScript 3.0
*   video player display object
*
*   @author     Arbie Almeida
*   @version    1.0.0
*
*   --VERSION HISTORY--
*   7.10.09 (1.0.0) - first version
*   7.13.09 (1.0.1) - pause state correction
*   7.15.09 (1.0.2) - seek method correction
*/
/*
##### USAGE #####

::instation and loading a video file::
    var flvplayer:FLVPlayer = new FLVPlayer();
    flvplayer.loadContent(content_pat:String);
    
::close video download and clear playback display::
    flvplayer.closeVideo();
    
::playback functions, works without skin::
    flvplayer.pauseVideo();
    flvplayer.playVideo();
    flvplayer.rewindVideo();

::seek video playhead to a specific time::
    flvplayer.seek(time:Number);
    
::mute video, works without skin::
    flvplayer.muteVideo();
    
::set video volume, works without skin::
    flvplayer.setVolume(level:Number); -level value is a Number 0<= n <= 1

## SKIN DEPENDENT FUNCTIONS ##

::resets click-seek functionality range to accomodate new width::
    flvplayer.resetSeekRange(method:String = "");   -accepts optional scaling method value
    
::add skin MovieClips::
    -add seek bar and drag handle MovieClips.
    flvplayer.addSeekBarDrag(seekbar_mc:MovieClip, seekdrag_mc:MovieClip, scale_method:String = ""); -accepts optional scaling method value
    
    -add play/pause button.
    flvplayer.addPlayPauseButton(playpause_mc:MovieClip);
    
    -add rewind button.
    flvplayer.addRewindButton(rewind_mc:MovieClip);
    
    -add volume bar and drag handle MovieClips.
    flvplayer.addVolumeBarDrag(volumebar_mc:MovieClip, volumedrag_mc:MovieClip);
    
    -add mute button.
    flvplayer.addMuteButton(mute_mc:MovieClip);
    
::automatically seek the video based on the seekbar MovieClip width to the given X coordinate::
    flvplayer.seekAtX(x:Number);

::automatically set the volume based on the volumebar MovieClip width to the given X coordinate::
    flvplayer.volumeAtX(x:Number);

## ATTRIBUTES ##
    -set/get video volume.
    flvplayer.volume = new_volume;
    
    -set/get video auto play on load.
    flvplayer.autoPlay = true/false;
    
    -set/get video auto rewind on playback completion.
    flvplayer.autoRewind = true/false;
    
    -set/get video image smoothing.
    flvplayer.smoothing = true/false;
    
    -set/get seekbar scaling method.
    flvplayer.seekbarScalingMethod = FLVPlayer.SEEK_FULL_BASE;
    
    -set/get delay playback while loading.
    flvplayer.delayPlayback = true/false;
    
    -get delay time value when delaying playback.
    var delay_time:Number = flvplayer.delayTime;
    
    -check if video is paused, stopped, or muted.
    var paused:Boolean = flvplayer.paused;
    var stopped:Boolean = flvplayer.stopped; 
    var muted:Boolean = flvplayer.muted; 
*/

package ee
{
    import flash.display.MovieClip;
	import flash.media.Video;
	import flash.media.SoundTransform;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.*;
	import flash.events.NetStatusEvent;
	import flash.events.*;
	import flash.geom.Rectangle;
	
	import ee.events.FLVPlayerEvent;
	
    public class FLVPlayer extends MovieClip
    {
        public static var SEEK_FULL_BASE:String = "full_base";
	    
	    //user defined variables
	    protected var _testing_bytes:Number = 128000;
		protected var _delay_multiplier:Number = 1.5;
		protected var _content_path:String;
		
	    protected var _auto_play:Boolean = false;
	    protected var _auto_rewind:Boolean = false;
	    protected var _get_delay:Boolean = false;
	    protected var _smoothing:Boolean = false;
	    protected var _seekbar_scale_method:String = "";
			
		//functional variables
		protected var _net_connect:NetConnection;
		protected var _net_stream:NetStream;
		protected var _video:Video;
		
		protected var _seek_rect:Rectangle;
		protected var _volume_rect:Rectangle;
		protected var _video_duration:Number = 0;
		protected var _seekbar_ratio:Number = 0;
		protected var _volume_ratio:Number = 0;
		
		//state variables
		protected var _paused:Boolean = false;
		protected var _stopped:Boolean = false;
		protected var _ready:Boolean = false;
		protected var _scrubbing:Boolean = false;
		protected var _volume_scrubbing:Boolean = false;
		protected var _muted:Boolean = false;
		protected var _last_volume:Number = 0;
		
		protected var _end_bytes:Number = 0;
		protected var _start_time:Number = 0;
		protected var _end_time:Number = 0;
		protected var _delay_time:Number = 0;
		protected var _seeking_width:Number = 0;
		protected var _client_obj:Object;
		
		//referential objects	
		protected var _seekdrag_mc:MovieClip;
		protected var _seekbar_mc:MovieClip;
		
		protected var _progressbar_mc:MovieClip;
		protected var _progressbase_mc:MovieClip;
		
		protected var _playpause_mc:MovieClip;
		protected var _rewind_mc:MovieClip;
		protected var _mute_mc:MovieClip;
		
		protected var _volumedrag_mc:MovieClip;
		protected var _volumebar_mc:MovieClip;
		
        public function FLVPlayer()
        {
            initConnection();
            initVideo();
        }
        
        protected function initConnection():void
        {
            _net_connect = new NetConnection();
			_net_connect.connect(null);
			_net_stream = new NetStream(_net_connect);
		    _net_stream.checkPolicyFile = true;
		    
		    _net_stream.bufferTime = 1;
			_client_obj = new Object();
			_client_obj.onMetaData = onStreamMetadata;
			_net_stream.client = _client_obj;
			_net_stream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
        }
        
        protected function initVideo():void
        {
            _video = new Video();
			_video.attachNetStream(_net_stream);
			addChild(_video);
			_video.smoothing = _smoothing;
        }
        
        public function loadContent($content_path:String):void
        {
            if($content_path != "") {
                _content_path = $content_path;
                _net_stream.play(_content_path);
            }
        }
        
        public function closeVideo():void
        {
            _net_stream.close();
            removeChild(_video);
            _video = null;
            initVideo();
            _end_time = 0;
            _ready = false;
        }
        
        protected function onStreamMetadata($data_obj:Object):void
        {
            if(!_ready) {
                _ready = true;
                if(($data_obj.width != 0) && ($data_obj.height != 0)) {
                    _video.width = $data_obj.width;
        			_video.height = $data_obj.height;
                } else {
                    _video.width = _video.videoWidth;
        			_video.height = _video.videoHeight; 
                }
                
                _net_stream.resume();
                _net_stream.seek(0.0);
                
                if(!_auto_play) {
                    if(_playpause_mc != null) {
                        if(_paused) {
                            _paused = false;
                            _playpause_mc.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                        }
                    } else {
                        pauseVideo();
                    }
                }
                
                _video_duration = $data_obj.duration;
                
                dispatchEvent(new FLVPlayerEvent(FLVPlayerEvent.READY));
                
    			
    			if(_seekbar_mc != null && _seekdrag_mc != null) {
    			    resetSeekRange();
    			}
    			
    			if(_get_delay) {
    			    if(_net_stream.bytesLoaded >= _net_stream.bytesTotal) {
			            _get_delay = false;
			            if(_auto_play) {
			                if(_playpause_mc != null) {
			                    if(!_paused) {
			                        pauseVideo();
                                    _playpause_mc.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
			                    }
                            } else {
                                playVideo();
                            }
			            }
			            dispatchEvent(new FLVPlayerEvent(FLVPlayerEvent.ON_DELAY));
			        } else {
			            pauseVideo();
			            _start_time = getTimer();
        			    _end_bytes = _net_stream.bytesLoaded + _testing_bytes;
        			    if(_end_bytes > _net_stream.bytesTotal) {
        			       _end_bytes = _net_stream.bytesTotal;
        			    }
			        }
    			}
    			addEventListener(Event.ENTER_FRAME, onProgress);
 		    }
        }
        
        protected function onNetStatus($net_evt:NetStatusEvent):void
        {
            switch($net_evt.info.code) {
                case "NetStream.Buffer.Flush":
		        break;
		        case "NetStream.Play.Stop":
		            dispatchEvent(new FLVPlayerEvent(FLVPlayerEvent.COMPLETE));
		        case "NetStream.Seek.InvalidTime":
		            if(_auto_rewind) {
		                if(_rewind_mc != null) {
		                    _rewind_mc.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		                } else if (_playpause_mc != null) {
		                    if(!_stopped) {
		                        _net_stream.resume();
		                        _playpause_mc.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		                    }
		                    rewindVideo();
		                } else {
		                    rewindVideo();
		                }
		            }
		        break;
                default:
                break;
            }
        }
        
        public function rewindVideo($evt:MouseEvent = null):void
        {
            _net_stream.pause();
			_paused = true;
			_stopped = true;
			_net_stream.seek(0.0);
        }
        
        public function playVideo():void
        {
            _paused = false;
            _net_stream.resume();
        }
        
        public function pauseVideo():void
        {
            _paused = true;
            _net_stream.pause();
        }
        
        public function muteVideo():void
        {
            muteSound(new MouseEvent(MouseEvent.CLICK));
        }
        
        protected function startSeekDrag($evt:MouseEvent):void
		{
			_seekdrag_mc.startDrag(false, _seek_rect);
			_scrubbing = true;
			stage.addEventListener(MouseEvent.MOUSE_UP, stopSeekDragOutside);
		}

		protected function stopSeekDrag($evt:MouseEvent):void
		{
		    _scrubbing = false;
			_seekdrag_mc.stopDrag();
		}

		protected function stopSeekDragOutside($evt:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopSeekDragOutside);
			stopSeekDrag($evt);
		}

		protected function playPauseVideo($evt:MouseEvent):void
		{
		    if(_stopped) {
		        _stopped = false;
		    }
		    _net_stream.togglePause();
		    
		    if(_paused == true) {
		        _paused = false;
		    } else {
		        _paused = true;
		    }
		}
		
		protected function muteSound($evt:MouseEvent):void
		{
		    var $sound_transform:SoundTransform = _net_stream.soundTransform;//new SoundTransform(1, 0);
		    if(!_muted) {
		        _last_volume = _net_stream.soundTransform.volume;
		        $sound_transform.volume = 0;
		        _muted = true;
		    } else {
		        $sound_transform.volume = _last_volume;
		        _muted = false;
		    }
		    _net_stream.soundTransform = $sound_transform;
		    
		    if(_volumedrag_mc != null) {
		        _volumedrag_mc.mouseEnabled = _volumedrag_mc.mouseChildren = !_muted;
		    }
		}
		
		protected function startVolumeDrag($evt:MouseEvent):void
		{
		    _volume_scrubbing = true;
			_volumedrag_mc.startDrag(false, _volume_rect);
			stage.addEventListener(MouseEvent.MOUSE_UP, stopVolumeDragOutside);
		}

		protected function stopVolumeDrag($evt:MouseEvent):void
		{
		    _volume_scrubbing = false;
			_volumedrag_mc.stopDrag();
		}

		protected function stopVolumeDragOutside($evt:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopVolumeDragOutside);
			stopVolumeDrag($evt);
		}
		
		protected function onEnterFrame($evt:Event):void
	    {
	        if(_video_duration > 0) {
	            if(_seekbar_mc != null && _seekdrag_mc != null) {
	                if(_scrubbing) {
    		            var $new_time:Number = Math.floor((_seekdrag_mc.x - _seekbar_mc.x) * _seekbar_ratio);
                        _net_stream.seek($new_time);
    		        } else {
    		            _seekdrag_mc.x = Math.round(_seekbar_mc.x + (_net_stream.time / _seekbar_ratio));
    		        }
	            }
		    }
		    
		    if(_volumebar_mc != null) {
		        if(_volume_scrubbing) {
		            var $sound_transform:SoundTransform = new SoundTransform(1, 0);
        		    $sound_transform.volume = (_volumedrag_mc.x - _volumebar_mc.x) * _volume_ratio;
        		    _net_stream.soundTransform = $sound_transform;
		        } else {
		            _volumedrag_mc.x = _volumebar_mc.x + (_net_stream.soundTransform.volume / _volume_ratio);
		        }
		    }
	    }
	    
	    protected function onProgress($evt:Event):void
	    {
	        if(_progressbar_mc != null) {
                var $loaded_percent:Number = _net_stream.bytesLoaded / _net_stream.bytesTotal;
                _progressbar_mc.width = _progressbase_mc.width * $loaded_percent;
            }
            if(_get_delay && (_end_time == 0)) {
                if(_net_stream.bytesLoaded >= _end_bytes) {
                    _end_time = getTimer();
                    getDownloadSpeed();
                }
            }
            if(_net_stream.bytesLoaded == _net_stream.bytesTotal) {
                removeEventListener(Event.ENTER_FRAME, onProgress);
            }
	    }
	    
	    protected function getDownloadSpeed():void
	    {
	        var $test_time:int = Math.ceil((_end_time - _start_time) / 1000);
	        var $download_speed:Number = Math.round(_testing_bytes / $test_time);
	        var $total_time:Number = _net_stream.bytesTotal / $download_speed;
	        _delay_time = Math.log($total_time) * _delay_multiplier;
	        _delay_time = Math.floor(_delay_time - $test_time);
	        
	        var $play_video:Function = function() {
	            if(_auto_play) {
	                if(_playpause_mc != null) {
    	                if(_paused) {
    	                    _net_stream.pause();
    	                    _playpause_mc.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
    	                }
                    } else {
                        playVideo();
                    }
	            }
                $delay_timer.removeEventListener(TimerEvent.TIMER, $play_video);
	        }
	        
	        dispatchEvent(new FLVPlayerEvent(FLVPlayerEvent.ON_DELAY));
	        var $delay_timer:Timer = new Timer(_delay_time * 1000, 1);
	        $delay_timer.addEventListener(TimerEvent.TIMER, $play_video);
	        $delay_timer.start();
	    }
	    
	    public function resetSeekRange():void
        {
            if(_seekbar_scale_method == SEEK_FULL_BASE) {
                _seeking_width = _seekbar_mc.width;
            } else {
                _seeking_width = _seekbar_mc.width - _seekdrag_mc.width;
            }
            
            _seek_rect = new Rectangle(_seekbar_mc.x, _seekbar_mc.y, _seeking_width, 0);
            _seekbar_ratio = _video_duration / _seeking_width;
        }
        
        public function addSeekBarDrag($seekbar_mc:MovieClip, $seekdrag_mc:MovieClip, $scale_method:String = ""):void
        {
            _seekbar_mc = $seekbar_mc;
            _seekdrag_mc = $seekdrag_mc;
            _seekbar_scale_method = $scale_method;
            _seekdrag_mc.addEventListener(MouseEvent.MOUSE_DOWN, startSeekDrag);
            _seekdrag_mc.addEventListener(MouseEvent.MOUSE_UP, stopSeekDrag);
            
            resetSeekRange();
            
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        public function addPlayPauseButton($playpause_mc:MovieClip):void
        {
            _playpause_mc = $playpause_mc;
            _playpause_mc.addEventListener(MouseEvent.CLICK, playPauseVideo);
        }
        
        public function addRewindButton($rewind_mc:MovieClip):void
        {
            _rewind_mc = $rewind_mc;
            _rewind_mc.addEventListener(MouseEvent.CLICK, rewindVideo);
        }
        
        public function addMuteButton($mute_mc:MovieClip):void
        {
            _mute_mc = $mute_mc;
            _mute_mc.addEventListener(MouseEvent.CLICK, muteSound);
        }
        
        public function addProgressBar($progressbase_mc:MovieClip, $progressbar_mc:MovieClip):void
        {
            _progressbase_mc = $progressbase_mc;
            _progressbar_mc = $progressbar_mc;
        }
        
        public function addVolumeBarDrag($volumebar_mc:MovieClip, $volumedrag_mc:MovieClip):void
        {
            _volumebar_mc = $volumebar_mc;
            _volumedrag_mc = $volumedrag_mc;
            _volumedrag_mc.addEventListener(MouseEvent.MOUSE_DOWN, startVolumeDrag);
            _volumedrag_mc.addEventListener(MouseEvent.MOUSE_UP, stopVolumeDrag);
            
            _volume_rect = new Rectangle(_volumebar_mc.x, _volumebar_mc.y, _volumebar_mc.width, 0);
            _volume_ratio = 1 / _volumebar_mc.width;
            
            if(!hasEventListener(Event.ENTER_FRAME)) {
                addEventListener(Event.ENTER_FRAME, onEnterFrame);
            }
        }
        
        public function seek($new_time:Number):void
        {
            if(!isNaN($new_time)) {
                _scrubbing = true;
                _net_stream.seek($new_time);
                _scrubbing = false;
            }
        }
        
        public function seekAtX($new_x:Number):void
        {
            if(_seekbar_mc != null) {
                _scrubbing = true;
                var $new_time:Number = Math.floor(($new_x - _seekbar_mc.x) * _seekbar_ratio);
                _net_stream.seek($new_time);
                _scrubbing = false;
            }
        }
        
        public function volumeAtX($new_x:Number):void
        {
            if(_volumebar_mc != null) {
                _volume_scrubbing = true;
    		    var $new_volume:Number = ($new_x - _volumebar_mc.x) * _volume_ratio;
    		    var sound_transform:SoundTransform = new SoundTransform($new_volume, 0);
    		    _net_stream.soundTransform = sound_transform;
    		    _volume_scrubbing = false;
            }
        }
        
        public function get time():Number
        {
            return _net_stream.time;
        }
        
        public function get videoDuration():Number
        {
            return _video_duration;
        }
        
        public function get volume():Number
        {
            return _net_stream.soundTransform.volume;
        }
        
        public function set volume($volume:Number):void
        {
            if(!isNaN($volume)) {
                _volume_scrubbing = true;
                var $sound_transform:SoundTransform = new SoundTransform($volume, 0);
    		    _net_stream.soundTransform = $sound_transform;
    		    _volume_scrubbing = false;
            }
        }
        
        public function set autoPlay($autoplay:Boolean):void
        {
            _auto_play = $autoplay;
        }
        
        public function get autoPlay():Boolean
        {
            return _auto_play;
        }
        
        public function set autoRewind($autorewind:Boolean):void
        {
            _auto_rewind = $autorewind;
        }
        
        public function get autoRewind():Boolean
        {
            return _auto_rewind;
        }
        
        public function set smoothing($smoothing:Boolean):void
        {
            _smoothing = $smoothing;
            _video.smoothing = _smoothing;
        }
        
        public function get smoothing():Boolean
        {
            return _smoothing;
        }
        
        public function get seekbarScaleMethod():String
        {
            return _seekbar_scale_method;
        }
        
        public function set seekbarScaleMethod($method:String):void
        {
            _seekbar_scale_method = $method;
        }
        
        public function set delayPlayback($delay:Boolean):void
        {
            _get_delay = $delay;
        }
        
        public function get delayPlayback():Boolean
        {
            return _get_delay;
        }
        
        public function get delayTime():Number
        {
            return _delay_time;
        }
        
        public function get paused():Boolean
        {
            return _paused;
        }
        
        public function get stopped():Boolean
        {
            return _stopped;
        }
        
        public function get muted():Boolean
        {
            return _muted;
        }
    }
}