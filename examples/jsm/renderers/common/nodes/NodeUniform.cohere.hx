import js.Node;

class FloatNodeUniform extends FloatUniform {
	var nodeUniform:Node;

	public function new(nodeUniform:Node) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Float {
		return nodeUniform.value;
	}
}

class Vector2NodeUniform extends Vector2Uniform {
	var nodeUniform:Node;

	public function new(nodeUniform:Node) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Float {
		return nodeUniform.value;
	}
}

class Vector3NodeUniform extends Vector3Uniform {
	var nodeUniform:Node;

	public function new(nodeUniform:Node) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Float {
		return nodeUniform.value;
	}
}

class Vector4NodeUniform extends Vector4Uniform {
	var nodeUniform:Node;

	public function new(nodeUniform:Node) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Float {
		return nodeUniform.value;
	}
}

class ColorNodeUniform extends ColorUniform {
	var nodeUniform:Node;

	public function new(nodeUniform:Node) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Float {
		return nodeUniform.value;
	}
}

class Matrix3NodeUniform extends Matrix3Uniform {
	var nodeUniform:Node;

	public function new(nodeUniform:Node) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Float {
		return nodeUniform.value;
	}
}

class Matrix4NodeUniform extends Matrix4Uniform {
	var nodeUniform:Node;

	public function new(nodeUniform:Node) {
		super(nodeUniform.name, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function getValue():Float {
		return nodeUniform.value;
	}
}