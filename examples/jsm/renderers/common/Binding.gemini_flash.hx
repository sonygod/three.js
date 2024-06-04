class Binding {

	public var name:String;
	public var visibility:Int;

	public function new(name:String = "") {
		this.name = name;
		this.visibility = 0;
	}

	public function setVisibility(visibility:Int) {
		this.visibility |= visibility;
	}

	public function clone():Binding {
		return cast(new this.constructor(), this);
	}

}