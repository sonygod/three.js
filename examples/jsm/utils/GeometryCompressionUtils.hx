import three.math.Vector3;
import three.math.Matrix3;
import three.math.Matrix4;
import three.core.BufferAttribute;
import three.materials.PackedPhongMaterial;

class GeometryCompressionUtils {

	public static function compressNormals(mesh:three.Mesh, encodeMethod:String):Void {
		if (!mesh.geometry) {
			trace('Mesh must contain geometry. ');
			return;
		}

		var normal = mesh.geometry.attributes.normal;

		if (!normal) {
			trace('Geometry must contain normal attribute. ');
			return;
		}

		if (normal.isPacked) return;

		if (normal.itemSize != 3) {
			trace('normal.itemSize is not 3, which cannot be encoded. ');
			return;
		}

		var array = normal.array;
		var count = normal.count;

		var result:Dynamic;
		if (encodeMethod == "DEFAULT") {

			// TODO: Add 1 byte to the result, making the encoded length to be 4 bytes.
			result = TypedArray.alloc(Int8, count * 3);

			for (var idx:Int = 0; idx < array.length; idx += 3) {
				var encoded = defaultEncode(array[idx], array[idx + 1], array[idx + 2], 1);

				result[idx + 0] = encoded[0];
				result[idx + 1] = encoded[1];
				result[idx + 2] = encoded[2];
			}

			mesh.geometry.setAttribute('normal', new BufferAttribute(result, 3, true));
			mesh.geometry.attributes.normal.bytes = result.length * 1;

		} else if (encodeMethod == "OCT1Byte") {

			result = TypedArray.alloc(Int8, count * 2);

			for (var idx:Int = 0; idx < array.length; idx += 3) {
				var encoded = octEncodeBest(array[idx], array[idx + 1], array[idx + 2], 1);

				result[idx / 3 * 2 + 0] = encoded[0];
				result[idx / 3 * 2 + 1] = encoded[1];
			}

			mesh.geometry.setAttribute('normal', new BufferAttribute(result, 2, true));
			mesh.geometry.attributes.normal.bytes = result.length * 1;

		} else if (encodeMethod == "OCT2Byte") {

			result = TypedArray.alloc(Int16, count * 2);

			for (var idx:Int = 0; idx < array.length; idx += 3) {
				var encoded = octEncodeBest(array[idx], array[idx + 1], array[idx + 2], 2);

				result[idx / 3 * 2 + 0] = encoded[0];
				result[idx / 3 * 2 + 1] = encoded[1];
			}

			mesh.geometry.setAttribute('normal', new BufferAttribute(result, 2, true));
			mesh.geometry.attributes.normal.bytes = result.length * 2;

		} else if (encodeMethod == "ANGLES") {

			result = TypedArray.alloc(Int16, count * 2);

			for (var idx:Int = 0; idx < array.length; idx += 3) {
				var encoded = anglesEncode(array[idx], array[idx + 1], array[idx + 2]);

				result[idx / 3 * 2 + 0] = encoded[0];
				result[idx / 3 * 2 + 1] = encoded[1];
			}

			mesh.geometry.setAttribute('normal', new BufferAttribute(result, 2, true));
			mesh.geometry.attributes.normal.bytes = result.length * 2;

		} else {

			trace('Unrecognized encoding method, should be `DEFAULT` or `ANGLES` or `OCT`. ');
			return;
		}

		mesh.geometry.attributes.normal.needsUpdate = true;
		mesh.geometry.attributes.normal.isPacked = true;
		mesh.geometry.attributes.normal.packingMethod = encodeMethod;

		// modify material
		if (!(mesh.material is PackedPhongMaterial)) {
			mesh.material = new PackedPhongMaterial().copy(mesh.material);
		}

		if (encodeMethod == "ANGLES") {
			mesh.material.defines.USE_PACKED_NORMAL = 0;
		}

		if (encodeMethod == "OCT1Byte") {
			mesh.material.defines.USE_PACKED_NORMAL = 1;
		}

		if (encodeMethod == "OCT2Byte") {
			mesh.material.defines.USE_PACKED_NORMAL = 1;
		}

		if (encodeMethod == "DEFAULT") {
			mesh.material.defines.USE_PACKED_NORMAL = 2;
		}
	}

	// ... other functions omitted for brevity

	private static function defaultEncode(x:Float, y:Float, z:Float, bytes:Int):Array<Int> {
		if (bytes == 1) {
			var tmpx = Math.round((x + 1) * 0.5 * 255);
			var tmpy = Math.round((y + 1) * 0.5 * 255);
			var tmpz = Math.round((z + 1) * 0.5 * 255);
			return [tmpx, tmpy, tmpz];
		} else if (bytes == 2) {
			var tmpx = Math.round((x + 1) * 0.5 * 65535);
			var tmpy = Math.round((y + 1) * 0.5 * 65535);
			var tmpz = Math.round((z + 1) * 0.5 * 65535);
			return [tmpx, tmpy, tmpz];
		} else {
			trace('number of bytes must be 1 or 2');
			return [0, 0, 0];
		}
	}

	// ... other functions omitted for brevity
}