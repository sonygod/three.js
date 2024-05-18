Here is the equivalent Haxe code for the provided JavaScript code:
```
package renderers.webgl;

class WebGLInfo {
    private var gl:GL;

    private var memory = {
        geometries: 0,
        textures: 0
    };

    private var render = {
        frame: 0,
        calls: 0,
        triangles: 0,
        points: 0,
        lines: 0
    };

    public function new(gl:GL) {
        this.gl = gl;
    }

    private function update(count:Int, mode:Int, instanceCount:Int) {
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
                trace('THREE.WebGLInfo: Unknown draw mode: ' + mode);
                break;
        }
    }

    private function reset() {
        render.calls = 0;
        render.triangles = 0;
        render.points = 0;
        render.lines = 0;
    }

    public function getMemory() {
        return memory;
    }

    public function getRender() {
        return render;
    }

    public function getPrograms() {
        return null;
    }

    public var autoReset:Bool = true;

    public function getReset() {
        return reset;
    }

    public function getUpdate() {
        return update;
    }
}
```
Note that I've made the following changes to convert the JavaScript code to Haxe:

* Added type annotations for variables and function parameters
* Changed the syntax for object literals to Haxe's syntax
* Replaced `function` with `public function` to define public methods
* Added `private` access modifier for variables and methods that don't need to be exposed
* Changed `console.error` to `trace` for error logging
* Added getter methods for properties that need to be exposed
* Changed the constructor function to a Haxe constructor method `new`

Please note that this is a mechanical conversion, and you may need to adjust the code to fit your specific use case.