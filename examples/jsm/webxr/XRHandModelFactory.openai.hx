package three.js.examples.jvm XRHandModelFactory;

import three.Object3D;

class XRHandModel extends Object3D {
    public var controller:Controller;
    public var motionController:Null<MotionController>;
    public var envMap:Null<Texture>;
    public var mesh:Null<Mesh>;

    public function new(controller:Controller) {
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
    public var gltfLoader:Null<GltfLoader>;
    public var path:String;
    public var onLoad:Null<Void->Void>;

    public function new(gltfLoader:Null<GltfLoader> = null, onLoad:Null<Void->Void> = null) {
        this.gltfLoader = gltfLoader;
        this.path = null;
        this.onLoad = onLoad;
    }

    public function setPath(path:String):XRHandModelFactory {
        this.path = path;
        return this;
    }

    public function createHandModel(controller:Controller, profile:String = "spheres"):XRHandModel {
        var handModel:XRHandModel = new XRHandModel(controller);

        controller.addEventListener("connected", function(event) {
            var xrInputSource:XrInputSource = event.data;

            if (xrInputSource.hand != null && handModel.motionController == null) {
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

// Export the XRHandModelFactory class
extern class XRHandModelFactory {
    public static function create():XRHandModelFactory;
}