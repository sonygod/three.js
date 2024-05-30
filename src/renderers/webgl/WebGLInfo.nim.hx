import js.html.webgl.WebGLRenderingContext;

class WebGLInfo {
    public var memory(default, null):Dynamic;
    public var render(default, null):Dynamic;
    public var programs:Null<Dynamic>;
    public var autoReset:Bool;
    public var reset:Void->Void;
    public var update:(Int, Int, Int)->Void;

    public function new(gl:WebGLRenderingContext) {
        this.memory = {
            geometries: 0,
            textures: 0
        };

        this.render = {
            frame: 0,
            calls: 0,
            triangles: 0,
            points: 0,
            lines: 0
        };

        this.update = function(count:Int, mode:Int, instanceCount:Int) {
            this.render.calls++;

            switch (mode) {
                case gl.TRIANGLES:
                    this.render.triangles += instanceCount * (count / 3);
                    break;

                case gl.LINES:
                    this.render.lines += instanceCount * (count / 2);
                    break;

                case gl.LINE_STRIP:
                    this.render.lines += instanceCount * (count - 1);
                    break;

                case gl.LINE_LOOP:
                    this.render.lines += instanceCount * count;
                    break;

                case gl.POINTS:
                    this.render.points += instanceCount * count;
                    break;

                default:
                    trace.error('THREE.WebGLInfo: Unknown draw mode:', mode);
                    break;
            }
        }

        this.reset = function() {
            this.render.calls = 0;
            this.render.triangles = 0;
            this.render.points = 0;
            this.render.lines = 0;
        }

        this.autoReset = true;
        this.programs = null;
    }
}