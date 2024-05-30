import haxe.unit.TestCase;
import haxe.unit.Test;
import js.Browser;

class EventDispatcherTest extends TestCase {
    public function testInstancing():Void {
        var object = new js.event.EventDispatcher();
        this.assertTrue(object != null, "Can instantiate an EventDispatcher.");
    }

    public function testAddEventListener():Void {
        var eventDispatcher = new js.event.EventDispatcher();
        var listener = { };

        eventDispatcher.addEventListener("anyType", listener);
        this.assertEqual(eventDispatcher._listeners.get("anyType").length, 1, "Listener with unknown type was added.");
        this.assertEqual(eventDispatcher._listeners.get("anyType")[0], listener, "Listener with unknown type was added.");

        eventDispatcher.addEventListener("anyType", listener);
        this.assertEqual(eventDispatcher._listeners.get("anyType").length, 1, "Can't add one listener twice to the same type.");
        this.assertEqual(eventDispatcher._listeners.get("anyType")[0], listener, "Listener is still there.");
    }

    public function testHasEventListener():Void {
        var eventDispatcher = new js.event.EventDispatcher();
        var listener = { };

        eventDispatcher.addEventListener("anyType", listener);
        this.assertTrue(eventDispatcher.hasEventListener("anyType", listener), "Listener was found.");
        this.assertFalse(eventDispatcher.hasEventListener("anotherType", listener), "Listener was not found, which is good.");
    }

    public function testRemoveEventListener():Void {
        var eventDispatcher = new js.event.EventDispatcher();
        var listener = { };

        this.assertNull(eventDispatcher._listeners, "There are no listeners by default.");

        eventDispatcher.addEventListener("anyType", listener);
        this.assertEqual(eventDispatcher._listeners.keys().length, 1, "If a listener was added, there is a new key.");
        this.assertEqual(eventDispatcher._listeners.get("anyType").length, 1, "If a listener was added, there is a new key.");

        eventDispatcher.removeEventListener("anyType", listener);
        this.assertEqual(eventDispatcher._listeners.get("anyType").length, 0, "Listener was deleted.");

        eventDispatcher.removeEventListener("unknownType", listener);
        this.assertNull(eventDispatcher._listeners.get("unknownType"), "Unknown types will be ignored.");

        eventDispatcher.removeEventListener("anyType", null);
        this.assertEqual(eventDispatcher._listeners.get("anyType").length, 0, "Null listeners are ignored.");
    }

    public function testDispatchEvent():Void {
        var eventDispatcher = new js.event.EventDispatcher();
        var callCount = 0;
        var listener = function() {
            callCount++;
        };

        eventDispatcher.addEventListener("anyType", listener);
        this.assertEqual(callCount, 0, "No event, no call.");

        eventDispatcher.dispatchEvent(new js.event.Event("anyType"));
        this.assertEqual(callCount, 1, "One event, one call.");

        eventDispatcher.dispatchEvent(new js.event.Event("anyType"));
        this.assertEqual(callCount, 2, "Two events, two calls.");
    }
}

class EventDispatcherSuite extends js.event.Event {
    public static function __init__() {
        #if js
        Test.suite(EventDispatcherTest);
        #end
    }
}