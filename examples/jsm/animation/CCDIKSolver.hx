package three.js.examples.jsm.animation;

import three.js.Lib;
import three.js.math.Vector3;
import three.js.math.Quaternion;
import three.js.math.Matrix4;
import three.js.objects.SkinnedMesh;
import three.js.objects.Bone;
import three.js.objects.Object3D;
import three.js.geometries.SphereGeometry;
import three.js.materials.MeshBasicMaterial;
import three.js.materials.LineBasicMaterial;
import three.js.objects.Line;
import three.js.objects.Mesh;

class CCDIKSolver {
    public var mesh:SkinnedMesh;
    public var iks:Array<IKParameter>;

    public function new(mesh:SkinnedMesh, iks:Array<IKParameter> = []) {
        this.mesh = mesh;
        this.iks = iks;
        _valid();
    }

    public function update():CCDIKSolver {
        for (ik in iks) {
            updateOne(ik);
        }
        return this;
    }

    public function updateOne(ik:IKParameter):CCDIKSolver {
        var bones:Array<Bone> = mesh.skeleton.bones;
        var effector:Bone = bones[ik.effector];
        var target:Bone = bones[ik.target];

        _targetPos.setFromMatrixPosition(target.matrixWorld);

        var links:Array<Link> = ik.links;
        var iteration:Int = ik.iteration != null ? ik.iteration : 1;

        for (i in 0...iteration) {
            var rotated:Bool = false;

            for (j in 0...links.length) {
                var link:Bone = bones[links[j].index];

                if (!links[j].enabled) break;

                var limitation:Vector3 = links[j].limitation;
                var rotationMin:Float = links[j].rotationMin;
                var rotationMax:Float = links[j].rotationMax;

                link.matrixWorld.decompose(_linkPos, _invLinkQ, _linkScale);
                _invLinkQ.invert();

                _effectorPos.setFromMatrixPosition(effector.matrixWorld);

                _effectorVec.subVectors(_effectorPos, _linkPos);
                _effectorVec.applyQuaternion(_invLinkQ);
                _effectorVec.normalize();

                _targetVec.subVectors(_targetPos, _linkPos);
                _targetVec.applyQuaternion(_invLinkQ);
                _targetVec.normalize();

                var angle:Float = _targetVec.dot(_effectorVec);

                if (angle > 1.0) angle = 1.0;
                else if (angle < -1.0) angle = -1.0;

                angle = Math.acos(angle);

                if (angle < 1e-5) continue;

                if (ik.minAngle != null && angle < ik.minAngle) angle = ik.minAngle;
                if (ik.maxAngle != null && angle > ik.maxAngle) angle = ik.maxAngle;

                _axis.crossVectors(_effectorVec, _targetVec);
                _axis.normalize();

                _q.setFromAxisAngle(_axis, angle);
                link.quaternion.multiply(_q);

                if (limitation != null) {
                    var c:Float = link.quaternion.w;
                    if (c > 1.0) c = 1.0;
                    var c2:Float = Math.sqrt(1 - c * c);
                    link.quaternion.set(limited.x * c2, limited.y * c2, limited.z * c2, c);
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
        return new CCDIKHelper(mesh, iks, sphereSize);
    }

    private function _valid() {
        for (ik in iks) {
            var bones:Array<Bone> = mesh.skeleton.bones;
            var effector:Bone = bones[ik.effector];
            var links:Array<Link> = ik.links;
            var link0:Bone = effector;

            for (link in links) {
                link1 = bones[link.index];

                if (link0.parent != link1) {
                    console.warn('THREE.CCDIKSolver: bone ' + link0.name + ' is not the child of bone ' + link1.name);
                }

                link0 = link1;
            }
        }
    }
}

class CCDIKHelper extends Object3D {
    var root:SkinnedMesh;
    var iks:Array<IKParameter>;
    var sphereGeometry:SphereGeometry;
    var targetSphereMaterial:MeshBasicMaterial;
    var effectorSphereMaterial:MeshBasicMaterial;
    var linkSphereMaterial:MeshBasicMaterial;
    var lineMaterial:LineBasicMaterial;

    public function new(mesh:SkinnedMesh, iks:Array<IKParameter> = [], sphereSize:Float = 0.25) {
        super();
        this.root = mesh;
        this.iks = iks;

        this.matrix.copy(mesh.matrixWorld);
        this.matrixAutoUpdate = false;

        sphereGeometry = new SphereGeometry(sphereSize, 16, 8);

        targetSphereMaterial = new MeshBasicMaterial({
            color: new Color(0xff8888),
            depthTest: false,
            depthWrite: false,
            transparent: true
        });

        effectorSphereMaterial = new MeshBasicMaterial({
            color: new Color(0x88ff88),
            depthTest: false,
            depthWrite: false,
            transparent: true
        });

        linkSphereMaterial = new MeshBasicMaterial({
            color: new Color(0x8888ff),
            depthTest: false,
            depthWrite: false,
            transparent: true
        });

        lineMaterial = new LineBasicMaterial({
            color: new Color(0xff0000),
            depthTest: false,
            depthWrite: false,
            transparent: true
        });

        _init();
    }

    override public function updateMatrixWorld(force:Bool) {
        if (visible) {
            var offset:Int = 0;

            for (ik in iks) {
                var targetBone:Bone = root.skeleton.bones[ik.target];
                var effectorBone:Bone = root.skeleton.bones[ik.effector];

                var targetMesh:Mesh = children[offset++];
                var effectorMesh:Mesh = children[offset++];

                targetMesh.position.copy(getPosition(targetBone, _matrix));
                effectorMesh.position.copy(getPosition(effectorBone, _matrix));

                for (link in ik.links) {
                    var linkBone:Bone = root.skeleton.bones[link.index];
                    var linkMesh:Mesh = children[offset++];

                    linkMesh.position.copy(getPosition(linkBone, _matrix));
                }

                var line:Line = children[offset++];
                var array:Array<Float> = line.geometry.attributes.position.array;

                setPositionOfBoneToAttributeArray(array, 0, targetBone, _matrix);
                setPositionOfBoneToAttributeArray(array, 1, effectorBone, _matrix);

                for (link in ik.links) {
                    var linkBone:Bone = root.skeleton.bones[link.index];
                    setPositionOfBoneToAttributeArray(array, link.index, linkBone, _matrix);
                }

                line.geometry.attributes.position.needsUpdate = true;
            }
        }

        super.updateMatrixWorld(force);
    }

    public function dispose() {
        sphereGeometry.dispose();

        targetSphereMaterial.dispose();
        effectorSphereMaterial.dispose();
        linkSphereMaterial.dispose();
        lineMaterial.dispose();

        for (child in children) {
            if (child.isLine) child.geometry.dispose();
        }
    }

    private function _init() {
        for (ik in iks) {
            createLineGeometry(ik);
        }
    }

    private function createLineGeometry(ik:IKParameter):BufferGeometry {
        var geometry:BufferGeometry = new BufferGeometry();
        var vertices:Array<Float> = new Array<Float>((2 + ik.links.length) * 3);
        geometry.setAttribute('position', new BufferAttribute(vertices, 3));

        return geometry;
    }

    private function createTargetMesh():Mesh {
        return new Mesh(sphereGeometry, targetSphereMaterial);
    }

    private function createEffectorMesh():Mesh {
        return new Mesh(sphereGeometry, effectorSphereMaterial);
    }

    private function createLinkMesh():Mesh {
        return new Mesh(sphereGeometry, linkSphereMaterial);
    }

    private function createLine(ik:IKParameter):Line {
        return new Line(createLineGeometry(ik), lineMaterial);
    }
}

typedef IKParameter = {
    target:Int,
    effector:Int,
    links:Array<Link>,
    iteration:Int,
    minAngle:Float,
    maxAngle:Float
}

typedef Link = {
    index:Int,
    limitation:Vector3,
    enabled:Bool,
    rotationMin:Float,
    rotationMax:Float
}