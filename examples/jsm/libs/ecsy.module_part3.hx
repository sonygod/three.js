package three.js.examples.jsm.libs;

class EventDispatcher {
  private var _listeners:Map<String, Array<Dynamic -> Void>>;
  public var stats: {
    fired:Int,
    handled:Int
  };

  public function new() {
    _listeners = new Map();
    stats = { fired: 0, handled: 0 };
  }

  /**
   * Add an event listener
   * @param eventName Name of the event to listen
   * @param listener Callback to trigger when the event is fired
   */
  public function addEventListener(eventName:String, listener:Dynamic -> Void) {
    if (!_listeners.exists(eventName)) {
      _listeners.set(eventName, []);
    }
    var listeners:Array<Dynamic -> Void> = _listeners.get(eventName);
    if (listeners.indexOf(listener) == -1) {
      listeners.push(listener);
    }
  }

  /**
   * Check if an event listener is already added to the list of listeners
   * @param eventName Name of the event to check
   * @param listener Callback for the specified event
   */
  public function hasEventListener(eventName:String, listener:Dynamic -> Void):Bool {
    return _listeners.exists(eventName) && _listeners.get(eventName).indexOf(listener) != -1;
  }

  /**
   * Remove an event listener
   * @param eventName Name of the event to remove
   * @param listener Callback for the specified event
   */
  public function removeEventListener(eventName:String, listener:Dynamic -> Void) {
    if (_listeners.exists(eventName)) {
      var listeners:Array<Dynamic -> Void> = _listeners.get(eventName);
      var index:Int = listeners.indexOf(listener);
      if (index != -1) {
        listeners.splice(index, 1);
      }
    }
  }

  /**
   * Dispatch an event
   * @param eventName Name of the event to dispatch
   * @param entity (Optional) Entity to emit
   * @param component
   */
  public function dispatchEvent(eventName:String, ?entity:Dynamic, ?component:Dynamic) {
    stats.fired++;

    if (_listeners.exists(eventName)) {
      var listeners:Array<Dynamic -> Void> = _listeners.get(eventName);
      var array:Array<Dynamic -> Void> = listeners.copy();
      for (i in 0...array.length) {
        array[i](entity, component);
      }
    }
  }

  /**
   * Reset stats counters
   */
  public function resetCounters() {
    stats.fired = 0;
    stats.handled = 0;
  }
}