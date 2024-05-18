package three.js/examples/jsm/animation;

import ammo.btCollisionConfiguration;
import ammo.btCollisionDispatcher;
import ammo.btDbvtBroadphase;
import ammo.btDiscreteDynamicsWorld;
import ammo.btDefaultCollisionConfiguration;
import ammo.btSequentialImpulseConstraintSolver;
import ammo.btVector3;

class MMDPhysics {
    var manager:ResourceManager;
    var mesh:SkinnedMesh;
    var unitStep:Float;
    var maxStepNum:Int;
    var gravity:Vector3;
    var world:btDiscreteDynamicsWorld;
    var bodies:Array<RigidBody>;
    var constraints:Array<Constraint>;

    public function new(mesh:SkinnedMesh, rigidBodyParams:Array<Object>, ?constraintParams:Array<Object> = [], ?params:Object = {}) {
        if (Ammo == null) {
            throw new Error('THREE.MMDPhysics: Import ammo.js https://github.com/kripken/ammo.js');
        }

        manager = new ResourceManager();
        this.mesh = mesh;

        unitStep = params.unitStep != null ? params.unitStep : 1 / 65;
        maxStepNum = params.maxStepNum != null ? params.maxStepNum : 3;
        gravity = new Vector3(0, -9.8 * 10, 0);
        if (params.gravity != null) gravity.copy(params.gravity);

        world = params.world != null ? params.world : null; // experimental

        bodies = [];
        constraints = [];

        _init(mesh, rigidBodyParams, constraintParams);
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

            scale.copy(mesh.scale);

            mesh.scale.set(1, 1, 1);
            mesh.updateMatrixWorld(true);
        }

        _updateRigidBodies();
        _stepSimulation(delta);
        _updateBones();

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
        for (i in 0...bodies.length) {
            bodies[i].reset();
        }
        return this;
    }

    public function warmup(cycles:Int):MMDPhysics {
        for (i in 0...cycles) {
            update(1 / 60);
        }
        return this;
    }

    public function setGravity(gravity:Vector3):MMDPhysics {
        world.setGravity(new btVector3(gravity.x, gravity.y, gravity.z));
        gravity.copy(gravity);
        return this;
    }

    public function createHelper():MMDPhysicsHelper {
        return new MMDPhysicsHelper(mesh, this);
    }

    private function _init(mesh:SkinnedMesh, rigidBodyParams:Array<Object>, constraintParams:Array<Object>) {
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

        if (world == null) {
            world = _createWorld();
            setGravity(gravity);
        }

        _initRigidBodies(rigidBodyParams);
        _initConstraints(constraintParams);

        if (parent != null) mesh.parent = parent;

        mesh.position.copy(currentPosition);
        mesh.quaternion.copy(currentQuaternion);
        mesh.scale.copy(currentScale);

        mesh.updateMatrixWorld(true);

        reset();

        manager.freeThreeVector3(currentPosition);
        manager.freeThreeQuaternion(currentQuaternion);
        manager.freeThreeVector3(currentScale);
    }

    private function _createWorld():btDiscreteDynamicsWorld {
        var config = new btDefaultCollisionConfiguration();
        var dispatcher = new btCollisionDispatcher(config);
        var cache = new btDbvtBroadphase();
        var solver = new btSequentialImpulseConstraintSolver();
        var world = new btDiscreteDynamicsWorld(dispatcher, cache, solver, config);
        return world;
    }

    private function _initRigidBodies(rigidBodies:Array<Object>) {
        for (i in 0...rigidBodies.length) {
            bodies.push(new RigidBody(mesh, world, rigidBodies[i], manager));
        }
    }

    private function _initConstraints(constraints:Array<Object>) {
        for (i in 0...constraints.length) {
            var params = constraints[i];
            var bodyA = bodies[params.rigidBodyIndex1];
            var bodyB = bodies[params.rigidBodyIndex2];
            this.constraints.push(new Constraint(mesh, world, bodyA, bodyB, params, manager));
        }
    }

    private function _stepSimulation(delta:Float) {
        var unitStep = this.unitStep;
        var stepTime = delta;
        var maxStepNum = (delta / unitStep) | 0 + 1;

        if (stepTime < unitStep) {
            stepTime = unitStep;
            maxStepNum = 1;
        }

        if (maxStepNum > this.maxStepNum) {
            maxStepNum = this.maxStepNum;
        }

        world.stepSimulation(stepTime, maxStepNum, unitStep);
    }

    private function _updateRigidBodies() {
        for (i in 0...bodies.length) {
            bodies[i].updateFromBone();
        }
    }

    private function _updateBones() {
        for (i in 0...bodies.length) {
            bodies[i].updateBone();
        }
    }
}