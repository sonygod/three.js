import js.html.WebGL;

class AudioAnalyser {
    public var analyser: Dynamic;
    public var data: js.typedarrays.Uint8Array;

    public function new(audio: Dynamic, fftSize: Int = 2048) {
        this.analyser = audio.context.createAnalyser();
        this.analyser.fftSize = fftSize;

        this.data = js.typedarrays.Uint8Array.new(this.analyser.frequencyBinCount);

        audio.getOutput().connect(this.analyser);
    }

    public function getFrequencyData(): js.typedarrays.Uint8Array {
        this.analyser.getByteFrequencyData(this.data);

        return this.data;
    }

    public function getAverageFrequency(): Float {
        var value: Float = 0;
        var data: js.typedarrays.Uint8Array = this.getFrequencyData();

        for (var i: Int = 0; i < data.length; i++) {
            value += data[i];
        }

        return value / data.length;
    }
}