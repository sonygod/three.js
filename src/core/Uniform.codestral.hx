class Uniform {
    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
    }

    public function clone():Uniform {
        return new Uniform(Std.is(this.value, 'clone') ? this.value.clone() : this.value);
    }
}