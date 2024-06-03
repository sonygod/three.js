import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.core.Float32BufferAttribute;
import three.math.Color;
import three.math.Matrix4;
import three.math.Vector3;
import three.objects.LineSegments;
import three.materials.LineBasicMaterial;

class SkeletonHelper extends LineSegments {

	public var root:Dynamic;
	public var bones:Array<Dynamic>;

	public function new(object:Dynamic) {
		var bones = getBoneList(object);

		var geometry = new BufferGeometry();

		var vertices:Array<Float> = [];
		var colors:Array<Float> = [];

		var color1 = new Color(0, 0, 1);
		var color2 = new Color(0, 1, 0);

		for (i in 0...bones.length) {
			var bone = bones[i];

			if (bone.isBone && bone.parent != null && bone.parent.isBone) {
				vertices.push(0, 0, 0);
				vertices.push(0, 0, 0);
				colors.push(color1.r, color1.g, color1.b);
				colors.push(color2.r, color2.g, color2.b);
			}
		}

		geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
		geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

		var material = new LineBasicMaterial({vertexColors: true, depthTest: false, depthWrite: false, toneMapped: false, transparent: true});

		super(geometry, material);

		this.isSkeletonHelper = true;
		this.type = 'SkeletonHelper';

		this.root = object;
		this.bones = bones;

		this.matrix = object.matrixWorld;
		this.matrixAutoUpdate = false;
	}

	public function updateMatrixWorld(force:Bool = false):Void {
		var bones = this.bones;
		var geometry = this.geometry;
		var position = geometry.getAttribute('position');

		var _matrixWorldInv = new Matrix4();
		_matrixWorldInv.copy(this.root.matrixWorld).invert();

		var _vector = new Vector3();
		var _boneMatrix = new Matrix4();

		var j = 0;
		for (i in 0...bones.length) {
			var bone = bones[i];

			if (bone.parent != null && bone.parent.isBone) {
				_boneMatrix.multiplyMatrices(_matrixWorldInv, bone.matrixWorld);
				_vector.setFromMatrixPosition(_boneMatrix);
				position.setXYZ(j, _vector.x, _vector.y, _vector.z);

				_boneMatrix.multiplyMatrices(_matrixWorldInv, bone.parent.matrixWorld);
				_vector.setFromMatrixPosition(_boneMatrix);
				position.setXYZ(j + 1, _vector.x, _vector.y, _vector.z);

				j += 2;
			}
		}

		geometry.getAttribute('position').needsUpdate = true;

		super.updateMatrixWorld(force);
	}

	public function dispose():Void {
		this.geometry.dispose();
		this.material.dispose();
	}

}

function getBoneList(object:Dynamic):Array<Dynamic> {
	var boneList:Array<Dynamic> = [];

	if (object.isBone) {
		boneList.push(object);
	}

	for (i in 0...object.children.length) {
		boneList.push(getBoneList(object.children[i]));
	}

	return boneList;
}

class SkeletonHelper {
	static public var isSkeletonHelper:Bool = true;
	static public var type:String = "SkeletonHelper";
}

export class SkeletonHelper {
}