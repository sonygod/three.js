import three.Object3D;
import three.examples.jsm.webxr.XRHandPrimitiveModel;
import three.examples.jsm.webxr.XRHandMeshModel;

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

	public function updateMatrixWorld(force:Bool):Void {
		super.updateMatrixWorld(force);
		if (this.motionController != null) {
			this.motionController.updateMesh();
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

	public function setPath(path:Dynamic):XRHandModelFactory {
		this.path = path;
		return this;
	}

	public function createHandModel(controller:Dynamic, profile:Dynamic):XRHandModel {
		var handModel = new XRHandModel(controller);
		controller.addEventListener('connected', function(event:Dynamic) {
			var xrInputSource = event.data;
			if (xrInputSource.hand && handModel.motionController == null) {
				handModel.xrInputSource = xrInputSource;
				if (profile == null || profile == 'spheres') {
					handModel.motionController = new XRHandPrimitiveModel(handModel, controller, this.path, xrInputSource.handedness, {primitive: 'sphere'});
				} else if (profile == 'boxes') {
					handModel.motionController = new XRHandPrimitiveModel(handModel, controller, this.path, xrInputSource.handedness, {primitive: 'box'});
				} else if (profile == 'mesh') {
					handModel.motionController = new XRHandMeshModel(handModel, controller, this.path, xrInputSource.handedness, this.gltfLoader, this.onLoad);
				}
			}
			controller.visible = true;
		});
		controller.addEventListener('disconnected', function() {
			controller.visible = false;
		});
		return handModel;
	}
}