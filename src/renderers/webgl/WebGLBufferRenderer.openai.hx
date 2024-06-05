package three.js.src.renderers.webgl;

import js.html.webgl.WebGLRenderingContext;
import js.html.webgl.Extension;

class WebGLBufferRenderer {
    private var gl: WebGLRenderingContext;
    private var extensions: Map<String, Extension>;
    private var info: Dynamic;
    private var mode: Int;

    public function new(gl: WebGLRenderingContext, extensions: Map<String, Extension>, info: Dynamic) {
        this.gl = gl;
        this.extensions = extensions;
        this.info = info;
    }

    private function setMode(value: Int): Void {
        mode = value;
    }

    private function render(start: Int, count: Int): Void {
        gl.drawArrays(mode, start, count);
        info.update(count, mode, 1);
    }

    private function renderInstances(start: Int, count: Int, primcount: Int): Void {
        if (primcount == 0) return;
        gl.drawArraysInstanced(mode, start, count, primcount);
        info.update(count, mode, primcount);
    }

    private function renderMultiDraw(starts: Array<Int>, counts: Array<Int>, drawCount: Int): Void {
        if (drawCount == 0) return;
        var extension: Extension = extensions.get('WEBGL_multi_draw');
        if (extension == null) {
            for (i in 0...drawCount) {
                render(starts[i], counts[i]);
            }
        } else {
            extension.multiDrawArraysWEBGL(mode, starts, 0, counts, 0, drawCount);
            var elementCount: Int = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            info.update(elementCount, mode, 1);
        }
    }

    private function renderMultiDrawInstances(starts: Array<Int>, counts: Array<Int>, drawCount: Int, primcount: Array<Int>): Void {
        if (drawCount == 0) return;
        var extension: Extension = extensions.get('WEBGL_multi_draw');
        if (extension == null) {
            for (i in 0...starts.length) {
                renderInstances(starts[i], counts[i], primcount[i]);
            }
        } else {
            extension.multiDrawArraysInstancedWEBGL(mode, starts, 0, counts, 0, primcount, 0, drawCount);
            var elementCount: Int = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            for (i in 0...primcount.length) {
                info.update(elementCount, mode, primcount[i]);
            }
        }
    }

    public function setMode(value: Int): WebGLBufferRenderer {
        setMode(value);
        return this;
    }

    public function render(start: Int, count: Int): WebGLBufferRenderer {
        render(start, count);
        return this;
    }

    public function renderInstances(start: Int, count: Int, primcount: Int): WebGLBufferRenderer {
        renderInstances(start, count, primcount);
        return this;
    }

    public function renderMultiDraw(starts: Array<Int>, counts: Array<Int>, drawCount: Int): WebGLBufferRenderer {
        renderMultiDraw(starts, counts, drawCount);
        return this;
    }

    public function renderMultiDrawInstances(starts: Array<Int>, counts: Array<Int>, drawCount: Int, primcount: Array<Int>): WebGLBufferRenderer {
        renderMultiDrawInstances(starts, counts, drawCount, primcount);
        return this;
    }
}