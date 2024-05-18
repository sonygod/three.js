package three.core;

class Uniform {
    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
    }

    public function clone():Uniform {
        return new Uniform(value.clone != null ? value.clone() : value);
    }
}