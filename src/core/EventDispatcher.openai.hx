package three.js.src.core;

import haxe.ds.StringMap;

class EventDispatcher {
  private var _listeners:StringMap<Array<Void->Void>>;

  public function addEventListener(type:String, listener:Void->Void) {
    if (_listeners == null) _listeners = new StringMap();
    if (!_listeners.exists(type)) _listeners.set(type, new Array());
    if (_listeners.get(type).indexOf(listener) == -1) _listeners.get(type).push(listener);
  }

  public function hasEventListener(type:String, listener:Void->Void) {
    if (_listeners == null) return false;
    return _listeners.exists(type) && _listeners.get(type).indexOf(listener) != -1;
  }

  public function removeEventListener(type:String, listener:Void->Void) {
    if (_listeners == null) return;
    if (_listeners.exists(type)) {
      var listenerArray = _listeners.get(type);
      var index = listenerArray.indexOf(listener);
      if (index != -1) listenerArray.splice(index, 1);
    }
  }

  public function dispatchEvent(event:{type:String}) {
    if (_listeners == null) return;
    if (_listeners.exists(event.type)) {
      var listenerArray = _listeners.get(event.type);
      event.target = this;
      var array = listenerArray.copy();
      for (i in 0...array.length) {
        array[i](event);
      }
      event.target = null;
    }
  }
}