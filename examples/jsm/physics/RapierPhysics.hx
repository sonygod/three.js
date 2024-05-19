package three.js.examples.javascript.physics;

import three.js.Clock;
import three.js.Vector3;
import three.js.Quaternion;
import three.js.Matrix4;

class RapierPhysics {
    static inline var RAPIER_PATH = 'https://cdn.skypack.dev/@dimforge/rapier3d-compat@0.12.0';
    static inline var frameRate = 60;

    static var _scale = new Vector3(1, 1, 1);
    static var ZERO = new Vector3();

    static var RAPIER:Dynamic = null;

    static function getShape(geometry:Dynamic) {
        var parameters = geometry.parameters;

        // TODO change type to is*

        if (geometry.type == 'BoxGeometry') {
            var sx = parameters.width != null ? parameters.width / 2 : 0.5;
            var sy = parameters.height != null ? parameters.height / 2 : 0.5;
            var sz = parameters.depth != null ? parameters.depth / 2 : 0.5;

            return RAPIER.ColliderDesc.cuboid(sx, sy, sz);
        } else if (geometry.type == 'SphereGeometry' || geometry.type == 'IcosahedronGeometry') {
            var radius = parameters.radius != null ? parameters.radius : 1;
            return RAPIER.ColliderDesc.ball(radius);
        }

        return null;
    }

    static async function init() {
        if (RAPIER == null) {
            RAPIER = await js.Browser.import(RAPIER_PATH);
            await RAPIER.init();
        }

        var gravity = new Vector3(0.0, -9.81, 0.0);
        var world = new RAPIER.World(gravity);

        var meshes:Array<Dynamic> = [];
        var meshMap:WeakMap<Dynamic, Dynamic> = new WeakMap();

        var _vector = new Vector3();
        var _quaternion = new Quaternion();
        var _matrix = new Matrix4();

        function addScene(scene:Dynamic) {
            scene.traverse(function(child:Dynamic) {
                if (child.isMesh) {
                    var physics = child.userData.physics;

                    if (physics != null) {
                        addMesh(child, physics.mass, physics.restitution);
                    }
                }
            });
        }

        function addMesh(mesh:Dynamic, mass:Float = 0, restitution:Float = 0) {
            var shape = getShape(mesh.geometry);

            if (shape == null) return;

            shape.setMass(mass);
            shape.setRestitution(restitution);

            var body:Dynamic;
            if (mesh.isInstancedMesh) {
                body = createInstancedBody(mesh, mass, shape);
            } else {
                body = createBody(mesh.position, mesh.quaternion, mass, shape);
            }

            if (mass > 0) {
                meshes.push(mesh);
                meshMap.set(mesh, body);
            }
        }

        function createInstancedBody(mesh:Dynamic, mass:Float, shape:Dynamic) {
            var array = mesh.instanceMatrix.array;

            var bodies:Array<Dynamic> = [];

            for (i in 0...mesh.count) {
                var position = _vector.fromArray(array, i * 16 + 12);
                bodies.push(createBody(position, null, mass, shape));
            }

            return bodies;
        }

        function createBody(position:Vector3, quaternion:Quaternion, mass:Float, shape:Dynamic) {
            var desc:Dynamic = mass > 0 ? RAPIER.RigidBodyDesc.dynamic() : RAPIER.RigidBodyDesc.fixed();
            desc.setTranslation(position.x, position.y, position.z);
            if (quaternion != null) desc.setRotation(quaternion);

            var body = world.createRigidBody(desc);
            world.createCollider(shape, body);

            return body;
        }

        function setMeshPosition(mesh:Dynamic, position:Vector3, index:Int = 0) {
            var body:Dynamic = meshMap.get(mesh);

            if (mesh.isInstancedMesh) {
                body = body[index];
            }

            body.setAngvel(ZERO);
            body.setLinvel(ZERO);
            body.setTranslation(position);
        }

        function setMeshVelocity(mesh:Dynamic, velocity:Vector3, index:Int = 0) {
            var body:Dynamic = meshMap.get(mesh);

            if (mesh.isInstancedMesh) {
                body = body[index];
            }

            body.setLinvel(velocity);
        }

        var clock = new Clock();

        function step() {
            world.timestep = clock.getDelta();
            world.step();

            for (i in 0...meshes.length) {
                var mesh = meshes[i];

                if (mesh.isInstancedMesh) {
                    var array = mesh.instanceMatrix.array;
                    var bodies:Array<Dynamic> = meshMap.get(mesh);

                    for (j in 0...bodies.length) {
                        var body = bodies[j];

                        var position = body.translation();
                        _quaternion.copy(body.rotation());

                        _matrix.compose(position, _quaternion, _scale).toArray(array, j * 16);
                    }

                    mesh.instanceMatrix.needsUpdate = true;
                    mesh.computeBoundingSphere();
                } else {
                    var body = meshMap.get(mesh);

                    mesh.position.copy(body.translation());
                    mesh.quaternion.copy(body.rotation());
                }
            }
        }

        haxe.Timer.delay(step, 1000 / frameRate);

        return {
            addScene: addScene,
            addMesh: addMesh,
            setMeshPosition: setMeshPosition,
            setMeshVelocity: setMeshVelocity
        };
    }
}