package three.js.examples.jvm.webxr;

import three.js.lib.Matrix4;
import three.js.lib.Vector3;
import three.js.lib.geometries.SphereGeometry;
import three.js.lib.geometries.BoxGeometry;
import three.js.lib.materials.MeshStandardMaterial;
import three.js.lib.meshes.InstancedMesh;
import three.js.lib.DynamicDrawUsage;

class XRHandPrimitiveModel {
    public var controller:Dynamic;
    public var handModel:Dynamic;
    public var envMap:Null<Dynamic>;
    private var handMesh:InstancedMesh;
    private var joints:Array<String>;

    private var _matrix:Matrix4;
    private var _vector:Vector3;

    public function new(handModel:Dynamic, controller:Dynamic, path:Dynamic, handedness:Dynamic, options:Dynamic = null) {
        _matrix = new Matrix4();
        _vector = new Vector3();

        this.controller = controller;
        this.handModel = handModel;
        this.envMap = null;

        var geometry:Geometry;

        if (options == null || !options.primitive || options.primitive == 'sphere') {
            geometry = new SphereGeometry(1, 10, 10);
        } else if (options.primitive == 'box') {
            geometry = new BoxGeometry(1, 1, 1);
        }

        var material:MeshStandardMaterial = new MeshStandardMaterial();

        handMesh = new InstancedMesh(geometry, material, 30);
        handMesh.frustumCulled = false;
        handMesh.instanceMatrix.setUsage(DynamicDrawUsage); // will be updated every frame
        handMesh.castShadow = true;
        handMesh.receiveShadow = true;
        handModel.add(handMesh);

        joints = [
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
    }

    public function updateMesh() {
        var defaultRadius:Float = 0.008;
        var joints:Array<Dynamic> = controller.joints;

        var count:Int = 0;

        for (i in 0...joints.length) {
            var joint:Dynamic = joints[joints[i]];

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