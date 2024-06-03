class WebGLBufferRenderer {
    private var gl:js.html.WebGLRenderingContext;
    private var extensions:Map<String, dynamic>;
    private var info:Info;
    private var mode:Int;

    public function new(gl:js.html.WebGLRenderingContext, extensions:Map<String, dynamic>, info:Info) {
        this.gl = gl;
        this.extensions = extensions;
        this.info = info;
    }

    public function setMode(value:Int) {
        this.mode = value;
    }

    public function render(start:Int, count:Int) {
        this.gl.drawArrays(this.mode, start, count);
        this.info.update(count, this.mode, 1);
    }

    public function renderInstances(start:Int, count:Int, primcount:Int) {
        if (primcount === 0) return;
        this.gl.drawArraysInstanced(this.mode, start, count, primcount);
        this.info.update(count, this.mode, primcount);
    }

    public function renderMultiDraw(starts:Array<Int>, counts:Array<Int>, drawCount:Int) {
        if (drawCount === 0) return;
        var extension = this.extensions.get("WEBGL_multi_draw");

        if (extension === null) {
            for (var i:Int = 0; i < drawCount; i++) {
                this.render(starts[i], counts[i]);
            }
        } else {
            js.html.WebGLRenderingContext.prototype.multiDrawArraysWEBGL.call(this.gl, this.mode, starts, 0, counts, 0, drawCount);
            var elementCount = 0;
            for (var i:Int = 0; i < drawCount; i++) {
                elementCount += counts[i];
            }
            this.info.update(elementCount, this.mode, 1);
        }
    }

    public function renderMultiDrawInstances(starts:Array<Int>, counts:Array<Int>, drawCount:Int, primcount:Array<Int>) {
        if (drawCount === 0) return;
        var extension = this.extensions.get("WEBGL_multi_draw");

        if (extension === null) {
            for (var i:Int = 0; i < starts.length; i++) {
                this.renderInstances(starts[i], counts[i], primcount[i]);
            }
        } else {
            js.html.WebGLRenderingContext.prototype.multiDrawArraysInstancedWEBGL.call(this.gl, this.mode, starts, 0, counts, 0, primcount, 0, drawCount);
            var elementCount = 0;
            for (var i:Int = 0; i < drawCount; i++) {
                elementCount += counts[i];
            }
            for (var i:Int = 0; i < primcount.length; i++) {
                this.info.update(elementCount, this.mode, primcount[i]);
            }
        }
    }
}