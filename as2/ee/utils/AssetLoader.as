/**
 * Asset Loader with queue
 * Loads files (jpgs, pngs, movie clips, etc) and LoadVars
 *
 * @author		Ryan Quigley
 * @version		1.0.1
 *
 * 11.27.07 (1.0.0) - First version
 * 04.18.08 (1.0.1) - add checkPolicyFile
 */

/*
Inspired by Zeh Fernando LoadingQueue

TODO:
-setPriority (see lehmannmaupin publications)

Usage:

import ee.utils.AssetLoader;

Basic:
var al = new AssetLoader({onComplete:myFunction});
al.addLoadVars(myLoadVarsObj, myUrl);
al.addMovie(myMC, myUrl);
al.start();


With Callbacks:
al.addMovie(
	myMC,
	myUrl,
	{
		onLoadProgress:function()
		{
			// stuff here
		},
		onComplete:function()
		{
			// stuff here
		}
	});


With Loading Profile (basic is 'slot'):
var al = new AssetLoader({method:primary_then_parallel});


Using slots, use custom # of slots (default is 3)
al.setSlots(1);

Oneshot:
AssetLoader.loadMovie(myMC, myUrl, {onComplete:myFunction, onLoadProgress:myComplete});

AssetLoader.loadLoadVars(myLV, myUrl, {onComplete:myFunction});
// loadLoadVars doesn't have onLoadProgress


If doing bitmap effects with files, you'll want to add
checkPolicyFile: true
i.e.
al.addMovie(l_mc.i_mc ,FILES_LOC + eval("w"+n+"_f") , { checkPolicyFile: true, onComplete: onImageLoad});

*/

import ee.utils.Proxy;

class ee.utils.AssetLoader
{
	private static var TYPE_MOVIECLIP:Number = 0;
	private static var TYPE_LOADVARS:Number = 1;

	private static var LOADTYPE_PRIMARY_THEN_PARALLEL:Number = 0;
	private static var LOADTYPE_SLOT:Number = 1;

	private var _vars:Object

	private var _isLoading:Boolean;

	private var _scope:MovieClip;

	private var _maxSlots:Number;
	private var _usedSlots:Number;
	private var _queue_a:Array;

	private var _method:Number;

	public var _onComplete:Function;
	public var _onCompleteParams:Array;

	public var _assetCallback:Object;

	public var _numRemaining:Number;
	public var _numTotal:Number;

	public function AssetLoader(p_vars:Object)
	{
		_vars = p_vars;

		_onComplete = p_vars.onComplete;
		_onCompleteParams = p_vars.onCompleteParams || [];

		_scope = p_vars.scope || _root;

		setSlots(p_vars.slots);

		setMethod(p_vars.method || "slot");

		_isLoading = false;
		_usedSlots = 0;

		_numRemaining = 0;
		_numTotal = 0;

		_queue_a = new Array();
		_assetCallback = new Object();
		_assetCallback.onLoadInit = Proxy.create(this, doneLoadingAsset);
	}

	public function setMethod(p_type:String):Void
	{
		if (p_type == 'primary_then_parallel') {
			_method = LOADTYPE_PRIMARY_THEN_PARALLEL;
		} else {
			_method = LOADTYPE_SLOT;
		}
	}


	private function rePrioritize():Void
	{
		if (_method == LOADTYPE_PRIMARY_THEN_PARALLEL) {
			if (_numRemaining ==  _numTotal - 1) {
				setSlots(3);
			} else if (_numRemaining == _numTotal) {
				setSlots(1);
			}

		} else if (_method == LOADTYPE_SLOT) {
			// do nothing
		}
	}

	public function addMovie(p_mc:MovieClip, p_url:String, p_vars:Object)
	{
		var p_priority = (p_vars && !isNaN(p_vars.priority) ? p_vars.priority : 5);

		_queue_a.push({
			type:		TYPE_MOVIECLIP,
			url:		p_url,
			target:		p_mc,
			isLoading:	false,
			priority:	p_priority,
			vars:		p_vars
			});
	}

	public function addLoadVars(p_lv:LoadVars, p_url:String, p_vars:Object)
	{
		var p_priority = (p_vars && !isNaN(p_vars.priority) ? p_vars.priority : 5);

		_queue_a.push({
			type:		TYPE_LOADVARS,
			url:		p_url,
			target:		p_lv,
			isLoading:	false,
			priority:	p_priority,
			vars:		p_vars
			});
	}


	public function setSlots(p_slots:Number): Void
	{
		// Sets the number of maximum slots for loading
		if (isNaN(p_slots) || p_slots < 1) p_slots = 3;
		_maxSlots = p_slots;
	}


	public function start()
	{
		if (!_isLoading) {
			_isLoading = true;
			_scope.createEmptyMovieClip("AssetLoaderController", _scope.getNextHighestDepth());
			_scope.AssetLoaderController.loadingInstance = this;

			_numTotal = _numRemaining = _queue_a.length;

			if (_numRemaining < _maxSlots) {
				setSlots(_numRemaining);
			}

			loadNext();
		}
	}


	private function loadNext()
	{
		//trace(" ...AssetLoader :: loadNext");

		if (_isLoading) {
			if (_numRemaining > 0) {

				rePrioritize();

				if (_usedSlots < _maxSlots) {
					// Can load another one
					// Find the next one
					var $nextSlot:Number;
					var $nextSlotPriority:Number;

					for (var i:Number = 0; i < _numTotal; i++) {
						if (_queue_a[i] != null && !_queue_a[i].isLoading && ($nextSlotPriority == undefined || _queue_a[i].priority < $nextSlotPriority)) {
							//trace(" ...AssetLoader :: next is "+i);
							$nextSlot = i;
							$nextSlotPriority = _queue_a[i].priority;
							//break;
						}
					}
					if (!isNaN($nextSlot)) {
						// There's at least one left, so load it
						trace(" ...AssetLoader :: loading "+$nextSlot+', url:'+_queue_a[$nextSlot].url + ", target: "+_queue_a[$nextSlot].target);

						switch (_queue_a[$nextSlot].type) {
							case TYPE_MOVIECLIP:
								_queue_a[$nextSlot].loader = new MovieClipLoader();

								if (_queue_a[$nextSlot].vars.checkPolicyFile) {
									_queue_a[$nextSlot].loader.checkPolicyFile = true;
								}

								_queue_a[$nextSlot].loader.addListener(_assetCallback);

								if (_queue_a[$nextSlot].vars.listener) {
									_queue_a[$nextSlot].loader.addListener(_queue_a[$nextSlot].vars.listener);
								}

								if (_queue_a[$nextSlot].vars.onComplete || _queue_a[$nextSlot].vars.onLoadProgress) {
									_queue_a[$nextSlot].callback = new Object();

									if (_queue_a[$nextSlot].vars.onLoadProgress) {
										_queue_a[$nextSlot].callback.onLoadProgress = _queue_a[$nextSlot].vars.onLoadProgress;
									}
									if (_queue_a[$nextSlot].vars.onComplete) {
										_queue_a[$nextSlot].callback.onLoadInit = _queue_a[$nextSlot].vars.onComplete;
									}
									if (_queue_a[$nextSlot].vars.onLoadError) {
										_queue_a[$nextSlot].callback.onLoadError = _queue_a[$nextSlot].vars.onLoadError;
									}

									_queue_a[$nextSlot].loader.addListener(_queue_a[$nextSlot].callback);
								}

								_queue_a[$nextSlot].loader.loadClip(_queue_a[$nextSlot].url, _queue_a[$nextSlot].target);

								break;
							case TYPE_LOADVARS:
								_queue_a[$nextSlot].target.onLoad = Proxy.create(this, doneLoadingAsset);
								
								// IE cache killer. - IE still seems to think that it should be caching data, even when it shouldn't be
								// RQ - 030308 - Switched to forcing no-cache on hosting environment
								//var dv:Date = new Date();
								//var tv = dv.getTime();
								//_queue_a[$nextSlot].target.load(_queue_a[$nextSlot].url + "?" + tv);
								_queue_a[$nextSlot].target.load(_queue_a[$nextSlot].url);

								break;
							default:
								//trace(" ...AssetLoader ERROR! Tried to load an unkown type of asset?");
						}
						_queue_a[$nextSlot].isLoading = true;
						_usedSlots++;
					}

					if (_numRemaining != _usedSlots) {
						loadNext();
					}
				}

			} else {
				// Everything done
				//trace(" ...AssetLoader :: finished");

				doneLoading();

				this.stop();
			}
		}
	}


	private function doneLoading()
	{
		if (_onComplete) {
			_onComplete();
		}
	}

	// Stops loading
	public function stop()
	{
		if (_isLoading) {
			//trace(" ...AssetLoader :: stopped");

			for (var i:Number = _numTotal; i >= 0 ; --i) {
				if (_queue_a[i] != null) {
					_queue_a[i] = null;
				}
			}

			_isLoading = false;
			_scope.AssetLoaderController.removeMovieClip();
		}
	}

	private function doneLoadingAsset(target_mc:MovieClip)
	{
		for (var i:Number = _numTotal; i >= 0 ; --i) {
			if ( ((_queue_a[i].type == TYPE_MOVIECLIP) && _queue_a[i].target == target_mc) ||
				 ((_queue_a[i].type == TYPE_LOADVARS) && _queue_a[i].target.loaded == true)) {

				// Done loading
				//trace(" ...AssetLoader :: doneLoadingAsset - pos: " + i + "target_mc/success: " + target_mc);

				_queue_a[i].isLoading = false;

				switch (_queue_a[i].type) {
					case TYPE_MOVIECLIP:
						_queue_a[i].loader.removeListener(_assetCallback);
						delete _queue_a[i].loader;

						break;
					case TYPE_LOADVARS:
						_queue_a[i].target.onLoad = null;

						// individual callback here to accomodate LV.onLoad
						if (_queue_a[i].vars.onComplete) {
							_queue_a[i].vars.onComplete();
						}

						break;
				}

				_queue_a[i] = null;

				_usedSlots--;

				_numRemaining--;

				loadNext();
			}
		}

	}

	public static function loadMovie(p_mc:MovieClip, p_url:String, p_vars:Object):AssetLoader
	{
		var al:AssetLoader = new AssetLoader();
		al.addMovie(p_mc, p_url, p_vars);
		al.start();

		return al;
	}

	public static function loadLoadVars(p_lv:LoadVars, p_url:String, p_vars:Object):AssetLoader
	{
		var al:AssetLoader = new AssetLoader();
		al.addLoadVars(p_lv, p_url, p_vars);
		al.start();

		return al;
	}

}