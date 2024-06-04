import three.Object3D;
import three.Sphere;
import three.Box3;
import XRHandMeshModel from "./XRHandMeshModel";

class OculusHandModel extends Object3D {

	public var controller:Dynamic;
	public var motionController:XRHandMeshModel;
	public var envMap:Dynamic;
	public var loader:Dynamic;
	public var onLoad:Dynamic;

	public var mesh:Dynamic;

	public function new(controller:Dynamic, loader:Dynamic = null, onLoad:Dynamic = null) {
		super();
		this.controller = controller;
		this.motionController = null;
		this.envMap = null;
		this.loader = loader;
		this.onLoad = onLoad;

		this.mesh = null;

		controller.addEventListener('connected', function(event:Dynamic) {
			var xrInputSource = event.data;

			if (xrInputSource.hand && this.motionController == null) {
				this.xrInputSource = xrInputSource;

				this.motionController = new XRHandMeshModel(this, controller, this.path, xrInputSource.handedness, this.loader, this.onLoad);
			}
		});

		controller.addEventListener('disconnected', function() {
			this.clear();
			this.motionController = null;
		});
	}

	public function updateMatrixWorld(force:Bool = false):Void {
		super.updateMatrixWorld(force);

		if (this.motionController != null) {
			this.motionController.updateMesh();
		}
	}

	public function getPointerPosition():Dynamic {
		var indexFingerTip = this.controller.joints['index-finger-tip'];
		if (indexFingerTip != null) {
			return indexFingerTip.position;
		} else {
			return null;
		}
	}

	public function intersectBoxObject(boxObject:Dynamic):Bool {
		var pointerPosition = this.getPointerPosition();
		if (pointerPosition != null) {
			var indexSphere = new Sphere(pointerPosition, 0.01);
			var box = new Box3().setFromObject(boxObject);
			return indexSphere.intersectsBox(box);
		} else {
			return false;
		}
	}

	public function checkButton(button:Dynamic):Void {
		if (this.intersectBoxObject(button)) {
			button.onPress();
		} else {
			button.onClear();
		}

		if (button.isPressed()) {
			button.whilePressed();
		}
	}

	private function clear():Void {
		// Implement clear logic here
	}

	private var xrInputSource:Dynamic;

	private var path:String = ""; // Assuming you have a path property for the model

}