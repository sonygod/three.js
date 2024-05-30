package three.js.examples.jsm.renderers.common.nodes;

import Uniform.*;

class FloatNodeUniform extends FloatUniform {
    public var nodeUniform:NodeUniform;

    public function new(nodeUniform:NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    override public function getValue():Float {
        return nodeUniform.value;
    }
}

class Vector2NodeUniform extends Vector2Uniform {
    public var nodeUniform:NodeUniform;

    public function new(nodeUniform:NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    override public function getValue():Vector2 {
        return nodeUniform.value;
    }
}

class Vector3NodeUniform extends Vector3Uniform {
    public var nodeUniform:NodeUniform;

    public function new(nodeUniform:NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    override public function getValue():Vector3 {
        return nodeUniform.value;
    }
}

class Vector4NodeUniform extends Vector4Uniform {
    public var nodeUniform:NodeUniform;

    public function new(nodeUniform:NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    override public function getValue():Vector4 {
        return nodeUniform.value;
    }
}

class ColorNodeUniform extends ColorUniform {
    public var nodeUniform:NodeUniform;

    public function new(nodeUniform:NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    override public function getValue():Color {
        return nodeUniform.value;
    }
}

class Matrix3NodeUniform extends Matrix3Uniform {
    public var nodeUniform:NodeUniform;

    public function new(nodeUniform:NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    override public function getValue():Matrix3 {
        return nodeUniform.value;
    }
}

class Matrix4NodeUniform extends Matrix4Uniform {
    public var nodeUniform:NodeUniform;

    public function new(nodeUniform:NodeUniform) {
        super(nodeUniform.name, nodeUniform.value);
        this.nodeUniform = nodeUniform;
    }

    override public function getValue():Matrix4 {
        return nodeUniform.value;
    }
}