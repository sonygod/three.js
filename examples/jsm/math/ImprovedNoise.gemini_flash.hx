// https://cs.nyu.edu/~perlin/noise/

class ImprovedNoise {

	static var _p:Array<Int> = [151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,
		23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,
		174,20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,
		133,230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,
		89,18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,
		202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,119,
		248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,
		178,185,112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,
		14,239,107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,
		93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180];

	static function init() {
		for (i in 0...256) {
			_p[256 + i] = _p[i];
		}
	}

	static function fade(t:Float):Float {
		return t * t * t * (t * (t * 6 - 15) + 10);
	}

	static function lerp(t:Float, a:Float, b:Float):Float {
		return a + t * (b - a);
	}

	static function grad(hash:Int, x:Float, y:Float, z:Float):Float {
		var h = hash & 15;
		var u = if (h < 8) x else y;
		var v = if (h < 4) y else if (h == 12 || h == 14) x else z;
		return (if ((h & 1) == 0) u else -u) + (if ((h & 2) == 0) v else -v);
	}

	public function new() {
		init();
	}

	public function noise(x:Float, y:Float, z:Float):Float {
		var floorX = Math.floor(x);
		var floorY = Math.floor(y);
		var floorZ = Math.floor(z);

		var X = floorX & 255;
		var Y = floorY & 255;
		var Z = floorZ & 255;

		x -= floorX;
		y -= floorY;
		z -= floorZ;

		var xMinus1 = x - 1;
		var yMinus1 = y - 1;
		var zMinus1 = z - 1;

		var u = fade(x);
		var v = fade(y);
		var w = fade(z);

		var A = _p[X] + Y;
		var AA = _p[A] + Z;
		var AB = _p[A + 1] + Z;
		var B = _p[X + 1] + Y;
		var BA = _p[B] + Z;
		var BB = _p[B + 1] + Z;

		return lerp(w, lerp(v, lerp(u, grad(_p[AA], x, y, z),
			grad(_p[BA], xMinus1, y, z)),
		lerp(u, grad(_p[AB], x, yMinus1, z),
			grad(_p[BB], xMinus1, yMinus1, z))),
		lerp(v, lerp(u, grad(_p[AA + 1], x, y, zMinus1),
			grad(_p[BA + 1], xMinus1, y, zMinus1)),
		lerp(u, grad(_p[AB + 1], x, yMinus1, zMinus1),
			grad(_p[BB + 1], xMinus1, yMinus1, zMinus1))));

	}

}