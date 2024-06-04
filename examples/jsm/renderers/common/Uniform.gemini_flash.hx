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
  public var isFloatUniform:Bool;

  public function new(name:String, value:Float = 0) {
    super(name, value);
    this.isFloatUniform = true;
    this.boundary = 4;
    this.itemSize = 1;
  }
}

class Vector2Uniform extends Uniform {
  public var isVector2Uniform:Bool;

  public function new(name:String, value:Vector2 = new Vector2()) {
    super(name, value);
    this.isVector2Uniform = true;
    this.boundary = 8;
    this.itemSize = 2;
  }
}

class Vector3Uniform extends Uniform {
  public var isVector3Uniform:Bool;

  public function new(name:String, value:Vector3 = new Vector3()) {
    super(name, value);
    this.isVector3Uniform = true;
    this.boundary = 16;
    this.itemSize = 3;
  }
}

class Vector4Uniform extends Uniform {
  public var isVector4Uniform:Bool;

  public function new(name:String, value:Vector4 = new Vector4()) {
    super(name, value);
    this.isVector4Uniform = true;
    this.boundary = 16;
    this.itemSize = 4;
  }
}

class ColorUniform extends Uniform {
  public var isColorUniform:Bool;

  public function new(name:String, value:Color = new Color()) {
    super(name, value);
    this.isColorUniform = true;
    this.boundary = 16;
    this.itemSize = 3;
  }
}

class Matrix3Uniform extends Uniform {
  public var isMatrix3Uniform:Bool;

  public function new(name:String, value:Matrix3 = new Matrix3()) {
    super(name, value);
    this.isMatrix3Uniform = true;
    this.boundary = 48;
    this.itemSize = 12;
  }
}

class Matrix4Uniform extends Uniform {
  public var isMatrix4Uniform:Bool;

  public function new(name:String, value:Matrix4 = new Matrix4()) {
    super(name, value);
    this.isMatrix4Uniform = true;
    this.boundary = 64;
    this.itemSize = 16;
  }
}

class WebGPUUniformsGroup {
  // ... (implementation of WebGPUUniformsGroup)
}

class WebGPURenderer {
  // ... (implementation of WebGPURenderer)
}

class WebGPUShaderMaterial {
  // ... (implementation of WebGPUShaderMaterial)
}

class WebGPUShader {
  // ... (implementation of WebGPUShader)
}

// ... (other classes and functions)