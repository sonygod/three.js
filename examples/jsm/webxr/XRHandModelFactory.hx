package three.js.examples.webxr;

import three.Object3D;

class XRHandModel extends Object3D {
    public var controller:Dynamic;
    public var motionController:Dynamic;
    public var envMap:Dynamic;
    public var mesh:Dynamic;

    public function new(controller:Dynamic) {
        super();
        this.controller = controller;
        this.motionController = null;
        this.envMap = null;
        this.mesh = null;
    }

    override public function updateMatrixWorld(force:Bool) {
        super.updateMatrixWorld(force);
        if (this.motionController != null) {
            this.motionController.updateMesh();
        }
    }
}

class XRHandModelFactory {
    public var gltfLoader:Dynamic;
    public var path:String;
    public var onLoad:Dynamic -> Void;

    public function new(gltfLoader:Dynamic = null, onLoad:Dynamic -> Void = null) {
        this.gltfLoader = gltfLoader;
        this.path = null;
        this.onLoad = onLoad;
    }

    public function setPath(path:String):XRHandModelFactory {
        this.path = path;
        return this;
    }

    public function createHandModel(controller:Dynamic, profile:String):XRHandModel {
        var handModel:XRHandModel = new XRHandModel(controller);

        controller.addEventListener("connected", function(event:Dynamic) {
            var xrInputSource:Dynamic = event.data;
            if (xrInputSource.hand && handModel.motionController == null) {
                handModel.xrInputSource = xrInputSource;

                if (profile == null || profile == "spheres") {
                    handModel.motionController = new XRHandPrimitiveModel(handModel, controller, this.path, xrInputSource.handedness, { primitive: "sphere" });
                } else if (profile == "boxes") {
                    handModel.motionController = new XRHandPrimitiveModel(handModel, controller, this.path, xrInputSource.handedness, { primitive: "box" });
                } else if (profile == "mesh") {
                    handModel.motionController = new XRHandMeshModel(handModel, controller, this.path, xrInputSource.handedness, this.gltfLoader, this.onLoad);
                }
            }

            controller.visible = true;
        });

        controller.addEventListener("disconnected", function() {
            controller.visible = false;
            // handModel.motionController = null;
            // handModel.remove(scene);
            // scene = null;
        });

        return handModel;
    }
}

// Export the factory
@:expose("XRHandModelFactory")
extern class XRHandModelFactory {}