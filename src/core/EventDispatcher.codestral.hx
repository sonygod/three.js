class EventDispatcher {
    private var _listeners:haxe.ds.StringMap<Array<Dynamic>>;

    public function new() {
        this._listeners = new haxe.ds.StringMap<Array<Dynamic>>();
    }

    public function addEventListener(type:String, listener:Dynamic) {
        if (!this._listeners.exists(type)) {
            this._listeners.set(type, []);
        }

        var listenerArray = this._listeners.get(type);

        if (!listenerArray.contains(listener)) {
            listenerArray.push(listener);
        }
    }

    public function hasEventListener(type:String, listener:Dynamic):Bool {
        if (!this._listeners.exists(type)) {
            return false;
        }

        var listenerArray = this._listeners.get(type);

        return listenerArray.contains(listener);
    }

    public function removeEventListener(type:String, listener:Dynamic) {
        if (!this._listeners.exists(type)) {
            return;
        }

        var listenerArray = this._listeners.get(type);
        var index = listenerArray.indexOf(listener);

        if (index != -1) {
            listenerArray.splice(index, 1);
        }
    }

    public function dispatchEvent(event:Dynamic) {
        if (!this._listeners.exists(event.type)) {
            return;
        }

        var listenerArray = this._listeners.get(event.type);
        event.target = this;

        // Make a copy, in case listeners are removed while iterating.
        var array = listenerArray.slice();

        for (i in 0...array.length) {
            array[i](event);
        }

        event.target = null;
    }
}