import js.Browser.document;
import js.html.Element;
import three.core.Object3D;
import three.materials.MeshBasicMaterial;
import three.materials.Material;
import three.objects.Mesh;
import three.geometries.SphereGeometry;
import three.loaders.GLTFLoader;
import webxr.input.motioncontrollers.Constants;
import webxr.input.motioncontrollers.fetchProfile;
import webxr.input.motioncontrollers.MotionController;

class XRControllerModel extends Object3D {
    public var motionController: MotionController = null;
    public var envMap: Material = null;

    public function new() {
        super();
    }

    public function setEnvironmentMap(envMap: Material): XRControllerModel {
        if (this.envMap == envMap) return this;

        this.envMap = envMap;
        this.traverse((child: Object3D) -> {
            if (Std.is(child, Mesh)) {
                child.material.envMap = this.envMap;
                child.material.needsUpdate = true;
            }
        });
        return this;
    }

    public override function updateMatrixWorld(force: Bool = false): Void {
        super.updateMatrixWorld(force);

        if (this.motionController == null) return;

        this.motionController.updateFromGamepad();

        for (component in this.motionController.components.values()) {
            for (visualResponse in component.visualResponses.values()) {
                if (visualResponse.valueNode == null) continue;

                if (visualResponse.valueNodeProperty == Constants.VisualResponseProperty.VISIBILITY) {
                    visualResponse.valueNode.visible = visualResponse.value;
                } else if (visualResponse.valueNodeProperty == Constants.VisualResponseProperty.TRANSFORM) {
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

function findNodes(motionController: MotionController, scene: Object3D): Void {
    for (component in motionController.components.values()) {
        if (component.type == Constants.ComponentType.TOUCHPAD) {
            component.touchPointNode = scene.getObjectByName(component.touchPointNodeName);
            if (component.touchPointNode == null) {
                js.Browser.console.warn("Could not find touch dot, ${component.touchPointNodeName}, in touchpad component ${component.id}");
            } else {
                var sphereGeometry = new SphereGeometry(0.001);
                var material = new MeshBasicMaterial({ color: 0x0000FF });
                var sphere = new Mesh(sphereGeometry, material);
                component.touchPointNode.add(sphere);
            }
        }

        for (visualResponse in component.visualResponses.values()) {
            if (visualResponse.valueNodeProperty == Constants.VisualResponseProperty.TRANSFORM) {
                visualResponse.minNode = scene.getObjectByName(visualResponse.minNodeName);
                visualResponse.maxNode = scene.getObjectByName(visualResponse.maxNodeName);

                if (visualResponse.minNode == null) {
                    js.Browser.console.warn("Could not find ${visualResponse.minNodeName} in the model");
                    continue;
                }

                if (visualResponse.maxNode == null) {
                    js.Browser.console.warn("Could not find ${visualResponse.maxNodeName} in the model");
                    continue;
                }
            }

            visualResponse.valueNode = scene.getObjectByName(visualResponse.valueNodeName);
            if (visualResponse.valueNode == null) {
                js.Browser.console.warn("Could not find ${visualResponse.valueNodeName} in the model");
            }
        }
    }
}

function addAssetSceneToControllerModel(controllerModel: XRControllerModel, scene: Object3D): Void {
    findNodes(controllerModel.motionController, scene);

    if (controllerModel.envMap != null) {
        scene.traverse((child: Object3D) -> {
            if (Std.is(child, Mesh)) {
                child.material.envMap = controllerModel.envMap;
                child.material.needsUpdate = true;
            }
        });
    }

    controllerModel.add(scene);
}

class XRControllerModelFactory {
    public var gltfLoader: GLTFLoader = null;
    public var path: String = "https://cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0/dist/profiles";
    private var _assetCache: haxe.ds.StringMap<Object> = new haxe.ds.StringMap<Object>();
    public var onLoad: (scene: Object3D) -> Void = null;

    public function new(gltfLoader: GLTFLoader = null, onLoad: (scene: Object3D) -> Void = null) {
        this.gltfLoader = gltfLoader;
        this.onLoad = onLoad;

        if (this.gltfLoader == null) {
            this.gltfLoader = new GLTFLoader();
        }
    }

    public function setPath(path: String): XRControllerModelFactory {
        this.path = path;
        return this;
    }

    public function createControllerModel(controller: XRInputSource): XRControllerModel {
        var controllerModel = new XRControllerModel();
        var scene: Object3D = null;

        controller.addEventListener("connected", (event: Event) -> {
            var xrInputSource = event.data;

            if (xrInputSource.targetRayMode != "tracked-pointer" || xrInputSource.gamepad == null) return;

            fetchProfile(xrInputSource, this.path, "generic-trigger").then((result: Dynamic) -> {
                controllerModel.motionController = new MotionController(
                    xrInputSource,
                    result.profile,
                    result.assetPath
                );

                var cachedAsset = this._assetCache.get(controllerModel.motionController.assetUrl);
                if (cachedAsset != null) {
                    scene = cachedAsset.scene.clone();
                    addAssetSceneToControllerModel(controllerModel, scene);

                    if (this.onLoad != null) this.onLoad(scene);
                } else {
                    if (this.gltfLoader == null) {
                        throw new Error("GLTFLoader not set.");
                    }

                    this.gltfLoader.setPath("");
                    this.gltfLoader.load(controllerModel.motionController.assetUrl, (asset: Dynamic) -> {
                        this._assetCache.set(controllerModel.motionController.assetUrl, asset);

                        scene = asset.scene.clone();
                        addAssetSceneToControllerModel(controllerModel, scene);

                        if (this.onLoad != null) this.onLoad(scene);
                    }, null, () -> {
                        throw new Error("Asset ${controllerModel.motionController.assetUrl} missing or malformed.");
                    });
                }
            }).catch((err: Dynamic) -> {
                js.Browser.console.warn(err);
            });
        });

        controller.addEventListener("disconnected", () -> {
            controllerModel.motionController = null;
            controllerModel.remove(scene);
            scene = null;
        });

        return controllerModel;
    }
}