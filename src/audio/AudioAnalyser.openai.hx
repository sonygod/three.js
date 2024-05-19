class AudioAnalyser {

    var analyser:AnalyserNode;
    var data:UInt8Array;

    public function new(audio:Audio, fftSize:Int = 2048) {
        analyser = audio.context.createAnalyser();
        analyser.fftSize = fftSize;
        data = new UInt8Array(analyser.frequencyBinCount);
        audio.getOutput().connect(analyser);
    }

    public function getFrequencyData():UInt8Array {
        analyser.getByteFrequencyData(data);
        return data;
    }

    public function getAverageFrequency():Float {
        var value:Float = 0;
        var data:UInt8Array = getFrequencyData();
        for (i in 0...data.length) {
            value += data[i];
        }
        return value / data.length;
    }
}

typedef AudioAnalyser = audio.AudioAnalyser;
```