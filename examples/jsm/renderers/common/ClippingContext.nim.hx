import three.math.Matrix3;
import three.math.Plane;
import three.math.Vector4;

class ClippingContext {

	public var version(default, null):Int;
	public var globalClippingCount(default, null):Int;
	public var localClippingCount(default, null):Int;
	public var localClippingEnabled(default, null):Bool;
	public var localClipIntersection(default, null):Bool;
	public var planes(default, null):Array<Vector4>;
	public var parentVersion(default, null):Int;
	public var viewNormalMatrix(default, null):Matrix3;
	public var viewMatrix(default, null):Matrix3;

	public function new() {
		version = ++ _clippingContextVersion;
		globalClippingCount = 0;
		localClippingCount = 0;
		localClippingEnabled = false;
		localClipIntersection = false;
		planes = [];
		parentVersion = 0;
		viewNormalMatrix = new Matrix3();
	}

	public function projectPlanes(source:Array<Plane>, offset:Int) {
		var l = source.length;
		var planes = this.planes;
		for (i in 0...l) {
			_plane.copy(source[i]).applyMatrix4(this.viewMatrix, this.viewNormalMatrix);
			var v = planes[offset + i];
			var normal = _plane.normal;
			v.x = -normal.x;
			v.y = -normal.y;
			v.z = -normal.z;
			v.w = _plane.constant;
		}
	}

	public function updateGlobal(renderer, camera) {
		var rendererClippingPlanes = renderer.clippingPlanes;
		this.viewMatrix = camera.matrixWorldInverse;
		this.viewNormalMatrix.getNormalMatrix(this.viewMatrix);
		var update = false;
		if (Std.is(rendererClippingPlanes, Array) && rendererClippingPlanes.length !== 0) {
			var l = rendererClippingPlanes.length;
			if (l !== this.globalClippingCount) {
				var planes = [];
				for (i in 0...l) {
					planes.push(new Vector4());
				}
				this.globalClippingCount = l;
				this.planes = planes;
				update = true;
			}
			this.projectPlanes(rendererClippingPlanes, 0);
		} else if (this.globalClippingCount !== 0) {
			this.globalClippingCount = 0;
			this.planes = [];
			update = true;
		}
		if (renderer.localClippingEnabled !== this.localClippingEnabled) {
			this.localClippingEnabled = renderer.localClippingEnabled;
			update = true;
		}
		if (update) this.version = _clippingContextVersion++;
	}

	public function update(parent:ClippingContext, material) {
		var update = false;
		if (this !== parent && parent.version !== this.parentVersion) {
			this.globalClippingCount = material.isShadowNodeMaterial ? 0 : parent.globalClippingCount;
			this.localClippingEnabled = parent.localClippingEnabled;
			this.planes = Array.from(parent.planes);
			this.parentVersion = parent.version;
			this.viewMatrix = parent.viewMatrix;
			this.viewNormalMatrix = parent.viewNormalMatrix;
			update = true;
		}
		if (this.localClippingEnabled) {
			var localClippingPlanes = material.clippingPlanes;
			if (Std.is(localClippingPlanes, Array) && localClippingPlanes.length !== 0) {
				var l = localClippingPlanes.length;
				var planes = this.planes;
				var offset = this.globalClippingCount;
				if (update || l !== this.localClippingCount) {
					planes.length = offset + l;
					for (i in 0...l) {
						planes[offset + i] = new Vector4();
					}
					this.localClippingCount = l;
					update = true;
				}
				this.projectPlanes(localClippingPlanes, offset);
			} else if (this.localClippingCount !== 0) {
				this.localClippingCount = 0;
				update = true;
			}
			if (this.localClipIntersection !== material.clipIntersection) {
				this.localClipIntersection = material.clipIntersection;
				update = true;
			}
		}
		if (update) this.version = _clippingContextVersion++;
	}

}