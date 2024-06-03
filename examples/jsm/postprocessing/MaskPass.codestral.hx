import js.Browser.document;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.cameras.Camera;
import three.renderers.WebGLRenderTarget;
import three.renderers.WebGLState;
import three.renderers.webgl.WebGLContext;
import three.postprocessing.Pass;

class MaskPass extends Pass {
    public var scene:Scene;
    public var camera:Camera;
    public var inverse:Bool = false;

    public function new(scene:Scene, camera:Camera) {
        super();
        this.scene = scene;
        this.camera = camera;
        this.clear = true;
        this.needsSwap = false;
    }

    public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
        var context:WebGLContext = renderer.getContext();
        var state:WebGLState = renderer.state;

        state.buffers.color.setMask(false);
        state.buffers.depth.setMask(false);

        state.buffers.color.setLocked(true);
        state.buffers.depth.setLocked(true);

        var writeValue:Int;
        var clearValue:Int;

        if (this.inverse) {
            writeValue = 0;
            clearValue = 1;
        } else {
            writeValue = 1;
            clearValue = 0;
        }

        state.buffers.stencil.setTest(true);
        state.buffers.stencil.setOp(context.REPLACE, context.REPLACE, context.REPLACE);
        state.buffers.stencil.setFunc(context.ALWAYS, writeValue, 0xffffffff);
        state.buffers.stencil.setClear(clearValue);
        state.buffers.stencil.setLocked(true);

        renderer.setRenderTarget(readBuffer);
        if (this.clear) renderer.clear();
        renderer.render(this.scene, this.camera);

        renderer.setRenderTarget(writeBuffer);
        if (this.clear) renderer.clear();
        renderer.render(this.scene, this.camera);

        state.buffers.color.setLocked(false);
        state.buffers.depth.setLocked(false);

        state.buffers.color.setMask(true);
        state.buffers.depth.setMask(true);

        state.buffers.stencil.setLocked(false);
        state.buffers.stencil.setFunc(context.EQUAL, 1, 0xffffffff);
        state.buffers.stencil.setOp(context.KEEP, context.KEEP, context.KEEP);
        state.buffers.stencil.setLocked(true);
    }
}

class ClearMaskPass extends Pass {
    public function new() {
        super();
        this.needsSwap = false;
    }

    public function render(renderer:WebGLRenderer) {
        renderer.state.buffers.stencil.setLocked(false);
        renderer.state.buffers.stencil.setTest(false);
    }
}