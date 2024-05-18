import three.math.Box3;
import three.math.Line3;
import three.math.Plane;
import three.math.Sphere;
import three.math.Triangle;
import three.math.Vector3;
import three.math.Capsule;
import three.math.Layers;

class Octree {
	private static const _v1:Vector3 = new Vector3();
	private static const _v2:Vector3 = new Vector3();
	private static const _point1:Vector3 = new Vector3();
	private static const _point2:Vector3 = new Vector3();
	private static const _plane:Plane = new Plane();
	private static const _line1:Line3 = new Line3();
	private static const _line2:Line3 = new Line3();
	private static const _sphere:Sphere = new Sphere();
	private static const _capsule:Capsule = new Capsule();
	private static const _temp1:Vector3 = new Vector3();
	private static const _temp2:Vector3 = new Vector3();
	private static const _temp3:Vector3 = new Vector3();
	private static const EPS:Float = 1e-10;

	public var box:Box3;
	public var bounds:Box3;
	public var subTrees:Array<Octree>;
	public var triangles:Array<Triangle>;
	public var layers:Layers;

	public function new(box:Box3) {
		this.box = box;
		this.bounds = new Box3();
		this.subTrees = [];
		this.triangles = [];
		this.layers = new Layers();
	}

	public function addTriangle(triangle:Triangle):Octree {
		// ...
	}

	public function calcBox():Octree {
		// ...
	}

	public function split(level:Int):Octree {
		// ...
	}

	public function build():Octree {
		// ...
	}

	public function getRayTriangles(ray:Line3, triangles:Array<Triangle>):Array<Triangle> {
		// ...
	}

	public function triangleCapsuleIntersect(capsule:Capsule, triangle:Triangle):Dynamic {
		// ...
	}

	public function triangleSphereIntersect(sphere:Sphere, triangle:Triangle):Dynamic {
		// ...
	}

	public function getSphereTriangles(sphere:Sphere, triangles:Array<Triangle>):Array<Triangle> {
		// ...
	}

	public function getCapsuleTriangles(capsule:Capsule, triangles:Array<Triangle>):Array<Triangle> {
		// ...
	}

	public function sphereIntersect(sphere:Sphere):Dynamic {
		// ...
	}

	public function capsuleIntersect(capsule:Capsule):Dynamic {
		// ...
	}

	public function rayIntersect(ray:Line3):Dynamic {
		// ...
	}

	public function fromGraphNode(group:Dynamic):Octree {
		// ...
	}

	public function clear():Octree {
		// ...
	}
}