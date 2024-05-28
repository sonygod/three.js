package three.js.src.audio;

import js.html.audio.AudioContext;
import js.html.audio.Analyser;
import js.html.Uint8Array;

class AudioAnalyser {

    private var analyser:Analyser;
    private var data:Uint8Array;
    private var audio:Dynamic; // assuming audio is an object with a getOutput() method

    public function new(audio:Dynamic, fftSize:Int = 2048) {
        this.analyser = audio.context.createAnalyser();
        this.analyser.fftSize = fftSize;

        this.data = new Uint8Array(this.analyser.frequencyBinCount);

        audio.getOutput().connect(this.analyser);
    }

    public function getFrequencyData():Uint8Array {
        this.analyser.getByteFrequencyData(this.data);
        return this.data;
    }

    public function getAverageFrequency():Float {
        var value:Float = 0.0;
        var data:Uint8Array = this.getFrequencyData();

        for (i in 0...data.length) {
            value += data[i];
        }

        return value / data.length;
    }
}