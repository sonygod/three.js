package three.core;

import haxe.unit.TestCase;

class EventDispatcherTests {
    public function new() {}

    public function testInstancing() {
        var object = new EventDispatcher();
        assertTrue(object != null, "Can instantiate an EventDispatcher.");
    }

    public function testAddEventListener() {
        var eventDispatcher = new EventDispatcher();
        var listener = {};
        eventDispatcher.addEventListener("anyType", listener);

        assertTrue(eventDispatcher._listeners.anyType.length == 1, "listener with unknown type was added");
        assertTrue(eventDispatcher._listeners.anyType[0] == listener, "listener with unknown type was added");

        eventDispatcher.addEventListener("anyType", listener);
        assertTrue(eventDispatcher._listeners.anyType.length == 1, "can't add one listener twice to same type");
        assertTrue(eventDispatcher._listeners.anyType[0] == listener, "listener is still there");
    }

    public function testHasEventListener() {
        var eventDispatcher = new EventDispatcher();
        var listener = {};
        eventDispatcher.addEventListener("anyType", listener);

        assertTrue(eventDispatcher.hasEventListener("anyType", listener), "listener was found");
        assertFalse(eventDispatcher.hasEventListener("anotherType", listener), "listener was not found which is good");
    }

    public function testRemoveEventListener() {
        var eventDispatcher = new EventDispatcher();
        var listener = {};

        assertTrue(eventDispatcher._listeners == null, "there are no listeners by default");

        eventDispatcher.addEventListener("anyType", listener);
        assertTrue(Object.keys(eventDispatcher._listeners).length == 1 && eventDispatcher._listeners.anyType.length == 1, "if a listener was added, there is a new key");

        eventDispatcher.removeEventListener("anyType", listener);
        assertTrue(eventDispatcher._listeners.anyType.length == 0, "listener was deleted");

        eventDispatcher.removeEventListener("unknownType", listener);
        assertTrue(eventDispatcher._listeners.unknownType == null, "unknown types will be ignored");

        eventDispatcher.removeEventListener("anyType", null);
        assertTrue(eventDispatcher._listeners.anyType.length == 0, "undefined listeners are ignored");
    }

    public function testDispatchEvent() {
        var eventDispatcher = new EventDispatcher();
        var callCount = 0;
        var listener = function() {
            callCount++;
        };

        eventDispatcher.addEventListener("anyType", listener);
        assertEquals(callCount, 0, "no event, no call");

        eventDispatcher.dispatchEvent({ type: "anyType" });
        assertEquals(callCount, 1, "one event, one call");

        eventDispatcher.dispatchEvent({ type: "anyType" });
        assertEquals(callCount, 2, "two events, two calls");
    }
}