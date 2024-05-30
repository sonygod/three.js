import Camera.Camera;
import MathUtils.*;
import Vector2.Vector2;
import Vector3.Vector3;

class PerspectiveCamera extends Camera {

	public var isPerspectiveCamera:Bool = true;
	public var type:String = 'PerspectiveCamera';
	public var fov:Float = 50;
	public var zoom:Float = 1;
	public var near:Float = 0.1;
	public var far:Float = 2000;
	public var focus:Float = 10;
	public var aspect:Float = 1;
	public var view:Null<Dynamic> = null;
	public var filmGauge:Float = 35;
	public var filmOffset:Float = 0;

	public function new(fov?:Float, aspect?:Float, near?:Float, far?:Float) {
		super();
		if (fov != null) this.fov = fov;
		if (aspect != null) this.aspect = aspect;
		if (near != null) this.near = near;
		if (far != null) this.far = far;
		this.updateProjectionMatrix();
	}

	public function copy(source:PerspectiveCamera, recursive:Bool):PerspectiveCamera {
		super.copy(source, recursive);
		this.fov = source.fov;
		this.zoom = source.zoom;
		this.near = source.near;
		this.far = source.far;
		this.focus = source.focus;
		this.aspect = source.aspect;
		this.view = source.view == null ? null : Type.createEmptyInstance(Type.getClass(source.view));
		this.filmGauge = source.filmGauge;
		this.filmOffset = source.filmOffset;
		return this;
	}

	public function setFocalLength(focalLength:Float) {
		const vExtentSlope = 0.5 * this.getFilmHeight() / focalLength;
		this.fov = RAD2DEG * 2 * Math.atan(vExtentSlope);
		this.updateProjectionMatrix();
	}

	public function getFocalLength():Float {
		const vExtentSlope = Math.tan(DEG2RAD * 0.5 * this.fov);
		return 0.5 * this.getFilmHeight() / vExtentSlope;
	}

	public function getEffectiveFOV():Float {
		return RAD2DEG * 2 * Math.atan(Math.tan(DEG2RAD * 0.5 * this.fov) / this.zoom);
	}

	public function getFilmWidth():Float {
		return this.filmGauge * Math.min(this.aspect, 1);
	}

	public function getFilmHeight():Float {
		return this.filmGauge / Math.max(this.aspect, 1);
	}

	public function getViewBounds(distance:Float, minTarget:Vector2, maxTarget:Vector2):Void {
		var v3 = new Vector3(-1, -1, 0.5);
		v3.applyMatrix4(this.projectionMatrixInverse);
		minTarget.set(v3.x, v3.y).multiplyScalar(-distance / v3.z);
		v3.set(1, 1, 0.5);
		v3.applyMatrix4(this.projectionMatrixInverse);
		maxTarget.set(v3.x, v3.y).multiplyScalar(-distance / v3.z);
	}

	public function getViewSize(distance:Float, target:Vector2):Vector2 {
		this.getViewBounds(distance, new Vector2(), new Vector2());
		return target.subVectors(new Vector2(), new Vector2());
	}

	public function setViewOffset(fullWidth:Float, fullHeight:Float, x:Float, y:Float, width:Float, height:Float):Void {
		this.aspect = fullWidth / fullHeight;
		if (this.view == null) {
			this.view = {
				enabled: true,
				fullWidth: 1,
				fullHeight: 1,
				offsetX: 0,
				offsetY: 0,
				width: 1,
				height: 1
			};
		}
		this.view.enabled = true;
		this.view.fullWidth = fullWidth;
		this.view.fullHeight = fullHeight;
		this.view.offsetX = x;
		this.view.offsetY = y;
		this.view.width = width;
		this.view.height = height;
		this.updateProjectionMatrix();
	}

	public function clearViewOffset():Void {
		if (this.view != null) {
			this.view.enabled = false;
		}
		this.updateProjectionMatrix();
	}

	public function updateProjectionMatrix():Void {
		const near = this.near;
		let top = near * Math.tan(DEG2RAD * 0.5 * this.fov) / this.zoom;
		let height = 2 * top;
		let width = this.aspect * height;
		let left = -0.5 * width;
		const view = this.view;
		if (this.view != null && this.view.enabled) {
			const fullWidth = view.fullWidth,
				fullHeight = view.fullHeight;
			left += view.offsetX * width / fullWidth;
			top -= view.offsetY * height / fullHeight;
			width *= view.width / fullWidth;
			height *= view.height / fullHeight;
		}
		const skew = this.filmOffset;
		if (skew != 0) left += near * skew / this.getFilmWidth();
		this.projectionMatrix.makePerspective(left, left + width, top, top - height, near, this.far, this.coordinateSystem);
		this.projectionMatrixInverse.copy(this.projectionMatrix).invert();
	}

	public function toJSON(meta:Dynamic):Dynamic {
		const data = super.toJSON(meta);
		data.object.fov = this.fov;
		data.object.zoom = this.zoom;
		data.object.near = this.near;
		data.object.far = this.far;
		data.object.focus = this.focus;
		data.object.aspect = this.aspect;
		if (this.view != null) data.object.view = Type.createEmptyInstance(Type.getClass(this.view));
		data.object.filmGauge = this.filmGauge;
		data.object.filmOffset = this.filmOffset;
		return data;
	}

}