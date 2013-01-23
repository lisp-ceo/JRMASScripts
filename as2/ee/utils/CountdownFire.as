/*
	Utility function to fire a number of actions when a number of jobs have been completed. 
	
	
	var a = new CountdownFire(2);
	a.addTarget(this, about, "process");
	a.addTarget(this, about, "innovation");
	a.doneJob();
	a.doneJob();
	
*/


class ee.utils.CountdownFire
{
	private var _num_count:Number;

	private var _target_a:Array;

	public function CountdownFire (num_count:Number, done_object:Object, done_function:Function)
	{
		_num_count = num_count;
		_target_a = new Array();
	}
	
	public function addTarget(done_object:Object, done_function:Function)
	{
		trace("ADD TARGET");
		_target_a.push({ obj:done_object, func:done_function, args: arguments.slice (2)});		
	}
	
	public function doneJob()
	{		
		if (--_num_count == 0) {
			trace("FIRE" + _target_a.length);
			for (var i in _target_a) {
				_target_a[i].func.apply(_target_a[i].obj, arguments.concat(_target_a[i].args));
			}
		}

		// zero out the targets
		_target_a = null;

	}
}
