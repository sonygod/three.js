package three.js.examples.jsm.renderers.webgl;

import js.html.webgl.GL;
import js.html.webgl.Extensions;

class WebGLBufferRenderer {
    public var gl:GL;
    public var extensions:Extensions;
    public var info:Dynamic;
    public var mode:Null<Int>;
    public var index:Int;
    public var type:Null<Int>;
    public var object:Dynamic;

    public function new(backend:Dynamic) {
        gl = backend.gl;
        extensions = backend.extensions;
        info = backend.renderer.info;
        mode = null;
        index = 0;
        type = null;
        object = null;
    }

    public function render(start:Int, count:Int) {
        if (index != 0) {
            gl.drawElements(mode, count, type, start);
        } else {
            gl.drawArrays(mode, start, count);
        }
        info.update(object, count, mode, 1);
    }

    public function renderInstances(start:Int, count:Int, primcount:Int) {
        if (primcount == 0) return;
        if (index != 0) {
            gl.drawElementsInstanced(mode, count, type, start, primcount);
        } else {
            gl.drawArraysInstanced(mode, start, count, primcount);
        }
        info.update(object, count, mode, primcount);
    }

    public function renderMultiDraw(starts:Array<Int>, counts:Array<Int>, drawCount:Int) {
        if (drawCount == 0) return;
        var extension:Dynamic = extensions.get('WEBGL_multi_draw');
        if (extension == null) {
            for (i in 0...drawCount) {
                render(starts[i], counts[i]);
            }
        } else {
            if (index != 0) {
                extension.multiDrawElementsWEBGL(mode, counts, 0, type, starts, 0, drawCount);
            } else {
                extension.multiDrawArraysWEBGL(mode, starts, 0, counts, 0, drawCount);
            }
            var elementCount:Int = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            info.update(object, elementCount, mode, 1);
        }
    }

    public function renderMultiDrawInstances(starts:Array<Int>, counts:Array<Int>, drawCount:Int, primcount:Array<Int>) {
        if (drawCount == 0) return;
        var extension:Dynamic = extensions.get('WEBGL_multi_draw');
        if (extension == null) {
            for (i in 0...drawCount) {
                renderInstances(starts[i], counts[i], primcount[i]);
            }
        } else {
            if (index != 0) {
                extension.multiDrawElementsInstancedWEBGL(mode, counts, 0, type, starts, 0, primcount, 0, drawCount);
            } else {
                extension.multiDrawArraysInstancedWEBGL(mode, starts, 0, counts, 0, primcount, 0, drawCount);
            }
            var elementCount:Int = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            for (i in 0...primcount.length) {
                info.update(object, elementCount, mode, primcount[i]);
            }
        }
    }
}