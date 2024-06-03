import three.Matrix4;
import three.Quaternion;
import three.Vector3;
import mmd.MMDParser;

class MMDExporter {

	/**
	 * Dependencies
	 *  - mmd-parser https://github.com/takahirox/mmd-parser
	 */

	/* TODO: implement
	// mesh -> pmd
	public function parsePmd(object:Dynamic):Dynamic {

	}
	*/

	/* TODO: implement
	// mesh -> pmx
	public function parsePmx(object:Dynamic):Dynamic {

	}
	*/

	/* TODO: implement
	// animation + skeleton -> vmd
	public function parseVmd(object:Dynamic):Dynamic {

	}
	*/

	/**
	 * skeleton -> vpd
	 * Returns Shift_JIS encoded Uint8Array. Otherwise return strings.
	 */
	public function parseVpd(skin:Dynamic, outputShiftJis:Bool, useOriginalBones:Bool):Dynamic {

		if (!Reflect.hasField(skin, "isSkinnedMesh") || skin.isSkinnedMesh != true) {

			Sys.warning("THREE.MMDExporter: parseVpd() requires SkinnedMesh instance.");
			return null;

		}

		function toStringsFromNumber(num:Float):String {

			if (Math.abs(num) < 1e-6) num = 0;

			var a = num.toString();

			if (a.indexOf(".") == - 1) {

				a += ".";

			}

			a += "000000";

			var index = a.indexOf(".");

			var d = a.slice(0, index);
			var p = a.slice(index + 1, index + 7);

			return d + "." + p;

		}

		function toStringsFromArray(array:Array<Float>):String {

			var a = new Array<String>();

			for (i in 0...array.length) {

				a.push(toStringsFromNumber(array[i]));

			}

			return a.join(",");

		}

		skin.updateMatrixWorld(true);

		var bones = skin.skeleton.bones;
		var bones2 = getBindBones(skin);

		var position = new Vector3();
		var quaternion = new Quaternion();
		var quaternion2 = new Quaternion();
		var matrix = new Matrix4();

		var array = new Array<String>();
		array.push("Vocaloid Pose Data file");
		array.push("");
		array.push((skin.name != "" ? skin.name.replace(new EReg("\\s", "g"), "_") : "skin") + ".osm;");
		array.push(bones.length + ";");
		array.push("");

		for (i in 0...bones.length) {

			var bone = bones[i];
			var bone2 = bones2[i];

			/*
			 * use the bone matrix saved before solving IK.
			 * see CCDIKSolver for the detail.
			 */
			if (useOriginalBones &&
				Reflect.hasField(bone.userData, "ik") &&
				Reflect.hasField(bone.userData.ik, "originalMatrix")
			) {

				matrix.fromArray(bone.userData.ik.originalMatrix);

			} else {

				matrix.copy(bone.matrix);

			}

			position.setFromMatrixPosition(matrix);
			quaternion.setFromRotationMatrix(matrix);

			var pArray = position.sub(bone2.position).toArray();
			var qArray = quaternion2.copy(bone2.quaternion).conjugate().multiply(quaternion).toArray();

			// right to left
			pArray[2] = - pArray[2];
			qArray[0] = - qArray[0];
			qArray[1] = - qArray[1];

			array.push("Bone" + i + "{" + bone.name);
			array.push("  " + toStringsFromArray(pArray) + ";");
			array.push("  " + toStringsFromArray(qArray) + ";");
			array.push("}");
			array.push("");

		}

		array.push("");

		var lines = array.join("\n");

		return (outputShiftJis) ? unicodeToShiftjis(lines) : lines;

	}

}

// Unicode to Shift_JIS table
var u2sTable:Dynamic;

function unicodeToShiftjis(str:String):Uint8Array {

	if (u2sTable == null) {

		var encoder = new MMDParser.CharsetEncoder();
		var table = encoder.s2uTable;
		u2sTable = {};

		var keys = Reflect.field(table);

		for (i in 0...keys.length) {

			var key = keys[i];

			var value = table[key];
			key = Std.parseInt(key);

			u2sTable[value] = key;

		}

	}

	var array = new Array<Int>();

	for (i in 0...str.length) {

		var code = str.charCodeAt(i);

		var value = u2sTable[code];

		if (value == null) {

			throw new Error("cannot convert charcode 0x" + code.toString(16));

		} else if (value > 0xff) {

			array.push((value >> 8) & 0xff);
			array.push(value & 0xff);

		} else {

			array.push(value & 0xff);

		}

	}

	return new Uint8Array(array);

}

function getBindBones(skin:Dynamic):Array<Dynamic> {

	// any more efficient ways?
	var poseSkin = skin.clone();
	poseSkin.pose();
	return poseSkin.skeleton.bones;

}