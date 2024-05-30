import js.three.MathUtils;
import js.three.Quaternion;
import js.three.Vector3;

var _va = new Vector3(); // from pe to pa
var _vb = new Vector3(); // from pe to pb
var _vc = new Vector3(); // from pe to pc
var _vr = new Vector3(); // right axis of screen
var _vu = new Vector3(); // up axis of screen
var _vn = new Vector3(); // normal vector of screen
var _vec = new Vector3(); // temporary vector
var _quat = new Quaternion(); // temporary quaternion

/**
 * Set a PerspectiveCamera's projectionMatrix and quaternion
 * to exactly frame the corners of an arbitrary rectangle.
 * NOTE: This function ignores the standard parameters;
 * do not call updateProjectionMatrix() after this!
 * @param {Vector3} bottomLeftCorner
 * @param {Vector3} bottomRightCorner
 * @param {Vector3} topLeftCorner
 * @param {boolean} estimateViewFrustum
 */
function frameCorners(camera : PerspectiveCamera, bottomLeftCorner : Vector3, bottomRightCorner : Vector3, topLeftCorner : Vector3, estimateViewFrustum : Bool = false) {
	var pa = bottomLeftCorner;
	var pb = bottomRightCorner;
	var pc = topLeftCorner;
	var pe = camera.position; // eye position
	var n = camera.near; // distance of near clipping plane
	var f = camera.far; //distance of far clipping plane

	_vr.copy(pb).sub(pa).normalize();
	_vu.copy(pc).sub(pa).normalize();
	_vn.crossVectors(_vr, _vu).normalize();

	_va.copy(pa).sub(pe); // from pe to pa
	_vb.copy(pb).sub(pe); // from pe to pb
	_vc.copy(pc).sub(pe); // from pe to pc

	var d = -_va.dot(_vn); // distance from eye to screen
	var l = _vr.dot(_va) * n / d; // distance to left screen edge
	var r = _vr.dot(_vb) * n / d; // distance to right screen edge
	var b = _vu.dot(_va) * n / d; // distance to bottom screen edge
	var t = _vu.dot(_vc) * n / d; // distance to top screen edge

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
		camera.fov = MathUtils.RAD2DEG / Math.min(1.0, camera.aspect) *
			Math.atan((_vec.copy(pb).sub(pa).length() +
				(_vec.copy(pc).sub(pa).length())) / _va.length());
	}
}

function main() {
	// Usage example
	var camera = new PerspectiveCamera();
	var bottomLeft = new Vector3(0, 0, 0);
	var bottomRight = new Vector3(10, 0, 10);
	var topLeft = new Vector3(0, 10, 10);
	frameCorners(camera, bottomLeft, bottomRight, topLeft);
}

class PerspectiveCamera {
	public var position:Vector3;
	public var near:Float;
	public var far:Float;
	public var aspect:Float;
	public var fov:Float;
	public var projectionMatrix:Matrix4;
	public var projectionMatrixInverse:Matrix4;
	public var quaternion:Quaternion;
}