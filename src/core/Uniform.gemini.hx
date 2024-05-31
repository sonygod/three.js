class Uniform {

  public var value:Dynamic;

  public function new(value:Dynamic) {
    this.value = value;
  }

  public function clone():Uniform {
    return new Uniform(if (Reflect.hasField(this.value, "clone")) { this.value.clone() } else { this.value });
  }

}