import three.core.BufferGeometry;

class InstancedBufferGeometry extends BufferGeometry {

    public var instanceCount:Int = Int.POSITIVE_INFINITY;

    public function new() {
        super();
        this.isInstancedBufferGeometry = true;
        this.type = 'InstancedBufferGeometry';
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