class Uniform {

    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
    }

    public function clone():Uniform {
        return new Uniform(this.value.clone === undefined ? this.value : this.value.clone());
    }

}