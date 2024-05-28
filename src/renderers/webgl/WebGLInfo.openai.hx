package three.js.src.renderers.webgl;

class WebGLInfo {
	var gl:GL;

	var memory = {
		geometries: 0,
		textures: 0
	};

	var render = {
		frame: 0,
		calls: 0,
		triangles: 0,
		points: 0,
		lines: 0
	};

	var programs:Null<Array<Dynamic>> = null;

	var autoReset:Bool = true;

	public function new(gl:GL) {
		this.gl = gl;
	}

	function update(count:Int, mode:Int, instanceCount:Int) {
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

	function reset() {
		render.calls = 0;
		render.triangles = 0;
		render.points = 0;
		render.lines = 0;
	}

	public function getMemory():{geometries:Int, textures:Int} {
		return memory;
	}

	public function getRender():{frame:Int, calls:Int, triangles:Int, points:Int, lines:Int} {
		return render;
	}

	public function getPrograms():Null<Array<Dynamic>> {
		return programs;
	}

	public function isAutoReset():Bool {
		return autoReset;
	}

	public function reset():Void {
		reset();
	}

	public function update(count:Int, mode:Int, instanceCount:Int):Void {
		update(count, mode, instanceCount);
	}
}