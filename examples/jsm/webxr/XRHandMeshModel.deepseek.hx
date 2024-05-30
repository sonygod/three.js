import js.Lib;
import three.GLTFLoader;
import three.Object3D;
import three.Scene;
import three.SkinnedMesh;

class XRHandMeshModel {

    static var DEFAULT_HAND_PROFILE_PATH:String = 'https://cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0/dist/profiles/generic-hand/';

    var controller:Dynamic;
    var handModel:Dynamic;
    var bones:Array<Dynamic>;

    public function new(handModel:Dynamic, controller:Dynamic, path:String, handedness:String, loader:GLTFLoader = null, onLoad:Dynamic = null) {

        this.controller = controller;
        this.handModel = handModel;
        this.bones = [];

        if (loader == null) {

            loader = new GLTFLoader();
            loader.setPath(path != null ? path : DEFAULT_HAND_PROFILE_PATH);

        }

        loader.load(`${handedness}.glb`, function(gltf:Dynamic) {

            var object:Object3D = cast(gltf.scene.children[0], Object3D);
            this.handModel.add(object);

            var mesh:SkinnedMesh = cast(object.getObjectByProperty('type', 'SkinnedMesh'), SkinnedMesh);
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

            for (jointName in joints) {

                var bone = object.getObjectByName(jointName);

                if (bone != null) {

                    js.Lib.setProperty(bone, 'jointName', jointName);

                } else {

                    trace(`Couldn't find ${jointName} in ${handedness} hand mesh`);

                }

                this.bones.push(bone);

            }

            if (onLoad != null) onLoad(object);

        });

    }

    public function updateMesh() {

        // XR Joints
        var XRJoints:Dynamic = this.controller.joints;

        for (i in this.bones) {

            var bone = this.bones[i];

            if (bone != null) {

                var XRJoint:Dynamic = js.Lib.getProperty(XRJoints, bone.jointName);

                if (js.Lib.getProperty(XRJoint, 'visible')) {

                    var position:Dynamic = js.Lib.getProperty(XRJoint, 'position');

                    js.Lib.setProperty(bone.position, 'copy', position);
                    js.Lib.setProperty(bone.quaternion, 'copy', js.Lib.getProperty(XRJoint, 'quaternion'));
                    // bone.scale.setScalar(js.Lib.getProperty(XRJoint, 'jointRadius') != null ? js.Lib.getProperty(XRJoint, 'jointRadius') : defaultRadius);

                }

            }

        }

    }

}