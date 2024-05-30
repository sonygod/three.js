package three.js.examples.jsm.webxr;

import three.Mesh;
import three.MeshBasicMaterial;
import three.Object3D;
import three.SphereGeometry;
import three.loaders.GLTFLoader;

import motion.ControllersModule;

class XRControllerModel extends Object3D {
    public var motionController:Null<MotionController>;
    public var envMap:Null<three.Texture>;

    public function new() {
        super();
    }

    public function setEnvironmentMap(envMap:three.Texture):XRControllerModel {
        if (this.envMap == envMap) return this;

        this.envMap = envMap;
        traverse(function(child:Object3D) {
            if (child.isMesh) {
                cast(child, Mesh).material.envMap = this.envMap;
                cast(child, Mesh).material.needsUpdate = true;
            }
        });
        return this;
    }

    override public function updateMatrixWorld(force:Bool = false) {
        super.updateMatrixWorld(force);

        if (this.motionController == null) return;

        this.motionController.updateFromGamepad();

        for (component in this.motionController.components) {
            for (visualResponse in component.visualResponses) {
                var valueNode:Object3D = null;
                var minNode:Object3D = null;
                var maxNode:Object3D = null;
                var valueNodeProperty:Int = -1;

                switch (visualResponse.valueNodeProperty) {
                    case MotionControllerConstants.VisualResponseProperty.VISIBILITY:
                        valueNode.visible = visualResponse.value;
                    case MotionControllerConstants.VisualResponseProperty.TRANSFORM:
                        valueNode.quaternion.slerpQuaternions(minNode.quaternion, maxNode.quaternion, visualResponse.value);
                        valueNode.position.lerpVectors(minNode.position, maxNode.position, visualResponse.value);
                }
            }
        }
    }
}

class XRControllerModelFactory {
    private var gltfLoader:GLTFLoader;
    private var path:String;
    private var assetCache:Map<String, { scene:Object3D }>;
    private var onLoad:Null<Object->Void>;

    public function new(gltfLoader:GLTFLoader = null, onLoad:Null<Object->Void> = null) {
        this.gltfLoader = gltfLoader;
        this.path = 'https://cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0/dist/profiles';
        this.assetCache = new Map();
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

        controller.addEventListener('connected', function(event:Object) {
            var xrInputSource:Object = event.data;

            if (xrInputSource.targetRayMode != 'tracked-pointer' || xrInputSource.gamepad == null) return;

            fetchProfile(xrInputSource, this.path, 'generic-trigger').then(function(result:Object) {
                controllerModel.motionController = new MotionController(xrInputSource, result.profile, result.assetPath);

                var cachedAsset:Object = this.assetCache[controllerModel.motionController.assetUrl];
                if (cachedAsset != null) {
                    scene = cachedAsset.scene.clone();

                    addAssetSceneToControllerModel(controllerModel, scene);

                    if (this.onLoad != null) this.onLoad(scene);
                } else {
                    if (this.gltfLoader == null) {
                        throw new Error('GLTFLoader not set.');
                    }

                    this.gltfLoader.setPath('');
                    this.gltfLoader.load(controllerModel.motionController.assetUrl, function(asset:Object) {
                        this.assetCache[controllerModel.motionController.assetUrl] = asset;

                        scene = asset.scene.clone();

                        addAssetSceneToControllerModel(controllerModel, scene);

                        if (this.onLoad != null) this.onLoad(scene);
                    }, null, function() {
                        throw new Error('Asset ' + controllerModel.motionController.assetUrl + ' missing or malformed.');
                    });
                }
            }).catchError(function(err:Error) {
                trace(err);
            });
        });

        controller.addEventListener('disconnected', function() {
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
                cast(child, Mesh).material.envMap = controllerModel.envMap;
                cast(child, Mesh).material.needsUpdate = true;
            }
        });
    }

    controllerModel.add(scene);
}

function findNodes(motionController:MotionController, scene:Object3D):Void {
    for (component in motionController.components) {
        var touchPointNode:Object3D = null;

        if (component.type == MotionControllerConstants.ComponentType.TOUCHPAD) {
            touchPointNode = scene.getObjectByName(component.touchPointNodeName);

            if (touchPointNode != null) {
                var sphereGeometry:SphereGeometry = new SphereGeometry(0.001);
                var material:MeshBasicMaterial = new MeshBasicMaterial({ color: 0x0000FF });
                var sphere:Mesh = new Mesh(sphereGeometry, material);
                touchPointNode.add(sphere);
            } else {
                trace('Could not find touch dot, ' + component.touchPointNodeName + ', in touchpad component ' + component.id);
            }
        }

        for (visualResponse in component.visualResponses) {
            var valueNode:Object3D = null;
            var minNode:Object3D = null;
            var maxNode:Object3D = null;

            switch (visualResponse.valueNodeProperty) {
                case MotionControllerConstants.VisualResponseProperty.TRANSFORM:
                    minNode = scene.getObjectByName(visualResponse.minNodeName);
                    maxNode = scene.getObjectByName(visualResponse.maxNodeName);

                    if (minNode == null) {
                        trace('Could not find ' + visualResponse.minNodeName + ' in the model');
                    }

                    if (maxNode == null) {
                        trace('Could not find ' + visualResponse.maxNodeName + ' in the model');
                    }

                default:
                    valueNode = scene.getObjectByName(visualResponse.valueNodeName);

                    if (valueNode == null) {
                        trace('Could not find ' + visualResponse.valueNodeName + ' in the model');
                    }
            }
        }
    }
}