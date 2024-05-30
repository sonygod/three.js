package;

import js.Lib;
import three.src.core.InstancedInterleavedBuffer;
import three.src.core.InterleavedBuffer;

class InstancedInterleavedBufferTest {
    static function main() {
        QUnit.module('Core', () -> {
            QUnit.module('InstancedInterleavedBuffer', () -> {
                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var object = new InstancedInterleavedBuffer();
                    assert.strictEqual(
                        Std.is(object, InterleavedBuffer), true,
                        'InstancedInterleavedBuffer extends from InterleavedBuffer'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var array = [1, 2, 3, 7, 8, 9];
                    var instance = new InstancedInterleavedBuffer(array, 3);
                    assert.ok(instance.meshPerAttribute == 1, 'ok');
                });

                // PROPERTIES
                QUnit.todo('meshPerAttribute', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isInstancedInterleavedBuffer', (assert) -> {
                    var object = new InstancedInterleavedBuffer();
                    assert.ok(
                        object.isInstancedInterleavedBuffer,
                        'InstancedInterleavedBuffer.isInstancedInterleavedBuffer should be true'
                    );
                });

                QUnit.test('copy', (assert) -> {
                    var array = [1, 2, 3, 7, 8, 9];
                    var instance = new InstancedInterleavedBuffer(array, 3);
                    var copiedInstance = instance.copy(instance);
                    assert.ok(copiedInstance.meshPerAttribute == 1, 'additional attribute was copied');
                });

                QUnit.todo('clone', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('toJSON', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}