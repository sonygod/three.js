package;

import js.QUnit.QUnit;
import js.Three.InstancedBufferAttribute;
import js.Three.BufferAttribute;

class _Test {
    static public function main() {
        QUnit.module('Core', function() {
            QUnit.module('InstancedBufferAttribute', function() {
                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var object = new BufferAttribute();
                    assert.strictEqual(object instanceof BufferAttribute, true, 'BufferAttribute extends from BufferAttribute');
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    // array, itemSize
                    var instance = new InstancedBufferAttribute(new Float32Array(10), 2);
                    assert.ok(instance.meshPerAttribute == 1, 'Can instantiate an InstancedBufferGeometry.');

                    // array, itemSize, normalized, meshPerAttribute
                    instance = new InstancedBufferAttribute(new Float32Array(10), 2, false, 123);
                    assert.ok(instance.meshPerAttribute == 123, 'Can instantiate an InstancedBufferGeometry with array, itemSize, normalized, and meshPerAttribute.');
                });

                // PROPERTIES
                QUnit.todo('meshPerAttribute', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isInstancedBufferAttribute', function(assert) {
                    var object = new InstancedBufferAttribute();
                    assert.ok(object.isInstancedBufferAttribute, 'InstancedBufferAttribute.isInstancedBufferAttribute should be true');
                });

                QUnit.test('copy', function(assert) {
                    var array = new Float32Array([1, 2, 3, 7, 8, 9]);
                    var instance = new InstancedBufferAttribute(array, 2, true, 123);
                    var copiedInstance = instance.copy(instance);

                    assert.ok(copiedInstance instanceof InstancedBufferAttribute, 'the clone has the correct type');
                    assert.ok(copiedInstance.itemSize == 2, 'itemSize was copied');
                    assert.ok(copiedInstance.normalized, 'normalized was copied');
                    assert.ok(copiedInstance.meshPerAttribute == 123, 'meshPerAttribute was copied');

                    for (var i = 0; i < array.length; i++) {
                        assert.ok(copiedInstance.array[i] == array[i], 'array was copied');
                    }
                });

                QUnit.todo('toJSON', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}