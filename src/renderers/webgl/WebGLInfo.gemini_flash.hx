import haxe.ds.StringMap;

class WebGLInfo {

	public var memory: {
		geometries: Int;
		textures: Int;
	};

	public var render: {
		frame: Int;
		calls: Int;
		triangles: Int;
		points: Int;
		lines: Int;
	};

	public var programs: StringMap<Dynamic>;
	public var autoReset: Bool;

	public function new(gl: Dynamic) {
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

		this.programs = new StringMap<Dynamic>();
		this.autoReset = true;
	}

	public function update(count: Int, mode: Int, instanceCount: Int): Void {
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
				trace('THREE.WebGLInfo: Unknown draw mode: ${mode}');
				break;
		}
	}

	public function reset(): Void {
		this.render.calls = 0;
		this.render.triangles = 0;
		this.render.points = 0;
		this.render.lines = 0;
	}

}


**Explanation:**

* **Class Definition:** The JavaScript code defines a function, but in Haxe, we define a class `WebGLInfo`.
* **Constructor:** The `new` function in Haxe is the constructor for the class, similar to the JavaScript function. We initialize the `memory`, `render`, `programs`, and `autoReset` properties inside the constructor.
* **Data Structures:** The `memory` and `render` objects in JavaScript are similar to Haxe objects. We create them within the class.
* **`update` Function:** The `update` function remains mostly the same, with the `switch` statement handling the draw modes. The `trace` function is used for logging in Haxe instead of `console.error`.
* **`reset` Function:** The `reset` function is also identical to the JavaScript version.

**Usage:**


// Assuming you have a gl object representing the WebGL context
var info = new WebGLInfo(gl);

// ...

// Call update when rendering
info.update(count, mode, instanceCount);

// Reset the info at appropriate times
info.reset();