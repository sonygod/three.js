import Pass from './Pass.hx';

class MaskPass extends Pass {
    public var scene:Scene;
    public var camera:Camera;
    public var clear:Bool;
    public var needsSwap:Bool;
    public var inverse:Bool;

    public function new(scene:Scene, camera:Camera) {
        super();
        this.scene = scene;
        this.camera = camera;
        this.clear = true;
        this.needsSwap = false;
        this.inverse = false;
    }

    public function render(renderer:Renderer, writeBuffer:RenderBuffer, readBuffer:RenderBuffer):Void {
        var context = renderer.getContext();
        var state = renderer.state;

        // don't update color or depth
        state.buffers.color.setMask(false);
        state.buffers.depth.setMask(false);

        // lock buffers
        state.buffers.color.setLocked(true);
        state.buffers.depth.setLocked(true);

        // set up stencil
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

        // draw into the stencil buffer
        renderer.setRenderTarget(readBuffer);
        if (this.clear) renderer.clear();
        renderer.render(this.scene, this.camera);

        renderer.setRenderTarget(writeBuffer);
        if (this.clear) renderer.clear();
        renderer.render(this.scene, this.camera);

        // unlock color and depth buffer and make them writable for subsequent rendering/clearing
        state.buffers.color.setLocked(false);
        state.buffers.depth.setLocked(false);

        state.buffers.color.setMask(true);
        state.buffers.depth.setMask(true);

        // only render where stencil is set to 1
        state.buffers.stencil.setLocked(false);
        state.buffers.stencil.setFunc(context.EQUAL, 1, 0xffffffff); // draw if == 1
        state.buffers.stencil.setOp(context.KEEP, context.KEEP, context.KEEP);
        state.buffers.stencil.setLocked(true);
    }
}

class ClearMaskPass extends Pass {
    public var needsSwap:Bool;

    public function new() {
        super();
        this.needsSwap = false;
    }

    public function render(renderer:Renderer):Void {
        renderer.state.buffers.stencil.setLocked(false);
        renderer.state.buffers.stencil.setTest(false);
    }
}

class Exports {
    static public function get_MaskPass():Class<MaskPass> {
        return MaskPass;
    }

    static public function get_ClearMaskPass():Class<ClearMaskPass> {
        return ClearMaskPass;
    }
}