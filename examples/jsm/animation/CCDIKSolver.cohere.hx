import js.three.BufferAttribute;
import js.three.BufferGeometry;
import js.three.Color;
import js.three.Line;
import js.three.LineBasicMaterial;
import js.three.Matrix4;
import js.three.Mesh;
import js.three.MeshBasicMaterial;
import js.three.Object3D;
import js.three.Quaternion;
import js.three.SphereGeometry;
import js.three.Vector3;

class CCDIKSolver {
    var mesh:SkinnedMesh;
    var iks:Array<Dynamic>;
    public function new(mesh:SkinnedMesh, iks:Array<Dynamic>) {
        this.mesh = mesh;
        this.iks = iks;
        _valid();
    }
    public function update():CCDIKSolver {
        for (i in 0...iks.length) {
            updateOne(iks[i]);
        }
        return this;
    }
    public function updateOne(ik:Dynamic):CCDIKSolver {
        var bones = mesh.skeleton.bones;
        var math = Math.instance;
        var effector = bones[ik.effector];
        var target = bones[ik.target];
        var _targetPos = new Vector3();
        _targetPos.setFromMatrixPosition(target.matrixWorld);
        var links = ik.links;
        var iteration = if (ik.iteration != null) ik.iteration else 1;
        for (i in 0...iteration) {
            var rotated = false;
            for (j in 0...links.length) {
                var link = bones[links[j].index];
                if (links[j].enabled == false) {
                    break;
                }
                var limitation = links[j].limitation;
                var rotationMin = links[j].rotationMin;
                var rotationMax = links[j].rotationMax;
                var _linkPos = new Vector3();
                var _invLinkQ = new Quaternion();
                var _effectorPos = new Vector3();
                link.matrixWorld.decompose(_linkPos, _invLinkQ, _linkScale);
                _invLinkQ.invert();
                _effectorPos.setFromMatrixPosition(effector.matrixWorld);
                var _effectorVec = new Vector3();
                _effectorVec.subVectors(_effectorPos, _linkPos);
                _effectorVec.applyQuaternion(_invLinkQ);
                _effectorVec.normalize();
                var _targetVec = new Vector3();
                _targetVec.subVectors(_targetPos, _linkPos);
                _targetVec.applyQuaternion(_invLinkQ);
                _targetVec.normalize();
                var angle = _targetVec.dot(_effectorVec);
                if (angle > 1.0) {
                    angle = 1.0;
                } else if (angle < -1.0) {
                    angle = -1.0;
                }
                angle = math.acos(angle);
                if (angle < 1e-5) {
                    continue;
                }
                if (ik.minAngle != null && angle < ik.minAngle) {
                    angle = ik.minAngle;
                }
                if (ik.maxAngle != null && angle > ik.maxAngle) {
                    angle = ik.maxAngle;
                }
                var _axis = new Vector3();
                _axis.crossVectors(_effectorVec, _targetVec);
                _axis.normalize();
                var _q = new Quaternion();
                _q.setFromAxisAngle(_axis, angle);
                link.quaternion.multiply(_q);
                if (limitation != null) {
                    var c = link.quaternion.w;
                    if (c > 1.0) {
                        c = 1.0;
                    }
                    var c2 = math.sqrt(1 - c * c);
                    link.quaternion.set(limitation.x * c2, limitation.y * c2, limitation.z * c2, c);
                }
                if (rotationMin != null) {
                    var _vector = new Vector3();
                    link.rotation.setFromVector3(_vector.setFromEuler(link.rotation).max(rotationMin));
                }
                if (rotationMax != null) {
                    var _vector = new Vector3();
                    link.rotation.setFromVector3(_vector.setFromEuler(link.rotation).min(rotationMax));
                }
                link.updateMatrixWorld(true);
                rotated = true;
            }
            if (!rotated) {
                break;
            }
        }
        return this;
    }
    public function createHelper(sphereSize:Float):CCDIKHelper {
        return new CCDIKHelper(mesh, iks, sphereSize);
    }
    private function _valid() {
        for (i in 0...iks.length) {
            var ik = iks[i];
            var effector = mesh.skeleton.bones[ik.effector];
            var links = ik.links;
            var link0 = effector;
            for (j in 0...links.length) {
                var link1 = mesh.skeleton.bones[links[j].index];
                if (link0.parent != link1) {
                    trace("CCDIKSolver: bone " + link0.name + " is not the child of bone " + link1.name);
                }
                link0 = link1;
            }
        }
    }
    static function getPosition(bone:Dynamic, matrixWorldInv:Dynamic):Vector3 {
        var _vector = new Vector3();
        _vector.setFromMatrixPosition(bone.matrixWorld);
        _vector.applyMatrix4(matrixWorldInv);
        return _vector;
    }
    static function setPositionOfBoneToAttributeArray(array:Float32Array, index:Int, bone:Dynamic, matrixWorldInv:Dynamic):Void {
        var v = getPosition(bone, matrixWorldInv);
        array[index * 3] = v.x;
        array[index * 3 + 1] = v.y;
        array[index * 3 + 2] = v.z;
    }
}

class CCDIKHelper extends Object3D {
    var root:SkinnedMesh;
    var iks:Array<Dynamic>;
    var sphereSize:Float;
    var sphereGeometry:SphereGeometry;
    var targetSphereMaterial:MeshBasicMaterial;
    var effectorSphereMaterial:MeshBasicMaterial;
    var linkSphereMaterial:MeshBasicMaterial;
    var lineMaterial:LineBasicMaterial;
    public function new(mesh:SkinnedMesh, iks:Array<Dynamic>, sphereSize:Float) {
        super();
        this.root = mesh;
        this.iks = iks;
        this.sphereSize = if (sphereSize != null) sphereSize else 0.25;
        this.sphereGeometry = new SphereGeometry(sphereSize, 16, 8);
        this.targetSphereMaterial = new MeshBasicMaterial({ color: new Color(0xff8888), depthTest: false, depthWrite: false, transparent: true });
        this.effectorSphereMaterial = new MeshBasicMaterial({ color: new Color(0x88ff88), depthTest: false, depthWrite: false, transparent: true });
        this.linkSphereMaterial = new MeshBasicMaterial({ color: new Color(0x8888ff), depthTest: false, depthWrite: false, transparent: true });
        this.lineMaterial = new LineBasicMaterial({ color: new Color(0xff0000), depthTest: false, depthWrite: false, transparent: true });
        _init();
    }
    override function updateMatrixWorld(force:Bool) {
        var mesh = this.root;
        if (this.visible) {
            var offset = 0;
            var _matrix = new Matrix4();
            _matrix.copy(mesh.matrixWorld).invert();
            for (i in 0...iks.length) {
                var ik = iks[i];
                var targetBone = mesh.skeleton.bones[ik.target];
                var effectorBone = mesh.skeleton.bones[ik.effector];
                var targetMesh = this.children[offset++];
                var effectorMesh = this.children[offset++];
                targetMesh.position.copy(getPosition(targetBone, _matrix));
                effectorMesh.position.copy(getPosition(effectorBone, _matrix));
                for (j in 0...ik.links.length) {
                    var link = ik.links[j];
                    var linkBone = mesh.skeleton.bones[link.index];
                    var linkMesh = this.children[offset++];
                    linkMesh.position.copy(getPosition(linkBone, _matrix));
                }
                var line = this.children[offset++];
                var array = line.geometry.attributes.position.array;
                setPositionOfBoneToAttributeArray(array, 0, targetBone, _matrix);
                setPositionOfBoneToAttributeArray(array, 1, effectorBone, _matrix);
                for (j in 0...ik.links.length) {
                    var link = ik.links[j];
                    var linkBone = mesh.skeleton.bones[link.index];
                    setPositionOfBoneToAttributeArray(array, j + 2, linkBone, _matrix);
                }
                line.geometry.attributes.position.needsUpdate = true;
            }
        }
        this.matrix.copy(mesh.matrixWorld);
        super.updateMatrixWorld(force);
    }
    public function dispose():Void {
        sphereGeometry.dispose();
        targetSphereMaterial.dispose();
        effectorSphereMaterial.dispose();
        linkSphereMaterial.dispose();
        lineMaterial.dispose();
        for (i in 0...children.length) {
            var child = children[i];
            if (child is Line) {
                child.geometry.dispose();
            }
        }
    }
    private function _init():Void {
        var scope = this;
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
        for (i in 0...iks.length) {
            var ik = iks[i];
            this.add(createTargetMesh());
            this.add(createEffectorMesh());
            for (j in 0...ik.links.length) {
                this.add(createLinkMesh());
            }
            this.add(createLine(ik));
        }
    }
}