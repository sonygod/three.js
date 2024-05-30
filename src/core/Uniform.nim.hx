class Uniform {
    public var value;

    public function new(value:Dynamic) {
        this.value = value;
    }

    public function clone():Uniform {
        return new Uniform(Reflect.hasField(this.value, 'clone') ? Reflect.callMethod(this.value, 'clone', []) : this.value);
    }
}