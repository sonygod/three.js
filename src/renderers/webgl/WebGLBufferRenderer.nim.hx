import js.html.webgl.WebGLRenderingContext;
import js.html.webgl.WebGLExtension;
import three.js.src.renderers.webgl.WebGLInfo;

class WebGLBufferRenderer {
    var mode:Int;
    var gl:WebGLRenderingContext;
    var extensions:Map<String, WebGLExtension>;
    var info:WebGLInfo;

    public function new(gl:WebGLRenderingContext, extensions:Map<String, WebGLExtension>, info:WebGLInfo) {
        this.gl = gl;
        this.extensions = extensions;
        this.info = info;
    }

    public function setMode(value:Int):Void {
        this.mode = value;
    }

    public function render(start:Int, count:Int):Void {
        this.gl.drawArrays(this.mode, start, count);
        this.info.update(count, this.mode, 1);
    }

    public function renderInstances(start:Int, count:Int, primcount:Int):Void {
        if (primcount == 0) return;
        this.gl.drawArraysInstanced(this.mode, start, count, primcount);
        this.info.update(count, this.mode, primcount);
    }

    public function renderMultiDraw(starts:Array<Int>, counts:Array<Int>, drawCount:Int):Void {
        if (drawCount == 0) return;
        var extension:WebGLExtension = this.extensions.get("WEBGL_multi_draw");
        if (extension == null) {
            for (i in 0...drawCount) {
                this.render(starts[i], counts[i]);
            }
        } else {
            extension.multiDrawArraysWEBGL(this.mode, starts, 0, counts, 0, drawCount);
            var elementCount:Int = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            this.info.update(elementCount, this.mode, 1);
        }
    }

    public function renderMultiDrawInstances(starts:Array<Int>, counts:Array<Int>, drawCount:Int, primcount:Array<Int>):Void {
        if (drawCount == 0) return;
        var extension:WebGLExtension = this.extensions.get("WEBGL_multi_draw");
        if (extension == null) {
            for (i in 0...starts.length) {
                this.renderInstances(starts[i], counts[i], primcount[i]);
            }
        } else {
            extension.multiDrawArraysInstancedWEBGL(this.mode, starts, 0, counts, 0, primcount, 0, drawCount);
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