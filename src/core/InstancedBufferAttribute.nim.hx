import three.js.src.core.BufferAttribute;

class InstancedBufferAttribute extends BufferAttribute {

    public var isInstancedBufferAttribute:Bool = true;
    public var meshPerAttribute:Int = 1;

    public function new(array:Array<Dynamic>, itemSize:Int, normalized:Bool, meshPerAttribute:Int = 1) {
        super(array, itemSize, normalized);
        this.meshPerAttribute = meshPerAttribute;
    }

    public function copy(source:InstancedBufferAttribute):InstancedBufferAttribute {
        super.copy(source);
        this.meshPerAttribute = source.meshPerAttribute;
        return this;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();
        data.meshPerAttribute = this.meshPerAttribute;
        data.isInstancedBufferAttribute = true;
        return data;
    }

}

export type InstancedBufferAttribute;