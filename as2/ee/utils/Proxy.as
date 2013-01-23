class ee.utils.Proxy
{
	public static function create (me:Object, oustsideFunc:Function):Function
	{
		var tempParam:Array = arguments.slice (2);
		var passObject:Boolean = arguments[arguments.length-1].passObject;
		passObject = (passObject != undefined) ? passObject : true;
		
		var tempProxy:Function = function ()
		{
			(!passObject) ? oustsideFunc.apply (null, tempParam) : oustsideFunc.apply (me, arguments.concat (tempParam));
		};
		return tempProxy;
	}
}
