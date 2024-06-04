import three.math.Matrix3;
import three.math.Plane;
import three.math.Vector4;

class ClippingContext {

	static var _clippingContextVersion:Int = 0;
	static var _plane:Plane = new Plane();

	public var version:Int;
	public var globalClippingCount:Int;
	public var localClippingCount:Int;
	public var localClippingEnabled:Bool;
	public var localClipIntersection:Bool;
	public var planes:Array<Vector4>;
	public var parentVersion:Int;
	public var viewNormalMatrix:Matrix3;
	public var viewMatrix:Matrix4;

	public function new() {
		this.version = ++ClippingContext._clippingContextVersion;

		this.globalClippingCount = 0;

		this.localClippingCount = 0;
		this.localClippingEnabled = false;
		this.localClipIntersection = false;

		this.planes = [];

		this.parentVersion = 0;
		this.viewNormalMatrix = new Matrix3();
	}

	public function projectPlanes(source:Array<Plane>, offset:Int) {
		for (i in 0...source.length) {
			_plane.copy(source[i]).applyMatrix4(viewMatrix, viewNormalMatrix);

			var v = planes[offset + i];
			var normal = _plane.normal;

			v.x = -normal.x;
			v.y = -normal.y;
			v.z = -normal.z;
			v.w = _plane.constant;
		}
	}

	public function updateGlobal(renderer:Dynamic, camera:Dynamic) {
		var rendererClippingPlanes = renderer.clippingPlanes;
		this.viewMatrix = camera.matrixWorldInverse;

		this.viewNormalMatrix.getNormalMatrix(this.viewMatrix);

		var update = false;

		if (Std.is(rendererClippingPlanes, Array) && rendererClippingPlanes.length != 0) {
			var l = rendererClippingPlanes.length;

			if (l != this.globalClippingCount) {
				var planes:Array<Vector4> = [];
				for (i in 0...l) {
					planes.push(new Vector4());
				}

				this.globalClippingCount = l;
				this.planes = planes;
				update = true;
			}

			this.projectPlanes(rendererClippingPlanes, 0);
		} else if (this.globalClippingCount != 0) {
			this.globalClippingCount = 0;
			this.planes = [];
			update = true;
		}

		if (renderer.localClippingEnabled != this.localClippingEnabled) {
			this.localClippingEnabled = renderer.localClippingEnabled;
			update = true;
		}

		if (update) this.version = ++ClippingContext._clippingContextVersion;
	}

	public function update(parent:ClippingContext, material:Dynamic) {
		var update = false;

		if (this != parent && parent.version != this.parentVersion) {
			this.globalClippingCount = if (material.isShadowNodeMaterial) 0 else parent.globalClippingCount;
			this.localClippingEnabled = parent.localClippingEnabled;
			this.planes = parent.planes.copy();
			this.parentVersion = parent.version;
			this.viewMatrix = parent.viewMatrix;
			this.viewNormalMatrix = parent.viewNormalMatrix;

			update = true;
		}

		if (this.localClippingEnabled) {
			var localClippingPlanes = material.clippingPlanes;

			if (Std.is(localClippingPlanes, Array) && localClippingPlanes.length != 0) {
				var l = localClippingPlanes.length;
				var planes = this.planes;
				var offset = this.globalClippingCount;

				if (update || l != this.localClippingCount) {
					planes.length = offset + l;

					for (i in 0...l) {
						planes[offset + i] = new Vector4();
					}

					this.localClippingCount = l;
					update = true;
				}

				this.projectPlanes(localClippingPlanes, offset);
			} else if (this.localClippingCount != 0) {
				this.localClippingCount = 0;
				update = true;
			}

			if (this.localClipIntersection != material.clipIntersection) {
				this.localClipIntersection = material.clipIntersection;
				update = true;
			}
		}

		if (update) this.version = ++ClippingContext._clippingContextVersion;
	}

}