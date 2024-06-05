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
    var _q:Quaternion = new Quaternion();
    var _targetPos:Vector3 = new Vector3();
    var _targetVec:Vector3 = new Vector3();
    var _effectorPos:Vector3 = new Vector3();
    var _effectorVec:Vector3 = new Vector3();
    var _linkPos:Vector3 = new Vector3();
    var _invLinkQ:Quaternion = new Quaternion();
    var _linkScale:Vector3 = new Vector3();
    var _axis:Vector3 = new Vector3();
    var _vector:Vector3 = new Vector3();
    var _matrix:Matrix4 = new Matrix4();

    var mesh:SkinnedMesh;
    var iks:Array<Dynamic>;

    public function new(mesh:SkinnedMesh, iks:Array<Dynamic> = []) {
        this.mesh = mesh;
        this.iks = iks;

        this._valid();
    }

    public function update():CCDIKSolver {
        for (ik in this.iks) {
            this.updateOne(ik);
        }

        return this;
    }

    public function updateOne(ik:Dynamic):CCDIKSolver {
        var bones = this.mesh.skeleton.bones;

        var effector = bones[ik.effector];
        var target = bones[ik.target];

        _targetPos.setFromMatrixPosition(target.matrixWorld);

        var links = ik.links;
        var iteration = ik.iteration != null ? ik.iteration : 1;

        for (i in 0...iteration) {
            var rotated = false;

            for (j in 0...links.length) {
                var link = bones[links[j].index];

                if (links[j].enabled == false) break;

                var limitation = links[j].limitation;
                var rotationMin = links[j].rotationMin;
                var rotationMax = links[j].rotationMax;

                link.matrixWorld.decompose(_linkPos, _invLinkQ, _linkScale);
                _invLinkQ.invert();
                _effectorPos.setFromMatrixPosition(effector.matrixWorld);

                _effectorVec.subVectors(_effectorPos, _linkPos);
                _effectorVec.applyQuaternion(_invLinkQ);
                _effectorVec.normalize();

                _targetVec.subVectors(_targetPos, _linkPos);
                _targetVec.applyQuaternion(_invLinkQ);
                _targetVec.normalize();

                var angle = _targetVec.dot(_effectorVec);

                if (angle > 1.0) {
                    angle = 1.0;
                } else if (angle < -1.0) {
                    angle = -1.0;
                }

                angle = Math.acos(angle);

                if (angle < 1e-5) continue;

                if (ik.minAngle != null && angle < ik.minAngle) {
                    angle = ik.minAngle;
                }

                if (ik.maxAngle != null && angle > ik.maxAngle) {
                    angle = ik.maxAngle;
                }

                _axis.crossVectors(_effectorVec, _targetVec);
                _axis.normalize();

                _q.setFromAxisAngle(_axis, angle);
                link.quaternion.multiply(_q);

                if (limitation != null) {
                    var c = link.quaternion.w;

                    if (c > 1.0) c = 1.0;

                    var c2 = Math.sqrt(1 - c * c);
                    link.quaternion.set(limitation.x * c2, limitation.y * c2, limitation.z * c2, c);
                }

                if (rotationMin != null) {
                    link.rotation.setFromVector3(_vector.setFromEuler(link.rotation).max(rotationMin));
                }

                if (rotationMax != null) {
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

        for (ik in iks) {
            var effector = bones[ik.effector];
            var links = ik.links;
            var link0, link1;

            link0 = effector;

            for (link in links) {
                link1 = bones[link.index];

                if (link0.parent != link1) {
                    trace("THREE.CCDIKSolver: bone ${link0.name} is not the child of bone ${link1.name}");
                }

                link0 = link1;
            }
        }
    }
}

static function getPosition(bone:Bone, matrixWorldInv:Matrix4):Vector3 {
    return _vector.setFromMatrixPosition(bone.matrixWorld).applyMatrix4(matrixWorldInv);
}

static function setPositionOfBoneToAttributeArray(array:Float32Array, index:Int, bone:Bone, matrixWorldInv:Matrix4) {
    var v = getPosition(bone, matrixWorldInv);

    array[index * 3 + 0] = v.x;
    array[index * 3 + 1] = v.y;
    array[index * 3 + 2] = v.z;
}

class CCDIKHelper extends Object3D {
    var root:SkinnedMesh;
    var iks:Array<Dynamic>;

    var sphereGeometry:SphereGeometry;

    var targetSphereMaterial:MeshBasicMaterial;
    var effectorSphereMaterial:MeshBasicMaterial;
    var linkSphereMaterial:MeshBasicMaterial;
    var lineMaterial:LineBasicMaterial;

    public function new(mesh:SkinnedMesh, iks:Array<Dynamic> = [], sphereSize:Float = 0.25) {
        super();

        this.root = mesh;
        this.iks = iks;

        this.matrix.copy(mesh.matrixWorld);
        this.matrixAutoUpdate = false;

        this.sphereGeometry = new SphereGeometry(sphereSize, 16, 8);

        this.targetSphereMaterial = new MeshBasicMaterial({
            color: new Color(0xff8888),
            depthTest: false,
            depthWrite: false,
            transparent: true
        });

        this.effectorSphereMaterial = new MeshBasicMaterial({
            color: new Color(0x88ff88),
            depthTest: false,
            depthWrite: false,
            transparent: true
        });

        this.linkSphereMaterial = new MeshBasicMaterial({
            color: new Color(0x8888ff),
            depthTest: false,
            depthWrite: false,
            transparent: true
        });

        this.lineMaterial = new LineBasicMaterial({
            color: new Color(0xff0000),
            depthTest: false,
            depthWrite: false,
            transparent: true
        });

        this._init();
    }

    override public function updateMatrixWorld(force:Bool = false):Void {
        var mesh = this.root;

        if (this.visible) {
            var offset = 0;

            var iks = this.iks;
            var bones = mesh.skeleton.bones;

            _matrix.copy(mesh.matrixWorld).invert();

            for (ik in iks) {
                var targetBone = bones[ik.target];
                var effectorBone = bones[ik.effector];

                var targetMesh = this.children[offset++];
                var effectorMesh = this.children[offset++];

                targetMesh.position.copy(getPosition(targetBone, _matrix));
                effectorMesh.position.copy(getPosition(effectorBone, _matrix));

                for (j in 0...ik.links.length) {
                    var link = ik.links[j];
                    var linkBone = bones[link.index];

                    var linkMesh = this.children[offset++];

                    linkMesh.position.copy(getPosition(linkBone, _matrix));
                }

                var line = this.children[offset++];
                var array = line.geometry.attributes.position.array;

                setPositionOfBoneToAttributeArray(array, 0, targetBone, _matrix);
                setPositionOfBoneToAttributeArray(array, 1, effectorBone, _matrix);

                for (j in 0...ik.links.length) {
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
            if (child is Line) child.geometry.dispose();
        }
    }

    private function _init() {
        var iks = this.iks;

        function createLineGeometry(ik:Dynamic):BufferGeometry {
            var geometry = new BufferGeometry();
            var vertices = new Float32Array((2 + ik.links.length) * 3);
            geometry.setAttribute('position', new BufferAttribute(vertices, 3));

            return geometry;
        }

        function createTargetMesh():Mesh {
            return new Mesh(this.sphereGeometry, this.targetSphereMaterial);
        }

        function createEffectorMesh():Mesh {
            return new Mesh(this.sphereGeometry, this.effectorSphereMaterial);
        }

        function createLinkMesh():Mesh {
            return new Mesh(this.sphereGeometry, this.linkSphereMaterial);
        }

        function createLine(ik:Dynamic):Line {
            return new Line(createLineGeometry(ik), this.lineMaterial);
        }

        for (ik in iks) {
            this.add(createTargetMesh());
            this.add(createEffectorMesh());

            for (j in 0...ik.links.length) {
                this.add(createLinkMesh());
            }

            this.add(createLine(ik));
        }
    }
}