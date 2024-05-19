import js.TypedArray;

class Int8BufferAttribute extends BufferAttribute {

    public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
        super(TypedArray.fromArray(array, Int8Array), itemSize, normalized);
    }

}