class Uint8BufferAttribute extends BufferAttribute {

    public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {

        super(new js.html.Uint8Array(new js.Array<UInt>(array)), itemSize, normalized);

    }

}