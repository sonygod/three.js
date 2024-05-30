import h3d.impl.GLTFParser;
import h3d.impl.GLTFModel;
import js.Browser.XmlHttpRequest;
import js.html.TextDecoder;

class XRHandMeshModel {
    var controller:Dynamic;
    var handModel:Dynamic;
    var bones:Array<Dynamic>;

    public function new(handModel:Dynamic, controller:Dynamic, ?path:String, handedness:String, ?loader:GLTFParser, ?onLoad:Dynamic->Void) {
        if (loader == null) {
            loader = GLTFParser.fromFile(path ?? 'https://cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0/dist/profiles/generic-hand/');
        }

        loader.loadBytes(handedness ~ '.glb', function(gltf:GLTFModel) {
            var object = gltf.scene.children[0];
            handModel.add(object);

            var mesh = null;
            for (obj in object.children) {
                if (obj.type == 'SkinnedMesh') {
                    mesh = obj;
                    break;
                }
            }

            mesh.frustumCulled = false;
            mesh.castShadow = true;
            mesh.receiveShadow = true;

            var joints = [
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
                'pinky-finger-tip'
            ];

            for (jointName in joints) {
                var bone = object.getObjectByName(jointName);
                if (bone != null) {
                    bone.jointName = jointName;
                } else {
                    trace('Couldn\'t find $jointName in $handedness hand mesh');
                }
                bones.push(bone);
            }

            if (onLoad != null) onLoad(object);
        });

        this.controller = controller;
        this.handModel = handModel;
        this.bones = [];
    }

    public function updateMesh() {
        var XRJoints = controller.joints;
        for (i in 0...bones.length) {
            var bone = bones[i];
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