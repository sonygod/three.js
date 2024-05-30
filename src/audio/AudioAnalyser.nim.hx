import js.html.AudioContext;
import js.html.AudioNode;
import js.html.AnalyserNode;
import js.html.Uint8Array;

class AudioAnalyser {

	var analyser:AnalyserNode;
	var data:Uint8Array;

	public function new(audio:AudioContext, fftSize:Int = 2048) {

		this.analyser = audio.createAnalyser();
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
		var data:Uint8Array = this.getFrequencyData();

		for (i in 0...data.length) {

			value += data[i];

		}

		return value / data.length;

	}

}

export haxe.extern.Lib.addClass(AudioAnalyser);