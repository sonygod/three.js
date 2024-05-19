package three.js.examples.jvm.AmmoPhysics;

import cpp.Lib;
import haxe.ds.WeakMap;

class AmmoPhysics {
    private var ammoLib:Ammo;
    private var world:Ammo.btDiscreteDynamicsWorld;
    private var collisionConfiguration:Ammo.btDefaultCollisionConfiguration;
    private var dispatcher:Ammo.btCollisionDispatcher;
    private var broadphase:Ammo.btDbvtBroadphase;
    private var solver:Ammo.btSequentialImpulseConstraintSolver;
    private var worldTransform:Ammo.btTransform;
    private var meshes:Array<Mesh>;
    private var meshMap:WeakMap<Mesh, Dynamic>;
    private var frameRate:Int;
    private var lastTime:Float;

    public function new() {
        if (!Lib.document.exists("Ammo")) {
            trace("AmmoPhysics: Couldn't find Ammo.js");
            return;
        }

        ammoLib = Lib.load("Ammo", null);

        frameRate = 60;

        collisionConfiguration = new Ammo.btDefaultCollisionConfiguration();
        dispatcher = new Ammo.btCollisionDispatcher(collisionConfiguration);
        broadphase = new Ammo.btDbvtBroadphase();
        solver = new Ammo.btSequentialImpulseConstraintSolver();
        world = new Ammo.btDiscreteDynamicsWorld(dispatcher, broadphase, solver, collisionConfiguration);
        world.setGravity(new Ammo.btVector3(0, -9.8, 0));

        worldTransform = new Ammo.btTransform();

        meshes = new Array();
        meshMap = new WeakMap();

        addScene = addScene;
        addMesh = addMesh;
        setMeshPosition = setMeshPosition;
    }

    private function getShape(geometry:Geometry):Ammo.btCollisionShape {
        var parameters = geometry.parameters;

        if (geometry.type == 'BoxGeometry') {
            var sx = parameters.width != null ? parameters.width / 2 : 0.5;
            var sy = parameters.height != null ? parameters.height / 2 : 0.5;
            var sz = parameters.depth != null ? parameters.depth / 2 : 0.5;

            var shape = new Ammo.btBoxShape(new Ammo.btVector3(sx, sy, sz));
            shape.setMargin(0.05);

            return shape;
        } else if (geometry.type == 'SphereGeometry' || geometry.type == 'IcosahedronGeometry') {
            var radius = parameters.radius != null ? parameters.radius : 1;

            var shape = new Ammo.btSphereShape(radius);
            shape.setMargin(0.05);

            return shape;
        }

        return null;
    }

    private function addScene(scene:Object) {
        scene.traverse(function(child:Object) {
            if (child.isMesh) {
                var physics = child.userData.physics;

                if (physics != null) {
                    addMesh(child, physics.mass);
                }
            }
        });
    }

    private function addMesh(mesh:Mesh, mass:Float = 0) {
        var shape:Ammo.btCollisionShape = getShape(mesh.geometry);

        if (shape != null) {
            if (mesh.isInstancedMesh) {
                handleInstancedMesh(mesh, mass, shape);
            } else if (mesh.isMesh) {
                handleMesh(mesh, mass, shape);
            }
        }
    }

    private function handleMesh(mesh:Mesh, mass:Float, shape:Ammo.btCollisionShape) {
        var position = mesh.position;
        var quaternion = mesh.quaternion;

        var transform = new Ammo.btTransform();
        transform.setIdentity();
        transform.setOrigin(new Ammo.btVector3(position.x, position.y, position.z));
        transform.setRotation(new Ammo.btQuaternion(quaternion.x, quaternion.y, quaternion.z, quaternion.w));

        var motionState = new Ammo.btDefaultMotionState(transform);

        var localInertia = new Ammo.btVector3(0, 0, 0);
        shape.calculateLocalInertia(mass, localInertia);

        var rbInfo = new Ammo.btRigidBodyConstructionInfo(mass, motionState, shape, localInertia);

        var body = new Ammo.btRigidBody(rbInfo);
        world.addRigidBody(body);

        if (mass > 0) {
            meshes.push(mesh);
            meshMap.set(mesh, body);
        }
    }

    private function handleInstancedMesh(mesh:Mesh, mass:Float, shape:Ammo.btCollisionShape) {
        var array = mesh.instanceMatrix.array;

        var bodies:Array<Ammo.btRigidBody> = new Array();

        for (i in 0...mesh.count) {
            var index = i * 16;

            var transform = new Ammo.btTransform();
            transform.setFromOpenGLMatrix(array.slice(index, index + 16));

            var motionState = new Ammo.btDefaultMotionState(transform);

            var localInertia = new Ammo.btVector3(0, 0, 0);
            shape.calculateLocalInertia(mass, localInertia);

            var rbInfo = new Ammo.btRigidBodyConstructionInfo(mass, motionState, shape, localInertia);

            var body = new Ammo.btRigidBody(rbInfo);
            world.addRigidBody(body);

            bodies.push(body);
        }

        if (mass > 0) {
            meshes.push(mesh);
            meshMap.set(mesh, bodies);
        }
    }

    private function setMeshPosition(mesh:Mesh, position:Ammo.btVector3, index:Int = 0) {
        if (mesh.isInstancedMesh) {
            var bodies:Array<Ammo.btRigidBody> = meshMap.get(mesh);
            var body = bodies[index];

            body.setAngularVelocity(new Ammo.btVector3(0, 0, 0));
            body.setLinearVelocity(new Ammo.btVector3(0, 0, 0));

            worldTransform.setIdentity();
            worldTransform.setOrigin(position);
            body.setWorldTransform(worldTransform);
        } else if (mesh.isMesh) {
            var body:Ammo.btRigidBody = meshMap.get(mesh);

            body.setAngularVelocity(new Ammo.btVector3(0, 0, 0));
            body.setLinearVelocity(new Ammo.btVector3(0, 0, 0));

            worldTransform.setIdentity();
            worldTransform.setOrigin(position);
            body.setWorldTransform(worldTransform);
        }
    }

    private function step() {
        var time:Float = Date.now().getTime();

        if (lastTime > 0) {
            var delta:Float = (time - lastTime) / 1000;

            world.stepSimulation(delta, 10);

            for (i in 0...meshes.length) {
                var mesh = meshes[i];

                if (mesh.isInstancedMesh) {
                    var array = mesh.instanceMatrix.array;
                    var bodies:Array<Ammo.btRigidBody> = meshMap.get(mesh);

                    for (j in 0...bodies.length) {
                        var body = bodies[j];

                        var motionState = body.getMotionState();
                        motionState.getWorldTransform(worldTransform);

                        var position = worldTransform.getOrigin();
                        var quaternion = worldTransform.getRotation();

                        compose(position, quaternion, array, j * 16);

                    }

                    mesh.instanceMatrix.needsUpdate = true;
                    mesh.computeBoundingSphere();
                } else if (mesh.isMesh) {
                    var body:Ammo.btRigidBody = meshMap.get(mesh);

                    var motionState = body.getMotionState();
                    motionState.getWorldTransform(worldTransform);

                    var position = worldTransform.getOrigin();
                    var quaternion = worldTransform.getRotation();
                    mesh.position.set(position.x(), position.y(), position.z());
                    mesh.quaternion.set(quaternion.x(), quaternion.y(), quaternion.z(), quaternion.w());
                }
            }
        }

        lastTime = time;
    }

    private function compose(position:Ammo.btVector3, quaternion:Ammo.btQuaternion, array:Array<Float>, index:Int) {
        var x:Float = quaternion.x();
        var y:Float = quaternion.y();
        var z:Float = quaternion.z();
        var w:Float = quaternion.w();
        var x2:Float = x + x;
        var y2:Float = y + y;
        var z2:Float = z + z;
        var xx:Float = x * x2;
        var xy:Float = x * y2;
        var xz:Float = x * z2;
        var yy:Float = y * y2;
        var yz:Float = y * z2;
        var zz:Float = z * z2;
        var wx:Float = w * x2;
        var wy:Float = w * y2;
        var wz:Float = w * z2;

        array[index + 0] = 1 - (yy + zz);
        array[index + 1] = xy + wz;
        array[index + 2] = xz - wy;
        array[index + 3] = 0;

        array[index + 4] = xy - wz;
        array[index + 5] = 1 - (xx + zz);
        array[index + 6] = yz + wx;
        array[index + 7] = 0;

        array[index + 8] = xz + wy;
        array[index + 9] = yz - wx;
        array[index + 10] = 1 - (xx + yy);
        array[index + 11] = 0;

        array[index + 12] = position.x();
        array[index + 13] = position.y();
        array[index + 14] = position.z();
        array[index + 15] = 1;
    }

    public function animate() {
        haxe.Timer.delay(step, 1000 / frameRate);
    }
}