import MathUtils from '../math/MathUtils';
import Vector2 from '../math/Vector2';
import Vector3 from '../math/Vector3';

class PerspectiveCamera {
    public isPerspectiveCamera: Bool;
    public type: String;
    public fov: Float;
    public zoom: Float;
    public near: Float;
    public far: Float;
    public focus: Float;
    public aspect: Float;
    public view: { enabled: Bool, fullWidth: Float, fullHeight: Float, offsetX: Float, offsetY: Float, width: Float, height: Float };
    public filmGauge: Float;
    public filmOffset: Float;
    public projectionMatrix: Float;
    public projectionMatrixInverse: Float;

    public function new(fov: Float = 50, aspect: Float = 1, near: Float = 0.1, far: Float = 2000) {
        this.isPerspectiveCamera = true;
        this.type = 'PerspectiveCamera';
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

    public function copy(source: PerspectiveCamera, recursive: Bool) {
        this.fov = source.fov;
        this.zoom = source.zoom;
        this.near = source.near;
        this.far = source.far;
        this.focus = source.focus;
        this.aspect = source.aspect;
        this.view = source.view == null ? null : { ...source.view };
        this.filmGauge = source.filmGauge;
        this.filmOffset = source.filmOffset;
        return this;
    }

    public function setFocalLength(focalLength: Float) {
        const vExtentSlope = 0.5 * this.getFilmHeight() / focalLength;
        this.fov = MathUtils.RAD2DEG * 2 * Math.atan(vExtentSlope);
        this.updateProjectionMatrix();
    }

    public function getFocalLength(): Float {
        const vExtentSlope = Math.tan(MathUtils.DEG2RAD * 0.5 * this.fov);
        return 0.5 * this.getFilmHeight() / vExtentSlope;
    }

    public function getEffectiveFOV(): Float {
        return MathUtils.RAD2DEG * 2 * Math.atan(Math.tan(MathUtils.DEG2RAD * 0.5 * this.fov) / this.zoom);
    }

    public function getFilmWidth(): Float {
        return this.filmGauge * Math.min(this.aspect, 1);
    }

    public function getFilmHeight(): Float {
        return this.filmGauge / Math.max(this.aspect, 1);
    }

    public function getViewBounds(distance: Float, minTarget: Vector2, maxTarget: Vector2) {
        const _v3 = new Vector3(-1, -1, 0.5);
        _v3.applyMatrix4(this.projectionMatrixInverse);
        minTarget.set(_v3.x, _v3.y).multiplyScalar(-distance / _v3.z);
        _v3.set(1, 1, 0.5);
        _v3.applyMatrix4(this.projectionMatrixInverse);
        maxTarget.set(_v3.x, _v3.y).multiplyScalar(-distance / _v3.z);
    }

    public function getViewSize(distance: Float, target: Vector2): Vector2 {
        this.getViewBounds(distance, _minTarget, _maxTarget);
        return target.subVectors(_maxTarget, _minTarget);
    }

    public function setViewOffset(fullWidth: Float, fullHeight: Float, x: Float, y: Float, width: Float, height: Float) {
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

    public function clearViewOffset() {
        if (this.view != null) {
            this.view.enabled = false;
        }
        this.updateProjectionMatrix();
    }

    public function updateProjectionMatrix() {
        const near = this.near;
        let top = near * Math.tan(MathUtils.DEG2RAD * 0.5 * this.fov) / this.zoom;
        let height = 2 * top;
        let width = this.aspect * height;
        let left = -0.5 * width;
        const view = this.view;
        if (this.view != null && this.view.enabled) {
            const fullWidth = view.fullWidth;
            const fullHeight = view.fullHeight;
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

    public function toJSON(meta: Bool): { object: { fov: Float, zoom: Float, near: Float, far: Float, focus: Float, aspect: Float, view: { enabled: Bool, fullWidth: Float, fullHeight: Float, offsetX: Float, offsetY: Float, width: Float, height: Float }, filmGauge: Float, filmOffset: Float } } {
        const data = {
            object: {
                fov: this.fov,
                zoom: this.zoom,
                near: this.near,
                far: this.far,
                focus: this.focus,
                aspect: this.aspect,
                view: this.view != null ? { ...this.view } : null,
                filmGauge: this.filmGauge,
                filmOffset: this.filmOffset
            }
        };
        return data;
    }
}

export { PerspectiveCamera };