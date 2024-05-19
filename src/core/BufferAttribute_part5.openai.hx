import js.TypedArray.ArrayBufferView;

class Int16BufferAttribute extends BufferAttribute {
  
  public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
    super(new Int16Array(array as ArrayBufferView), itemSize, normalized);
  }
}