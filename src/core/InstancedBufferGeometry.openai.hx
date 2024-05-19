import three.BufferGeometry;

class InstancedBufferGeometry extends BufferGeometry {

    public var instanceCount(default, null):Int;

    public function new():Void {
        super();

        this.isInstancedBufferGeometry = true;
        this.type = 'InstancedBufferGeometry';
        this.instanceCount = Math.POSITIVE_INFINITY;
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