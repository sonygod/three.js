import three.js.examples.jsm.geometries.ConvexGeometry;
import three.js.examples.jsm.misc.ConvexObjectBreaker;
import three.js.math.Vector3;
import three.js.math.Line3;
import three.js.math.Plane;

class ConvexObjectBreaker {

  public var minSizeForBreak(default, null):Float = 1.4;
  public var smallDelta(default, null):Float = 0.0001;

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
  public var tempResultObjects:Dynamic;

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

    this.segments = [];
    const n = 30 * 30;
    for (i in 0...n) this.segments[i] = false;
  }

  public function prepareBreakableObject(object:Dynamic, mass:Float, velocity:Vector3, angularVelocity:Vector3, breakable:Bool) {
    // object is a Object3d (normally a Mesh), must have a buffer geometry, and it must be convex.
    // Its material property is propagated to its children (sub-pieces)
    // mass must be > 0

    object.userData.mass = mass;
    object.userData.velocity = velocity.clone();
    object.userData.angularVelocity = angularVelocity.clone();
    object.userData.breakable = breakable;
  }

  public function subdivideByImpact(object:Dynamic, pointOfImpact:Vector3, normal:Vector3, maxRadialIterations:Int, maxRandomIterations:Int):Array<Dynamic> {
    // ...
  }

  public function cutByPlane(object:Dynamic, plane:Plane, output:Dynamic):Int {
    // ...
  }

  public static function transformFreeVector(v:Vector3, m:Dynamic):Vector3 {
    // ...
  }

  public static function transformFreeVectorInverse(v:Vector3, m:Dynamic):Vector3 {
    // ...
  }

  public static function transformTiedVectorInverse(v:Vector3, m:Dynamic):Vector3 {
    // ...
  }

  public static function transformPlaneToLocalSpace(plane:Plane, m:Dynamic, resultPlane:Plane):Void {
    // ...
  }
}