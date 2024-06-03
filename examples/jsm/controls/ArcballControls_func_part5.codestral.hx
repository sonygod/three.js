import three.Vector3;
import three.Matrix4;
import three.Quaternion;

class ArcballControls {
    private var _rotationMatrix: Matrix4;
    private var _translationMatrix: Matrix4;
    private var _m4_1: Matrix4;
    private var _m4_2: Matrix4;
    private var _v3_1: Vector3;
    private var _v3_2: Vector3;
    private var _rotationAxis: Vector3;
    private var _gizmos: Object;
    private var _gizmoMatrixState: Matrix4;
    private var camera: Object;
    private var _cameraMatrixState: Matrix4;

    // ... other variables

    public function new() {
        // Initialize variables
    }

    public function zRotate(point: Vector3, angle: Float): Matrix4 {
        _rotationMatrix.makeRotationAxis(_rotationAxis, angle);
        _translationMatrix.makeTranslation(-point.x, -point.y, -point.z);

        _m4_1.makeTranslation(point.x, point.y, point.z);
        _m4_1.multiply(_rotationMatrix);
        _m4_1.multiply(_translationMatrix);

        _v3_1.setFromMatrixPosition(_gizmoMatrixState).sub(point);
        _v3_2.copy(_v3_1).applyAxisAngle(_rotationAxis, angle);
        _v3_2.sub(_v3_1);

        _m4_2.makeTranslation(_v3_2.x, _v3_2.y, _v3_2.z);

        setTransformationMatrices(_m4_1, _m4_2);
        return _transformation;
    }

    // ... other methods

    private function setTransformationMatrices(m4_1: Matrix4, m4_2: Matrix4): Void {
        // Implementation
    }

    // ... other private methods
}