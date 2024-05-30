package three.test.unit.src.core;

import three.core.InstancedBufferAttribute;
import three.core.BufferAttribute;

class InstancedBufferAttributeTests {
    public function new() {}

    public static function main() {
        // INHERITANCE
        TestCase.test("Extending", function(assert) {
            var object = new BufferAttribute();
            assert.ok(object instanceof BufferAttribute, "BufferAttribute extends from BufferAttribute");
        });

        // INSTANCING
        TestCase.test("Instancing", function(assert) {
            // array, itemSize
            var instance = new InstancedBufferAttribute(new Float32Array(10), 2);
            assert.ok(instance.meshPerAttribute == 1, "Can instantiate an InstancedBufferGeometry.");

            // array, itemSize, normalized, meshPerAttribute
            instance = new InstancedBufferAttribute(new Float32Array(10), 2, false, 123);
            assert.ok(instance.meshPerAttribute == 123, "Can instantiate an InstancedBufferGeometry with array, itemSize, normalized, and meshPerAttribute.");
        });

        // PROPERTIES
        TestCase.todo("meshPerAttribute", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        TestCase.test("isInstancedBufferAttribute", function(assert) {
            var object = new InstancedBufferAttribute();
            assert.ok(object.isInstancedBufferAttribute, "InstancedBufferAttribute.isInstancedBufferAttribute should be true");
        });

        TestCase.test("copy", function(assert) {
            var array = new Float32Array([1, 2, 3, 7, 8, 9]);
            var instance = new InstancedBufferAttribute(array, 2, true, 123);
            var copiedInstance = instance.copy(instance);

            assert.ok(copiedInstance instanceof InstancedBufferAttribute, "the clone has the correct type");
            assert.ok(copiedInstance.itemSize == 2, "itemSize was copied");
            assert.ok(copiedInstance.normalized == true, "normalized was copied");
            assert.ok(copiedInstance.meshPerAttribute == 123, "meshPerAttribute was copied");

            for (i in 0...array.length) {
                assert.ok(copiedInstance.array[i] == array[i], "array was copied");
            }
        });

        TestCase.todo("toJSON", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}