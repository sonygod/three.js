package three.js.test.unit.src.core;

import haxe.unit.TestCase;
import three.core.InterleavedBufferAttribute;
import three.core.InterleavedBuffer;

class InterleavedBufferAttributeTests extends TestCase {

    public function new() {
        super();

        test("Instancing", function(assert) {
            var object:InterleavedBufferAttribute = new InterleavedBufferAttribute();
            assert.isTrue(object != null, "Can instantiate an InterleavedBufferAttribute.");
        });

        // PROPERTIES
        todo("name", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("data", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("itemSize", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("offset", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("normalized", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        test("count", function(assert) {
            var buffer:InterleavedBuffer = new InterleavedBuffer(new Float32Array([1, 2, 3, 7, 8, 9]), 3);
            var instance:InterleavedBufferAttribute = new InterleavedBufferAttribute(buffer, 2, 0);
            assert.isTrue(instance.count == 2, "count is calculated via array length / stride");
        });

        todo("array", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("needsUpdate", function(assert) {
            // set needsUpdate( value )
            assert.isTrue(false, "everything's gonna be alright");
        });

        // PUBLIC
        test("isInterleavedBufferAttribute", function(assert) {
            var object:InterleavedBufferAttribute = new InterleavedBufferAttribute();
            assert.isTrue(object.isInterleavedBufferAttribute, "InterleavedBufferAttribute.isInterleavedBufferAttribute should be true");
        });

        todo("applyMatrix4", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("applyNormalMatrix", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("transformDirection", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        // setY, setZ and setW are calculated in the same way so not testing this
        // TODO: ( you can't be sure that will be the case in future, or a mistake was introduce in one off them ! )
        test("setX", function(assert) {
            var buffer:InterleavedBuffer = new InterleavedBuffer(new Float32Array([1, 2, 3, 7, 8, 9]), 3);
            var instance:InterleavedBufferAttribute = new InterleavedBufferAttribute(buffer, 2, 0);

            instance.setX(0, 123);
            instance.setX(1, 321);

            assert.isTrue(instance.data.array[0] == 123 && instance.data.array[3] == 321, "x was calculated correct based on index and default offset");

            buffer = new InterleavedBuffer(new Float32Array([1, 2, 3, 7, 8, 9]), 3);
            instance = new InterleavedBufferAttribute(buffer, 2, 1);

            instance.setX(0, 123);
            instance.setX(1, 321);

            // the offset was defined as 1, so go one step further in the array
            assert.isTrue(instance.data.array[1] == 123 && instance.data.array[4] == 321, "x was calculated correct based on index and default offset");
        });

        todo("setY", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("setZ", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("setW", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("getX", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("getY", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("getZ", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("getW", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("setXY", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("setXYZ", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("setXYZW", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("clone", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });

        todo("toJSON", function(assert) {
            assert.isTrue(false, "everything's gonna be alright");
        });
    }
}