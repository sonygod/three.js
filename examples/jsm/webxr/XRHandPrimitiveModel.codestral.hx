import three.core.BufferGeometry;
import three.geometries.SphereGeometry;
import three.geometries.BoxGeometry;
import three.materials.MeshStandardMaterial;
import three.objects.InstancedMesh;
import three.math.Matrix4;
import three.math.Vector3;

class XRHandPrimitiveModel {

    var controller:Dynamic;
    var handModel:Dynamic;
    var envMap:Dynamic = null;
    var handMesh:InstancedMesh;
    var joints:Array<String>;

    public function new(handModel:Dynamic, controller:Dynamic, path:String, handedness:String, options:Dynamic) {

        this.controller = controller;
        this.handModel = handModel;

        var geometry:BufferGeometry;

        if (options == null || options.primitive == null || options.primitive == "sphere") {

            geometry = new SphereGeometry(1.0, 10, 10);

        } else if (options.primitive == "box") {

            geometry = new BoxGeometry(1.0, 1.0, 1.0);

        }

        var material = new MeshStandardMaterial();

        this.handMesh = new InstancedMesh(geometry, material, 30);
        this.handMesh.frustumCulled = false;
        this.handMesh.instanceMatrix.setUsage(three.core.DynamicDrawUsage);
        this.handMesh.castShadow = true;
        this.handMesh.receiveShadow = true;
        this.handModel.add(this.handMesh);

        this.joints = [
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
            "pinky-finger-tip"
        ];
    }

    public function updateMesh():Void {

        var defaultRadius = 0.008;
        var joints = this.controller.joints;
        var _matrix = new Matrix4();
        var _vector = new Vector3();

        var count = 0;

        for (var i = 0; i < this.joints.length; i++) {

            var joint = joints[this.joints[i]];

            if (joint.visible) {

                _vector.setScalar(joint.jointRadius != null ? joint.jointRadius : defaultRadius);
                _matrix.compose(joint.position, joint.quaternion, _vector);
                this.handMesh.setMatrixAt(i, _matrix);

                count++;

            }

        }

        this.handMesh.count = count;
        this.handMesh.instanceMatrix.needsUpdate = true;

    }

}