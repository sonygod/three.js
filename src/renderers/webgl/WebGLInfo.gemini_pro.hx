import haxe.ds.StringMap;

class WebGLInfo {

  public var memory: { geometries: Int, textures: Int } = { geometries: 0, textures: 0 };

  public var render: { frame: Int, calls: Int, triangles: Float, points: Float, lines: Float } = { frame: 0, calls: 0, triangles: 0, points: 0, lines: 0 };

  public var programs: StringMap<Dynamic> = new StringMap<Dynamic>();

  public var autoReset: Bool = true;

  public function new(gl: WebGLRenderingContext) {
    // No need to recreate the object as in the original JS version,
    // Haxe objects are already mutable.
  }

  public function update(count: Int, mode: Int, instanceCount: Int = 1): Void {
    render.calls++;

    switch (mode) {
      case WebGLRenderingContext.TRIANGLES:
        render.triangles += instanceCount * (count / 3);
      case WebGLRenderingContext.LINES:
        render.lines += instanceCount * (count / 2);
      case WebGLRenderingContext.LINE_STRIP:
        render.lines += instanceCount * (count - 1);
      case WebGLRenderingContext.LINE_LOOP:
        render.lines += instanceCount * count;
      case WebGLRenderingContext.POINTS:
        render.points += instanceCount * count;
      default:
        // Haxe doesn't have a 'console' object, use 'trace' for logging
        trace('THREE.WebGLInfo: Unknown draw mode: ${mode}');
    }
  }

  public function reset(): Void {
    render.calls = 0;
    render.triangles = 0;
    render.points = 0;
    render.lines = 0;
  }
}


**Explanation:**

1. **Haxe Object Mutability:**  Haxe objects are mutable by default, so there's no need to return a new object in the `new` function. We simply initialize the `memory` and `render` fields.

2. **`console.error` to `trace`:** Haxe doesn't have a `console` object, so we use `trace` for logging errors.

3. **No `export` keyword:** Haxe doesn't use the `export` keyword for modules. You'll typically define your classes in separate `.hx` files and compile them together.

4. **`StringMap` for programs:** Since you're using a JavaScript `Map` for programs in the original, I've used `haxe.ds.StringMap` in the Haxe equivalent.

**To use the `WebGLInfo` class:**

1. **Create an instance:**
   
   var info = new WebGLInfo(gl);
   

2. **Call `update` when drawing:**
   
   info.update(count, mode, instanceCount);
   

3. **Reset after rendering:**
   
   info.reset();