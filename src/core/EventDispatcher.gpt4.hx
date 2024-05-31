/**
 * https://github.com/mrdoob/eventdispatcher.js/
 */

package core;

typedef Event = {
	var type:String;
	var target:Dynamic;
}

class EventDispatcher {
	private var _listeners:Map<String, Array<Dynamic -> Void>>;

	public function new() {
		_listeners = new Map();
	}

	public function addEventListener(type:String, listener:Dynamic -> Void):Void {
		if (!_listeners.exists(type)) {
			_listeners.set(type, []);
		}
		var listeners = _listeners.get(type);
		if (listeners.indexOf(listener) == -1) {
			listeners.push(listener);
		}
	}

	public function hasEventListener(type:String, listener:Dynamic -> Void):Bool {
		if (!_listeners.exists(type)) return false;
		var listeners = _listeners.get(type);
		return listeners != null && listeners.indexOf(listener) != -1;
	}

	public function removeEventListener(type:String, listener:Dynamic -> Void):Void {
		if (!_listeners.exists(type)) return;
		var listeners = _listeners.get(type);
		if (listeners != null) {
			var index = listeners.indexOf(listener);
			if (index != -1) {
				listeners.splice(index, 1);
			}
		}
	}

	public function dispatchEvent(event:Event):Void {
		if (!_listeners.exists(event.type)) return;
		var listeners = _listeners.get(event.type);
		if (listeners != null) {
			event.target = this;
			var array = listeners.slice();
			for (listener in array) {
				listener(event);
			}
			event.target = null;
		}
	}
}