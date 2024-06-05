import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.Line;
import three.LineBasicMaterial;
import three.Matrix4;
import three.Mesh;
import three.MeshBasicMaterial;
import three.Object3D;
import three.Quaternion;
import three.SphereGeometry;
import three.Vector3;

class CCDIKSolver {

    var mesh:three.SkinnedMesh;
    var iks:Array<Dynamic>;

    public function new(mesh:three.SkinnedMesh, iks:Array<Dynamic> = []) {
        this.mesh = mesh;
        this.iks = iks;
        this._valid();
    }

    public function update():CCDIKSolver {
        for (i in 0...this.iks.length) {
            this.updateOne(this.iks[i]);
        }
        return this;
    }

    public function updateOne(ik:Dynamic):CCDIKSolver {
        var bones = this.mesh.skeleton.bones;
        var effector = bones[ik.effector];
        var target = bones[ik.target];
        var links = ik.links;
        var iteration = ik.iteration !== undefined ? ik.iteration : 1;
        var _q = new Quaternion();
        var _targetPos = new Vector3();
        var _targetVec = new Vector3();
        var _effectorPos = new Vector3();
        var _effectorVec = new Vector3();
        var _linkPos = new Vector3();
        var _invLinkQ = new Quaternion();
        var _linkScale = new Vector3();
        var _axis = new Vector3();
        var _vector = new Vector3();
        var _matrix = new Matrix4();

        _targetPos.setFromMatrixPosition(target.matrixWorld);

        for (var i = 0; i < iteration; i++) {
            var rotated = false;

            for (var j = 0; j < links.length; j++) {
                if (links[j].enabled === false) break;

                var link = bones[links[j].index];
                var limitation = links[j].limitation;
                var rotationMin = links[j].rotationMin;
                var rotationMax = links[j].rotationMax;

                link.matrixWorld.decompose(_linkPos, _invLinkQ, _linkScale);
                _invLinkQ.invert();
                _effectorPos.setFromMatrixPosition(effector.matrixWorld);

                _effectorVec.subVectors(_effectorPos, _linkPos).applyQuaternion(_invLinkQ).normalize();
                _targetVec.subVectors(_targetPos, _linkPos).applyQuaternion(_invLinkQ).normalize();

                var angle = _targetVec.dot(_effectorVec);
                if (angle > 1.0) angle = 1.0;
                else if (angle < -1.0) angle = -1.0;

                angle = Math.acos(angle);

                if (angle < 1e-5) continue;
                if (ik.minAngle !== undefined && angle < ik.minAngle) angle = ik.minAngle;
                if (ik.maxAngle !== undefined && angle > ik.maxAngle) angle = ik.maxAngle;

                _axis.crossVectors(_effectorVec, _targetVec).normalize();
                _q.setFromAxisAngle(_axis, angle);
                link.quaternion.multiply(_q);

                if (limitation !== undefined) {
                    var c = link.quaternion.w;
                    if (c > 1.0) c = 1.0;
                    var c2 = Math.sqrt(1 - c * c);
                    link.quaternion.set(limitation.x * c2, limitation.y * c2, limitation.z * c2, c);
                }

                if (rotationMin !== undefined) {
                    link.rotation.setFromVector3(_vector.setFromEuler(link.rotation).max(rotationMin));
                }

                if (rotationMax !== undefined) {
                    link.rotation.setFromVector3(_vector.setFromEuler(link.rotation).min(rotationMax));
                }

                link.updateMatrixWorld(true);
                rotated = true;
            }

            if (!rotated) break;
        }

        return this;
    }

    public function createHelper(sphereSize:Float):CCDIKHelper {
        return new CCDIKHelper(this.mesh, this.iks, sphereSize);
    }

    private function _valid() {
        var iks = this.iks;
        var bones = this.mesh.skeleton.bones;

        for (var i = 0; i < iks.length; i++) {
            var ik = iks[i];
            var effector = bones[ik.effector];
            var links = ik.links;
            var link0 = effector;

            for (var j = 0; j < links.length; j++) {
                var link1 = bones[links[j].index];
                if (link0.parent !== link1) {
                    trace('THREE.CCDIKSolver: bone ' + link0.name + ' is not the child of bone ' + link1.name);
                }
                link0 = link1;
            }
        }
    }
}

class CCDIKHelper extends Object3D {

    var root:three.SkinnedMesh;
    var iks:Array<Dynamic>;
    var sphereGeometry:SphereGeometry;
    var targetSphereMaterial:MeshBasicMaterial;
    var effectorSphereMaterial:MeshBasicMaterial;
    var linkSphereMaterial:MeshBasicMaterial;
    var lineMaterial:LineBasicMaterial;

    public function new(mesh:three.SkinnedMesh, iks:Array<Dynamic> = [], sphereSize:Float = 0.25) {
        super();
        this.root = mesh;
        this.iks = iks;
        this.matrix.copy(mesh.matrixWorld);
        this.matrixAutoUpdate = false;
        this.sphereGeometry = new SphereGeometry(sphereSize, 16, 8);
        this.targetSphereMaterial = new MeshBasicMaterial({color: new Color(0xff8888), depthTest: false, depthWrite: false, transparent: true});
        this.effectorSphereMaterial = new MeshBasicMaterial({color: new Color(0x88ff88), depthTest: false, depthWrite: false, transparent: true});
        this.linkSphereMaterial = new MeshBasicMaterial({color: new Color(0x8888ff), depthTest: false, depthWrite: false, transparent: true});
        this.lineMaterial = new LineBasicMaterial({color: new Color(0xff0000), depthTest: false, depthWrite: false, transparent: true});
        this._init();
    }

    public function updateMatrixWorld(force:Bool) {
        var mesh = this.root;
        if (this.visible) {
            var offset = 0;
            var iks = this.iks;
            var bones = mesh.skeleton.bones;
            var _matrix = new Matrix4().copy(mesh.matrixWorld).invert();

            for (var i = 0; i < iks.length; i++) {
                var ik = iks[i];
                var targetBone = bones[ik.target];
                var effectorBone = bones[ik.effector];
                var targetMesh = this.children[offset++];
                var effectorMesh = this.children[offset++];
                targetMesh.position.copy(getPosition(targetBone, _matrix));
                effectorMesh.position.copy(getPosition(effectorBone, _matrix));

                for (var j = 0; j < ik.links.length; j++) {
                    var link = ik.links[j];
                    var linkBone = bones[link.index];
                    var linkMesh = this.children[offset++];
                    linkMesh.position.copy(getPosition(linkBone, _matrix));
                }

                var line = this.children[offset++];
                var array = line.geometry.attributes.position.array;
                setPositionOfBoneToAttributeArray(array, 0, targetBone, _matrix);
                setPositionOfBoneToAttributeArray(array, 1, effectorBone, _matrix);

                for (var j = 0; j < ik.links.length; j++) {
                    var link = ik.links[j];
                    var linkBone = bones[link.index];
                    setPositionOfBoneToAttributeArray(array, j + 2, linkBone, _matrix);
                }

                line.geometry.attributes.position.needsUpdate = true;
            }
        }

        this.matrix.copy(mesh.matrixWorld);
        super.updateMatrixWorld(force);
    }

    public function dispose() {
        this.sphereGeometry.dispose();
        this.targetSphereMaterial.dispose();
        this.effectorSphereMaterial.dispose();
        this.linkSphereMaterial.dispose();
        this.lineMaterial.dispose();
        for (child in this.children) {
            if (child.isLine) child.geometry.dispose();
        }
    }

    private function _init() {
        var scope = this;
        var iks = this.iks;

        function createLineGeometry(ik:Dynamic):BufferGeometry {
            var geometry = new BufferGeometry();
            var vertices = new Float32Array((2 + ik.links.length) * 3);
            geometry.setAttribute('position', new BufferAttribute(vertices, 3));
            return geometry;
        }

        function createTargetMesh():Mesh {
            return new Mesh(scope.sphereGeometry, scope.targetSphereMaterial);
        }

        function createEffectorMesh():Mesh {
            return new Mesh(scope.sphereGeometry, scope.effectorSphereMaterial);
        }

        function createLinkMesh():Mesh {
            return new Mesh(scope.sphereGeometry, scope.linkSphereMaterial);
        }

        function createLine(ik:Dynamic):Line {
            return new Line(createLineGeometry(ik), scope.lineMaterial);
        }

        for (var i = 0; i < iks.length; i++) {
            var ik = iks[i];
            this.add(createTargetMesh());
            this.add(createEffectorMesh());

            for (var j = 0; j < ik.links.length; j++) {
                this.add(createLinkMesh());
            }

            this.add(createLine(ik));
        }
    }
}

function getPosition(bone:three.Bone, matrixWorldInv:Matrix4):Vector3 {
    return new Vector3().setFromMatrixPosition(bone.matrixWorld).applyMatrix4(matrixWorldInv);
}

function setPositionOfBoneToAttributeArray(array:Float32Array, index:Int, bone:three.Bone, matrixWorldInv:Matrix4) {
    var v = getPosition(bone, matrixWorldInv);
    array[index * 3 + 0] = v.x;
    array[index * 3 + 1] = v.y;
    array[index * 3 + 2] = v.z;
}