@:native('three.js.src.core.BufferAttribute_part3.Uint8BufferAttribute')
class Uint8BufferAttribute extends BufferAttribute {

    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new Uint8Array(array), itemSize, normalized);
    }

}