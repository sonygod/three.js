import three.DynamicDrawUsage;
import three.SphereGeometry;
import three.BoxGeometry;
import three.MeshStandardMaterial;
import three.InstancedMesh;
import three.Matrix4;
import three.Vector3;

class XRHandPrimitiveModel {

    static var _matrix:Matrix4 = new Matrix4();
    static var _vector:Vector3 = new Vector3();

    var controller:Dynamic;
    var handModel:Dynamic;
    var envMap:Dynamic;
    var handMesh:InstancedMesh;
    var joints:Array<String>;

    public function new(handModel:Dynamic, controller:Dynamic, path:String, handedness:String, options:Dynamic) {

        this.controller = controller;
        this.handModel = handModel;
        this.envMap = null;

        var geometry:Dynamic;

        if (!options || !options.primitive || options.primitive == 'sphere') {

            geometry = new SphereGeometry(1, 10, 10);

        } else if (options.primitive == 'box') {

            geometry = new BoxGeometry(1, 1, 1);

        }

        var material = new MeshStandardMaterial();

        this.handMesh = new InstancedMesh(geometry, material, 30);
        this.handMesh.frustumCulled = false;
        this.handMesh.instanceMatrix.setUsage(DynamicDrawUsage); // will be updated every frame
        this.handMesh.castShadow = true;
        this.handMesh.receiveShadow = true;
        this.handModel.add(this.handMesh);

        this.joints = [
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

    public function updateMesh():Void {

        var defaultRadius:Float = 0.008;
        var joints:Dynamic = this.controller.joints;

        var count:Int = 0;

        for (i in 0...this.joints.length) {

            var joint:Dynamic = joints[this.joints[i]];

            if (joint.visible) {

                _vector.setScalar(joint.jointRadius || defaultRadius);
                _matrix.compose(joint.position, joint.quaternion, _vector);
                this.handMesh.setMatrixAt(i, _matrix);

                count++;

            }

        }

        this.handMesh.count = count;
        this.handMesh.instanceMatrix.needsUpdate = true;

    }

}