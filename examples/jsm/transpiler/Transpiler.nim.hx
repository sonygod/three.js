class Transpiler {
    var decoder:Dynamic;
    var encoder:Dynamic;

    public function new(decoder:Dynamic, encoder:Dynamic) {
        this.decoder = decoder;
        this.encoder = encoder;
    }

    public function parse(source:Dynamic):Dynamic {
        return this.encoder.emit(this.decoder.parse(source));
    }
}