class EventDispatcher {
	private var _listeners:Map<String,Array<Dynamic>> = null;

	public function addEventListener(type:String, listener:Dynamic) {
		if (_listeners == null) _listeners = new Map();
		var listeners = _listeners;
		if (!listeners.exists(type)) {
			listeners.set(type, []);
		}
		if (listeners.get(type).indexOf(listener) == -1) {
			listeners.get(type).push(listener);
		}
	}

	public function hasEventListener(type:String, listener:Dynamic):Bool {
		if (_listeners == null) return false;
		var listeners = _listeners;
		return listeners.exists(type) && listeners.get(type).indexOf(listener) != -1;
	}

	public function removeEventListener(type:String, listener:Dynamic) {
		if (_listeners == null) return;
		var listeners = _listeners;
		var listenerArray = listeners.get(type);
		if (listenerArray != null) {
			var index = listenerArray.indexOf(listener);
			if (index != -1) {
				listenerArray.splice(index, 1);
			}
		}
	}

	public function dispatchEvent(event:Dynamic) {
		if (_listeners == null) return;
		var listeners = _listeners;
		var listenerArray = listeners.get(event.type);
		if (listenerArray != null) {
			event.target = this;
			// Make a copy, in case listeners are removed while iterating.
			var array = listenerArray.copy();
			for (i in 0...array.length) {
				array[i](event);
			}
			event.target = null;
		}
	}
}