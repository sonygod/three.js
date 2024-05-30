import js.three.Object3D;
import js.three.Sphere;
import js.three.Box3;

import js.XRHandMeshModel;

class OculusHandModel extends Object3D {
    var TOUCH_RADIUS = 0.01;
    static var POINTING_JOINT = "index-finger-tip";

    public function new(controller:Dynamic, ?loader:Dynamic, ?onLoad:Dynamic) {
        super();
        this.controller = controller;
        this.motionController = null;
        this.envMap = null;
        this.loader = loader;
        this.onLoad = onLoad;
        this.mesh = null;

        controller.addEventListener("connected", function(event) {
            var xrInputSource = event.data;
            if (xrInputSource.hand && this.motionController == null) {
                this.xrInputSource = xrInputSource;
                this.motionController = new XRHandMeshModel(this, controller, null, xrInputSource.handedness, loader, onLoad);
            }
        });

        controller.addEventListener("disconnected", function() {
            this.clear();
            this.motionController = null;
        });
    }

    public function updateMatrixWorld(?force:Bool) {
        super.updateMatrixWorld(force);
        if (this.motionController != null) {
            this.motionController.updateMesh();
        }
    }

    public function getPointerPosition():Dynamic {
        var indexFingerTip = this.controller.joints[POINTING_JOINT];
        if (indexFingerTip != null) {
            return indexFingerTip.position;
        } else {
            return null;
        }
    }

    public function intersectBoxObject(boxObject:Dynamic):Bool {
        var pointerPosition = this.getPointerPosition();
        if (pointerPosition != null) {
            var indexSphere = new Sphere(pointerPosition, TOUCH_RADIUS);
            var box = new Box3();
            box.setFromObject(boxObject);
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

class js.OculusHandModel = OculusHandModel;