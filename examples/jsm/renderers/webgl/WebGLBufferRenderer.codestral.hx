package three.js.renderers.webgl;

import js.html.WebGLRenderingContext;
import js.html.WebGLRenderingContextBase;
import js.html.WebGLMultiDraw;

class WebGLBufferRenderer {
    private var gl: WebGLRenderingContext;
    private var extensions: Map<String, any>;
    private var info: any;
    private var mode: Int;
    private var index: Int;
    private var type: Int;
    private var object: any;

    public function new(backend: any) {
        this.gl = backend.gl;
        this.extensions = backend.extensions;
        this.info = backend.renderer.info;
        this.mode = null;
        this.index = 0;
        this.type = null;
        this.object = null;
    }

    public function render(start: Int, count: Int) {
        if (this.index !== 0) {
            this.gl.drawElements(this.mode, count, this.type, start);
        } else {
            this.gl.drawArrays(this.mode, start, count);
        }

        this.info.update(this.object, count, this.mode, 1);
    }

    public function renderInstances(start: Int, count: Int, primcount: Int) {
        if (primcount === 0) return;

        if (this.index !== 0) {
            this.gl.drawElementsInstanced(this.mode, count, this.type, start, primcount);
        } else {
            this.gl.drawArraysInstanced(this.mode, start, count, primcount);
        }

        this.info.update(this.object, count, this.mode, primcount);
    }

    public function renderMultiDraw(starts: Array<Int>, counts: Array<Int>, drawCount: Int) {
        if (drawCount === 0) return;

        var extension: WebGLMultiDraw = this.extensions.get('WEBGL_multi_draw');

        if (extension == null) {
            for (i in 0...drawCount) {
                this.render(starts[i], counts[i]);
            }
        } else {
            if (this.index !== 0) {
                extension.multiDrawElementsWEBGL(this.mode, counts, 0, this.type, starts, 0, drawCount);
            } else {
                extension.multiDrawArraysWEBGL(this.mode, starts, 0, counts, 0, drawCount);
            }

            var elementCount: Int = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }

            this.info.update(this.object, elementCount, this.mode, 1);
        }
    }

    public function renderMultiDrawInstances(starts: Array<Int>, counts: Array<Int>, drawCount: Int, primcount: Array<Int>) {
        if (drawCount === 0) return;

        var extension: WebGLMultiDraw = this.extensions.get('WEBGL_multi_draw');

        if (extension == null) {
            for (i in 0...drawCount) {
                this.renderInstances(starts[i], counts[i], primcount[i]);
            }
        } else {
            if (this.index !== 0) {
                extension.multiDrawElementsInstancedWEBGL(this.mode, counts, 0, this.type, starts, 0, primcount, 0, drawCount);
            } else {
                extension.multiDrawArraysInstancedWEBGL(this.mode, starts, 0, counts, 0, primcount, 0, drawCount);
            }

            var elementCount: Int = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }

            for (i in 0...primcount.length) {
                this.info.update(this.object, elementCount, this.mode, primcount[i]);
            }
        }
    }
}