class Info {

	var autoReset:Bool;
	var frame:Int;
	var calls:Int;
	var render:Dynamic<Int>;
	var compute:Dynamic<Int>;
	var memory:Dynamic<Int>;

	public function new() {

		this.autoReset = true;

		this.frame = 0;
		this.calls = 0;

		this.render = {
			calls: 0,
			drawCalls: 0,
			triangles: 0,
			points: 0,
			lines: 0,
			timestamp: 0
		};

		this.compute = {
			calls: 0,
			computeCalls: 0,
			timestamp: 0
		};

		this.memory = {
			geometries: 0,
			textures: 0
		};

	}

	public function update(object:Dynamic, count:Int, instanceCount:Int):Void {

		this.render.drawCalls ++;

		if (object.isMesh || object.isSprite) {

			this.render.triangles += instanceCount * (count / 3);

		} else if (object.isPoints) {

			this.render.points += instanceCount * count;

		} else if (object.isLineSegments) {

			this.render.lines += instanceCount * (count / 2);

		} else if (object.isLine) {

			this.render.lines += instanceCount * (count - 1);

		} else {

			trace('THREE.WebGPUInfo: Unknown object type.');

		}

	}

	public function updateTimestamp(type:String, time:Int):Void {

		this.render[type].timestamp += time;

	}

	public function reset():Void {

		this.render.drawCalls = 0;
		this.compute.computeCalls = 0;

		this.render.triangles = 0;
		this.render.points = 0;
		this.render.lines = 0;

		this.render.timestamp = 0;
		this.compute.timestamp = 0;

	}

	public function dispose():Void {

		this.reset();

		this.calls = 0;

		this.render.calls = 0;
		this.compute.calls = 0;

		this.render.timestamp = 0;
		this.compute.timestamp = 0;
		this.memory.geometries = 0;
		this.memory.textures = 0;

	}

}