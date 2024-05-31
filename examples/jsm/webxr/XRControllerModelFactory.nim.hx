import three.Mesh;
import three.MeshBasicMaterial;
import three.Object3D;
import three.SphereGeometry;

import three_extra.loaders.GLTFLoader;

import three_extra.motion_controllers.MotionController;
import three_extra.motion_controllers.MotionControllerConstants;
import three_extra.motion_controllers.fetchProfile;

class XRControllerModel extends Object3D {

	public var motionController:MotionController;
	public var envMap:Dynamic;

	public function new() {
		super();
		motionController = null;
		envMap = null;
	}

	public function setEnvironmentMap(envMap:Dynamic):XRControllerModel {
		if (this.envMap == envMap) {
			return this;
		}
		this.envMap = envMap;
		this.traverse(function(child) {
			if (Std.is(child, Mesh)) {
				child.material.envMap = this.envMap;
				child.material.needsUpdate = true;
			}
		});
		return this;
	}

	public override function updateMatrixWorld(force:Bool):Void {
		super.updateMatrixWorld(force);
		if (motionController == null) return;
		motionController.updateFromGamepad();
		for (component in motionController.components.values()) {
			for (visualResponse in component.visualResponses.values()) {
				var valueNode = visualResponse.valueNode;
				var minNode = visualResponse.minNode;
				var maxNode = visualResponse.maxNode;
				var value = visualResponse.value;
				var valueNodeProperty = visualResponse.valueNodeProperty;
				if (valueNode == null) continue;
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

class XRControllerModelFactory {

	public var gltfLoader:GLTFLoader;
	public var path:String;
	private var _assetCache:Map<String, Dynamic>;
	public var onLoad:Dynamic;

	public function new(gltfLoader:GLTFLoader = null, onLoad:Dynamic = null) {
		this.gltfLoader = gltfLoader;
		this.path = "https://cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0/dist/profiles";
		this._assetCache = new Map();
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
		controller.addEventListener("connected", function(event) {
			var xrInputSource = event.data;
			if (xrInputSource.targetRayMode != "tracked-pointer" || xrInputSource.gamepad == null) return;
			fetchProfile(xrInputSource, this.path, "generic-trigger").handle(function(data) {
				controllerModel.motionController = new MotionController(xrInputSource, data.profile, data.assetPath);
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
					this.gltfLoader.load(controllerModel.motionController.assetUrl, function(asset) {
						this._assetCache.set(controllerModel.motionController.assetUrl, asset);
						scene = asset.scene.clone();
						addAssetSceneToControllerModel(controllerModel, scene);
						if (this.onLoad != null) this.onLoad(scene);
					}, null, function() {
						throw new Error("Asset " + controllerModel.motionController.assetUrl + " missing or malformed.");
					});
				}
			}).catch(function(err) {
				trace(err);
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