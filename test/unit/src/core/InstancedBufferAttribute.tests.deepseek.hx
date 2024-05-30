package;

import js.Lib;
import three.src.core.InstancedBufferAttribute;
import three.src.core.BufferAttribute;

class InstancedBufferAttributeTest {

    static function main() {
        // INHERITANCE
        var object = new BufferAttribute();
        Lib.assert(object instanceof BufferAttribute, "BufferAttribute extends from BufferAttribute");

        // INSTANCING
        var instance = new InstancedBufferAttribute(new js.Float32Array([10]), 2);
        Lib.assert(instance.meshPerAttribute == 1, "Can instantiate an InstancedBufferGeometry.");

        instance = new InstancedBufferAttribute(new js.Float32Array([10]), 2, false, 123);
        Lib.assert(instance.meshPerAttribute == 123, "Can instantiate an InstancedBufferGeometry with array, itemSize, normalized, and meshPerAttribute.");

        // PROPERTIES
        // TODO: meshPerAttribute

        // PUBLIC
        var object = new InstancedBufferAttribute();
        Lib.assert(object.isInstancedBufferAttribute, "InstancedBufferAttribute.isInstancedBufferAttribute should be true");

        var array = new js.Float32Array([1, 2, 3, 7, 8, 9]);
        instance = new InstancedBufferAttribute(array, 2, true, 123);
        var copiedInstance = instance.copy(instance);

        Lib.assert(copiedInstance instanceof InstancedBufferAttribute, "the clone has the correct type");
        Lib.assert(copiedInstance.itemSize == 2, "itemSize was copied");
        Lib.assert(copiedInstance.normalized == true, "normalized was copied");
        Lib.assert(copiedInstance.meshPerAttribute == 123, "meshPerAttribute was copied");

        for (i in 0...array.length) {
            Lib.assert(copiedInstance.array[i] == array[i], "array was copied");
        }

        // TODO: toJSON
    }
}