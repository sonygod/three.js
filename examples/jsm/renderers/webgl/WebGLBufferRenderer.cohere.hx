class WebGLBufferRenderer {
    var gl: WebGLRenderingContext;
    var extensions: Dynamic;
    var info: Dynamic;
    var mode: Int;
    var index: Int;
    var type: Int;
    var object: Dynamic;

    public function new(backend: Dynamic) {
        gl = backend.gl;
        extensions = backend.extensions;
        info = backend.renderer.info;
        mode = null;
        index = 0;
        type = null;
        object = null;
    }

    public function render(start: Int, count: Int): Void {
        if (index != 0) {
            gl.drawElements(mode, count, type, start);
        } else {
            gl.drawArrays(mode, start, count);
        }
        info.update(object, count, mode, 1);
    }

    public function renderInstances(start: Int, count: Int, primcount: Int): Void {
        if (primcount == 0) {
            return;
        }
        if (index != 0) {
            gl.drawElementsInstanced(mode, count, type, start, primcount);
        } else {
            gl.drawArraysInstanced(mode, start, count, primcount);
        }
        info.update(object, count, mode, primcount);
    }

    public function renderMultiDraw(starts: Array<Int>, counts: Array<Int>, drawCount: Int): Void {
        if (drawCount == 0) {
            return;
        }
        var extension = extensions.get("WEBGL_multi_draw");
        if (extension == null) {
            var i = 0;
            while (i < drawCount) {
                render(starts[i], counts[i]);
                i++;
            }
        } else {
            if (index != 0) {
                extension.multiDrawElementsWEBGL(mode, counts, 0, type, starts, 0, drawCount);
            } else {
                extension.multiDrawArraysWEBGL(mode, starts, 0, counts, 0, drawCount);
            }
            var elementCount = 0;
            var i = 0;
            while (i < drawCount) {
                elementCount += counts[i];
                i++;
            }
            info.update(object, elementCount, mode, 1);
        }
    }

    public function renderMultiDrawInstances(starts: Array<Int>, counts: Array<Int>, drawCount: Int, primcount: Array<Int>): Void {
        if (drawCount == 0) {
            return;
        }
        var extension = extensions.get("WEBGL_multi_draw");
        if (extension == null) {
            var i = 0;
            while (i < drawCount) {
                renderInstances(starts[i], counts[i], primcount[i]);
                i++;
            }
        } else {
            if (index != 0) {
                extension.multiDrawElementsInstancedWEBGL(mode, counts, 0, type, starts, 0, primcount, 0, drawCount);
            } else {
                extension.multiDrawArraysInstancedWEBGL(mode, starts, 0, counts, 0, primcount, 0, drawCount);
            }
            var elementCount = 0;
            var i = 0;
            while (i < drawCount) {
                elementCount += counts[i];
                i++;
            }
            var j = 0;
            while (j < primcount.length) {
                info.update(object, elementCount, mode, primcount[j]);
                j++;
            }
        }
    }
}

class Export {
    static public function WebGLBufferRenderer() : WebGLBufferRenderer {
        return WebGLBufferRenderer;
    }
}