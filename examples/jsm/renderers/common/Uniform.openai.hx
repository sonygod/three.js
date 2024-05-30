package three.js.examples.jm.renderers.common;

import three.Color;
import three.Matrix3;
import three.Matrix4;
import three.Vector2;
import three.Vector3;
import three.Vector4;

class Uniform {
    public var name:String;
    public var value:Dynamic;
    public var boundary:Int;
    public var itemSize:Int;
    public var offset:Int;

    public function new(name:String, value:Dynamic = null) {
        this.name = name;
        this.value = value;
        this.boundary = 0;
        this.itemSize = 0;
        this.offset = 0;
    }

    public function setValue(value:Dynamic):Void {
        this.value = value;
    }

    public function getValue():Dynamic {
        return this.value;
    }
}

class FloatUniform extends Uniform {
    public var isFloatUniform:Bool = true;

    public function new(name:String, value:Float = 0) {
        super(name, value);
        this.boundary = 4;
        this.itemSize = 1;
    }
}

class Vector2Uniform extends Uniform {
    public var isVector2Uniform:Bool = true;

    public function new(name:String, value:Vector2 = null) {
        super(name, value != null ? value : new Vector2());
        this.boundary = 8;
        this.itemSize = 2;
    }
}

class Vector3Uniform extends Uniform {
    public var isVector3Uniform:Bool = true;

    public function new(name:String, value:Vector3 = null) {
        super(name, value != null ? value : new Vector3());
        this.boundary = 16;
        this.itemSize = 3;
    }
}

class Vector4Uniform extends Uniform {
    public var isVector4Uniform:Bool = true;

    public function new(name:String, value:Vector4 = null) {
        super(name, value != null ? value : new Vector4());
        this.boundary = 16;
        this.itemSize = 4;
    }
}

class ColorUniform extends Uniform {
    public var isColorUniform:Bool = true;

    public function new(name:String, value:Color = null) {
        super(name, value != null ? value : new Color());
        this.boundary = 16;
        this.itemSize = 3;
    }
}

class Matrix3Uniform extends Uniform {
    public var isMatrix3Uniform:Bool = true;

    public function new(name:String, value:Matrix3 = null) {
        super(name, value != null ? value : new Matrix3());
        this.boundary = 48;
        this.itemSize = 12;
    }
}

class Matrix4Uniform extends Uniform {
    public var isMatrix4Uniform:Bool = true;

    public function new(name:String, value:Matrix4 = null) {
        super(name, value != null ? value : new Matrix4());
        this.boundary = 64;
        this.itemSize = 16;
    }
}