Here is the equivalent Haxe code for the given JavaScript code:
```
package three.src.core;

class EventDispatcher {
    private var _listeners:Map<String, Array<Dynamic>>;

    public function addEventListener(type:String, listener:Dynamic) {
        if (_listeners == null) _listeners = new Map<String, Array<Dynamic>>();

        var listeners = _listeners;
        if (!listeners.exists(type)) {
            listeners.set(type, new Array<Dynamic>());
        }

        var listenerArray = listeners.get(type);
        if (listenerArray.indexOf(listener) == -1) {
            listenerArray.push(listener);
        }
    }

    public function hasEventListener(type:String, listener:Dynamic) {
        if (_listeners == null) return false;

        var listeners = _listeners;
        var listenerArray = listeners.get(type);
        return listenerArray != null && listenerArray.indexOf(listener) != -1;
    }

    public function removeEventListener(type:String, listener:Dynamic) {
        if (_listeners == null) return;

        var listeners = _listeners;
        var listenerArray = listeners.get(type);
        if (listenerArray != null) {
            var index = listenerArray.indexOf(listener);
            if (index != -1) {
                listenerArray.remove(listener);
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
```
Note that I've used the `Map` class from the Haxe standard library to replace the JavaScript object used to store the listeners. I've also replaced the JavaScript `indexOf` method with the Haxe `indexOf` method, and the `splice` method with the `remove` method.

Also, I've used the `Dynamic` type to represent the listener functions, as Haxe does not have a direct equivalent to JavaScript's function type.

You can use this Haxe code in your Haxe project, and it should provide the same functionality as the original JavaScript code.