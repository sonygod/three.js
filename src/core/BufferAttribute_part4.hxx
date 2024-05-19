@:jsRequire('three.js/src/core/BufferAttribute.js')
class Uint8ClampedBufferAttribute extends BufferAttribute {

    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new Uint8ClampedArray(array), itemSize, normalized);
    }

}

@:native("new Uint8ClampedArray($v)")
extern class Uint8ClampedArray {
    public function new(v:Array<Int>);
}