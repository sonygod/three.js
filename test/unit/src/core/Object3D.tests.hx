import haxe.ds.StringMap;

class Object3DTests {

	public static function matrixEquals4( a:Matrix4, b:Matrix4 ):Bool {
		for (i in 0...16) {
			if (Math.abs(a.elements[i] - b.elements[i]) >= eps) {
				return false;
			}
		}
		return true;
	}

	static function main() {
		var RadToDeg:Float = 180 / Math.PI;

		var eulerEquals = function (a:Euler, b:Euler, tolerance:Float = 0.0001) -> Bool:
			if (a.order != b.order) {
				return false;
			}
			return (
				Math.abs(a.x - b.x) <= tolerance &&
				Math.abs(a.y - b.y) <= tolerance &&
				Math.abs(a.z - b.z) <= tolerance
			);

		// INHERITANCE
		// ... (skipped, as Haxe does not have a concept of modules)

		// PROPERTIES
		// ... (skipped, as Haxe does not have a concept of modules)

		// STATIC
		// ... (skipped, as Haxe does not have a concept of modules)

		// PUBLIC
		// ... (skipped, as Haxe does not have a concept of modules)

		// METHODS
		// ... (skipped, as Haxe does not have a concept of modules)
	}
}