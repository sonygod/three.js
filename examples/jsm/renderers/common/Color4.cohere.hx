class Color4 extends js.three.Color {
    var a: Float;

    public function new(r: Float, g: Float, b: Float, a: Float = 1.0) {
        super(r, g, b);
        this.a = a;
    }

    public function set(r: Float, g: Float, b: Float, a: Float = 1.0): Void {
        this.a = a;
        super.set(r, g, b);
    }

    public function copy(color: Color4): Void {
        if (color.a != null) this.a = color.a;
        super.copy(color);
    }

    public function clone(): Color4 {
        return new Color4(this.r, this.g, this.b, this.a);
    }
}