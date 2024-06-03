import js.Browser.document;
import js.lib.Function;
import js.lib.Array;
import js.lib.String;

// Import the GLTFLoader
// Note: You might need to create a Haxe extern for the GLTFLoader
class GLTFLoader {
    public function new() {}
    public function setPath(path: String) {}
    public function load(url: String, onLoad: Function) {}
}

class XRHandMeshModel {
    public var DEFAULT_HAND_PROFILE_PATH:String = "https://cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0/dist/profiles/generic-hand/";
    public var controller:Dynamic;
    public var handModel:Dynamic;
    public var bones:Array<Dynamic>;
    public var loader:GLTFLoader;

    public function new(handModel, controller, path, handedness, loader:GLTFLoader = null, onLoad:Function = null) {
        this.controller = controller;
        this.handModel = handModel;
        this.bones = new Array<Dynamic>();

        if (loader == null) {
            this.loader = new GLTFLoader();
            this.loader.setPath(path == null ? DEFAULT_HAND_PROFILE_PATH : path);
        } else {
            this.loader = loader;
        }

        var onLoadCallback = function(gltf) {
            var object = gltf.scene.children[0];
            this.handModel.add(object);

            var mesh = object.getObjectByProperty('type', 'SkinnedMesh');
            mesh.frustumCulled = false;
            mesh.castShadow = true;
            mesh.receiveShadow = true;

            var joints = [
                "wrist",
                "thumb-metacarpal",
                "thumb-phalanx-proximal",
                "thumb-phalanx-distal",
                "thumb-tip",
                "index-finger-metacarpal",
                "index-finger-phalanx-proximal",
                "index-finger-phalanx-intermediate",
                "index-finger-phalanx-distal",
                "index-finger-tip",
                "middle-finger-metacarpal",
                "middle-finger-phalanx-proximal",
                "middle-finger-phalanx-intermediate",
                "middle-finger-phalanx-distal",
                "middle-finger-tip",
                "ring-finger-metacarpal",
                "ring-finger-phalanx-proximal",
                "ring-finger-phalanx-intermediate",
                "ring-finger-phalanx-distal",
                "ring-finger-tip",
                "pinky-finger-metacarpal",
                "pinky-finger-phalanx-proximal",
                "pinky-finger-phalanx-intermediate",
                "pinky-finger-phalanx-distal",
                "pinky-finger-tip",
            ];

            for (jointName in joints) {
                var bone = object.getObjectByName(jointName);

                if (bone != null) {
                    bone.jointName = jointName;
                } else {
                    js.Browser.console.warn("Couldn't find " + jointName + " in " + handedness + " hand mesh");
                }

                this.bones.push(bone);
            }

            if (onLoad != null) onLoad(object);
        }

        this.loader.load(handedness + ".glb", onLoadCallback.bind(this));
    }

    public function updateMesh() {
        var XRJoints = this.controller.joints;

        for (i in 0...this.bones.length) {
            var bone = this.bones[i];

            if (bone != null) {
                var XRJoint = XRJoints[bone.jointName];

                if (XRJoint.visible) {
                    var position = XRJoint.position;

                    bone.position.copy(position);
                    bone.quaternion.copy(XRJoint.quaternion);
                    // bone.scale.setScalar(XRJoint.jointRadius || defaultRadius);
                }
            }
        }
    }
}

// Export the class
js.Boot.getClass(XRHandMeshModel).__name__ = "XRHandMeshModel";