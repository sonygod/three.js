class Uniform {
	public var value:Dynamic;

	public function new(value:Dynamic) {
		this.value = value;
	}

	public function clone():Uniform {
		return new Uniform(Reflect.hasField(this.value, 'clone') ? Reflect.field(this.value, 'clone')() : this.value);
	}
}