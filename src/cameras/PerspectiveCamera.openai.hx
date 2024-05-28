package three.js.src.cameras;

import three.js.src.cameras.Camera;
import math.MathUtils;
import math.Vector2;
import math.Vector3;

class PerspectiveCamera extends Camera {
    private var _v3:Vector3 = new Vector3();
    private var _minTarget:Vector2 = new Vector2();
    private var _maxTarget:Vector2 = new Vector2();

    public function new(?fov:Float = 50, ?aspect:Float = 1, ?near:Float = 0.1, ?far:Float = 2000) {
        super();

        isPerspectiveCamera = true;
        type = 'PerspectiveCamera';

        this.fov = fov;
        zoom = 1;

        this.near = near;
        this.far = far;
        focus = 10;

        this.aspect = aspect;
        view = null;

        filmGauge = 35; // width of the film (default in millimeters)
        filmOffset = 0; // horizontal film offset (same unit as gauge)

        updateProjectionMatrix();
    }

    public function copy(source:PerspectiveCamera, recursive:Bool):PerspectiveCamera {
        super.copy(source, recursive);

        fov = source.fov;
        zoom = source.zoom;

        near = source.near;
        far = source.far;
        focus = source.focus;

        aspect = source.aspect;
        view = if (source.view == null) null else { }
        view = source.view.copy();

        filmGauge = source.filmGauge;
        filmOffset = source.filmOffset;

        return this;
    }

    /**
     * Sets the FOV by focal length in respect to the current .filmGauge.
     *
     * The default film gauge is 35, so that the focal length can be specified for
     * a 35mm (full frame) camera.
     *
     * Values for focal length and film gauge must have the same unit.
     */
    public function setFocalLength(focalLength:Float) {
        var vExtentSlope:Float = 0.5 * getFilmHeight() / focalLength;

        fov = MathUtils.RAD2DEG * 2 * Math.atan(vExtentSlope);
        updateProjectionMatrix();
    }

    /**
     * Calculates the focal length from the current .fov and .filmGauge.
     */
    public function getFocalLength():Float {
        var vExtentSlope:Float = Math.tan(MathUtils.DEG2RAD * 0.5 * fov);

        return 0.5 * getFilmHeight() / vExtentSlope;
    }

    public function getEffectiveFOV():Float {
        return MathUtils.RAD2DEG * 2 * Math.atan(Math.tan(MathUtils.DEG2RAD * 0.5 * fov) / zoom);
    }

    public function getFilmWidth():Float {
        return filmGauge * Math.min(aspect, 1);
    }

    public function getFilmHeight():Float {
        return filmGauge / Math.max(aspect, 1);
    }

    /**
     * Computes the 2D bounds of the camera's viewable rectangle at a given distance along the viewing direction.
     * Sets minTarget and maxTarget to the coordinates of the lower-left and upper-right corners of the view rectangle.
     */
    public function getViewBounds(distance:Float, minTarget:Vector2, maxTarget:Vector2) {
        _v3.set(-1, -1, 0.5).applyMatrix4(projectionMatrixInverse);

        minTarget.x = _v3.x;
        minTarget.y = _v3.y;
        minTarget.multiplyScalar(-distance / _v3.z);

        _v3.set(1, 1, 0.5).applyMatrix4(projectionMatrixInverse);

        maxTarget.x = _v3.x;
        maxTarget.y = _v3.y;
        maxTarget.multiplyScalar(-distance / _v3.z);
    }

    /**
     * Computes the width and height of the camera's viewable rectangle at a given distance along the viewing direction.
     * Copies the result into the target Vector2, where x is width and y is height.
     */
    public function getViewSize(distance:Float, target:Vector2) {
        getViewBounds(distance, _minTarget, _maxTarget);

        target.x = _maxTarget.x - _minTarget.x;
        target.y = _maxTarget.y - _minTarget.y;

        return target;
    }

    /**
     * Sets an offset in a larger frustum. This is useful for multi-window or
     * multi-monitor/multi-machine setups.
     *
     * For example, if you have 3x2 monitors and each monitor is 1920x1080 and
     * the monitors are in grid like this
     *
     *   +---+---+---+
     *   | A | B | C |
     *   +---+---+---+
     *   | D | E | F |
     *   +---+---+---+
     *
     * then for each monitor you would call it like this
     *
     *   const w = 1920;
     *   const h = 1080;
     *   const fullWidth = w * 3;
     *   const fullHeight = h * 2;
     *
     *   --A--
     *   camera.setViewOffset( fullWidth, fullHeight, w * 0, h * 0, w, h );
     *   --B--
     *   camera.setViewOffset( fullWidth, fullHeight, w * 1, h * 0, w, h );
     *   --C--
     *   camera.setViewOffset( fullWidth, fullHeight, w * 2, h * 0, w, h );
     *   --D--
     *   camera.setViewOffset( fullWidth, fullHeight, w * 0, h * 1, w, h );
     *   --E--
     *   camera.setViewOffset( fullWidth, fullHeight, w * 1, h * 1, w, h );
     *   --F--
     *   camera.setViewOffset( fullWidth, fullHeight, w * 2, h * 1, w, h );
     *
     *   Note there is no reason monitors have to be the same size or in a grid.
     */
    public function setViewOffset(fullWidth:Float, fullHeight:Float, x:Float, y:Float, width:Float, height:Float) {
        aspect = fullWidth / fullHeight;

        if (view == null) {
            view = {
                enabled: true,
                fullWidth: 1,
                fullHeight: 1,
                offsetX: 0,
                offsetY: 0,
                width: 1,
                height: 1
            };
        }

        view.enabled = true;
        view.fullWidth = fullWidth;
        view.fullHeight = fullHeight;
        view.offsetX = x;
        view.offsetY = y;
        view.width = width;
        view.height = height;

        updateProjectionMatrix();
    }

    public function clearViewOffset() {
        if (view != null) {
            view.enabled = false;
        }

        updateProjectionMatrix();
    }

    public function updateProjectionMatrix() {
        var near:Float = this.near;
        var top:Float = near * Math.tan(MathUtils.DEG2RAD * 0.5 * fov) / zoom;
        var height:Float = 2 * top;
        var width:Float = aspect * height;
        var left:Float = -0.5 * width;
        var view = this.view;

        if (view != null && view.enabled) {
            var fullWidth:Float = view.fullWidth,
                fullHeight:Float = view.fullHeight;

            left += view.offsetX * width / fullWidth;
            top -= view.offsetY * height / fullHeight;
            width *= view.width / fullWidth;
            height *= view.height / fullHeight;
        }

        var skew:Float = filmOffset;
        if (skew != 0) left += near * skew / getFilmWidth();

        projectionMatrix.makePerspective(left, left + width, top, top - height, near, far, coordinateSystem);

        projectionMatrixInverse.copy(projectionMatrix).invert();
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data:Dynamic = super.toJSON(meta);

        data.object.fov = fov;
        data.object.zoom = zoom;

        data.object.near = near;
        data.object.far = far;
        data.object.focus = focus;

        data.object.aspect = aspect;

        if (view != null) data.object.view = view.copy();

        data.object.filmGauge = filmGauge;
        data.object.filmOffset = filmOffset;

        return data;
    }
}