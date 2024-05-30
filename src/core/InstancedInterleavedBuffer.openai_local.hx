import three.core.InterleavedBuffer;

class InstancedInterleavedBuffer extends InterleavedBuffer {

    public var isInstancedInterleavedBuffer:Bool;
    public var meshPerAttribute:Int;

    public function new(array:Array<Float>, stride:Int, meshPerAttribute:Int = 1) {
        super(array, stride);
        this.isInstancedInterleavedBuffer = true;
        this.meshPerAttribute = meshPerAttribute;
    }

    public override function copy(source:InterleavedBuffer):InstancedInterleavedBuffer {
        super.copy(source);
        if (Std.is(source, InstancedInterleavedBuffer)) {
            this.meshPerAttribute = (cast source:InstancedInterleavedBuffer).meshPerAttribute;
        }
        return this;
    }

    public override function clone(data:Dynamic):InterleavedBuffer {
        var ib:InstancedInterleavedBuffer = cast super.clone(data);
        ib.meshPerAttribute = this.meshPerAttribute;
        return ib;
    }

    public override function toJSON(data:Dynamic):Dynamic {
        var json:Dynamic = super.toJSON(data);
        json.isInstancedInterleavedBuffer = true;
        json.meshPerAttribute = this.meshPerAttribute;
        return json;
    }
}