package three.js.examples.webxr;

import three.js.Mesh;
import three.js.MeshBasicMaterial;
import three.js.Object3D;
import three.js.SphereGeometry;
import three.loaders.GLTFLoader;

class XRControllerModel extends Object3D {
    public var motionController:MotionController;
    public var envMap:Texture;

    public function new() {
        super();
        this.motionController = null;
        this.envMap = null;
    }

    public function setEnvironmentMap(envMap:Texture):XRControllerModel {
        if (this.envMap == envMap) return this;
        this.envMap = envMap;
        this.traverse(function(child:Object3D) {
            if (child.isMesh) {
                child.material.envMap = this.envMap;
                child.material.needsUpdate = true;
            }
        });
        return this;
    }

    override public function updateMatrixWorld(force:Bool) {
        super.updateMatrixWorld(force);
        if (!this.motionController) return;
        this.motionController.updateFromGamepad();
        for (component in this.motionController.components) {
            for (visualResponse in component.visualResponses) {
                if (visualResponse.valueNode == null) continue;
                if (visualResponse.valueNodeProperty == MotionControllerConstants.VisualResponseProperty.VISIBILITY) {
                    visualResponse.valueNode.visible = visualResponse.value;
                } else if (visualResponse.valueNodeProperty == MotionControllerConstants.VisualResponseProperty.TRANSFORM) {
                    visualResponse.valueNode.quaternion.slerpQuaternions(
                        visualResponse.minNode.quaternion,
                        visualResponse.maxNode.quaternion,
                        visualResponse.value
                    );
                    visualResponse.valueNode.position.lerpVectors(
                        visualResponse.minNode.position,
                        visualResponse.maxNode.position,
                        visualResponse.value
                    );
                }
            }
        }
    }
}

class MotionController {
    public var components:Array<MotionControllerComponent>;

    public function new(xrInputSource:Object, profile:Object, assetPath:String) {
        // TO DO: implement MotionController constructor
    }

    public function updateFromGamepad() {
        // TO DO: implement updateFromGamepad method
    }
}

class MotionControllerComponent {
    public var type:Int;
    public var touchPointNodeName:String;
    public var visualResponses:Array<MotionControllerVisualResponse>;

    public function new() {}
}

class MotionControllerVisualResponse {
    public var valueNode:Object3D;
    public var minNode:Object3D;
    public var maxNode:Object3D;
    public var valueNodeProperty:Int;
    public var value:Float;

    public function new() {}
}

class XRControllerModelFactory {
    private var gltfLoader:GLTFLoader;
    private var path:String;
    private var _assetCache:Map<String, { scene:Object3D }>;
    private var onLoad:(scene:Object3D) -> Void;

    public function new(gltfLoader:GLTFLoader = null, onLoad:(scene:Object3D) -> Void = null) {
        this.gltfLoader = gltfLoader;
        this.path = DEFAULT_PROFILES_PATH;
        this._assetCache = new Map();
        this.onLoad = onLoad;
        if (gltfLoader == null) {
            this.gltfLoader = new GLTFLoader();
        }
    }

    public function setPath(path:String):XRControllerModelFactory {
        this.path = path;
        return this;
    }

    public function createControllerModel(controller:Object):XRControllerModel {
        var controllerModel:XRControllerModel = new XRControllerModel();
        var scene:Object3D = null;

        controller.addEventListener("connected", function(event) {
            var xrInputSource:Object = event.data;
            if (xrInputSource.targetRayMode != "tracked-pointer" || !xrInputSource.gamepad) return;
            fetchProfile(xrInputSource, this.path, DEFAULT_PROFILE).then(function(profile:Object) {
                controllerModel.motionController = new MotionController(xrInputSource, profile, profile.assetPath);
                var cachedAsset:{ scene:Object3D } = this._assetCache[controllerModel.motionController.assetUrl];
                if (cachedAsset != null) {
                    scene = cachedAsset.scene.clone();
                    addAssetSceneToControllerModel(controllerModel, scene);
                    if (this.onLoad != null) this.onLoad(scene);
                } else {
                    this.gltfLoader.setPath("");
                    this.gltfLoader.load(controllerModel.motionController.assetUrl, function(asset:Object) {
                        this._assetCache[controllerModel.motionController.assetUrl] = asset;
                        scene = asset.scene.clone();
                        addAssetSceneToControllerModel(controllerModel, scene);
                        if (this.onLoad != null) this.onLoad(scene);
                    }, null, function() {
                        throw new Error("Asset " + controllerModel.motionController.assetUrl + " missing or malformed.");
                    });
                }
            }).catchError(function(err:Error) {
                Console.warn(err);
            });
        });

        controller.addEventListener("disconnected", function() {
            controllerModel.motionController = null;
            controllerModel.remove(scene);
            scene = null;
        });

        return controllerModel;
    }
}

function addAssetSceneToControllerModel(controllerModel:XRControllerModel, scene:Object3D):Void {
    findNodes(controllerModel.motionController, scene);
    if (controllerModel.envMap != null) {
        scene.traverse(function(child:Object3D) {
            if (child.isMesh) {
                child.material.envMap = controllerModel.envMap;
                child.material.needsUpdate = true;
            }
        });
    }
    controllerModel.add(scene);
}

function findNodes(motionController:MotionController, scene:Object3D):Void {
    for (component in motionController.components) {
        for (visualResponse in component.visualResponses) {
            if (visualResponse.valueNodeName != null) {
                visualResponse.valueNode = scene.getObjectByName(visualResponse.valueNodeName);
                if (visualResponse.valueNode == null) {
                    Console.warn("Could not find " + visualResponse.valueNodeName + " in the model");
                }
            }
            if (visualResponse.minNodeName != null) {
                visualResponse.minNode = scene.getObjectByName(visualResponse.minNodeName);
                if (visualResponse.minNode == null) {
                    Console.warn("Could not find " + visualResponse.minNodeName + " in the model");
                }
            }
            if (visualResponse.maxNodeName != null) {
                visualResponse.maxNode = scene.getObjectByName(visualResponse.maxNodeName);
                if (visualResponse.maxNode == null) {
                    Console.warn("Could not find " + visualResponse.maxNodeName + " in the model");
                }
            }
        }
    }
}

function fetchProfile(xrInputSource:Object, path:String, profileName:String):Promise<Object> {
    // TO DO: implement fetchProfile function
    return null;
}

const DEFAULT_PROFILES_PATH = "https://cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0/dist/profiles";
const DEFAULT_PROFILE = "generic-trigger";

const Constants = {
    VisualResponseProperty: {
        VISIBILITY: 0,
        TRANSFORM: 1
    }
};