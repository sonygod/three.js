import three.core.BufferAttribute;

class InstancedBufferAttribute extends BufferAttribute {

    public var meshPerAttribute:Int;

    public function new(array:Array<Float>, itemSize:Int, normalized:Bool, meshPerAttribute:Int = 1) {
        super(array, itemSize, normalized);
        this.isInstancedBufferAttribute = true;
        this.meshPerAttribute = meshPerAttribute;
    }

    @:override
    public function copy(source:InstancedBufferAttribute):InstancedBufferAttribute {
        super.copy(source);
        this.meshPerAttribute = source.meshPerAttribute;
        return this;
    }

    @:override
    public function toJSON():Dynamic {
        var data = super.toJSON();
        data.meshPerAttribute = this.meshPerAttribute;
        data.isInstancedBufferAttribute = true;
        return data;
    }
}