import three.cameras.Camera;
import three.math.MathUtils;
import three.math.Vector2;
import three.math.Vector3;

class PerspectiveCamera extends Camera {
	public var isPerspectiveCamera:Bool = true;
	public var type:String = "PerspectiveCamera";
	public var fov:Float;
	public var zoom:Float;
	public var near:Float;
	public var far:Float;
	public var focus:Float;
	public var aspect:Float;
	public var view:Dynamic;
	public var filmGauge:Float;
	public var filmOffset:Float;

	public function new(fov:Float = 50, aspect:Float = 1, near:Float = 0.1, far:Float = 2000) {
		super();
		this.fov = fov;
		this.zoom = 1;
		this.near = near;
		this.far = far;
		this.focus = 10;
		this.aspect = aspect;
		this.view = null;
		this.filmGauge = 35;
		this.filmOffset = 0;
		this.updateProjectionMatrix();
	}

	public function copy(source:PerspectiveCamera, recursive:Bool = false):PerspectiveCamera {
		super.copy(source, recursive);
		this.fov = source.fov;
		this.zoom = source.zoom;
		this.near = source.near;
		this.far = source.far;
		this.focus = source.focus;
		this.aspect = source.aspect;
		this.view = if (source.view == null) null else {
			var view = new Dynamic();
			view["enabled"] = source.view["enabled"];
			view["fullWidth"] = source.view["fullWidth"];
			view["fullHeight"] = source.view["fullHeight"];
			view["offsetX"] = source.view["offsetX"];
			view["offsetY"] = source.view["offsetY"];
			view["width"] = source.view["width"];
			view["height"] = source.view["height"];
			view;
		};
		this.filmGauge = source.filmGauge;
		this.filmOffset = source.filmOffset;
		return this;
	}

	public function setFocalLength(focalLength:Float) {
		var vExtentSlope = 0.5 * this.getFilmHeight() / focalLength;
		this.fov = MathUtils.RAD2DEG * 2 * Math.atan(vExtentSlope);
		this.updateProjectionMatrix();
	}

	public function getFocalLength():Float {
		var vExtentSlope = Math.tan(MathUtils.DEG2RAD * 0.5 * this.fov);
		return 0.5 * this.getFilmHeight() / vExtentSlope;
	}

	public function getEffectiveFOV():Float {
		return MathUtils.RAD2DEG * 2 * Math.atan(Math.tan(MathUtils.DEG2RAD * 0.5 * this.fov) / this.zoom);
	}

	public function getFilmWidth():Float {
		return this.filmGauge * Math.min(this.aspect, 1);
	}

	public function getFilmHeight():Float {
		return this.filmGauge / Math.max(this.aspect, 1);
	}

	public function getViewBounds(distance:Float, minTarget:Vector2, maxTarget:Vector2) {
		var _v3 = new Vector3(-1, -1, 0.5);
		_v3.applyMatrix4(this.projectionMatrixInverse);
		minTarget.set(_v3.x, _v3.y).multiplyScalar(-distance / _v3.z);
		_v3.set(1, 1, 0.5).applyMatrix4(this.projectionMatrixInverse);
		maxTarget.set(_v3.x, _v3.y).multiplyScalar(-distance / _v3.z);
	}

	public function getViewSize(distance:Float, target:Vector2):Vector2 {
		var _minTarget = new Vector2();
		var _maxTarget = new Vector2();
		this.getViewBounds(distance, _minTarget, _maxTarget);
		return target.subVectors(_maxTarget, _minTarget);
	}

	public function setViewOffset(fullWidth:Float, fullHeight:Float, x:Float, y:Float, width:Float, height:Float) {
		this.aspect = fullWidth / fullHeight;
		if (this.view == null) {
			this.view = {
				"enabled": true,
				"fullWidth": 1,
				"fullHeight": 1,
				"offsetX": 0,
				"offsetY": 0,
				"width": 1,
				"height": 1
			};
		}
		this.view["enabled"] = true;
		this.view["fullWidth"] = fullWidth;
		this.view["fullHeight"] = fullHeight;
		this.view["offsetX"] = x;
		this.view["offsetY"] = y;
		this.view["width"] = width;
		this.view["height"] = height;
		this.updateProjectionMatrix();
	}

	public function clearViewOffset() {
		if (this.view != null) {
			this.view["enabled"] = false;
		}
		this.updateProjectionMatrix();
	}

	public function updateProjectionMatrix() {
		var near = this.near;
		var top = near * Math.tan(MathUtils.DEG2RAD * 0.5 * this.fov) / this.zoom;
		var height = 2 * top;
		var width = this.aspect * height;
		var left = -0.5 * width;
		var view = this.view;
		if (this.view != null && this.view["enabled"]) {
			var fullWidth = view["fullWidth"];
			var fullHeight = view["fullHeight"];
			left += view["offsetX"] * width / fullWidth;
			top -= view["offsetY"] * height / fullHeight;
			width *= view["width"] / fullWidth;
			height *= view["height"] / fullHeight;
		}
		var skew = this.filmOffset;
		if (skew != 0) left += near * skew / this.getFilmWidth();
		this.projectionMatrix.makePerspective(left, left + width, top, top - height, near, this.far, this.coordinateSystem);
		this.projectionMatrixInverse.copy(this.projectionMatrix).invert();
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var data = super.toJSON(meta);
		data["object"]["fov"] = this.fov;
		data["object"]["zoom"] = this.zoom;
		data["object"]["near"] = this.near;
		data["object"]["far"] = this.far;
		data["object"]["focus"] = this.focus;
		data["object"]["aspect"] = this.aspect;
		if (this.view != null) data["object"]["view"] = {
			"enabled": this.view["enabled"],
			"fullWidth": this.view["fullWidth"],
			"fullHeight": this.view["fullHeight"],
			"offsetX": this.view["offsetX"],
			"offsetY": this.view["offsetY"],
			"width": this.view["width"],
			"height": this.view["height"]
		};
		data["object"]["filmGauge"] = this.filmGauge;
		data["object"]["filmOffset"] = this.filmOffset;
		return data;
	}
}