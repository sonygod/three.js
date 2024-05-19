/**
 * https://github.com/mrdoob/eventdispatcher.js/
 */

import js.lib.Event;

class EventDispatcher {
	
	public var _listeners:Map<String, Array<Dynamic>>;

	public function new() {

	}

	public function addEventListener(type:String, listener:Dynamic):Void {

		if (_listeners == null) _listeners = new Map<String, Array<Dynamic>>();

		var listeners:Array<Dynamic> = _listeners.get(type);

		if (listeners == null) {

			listeners = new Array<Dynamic>();
			_listeners.set(type, listeners);

		}

		if (listeners.indexOf(listener) == - 1) {

			listeners.push(listener);

		}

	}

	public function hasEventListener(type:String, listener:Dynamic):Bool {

		if (_listeners == null) return false;

		var listeners:Array<Dynamic> = _listeners.get(type);

		return listeners != null && listeners.indexOf(listener) != - 1;

	}

	public function removeEventListener(type:String, listener:Dynamic):Void {

		if (_listeners == null) return;

		var listeners:Array<Dynamic> = _listeners.get(type);

		if (listeners != null) {

			var index:Int = listeners.indexOf(listener);

			if (index != - 1) {

				listeners.splice(index, 1);

			}

		}

	}

	public function dispatchEvent(event:Event):Void {

		if (_listeners == null) return;

		var listeners:Array<Dynamic> = _listeners.get(event.type);

		if (listeners != null) {

			event.target = this;

			// Make a copy, in case listeners are removed while iterating.
			var array:Array<Dynamic> = listeners.slice();

			for (i in 0...array.length) {

				array[i](event);

			}

			event.target = null;

		}

	}

}
```