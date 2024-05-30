import js.three.Object3D;

import XRHandPrimitiveModel from "./XRHandPrimitiveModel";
import XRHandMeshModel from "./XRHandMeshModel";

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

    public function updateMatrixWorld(force:Dynamic) {
        super.updateMatrixWorld(force);
        if (motionController != null) {
            motionController.updateMesh();
        }
    }
}

class XRHandModelFactory {
    public var gltfLoader:Dynamic;
    public var path:Dynamic;
    public var onLoad:Dynamic;

    public function new(gltfLoader:Dynamic = null, onLoad:Dynamic = null) {
        this.gltfLoader = gltfLoader;
        this.path = null;
        this.onLoad = onLoad;
    }

    public function setPath(path:Dynamic):Void {
        this.path = path;
        return;
    }

    public function createHandModel(controller:Dynamic, profile:String):XRHandModel {
        var handModel = new XRHandModel(controller);

        $bind(controller, 'connected', function(event:Dynamic) {
            var xrInputSource = event.data;

            if (xrInputSource.hand != null && handModel.motionController == null) {
                handModel.xrInputSource = xrInputSource;

                if (profile == null || profile == 'spheres') {
                    handModel.motionController = new XRHandPrimitiveModel(handModel, controller, path, xrInputSource.handedness, { primitive: 'sphere' });
                } else if (profile == 'boxes') {
                    handModel.motionController = new XRHandPrimitiveModel(handModel, controller, path, xrInputSource.handedness, { primitive: 'box' });
                } else if (profile == 'mesh') {
                    handModel.motionController = new XRHandMeshModel(handModel, controller, path, xrInputSource.handedness, gltfLoader, onLoad);
                }
            }

            controller.visible = true;
        });

        $bind(controller, 'disconnected', function() {
            controller.visible = false;
        });

        return handModel;
    }
}

class js {
    public static class three {
        public static class Object3D {
            public function new():Void;
        }
    }
}

class XRHandPrimitiveModel {
    public function new(handModel:Dynamic, controller:Dynamic, path:Dynamic, handedness:Dynamic, options:Dynamic):Void;
}

class XRHandMeshModel {
    public function new(handModel:Dynamic, controller:Dynamic, path:Dynamic, handedness:Dynamic, gltfLoader:Dynamic, onLoad:Dynamic):Void;
}