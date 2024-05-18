import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.utils.BufferGeometryUtils;

class SimplifyModifier {

	private static function pushIfUnique<T>(array:Array<T>, object:T):Void {
		if (array.indexOf(object) === -1) array.push(object);
	}

	private static function removeFromArray<T>(array:Array<T>, object:T):Void {
		const k = array.indexOf(object);
		if (k > -1) array.splice(k, 1);
	}

	public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {
		// ... (same as JavaScript code)
	}

	// ... (other functions from the JavaScript code)

}

// ... (class Triangle and class Vertex from the JavaScript code)