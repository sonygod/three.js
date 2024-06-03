import three.math.MathUtils;
import three.math.ColorManagement;
import three.constants.SRGBColorSpace;

class Color {
    public var r: Float = 1.0;
    public var g: Float = 1.0;
    public var b: Float = 1.0;

    public function new(r: Float = 1.0, g: Float = 1.0, b: Float = 1.0) {
        this.set(r, g, b);
    }

    public function set(r: Dynamic, g: Float = -1.0, b: Float = -1.0, colorSpace: Int = SRGBColorSpace): Color {
        if (g == -1.0 && b == -1.0) {
            if (Std.is(r, Color)) {
                this.copy(r);
            } else if (Std.is(r, Int)) {
                this.setHex(r, colorSpace);
            } else if (Std.is(r, String)) {
                this.setStyle(r, colorSpace);
            }
        } else {
            this.setRGB(r, g, b, colorSpace);
        }
        return this;
    }

    // Other methods...
}

function hue2rgb(p: Float, q: Float, t: Float): Float {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1/6) return p + (q - p) * 6 * t;
    if (t < 1/2) return q;
    if (t < 2/3) return p + (q - p) * 6 * (2/3 - t);
    return p;
}

// Other functions and constants...