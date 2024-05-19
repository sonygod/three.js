package three.js.test.unit.src.core;

import QUnit in three.js.test.unit.src.QUnit;
import InstancedInterleavedBuffer in three.js.src.core.InstancedInterleavedBuffer;
import InterleavedBuffer in three.js.src.core.InterleavedBuffer;

class InstancedInterleavedBufferTests {
    public static function main() {
        QUnit.module("Core", () => {
            QUnit.module("InstancedInterleavedBuffer", () => {
                // INHERITANCE
                QUnit.test("Extending", (assert:QUnitAssert) => {
                    var object = new InstancedInterleavedBuffer();
                    assert.isTrue((object instanceof InterleavedBuffer), 'InstancedInterleavedBuffer extends from InterleavedBuffer');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert:QUnitAssert) => {
                    var array = new Float32Array([1, 2, 3, 7, 8, 9]);
                    var instance = new InstancedInterleavedBuffer(array, 3);
                    assert.ok(instance.meshPerAttribute == 1, 'ok');
                });

                // PROPERTIES
                QUnit.todo("meshPerAttribute", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isInstancedInterleavedBuffer", (assert:QUnitAssert) => {
                    var object = new InstancedInterleavedBuffer();
                    assert.ok(object.isInstancedInterleavedBuffer, 'InstancedInterleavedBuffer.isInstancedInterleavedBuffer should be true');
                });

                QUnit.test("copy", (assert:QUnitAssert) => {
                    var array = new Float32Array([1, 2, 3, 7, 8, 9]);
                    var instance = new InstancedInterleavedBuffer(array, 3);
                    var copiedInstance = instance.copy(instance);
                    assert.ok(copiedInstance.meshPerAttribute == 1, 'additional attribute was copied');
                });

                QUnit.todo("clone", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("toJSON", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}