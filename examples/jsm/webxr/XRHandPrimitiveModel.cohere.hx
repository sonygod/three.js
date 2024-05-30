import js.threesjs.math.Matrix4;
import js.threesjs.math.Vector3;
import js.threesjs.objects.InstancedMesh;
import js.threesjs.objects.MeshStandardMaterial;
import js.threesjs.objects.SphereGeometry;
import js.threesjs.objects.BoxGeometry;

class XRHandPrimitiveModel {
    var controller:Dynamic;
    var handModel:Dynamic;
    var envMap:Dynamic;
    var handMesh:InstancedMesh;
    var joints:Array<String>;

    public function new(handModel:Dynamic, controller:Dynamic, path:Dynamic, handedness:Dynamic, ?options:Dynamic) {
        this.controller = controller;
        this.handModel = handModel;
        this.envMap = null;

        var geometry:Dynamic;
        if (options == null || !options.primitive || options.primitive == "sphere") {
            geometry = new SphereGeometry(1, 10, 10);
        } else if (options.primitive == "box") {
            geometry = new BoxGeometry(1, 1, 1);
        }

        var material = new MeshStandardMaterial();

        this.handMesh = new InstancedMesh(geometry, material, 30);
        this.handMesh.frustumCulled = false;
        this.handMesh.instanceMatrix.setUsage(js.threesjs.constants.DynamicDrawUsage);
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

        var count = 0;
        for (i in 0...this.joints.length) {
            var joint = joints[$array[$iter]].cast<Dynamic>;

            if (joint.visible) {
                var _vector = new Vector3();
                _vector.setScalar(joint.jointRadius.default(defaultRadius));

                var _matrix = new Matrix4();
                _matrix.compose(joint.position, joint.quaternion, _vector);

                this.handMesh.setMatrixAt(i, _matrix);
                count++;
            }
        }

        this.handMesh.count = count;
        this.handMesh.instanceMatrix.needsUpdate = true;
    }
}