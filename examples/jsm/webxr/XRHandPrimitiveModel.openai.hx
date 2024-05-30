package three.js.examples.webxr;

import three.js.DynamicDrawUsage;
import three.js.SphereGeometry;
import three.js.BoxGeometry;
import three.js.MeshStandardMaterial;
import three.js.InstancedMesh;
import three.js.Matrix4;
import three.js.Vector3;

class XRHandPrimitiveModel {

    private var controller:Controller;
    private var handModel:HandModel;
    private var envMap:Null<Texture> = null;
    private var handMesh:InstancedMesh;

    private var joints:Array<String> = [
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

    private var _matrix:Matrix4 = new Matrix4();
    private var _vector:Vector3 = new Vector3();

    public function new(handModel:HandModel, controller:Controller, path:String, handedness:String, options:Dynamic = null) {
        this.controller = controller;
        this.handModel = handModel;

        var geometry:Geometry;
        if (options == null || options.primitive == null || options.primitive == 'sphere') {
            geometry = new SphereGeometry(1, 10, 10);
        } else if (options.primitive == 'box') {
            geometry = new BoxGeometry(1, 1, 1);
        }

        var material:MeshStandardMaterial = new MeshStandardMaterial();
        handMesh = new InstancedMesh(geometry, material, 30);
        handMesh.frustumCulled = false;
        handMesh.instanceMatrix.setUsage(DynamicDrawUsage);
        handMesh.castShadow = true;
        handMesh.receiveShadow = true;
        handModel.add(handMesh);
    }

    public function updateMesh() {
        var defaultRadius:Float = 0.008;
        var joints:Array<Joint> = controller.joints;
        var count:Int = 0;

        for (i in 0...joints.length) {
            var joint:Joint = joints[joints[i]];
            if (joint.visible) {
                _vector.setScalar(joint.jointRadius != null ? joint.jointRadius : defaultRadius);
                _matrix.compose(joint.position, joint.quaternion, _vector);
                handMesh.setMatrixAt(i, _matrix);
                count++;
            }
        }

        handMesh.count = count;
        handMesh.instanceMatrix.needsUpdate = true;
    }
}