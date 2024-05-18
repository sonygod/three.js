package audio;

import js.html.audio.Analyser;
import js.html.audio.AudioContext;
import js.html.audio.MediaStreamAudioSourceNode;

class AudioAnalyser {
    private var analyser:Analyser;
    private var data:Uint8Array;

    public function new(audio:AudioContext, fftSize:Int = 2048) {
        analyser = audio.createAnalyser();
        analyser.fftSize = fftSize;

        data = new Uint8Array(analyser.frequencyBinCount);

        // Assuming `audio.getOutput()` returns a MediaStreamAudioSourceNode
        audio.getOutput().connect(analyser);
    }

    public function getFrequencyData():Uint8Array {
        analyser.getByteFrequencyData(data);
        return data;
    }

    public function getAverageFrequency():Float {
        var value:Float = 0;
        var data:Uint8Array = getFrequencyData();

        for (i in 0...data.length) {
            value += data[i];
        }

        return value / data.length;
    }
}