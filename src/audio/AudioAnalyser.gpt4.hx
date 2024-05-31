package three.audio;

import js.html.AudioContext;
import js.html.AnalyserNode;
import js.html.Uint8Array;

class AudioAnalyser {
    var analyser:AnalyserNode;
    var data:Uint8Array;

    public function new(audio:Dynamic, ?fftSize:Int = 2048) {
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
        var value:Float = 0;
        var data = this.getFrequencyData();
        for (i in 0...data.length) {
            value += data[i];
        }
        return value / data.length;
    }
}

@:native("AudioAnalyser")
extern class AudioAnalyserExtern {
    static public var analyser:AnalyserNode;
    static public var data:Uint8Array;

    static public function new(audio:Dynamic, ?fftSize:Int = 2048):Void;
    static public function getFrequencyData():Uint8Array;
    static public function getAverageFrequency():Float;
}