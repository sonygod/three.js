package three.js.examples.jsm.transpiler;

class Transpiler {
    public var decoder:Dynamic;
    public var encoder:Dynamic;

    public function new(decoder:Dynamic, encoder:Dynamic) {
        this.decoder = decoder;
        this.encoder = encoder;
    }

    public function parse(source:Dynamic):Dynamic {
        return encoder.emit(decoder.parse(source));
    }
}