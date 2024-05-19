package three.test.unit.src.renderers;

import three.renderers.WebGL3DRenderTarget;
import three.renderers.WebGLRenderTarget;
import utest.Assert;
import utest.Test;

class WebGL3DRenderTargetTests {
    public function new() {}

    @TestBeforeClass
    public function setup() {}

    @Test("Extending")
    public function testExtending() {
        var object = new WebGL3DRenderTarget();
        Assert.isTrue(Std.is(object, WebGLRenderTarget), 'WebGL3DRenderTarget extends from WebGLRenderTarget');
    }

    @Test("Instancing")
    public function testInstancing() {
        var object = new WebGL3DRenderTarget();
        Assert.notNull(object, 'Can instantiate a WebGL3DRenderTarget.');
    }

    @Test("depth", ~/[TODO]/)
    public function testDepth() {
        Assert.fail('Everything\'s gonna be alright');
    }

    @Test("texture", ~/[TODO]/)
    public function testTexture() {
        // must be Data3DTexture
        Assert.fail('Everything\'s gonna be alright');
    }

    @Test("isWebGL3DRenderTarget", ~/[TODO]/)
    public function testIsWebGL3DRenderTarget() {
        Assert.fail('Everything\'s gonna be alright');
    }
}