import InterleavedBuffer from './InterleavedBuffer.hx';

class InstancedInterleavedBuffer extends InterleavedBuffer {

    public var isInstancedInterleavedBuffer:Bool = true;
    public var meshPerAttribute:Int = 1;

    public function new(array:Array<Dynamic>, stride:Int, meshPerAttribute:Int = 1) {
        super(array, stride);
        this.meshPerAttribute = meshPerAttribute;
    }

    public function copy(source:InstancedInterleavedBuffer):InstancedInterleavedBuffer {
        super.copy(source);
        this.meshPerAttribute = source.meshPerAttribute;
        return this;
    }

    public function clone(data:Array<Dynamic>):InstancedInterleavedBuffer {
        var ib = super.clone(data);
        ib.meshPerAttribute = this.meshPerAttribute;
        return ib;
    }

    public function toJSON(data:Dynamic):Dynamic {
        var json = super.toJSON(data);
        json.isInstancedInterleavedBuffer = true;
        json.meshPerAttribute = this.meshPerAttribute;
        return json;
    }

}

export InstancedInterleavedBuffer;