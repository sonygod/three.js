class WebGLInfo {
    public var memory:Map<String, Int> = new Map<String, Int>();
    public var render:Map<String, Float> = new Map<String, Float>();
    private var gl:js.html.WebGLRenderingContext;

    public function new(gl:js.html.WebGLRenderingContext) {
        this.gl = gl;

        memory.set("geometries", 0);
        memory.set("textures", 0);

        render.set("frame", 0);
        render.set("calls", 0);
        render.set("triangles", 0);
        render.set("points", 0);
        render.set("lines", 0);
    }

    public function update(count:Int, mode:Int, instanceCount:Int) {
        render.set("calls", render.get("calls") + 1);

        switch (mode) {
            case gl.TRIANGLES:
                render.set("triangles", render.get("triangles") + instanceCount * (count / 3));
                break;

            case gl.LINES:
                render.set("lines", render.get("lines") + instanceCount * (count / 2));
                break;

            case gl.LINE_STRIP:
                render.set("lines", render.get("lines") + instanceCount * (count - 1));
                break;

            case gl.LINE_LOOP:
                render.set("lines", render.get("lines") + instanceCount * count);
                break;

            case gl.POINTS:
                render.set("points", render.get("points") + instanceCount * count);
                break;

            default:
                trace("THREE.WebGLInfo: Unknown draw mode: " + mode);
                break;
        }
    }

    public function reset() {
        render.set("calls", 0);
        render.set("triangles", 0);
        render.set("points", 0);
        render.set("lines", 0);
    }
}