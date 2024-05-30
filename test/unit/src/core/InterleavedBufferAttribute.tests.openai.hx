import haxe.unit.TestCase;

import three.core.InterleavedBufferAttribute;
import three.core.InterleavedBuffer;

class InterleavedBufferAttributeTests extends TestCase {

    public function testInstancing() {
        var object = new InterleavedBufferAttribute();
        assertEquals(true, object != null, 'Can instantiate an InterleavedBufferAttribute.');
    }

    // PROPERTIES
    public function todo_name() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_data() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_itemSize() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_offset() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_normalized() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testCount() {
        var buffer = new InterleavedBuffer(new Single Precision Floating-Point Array([1, 2, 3, 7, 8, 9]), 3);
        var instance = new InterleavedBufferAttribute(buffer, 2, 0);
        assertEquals(2, instance.count, 'count is calculated via array length / stride');
    }

    public function todo_array() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_needsUpdate() {
        // set needsUpdate( value )
        Assert.fail('everything\'s gonna be alright');
    }

    // PUBLIC
    public function testIsInterleavedBufferAttribute() {
        var object = new InterleavedBufferAttribute();
        assertTrue(object.isInterleavedBufferAttribute, 'InterleavedBufferAttribute.isInterleavedBufferAttribute should be true');
    }

    public function todo_applyMatrix4() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_applyNormalMatrix() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_transformDirection() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testSetX() {
        var buffer = new InterleavedBuffer(new Single Precision Floating-Point Array([1, 2, 3, 7, 8, 9]), 3);
        var instance = new InterleavedBufferAttribute(buffer, 2, 0);

        instance.setX(0, 123);
        instance.setX(1, 321);

        assertTrue(instance.data.array[0] == 123 && instance.data.array[3] == 321, 'x was calculated correct based on index and default offset');

        buffer = new InterleavedBuffer(new Single Precision Floating-Point Array([1, 2, 3, 7, 8, 9]), 3);
        instance = new InterleavedBufferAttribute(buffer, 2, 1);

        instance.setX(0, 123);
        instance.setX(1, 321);

        // the offset was defined as 1, so go one step futher in the array
        assertTrue(instance.data.array[1] == 123 && instance.data.array[4] == 321, 'x was calculated correct based on index and default offset');
    }

    public function todo_setY() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_setZ() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_setW() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_getX() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_getY() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_getZ() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_getW() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_setXY() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_setXYZ() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_setXYZW() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_clone() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todo_toJSON() {
        Assert.fail('everything\'s gonna be alright');
    }
}