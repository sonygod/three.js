import {
	FloatUniform, Vector2Uniform, Vector3Uniform, Vector4Uniform,
	ColorUniform, Matrix3Uniform, Matrix4Uniform
} from '../Uniform.hx';

class FloatNodeUniform extends FloatUniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {

		super(nodeUniform.name, nodeUniform.value);

		this.nodeUniform = nodeUniform;

	}

	public function getValue():Float {

		return cast(nodeUniform.value, Float);

	}

}

class Vector2NodeUniform extends Vector2Uniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {

		super(nodeUniform.name, nodeUniform.value);

		this.nodeUniform = nodeUniform;

	}

	public function getValue():haxe.math.Vector2Default {

		return cast(nodeUniform.value, haxe.math.Vector2Default);

	}

}

class Vector3NodeUniform extends Vector3Uniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {

		super(nodeUniform.name, nodeUniform.value);

		this.nodeUniform = nodeUniform;

	}

	public function getValue():haxe.math.Vector3Default {

		return cast(nodeUniform.value, haxe.math.Vector3Default);

	}

}

class Vector4NodeUniform extends Vector4Uniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {

		super(nodeUniform.name, nodeUniform.value);

		this.nodeUniform = nodeUniform;

	}

	public function getValue():haxe.math.Vector4Default {

		return cast(nodeUniform.value, haxe.math.Vector4Default);

	}

}

class ColorNodeUniform extends ColorUniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {

		super(nodeUniform.name, nodeUniform.value);

		this.nodeUniform = nodeUniform;

	}

	public function getValue():haxe.math.Vector4Default {

		return cast(nodeUniform.value, haxe.math.Vector4Default);

	}

}

class Matrix3NodeUniform extends Matrix3Uniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {

		super(nodeUniform.name, nodeUniform.value);

		this.nodeUniform = nodeUniform;

	}

	public function getValue():haxe.math.Matrix3Default {

		return cast(nodeUniform.value, haxe.math.Matrix3Default);

	}

}

class Matrix4NodeUniform extends Matrix4Uniform {

	public var nodeUniform:Dynamic;

	public function new(nodeUniform:Dynamic) {

		super(nodeUniform.name, nodeUniform.value);

		this.nodeUniform = nodeUniform;

	}

	public function getValue():haxe.math.Matrix4Default {

		return cast(nodeUniform.value, haxe.math.Matrix4Default);

	}

}

export {
	FloatNodeUniform, Vector2NodeUniform, Vector3NodeUniform, Vector4NodeUniform,
	ColorNodeUniform, Matrix3NodeUniform, Matrix4NodeUniform
};