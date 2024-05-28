/**
 * https://github.com/mrdoob/eventdispatcher.js/
 */

class EventDispatcher {
	private var _listeners:Map<String, Array<Dynamic>> = null;

	public function addEventListener(type:String, listener:Dynamic):Void {
		if (_listeners == null)
			_listeners = new Map<String, Array<Dynamic>>();

		if (!_listeners.exists(type))
			_listeners.set(type, []);

		var listeners = _listeners.get(type);
		if (!listeners.contains(listener))
			listeners.push(listener);
	}

	public function hasEventListener(type:String, listener:Dynamic):Bool {
		if (_listeners == null)
			return false;

		var listeners = _listeners.get(type);
		return listeners != null && listeners.contains(listener);
	}

	public function removeEventListener(type:String, listener:Dynamic):Void {
		if (_listeners == null)
			return;

		var listeners = _listeners.get(type);
		if (listeners != null) {
			var index = listeners.indexOf(listener);
			if (index != -1)
				listeners.splice(index, 1);
		}
	}

	public function dispatchEvent(event:Dynamic):Void {
		if (_listeners == null)
			return;

		var listeners = _listeners.get(event.type);
		if (listeners != null) {
			event.target = this;

			// Make a copy, in case listeners are removed while iterating.
			var array = listeners.slice();

			for (i in 0...array.length) {
				array[i](event);
			}

			event.target = null;
		}
	}
}