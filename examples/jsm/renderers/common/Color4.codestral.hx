import three.Color;

class Color4 extends Color {

    public function new(r: Float, g: Float, b: Float, a: Float = 1) {
        super(r, g, b);
        this.a = a;
    }

    public function set(r: Float, g: Float, b: Float, a: Float = 1): Color {
        this.a = a;
        return super.set(r, g, b);
    }

    public function copy(color: Color): Color {
        if (Std.is(color, Color4) && color.a != null) this.a = color.a;
        return super.copy(color);
    }

    public function clone(): Color4 {
        return new Color4(this.r, this.g, this.b, this.a);
    }
}