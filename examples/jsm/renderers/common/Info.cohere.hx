class Info {
	var autoReset:Bool = true;
	var frame:Int;
	var calls:Int;
	var render:RenderInfo;
	var compute:ComputeInfo;
	var memory:MemoryInfo;

	public function new() {
		frame = 0;
		calls = 0;
		render = { calls: 0, drawCalls: 0, triangles: 0, points: 0, lines: 0, timestamp: 0 };
		compute = { calls: 0, computeCalls: 0, timestamp: 0 };
		memory = { geometries: 0, textures: 0 };
	}

	public function update(object:Dynamic, count:Int, instanceCount:Int):Void {
		render.drawCalls++;

		if (Std.is(object, Mesh)) {
			render.triangles += instanceCount * (count / 3);
		} else if (Std.is(object, Sprite)) {
			render.points += instanceCount * count;
		} else if (Std.is(object, LineSegments)) {
			render.lines += instanceCount * (count / 2);
		} else if (Std.is(object, Line)) {
			render.lines += instanceCount * (count - 1);
		} else {
			trace("Info: Unknown object type.");
		}
	}

	public function updateTimestamp(type:String, time:Float):Void {
		switch (type) {
			case "render":
				render.timestamp += time;
				break;
			case "compute":
				compute.timestamp += time;
				break;
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
	var calls:Int;
	var drawCalls:Int;
	var triangles:Int;
	var points:Int;
	var lines:Int;
	var timestamp:Float;
}

class ComputeInfo {
	var calls:Int;
	var computeCalls:Int;
	var timestamp:Float;
}

class MemoryInfo {
	var geometries:Int;
	var textures:Int;
}