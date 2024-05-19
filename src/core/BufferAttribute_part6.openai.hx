class Uint16BufferAttribute extends BufferAttribute {
  
  public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
  	super(new Uint16Array(array), itemSize, normalized);
  }

}