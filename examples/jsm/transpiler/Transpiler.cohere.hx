class Transpiler {
	public var decoder:IDecoder;
	public var encoder:IEncoder;

	public function new(decoder:IDecoder, encoder:IEncoder) {
		this.decoder = decoder;
		this.encoder = encoder;
	}

	public function parse(source:String):String {
		return encoder.emit(decoder.parse(source));
	}

}

interface IDecoder {
	function parse(source:String):Dynamic;
}

interface IEncoder {
	function emit(data:Dynamic):String;
}