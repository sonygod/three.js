package three.test.unit.src.renderers;

import haxe.unit.TestCase;

class WebGLCubeRenderTargetTest extends TestCase {
    public function new() {
        super();
    }

    public function testExtending() {
        var object = new WebGLCubeRenderTarget();
        assertTrue(object instanceof WebGLRenderTarget, 'WebGLCubeRenderTarget extends from WebGLRenderTarget');
    }

    public function testInstancing() {
        var object = new WebGLCubeRenderTarget();
        assertNotNull(object, 'Can instantiate a WebGLCubeRenderTarget.');
    }

    public function testTexture() {
        // doc update needed, this needs to be a CubeTexture unlike parent class
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsWebGLCubeRenderTarget() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testFromEquirectangularTexture() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testClear() {
        assertTrue(false, 'everything\'s gonna be alright');
    }
}