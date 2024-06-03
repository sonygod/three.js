class Transpiler {
    private var decoder: Decoder;
    private var encoder: Encoder;

    public function new(decoder: Decoder, encoder: Encoder) {
        this.decoder = decoder;
        this.encoder = encoder;
    }

    public function parse(source: String): String {
        return this.encoder.emit(this.decoder.parse(source));
    }
}