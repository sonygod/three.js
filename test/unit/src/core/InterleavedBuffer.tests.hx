import haxe.unit.TestCase;

import three.InterleavedBuffer;
import three.constants.DynamicDrawUsage;

class InterleavedBufferTests {
    public function new() {}

    public function testInterleavedBuffer() {
        TestCase.addTest("Core", "InterleavedBuffer", [
            TestCase.test("Instancing", function(assert) {
                var object = new InterleavedBuffer();
                assert.notNull(object, "Can instantiate an InterleavedBuffer.");
            }),

            TestCase.test("needsUpdate", function(assert) {
                var a = new InterleavedBuffer(new Float32Array([1, 2, 3, 4]), 2);
                a.needsUpdate = true;
                assert.AreEqual(1, a.version, "Check version increased");
            }),

            TestCase.test("isInterleavedBuffer", function(assert) {
                var object = new InterleavedBuffer();
                assert.isTrue(object.isInterleavedBuffer, "InterleavedBuffer.isInterleavedBuffer should be true");
            }),

            TestCase.test("setUsage", function(assert) {
                var instance = new InterleavedBuffer();
                instance.setUsage(DynamicDrawUsage);
                assert.AreEqual(DynamicDrawUsage, instance.usage, "Usage was set");
            }),

            TestCase.test("copy", function(assert) {
                var array = new Float32Array([1, 2, 3, 7, 8, 9]);
                var instance = new InterleavedBuffer(array, 3);
                instance.setUsage(DynamicDrawUsage);
                checkInstanceAgainstCopy(instance, instance.copy(instance), assert);
            }),

            TestCase.test("copyAt", function(assert) {
                var a = new InterleavedBuffer(new Float32Array([1, 2, 3, 4, 5, 6, 7, 8, 9]), 3);
                var b = new InterleavedBuffer(new Float32Array(9), 3);
                var expected = new Float32Array([4, 5, 6, 7, 8, 9, 1, 2, 3]);
                b.copyAt(1, a, 2);
                b.copyAt(0, a, 1);
                b.copyAt(2, a, 0);
                assert.deepEqual(b.array, expected, "Check the right values were replaced");
            }),

            TestCase.test("set", function(assert) {
                var instance = new InterleavedBuffer(new Float32Array([1, 2, 3, 7, 8, 9]), 3);
                instance.set([0, -1]);
                assert.isTrue(instance.array[0] == 0 && instance.array[1] == -1, "replace at first by default");
            }),

            TestCase.test("onUpload", function(assert) {
                var a = new InterleavedBuffer();
                var func = function() {};
                a.onUpload(func);
                assert.AreEqual(func, a.onUploadCallback, "Check callback was set properly");
            }),

            TestCase.test("count", function(assert) {
                var instance = new InterleavedBuffer(new Float32Array([1, 2, 3, 7, 8, 9]), 3);
                assert.AreEqual(2, instance.count, "count is calculated via array length / stride");
            }),
        ]);
    }

    function checkInstanceAgainstCopy(instance:InterleavedBuffer, copiedInstance:InterleavedBuffer, assert:TestCase) {
        assert.isTrue(copiedInstance instanceof InterleavedBuffer, "the clone has the correct type");

        for (i in 0...instance.array.length) {
            assert.AreEqual(instance.array[i], copiedInstance.array[i], "array was copied");
        }

        assert.AreEqual(instance.stride, copiedInstance.stride, "stride was copied");
        assert.AreEqual(DynamicDrawUsage, copiedInstance.usage, "usage was copied");
    }
}