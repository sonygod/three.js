import three.js.examples.jsm.renderers.common.nodes.Uniform;

class FloatNodeUniform extends Uniform.FloatUniform {

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Float {
		return this.nodeUniform.value;
	}

}

class Vector2NodeUniform extends Uniform.Vector2Uniform {

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Vector2 {
		return this.nodeUniform.value;
	}

}

class Vector3NodeUniform extends Uniform.Vector3Uniform {

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Vector3 {
		return this.nodeUniform.value;
	}

}

class Vector4NodeUniform extends Uniform.Vector4Uniform {

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Vector4 {
		return this.nodeUniform.value;
	}

}

class ColorNodeUniform extends Uniform.ColorUniform {

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Color {
		return this.nodeUniform.value;
	}

}

class Matrix3NodeUniform extends Uniform.Matrix3Uniform {

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Matrix3 {
		return this.nodeUniform.value;
	}

}

class Matrix4NodeUniform extends Uniform.Matrix4Uniform {

	public function new(nodeUniform:Dynamic) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Matrix4 {
		return this.nodeUniform.value;
	}

}

typedef NodeUniform = {
	var name:String;
	var value:Dynamic;
}