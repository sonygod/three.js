import qunit.QUnit;
import three.core.InterleavedBuffer;
import three.constants.DynamicDrawUsage;

class InterleavedBufferTest extends qunit.QUnit {

	static function main() {
		new InterleavedBufferTest().run();
	}

	public function new() {
		super();
		module("Core", function() {
			module("InterleavedBuffer", function() {
				function checkInstanceAgainstCopy(instance:InterleavedBuffer, copiedInstance:InterleavedBuffer, assert:qunit.Assert) {
					assert.ok(copiedInstance.isInterleavedBuffer, "the clone has the correct type");

					for (i in 0...instance.array.length) {
						assert.ok(copiedInstance.array[i] == instance.array[i], "array was copied");
					}

					assert.ok(copiedInstance.stride == instance.stride, "stride was copied");
					assert.ok(copiedInstance.usage == DynamicDrawUsage, "usage was copied");
				}

				// INSTANCING
				test("Instancing", function(assert:qunit.Assert) {
					var object = new InterleavedBuffer();
					assert.ok(object, "Can instantiate an InterleavedBuffer.");
				});

				// PROPERTIES
				todo("array", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("stride", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("count", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("usage", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("updateRanges", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("version", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("uuid", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("onUploadCallback", function(assert:qunit.Assert) {
					// onUploadCallback() {} declared but used as property, refactor req
					assert.ok(false, "everything's gonna be alright");
				});

				test("needsUpdate", function(assert:qunit.Assert) {
					var a = new InterleavedBuffer(new Float32Array([1, 2, 3, 4]), 2);
					a.needsUpdate = true;

					assert.strictEqual(a.version, 1, "Check version increased");
				});

				// PUBLIC
				test("isInterleavedBuffer", function(assert:qunit.Assert) {
					var object = new InterleavedBuffer();
					assert.ok(
						object.isInterleavedBuffer,
						"InterleavedBuffer.isInterleavedBuffer should be true"
					);
				});

				test("setUsage", function(assert:qunit.Assert) {
					var instance = new InterleavedBuffer();
					instance.setUsage(DynamicDrawUsage);

					assert.strictEqual(instance.usage, DynamicDrawUsage, "Usage was set");
				});

				test("copy", function(assert:qunit.Assert) {
					var array = new Float32Array([1, 2, 3, 7, 8, 9]);
					var instance = new InterleavedBuffer(array, 3);
					instance.setUsage(DynamicDrawUsage);

					checkInstanceAgainstCopy(instance, instance.copy(instance), assert);
				});

				test("copyAt", function(assert:qunit.Assert) {
					var a = new InterleavedBuffer(new Float32Array([1, 2, 3, 4, 5, 6, 7, 8, 9]), 3);
					var b = new InterleavedBuffer(new Float32Array(9), 3);
					var expected = new Float32Array([4, 5, 6, 7, 8, 9, 1, 2, 3]);

					b.copyAt(1, a, 2);
					b.copyAt(0, a, 1);
					b.copyAt(2, a, 0);

					assert.deepEqual(b.array, expected, "Check the right values were replaced");
				});

				test("set", function(assert:qunit.Assert) {
					var instance = new InterleavedBuffer(new Float32Array([1, 2, 3, 7, 8, 9]), 3);

					instance.set([0, - 1]);
					assert.ok(instance.array[0] == 0 && instance.array[1] == - 1, "replace at first by default");
				});

				todo("clone", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				test("onUpload", function(assert:qunit.Assert) {
					var a = new InterleavedBuffer();
					var func = function() {};

					a.onUpload(func);

					assert.strictEqual(a.onUploadCallback, func, "Check callback was set properly");
				});

				todo("toJSON", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				// OTHERS
				test("count", function(assert:qunit.Assert) {
					var instance = new InterleavedBuffer(new Float32Array([1, 2, 3, 7, 8, 9]), 3);

					assert.equal(instance.count, 2, "count is calculated via array length / stride");
				});
			});
		});
	}
}

InterleavedBufferTest.main();