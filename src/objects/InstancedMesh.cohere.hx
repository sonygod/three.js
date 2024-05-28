import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import js.Browser;

class InstancedMesh extends Mesh {

	public var instanceMatrix:InstancedBufferAttribute;
	public var instanceColor:InstancedBufferAttribute;
	public var morphTexture:DataTexture;
	public var count:Int;
	public var boundingBox:Box3;
	public var boundingSphere:Sphere;

	public function new(geometry:Geometry, material:Material, count:Int) {

		super(geometry, material);

		this.isInstancedMesh = true;

		instanceMatrix = new InstancedBufferAttribute(new Float32Array(count * 16), 16);
		instanceColor = null;
		morphTexture = null;

		this.count = count;

		boundingBox = null;
		boundingSphere = null;

		var i:Int;
		for (i = 0; i < count; i++) {

			setMatrixAt(i, Matrix3D.identity());

		}

	}

	public function computeBoundingBox():Void {

		var geometry = this.geometry;
		var count = this.count;

		if (boundingBox == null) {

			boundingBox = new Box3();

		}

		if (geometry.boundingBox == null) {

			geometry.computeBoundingBox();

		}

		boundingBox.makeEmpty();

		var instanceLocalMatrix = new Matrix3D();

		var box3 = new Box3();
		var i:Int;
		for (i = 0; i < count; i++) {

			getMatrixAt(i, instanceLocalMatrix);

			box3.copy(geometry.boundingBox).applyMatrix4(instanceLocalMatrix);

			boundingBox.union(box3);

		}

	}

	public function computeBoundingSphere():Void {

		var geometry = this.geometry;
		var count = this.count;

		if (boundingSphere == null) {

			boundingSphere = new Sphere();

		}

		if (geometry.boundingSphere == null) {

			geometry.computeBoundingSphere();

		}

		boundingSphere.makeEmpty();

		var instanceLocalMatrix = new Matrix3D();

		var sphere = new Sphere();
		var i:Int;
		for (i = 0; i < count; i++) {

			getMatrixAt(i, instanceLocalMatrix);

			sphere.copy(geometry.boundingSphere).applyMatrix4(instanceLocalMatrix);

			boundingSphere.union(sphere);

		}

	}

	override public function copy(source:InstancedMesh, recursive:Bool = true):InstancedMesh {

		super.copy(source, recursive);

		instanceMatrix.copy(source.instanceMatrix);

		if (source.morphTexture != null) morphTexture = source.morphTexture.clone() as DataTexture;
		if (source.instanceColor != null) instanceColor = source.instanceColor.clone() as InstancedBufferAttribute;

		count = source.count;

		if (source.boundingBox != null) boundingBox = source.boundingBox.clone() as Box3;
		if (source.boundingSphere != null) boundingSphere = source.boundingSphere.clone() as Sphere;

		return this;

	}

	public function getColorAt(index:Int, target:Vector3D):Vector3D {

		target.fromArray(instanceColor.array, index * 3);

		return target;

	}

	public function getMatrixAt(index:Int, target:Matrix3D):Matrix3D {

		target.fromArray(instanceMatrix.array, index * 16);

		return target;

	}

	public function getMorphAt(index:Int, target:MorphTarget):MorphTarget {

		var objectInfluences = target.morphTargetInfluences;

		var array = morphTexture.source.data.data;

		var len = objectInfluences.length + 1; // All influences + the baseInfluenceSum

		var dataIndex = index * len + 1; // Skip the baseInfluenceSum at the beginning

		var i:Int;
		for (i = 0; i < objectInfluences.length; i++) {

			objectInfluences[i] = array[dataIndex + i];

		}

		return target;

	}

	override public function raycast(raycaster:Raycaster, intersects:Array<RaycastResult>) {

		var matrixWorld = this.matrixWorld;
		var raycastTimes = count;

		var mesh = new Mesh(geometry, material);

		if (mesh.material == null) return;

		// test with bounding sphere first

		if (boundingSphere == null) computeBoundingSphere();

		var instanceIntersects:Array<RaycastResult> = [];

		var sphere = boundingSphere.clone() as Sphere;
		sphere.applyMatrix4(matrixWorld);

		if (!raycaster.ray.intersectsSphere(sphere)) return;

		// now test each instance

		var instanceLocalMatrix = new Matrix3D();
		var instanceWorldMatrix = new Matrix3D();

		var i:Int;
		for (i = 0; i < raycastTimes; i++) {

			// calculate the world matrix for each instance

			getMatrixAt(i, instanceLocalMatrix);

			instanceWorldMatrix.copy(matrixWorld).concat(instanceLocalMatrix);

			// the mesh represents this single instance

			mesh.matrixWorld = instanceWorldMatrix;

			mesh.raycast(raycaster, instanceIntersects);

			// process the result of raycast

			var j:Int;
			for (j = 0; j < instanceIntersects.length; j++) {

				var intersect = instanceIntersects[j];
				intersect.instanceId = i;
				intersect.object = this;
				intersects.push(intersect);

			}

			instanceIntersects.length = 0;

		}

	}

	public function setColorAt(index:Int, color:Vector3D):Void {

		if (instanceColor == null) {

			instanceColor = new InstancedBufferAttribute(new Float32Array(instanceMatrix.count * 3), 3);

		}

		color.toArray(instanceColor.array, index * 3);

	}

	public function setMatrixAt(index:Int, matrix:Matrix3D):Void {

		matrix.toArray(instanceMatrix.array, index * 16);

	}

	public function setMorphAt(index:Int, target:MorphTarget):Void {

		var objectInfluences = target.morphTargetInfluences;

		var len = objectInfluences.length + 1; // morphBaseInfluence + all influences

		if (morphTexture == null) {

			morphTexture = new DataTexture(new Float32Array(len * count), len, count, RedFormat, FloatType);

		}

		var array = morphTexture.source.data.data;

		var morphInfluencesSum:Float = 0;

		var i:Int;
		for (i = 0; i < objectInfluences.length; i++) {

			morphInfluencesSum += objectInfluences[i];

		}

		var morphBaseInfluence:Float = geometry.morphTargetsRelative ? 1 : 1 - morphInfluencesSum;

		var dataIndex = len * index;

		array[dataIndex] = morphBaseInfluence;

		array.set(objectInfluences, dataIndex + 1);

	}

	public function updateMorphTargets():Void {

		//

	}

	public function dispose():Void {

		dispatchEvent(new Event(Event.DISPOSE));

		if (morphTexture != null) {

			morphTexture.dispose();
			morphTexture = null;

		}

		Browser.document.removeEventListener(Event.RESIZE, onWindowResizeDispatch);

	}

}