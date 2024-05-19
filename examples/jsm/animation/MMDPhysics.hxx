package three.examples.jsm.animation;

import three.Bone;
import three.BoxGeometry;
import three.CapsuleGeometry;
import three.Color;
import three.Euler;
import three.Matrix4;
import three.Mesh;
import three.MeshBasicMaterial;
import three.Object3D;
import three.Quaternion;
import three.SphereGeometry;
import three.Vector3;

class MMDPhysics {

    public function new(mesh:SkinnedMesh, rigidBodyParams:Array<Dynamic>, constraintParams:Array<Dynamic> = [], params:Dynamic = {}) {

        if (Ammo.undefined) {
            throw new Error('THREE.MMDPhysics: Import ammo.js https://github.com/kripken/ammo.js');
        }

        manager = new ResourceManager();

        this.mesh = mesh;

        unitStep = (params.unitStep !== undefined) ? params.unitStep : 1 / 65;
        maxStepNum = (params.maxStepNum !== undefined) ? params.maxStepNum : 3;
        gravity = new Vector3(0, - 9.8 * 10, 0);

        if (params.gravity !== undefined) gravity.copy(params.gravity);

        world = (params.world !== undefined) ? params.world : null; // experimental

        bodies = [];
        constraints = [];

        _init(mesh, rigidBodyParams, constraintParams);

    }

    public function update(delta:Float):MMDPhysics {

        var manager = this.manager;
        var mesh = this.mesh;

        var stepTime = delta;
        var maxStepNum = ((delta / unitStep) | 0) + 1;

        if (stepTime < unitStep) {
            stepTime = unitStep;
            maxStepNum = 1;
        }

        if (maxStepNum > this.maxStepNum) {
            maxStepNum = this.maxStepNum;
        }

        world.stepSimulation(stepTime, maxStepNum, unitStep);

        _updateRigidBodies();
        _updateBones();

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

        world.setGravity(new Ammo.btVector3(gravity.x, gravity.y, gravity.z));
        this.gravity.copy(gravity);

        return this;

    }

    public function createHelper():MMDPhysicsHelper {

        return new MMDPhysicsHelper(mesh, this);

    }

    private function _init(mesh:SkinnedMesh, rigidBodies:Array<Dynamic>, constraintParams:Array<Dynamic>) {

        var manager = this.manager;

        var parent = mesh.parent;

        if (parent !== null) mesh.parent = null;

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

        if (world === null) {
            world = _createWorld();
            setGravity(gravity);
        }

        _initRigidBodies(rigidBodies);
        _initConstraints(constraintParams);

        if (parent !== null) mesh.parent = parent;

        mesh.position.copy(currentPosition);
        mesh.quaternion.copy(currentQuaternion);
        mesh.scale.copy(currentScale);

        mesh.updateMatrixWorld(true);

        reset();

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
            bodies.push(new RigidBody(mesh, world, rigidBodies[i], manager));
        }

    }

    private function _initConstraints(constraintParams:Array<Dynamic>) {

        for (i in 0...constraintParams.length) {
            var params = constraintParams[i];
            var bodyA = bodies[params.rigidBodyIndex1];
            var bodyB = bodies[params.rigidBodyIndex2];
            constraints.push(new Constraint(mesh, world, bodyA, bodyB, params, manager));
        }

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

    private var manager:ResourceManager;
    private var mesh:SkinnedMesh;
    private var unitStep:Float;
    private var maxStepNum:Int;
    private var gravity:Vector3;
    private var world:Ammo.btDiscreteDynamicsWorld;
    private var bodies:Array<RigidBody>;
    private var constraints:Array<Constraint>;

}

class ResourceManager {

    // ...

}

class RigidBody {

    // ...

}

class Constraint {

    // ...

}

class MMDPhysicsHelper extends Object3D {

    // ...

}