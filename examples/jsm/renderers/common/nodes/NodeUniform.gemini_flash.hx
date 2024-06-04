import Uniform.FloatUniform;
import Uniform.Vector2Uniform;
import Uniform.Vector3Uniform;
import Uniform.Vector4Uniform;
import Uniform.ColorUniform;
import Uniform.Matrix3Uniform;
import Uniform.Matrix4Uniform;

class FloatNodeUniform extends FloatUniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	override public function getValue():Float {
		return this.nodeUniform.value;
	}
}

class Vector2NodeUniform extends Vector2Uniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	override public function getValue():Array<Float> {
		return this.nodeUniform.value;
	}
}

class Vector3NodeUniform extends Vector3Uniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	override public function getValue():Array<Float> {
		return this.nodeUniform.value;
	}
}

class Vector4NodeUniform extends Vector4Uniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	override public function getValue():Array<Float> {
		return this.nodeUniform.value;
	}
}

class ColorNodeUniform extends ColorUniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	override public function getValue():Array<Float> {
		return this.nodeUniform.value;
	}
}

class Matrix3NodeUniform extends Matrix3Uniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	override public function getValue():Array<Array<Float>> {
		return this.nodeUniform.value;
	}
}

class Matrix4NodeUniform extends Matrix4Uniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	override public function getValue():Array<Array<Float>> {
		return this.nodeUniform.value;
	}
}

class Uniform {
	static public var FloatNodeUniform:Class<FloatNodeUniform> = FloatNodeUniform;
	static public var Vector2NodeUniform:Class<Vector2NodeUniform> = Vector2NodeUniform;
	static public var Vector3NodeUniform:Class<Vector3NodeUniform> = Vector3NodeUniform;
	static public var Vector4NodeUniform:Class<Vector4NodeUniform> = Vector4NodeUniform;
	static public var ColorNodeUniform:Class<ColorNodeUniform> = ColorNodeUniform;
	static public var Matrix3NodeUniform:Class<Matrix3NodeUniform> = Matrix3NodeUniform;
	static public var Matrix4NodeUniform:Class<Matrix4NodeUniform> = Matrix4NodeUniform;
}


**Explanation:**

* **Imports:** We import the necessary classes from the `Uniform` package.
* **Classes:** The classes are defined with the `class` keyword.
* **Constructors:** The constructors call the superclass constructor to initialize the base properties and then store the `nodeUniform` object.
* **`getValue()` Method:** The `getValue()` method overrides the superclass method and returns the value from the `nodeUniform` object.
* **`Uniform` Class:** We create a static `Uniform` class to expose the classes as static variables. This allows you to access the classes using the `Uniform` namespace, similar to the original JavaScript code.

**Usage:**


import Uniform;

// Create a FloatNodeUniform
var floatUniform = new Uniform.FloatNodeUniform({ name: "float", value: 1.0 });

// Access the value
var value = floatUniform.getValue();

// Output the value
trace(value); // Output: 1.0