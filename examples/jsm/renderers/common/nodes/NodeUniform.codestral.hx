import three.js.renderers.common.Uniform;

class FloatNodeUniform extends Uniform.FloatUniform {
    public var nodeUniform: NodeUniform;

    public function new(nodeUniform: NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    @:override
    public function getValue(): Float {
        return this.nodeUniform.value;
    }
}

class Vector2NodeUniform extends Uniform.Vector2Uniform {
    public var nodeUniform: NodeUniform;

    public function new(nodeUniform: NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    @:override
    public function getValue(): Array<Float> {
        return this.nodeUniform.value;
    }
}

class Vector3NodeUniform extends Uniform.Vector3Uniform {
    public var nodeUniform: NodeUniform;

    public function new(nodeUniform: NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    @:override
    public function getValue(): Array<Float> {
        return this.nodeUniform.value;
    }
}

class Vector4NodeUniform extends Uniform.Vector4Uniform {
    public var nodeUniform: NodeUniform;

    public function new(nodeUniform: NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    @:override
    public function getValue(): Array<Float> {
        return this.nodeUniform.value;
    }
}

class ColorNodeUniform extends Uniform.ColorUniform {
    public var nodeUniform: NodeUniform;

    public function new(nodeUniform: NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    @:override
    public function getValue(): Array<Float> {
        return this.nodeUniform.value;
    }
}

class Matrix3NodeUniform extends Uniform.Matrix3Uniform {
    public var nodeUniform: NodeUniform;

    public function new(nodeUniform: NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    @:override
    public function getValue(): Array<Float> {
        return this.nodeUniform.value;
    }
}

class Matrix4NodeUniform extends Uniform.Matrix4Uniform {
    public var nodeUniform: NodeUniform;

    public function new(nodeUniform: NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    @:override
    public function getValue(): Array<Float> {
        return this.nodeUniform.value;
    }
}