import js.html.webgl.WebGLRenderingContext;
import js.html.webgl.WebGLRenderingContextBase;
import js.html.webgl.WebGLRenderingContextExtension;
import js.html.webgl.WebGLRenderingContextExtensionBase;
import js.html.webgl.WebGLRenderingContextExtensionMap;

class WebGLIndexedBufferRenderer {
    var mode:Int;
    var type:Int;
    var bytesPerElement:Int;
    var gl:WebGLRenderingContext;
    var extensions:WebGLRenderingContextExtensionMap;
    var info:Dynamic;

    public function new(gl:WebGLRenderingContext, extensions:WebGLRenderingContextExtensionMap, info:Dynamic) {
        this.gl = gl;
        this.extensions = extensions;
        this.info = info;
    }

    public function setMode(value:Int) {
        this.mode = value;
    }

    public function setIndex(value:Dynamic) {
        this.type = value.type;
        this.bytesPerElement = value.bytesPerElement;
    }

    public function render(start:Int, count:Int) {
        this.gl.drawElements(this.mode, count, this.type, start * this.bytesPerElement);
        this.info.update(count, this.mode, 1);
    }

    public function renderInstances(start:Int, count:Int, primcount:Int) {
        if (primcount === 0) return;
        this.gl.drawElementsInstanced(this.mode, count, this.type, start * this.bytesPerElement, primcount);
        this.info.update(count, this.mode, primcount);
    }

    public function renderMultiDraw(starts:Array<Int>, counts:Array<Int>, drawCount:Int) {
        if (drawCount === 0) return;
        var extension:WebGLRenderingContextExtension = this.extensions.get('WEBGL_multi_draw');
        if (extension == null) {
            for (i in 0...drawCount) {
                this.render(starts[i] / this.bytesPerElement, counts[i]);
            }
        } else {
            extension.multiDrawElementsWEBGL(this.mode, counts, 0, this.type, starts, 0, drawCount);
            var elementCount:Int = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            this.info.update(elementCount, this.mode, 1);
        }
    }

    public function renderMultiDrawInstances(starts:Array<Int>, counts:Array<Int>, drawCount:Int, primcount:Array<Int>) {
        if (drawCount === 0) return;
        var extension:WebGLRenderingContextExtension = this.extensions.get('WEBGL_multi_draw');
        if (extension == null) {
            for (i in 0...starts.length) {
                this.renderInstances(starts[i] / this.bytesPerElement, counts[i], primcount[i]);
            }
        } else {
            extension.multiDrawElementsInstancedWEBGL(this.mode, counts, 0, this.type, starts, 0, primcount, 0, drawCount);
            var elementCount:Int = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            for (i in 0...primcount.length) {
                this.info.update(elementCount, this.mode, primcount[i]);
            }
        }
    }
}