// haxe
import three.core.InstancedBufferAttribute;
import three.core.BufferAttribute;
import qunit.QUnit;

QUnit.module("Core", () -> {
    QUnit.module("InstancedBufferAttribute", () -> {
        QUnit.test("Extending", (assert) -> {
            var object = new BufferAttribute();
            assert.isTrue(Std.is(object, BufferAttribute), "BufferAttribute extends from BufferAttribute");
        });

        QUnit.test("Instancing", (assert) -> {
            var instance = new InstancedBufferAttribute(new Float(10), 2);
            assert.isTrue(instance.meshPerAttribute == 1, "Can instantiate an InstancedBufferGeometry.");

            instance = new InstancedBufferAttribute(new Float(10), 2, false, 123);
            assert.isTrue(instance.meshPerAttribute == 123, "Can instantiate an InstancedBufferGeometry with array, itemSize, normalized, and meshPerAttribute.");
        });

        QUnit.todo("meshPerAttribute", (assert) -> {
            assert.isTrue(false, "everything's gonna be alright");
        });

        QUnit.test("isInstancedBufferAttribute", (assert) -> {
            var object = new InstancedBufferAttribute();
            assert.isTrue(object.isInstancedBufferAttribute, "InstancedBufferAttribute.isInstancedBufferAttribute should be true");
        });

        QUnit.test("copy", (assert) -> {
            var array = [1.0, 2.0, 3.0, 7.0, 8.0, 9.0];
            var instance = new InstancedBufferAttribute(array, 2, true, 123);
            var copiedInstance = instance.copy(instance);

            assert.isTrue(Std.is(copiedInstance, InstancedBufferAttribute), "the clone has the correct type");
            assert.isTrue(copiedInstance.itemSize == 2, "itemSize was copied");
            assert.isTrue(copiedInstance.normalized == true, "normalized was copied");
            assert.isTrue(copiedInstance.meshPerAttribute == 123, "meshPerAttribute was copied");

            for (i in 0...array.length) {
                assert.isTrue(copiedInstance.array[i] == array[i], "array was copied");
            }
        });

        QUnit.todo("toJSON", (assert) -> {
            assert.isTrue(false, "everything's gonna be alright");
        });
    });
});