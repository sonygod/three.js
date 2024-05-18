Here is the converted Haxe code:
```
package three.js.examples.jvm.controls;

import three.js.core.Mesh;
import three.js.geom.PlaneGeometry;
import three.js.materials.MeshBasicMaterial;
import three.js.math.Quaternion;
import three.js.math.Vector3;

class TransformControlsPlane extends Mesh {
    public var isTransformControlsPlane:Bool = true;
    public var type:String = 'TransformControlsPlane';

    private var _v1:Vector3 = new Vector3();
    private var _v2:Vector3 = new Vector3();
    private var _v3:Vector3 = new Vector3();
    private var _alignVector:Vector3 = new Vector3();
    private var _dirVector:Vector3 = new Vector3();
    private var _tempMatrix:Matrix4 = new Matrix4();
    private var _tempVector:Vector3 = new Vector3();
    private var _identityQuaternion:Quaternion = new Quaternion();
    private var _unitX:Vector3 = new Vector3(1, 0, 0);
    private var _unitY:Vector3 = new Vector3(0, 1, 0);
    private var _unitZ:Vector3 = new Vector3(0, 0, 1);
    private var space:String;
    private var mode:String;
    private var axis:String;
    private var eye:Vector3;
    private var cameraQuaternion:Quaternion;

    public function new() {
        super(new PlaneGeometry(100000, 100000, 2, 2), 
              new MeshBasicMaterial({
                  visible: false, 
                  wireframe: true, 
                  side: DoubleSide, 
                  transparent: true, 
                  opacity: 0.1, 
                  toneMapped: false
              }));
    }

    override public function updateMatrixWorld(force:Bool):Void {
        space = this.space;
        this.position.copy(this.worldPosition);

        if (mode == 'scale') 
            space = 'local'; // scale always oriented to local rotation

        _v1.copy(_unitX).applyQuaternion(space == 'local' ? this.worldQuaternion : _identityQuaternion);
        _v2.copy(_unitY).applyQuaternion(space == 'local' ? this.worldQuaternion : _identityQuaternion);
        _v3.copy(_unitZ).applyQuaternion(space == 'local' ? this.worldQuaternion : _identityQuaternion);

        // Align the plane for current transform mode, axis and space.

        _alignVector.copy(_v2);

        switch (mode) {
            case 'translate', 'scale':
                switch (axis) {
                    case 'X':
                        _alignVector.copy(eye).cross(_v1);
                        _dirVector.copy(_v1).cross(_alignVector);
                        break;
                    case 'Y':
                        _alignVector.copy(eye).cross(_v2);
                        _dirVector.copy(_v2).cross(_alignVector);
                        break;
                    case 'Z':
                        _alignVector.copy(eye).cross(_v3);
                        _dirVector.copy(_v3).cross(_alignVector);
                        break;
                    case 'XY':
                        _dirVector.copy(_v3);
                        break;
                    case 'YZ':
                        _dirVector.copy(_v1);
                        break;
                    case 'XZ':
                        _alignVector.copy(_v3);
                        _dirVector.copy(_v2);
                        break;
                    case 'XYZ', 'E':
                        _dirVector.set(0, 0, 0);
                        break;
                }
                break;
            case 'rotate', _:
                // special case for rotate
                _dirVector.set(0, 0, 0);
        }

        if (_dirVector.length() == 0) {
            // If in rotate mode, make the plane parallel to camera
            this.quaternion.copy(cameraQuaternion);
        } else {
            _tempMatrix.lookAt(_tempVector.set(0, 0, 0), _dirVector, _alignVector);
            this.quaternion.setFromRotationMatrix(_tempMatrix);
        }

        super.updateMatrixWorld(force);
    }
}
```
Note that I had to make some assumptions about the types of some variables, as they were not explicitly declared in the JavaScript code. I also had to replace some JavaScript-specific constructs (e.g. `let` and `switch` statements) with their Haxe equivalents. Additionally, I had to add some type annotations and imports to make the code compatible with Haxe.