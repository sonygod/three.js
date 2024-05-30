import js.three.Clock;
import js.three.Vector3;
import js.three.Quaternion;
import js.three.Matrix4;

class RapierPhysics {
    static var RAPIER_PATH: String = "https://cdn.skypack.dev/@dimforge/rapier3d-compat@0.12.0";
    static var frameRate: Int = 60;
    static var _scale: Vector3;
    static var ZERO: Vector3;
    static var RAPIER: Dynamic;

    static function getShape(geometry: { type: String, parameters: { width: Float, height: Float, depth: Float, radius: Float } }) : Dynamic {
        switch (geometry.type) {
            case "BoxGeometry":
                var sx: Float = geometry.parameters.width != null ? geometry.parameters.width / 2 : 0.5;
                var sy: Float = geometry.parameters.height != null ? geometry.parameters.height / 2 : 0.5;
                var sz: Float = geometry.parameters.depth != null ? geometry.parameters.depth / 2 : 0.5;
                return RAPIER.ColliderDesc.cuboid(sx, sy, sz);
            case "SphereGeometry":
            case "IcosahedronGeometry":
                var radius: Float = geometry.parameters.radius != null ? geometry.parameters.radius : 1;
                return RAPIER.ColliderDesc.ball(radius);
            default:
                return null;
        }
    }

    static async function init() : Void {
        if (RAPIER == null) {
            RAPIER = await js.dynamic($await(js.dynamic("import")("$RAPIER_PATH")));
            await RAPIER.init();
        }
    }

    static function addScene(scene: Dynamic) : Void {
        scene.traverse($ ({ isMesh: isMesh, userData: userData }) -> {
            if (isMesh && userData.physics != null) {
                addMesh(userData.mesh, userData.physics.mass, userData.physics.restitution);
            }
        });
    }

    static function addMesh(mesh: Dynamic, mass: Float = 0, restitution: Float = 0) : Void {
        var shape: Dynamic = getShape(mesh.geometry);
        if (shape == null) {
            return;
        }
        shape.setMass(mass);
        shape.setRestitution(restitution);
        var body: Dynamic = mesh.isInstancedMesh ? createInstancedBody(mesh, mass, shape) : createBody(mesh.position, mesh.quaternion, mass, shape);
        if (mass > 0) {
            meshes.push(mesh);
            meshMap.set(mesh, body);
        }
    }

    static function createInstancedBody(mesh: Dynamic, mass: Float, shape: Dynamic) : Array<Dynamic> {
        var array: Array<Float> = mesh.instanceMatrix.array;
        var bodies: Array<Dynamic> = [];
        for (i in 0...mesh.count) {
            var position: Vector3 = _vector.fromArray(array, i * 16 + 12);
            bodies.push(createBody(position, null, mass, shape));
        }
        return bodies;
    }

    static function createBody(position: Vector3, quaternion: Quaternion, mass: Float, shape: Dynamic) : Dynamic {
        var desc: Dynamic = mass > 0 ? RAPIER.RigidBodyDesc.dynamic() : RAPIER.RigidBodyDesc.fixed();
        desc.setTranslation(position.x, position.y, position.z);
        if (quaternion != null) {
            desc.setRotation(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
        }
        var body: Dynamic = world.createRigidBody(desc);
        world.createCollider(shape, body);
        return body;
    }

    static function setMeshPosition(mesh: Dynamic, position: Vector3, index: Int = 0) : Void {
        var body: Dynamic = meshMap.get(mesh);
        if (mesh.isInstancedMesh) {
            body = body[$index];
        }
        body.setAngvel(ZERO);
        body.setLinvel(ZERO);
        body.setTranslation(position.x, position.y, position.z);
    }

    static function setMeshVelocity(mesh: Dynamic, velocity: Vector3, index: Int = 0) : Void {
        var body: Dynamic = meshMap.get(mesh);
        if (mesh.isInstancedMesh) {
            body = body[$index];
        }
        body.setLinvel(velocity);
    }

    static function step() : Void {
        world.timestep = clock.getDelta();
        world.step();
        for (i in 0...meshes.length) {
            var mesh: Dynamic = meshes[$i];
            if (mesh.isInstancedMesh) {
                var array: Array<Float> = mesh.instanceMatrix.array;
                var bodies: Array<Dynamic> = meshMap.get(mesh);
                for (j in 0...bodies.length) {
                    var body: Dynamic = bodies[$j];
                    var position: Vector3 = body.translation();
                    _quaternion.copy(body.rotation());
                    _matrix.compose(position, _quaternion, _scale).toArray(array, j * 16);
                }
                mesh.instanceMatrix.needsUpdate = true;
                mesh.computeBoundingSphere();
            } else {
                var body: Dynamic = meshMap.get(mesh);
                mesh.position.copy(body.translation());
                mesh.quaternion.copy(body.rotation());
            }
        }
    }

    static var clock: Clock = new Clock();
    static var world: Dynamic;
    static var meshes: Array<Dynamic>;
    static var meshMap: Map<Dynamic, Dynamic>;
    static var _vector: Vector3;
    static var _quaternion: Quaternion;
    static var _matrix: Matrix4;

    static function new() : Void {
        _scale = new Vector3(1, 1, 1);
        ZERO = new Vector3(0, 0, 0);
        world = new RAPIER.World(new Vector3(0, -9.81, 0));
        meshes = [];
        meshMap = new Map();
        _vector = new Vector3();
        _quaternion = new Quaternion();
        _matrix = new Matrix4();
        setInterval(step, 1000 / frameRate);
    }
}

class Main {
    static function main() : Void {
        var physics: RapierPhysics = new RapierPhysics();
        // Add your scenes and meshes here
        physics.addScene(yourScene);
        // ...
    }
}