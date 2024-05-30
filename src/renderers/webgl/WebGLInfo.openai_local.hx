package three.renderers.webgl;

import js.html.WebGLRenderingContext;

class WebGLInfo {
    public var memory:Dynamic;
    public var render:Dynamic;
    public var programs:Null<Dynamic>;
    public var autoReset:Bool;

    public function new(gl:WebGLRenderingContext) {
        memory = {
            geometries: 0,
            textures: 0
        };

        render = {
            frame: 0,
            calls: 0,
            triangles: 0,
            points: 0,
            lines: 0
        };

        autoReset = true;
    }

    public function update(count:Int, mode:Int, instanceCount:Int):Void {
        render.calls++;

        switch (mode) {
            case WebGLRenderingContext.TRIANGLES:
                render.triangles += instanceCount * (count / 3);
                break;

            case WebGLRenderingContext.LINES:
                render.lines += instanceCount * (count / 2);
                break;

            case WebGLRenderingContext.LINE_STRIP:
                render.lines += instanceCount * (count - 1);
                break;

            case WebGLRenderingContext.LINE_LOOP:
                render.lines += instanceCount * count;
                break;

            case WebGLRenderingContext.POINTS:
                render.points += instanceCount * count;
                break;

            default:
                trace('THREE.WebGLInfo: Unknown draw mode: $mode');
                break;
        }
    }

    public function reset():Void {
        render.calls = 0;
        render.triangles = 0;
        render.points = 0;
        render.lines = 0;
    }
}