package;

import three.js.test.unit.src.core.EventDispatcher;
import js.Lib;

class EventDispatcherTest {
    static function main() {
        QUnit.module('Core', () -> {
            QUnit.module('EventDispatcher', () -> {
                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new EventDispatcher();
                    assert.ok(object != null, 'Can instantiate an EventDispatcher.');
                });

                // PUBLIC
                QUnit.test('addEventListener', (assert) -> {
                    var eventDispatcher = new EventDispatcher();
                    var listener = {};
                    eventDispatcher.addEventListener('anyType', listener);
                    assert.ok(eventDispatcher._listeners.anyType.length == 1, 'listener with unknown type was added');
                    assert.ok(eventDispatcher._listeners.anyType[0] == listener, 'listener with unknown type was added');
                    eventDispatcher.addEventListener('anyType', listener);
                    assert.ok(eventDispatcher._listeners.anyType.length == 1, 'can\'t add one listener twice to same type');
                    assert.ok(eventDispatcher._listeners.anyType[0] == listener, 'listener is still there');
                });

                QUnit.test('hasEventListener', (assert) -> {
                    var eventDispatcher = new EventDispatcher();
                    var listener = {};
                    eventDispatcher.addEventListener('anyType', listener);
                    assert.ok(eventDispatcher.hasEventListener('anyType', listener), 'listener was found');
                    assert.ok(!eventDispatcher.hasEventListener('anotherType', listener), 'listener was not found which is good');
                });

                QUnit.test('removeEventListener', (assert) -> {
                    var eventDispatcher = new EventDispatcher();
                    var listener = {};
                    assert.ok(eventDispatcher._listeners == null, 'there are no listeners by default');
                    eventDispatcher.addEventListener('anyType', listener);
                    assert.ok(Lib.keys(eventDispatcher._listeners).length == 1 && eventDispatcher._listeners.anyType.length == 1, 'if a listener was added, there is a new key');
                    eventDispatcher.removeEventListener('anyType', listener);
                    assert.ok(eventDispatcher._listeners.anyType.length == 0, 'listener was deleted');
                    eventDispatcher.removeEventListener('unknownType', listener);
                    assert.ok(eventDispatcher._listeners.unknownType == null, 'unknown types will be ignored');
                    eventDispatcher.removeEventListener('anyType', null);
                    assert.ok(eventDispatcher._listeners.anyType.length == 0, 'null listeners are ignored');
                });

                QUnit.test('dispatchEvent', (assert) -> {
                    var eventDispatcher = new EventDispatcher();
                    var callCount = 0;
                    var listener = function () {
                        callCount++;
                    };
                    eventDispatcher.addEventListener('anyType', listener);
                    assert.ok(callCount == 0, 'no event, no call');
                    eventDispatcher.dispatchEvent({type: 'anyType'});
                    assert.ok(callCount == 1, 'one event, one call');
                    eventDispatcher.dispatchEvent({type: 'anyType'});
                    assert.ok(callCount == 2, 'two events, two calls');
                });
            });
        });
    }
}