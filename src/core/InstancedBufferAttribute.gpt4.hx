import three.core.BufferAttribute;

class InstancedBufferAttribute extends BufferAttribute {

    public var isInstancedBufferAttribute:Bool;
    public var meshPerAttribute:Int;

    public function new(array:Dynamic, itemSize:Int, normalized:Bool, meshPerAttribute:Int = 1) {
        super(array, itemSize, normalized);
        this.isInstancedBufferAttribute = true;
        this.meshPerAttribute = meshPerAttribute;
    }

    public override function copy(source:BufferAttribute):InstancedBufferAttribute {
        super.copy(source);
        var src:InstancedBufferAttribute = cast source;
        this.meshPerAttribute = src.meshPerAttribute;
        return this;
    }

    public override function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();
        data.meshPerAttribute = this.meshPerAttribute;
        data.isInstancedBufferAttribute = true;
        return data;
    }

}