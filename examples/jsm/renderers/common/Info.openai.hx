package three.js.examples.jm.renderers.common;

class Info {
  public var autoReset:Bool = true;

  public var frame:Int = 0;
  public var calls:Int = 0;

  public var render:RenderStats = {
    calls: 0,
    drawCalls: 0,
    triangles: 0,
    points: 0,
    lines: 0,
    timestamp: 0
  };

  public var compute:ComputeStats = {
    calls: 0,
    computeCalls: 0,
    timestamp: 0
  };

  public var memory:MemoryStats = {
    geometries: 0,
    textures: 0
  };

  public function new() {} // constructor

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
      trace("THREE.WebGPUInfo: Unknown object type.");
    }
  }

  public function updateTimestamp(type:String, time:Float):Void {
    Reflect.setField(this, type).timestamp += time;
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

typedef RenderStats = {
  calls:Int,
  drawCalls:Int,
  triangles:Int,
  points:Int,
  lines:Int,
  timestamp:Float
}

typedef ComputeStats = {
  calls:Int,
  computeCalls:Int,
  timestamp:Float
}

typedef MemoryStats = {
  geometries:Int,
  textures:Int
}