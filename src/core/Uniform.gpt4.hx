package three.core;

class Uniform {

	public var value:Dynamic;

	public function new(value:Dynamic) {
		this.value = value;
	}

	public function clone():Uniform {
		var clonedValue = (Reflect.hasField(this.value, "clone") && Reflect.field(this.value, "clone") != null) ? Reflect.callMethod(this.value, Reflect.field(this.value, "clone"), []) : this.value;
		return new Uniform(clonedValue);
	}

}