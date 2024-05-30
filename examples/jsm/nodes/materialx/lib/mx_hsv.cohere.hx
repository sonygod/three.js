import haxe.io.Bytes;

class Math {
	public static function max(a:Float, b:Float):Float {
		return if (a > b) a else b;
	}

	public static function min(a:Float, b:Float):Float {
		return if (a < b) a else b;
	}

	public static function floor(f:Float):Float {
		return Std.int(f);
	}

	public static function trunc(f:Float):Float {
		return if (f < 0) Math.ceil(f) else Math.floor(f);
	}
}

class Vec3 {
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(x:Float, y:Float, z:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public function toBytes():Bytes {
		var bytes = new Bytes(4 * 3);
		var i32 = bytes.getData() as Array<Int>;
		i32[0] = Std.int(this.x);
		i32[1] = Std.int(this.y);
		i32[2] = Std.int(this.z);
		return bytes;
	}

	public static function fromBytes(bytes:Bytes):Vec3 {
		var i32 = bytes.getData() as Array<Int>;
		return new Vec3(i32[0], i32[1], i32[2]);
	}
}

class Mxhsvtorgb {
	public static function fromHsv(hsv:Vec3):Vec3 {
		var h = hsv.x;
		var s = hsv.y;
		var v = hsv.z;

		if (s < 0.0001) {
			return new Vec3(v, v, v);
		}

		h = (h * 6.0) % 1.0;
		var hi = Std.int(Math.floor(h));
		var f = h - Std.int(hi);
		var p = v * (1.0 - s);
		var q = v * (1.0 - s * f);
		var t = v * (1.0 - s * (1.0 - f));

		if (hi == 0) {
			return new Vec3(v, t, p);
		} else if (hi == 1) {
			return new Vec3(q, v, p);
		} else if (hi == 2) {
			return new Vec3(p, v, t);
		} else if (hi == 3) {
			return new Vec3(p, q, v);
		} else if (hi == 4) {
			return new Vec3(t, p, v);
		}

		return new Vec3(v, p, q);
	}
}

class Mxrgbtohsv {
	public static function fromRgb(c:Vec3):Vec3 {
		var r = c.x;
		var g = c.y;
		var b = c.z;
		var mincomp = Math.min(r, g, b);
		var maxcomp = Math.max(r, g, b);
		var delta = maxcomp - mincomp;
		var h = 0.0;
		var s = 0.0;
		var v = maxcomp;

		if (maxcomp > 0.0) {
			s = delta / maxcomp;
		}

		if (s <= 0.0) {
			h = 0.0;
		} else {
			if (r >= maxcomp) {
				h = (g - b) / delta;
			} else if (g >= maxcomp) {
				h = 2.0 + (b - r) / delta;
			} else {
				h = 4.0 + (r - g) / delta;
			}

			h /= 6.0;

			if (h < 0.0) {
				h += 1.0;
			}
		}

		return new Vec3(h, s, v);
	}
}

class Mxhsv {
	public static function toRgb(hsv:Vec3):Vec3 {
		return Mxhsvtorgb.fromHsv(hsv);
	}

	public static function fromRgb(rgb:Vec3):Vec3 {
		return Mxrgbtohsv.fromRgb(rgb);
	}
}