class AudioAnalyser {

	public var analyser:AnalyserNode;
	public var data:haxe.io.Bytes;

	public function new(audio:Audio, fftSize:Int = 2048) {
		this.analyser = audio.context.createAnalyser();
		this.analyser.fftSize = fftSize;
		this.data = haxe.io.Bytes.alloc(this.analyser.frequencyBinCount);
		audio.getOutput().connect(this.analyser);
	}

	public function getFrequencyData():haxe.io.Bytes {
		this.analyser.getByteFrequencyData(this.data);
		return this.data;
	}

	public function getAverageFrequency():Float {
		var value:Float = 0;
		var data = this.getFrequencyData();
		for (i in 0...data.length) {
			value += data.get(i);
		}
		return value / data.length;
	}
}


**Explanation:**

* **Imports:** The code imports `AnalyserNode` and `Audio` from the `three.js` library. It also imports `Bytes` from the `haxe.io` package for handling binary data.
* **Constructor:**
    * The `new` function initializes the `analyser` object using `audio.context.createAnalyser()`.
    * It sets the `fftSize` property of the analyser.
    * It creates a `Bytes` object of the appropriate size to store the frequency data.
    * It connects the audio output to the analyser.
* **`getFrequencyData()`:**
    * The function calls `analyser.getByteFrequencyData()` to get the frequency data.
    * It returns the `data` object containing the frequency data.
* **`getAverageFrequency()`:**
    * The function first calls `getFrequencyData()` to obtain the frequency data.
    * It iterates over the data array and sums up all the values.
    * Finally, it calculates the average frequency by dividing the sum by the total number of values.

**Notes:**

* The Haxe code uses the `Bytes` type to represent binary data, while the JavaScript code uses `Uint8Array`.
* The Haxe code uses the `for` loop to iterate over the data array, while the JavaScript code uses the `for` loop with the `i++` syntax.
* The Haxe code assumes that the `three.js` library is available and that the `Audio` and `AnalyserNode` types are defined within it.

**Usage:**


var audio = new Audio("audio.mp3");
var analyser = new AudioAnalyser(audio);
var frequencyData = analyser.getFrequencyData();
var averageFrequency = analyser.getAverageFrequency();