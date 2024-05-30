import three.MathUtils;
import three.Quaternion;
import three.Vector3;

class CameraUtils {

    static var _va:Vector3 = new Vector3(); // from pe to pa
    static var _vb:Vector3 = new Vector3(); // from pe to pb
    static var _vc:Vector3 = new Vector3(); // from pe to pc
    static var _vr:Vector3 = new Vector3(); // right axis of screen
    static var _vu:Vector3 = new Vector3(); // up axis of screen
    static var _vn:Vector3 = new Vector3(); // normal vector of screen
    static var _vec:Vector3 = new Vector3(); // temporary vector
    static var _quat:Quaternion = new Quaternion(); // temporary quaternion

    /** Set a PerspectiveCamera's projectionMatrix and quaternion
     * to exactly frame the corners of an arbitrary rectangle.
     * NOTE: This function ignores the standard parameters;
     * do not call updateProjectionMatrix() after this!
     * @param {Vector3} bottomLeftCorner
     * @param {Vector3} bottomRightCorner
     * @param {Vector3} topLeftCorner
     * @param {bool} estimateViewFrustum */
    public static function frameCorners(camera:PerspectiveCamera, bottomLeftCorner:Vector3, bottomRightCorner:Vector3, topLeftCorner:Vector3, estimateViewFrustum:Bool = false):Void {

        var pa:Vector3 = bottomLeftCorner;
        var pb:Vector3 = bottomRightCorner;
        var pc:Vector3 = topLeftCorner;
        var pe:Vector3 = camera.position; // eye position
        var n:Float = camera.near; // distance of near clipping plane
        var f:Float = camera.far; //distance of far clipping plane

        _vr.copy(pb).sub(pa).normalize();
        _vu.copy(pc).sub(pa).normalize();
        _vn.crossVectors(_vr, _vu).normalize();

        _va.copy(pa).sub(pe); // from pe to pa
        _vb.copy(pb).sub(pe); // from pe to pb
        _vc.copy(pc).sub(pe); // from pe to pc

        var d:Float = - _va.dot(_vn); // distance from eye to screen
        var l:Float = _vr.dot(_va) * n / d; // distance to left screen edge
        var r:Float = _vr.dot(_vb) * n / d; // distance to right screen edge
        var b:Float = _vu.dot(_va) * n / d; // distance to bottom screen edge
        var t:Float = _vu.dot(_vc) * n / d; // distance to top screen edge

        // Set the camera rotation to match the focal plane to the corners' plane
        _quat.setFromUnitVectors(_vec.set(0, 1, 0), _vu);
        camera.quaternion.setFromUnitVectors(_vec.set(0, 0, 1).applyQuaternion(_quat), _vn).multiply(_quat);

        // Set the off-axis projection matrix to match the corners
        camera.projectionMatrix.set(2.0 * n / (r - l), 0.0,
            (r + l) / (r - l), 0.0, 0.0,
            2.0 * n / (t - b),
            (t + b) / (t - b), 0.0, 0.0, 0.0,
            (f + n) / (n - f),
            2.0 * f * n / (n - f), 0.0, 0.0, -1.0, 0.0);
        camera.projectionMatrixInverse.copy(camera.projectionMatrix).invert();

        // FoV estimation to fix frustum culling
        if (estimateViewFrustum) {

            // Set fieldOfView to a conservative estimate
            // to make frustum tall/wide enough to encompass it
            camera.fov =
                MathUtils.RAD2DEG / Math.min(1.0, camera.aspect) *
                Math.atan((_vec.copy(pb).sub(pa).length() +
                    (_vec.copy(pc).sub(pa).length())) / _va.length());

        }

    }

}