class AudioAnalyser {
	var analyser:Dynamic;
	var data:Uint8Array;

	public function new(audio:Dynamic, fftSize:Int = 2048) {
		analyser = audio.getContext().createAnalyser();
		analyser.fftSize = fftSize;
		data = new Uint8Array(analyser.frequencyBinCount);
		audio.getOutput().connect(analyser);
	}

	public function getFrequencyData():Uint8Array {
		analyser.getByteFrequencyData(data);
		return data;
	}

	public function getAverageFrequency():Float {
		var value:Float = 0;
		var dataArray:Array<Int> = getFrequencyData().toArray();
		for (i in 0...dataArray.length) {
			value += dataArray[i];
		}
		return value / dataArray.length;
	}
}