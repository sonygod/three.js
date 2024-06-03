class AudioAnalyser {

	var analyser:haxe.io.AudioBufferSourceNode;
	var data:Array<Int>;

	public function new(audio:haxe.io.AudioBufferSourceNode, fftSize:Int = 2048) {
		this.analyser = audio.context.createAnalyser();
		this.analyser.fftSize = fftSize;
		this.data = new Array<Int>(this.analyser.frequencyBinCount);
		audio.getOutput().connect(this.analyser);
	}

	public function getFrequencyData():Array<Int> {
		this.analyser.getByteFrequencyData(this.data);
		return this.data;
	}

	public function getAverageFrequency():Float {
		var value:Int = 0;
		var data:Array<Int> = this.getFrequencyData();
		for (i in 0...data.length) {
			value += data[i];
		}
		return value / data.length;
	}
}


**Explanation:**

* **Class Definition:** The `class AudioAnalyser` declaration is similar to JavaScript, defining a class.
* **Constructor:** The `new` function is used as the constructor in Haxe. It takes the `audio` source and optional `fftSize` as parameters.
* **Data Types:**
    * `haxe.io.AudioBufferSourceNode` is used to represent the audio source.
    * `Array<Int>` is used for the frequency data.
* **Field Initialization:**
    * `analyser` and `data` are declared as fields and initialized within the constructor.
    * `this.analyser.frequencyBinCount` is used to get the number of frequency bins.
* **`getFrequencyData()`:**
    * The function `getByteFrequencyData` is used to populate the `data` array with frequency data.
* **`getAverageFrequency()`:**
    * The function iterates through the `data` array to calculate the average frequency.

**Key Differences from JavaScript:**

* **`new` keyword:** In Haxe, the constructor is defined using the `new` keyword instead of `constructor`.
* **Data Types:** Haxe uses strong typing, so you need to specify the data types for variables (e.g., `Int`, `Float`, `Array<Int>`).
* **Array Iteration:** The `for...in` loop is used to iterate through arrays in Haxe.

**Usage:**


// Assuming you have an AudioBufferSourceNode object called 'audio'
var analyser = new AudioAnalyser(audio);

// Get the frequency data
var frequencyData = analyser.getFrequencyData();

// Get the average frequency
var averageFrequency = analyser.getAverageFrequency();