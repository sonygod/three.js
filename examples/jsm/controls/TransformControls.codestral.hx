import three.core.{Raycaster, Vector3, Quaternion, Object3D, Euler, Matrix4};
import three.objects.{Mesh, Line, LineBasicMaterial, MeshBasicMaterial, BoxGeometry, CylinderGeometry, OctahedronGeometry, PlaneGeometry, SphereGeometry, TorusGeometry};
import three.constants.DoubleSide;

class TransformControls extends Object3D {

    private var _raycaster:Raycaster = new Raycaster();

    private var _tempVector:Vector3 = new Vector3();
    private var _tempVector2:Vector3 = new Vector3();
    private var _tempQuaternion:Quaternion = new Quaternion();
    private var _unit:haxe.ds.StringMap = new haxe.ds.StringMap();

    private var _changeEvent:Dynamic = { type: 'change' };
    private var _mouseDownEvent:Dynamic = { type: 'mouseDown', mode: null };
    private var _mouseUpEvent:Dynamic = { type: 'mouseUp', mode: null };
    private var _objectChangeEvent:Dynamic = { type: 'objectChange' };

    public function new(camera:Camera, domElement:HTMLElement) {
        super();

        if (domElement == null) {
            trace('THREE.TransformControls: The second parameter "domElement" is now mandatory.');
            domElement = js.Browser.document;
        }

        this.isTransformControls = true;

        this.visible = false;
        this.domElement = domElement;
        this.domElement.style.touchAction = 'none'; // disable touch scroll

        var _gizmo:TransformControlsGizmo = new TransformControlsGizmo();
        this._gizmo = _gizmo;
        this.add(_gizmo);

        var _plane:TransformControlsPlane = new TransformControlsPlane();
        this._plane = _plane;
        this.add(_plane);

        var scope:TransformControls = this;

        this._offset = new Vector3();
        this._startNorm = new Vector3();
        this._endNorm = new Vector3();
        this._cameraScale = new Vector3();

        this._parentPosition = new Vector3();
        this._parentQuaternion = new Quaternion();
        this._parentQuaternionInv = new Quaternion();
        this._parentScale = new Vector3();

        this._worldScaleStart = new Vector3();
        this._worldQuaternionInv = new Quaternion();
        this._worldScale = new Vector3();

        this._positionStart = new Vector3();
        this._quaternionStart = new Quaternion();
        this._scaleStart = new Vector3();

        this._getPointer = getPointer.bind(this);
        this._onPointerDown = onPointerDown.bind(this);
        this._onPointerHover = onPointerHover.bind(this);
        this._onPointerMove = onPointerMove.bind(this);
        this._onPointerUp = onPointerUp.bind(this);

        this.domElement.addEventListener('pointerdown', this._onPointerDown);
        this.domElement.addEventListener('pointermove', this._onPointerHover);
        this.domElement.addEventListener('pointerup', this._onPointerUp);

        this._unit = {
            'X': new Vector3(1, 0, 0),
            'Y': new Vector3(0, 1, 0),
            'Z': new Vector3(0, 0, 1)
        };

        this.defineProperty('camera', camera);
        this.defineProperty('object', null);
        this.defineProperty('enabled', true);
        this.defineProperty('axis', null);
        this.defineProperty('mode', 'translate');
        this.defineProperty('translationSnap', null);
        this.defineProperty('rotationSnap', null);
        this.defineProperty('scaleSnap', null);
        this.defineProperty('space', 'world');
        this.defineProperty('size', 1);
        this.defineProperty('dragging', false);
        this.defineProperty('showX', true);
        this.defineProperty('showY', true);
        this.defineProperty('showZ', true);

        var worldPosition:Vector3 = new Vector3();
        var worldPositionStart:Vector3 = new Vector3();
        var worldQuaternion:Quaternion = new Quaternion();
        var worldQuaternionStart:Quaternion = new Quaternion();
        var cameraPosition:Vector3 = new Vector3();
        var cameraQuaternion:Quaternion = new Quaternion();
        var pointStart:Vector3 = new Vector3();
        var pointEnd:Vector3 = new Vector3();
        var rotationAxis:Vector3 = new Vector3();
        var rotationAngle:Float = 0;
        var eye:Vector3 = new Vector3();

        this.defineProperty('worldPosition', worldPosition);
        this.defineProperty('worldPositionStart', worldPositionStart);
        this.defineProperty('worldQuaternion', worldQuaternion);
        this.defineProperty('worldQuaternionStart', worldQuaternionStart);
        this.defineProperty('cameraPosition', cameraPosition);
        this.defineProperty('cameraQuaternion', cameraQuaternion);
        this.defineProperty('pointStart', pointStart);
        this.defineProperty('pointEnd', pointEnd);
        this.defineProperty('rotationAxis', rotationAxis);
        this.defineProperty('rotationAngle', rotationAngle);
        this.defineProperty('eye', eye);
    }

    public function defineProperty(propName:String, defaultValue:Dynamic):Void {
        var propValue:Dynamic = defaultValue;

        var obj:Dynamic = {
            get: function() {
                return propValue != null ? propValue : defaultValue;
            },
            set: function(value:Dynamic) {
                if (propValue != value) {
                    propValue = value;
                    this._plane[propName] = value;
                    this._gizmo[propName] = value;

                    this.dispatchEvent({ type: propName + '-changed', value: value });
                    this.dispatchEvent(this._changeEvent);
                }
            }
        };

        haxe.lang.Runtime.setField(this, propName, obj);
        this[propName] = defaultValue;
        this._plane[propName] = defaultValue;
        this._gizmo[propName] = defaultValue;
    }

    // Rest of the methods...
}

// Continue with the rest of the Haxe conversion, following the same pattern.