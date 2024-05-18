package three.js.examples.jvm.renderers.common;

class Info {
    public var autoReset:Bool;
    public var frame:Int;
    public var calls:Int;
    public var render:RenderStats;
    public var compute:ComputeStats;
    public var memory:MemoryStats;

    public function new() {
        autoReset = true;
        frame = 0;
        calls = 0;
        render = new RenderStats();
        compute = new ComputeStats();
        memory = new MemoryStats();
    }

    public function update(object:Dynamic, count:Int, instanceCount:Int) {
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
            Sys.stderr().println('THREE.WebGPUInfo: Unknown object type.');
        }
    }

    public function updateTimestamp(type:String, time:Float) {
        Reflect.setField(this, type).timestamp += time;
    }

    public function reset() {
        render.drawCalls = 0;
        compute.computeCalls = 0;
        render.triangles = 0;
        render.points = 0;
        render.lines = 0;
        render.timestamp = 0;
        compute.timestamp = 0;
    }

    public function dispose() {
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

class RenderStats {
    public var calls:Int;
    public var drawCalls:Int;
    public var triangles:Int;
    public var points:Int;
    public var lines:Int;
    public var timestamp:Float;

    public function new() {
        calls = 0;
        drawCalls = 0;
        triangles = 0;
        points = 0;
        lines = 0;
        timestamp = 0.0;
    }
}

class ComputeStats {
    public var calls:Int;
    public var computeCalls:Int;
    public var timestamp:Float;

    public function new() {
        calls = 0;
        computeCalls = 0;
        timestamp = 0.0;
    }
}

class MemoryStats {
    public var geometries:Int;
    public var textures:Int;

    public function new() {
        geometries = 0;
        textures = 0;
    }
}