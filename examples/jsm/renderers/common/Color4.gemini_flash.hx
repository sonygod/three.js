import three.Color;

class Color4 extends Color {

	public var a:Float;

	public function new(r:Float, g:Float, b:Float, a:Float = 1) {
		super(r, g, b);
		this.a = a;
	}

	public function set(r:Float, g:Float, b:Float, a:Float = 1):Color4 {
		this.a = a;
		return cast super.set(r, g, b);
	}

	public function copy(color:Color4):Color4 {
		if (color.a != null) this.a = color.a;
		return cast super.copy(color);
	}

	public function clone():Color4 {
		return new Color4(this.r, this.g, this.b, this.a);
	}
}