package three.renderers.webgl;

import js.html.WebGLRenderingContext;

class WebGLIndexedBufferRenderer {

    private var gl:WebGLRenderingContext;
    private var extensions:Dynamic;
    private var info:Dynamic;
    private var mode:Int;
    private var type:Int;
    private var bytesPerElement:Int;

    public function new(gl:WebGLRenderingContext, extensions:Dynamic, info:Dynamic) {
        this.gl = gl;
        this.extensions = extensions;
        this.info = info;
    }

    public function setMode(value:Int):Void {
        this.mode = value;
    }

    public function setIndex(value:Dynamic):Void {
        this.type = value.type;
        this.bytesPerElement = value.bytesPerElement;
    }

    public function render(start:Int, count:Int):Void {
        gl.drawElements(mode, count, type, start * bytesPerElement);
        info.update(count, mode, 1);
    }

    public function renderInstances(start:Int, count:Int, primcount:Int):Void {
        if (primcount == 0) return;
        gl.drawElementsInstanced(mode, count, type, start * bytesPerElement, primcount);
        info.update(count, mode, primcount);
    }

    public function renderMultiDraw(starts:Array<Int>, counts:Array<Int>, drawCount:Int):Void {
        if (drawCount == 0) return;
        
        var extension = extensions.get('WEBGL_multi_draw');
        
        if (extension == null) {
            for (i in 0...drawCount) {
                this.render(starts[i] / bytesPerElement, counts[i]);
            }
        } else {
            extension.multiDrawElementsWEBGL(mode, counts, 0, type, starts, 0, drawCount);
            var elementCount = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            info.update(elementCount, mode, 1);
        }
    }

    public function renderMultiDrawInstances(starts:Array<Int>, counts:Array<Int>, drawCount:Int, primcount:Array<Int>):Void {
        if (drawCount == 0) return;
        
        var extension = extensions.get('WEBGL_multi_draw');
        
        if (extension == null) {
            for (i in 0...starts.length) {
                renderInstances(starts[i] / bytesPerElement, counts[i], primcount[i]);
            }
        } else {
            extension.multiDrawElementsInstancedWEBGL(mode, counts, 0, type, starts, 0, primcount, 0, drawCount);
            var elementCount = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            for (i in 0...primcount.length) {
                info.update(elementCount, mode, primcount[i]);
            }
        }
    }

}