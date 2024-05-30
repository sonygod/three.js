class Info {

	public var autoReset:Bool = true;

	public var frame:Int = 0;
	public var calls:Int = 0;

	public var render:Dynamic = {
		calls: 0,
		drawCalls: 0,
		triangles: 0,
		points: 0,
		lines: 0,
		timestamp: 0
	};

	public var compute:Dynamic = {
		calls: 0,
		computeCalls: 0,
		timestamp: 0
	};

	public var memory:Dynamic = {
		geometries: 0,
		textures: 0
	};

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

	public function update( object:Dynamic, count:Int, instanceCount:Int ) {

		this.render.drawCalls++;

		if (Std.is(object, Mesh) || Std.is(object, Sprite)) {

			this.render.triangles += instanceCount * (count / 3);

		} else if (Std.is(object, Points)) {

			this.render.points += instanceCount * count;

		} else if (Std.is(object, LineSegments)) {

			this.render.lines += instanceCount * (count / 2);

		} else if (Std.is(object, Line)) {

			this.render.lines += instanceCount * (count - 1);

		} else {

			trace('THREE.WebGPUInfo: Unknown object type.');

		}

	}

	public function updateTimestamp( type:String, time:Float ) {

		this[type].timestamp += time;

	}

	public function reset() {

		this.render.drawCalls = 0;
		this.compute.computeCalls = 0;

		this.render.triangles = 0;
		this.render.points = 0;
		this.render.lines = 0;

		this.render.timestamp = 0;
		this.compute.timestamp = 0;

	}

	public function dispose() {

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