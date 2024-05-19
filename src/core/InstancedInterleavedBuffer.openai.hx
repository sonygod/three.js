package three.core;

class InstancedInterleavedBuffer extends InterleavedBuffer {

  public var meshPerAttribute:Int;

  public function new(array:Array<Float>, stride:Int, meshPerAttribute:Int = 1) {
    super(array, stride);
    this.isInstancedInterleavedBuffer = true;
    this.meshPerAttribute = meshPerAttribute;
  }

  public function copy(source:InstancedInterleavedBuffer):InstancedInterleavedBuffer {
    super.copy(source);
    this.meshPerAttribute = source.meshPerAttribute;
    return this;
  }

  public function clone(data:Array<Float>):InstancedInterleavedBuffer {
    var ib:InstancedInterleavedBuffer = super.clone(data);
    ib.meshPerAttribute = this.meshPerAttribute;
    return ib;
  }

  public function toJSON(data:Array<Float>):Dynamic {
    var json:Dynamic = super.toJSON(data);
    json.isInstancedInterleavedBuffer = true;
    json.meshPerAttribute = this.meshPerAttribute;
    return json;
  }
}