import three.math.MathUtils;
import three.math.Quaternion;
import three.math.Vector3;

class CameraUtils {
    private var _va = new Vector3();
    private var _vb = new Vector3();
    private var _vc = new Vector3();
    private var _vr = new Vector3();
    private var _vu = new Vector3();
    private var _vn = new Vector3();
    private var _vec = new Vector3();
    private var _quat = new Quaternion();

    public function frameCorners(camera:Camera, bottomLeftCorner:Vector3, bottomRightCorner:Vector3, topLeftCorner:Vector3, estimateViewFrustum:Bool = false) {
        var pa = bottomLeftCorner;
        var pb = bottomRightCorner;
        var pc = topLeftCorner;
        var pe = camera.position;
        var n = camera.near;
        var f = camera.far;

        _vr.copy(pb).sub(pa).normalize();
        _vu.copy(pc).sub(pa).normalize();
        _vn.crossVectors(_vr, _vu).normalize();

        _va.copy(pa).sub(pe);
        _vb.copy(pb).sub(pe);
        _vc.copy(pc).sub(pe);

        var d = -_va.dot(_vn);
        var l = _vr.dot(_va) * n / d;
        var r = _vr.dot(_vb) * n / d;
        var b = _vu.dot(_va) * n / d;
        var t = _vu.dot(_vc) * n / d;

        _quat.setFromUnitVectors(_vec.set(0, 1, 0), _vu);
        camera.quaternion.setFromUnitVectors(_vec.set(0, 0, 1).applyQuaternion(_quat), _vn).multiply(_quat);

        camera.projectionMatrix.set(2.0 * n / (r - l), 0.0,
                                    (r + l) / (r - l), 0.0, 0.0,
                                    2.0 * n / (t - b),
                                    (t + b) / (t - b), 0.0, 0.0, 0.0,
                                    (f + n) / (n - f),
                                    2.0 * f * n / (n - f), 0.0, 0.0, -1.0, 0.0);
        camera.projectionMatrixInverse.copy(camera.projectionMatrix).invert();

        if (estimateViewFrustum) {
            camera.fov = MathUtils.RAD2DEG / Math.min(1.0, camera.aspect) *
                         Math.atan((_vec.copy(pb).sub(pa).length() +
                                    (_vec.copy(pc).sub(pa).length())) / _va.length());
        }
    }
}