/*
Copyright (c) 2005 JSON.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The Software shall be used for Good, not Evil.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/*
Ported to Actionscript 2 May 2005 by Trannie Carter <tranniec@designvox.com>,
wwww.designvox.com

Updated 2007-03-30

USAGE:
            var json = new JSON();
    try {
        var o:Object = json.parse(jsonStr);
        var s:String = json.stringify(obj);
    } catch(ex) {
        trace(ex.name + ":" + ex.message + ":" + ex.at + ":" + ex.text);
    }

*/

class JSON
{
	var ch:String = '';
	var at:Number = 0;
	var escapee:Array;
	var t,u;			// OPT?
	var text:String;

	static var inst:JSON;

	static function getInstance():JSON
	{
		if(inst == null)
		{
			inst = new JSON();
			
			inst.escapee = new Array();
			inst.escapee['"']  = '"';
			inst.escapee['\\'] = '\\';
			inst.escapee['/']  = '/';
			inst.escapee['b']    = '\b';
			inst.escapee['f']    = '\f';
			inst.escapee['n']    = '\n';
			inst.escapee['r']    = '\r';
			inst.escapee['t']    = '\t';
		}
		return inst;
	}

	function error(m)
	{
        throw {
            name: 'JSONError',
            message: m,
            at: at - 1,
            text: text
        };
    }
    function next(c)
	{
		if (c && c !== ch) {
			error("Expected '" + c + "' instead of '" + ch + "'");
		}

		ch = text.charAt(at);
		at += 1;
		return ch;
    }

	function number()
	{
        var
			number,
			string = '';

        if (ch == '-') {
            string = '-';
            this.next('-');
        }
        while (ch >= '0' && ch <= '9') {
            string += ch;
            this.next();
        }
        if (ch == '.') {
            string += '.';
            while (this.next() && ch >= '0' && ch <= '9') {
                string += ch;
            }
        }
        if (ch == 'e' || ch == 'E') {
            string += ch;
            this.next();
            if (ch == '-' || ch == '+') {
                string += ch;
                this.next();
            }
            while (ch >= '0' && ch <= '9') {
                string += ch;
                this.next();
            }
        }
        number = Number(string);
        if (!isFinite(number)) {
            this.error("Bad number");
        }
        return number;
    }

	function string()
	{
        var
			hex,
			i,
			string = '',
			uffff;
		
		if (ch == '"') {
			while (this.next()) {
				if (ch == '"') {
					this.next();
					return string;
				} else if (ch == '\\') {
					this.next();
                    if (ch === 'u') {
                        uffff = 0;
                        for (i = 0; i < 4; i += 1) {
                            hex = parseInt(this.next(), 16);
                            if (!isFinite(hex)) {
                                break;
                            }
                            uffff = uffff * 16 + hex;
                        }
                        string += String.fromCharCode(uffff);
                    } else if (typeof escapee[ch] == 'string') {
                        string += escapee[ch];
                    } else {
                        break;
                    }
				} else {
					string += ch;
				}
			}
		}
        this.error("Bad string");
    }

	function white()
	{
		while (ch && ch <= ' ') {
			this.next();
		}
	}
	
	function word()
	{
		switch (ch) {
			case 't':
				this.next('t');
				this.next('r');
				this.next('u');
				this.next('e');
				return true;
				break;
			case 'f':
				this.next('f');
				this.next('a');
				this.next('l');
				this.next('s');
				this.next('e');
				return false;
				break;
			case 'n':
				this.next('n');
				this.next('u');
				this.next('l');
				this.next('l');
				return null;
				break;
		}
		this.error("Syntax error");
    }

	function array()
	{
        var array = [];

        if (ch == '[') {
            this.next('[');
            this.white();
            if (ch == ']') {
                this.next(']');
                return array;   // empty array
            }
            while (ch) {
                array.push(value());
                this.white();
                if (ch == ']') {
                    this.next(']');
                    return array;
                }
                this.next(',');
                this.white();
            }
        }

	    var a = [];

	    this.error("Bad array");
	}

	function object()
	{
		var key,
			object = {};
		
		if (ch === '{') {
			this.next('{');
			this.white();
			if (ch === '}') {
				this.next('}');
				return object;   // empty object
			}
			while (ch) {
				key = this.string();
				this.white();
				this.next(':');
				//if (Object.hasOwnProperty.call(object, key)) {
				//	this.error('Duplicate key "' + key + '"');
				//}
				object[key] = this.value();
				this.white();
				if (ch === '}') {
				    this.next('}');
				    return object;
				}
				this.next(',');
				this.white();
			}
		}
		this.error("Bad object");
	}


	function value()
	{
		this.white();
		switch (ch) {
		case '{':
			return this.object();
		case '[':
			return this.array();
		case '"':
			return this.string();
		case '-':
			return this.number();
		default:
			return ch >= '0' && ch <= '9' ? this.number() : this.word();
		}
	}

	static function parse(text:String):Object {

		var inst:JSON = getInstance();
		inst.at = 0;
		inst.ch = ' ';
		inst.text = text;
 
        return inst.value();

    }

}
