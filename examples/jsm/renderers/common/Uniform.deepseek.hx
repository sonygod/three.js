import three.Color;
import three.Matrix3;
import three.Matrix4;
import three.Vector2;
import three.Vector3;
import three.Vector4;

class Uniform {

	var name:String;
	var value:Dynamic;
	var boundary:Int = 0;
	var itemSize:Int = 0;
	var offset:Int = 0;

	public function new(name:String, value:Dynamic = null) {
		this.name = name;
		this.value = value;
	}

	public function setValue(value:Dynamic):Void {
		this.value = value;
	}

	public function getValue():Dynamic {
		return this.value;
	}

}

class FloatUniform extends Uniform {

	public function new(name:String, value:Float = 0) {
		super(name, value);
		this.boundary = 4;
		this.itemSize = 1;
	}

}

class Vector2Uniform extends Uniform {

	public function new(name:String, value:Vector2 = new Vector2()) {
		super(name, value);
		this.boundary = 8;
		this.itemSize = 2;
	}

}

class Vector3Uniform extends Uniform {

	public function new(name:String, value:Vector3 = new Vector3()) {
		super(name, value);
		this.boundary = 16;
		this.itemSize = 3;
	}

}

class Vector4Uniform extends Uniform {

	public function new(name:String, value:Vector4 = new Vector4()) {
		super(name, value);
		this.boundary = 16;
		this.itemSize = 4;
	}

}

class ColorUniform extends Uniform {

	public function new(name:String, value:Color = new Color()) {
		super(name, value);
		this.boundary = 16;
		this.itemSize = 3;
	}

}

class Matrix3Uniform extends Uniform {

	public function new(name:String, value:Matrix3 = new Matrix3()) {
		super(name, value);
		this.boundary = 48;
		this.itemSize = 12;
	}

}

class Matrix4Uniform extends Uniform {

	public function new(name:String, value:Matrix4 = new Matrix4()) {
		super(name, value);
		this.boundary = 64;
		this.itemSize = 16;
	}

}

typedef Uniforms = {
	var FloatUniform:FloatUniform;
	var Vector2Uniform:Vector2Uniform;
	var Vector3Uniform:Vector3Uniform;
	var Vector4Uniform:Vector4Uniform;
	var ColorUniform:ColorUniform;
	var Matrix3Uniform:Matrix3Uniform;
	var Matrix4Uniform:Matrix4Uniform;
}