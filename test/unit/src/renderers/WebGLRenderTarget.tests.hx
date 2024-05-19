Here is the equivalent Haxe code:
```
package three.test.unit.src.renderers;

import haxe.unit.TestCase;
import three.renderers.WebGLRenderTarget;
import three.core.EventDispatcher;

class WebGLRenderTargetTest {
    public function new() {}

    public function testExtending():Void {
        var object:WebGLRenderTarget = new WebGLRenderTarget();
        assertTrue(object instanceof EventDispatcher, 'WebGLRenderTarget extends from EventDispatcher');
    }

    public function testInstancing():Void {
        var object:WebGLRenderTarget = new WebGLRenderTarget();
        assertTrue(object != null, 'Can instantiate a WebGLRenderTarget.');
    }

    public function todoWidth():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoHeight():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoDepth():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoScissor():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoScissorTest():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoViewport():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoTexture():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoDepthBuffer():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoStencilBuffer():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoDepthTexture():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoSamples():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoTextures():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoIsWebGLRenderTarget():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoSetSize():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoClone():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoCopy():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testDispose():Void {
        var object:WebGLRenderTarget = new WebGLRenderTarget();
        object.dispose();
        assertTrue(true);
    }
}
```
Note that I've used the `haxe.unit` package for testing, and assumed that the `WebGLRenderTarget` and `EventDispatcher` classes are already defined in your Haxe project. You may need to adjust the import statements and class references accordingly.