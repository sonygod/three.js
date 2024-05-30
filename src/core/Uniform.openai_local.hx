package three.core;

class Uniform {

	public var value:Dynamic;

	public function new(value:Dynamic) {
		this.value = value;
	}

	public function clone():Uniform {
		return new Uniform((Reflect.hasField(value, "clone") && Reflect.isFunction(value.clone)) ? value.clone() : value);
	}
}