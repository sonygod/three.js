import js.Promise;
import js.html.Window;
import js.html.performance.Performance;
import AmmoLib from 'AmmoLib'; // Assuming AmmoLib is imported correctly

class AmmoPhysics {
    var frameRate:Int = 60;
    var collisionConfiguration:AmmoLib.btDefaultCollisionConfiguration;
    var dispatcher:AmmoLib.btCollisionDispatcher;
    var broadphase:AmmoLib.btDbvtBroadphase;
    var solver:AmmoLib.btSequentialImpulseConstraintSolver;
    var world:AmmoLib.btDiscreteDynamicsWorld;
    var worldTransform:AmmoLib.btTransform;
    var meshes:Array<any> = [];
    var meshMap:Map<any, any> = new Map<any, any>();
    var lastTime:Float = 0.0;

    public function new() {
        if (!js.Browser.window.hasField('Ammo')) {
            trace('AmmoPhysics: Couldn\'t find Ammo.js');
            return Promise.resolve(null);
        }

        return AmmoLib.init().then((_:Void) => {
            collisionConfiguration = new AmmoLib.btDefaultCollisionConfiguration();
            dispatcher = new AmmoLib.btCollisionDispatcher(collisionConfiguration);
            broadphase = new AmmoLib.btDbvtBroadphase();
            solver = new AmmoLib.btSequentialImpulseConstraintSolver();
            world = new AmmoLib.btDiscreteDynamicsWorld(dispatcher, broadphase, solver, collisionConfiguration);
            world.setGravity(new AmmoLib.btVector3(0, -9.8, 0));
            worldTransform = new AmmoLib.btTransform();

            js.Browser.setInterval(step, 1000 / frameRate);

            return this;
        });
    }

    public function getShape(geometry:any):AmmoLib.btCollisionShape {
        var parameters = geometry.parameters;

        if (geometry.type == 'BoxGeometry') {
            var sx = parameters.hasOwnProperty('width') ? parameters.width / 2 : 0.5;
            var sy = parameters.hasOwnProperty('height') ? parameters.height / 2 : 0.5;
            var sz = parameters.hasOwnProperty('depth') ? parameters.depth / 2 : 0.5;

            var shape = new AmmoLib.btBoxShape(new AmmoLib.btVector3(sx, sy, sz));
            shape.setMargin(0.05);

            return shape;
        } else if (geometry.type == 'SphereGeometry' || geometry.type == 'IcosahedronGeometry') {
            var radius = parameters.hasOwnProperty('radius') ? parameters.radius : 1;

            var shape = new AmmoLib.btSphereShape(radius);
            shape.setMargin(0.05);

            return shape;
        }

        return null;
    }

    public function addScene(scene:any):Void {
        scene.traverse(function(child:any) {
            if (child.isMesh) {
                var physics = child.userData.physics;

                if (physics != null) {
                    addMesh(child, physics.mass);
                }
            }
        });
    }

    public function addMesh(mesh:any, mass:Float = 0.0):Void {
        var shape = getShape(mesh.geometry);

        if (shape != null) {
            if (mesh.isInstancedMesh) {
                handleInstancedMesh(mesh, mass, shape);
            } else if (mesh.isMesh) {
                handleMesh(mesh, mass, shape);
            }
        }
    }

    private function handleMesh(mesh:any, mass:Float, shape:AmmoLib.btCollisionShape):Void {
        var position = mesh.position;
        var quaternion = mesh.quaternion;

        var transform = new AmmoLib.btTransform();
        transform.setIdentity();
        transform.setOrigin(new AmmoLib.btVector3(position.x, position.y, position.z));
        transform.setRotation(new AmmoLib.btQuaternion(quaternion.x, quaternion.y, quaternion.z, quaternion.w));

        var motionState = new AmmoLib.btDefaultMotionState(transform);

        var localInertia = new AmmoLib.btVector3(0, 0, 0);
        shape.calculateLocalInertia(mass, localInertia);

        var rbInfo = new AmmoLib.btRigidBodyConstructionInfo(mass, motionState, shape, localInertia);

        var body = new AmmoLib.btRigidBody(rbInfo);
        world.addRigidBody(body);

        if (mass > 0) {
            meshes.push(mesh);
            meshMap.set(mesh, body);
        }
    }

    private function handleInstancedMesh(mesh:any, mass:Float, shape:AmmoLib.btCollisionShape):Void {
        var array = mesh.instanceMatrix.array;

        var bodies:Array<AmmoLib.btRigidBody> = [];

        for (var i:Int = 0; i < mesh.count; i++) {
            var index = i * 16;

            var transform = new AmmoLib.btTransform();
            transform.setFromOpenGLMatrix(array.slice(index, index + 16));

            var motionState = new AmmoLib.btDefaultMotionState(transform);

            var localInertia = new AmmoLib.btVector3(0, 0, 0);
            shape.calculateLocalInertia(mass, localInertia);

            var rbInfo = new AmmoLib.btRigidBodyConstructionInfo(mass, motionState, shape, localInertia);

            var body = new AmmoLib.btRigidBody(rbInfo);
            world.addRigidBody(body);

            bodies.push(body);
        }

        if (mass > 0) {
            meshes.push(mesh);

            meshMap.set(mesh, bodies);
        }
    }

    public function setMeshPosition(mesh:any, position:any, index:Int = 0):Void {
        if (mesh.isInstancedMesh) {
            var bodies = meshMap.get(mesh);
            var body = bodies[index];

            body.setAngularVelocity(new AmmoLib.btVector3(0, 0, 0));
            body.setLinearVelocity(new AmmoLib.btVector3(0, 0, 0));

            worldTransform.setIdentity();
            worldTransform.setOrigin(new AmmoLib.btVector3(position.x, position.y, position.z));
            body.setWorldTransform(worldTransform);
        } else if (mesh.isMesh) {
            var body = meshMap.get(mesh);

            body.setAngularVelocity(new AmmoLib.btVector3(0, 0, 0));
            body.setLinearVelocity(new AmmoLib.btVector3(0, 0, 0));

            worldTransform.setIdentity();
            worldTransform.setOrigin(new AmmoLib.btVector3(position.x, position.y, position.z));
            body.setWorldTransform(worldTransform);
        }
    }

    private function step():Void {
        var time = Performance.now();

        if (lastTime > 0) {
            var delta = (time - lastTime) / 1000;

            world.stepSimulation(delta, 10);

            for (var i:Int = 0; i < meshes.length; i++) {
                var mesh = meshes[i];

                if (mesh.isInstancedMesh) {
                    var array = mesh.instanceMatrix.array;
                    var bodies = meshMap.get(mesh);

                    for (var j:Int = 0; j < bodies.length; j++) {
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
                    var body = meshMap.get(mesh);

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

    private function compose(position:AmmoLib.btVector3, quaternion:AmmoLib.btQuaternion, array:Array<Float>, index:Int):Void {
        var x = quaternion.x(), y = quaternion.y(), z = quaternion.z(), w = quaternion.w();
        var x2 = x + x, y2 = y + y, z2 = z + z;
        var xx = x * x2, xy = x * y2, xz = x * z2;
        var yy = y * y2, yz = y * z2, zz = z * z2;
        var wx = w * x2, wy = w * y2, wz = w * z2;

        array[index + 0] = (1 - (yy + zz));
        array[index + 1] = (xy + wz);
        array[index + 2] = (xz - wy);
        array[index + 3] = 0;

        array[index + 4] = (xy - wz);
        array[index + 5] = (1 - (xx + zz));
        array[index + 6] = (yz + wx);
        array[index + 7] = 0;

        array[index + 8] = (xz + wy);
        array[index + 9] = (yz - wx);
        array[index + 10] = (1 - (xx + yy));
        array[index + 11] = 0;

        array[index + 12] = position.x();
        array[index + 13] = position.y();
        array[index + 14] = position.z();
        array[index + 15] = 1;
    }
}