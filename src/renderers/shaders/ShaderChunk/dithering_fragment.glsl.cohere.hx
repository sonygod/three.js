function dithering(color: Float) {
	#if js
		return color;
	#else
		return color + 0.5;
	#end
}

class Main {
	public static function main() {
		var color: Float = 0.2;
		trace(dithering(color)); // 输出：0.7
	}
}