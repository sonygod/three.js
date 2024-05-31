import three.audio.Audio;
import js.html.AudioContext;
import js.html.AnalyserNode;
import js.html.Uint8Array;

class AudioAnalyser {

	public var analyser:AnalyserNode;
	public var data:Uint8Array;

	public function new(audio:Audio, fftSize:Int = 2048) {
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
		var data = getFrequencyData();
		for (i in 0...data.length) {
			value += data[i];
		}
		return value / data.length;
	}
}


**Explanation:**

1. **Imports:** We import necessary classes from the Haxe libraries. 
   - `three.audio.Audio` represents the audio source.
   - `js.html.AudioContext` is the Web Audio API context.
   - `js.html.AnalyserNode` is the analyser object.
   - `js.html.Uint8Array` is used to store the frequency data.

2. **Class Definition:** The `AudioAnalyser` class is defined with the `new` constructor and methods.

3. **Constructor:**
   - The constructor takes the `audio` object and `fftSize` as arguments.
   - It creates an `AnalyserNode` using the `audio.context`.
   - The `fftSize` is set for the analyser.
   - A `Uint8Array` is created to store the frequency data based on the analyser's `frequencyBinCount`.
   - Finally, it connects the audio output to the analyser.

4. **`getFrequencyData()`:**
   - This method calls `analyser.getByteFrequencyData()` to fill the `data` array with frequency data.
   - It returns the `data` array.

5. **`getAverageFrequency()`:**
   - This method retrieves the frequency data using `getFrequencyData()`.
   - It iterates through the data array, summing the values.
   - It calculates the average frequency by dividing the sum by the length of the data array.
   - It returns the average frequency as a `Float`.

**To Use:**


// Create an Audio object
var audio = new Audio();

// Create an AudioAnalyser object
var analyser = new AudioAnalyser(audio);

// Get the average frequency
var averageFrequency = analyser.getAverageFrequency();