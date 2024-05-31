```haxe
import three.core.InterleavedBuffer;

class InstancedInterleavedBuffer extends InterleavedBuffer {

	public var isInstancedInterleavedBuffer:Bool;
	public var meshPerAttribute:Int;

	public function new(array:Array<Float>, stride:Int, meshPerAttribute:Int = 1) {
		super(array, stride);
		this.isInstancedInterleavedBuffer = true;
		this.meshPerAttribute = meshPerAttribute;
	}

	public function copy(source:InstancedInterleavedBuffer):InstancedInterleavedBuffer {
		super.copy(source);
		this.meshPerAttribute = source.meshPerAttribute;
		return this;
	}

	public function clone(data:Dynamic = null):InstancedInterleavedBuffer {
		var ib = super.clone(data);
		ib.meshPerAttribute = this.meshPerAttribute;
		return ib;
	}

	public function toJSON(data:Dynamic = null):Dynamic {
		var json = super.toJSON(data);
		json.isInstancedInterleavedBuffer = true;
		json.meshPerAttribute = this.meshPerAttribute;
		return json;
	}

}
```

This Haxe code is a direct translation of the provided JavaScript code. Here's a breakdown:

1. **Import:** The `import three.core.InterleavedBuffer;` line imports the `InterleavedBuffer` class from the Haxe `three` library.
2. **Class Definition:** The `InstancedInterleavedBuffer` class is defined, inheriting from `InterleavedBuffer`.
3. **Constructor:** The constructor takes the same parameters as the JavaScript version: `array` (the data array), `stride` (the number of elements per vertex), and `meshPerAttribute` (the number of meshes associated with each attribute). It initializes the `isInstancedInterleavedBuffer` flag to `true` and sets the `meshPerAttribute` property.
4. **Methods:** The `copy`, `clone`, and `toJSON` methods are translated directly, using Haxe syntax and making sure to set the `meshPerAttribute` property accordingly.

This Haxe code achieves the same functionality as the original JavaScript code, allowing you to work with instanced interleaved buffers in your Haxe Three.js projects. Remember to include this code in your Haxe project and use it as you would in JavaScript. 
