import qunit.QUnit;
import three.core.InterleavedBufferAttribute;
import three.core.InterleavedBuffer;

@:jsRequire("three/src/core/InterleavedBufferAttribute.js")
@:jsRequire("three/src/core/InterleavedBuffer.js")
class InterleavedBufferAttributeTests {
    static function main() {
        QUnit.module("Core", () -> {
            QUnit.module("InterleavedBufferAttribute", () -> {
                // INSTANCING
                QUnit.test("Instancing", assert -> {
                    var object = new InterleavedBufferAttribute();
                    assert.ok(object, "Can instantiate an InterleavedBufferAttribute.");
                });

                // PROPERTIES
                QUnit.test("count", assert -> {
                    var buffer = new InterleavedBuffer(new js.Float32Array([1, 2, 3, 7, 8, 9]), 3);
                    var instance = new InterleavedBufferAttribute(buffer, 2, 0);

                    assert.ok(instance.count == 2, "count is calculated via array length / stride");
                });

                // PUBLIC
                QUnit.test("isInterleavedBufferAttribute", assert -> {
                    var object = new InterleavedBufferAttribute();
                    assert.ok(object.isInterleavedBufferAttribute(), "InterleavedBufferAttribute.isInterleavedBufferAttribute should be true");
                });

                QUnit.test("setX", assert -> {
                    var buffer = new InterleavedBuffer(new js.Float32Array([1, 2, 3, 7, 8, 9]), 3);
                    var instance = new InterleavedBufferAttribute(buffer, 2, 0);

                    instance.setX(0, 123);
                    instance.setX(1, 321);

                    assert.ok(instance.data.array[0] == 123 && instance.data.array[3] == 321, "x was calculated correct based on index and default offset");

                    buffer = new InterleavedBuffer(new js.Float32Array([1, 2, 3, 7, 8, 9]), 3);
                    instance = new InterleavedBufferAttribute(buffer, 2, 1);

                    instance.setX(0, 123);
                    instance.setX(1, 321);

                    assert.ok(instance.data.array[1] == 123 && instance.data.array[4] == 321, "x was calculated correct based on index and default offset");
                });
            });
        });
    }
}