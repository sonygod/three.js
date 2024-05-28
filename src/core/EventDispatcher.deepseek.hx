/**
 * https://github.com/mrdoob/eventdispatcher.js/
 */

class EventDispatcher {

    var _listeners:Map<String, Array<Dynamic->Void>>;

    public function addEventListener(type:String, listener:Dynamic->Void) {
        if (_listeners == null) _listeners = new Map();
        var listeners = _listeners;
        if (!listeners.exists(type)) listeners.set(type, []);
        var listenerArray = listeners.get(type);
        if (listenerArray.indexOf(listener) == -1) listenerArray.push(listener);
    }

    public function hasEventListener(type:String, listener:Dynamic->Void):Bool {
        if (_listeners == null) return false;
        var listeners = _listeners;
        if (!listeners.exists(type)) return false;
        var listenerArray = listeners.get(type);
        return listenerArray.indexOf(listener) != -1;
    }

    public function removeEventListener(type:String, listener:Dynamic->Void) {
        if (_listeners == null) return;
        var listeners = _listeners;
        if (!listeners.exists(type)) return;
        var listenerArray = listeners.get(type);
        var index = listenerArray.indexOf(listener);
        if (index != -1) listenerArray.splice(index, 1);
    }

    public function dispatchEvent(event:Dynamic) {
        if (_listeners == null) return;
        var listeners = _listeners;
        if (!listeners.exists(Std.string(event.type))) return;
        var listenerArray = listeners.get(Std.string(event.type));
        var array = listenerArray.slice();
        for (i in array) {
            array[i](event);
        }
    }

}