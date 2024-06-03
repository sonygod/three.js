import js.Browser.window;
import js.html.WebSocket;
import js.lib.Function;
import three.Clock;
import three.math.Vector3;
import three.math.Quaternion;
import three.math.Matrix4;

class RapierPhysics {
    static var RAPIER_PATH:String = "https://cdn.skypack.dev/@dimforge/rapier3d-compat@0.12.0";
    static var frameRate:Int = 60;
    static var _scale:Vector3 = new Vector3(1, 1, 1);
    static var ZERO:Vector3 = new Vector3();
    static var RAPIER:Dynamic = null;

    static function getShape(geometry:Dynamic):Dynamic {
        var parameters = geometry.parameters;

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

    static function createInstancedBody(mesh:Dynamic, mass:Float, shape:Dynamic):Array<Dynamic> {
        var array = mesh.instanceMatrix.array;
        var bodies = [];

        for (i in 0...mesh.count) {
            var position = _vector.fromArray(array, i * 16 + 12);
            bodies.push(createBody(position, null, mass, shape));
        }

        return bodies;
    }

    static function createBody(position:Vector3, quaternion:Quaternion, mass:Float, shape:Dynamic):Dynamic {
        var desc = mass > 0 ? RAPIER.RigidBodyDesc.dynamic() : RAPIER.RigidBodyDesc.fixed();
        desc.setTranslation(position.x, position.y, position.z);

        if (quaternion != null) desc.setRotation(quaternion);

        var body = world.createRigidBody(desc);
        world.createCollider(shape, body);

        return body;
    }

    static function setMeshPosition(mesh:Dynamic, position:Vector3, index:Int = 0):Void {
        var body = meshMap.get(mesh);

        if (mesh.isInstancedMesh) {
            body = body[index];
        }

        body.setAngvel(ZERO);
        body.setLinvel(ZERO);
        body.setTranslation(position);
    }

    static function setMeshVelocity(mesh:Dynamic, velocity:Vector3, index:Int = 0):Void {
        var body = meshMap.get(mesh);

        if (mesh.isInstancedMesh) {
            body = body[index];
        }

        body.setLinvel(velocity);
    }

    static function step():Void {
        world.timestep = clock.getDelta();
        world.step();

        for (i in 0...meshes.length) {
            var mesh = meshes[i];

            if (mesh.isInstancedMesh) {
                var array = mesh.instanceMatrix.array;
                var bodies = meshMap.get(mesh);

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

    static function addScene(scene:Dynamic):Void {
        scene.traverse(function(child) {
            if (child.isMesh) {
                var physics = child.userData.physics;

                if (physics != null) {
                    addMesh(child, physics.mass, physics.restitution);
                }
            }
        });
    }

    static function addMesh(mesh:Dynamic, mass:Float = 0, restitution:Float = 0):Void {
        var shape = getShape(mesh.geometry);

        if (shape == null) return;

        shape.setMass(mass);
        shape.setRestitution(restitution);

        var body = mesh.isInstancedMesh ? createInstancedBody(mesh, mass, shape) : createBody(mesh.position, mesh.quaternion, mass, shape);

        if (mass > 0) {
            meshes.push(mesh);
            meshMap.set(mesh, body);
        }
    }

    static var gravity:Vector3 = new Vector3(0.0, -9.81, 0.0);
    static var world:Dynamic = new RAPIER.World(gravity);

    static var meshes:Array<Dynamic> = [];
    static var meshMap:WeakMap = new WeakMap();

    static var _vector:Vector3 = new Vector3();
    static var _quaternion:Quaternion = new Quaternion();
    static var _matrix:Matrix4 = new Matrix4();

    static var clock:Clock = new Clock();

    static function new() {
        var intervalId = window.setInterval(step, 1000 / frameRate);

        return {
            addScene: addScene,
            addMesh: addMesh,
            setMeshPosition: setMeshPosition,
            setMeshVelocity: setMeshVelocity
        };
    }
}

export RapierPhysics;