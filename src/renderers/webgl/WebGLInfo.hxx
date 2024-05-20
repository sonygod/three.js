class WebGLInfo {

    var memory:{geometries:Int, textures:Int};
    var render:{frame:Int, calls:Int, triangles:Int, points:Int, lines:Int};
    var programs:Dynamic;
    var autoReset:Bool;

    public function new(gl:Dynamic) {
        memory = {geometries:0, textures:0};
        render = {frame:0, calls:0, triangles:0, points:0, lines:0};
        programs = null;
        autoReset = true;
    }

    public function update(count:Int, mode:Int, instanceCount:Int) {
        render.calls++;
        switch (mode) {
            case gl.TRIANGLES:
                render.triangles += instanceCount * (count / 3);
                break;
            case gl.LINES:
                render.lines += instanceCount * (count / 2);
                break;
            case gl.LINE_STRIP:
                render.lines += instanceCount * (count - 1);
                break;
            case gl.LINE_LOOP:
                render.lines += instanceCount * count;
                break;
            case gl.POINTS:
                render.points += instanceCount * count;
                break;
            default:
                trace('THREE.WebGLInfo: Unknown draw mode:', mode);
                break;
        }
    }

    public function reset() {
        render.calls = 0;
        render.triangles = 0;
        render.points = 0;
        render.lines = 0;
    }
}