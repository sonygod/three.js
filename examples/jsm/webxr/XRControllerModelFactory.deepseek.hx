import three.Mesh;
import three.MeshBasicMaterial;
import three.Object3D;
import three.SphereGeometry;

import js.Lib.GLTFLoader;

import js.Lib.Constants as MotionControllerConstants;
import js.Lib.fetchProfile;
import js.Lib.MotionController;

class XRControllerModel extends Object3D {

	var motionController:MotionController;
	var envMap:Dynamic;

	public function new() {
		super();
		motionController = null;
		envMap = null;
	}

	public function setEnvironmentMap(envMap:Dynamic):XRControllerModel {
		if (this.envMap == envMap) return this;
		this.envMap = envMap;
		this.traverse(function(child) {
			if (child.isMesh) {
				child.material.envMap = this.envMap;
				child.material.needsUpdate = true;
			}
		});
		return this;
	}

	public function updateMatrixWorld(force:Bool):Void {
		super.updateMatrixWorld(force);
		if (!this.motionController) return;
		this.motionController.updateFromGamepad();
		for (component in this.motionController.components) {
			for (visualResponse in component.visualResponses) {
				var valueNode = visualResponse.valueNode;
				var minNode = visualResponse.minNode;
				var maxNode = visualResponse.maxNode;
				var value = visualResponse.value;
				var valueNodeProperty = visualResponse.valueNodeProperty;
				if (!valueNode) continue;
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

	var gltfLoader:GLTFLoader;
	var path:String;
	var _assetCache:Dynamic;
	var onLoad:Dynamic->Void;

	public function new(gltfLoader:GLTFLoader = null, onLoad:Dynamic->Void = null) {
		this.gltfLoader = gltfLoader ? gltfLoader : new GLTFLoader();
		this.path = "https://cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0/dist/profiles";
		this._assetCache = {};
		this.onLoad = onLoad;
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
			if (xrInputSource.targetRayMode != "tracked-pointer" || !xrInputSource.gamepad) return;
			fetchProfile(xrInputSource, this.path, "generic-trigger").then(function(profileData) {
				var profile = profileData.profile;
				var assetPath = profileData.assetPath;
				controllerModel.motionController = new MotionController(xrInputSource, profile, assetPath);
				var cachedAsset = this._assetCache[controllerModel.motionController.assetUrl];
				if (cachedAsset) {
					scene = cachedAsset.scene.clone();
					addAssetSceneToControllerModel(controllerModel, scene);
					if (this.onLoad) this.onLoad(scene);
				} else {
					if (!this.gltfLoader) throw "GLTFLoader not set.";
					this.gltfLoader.setPath("");
					this.gltfLoader.load(controllerModel.motionController.assetUrl, function(asset) {
						this._assetCache[controllerModel.motionController.assetUrl] = asset;
						scene = asset.scene.clone();
						addAssetSceneToControllerModel(controllerModel, scene);
						if (this.onLoad) this.onLoad(scene);
					}, null, function() {
						throw "Asset " + controllerModel.motionController.assetUrl + " missing or malformed.";
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