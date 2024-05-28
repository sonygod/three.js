package three.js.src.core;

import three.js.src.core.BufferGeometry;

class InstancedBufferGeometry extends BufferGeometry {

    public var isInstancedBufferGeometry:Bool = true;
    public var type:String = 'InstancedBufferGeometry';
    public var instanceCount:Int = Math.POSITIVE_INFINITY;

    public function new() {
        super();
    }

    public function copy(source:InstancedBufferGeometry):InstancedBufferGeometry {
        super.copy(source);
        instanceCount = source.instanceCount;
        return this;
    }

    public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();
        data.instanceCount = instanceCount;
        data.isInstancedBufferGeometry = true;
        return data;
    }
}