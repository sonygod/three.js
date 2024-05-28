class CCDIKSolver {
    private var mesh:SkeletonMesh;
    private var iks:Array< CCDIKLink >;

    public function new(mesh:SkeletonMesh, iks:Array< CCDIKLink >) {
        this.mesh = mesh;
        this.iks = iks;
    }

    public function update() {
        for (i in 0...iks.length) {
            updateOne(iks[i]);
        }
    }

    private function updateOne(ik:CCDIKLink) {
        // TO DO: implement CCDIK solver
    }
}

class MMDPhysics {
    private var mesh:SkeletonMesh;
    private var rigidBodies:Array< RigidBody >;
    private var constraints:Array< Constraint >;

    public function new(mesh:SkeletonMesh, rigidBodies:Array< RigidBody >, constraints:Array< Constraint >) {
        this.mesh = mesh;
        this.rigidBodies = rigidBodies;
        this.constraints = constraints;
    }

    public function update(delta:Float) {
        // TO DO: implement physics update
    }

    public function reset() {
        // TO DO: implement physics reset
    }
}

class AudioManager {
    private var audio:Audio;
    private var elapsedTime:Float;
    private var currentTime:Float;
    private var delayTime:Float;
    private var audioDuration:Float;
    private var duration:Float;

    public function new(audio:Audio, params:{ delayTime:Float } = {}) {
        this.audio = audio;
        this.elapsedTime = 0.0;
        this.currentTime = 0.0;
        this.delayTime = params.delayTime != null ? params.delayTime : 0.0;
        this.audioDuration = audio.buffer.duration;
        this.duration = this.audioDuration + this.delayTime;
    }

    public function control(delta:Float) {
        this.elapsedTime += delta;
        this.currentTime += delta;

        if (_shouldStopAudio()) audio.stop();
        if (_shouldStartAudio()) audio.play();

        return this;
    }

    private function _shouldStartAudio():Bool {
        if (audio.isPlaying) return false;

        while (currentTime >= duration) {
            currentTime -= duration;
        }

        if (currentTime < delayTime) return false;

        if ((currentTime - delayTime) > audioDuration) return false;

        return true;
    }

    private function _shouldStopAudio():Bool {
        return audio.isPlaying && currentTime >= duration;
    }
}

class GrantSolver {
    private var mesh:SkeletonMesh;
    private var grants:Array<Grant>;

    public function new(mesh:SkeletonMesh, grants:Array<Grant> = []) {
        this.mesh = mesh;
        this.grants = grants;
    }

    public function update() {
        for (i in 0...grants.length) {
            updateOne(grants[i]);
        }

        return this;
    }

    private function updateOne(grant:Grant) {
        var bones:Array<Bone> = mesh.skeleton.bones;
        var bone:Bone = bones[grant.index];
        var parentBone:Bone = bones[grant.parentIndex];

        if (grant.isLocal) {
            // TO DO: implement local grant
        } else {
            if (grant.affectPosition) {
                // TO DO: implement position grant
            }

            if (grant.affectRotation) {
                addGrantRotation(bone, parentBone.quaternion, grant.ratio);
            }
        }

        return this;
    }

    private function addGrantRotation(bone:Bone, q:Quaternion, ratio:Float) {
        var _q:Quaternion = new Quaternion(0, 0, 0, 1);
        _q.slerp(q, ratio);
        bone.quaternion.multiply(_q);

        return this;
    }
}