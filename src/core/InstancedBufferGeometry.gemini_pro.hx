import BufferGeometry from "./BufferGeometry";

class InstancedBufferGeometry extends BufferGeometry {

  public var isInstancedBufferGeometry:Bool = true;
  public var type:String = "InstancedBufferGeometry";
  public var instanceCount:Int = Int.MAX;

  public function new() {
    super();
  }

  public function copy(source:InstancedBufferGeometry):InstancedBufferGeometry {
    super.copy(source);
    this.instanceCount = source.instanceCount;
    return this;
  }

  public function toJSON():Dynamic {
    var data = super.toJSON();
    data.instanceCount = this.instanceCount;
    data.isInstancedBufferGeometry = true;
    return data;
  }
}

export class InstancedBufferGeometry {
}