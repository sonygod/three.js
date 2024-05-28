package three.src.core;

import three.src.core.BufferGeometry;

class InstancedBufferGeometry extends BufferGeometry {
    public var isInstancedBufferGeometry:Bool = true;
    public var type:String = 'InstancedBufferGeometry';
    public var instanceCount:Int = Math.POSITIVE_INFINITY;

    public function new() {
        super();
    }

    override public function copy(source:InstancedBufferGeometry):InstancedBufferGeometry {
        super.copy(source);
        this.instanceCount = source.instanceCount;
        return this;
    }

    override public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();
        data.instanceCount = this.instanceCount;
        data.isInstancedBufferGeometry = true;
        return data;
    }
}