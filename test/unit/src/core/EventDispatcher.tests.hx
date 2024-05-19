package three.test.unit.src.core;

import three.core.EventDispatcher;

class EventDispatcherTests {
    public static function main() {
        unit.tests.CoreTests.test("EventDispatcher", () -> {
            // INSTANCING
            unit.tests.CoreTests.test("Instancing", () -> {
                var object = new EventDispatcher();
                unit.Assert.isTrue(object != null, "Can instantiate an EventDispatcher.");
            });

            // PUBLIC
            unit.tests.CoreTests.test("addEventListener", () -> {
                var eventDispatcher = new EventDispatcher();

                var listener = {};
                eventDispatcher.addEventListener("anyType", listener);

                unit.Assert.isTrue(eventDispatcher._listeners["anyType"].length == 1, "listener with unknown type was added");
                unit.Assert.isTrue(eventDispatcher._listeners["anyType"][0] == listener, "listener with unknown type was added");

                eventDispatcher.addEventListener("anyType", listener);

                unit.Assert.isTrue(eventDispatcher._listeners["anyType"].length == 1, "can't add one listener twice to same type");
                unit.Assert.isTrue(eventDispatcher._listeners["anyType"][0] == listener, "listener is still there");
            });

            unit.tests.CoreTests.test("hasEventListener", () -> {
                var eventDispatcher = new EventDispatcher();

                var listener = {};
                eventDispatcher.addEventListener("anyType", listener);

                unit.Assert.isTrue(eventDispatcher.hasEventListener("anyType", listener), "listener was found");
                unit.Assert.isFalse(eventDispatcher.hasEventListener("anotherType", listener), "listener was not found which is good");
            });

            unit.tests.CoreTests.test("removeEventListener", () -> {
                var eventDispatcher = new EventDispatcher();

                var listener = {};

                unit.Assert.isTrue(eventDispatcher._listeners == null, "there are no listeners by default");

                eventDispatcher.addEventListener("anyType", listener);
                unit.Assert.isTrue(Object.keys(eventDispatcher._listeners).length == 1 && eventDispatcher._listeners["anyType"].length == 1, "if a listener was added, there is a new key");

                eventDispatcher.removeEventListener("anyType", listener);
                unit.Assert.isTrue(eventDispatcher._listeners["anyType"].length == 0, "listener was deleted");

                eventDispatcher.removeEventListener("unknownType", listener);
                unit.Assert.isTrue(eventDispatcher._listeners["unknownType"] == null, "unknown types will be ignored");

                eventDispatcher.removeEventListener("anyType", null);
                unit.Assert.isTrue(eventDispatcher._listeners["anyType"].length == 0, "undefined listeners are ignored");
            });

            unit.tests.CoreTests.test("dispatchEvent", () -> {
                var eventDispatcher = new EventDispatcher();

                var callCount = 0;
                var listener = () -> {
                    callCount++;
                };

                eventDispatcher.addEventListener("anyType", listener);
                unit.Assert.isTrue(callCount == 0, "no event, no call");

                eventDispatcher.dispatchEvent({ type: "anyType" });
                unit.Assert.isTrue(callCount == 1, "one event, one call");

                eventDispatcher.dispatchEvent({ type: "anyType" });
                unit.Assert.isTrue(callCount == 2, "two events, two calls");
            });
        });
    }
}