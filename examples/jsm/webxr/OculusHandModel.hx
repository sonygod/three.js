package three.js.examples.jsm.webxr;

import three.Object3D;
import three.Sphere;
import three.Box3;
import XRHandMeshModel;

class OculusHandModel extends Object3D {
    public var controller:Dynamic;
    public var motionController:XRHandMeshModel;
    public var envMap:Dynamic;
    public var loader:Dynamic;
    public var onLoad:Dynamic;
    public var mesh:Dynamic;
    public var xrInputSource:Dynamic;

    private static inline var TOUCH_RADIUS:Float = 0.01;
    private static inline var POINTING_JOINT:String = 'index-finger-tip';

    public function new(controller:Dynamic, ?loader:Dynamic, ?onLoad:Dynamic) {
        super();

        this.controller = controller;
        this.motionController = null;
        this.envMap = null;
        this.loader = loader;
        this.onLoad = onLoad;

        this.mesh = null;

        controller.addEventListener('connected', function(event) {
            var xrInputSource = event.data;

            if (xrInputSource.hand && this.motionController == null) {
                this.xrInputSource = xrInputSource;

                this.motionController = new XRHandMeshModel(this, controller, this.path, xrInputSource.handedness, loader, onLoad);
            }
        });

        controller.addEventListener('disconnected', function() {
            this.clear();
            this.motionController = null;
        });
    }

    override public function updateMatrixWorld(force:Bool) {
        super.updateMatrixWorld(force);

        if (this.motionController != null) {
            this.motionController.updateMesh();
        }
    }

    public function getPointerPosition():Vector3 {
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