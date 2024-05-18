package three.js.examples.jm.animation;

class GrantSolver {
    public var mesh:Mesh;
    public var grants:Array<Dynamic>;

    public function new(mesh:Mesh, grants:Array<Dynamic> = []) {
        this.mesh = mesh;
        this.grants = grants;
    }

    /**
     * Solve all the grant bones
     * @return GrantSolver
     */
    public function update():GrantSolver {
        var grants:Array<Dynamic> = this.grants;

        for (i in 0...grants.length) {
            updateOne(grants[i]);
        }

        return this;
    }

    /**
     * Solve a grant bone
     * @param grant - grant parameter
     * @return GrantSolver
     */
    public function updateOne(grant:Dynamic):GrantSolver {
        var bones:Array<Bone> = mesh.skeleton.bones;
        var bone:Bone = bones[grant.index];
        var parentBone:Bone = bones[grant.parentIndex];

        if (grant.isLocal) {
            // TODO: implement
            if (grant.affectPosition) {

            }

            // TODO: implement
            if (grant.affectRotation) {

            }
        } else {
            // TODO: implement
            if (grant.affectPosition) {

            }

            if (grant.affectRotation) {
                addGrantRotation(bone, parentBone.quaternion, grant.ratio);
            }
        }

        return this;
    }

    private var _q:Quaternion = new Quaternion(0, 0, 0, 1);

    public function addGrantRotation(bone:Bone, q:Quaternion, ratio:Float):GrantSolver {
        _q.slerp(q, ratio);
        bone.quaternion.multiply(_q);

        return this;
    }
}