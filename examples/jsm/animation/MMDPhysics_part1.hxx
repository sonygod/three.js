class MMDPhysics {

    public function new(mesh:three.SkinnedMesh, rigidBodyParams:Array<Dynamic>, constraintParams:Array<Dynamic> = [], params:Dynamic = {}) {

        if (Ammo == null) {

            throw 'THREE.MMDPhysics: Import ammo.js https://github.com/kripken/ammo.js';

        }

        this.manager = new ResourceManager();

        this.mesh = mesh;

        this.unitStep = (params.unitStep != null) ? params.unitStep : 1 / 65;
        this.maxStepNum = (params.maxStepNum != null) ? params.maxStepNum : 3;
        this.gravity = new three.Vector3(0, - 9.8 * 10, 0);

        if (params.gravity != null) this.gravity.copy(params.gravity);

        this.world = (params.world != null) ? params.world : null; // experimental

        this.bodies = [];
        this.constraints = [];

        this._init(mesh, rigidBodyParams, constraintParams);

    }

    public function update(delta:Float):MMDPhysics {

        var manager = this.manager;
        var mesh = this.mesh;

        var isNonDefaultScale = false;

        var position = manager.allocThreeVector3();
        var quaternion = manager.allocThreeQuaternion();
        var scale = manager.allocThreeVector3();

        mesh.matrixWorld.decompose(position, quaternion, scale);

        if (scale.x != 1 || scale.y != 1 || scale.z != 1) {

            isNonDefaultScale = true;

        }

        var parent;

        if (isNonDefaultScale) {

            parent = mesh.parent;

            if (parent != null) mesh.parent = null;

            scale.copy(this.mesh.scale);

            mesh.scale.set(1, 1, 1);
            mesh.updateMatrixWorld(true);

        }

        this._updateRigidBodies();
        this._stepSimulation(delta);
        this._updateBones();

        if (isNonDefaultScale) {

            if (parent != null) mesh.parent = parent;

            mesh.scale.copy(scale);

        }

        manager.freeThreeVector3(scale);
        manager.freeThreeQuaternion(quaternion);
        manager.freeThreeVector3(position);

        return this;

    }

    public function reset():MMDPhysics {

        for (i in 0...this.bodies.length) {

            this.bodies[i].reset();

        }

        return this;

    }

    public function warmup(cycles:Int):MMDPhysics {

        for (i in 0...cycles) {

            this.update(1 / 60);

        }

        return this;

    }

    public function setGravity(gravity:three.Vector3):MMDPhysics {

        this.world.setGravity(new Ammo.btVector3(gravity.x, gravity.y, gravity.z));
        this.gravity.copy(gravity);

        return this;

    }

    public function createHelper():MMDPhysicsHelper {

        return new MMDPhysicsHelper(this.mesh, this);

    }

    private function _init(mesh:three.SkinnedMesh, rigidBodyParams:Array<Dynamic>, constraintParams:Array<Dynamic>) {

        var manager = this.manager;

        var parent = mesh.parent;

        if (parent != null) mesh.parent = null;

        var currentPosition = manager.allocThreeVector3();
        var currentQuaternion = manager.allocThreeQuaternion();
        var currentScale = manager.allocThreeVector3();

        currentPosition.copy(mesh.position);
        currentQuaternion.copy(mesh.quaternion);
        currentScale.copy(mesh.scale);

        mesh.position.set(0, 0, 0);
        mesh.quaternion.set(0, 0, 0, 1);
        mesh.scale.set(1, 1, 1);

        mesh.updateMatrixWorld(true);

        if (this.world == null) {

            this.world = this._createWorld();
            this.setGravity(this.gravity);

        }

        this._initRigidBodies(rigidBodyParams);
        this._initConstraints(constraintParams);

        if (parent != null) mesh.parent = parent;

        mesh.position.copy(currentPosition);
        mesh.quaternion.copy(currentQuaternion);
        mesh.scale.copy(currentScale);

        mesh.updateMatrixWorld(true);

        this.reset();

        manager.freeThreeVector3(currentPosition);
        manager.freeThreeQuaternion(currentQuaternion);
        manager.freeThreeVector3(currentScale);

    }

    private function _createWorld():Ammo.btDiscreteDynamicsWorld {

        var config = new Ammo.btDefaultCollisionConfiguration();
        var dispatcher = new Ammo.btCollisionDispatcher(config);
        var cache = new Ammo.btDbvtBroadphase();
        var solver = new Ammo.btSequentialImpulseConstraintSolver();
        var world = new Ammo.btDiscreteDynamicsWorld(dispatcher, cache, solver, config);
        return world;

    }

    private function _initRigidBodies(rigidBodies:Array<Dynamic>) {

        for (i in 0...rigidBodies.length) {

            this.bodies.push(new RigidBody(this.mesh, this.world, rigidBodies[i], this.manager));

        }

    }

    private function _initConstraints(constraints:Array<Dynamic>) {

        for (i in 0...constraints.length) {

            var params = constraints[i];
            var bodyA = this.bodies[params.rigidBodyIndex1];
            var bodyB = this.bodies[params.rigidBodyIndex2];
            this.constraints.push(new Constraint(this.mesh, this.world, bodyA, bodyB, params, this.manager));

        }

    }

    private function _stepSimulation(delta:Float) {

        var unitStep = this.unitStep;
        var stepTime = delta;
        var maxStepNum = ((delta / unitStep) | 0) + 1;

        if (stepTime < unitStep) {

            stepTime = unitStep;
            maxStepNum = 1;

        }

        if (maxStepNum > this.maxStepNum) {

            maxStepNum = this.maxStepNum;

        }

        this.world.stepSimulation(stepTime, maxStepNum, unitStep);

    }

    private function _updateRigidBodies() {

        for (i in 0...this.bodies.length) {

            this.bodies[i].updateFromBone();

        }

    }

    private function _updateBones() {

        for (i in 0...this.bodies.length) {

            this.bodies[i].updateBone();

        }

    }

}