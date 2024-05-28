class WebGLBufferRenderer {
    var mode:Int;
    function new(gl:WebGLRenderer, extensions:Dynamic, info:Dynamic) {
        mode = 0;
    }
    function setMode(value:Int) {
        mode = value;
    }
    function render(start:Int, count:Int) {
        gl.drawArrays(mode, start, count);
        info.update(count, mode, 1);
    }
    function renderInstances(start:Int, count:Int, primcount:Int) {
        if (primcount == 0) return;
        gl.drawArraysInstanced(mode, start, count, primcount);
        info.update(count, mode, primcount);
    }
    function renderMultiDraw(starts:Array<Int>, counts:Array<Int>, drawCount:Int) {
        if (drawCount == 0) return;
        var extension = extensions.get("WEBGL_multi_draw");
        if (extension == null) {
            for (i in 0...drawCount) {
                render(starts[i], counts[i]);
            }
        } else {
            extension.multiDrawArraysWEBGL(mode, starts, 0, counts, 0, drawCount);
            var elementCount = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            info.update(elementCount, mode, 1);
        }
    }
    function renderMultiDrawInstances(starts:Array<Int>, counts:Array<Int>, drawCount:Int, primcounts:Array<Int>) {
        if (drawCount == 0) return;
        var extension = extensions.get("WEBGL_multi_draw");
        if (extension == null) {
            for (i in 0...drawCount) {
                renderInstances(starts[i], counts[i], primcounts[i]);
            }
        } else {
            extension.multiDrawArraysInstancedWEBGL(mode, starts, 0, counts, 0, primcounts, 0, drawCount);
            var elementCount = 0;
            for (i in 0...drawCount) {
                elementCount += counts[i];
            }
            for (i in 0...drawCount) {
                info.update(elementCount, mode, primcounts[i]);
            }
        }
    }
}