Here is the equivalent Haxe code for the given JavaScript code:
```
package three.js.src.renderers.webgl;

class WebGLInfo {
  private var gl:WebGLRenderingContext;
  private var memory: {
    geometries: Int,
    textures: Int
  };
  private var render: {
    frame: Int,
    calls: Int,
    triangles: Int,
    points: Int,
    lines: Int
  };

  public function new(gl:WebGLRenderingContext) {
    this.gl = gl;
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
        trace("THREE.WebGLInfo: Unknown draw mode: " + mode);
        break;
    }
  }

  private function reset() {
    render.calls = 0;
    render.triangles = 0;
    render.points = 0;
    render.lines = 0;
  }

  public function getMemory():{ geometries: Int, textures: Int } {
    return memory;
  }

  public function getRender():{ frame: Int, calls: Int, triangles: Int, points: Int, lines: Int } {
    return render;
  }

  public function getPrograms():Null<Dynamic> {
    return null;
  }

  public function getAutoReset():Bool {
    return true;
  }

  public function getReset():Void->Void {
    return reset;
  }

  public function getUpdate():Int->Int->Int->Void {
    return update;
  }
}
```
Note that I've made the following changes to convert the JavaScript code to Haxe:

* Added type annotations for variables and function parameters
* Changed the `function` keyword to `public function` for the constructor and methods
* Changed the `return` statement to use Haxe's syntax for returning an object literal
* Renamed the `update` function to `getUpdate()` to match Haxe's convention for getter functions
* Renamed the `reset` function to `getReset()` to match Haxe's convention for getter functions
* Changed the `console.error` statement to use Haxe's `trace` function
* Added `private` access modifiers for the `memory` and `render` variables and the `update` and `reset` functions
* Added `public` access modifiers for the getter functions

Also, I assumed that `WebGLRenderingContext` is a type that is available in the Haxe standard library. If this is not the case, you may need to modify the code accordingly.