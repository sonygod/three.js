class Uniform {
    public var name: String;
    public var value: Dynamic;
    public var boundary: Int;
    public var itemSize: Int;
    public var offset: Int;

    public function new(name: String, value: Dynamic = null) {
        this.name = name;
        this.value = value;
        this.boundary = 0;
        this.itemSize = 0;
    }

    public function setValue(value: Dynamic) {
        this.value = value;
    }

    public function getValue(): Dynamic {
        return value;
    }
}

class FloatUniform extends Uniform {
    public var isFloatUniform: Bool;

    public function new(name: String, value: Float = 0.) {
        super(name, value);
        isFloatUniform = true;
        boundary = 4;
        itemSize = 1;
    }
}

class Vector2Uniform extends Uniform {
    public var isVector2Uniform: Bool;

    public function new(name: String, value: { x: Float, y: Float } = { x: 0., y: 0. }) {
        super(name, value);
        isVector2Uniform = true;
        boundary = 8;
        itemSize = 2;
    }
}

class Vector3Uniform extends Uniform {
    public var isVector3Uniform: Bool;

    public function new(name: String, value: { x: Float, y: Float, z: Float } = { x: 0., y: 0., z: 0. }) {
        super(name, value);
        isVector3Uniform = true;
        boundary = 16;
        itemSize = 3;
    }
}

class Vector4Uniform extends Uniform {
    public var isVector4Uniform: Bool;

    public function new(name: String, value: { x: Float, y: Float, z: Float, w: Float } = { x: 0., y: 0., z: 0., w: 0. }) {
        super(name, value);
        isVector4Uniform = true;
        boundary = 16;
        itemSize = 4;
    }
}

class ColorUniform extends Uniform {
    public var isColorUniform: Bool;

    public function new(name: String, value: { r: Float, g: Float, b: Float } = { r: 0., g: 0., b: 0. }) {
        super(name, value);
        isColorUniform = true;
        boundary = 16;
        itemSize = 3;
    }
}

class Matrix3Uniform extends Uniform {
    public var isMatrix3Uniform: Bool;

    public function new(name: String, value: { elements: Array<Float> } = { elements: [1., 0., 0., 0., 1., 0., 0., 0., 1.] }) {
        super(name, value);
        isMatrix3Uniform = true;
        boundary = 48;
        itemSize = 12;
    }
}

class Matrix4Uniform extends Uniform {
    public var isMatrix4Uniform: Bool;

    public function new(name: String, value: { elements: Array<Float> } = { elements: [1., 0., 0., 0., 1., 0., 0., 0., 1., 0., 0., 0., 1., 0., 0., 0.] }) {
        super(name, value);
        isMatrix4Uniform = true;
        boundary = 64;
        itemSize = 16;
    }
}

class Exports {
    static public function FloatUniform() {
        return FloatUniform;
    }

    static public function Vector2Uniform() {
        return Vector2Uniform;
    }

    static public function Vector3Uniform() {
        return Vector3Uniform;
    }

    static public function Vector4Uniform() {
        return Vector4Uniform;
    }

    static public function ColorUniform() {
        return ColorUniform;
    }

    static public function Matrix3Uniform() {
        return Matrix3Uniform;
    }

    static public function Matrix4Uniform() {
        return Matrix4Uniform;
    }
}