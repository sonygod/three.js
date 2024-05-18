package three.core;

import haxe.ds.StringMap;

class EventDispatcher {
    private var _listeners:StringMap<Array<Dynamic->Void>>;

    public function addEventListener(type:String, listener:Dynamic->Void) {
        if (_listeners == null) _listeners = new StringMap();
        var listeners = _listeners;
        if (!listeners.exists(type)) listeners.set(type, new Array());
        var listenerArray = listeners.get(type);
        if (listenerArray.indexOf(listener) == -1) listenerArray.push(listener);
    }

    public function hasEventListener(type:String, listener:Dynamic->Void) {
        if (_listeners == null) return false;
        var listeners = _listeners;
        var listenerArray = listeners.get(type);
        return listenerArray != null && listenerArray.indexOf(listener) != -1;
    }

    public function removeEventListener(type:String, listener:Dynamic->Void) {
        if (_listeners == null) return;
        var listeners = _listeners;
        var listenerArray = listeners.get(type);
        if (listenerArray != null) {
            var index = listenerArray.indexOf(listener);
            if (index != -1) listenerArray.splice(index, 1);
        }
    }

    public function dispatchEvent(event:Dynamic) {
        if (_listeners == null) return;
        var listeners = _listeners;
        var listenerArray = listeners.get(event.type);
        if (listenerArray != null) {
            event.target = this;
            var array = listenerArray.copy();
            for (i in 0...array.length) {
                array[i](event);
            }
            event.target = null;
        }
    }
}