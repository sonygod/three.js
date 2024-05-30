import three.Object3D;
import three.Sphere;
import three.Box3;
import js.Lib;

@:jsRequire('./XRHandMeshModel.js')
external class XRHandMeshModel {
    public function new(controller:OculusHandModel, controller:Object, path:String, handedness:String, loader:Object, onLoad:Object):Void;
    public function updateMesh():Void;
}

class OculusHandModel extends Object3D {

    var controller:Object;
    var motionController:XRHandMeshModel;
    var envMap:Object;
    var loader:Object;
    var onLoad:Object;
    var mesh:Object;
    var xrInputSource:Object;

    public function new(controller:Object, loader:Object = null, onLoad:Object = null) {
        super();

        this.controller = controller;
        this.motionController = null;
        this.envMap = null;
        this.loader = loader;
        this.onLoad = onLoad;

        this.mesh = null;

        controller.addEventListener('connected', function(event:Object):Void {
            var xrInputSource:Object = event.data;

            if (xrInputSource.hand && !this.motionController) {
                this.xrInputSource = xrInputSource;
                this.motionController = new XRHandMeshModel(this, controller, this.path, xrInputSource.handedness, this.loader, this.onLoad);
            }
        });

        controller.addEventListener('disconnected', function():Void {
            this.clear();
            this.motionController = null;
        });
    }

    public function updateMatrixWorld(force:Bool):Void {
        super.updateMatrixWorld(force);

        if (this.motionController) {
            this.motionController.updateMesh();
        }
    }

    public function getPointerPosition():Object {
        var indexFingerTip:Object = this.controller.joints['index-finger-tip'];
        if (indexFingerTip) {
            return indexFingerTip.position;
        } else {
            return null;
        }
    }

    public function intersectBoxObject(boxObject:Object):Bool {
        var pointerPosition:Object = this.getPointerPosition();
        if (pointerPosition) {
            var indexSphere:Sphere = new Sphere(pointerPosition, 0.01);
            var box:Box3 = new Box3().setFromObject(boxObject);
            return indexSphere.intersectsBox(box);
        } else {
            return false;
        }
    }

    public function checkButton(button:Object):Void {
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