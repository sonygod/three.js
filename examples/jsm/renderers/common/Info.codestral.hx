class Info {
    public var autoReset:Bool = true;
    public var frame:Int = 0;
    public var calls:Int = 0;

    public var render:{calls:Int, drawCalls:Int, triangles:Int, points:Int, lines:Int, timestamp:Int};
    public var compute:{calls:Int, computeCalls:Int, timestamp:Int};
    public var memory:{geometries:Int, textures:Int};

    public function new() {
        this.render = {calls:0, drawCalls:0, triangles:0, points:0, lines:0, timestamp:0};
        this.compute = {calls:0, computeCalls:0, timestamp:0};
        this.memory = {geometries:0, textures:0};
    }

    public function update(object:Dynamic, count:Int, instanceCount:Int) {
        this.render.drawCalls++;

        if (Std.is(object, js.Boot.getClass('THREE.Mesh')) || Std.is(object, js.Boot.getClass('THREE.Sprite'))) {
            this.render.triangles += instanceCount * (count / 3);
        } else if (Std.is(object, js.Boot.getClass('THREE.Points'))) {
            this.render.points += instanceCount * count;
        } else if (Std.is(object, js.Boot.getClass('THREE.LineSegments'))) {
            this.render.lines += instanceCount * (count / 2);
        } else if (Std.is(object, js.Boot.getClass('THREE.Line'))) {
            this.render.lines += instanceCount * (count - 1);
        } else {
            trace('THREE.WebGPUInfo: Unknown object type.');
        }
    }

    public function updateTimestamp(type:String, time:Int) {
        if(type == 'render') this.render.timestamp += time;
        else if(type == 'compute') this.compute.timestamp += time;
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