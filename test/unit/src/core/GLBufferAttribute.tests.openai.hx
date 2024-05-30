package three.test.unit.src.core;

import three.core.GLBufferAttribute;

class GLBufferAttributeTests {

    public function new() {

    }

    @Test
    public function testInstancing() {
        var object = new GLBufferAttribute();
        assertTrue(object != null, 'Can instantiate a GLBufferAttribute.');
    }

    @Todo
    public function testName() {
        assertTrue(false, "everything's gonna be alright");
    }

    @Todo
    public function testBuffer() {
        assertTrue(false, "everything's gonna be alright");
    }

    @Todo
    public function testType() {
        assertTrue(false, "everything's gonna be alright");
    }

    @Todo
    public function testItemSize() {
        assertTrue(false, "everything's gonna be alright");
    }

    @Todo
    public function testElementSize() {
        assertTrue(false, "everything's gonna be alright");
    }

    @Todo
    public function testCount() {
        assertTrue(false, "everything's gonna be alright");
    }

    @Todo
    public function testVersion() {
        assertTrue(false, "everything's gonna be alright");
    }

    @Todo
    public function testNeedsUpdate() {
        // set needsUpdate( value )
        assertTrue(false, "everything's gonna be alright");
    }

    @Test
    public function testIsGLBufferAttribute() {
        var object = new GLBufferAttribute();
        assertTrue(object.isGLBufferAttribute, 'GLBufferAttribute.isGLBufferAttribute should be true');
    }

    @Todo
    public function testSetBuffer() {
        assertTrue(false, "everything's gonna be alright");
    }

    @Todo
    public function testSetType() {
        assertTrue(false, "everything's gonna be alright");
    }

    @Todo
    public function testSetItemSize() {
        assertTrue(false, "everything's gonna be alright");
    }

    @Todo
    public function testSetCount() {
        assertTrue(false, "everything's gonna be alright");
    }
}