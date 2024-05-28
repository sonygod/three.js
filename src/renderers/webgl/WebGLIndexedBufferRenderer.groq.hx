package three.js.src.renderers.webgl;

import js.html.webgl.GL;
import js.html.webglExtensions WEBGL_multi_draw;

class WebGLIndexedBufferRenderer {
    private var gl:GL;
    private var extensions:Dynamic;
    private var info:Dynamic;

    private var mode:Int;
    private var type:Int;
    private var bytesPerElement:Int;

    public function new(gl:GL, extensions:Dynamic, info:Dynamic) {
        this.gl = gl;
        this.extensions = extensions;
        this.info = info;
    }

    private function setMode(value:Int):Void {
        mode = value;
    }

    private function setIndex(value:Dynamic):Void {
        type = value.type;
        bytesPerElement = value.bytesPerElement;
    }

    private function render(start:Int, count:Int):Void {
        gl.drawElements(mode, count, type, start * bytesPerElement);
        info.update(count, mode, 1);
    }

    private function renderInstances(start:Int, count:Int, primcount:Int):Void {
        if (primcount == 0) return;
        gl.drawElementsInstanced(mode, count, type, start * bytesPerElement, primcount);
        info.update(count, mode, primcount);
    }

    private function renderMultiDraw(starts:Array<Int>, counts:Array<Int>, drawCount:Int):Void {
        if (drawCount == 0) return;
        var extension:WEBGL_multi_draw = extensions.get('WEBGL_multi_draw');
        if (extension == null) {
            for (i in 0...drawCount) {
                render(starts[i] / bytesPerElement, counts[i]);
            }
        } else {
            extension.multiDrawElementsWEBGL(mode, counts, 0, type, starts, 0, drawCount);
            var elementCount:Int = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            info.update(elementCount, mode, 1);
        }
    }

    private function renderMultiDrawInstances(starts:Array<Int>, counts:Array<Int>, drawCount:Int, primcount:Array<Int>):Void {
        if (drawCount == 0) return;
        var extension:WEBGL_multi_draw = extensions.get('WEBGL_multi_draw');
        if (extension == null) {
            for (i in 0...starts.length) {
                renderInstances(starts[i] / bytesPerElement, counts[i], primcount[i]);
            }
        } else {
            extension.multiDrawElementsInstancedWEBGL(mode, counts, 0, type, starts, 0, primcount, 0, drawCount);
            var elementCount:Int = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            for (i in 0...primcount.length) {
                info.update(elementCount, mode, primcount[i]);
            }
        }
    }

    public var setMode:Void->Int->Void = setMode;
    public var setIndex:Void->Dynamic->Void = setIndex;
    public var render:Void->Int->Int->Void = render;
    public var renderInstances:Void->Int->Int->Int->Void = renderInstances;
    public var renderMultiDraw:Void->Array<Int>->Array<Int>->Int->Void = renderMultiDraw;
    public var renderMultiDrawInstances:Void->Array<Int>->Array<Int>->Int->Array<Int>->Void = renderMultiDrawInstances;
}