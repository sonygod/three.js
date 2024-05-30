import js.three.Object3D;
import js.three.Mesh;
import js.three.MeshBasicMaterial;
import js.three.SphereGeometry;
import js.three.GLTFLoader;
import js.motionControllers.MotionController;
import js.motionControllers.Constants as MotionControllerConstants;
import js.motionControllers.fetchProfile;

class XRControllerModel extends Object3D {
    public var motionController:MotionController;
    public var envMap:Dynamic;

    public function new() {
        super();
        this.motionController = null;
        this.envMap = null;
    }

    public function setEnvironmentMap(envMap:Dynamic):XRControllerModel {
        if (this.envMap == envMap) {
            return this;
        }
        this.envMap = envMap;
        this.traverse($dynamic({ child ->
            if (child.isMesh) {
                child.material.envMap = this.envMap;
                child.material.needsUpdate = true;
            }
        }));
        return this;
    }

    public function updateMatrixWorld(force:Bool):Void {
        super.updateMatrixWorld(force);
        if (this.motionController == null) {
            return;
        }
        this.motionController.updateFromGamepad();
        var components = this.motionController.components;
        for (component in components.keys()) {
            var visualResponses = components[component].visualResponses;
            for (visualResponse in visualResponses.keys()) {
                var valueNode = visualResponses[visualResponse].valueNode;
                var minNode = visualResponses[visualResponse].minNode;
                var maxNode = visualResponses[visualResponse].maxNode;
                var value = visualResponses[visualResponse].value;
                var valueNodeProperty = visualResponses[visualResponse].valueNodeProperty;
                if (valueNode == null) {
                    continue;
                }
                if (valueNodeProperty == MotionControllerConstants.VisualResponseProperty.VISIBILITY) {
                    valueNode.visible = value;
                } else if (valueNodeProperty == MotionControllerConstants.VisualResponseProperty.TRANSFORM) {
                    valueNode.quaternion.slerpQuaternions(minNode.quaternion, maxNode.quaternion, value);
                    valueNode.position.lerpVectors(minNode.position, maxNode.position, value);
                }
            }
        }
    }
}

function findNodes(motionController:MotionController, scene:Dynamic):Void {
    var components = motionController.components;
    for (component in components.keys()) {
        var type = components[component].type;
        var touchPointNodeName = components[component].touchPointNodeName;
        var visualResponses = components[component].visualResponses;
        if (type == MotionControllerConstants.ComponentType.TOUCHPAD) {
            var touchPointNode = scene.getObjectByName(touchPointNodeName);
            if (touchPointNode != null) {
                var sphereGeometry = new SphereGeometry(0.001);
                var material = new MeshBasicMaterial({ color: 0x0000FF });
                var sphere = new Mesh(sphereGeometry, material);
                touchPointNode.add(sphere);
            } else {
                trace(`Could not find touch dot, ${touchPointNodeName}, in touchpad component ${component}`);
            }
        }
        for (visualResponse in visualResponses.keys()) {
            var valueNodeName = visualResponses[visualResponse].valueNodeName;
            var minNodeName = visualResponses[visualResponse].minNodeName;
            var maxNodeName = visualResponses[visualResponse].maxNodeName;
            var valueNodeProperty = visualResponses[visualResponse].valueNodeProperty;
            if (valueNodeProperty == MotionControllerConstants.VisualResponseProperty.TRANSFORM) {
                var minNode = scene.getObjectByName(minNodeName);
                var maxNode = scene.getObjectByName(maxNodeName);
                if (minNode == null) {
                    trace(`Could not find ${minNodeName} in the model`);
                    continue;
                }
                if (maxNode == null) {
                    trace(`Could not find ${maxNodeName} in the model`);
                    continue;
                }
                visualResponses[visualResponse].minNode = minNode;
                visualResponses[visualResponse].maxNode = maxNode;
            }
            var valueNode = scene.getObjectByName(valueNodeName);
            if (valueNode == null) {
                trace(`Could not find ${valueNodeName} in the model`);
            }
            visualResponses[visualResponse].valueNode = valueNode;
        }
    }
}

function addAssetSceneToControllerModel(controllerModel:XRControllerModel, scene:Dynamic):Void {
    findNodes(controllerModel.motionController, scene);
    if (controllerModel.envMap != null) {
        scene.traverse($dynamic({ child ->
            if (child.isMesh) {
                child.material.envMap = controllerModel.envMap;
                child.material.needsUpdate = true;
            }
        }));
    }
    controllerModel.add(scene);
}

class XRControllerModelFactory {
    public var gltfLoader:GLTFLoader;
    public var path:String;
    public var _assetCache:Dynamic;
    public var onLoad:Dynamic;

    public function new(gltfLoader:GLTFLoader = null, onLoad:Dynamic = null) {
        this.gltfLoader = gltfLoader;
        this.path = "https://cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0/dist/profiles";
        this._assetCache = {};
        this.onLoad = onLoad;
        if (this.gltfLoader == null) {
            this.gltfLoader = new GLTFLoader();
        }
    }

    public function setPath(path:String):XRControllerModelFactory {
        this.path = path;
        return this;
    }

    public function createControllerModel(controller:Dynamic):XRControllerModel {
        var controllerModel = new XRControllerModel();
        var scene:Dynamic = null;
        controller.addEventListener('connected', $dynamic({ event ->
            var xrInputSource = event.data;
            if (xrInputSource.targetRayMode != 'tracked-pointer' || xrInputSource.gamepad == null) {
                return;
            }
            fetchProfile(xrInputSource, this.path, "generic-trigger").then($dynamic({ result ->
                controllerModel.motionController = new MotionController(xrInputSource, result.profile, result.assetPath);
                var cachedAsset = this._assetCache[controllerModel.motionController.assetUrl];
                if (cachedAsset != null) {
                    scene = cachedAsset.scene.clone();
                    addAssetSceneToControllerModel(controllerModel, scene);
                    if (this.onLoad != null) {
                        this.onLoad(scene);
                    }
                } else {
                    if (this.gltfLoader == null) {
                        throw new Error('GLTFLoader not set.');
                    }
                    this.gltfLoader.setPath('');
                    this.gltfLoader.load(controllerModel.motionController.assetUrl, $dynamic({ asset ->
                        this._assetCache[controllerModel.motionController.assetUrl] = asset;
                        scene = asset.scene.clone();
                        addAssetSceneToControllerModel(controllerModel, scene);
                        if (this.onLoad != null) {
                            this.onLoad(scene);
                        }
                    }), null, $dynamic({ () ->
                        throw new Error(`Asset ${controllerModel.motionController.assetUrl} missing or malformed.`);
                    }));
                }
            }), $dynamic({ err ->
                trace(err);
            }));
        }));
        controller.addEventListener('disconnected', $dynamic({ () ->
            controllerModel.motionController = null;
            controllerModel.remove(scene);
            scene = null;
        }));
        return controllerModel;
    }
}