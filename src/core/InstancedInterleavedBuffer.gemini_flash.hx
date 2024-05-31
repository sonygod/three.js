import three.core.InterleavedBuffer;

class InstancedInterleavedBuffer extends InterleavedBuffer {
  public var isInstancedInterleavedBuffer:Bool = true;
  public var meshPerAttribute:Int;

  public function new(array:Array<Float>, stride:Int, meshPerAttribute:Int = 1) {
    super(array, stride);
    this.meshPerAttribute = meshPerAttribute;
  }

  public function copy(source:InstancedInterleavedBuffer):InstancedInterleavedBuffer {
    super.copy(source);
    this.meshPerAttribute = source.meshPerAttribute;
    return this;
  }

  public function clone(data:Dynamic = null):InstancedInterleavedBuffer {
    var ib = super.clone(data) as InstancedInterleavedBuffer;
    ib.meshPerAttribute = this.meshPerAttribute;
    return ib;
  }

  public function toJSON(data:Dynamic = null):Dynamic {
    var json = super.toJSON(data);
    json.isInstancedInterleavedBuffer = true;
    json.meshPerAttribute = this.meshPerAttribute;
    return json;
  }
}