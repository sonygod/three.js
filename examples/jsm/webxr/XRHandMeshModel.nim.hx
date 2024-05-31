import three.js.examples.jsm.loaders.GLTFLoader;

class Default {
	public static var HAND_PROFILE_PATH:String = 'https://cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0/dist/profiles/generic-hand/';
}

class XRHandMeshModel {

	public var controller:Dynamic;
	public var handModel:Dynamic;
	public var bones:Array<Dynamic>;

	public function new(handModel:Dynamic, controller:Dynamic, path:String, handedness:String, loader:GLTFLoader = null, onLoad:Dynamic = null) {

		this.controller = controller;
		this.handModel = handModel;

		this.bones = [];

		if (loader == null) {

			loader = new GLTFLoader();
			loader.setPath(path != null ? path : Default.HAND_PROFILE_PATH);

		}

		loader.load(handedness + ".glb", function(gltf:Dynamic) {

			var object:Dynamic = gltf.scene.children[0];
			handModel.add(object);

			var mesh:Dynamic = object.getObjectByProperty('type', 'SkinnedMesh');
			mesh.frustumCulled = false;
			mesh.castShadow = true;
			mesh.receiveShadow = true;

			var joints:Array<String> = [
				'wrist',
				'thumb-metacarpal',
				'thumb-phalanx-proximal',
				'thumb-phalanx-distal',
				'thumb-tip',
				'index-finger-metacarpal',
				'index-finger-phalanx-proximal',
				'index-finger-phalanx-intermediate',
				'index-finger-phalanx-distal',
				'index-finger-tip',
				'middle-finger-metacarpal',
				'middle-finger-phalanx-proximal',
				'middle-finger-phalanx-intermediate',
				'middle-finger-phalanx-distal',
				'middle-finger-tip',
				'ring-finger-metacarpal',
				'ring-finger-phalanx-proximal',
				'ring-finger-phalanx-intermediate',
				'ring-finger-phalanx-distal',
				'ring-finger-tip',
				'pinky-finger-metacarpal',
				'pinky-finger-phalanx-proximal',
				'pinky-finger-phalanx-intermediate',
				'pinky-finger-phalanx-distal',
				'pinky-finger-tip',
			];

			for (joint in joints) {

				var bone:Dynamic = object.getObjectByName(joint);

				if (bone != null) {

					bone.jointName = joint;

				} else {

					trace.warn("Couldn't find " + joint + " in " + handedness + " hand mesh");

				}

				this.bones.push(bone);

			}

			if (onLoad != null) onLoad(object);

		});

	}

	public function updateMesh() {

		// XR Joints
		var XRJoints:Dynamic = this.controller.joints;

		for (i in 0...this.bones.length) {

			var bone:Dynamic = this.bones[i];

			if (bone != null) {

				var XRJoint:Dynamic = XRJoints[bone.jointName];

				if (XRJoint.visible) {

					var position:Dynamic = XRJoint.position;

					bone.position.copy(position);
					bone.quaternion.copy(XRJoint.quaternion);
					// bone.scale.setScalar(XRJoint.jointRadius || defaultRadius);

				}

			}

		}

	}

}