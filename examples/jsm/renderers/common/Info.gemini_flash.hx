class Info {
	public var autoReset:Bool = true;
	public var frame:Int = 0;
	public var calls:Int = 0;
	public var render:RenderInfo = new RenderInfo();
	public var compute:ComputeInfo = new ComputeInfo();
	public var memory:MemoryInfo = new MemoryInfo();

	public function new() {
	}

	public function update(object:Dynamic, count:Int, instanceCount:Int):Void {
		render.drawCalls++;

		if (object.isMesh || object.isSprite) {
			render.triangles += instanceCount * (count / 3);
		} else if (object.isPoints) {
			render.points += instanceCount * count;
		} else if (object.isLineSegments) {
			render.lines += instanceCount * (count / 2);
		} else if (object.isLine) {
			render.lines += instanceCount * (count - 1);
		} else {
			Sys.println("THREE.WebGPUInfo: Unknown object type.");
		}
	}

	public function updateTimestamp(type:String, time:Float):Void {
		switch (type) {
		case "render":
			render.timestamp += time;
		case "compute":
			compute.timestamp += time;
		default:
			Sys.println("THREE.WebGPUInfo: Unknown timestamp type.");
		}
	}

	public function reset():Void {
		render.drawCalls = 0;
		compute.computeCalls = 0;

		render.triangles = 0;
		render.points = 0;
		render.lines = 0;

		render.timestamp = 0;
		compute.timestamp = 0;
	}

	public function dispose():Void {
		reset();

		calls = 0;

		render.calls = 0;
		compute.calls = 0;

		render.timestamp = 0;
		compute.timestamp = 0;
		memory.geometries = 0;
		memory.textures = 0;
	}
}

class RenderInfo {
	public var calls:Int = 0;
	public var drawCalls:Int = 0;
	public var triangles:Float = 0;
	public var points:Float = 0;
	public var lines:Float = 0;
	public var timestamp:Float = 0;

	public function new() {
	}
}

class ComputeInfo {
	public var calls:Int = 0;
	public var computeCalls:Int = 0;
	public var timestamp:Float = 0;

	public function new() {
	}
}

class MemoryInfo {
	public var geometries:Int = 0;
	public var textures:Int = 0;

	public function new() {
	}
}