import three.js.examples.jsm.webxr.XRHandMeshModel;
import three.js.Object3D;
import three.js.Sphere;
import three.js.Box3;

class TOUCH_RADIUS {
    static var value = 0.01;
}

class POINTING_JOINT {
    static var value = 'index-finger-tip';
}

class OculusHandModel extends Object3D {

    public var controller:Dynamic;
    public var motionController:Dynamic;
    public var envMap:Dynamic;
    public var loader:Dynamic;
    public var onLoad:Dynamic;
    public var mesh:Dynamic;
    public var xrInputSource:Dynamic;

    public function new(controller:Dynamic, loader:Dynamic = null, onLoad:Dynamic = null) {
        super();

        this.controller = controller;
        this.motionController = null;
        this.envMap = null;
        this.loader = loader;
        this.onLoad = onLoad;

        this.mesh = null;

        controller.addEventListener('connected', function(event) {
            var xrInputSource = event.data;

            if (xrInputSource.hand && !this.motionController) {
                this.xrInputSource = xrInputSource;
                this.motionController = new XRHandMeshModel(this, controller, this.path, xrInputSource.handedness, this.loader, this.onLoad);
            }
        });

        controller.addEventListener('disconnected', function() {
            this.clear();
            this.motionController = null;
        });
    }

    public function updateMatrixWorld(force:Bool) {
        super.updateMatrixWorld(force);

        if (this.motionController) {
            this.motionController.updateMesh();
        }
    }

    public function getPointerPosition() {
        var indexFingerTip = this.controller.joints[POINTING_JOINT.value];
        if (indexFingerTip) {
            return indexFingerTip.position;
        } else {
            return null;
        }
    }

    public function intersectBoxObject(boxObject:Dynamic) {
        var pointerPosition = this.getPointerPosition();
        if (pointerPosition) {
            var indexSphere = new Sphere(pointerPosition, TOUCH_RADIUS.value);
            var box = new Box3().setFromObject(boxObject);
            return indexSphere.intersectsBox(box);
        } else {
            return false;
        }
    }

    public function checkButton(button:Dynamic) {
        if (this.intersectBoxObject(button)) {
            button.onPress();
        } else {
            button.onClear();
        }

        if (button.isPressed()) {
            button.whilePressed();
        }
    }
}