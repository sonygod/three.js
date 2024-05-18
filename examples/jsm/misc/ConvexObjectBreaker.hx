import three.math.Vector3;
import three.math.Plane;
import three.math.Line3;
import three.core.Geometry;
import three.core.Mesh;
import three.geometries.ConvexGeometry;

class ConvexObjectBreaker {

	public var minSizeForBreak:Float = 1.4;
	public var smallDelta:Float = 0.0001;

	public var tempLine1:Line3;
	public var tempPlane1:Plane;
	public var tempPlane2:Plane;
	public var tempPlane_Cut:Plane;
	public var tempCM1:Vector3;
	public var tempCM2:Vector3;
	public var tempVector3:Vector3;
	public var tempVector3_2:Vector3;
	public var tempVector3_3:Vector3;
	public var tempVector3_P0:Vector3;
	public var tempVector3_P1:Vector3;
	public var tempVector3_P2:Vector3;
	public var tempVector3_N0:Vector3;
	public var tempVector3_N1:Vector3;
	public var tempVector3_AB:Vector3;
	public var tempVector3_CB:Vector3;
	public var tempResultObjects:Object;

	public var segments:Array<Bool>;

	public function new(minSizeForBreak:Float = 1.4, smallDelta:Float = 0.0001) {
		this.minSizeForBreak = minSizeForBreak;
		this.smallDelta = smallDelta;

		this.tempLine1 = new Line3();
		this.tempPlane1 = new Plane();
		this.tempPlane2 = new Plane();
		this.tempPlane_Cut = new Plane();
		this.tempCM1 = new Vector3();
		this.tempCM2 = new Vector3();
		this.tempVector3 = new Vector3();
		this.tempVector3_2 = new Vector3();
		this.tempVector3_3 = new Vector3();
		this.tempVector3_P0 = new Vector3();
		this.tempVector3_P1 = new Vector3();
		this.tempVector3_P2 = new Vector3();
		this.tempVector3_N0 = new Vector3();
		this.tempVector3_N1 = new Vector3();
		this.tempVector3_AB = new Vector3();
		this.tempVector3_CB = new Vector3();
		this.tempResultObjects = { object1: null, object2: null };

		this.segments = new Array<Bool>(30 * 30);
		for (i in 0...this.segments.length) {
			this.segments[i] = false;
		}
	}

	public function prepareBreakableObject(object:Mesh, mass:Float, velocity:Vector3, angularVelocity:Vector3, breakable:Bool) {
		// object is a Object3d (normally a Mesh), must have a buffer geometry, and it must be convex.
		// Its material property is propagated to its children (sub-pieces)
		// mass must be > 0

		var userData:Dynamic = object.userData;
		userData.mass = mass;
		userData.velocity = velocity.clone();
		userData.angularVelocity = angularVelocity.clone();
		userData.breakable = breakable;
	}

	//... (other functions remain the same)

	static public function transformPlaneToLocalSpace(plane:Plane, m:Matrix4, resultPlane:Plane) {
		resultPlane.normal.copy(plane.normal);
		resultPlane.constant = plane.constant;

		var referencePoint:Vector3 = ConvexObjectBreaker.transformTiedVectorInverse(plane.coplanarPoint(new Vector3()), m);

		ConvexObjectBreaker.transformFreeVectorInverse(resultPlane.normal, m);

		// recalculate constant (like in setFromNormalAndCoplanarPoint)
		resultPlane.constant = - referencePoint.dot(resultPlane.normal);
	}

}