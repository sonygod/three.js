import js.QUnit;
import three.src.core.InterleavedBuffer;
import three.src.constants.DynamicDrawUsage;

class InterleavedBufferTests {
    public function new() {
        QUnit.module("Core", () -> {
            QUnit.module("InterleavedBuffer", () -> {
                function checkInstanceAgainstCopy(instance:InterleavedBuffer, copiedInstance:InterleavedBuffer, assert:js.QUnit.Assert) {
                    assert.ok(js.Boot.instanceof(copiedInstance, InterleavedBuffer), 'the clone has the correct type');

                    for (var i:Int = 0; i < instance.array.length; i ++) {
                        assert.ok(copiedInstance.array[i] == instance.array[i], 'array was copied');
                    }

                    assert.ok(copiedInstance.stride == instance.stride, 'stride was copied');
                    assert.ok(copiedInstance.usage == DynamicDrawUsage, 'usage was copied');
                }

                QUnit.test("Instancing", (assert:js.QUnit.Assert) -> {
                    var object = new InterleavedBuffer();
                    assert.ok(object != null, 'Can instantiate an InterleavedBuffer.');
                });

                QUnit.test("needsUpdate", (assert:js.QUnit.Assert) -> {
                    var a = new InterleavedBuffer(new js.Float32Array([1, 2, 3, 4]), 2);
                    a.needsUpdate = true;

                    assert.strictEqual(a.version, 1, 'Check version increased');
                });

                QUnit.test("isInterleavedBuffer", (assert:js.QUnit.Assert) -> {
                    var object = new InterleavedBuffer();
                    assert.ok(
                        object.isInterleavedBuffer,
                        'InterleavedBuffer.isInterleavedBuffer should be true'
                    );
                });

                QUnit.test("setUsage", (assert:js.QUnit.Assert) -> {
                    var instance = new InterleavedBuffer();
                    instance.setUsage(DynamicDrawUsage);

                    assert.strictEqual(instance.usage, DynamicDrawUsage, 'Usage was set');
                });

                QUnit.test("copy", (assert:js.QUnit.Assert) -> {
                    var array = new js.Float32Array([1, 2, 3, 7, 8, 9]);
                    var instance = new InterleavedBuffer(array, 3);
                    instance.setUsage(DynamicDrawUsage);

                    checkInstanceAgainstCopy(instance, instance.copy(instance), assert);
                });

                QUnit.test("copyAt", (assert:js.QUnit.Assert) -> {
                    var a = new InterleavedBuffer(new js.Float32Array([1, 2, 3, 4, 5, 6, 7, 8, 9]), 3);
                    var b = new InterleavedBuffer(new js.Float32Array(9), 3);
                    var expected = new js.Float32Array([4, 5, 6, 7, 8, 9, 1, 2, 3]);

                    b.copyAt(1, a, 2);
                    b.copyAt(0, a, 1);
                    b.copyAt(2, a, 0);

                    assert.deepEqual(b.array, expected, 'Check the right values were replaced');
                });

                QUnit.test("set", (assert:js.QUnit.Assert) -> {
                    var instance = new InterleavedBuffer(new js.Float32Array([1, 2, 3, 7, 8, 9]), 3);

                    instance.set([0, -1]);
                    assert.ok(instance.array[0] == 0 && instance.array[1] == -1, 'replace at first by default');
                });

                QUnit.test("onUpload", (assert:js.QUnit.Assert) -> {
                    var a = new InterleavedBuffer();
                    var func = function() {};

                    a.onUpload(func);

                    assert.strictEqual(a.onUploadCallback, func, 'Check callback was set properly');
                });

                QUnit.test("count", (assert:js.QUnit.Assert) -> {
                    var instance = new InterleavedBuffer(new js.Float32Array([1, 2, 3, 7, 8, 9]), 3);

                    assert.equal(instance.count, 2, 'count is calculated via array length / stride');
                });
            });
        });
    }
}