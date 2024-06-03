import haxe.ui.Entity;
import haxe.ui.geom.Matrix4;
import haxe.ui.geom.Ray;
import haxe.ui.geom.Sphere;
import haxe.ui.geom.Vector3;
import haxe.ui.material.PointsMaterial;
import haxe.ui.mesh.BufferGeometry;

class Points extends Entity {
	public var isPoints:Bool = true;
	public var type(default, null):String = "Points";
	public var geometry(default, null):BufferGeometry;
	public var material(default, null):PointsMaterial;
	public var morphTargetInfluences:Array<Float>;
	public var morphTargetDictionary:Map<String, Int>;

	public function new(geometry:BufferGeometry = new BufferGeometry(), material:PointsMaterial = new PointsMaterial()) {
		super();
		this.geometry = geometry;
		this.material = material;
		this.updateMorphTargets();
	}

	public function copy(source:Points, recursive:Bool):Points {
		super.copy(source, recursive);
		this.material = source.material;
		this.geometry = source.geometry;
		return this;
	}

	public function raycast(raycaster:Raycaster, intersects:Array<RaycastInfo>):Void {
		var geometry = this.geometry;
		var matrixWorld = this.matrixWorld;
		var threshold = raycaster.params.Points.threshold;
		var drawRange = geometry.drawRange;

		// Checking boundingSphere distance to ray
		if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

		var _sphere = new Sphere();
		_sphere.copy(geometry.boundingSphere);
		_sphere.applyMatrix4(matrixWorld);
		_sphere.radius += threshold;

		if (!raycaster.ray.intersectsSphere(_sphere)) return;

		//
		var _inverseMatrix = new Matrix4();
		_inverseMatrix.copy(matrixWorld).invert();
		var _ray = new Ray();
		_ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);

		var localThreshold = threshold / ((this.scale.x + this.scale.y + this.scale.z) / 3);
		var localThresholdSq = localThreshold * localThreshold;

		var index = geometry.index;
		var attributes = geometry.attributes;
		var positionAttribute = attributes.position;

		if (index != null) {
			var start = Math.max(0, drawRange.start);
			var end = Math.min(index.count, (drawRange.start + drawRange.count));

			for (var i = start; i < end; i++) {
				var a = index.getX(i);
				var _position = new Vector3();
				_position.fromBufferAttribute(positionAttribute, a);
				testPoint(_position, a, localThresholdSq, matrixWorld, raycaster, intersects, this);
			}
		} else {
			var start = Math.max(0, drawRange.start);
			var end = Math.min(positionAttribute.count, (drawRange.start + drawRange.count));

			for (var i = start; i < end; i++) {
				var _position = new Vector3();
				_position.fromBufferAttribute(positionAttribute, i);
				testPoint(_position, i, localThresholdSq, matrixWorld, raycaster, intersects, this);
			}
		}
	}

	public function updateMorphTargets():Void {
		var geometry = this.geometry;
		var morphAttributes = geometry.morphAttributes;
		var keys = Reflect.fields(morphAttributes);
		if (keys.length > 0) {
			var morphAttribute = morphAttributes[keys[0]];
			if (morphAttribute != null) {
				this.morphTargetInfluences = new Array<Float>();
				this.morphTargetDictionary = new Map<String, Int>();
				for (var m = 0; m < morphAttribute.length; m++) {
					var name = morphAttribute[m].name == null ? String(m) : morphAttribute[m].name;
					this.morphTargetInfluences.push(0);
					this.morphTargetDictionary.set(name, m);
				}
			}
		}
	}
}

function testPoint(point:Vector3, index:Int, localThresholdSq:Float, matrixWorld:Matrix4, raycaster:Raycaster, intersects:Array<RaycastInfo>, object:Points):Void {
	var _ray = new Ray();
	_ray.copy(raycaster.ray);
	var rayPointDistanceSq = _ray.distanceSqToPoint(point);
	if (rayPointDistanceSq < localThresholdSq) {
		var intersectPoint = new Vector3();
		_ray.closestPointToPoint(point, intersectPoint);
		intersectPoint.applyMatrix4(matrixWorld);
		var distance = raycaster.ray.origin.distanceTo(intersectPoint);
		if (distance < raycaster.near || distance > raycaster.far) return;
		intersects.push({
			distance: distance,
			distanceToRay: Math.sqrt(rayPointDistanceSq),
			point: intersectPoint,
			index: index,
			face: null,
			object: object
		});
	}
}

typedef RaycastInfo = {
	var distance:Float;
	var distanceToRay:Float;
	var point:Vector3;
	var index:Int;
	var face:Dynamic;
	var object:Points;
};

typedef Raycaster = {
	var ray:Ray;
	var near:Float;
	var far:Float;
	var params:{
		Points:{
			threshold:Float
		}
	}
};