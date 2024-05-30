import js.Browser.window;
import js.three.Clock;
import js.three.Matrix4;
import js.three.Quaternion;
import js.three.Vector3;

class JoltPhysics {
    static var JOLT_PATH:String = "https://cdn.jsdelivr.net/npm/jolt-physics@0.23.0/dist/jolt-physics.wasm-compat.js";
    static var jolt:JoltInterface;
    static var frameRate:Int = 60;
    static var clock:Clock;
    static var meshes:Array<Dynamic>;
    static var meshMap:WeakMap<Dynamic,Dynamic>;
    static var _position:Vector3;
    static var _quaternion:Quaternion;
    static var _scale:Vector3;
    static var _matrix:Matrix4;

    static function getShape(geometry:Dynamic) {
        var parameters = geometry.parameters;
        if (geometry.type == "BoxGeometry") {
            var sx = parameters.width != null ? parameters.width / 2 : 0.5;
            var sy = parameters.height != null ? parameters.height / 2 : 0.5;
            var sz = parameters.depth != null ? parameters.depth / 2 : 0.5;
            return new jolt.BoxShape(new jolt.Vec3(sx, sy, sz), 0.05 * Math.min(sx, sy, sz), null);
        } else if (geometry.type == "SphereGeometry" || geometry.type == "IcosahedronGeometry") {
            var radius = parameters.radius != null ? parameters.radius : 1;
            return new jolt.SphereShape(radius, null);
        }
        return null;
    }

    static function setupCollisionFiltering(settings:Dynamic) {
        var objectFilter = new jolt.ObjectLayerPairFilterTable(2);
        objectFilter.EnableCollision(0, 1);
        objectFilter.EnableCollision(1, 1);

        var BP_LAYER_NON_MOVING = new jolt.BroadPhaseLayer(0);
        var BP_LAYER_MOVING = new jolt.BroadPhaseLayer(1);
        var NUM_BROAD_PHASE_LAYERS = 2;

        var bpInterface = new jolt.BroadPhaseLayerInterfaceTable(2, NUM_BROAD_PHASE_LAYERS);
        bpInterface.MapObjectToBroadPhaseLayer(0, BP_LAYER_NON_MOVING);
        bpInterface.MapObjectToBroadPhaseLayer(1, BP_LAYER_MOVING);

        settings.mObjectLayerPairFilter = objectFilter;
        settings.mBroadPhaseLayerInterface = bpInterface;
        settings.mObjectVsBroadPhaseLayerFilter = new jolt.ObjectVsBroadPhaseLayerFilterTable(bpInterface, NUM_BROAD_PHASE_LAYERS, objectFilter, 2);
    }

    static async function init() {
        if (jolt == null) {
            var initJolt = await js.dynamic({ default : null }).from(await js.lib.fetch(JOLT_PATH));
            jolt = await initJolt();
        }

        var settings = new jolt.JoltSettings();
        setupCollisionFiltering(settings);

        jolt = new JoltInterface(settings);

        var physicsSystem = jolt.GetPhysicsSystem();
        var bodyInterface = physicsSystem.GetBodyInterface();

        meshes = [];
        meshMap = new WeakMap();

        _position = new Vector3();
        _quaternion = new Quaternion();
        _scale = new Vector3(1, 1, 1);
        _matrix = new Matrix4();
    }

    static function addScene(scene:Dynamic) {
        scene.traverse(function (child) {
            if (child.isMesh) {
                var physics = child.userData.physics;
                if (physics != null) {
                    addMesh(child, physics.mass, physics.restitution);
                }
            }
        });
    }

    static function addMesh(mesh:Dynamic, mass:Float = 0, restitution:Float = 0) {
        var shape = getShape(mesh.geometry);
        if (shape == null) return;

        var body = mesh.isInstancedMesh ? createInstancedBody(mesh, mass, restitution, shape) : createBody(mesh.position, mesh.quaternion, mass, restitution, shape);

        if (mass > 0) {
            meshes.push(mesh);
            meshMap.set(mesh, body);
        }
    }

    static function createInstancedBody(mesh:Dynamic, mass:Float, restitution:Float, shape:Dynamic) {
        var array = mesh.instanceMatrix.array;
        var bodies = [];

        for (i in 0...mesh.count) {
            var position = _position.fromArray(array, i * 16 + 12);
            var quaternion = _quaternion.setFromRotationMatrix(_matrix.fromArray(array, i * 16));
            bodies.push(createBody(position, quaternion, mass, restitution, shape));
        }

        return bodies;
    }

    static function createBody(position:Dynamic, rotation:Dynamic, mass:Float, restitution:Float, shape:Dynamic) {
        var pos = new jolt.Vec3(position.x, position.y, position.z);
        var rot = new jolt.Quat(rotation.x, rotation.y, rotation.z, rotation.w);

        var motion = mass > 0 ? jolt.EMotionType_Dynamic : jolt.EMotionType_Static;
        var layer = mass > 0 ? 1 : 0;

        var creationSettings = new jolt.BodyCreationSettings(shape, pos, rot, motion, layer);
        creationSettings.mRestitution = restitution;

        var body = bodyInterface.CreateBody(creationSettings);
        bodyInterface.AddBody(body.GetID(), jolt.EActivation_Activate);

        creationSettings.free();

        return body;
    }

    static function setMeshPosition(mesh:Dynamic, position:Dynamic, index:Int = 0) {
        if (mesh.isInstancedMesh) {
            var bodies = meshMap.get(mesh);
            var body = bodies[index];

            bodyInterface.RemoveBody(body.GetID());
            bodyInterface.DestroyBody(body.GetID());

            var physics = mesh.userData.physics;
            var shape = body.GetShape();
            var body2 = createBody(position, { x: 0, y: 0, z: 0, w: 1 }, physics.mass, physics.restitution, shape);

            bodies[index] = body2;
        } else {
            // TODO: Implement this
        }
    }

    static function setMeshVelocity(mesh:Dynamic, velocity:Dynamic, index:Int = 0) {
        /*
        let body = meshMap.get(mesh);

        if (mesh.isInstancedMesh) {
            body = body[index];
        }

        body.setLinvel(velocity);
        */
    }

    static function step() {
        var deltaTime = clock.getDelta();

        // Don't go below 30 Hz to prevent spiral of death
        deltaTime = Math.min(deltaTime, 1.0 / 30.0);

        // When running below 55 Hz, do 2 steps instead of 1
        var numSteps = deltaTime > 1.0 / 55.0 ? 2 : 1;

        // Step the physics world
        jolt.Step(deltaTime, numSteps);

        for (i in 0...meshes.length) {
            var mesh = meshes[i];

            if (mesh.isInstancedMesh) {
                var array = mesh.instanceMatrix.array;
                var bodies = meshMap.get(mesh);

                for (j in 0...bodies.length) {
                    var body = bodies[j];
                    var position = body.GetPosition();
                    var quaternion = body.GetRotation();

                    _position.set(position.GetX(), position.GetY(), position.GetZ());
                    _quaternion.set(quaternion.GetX(), quaternion.GetY(), quaternion.GetZ(), quaternion.GetW());

                    _matrix.compose(_position, _quaternion, _scale).toArray(array, j * 16);
                }

                mesh.instanceMatrix.needsUpdate = true;
                mesh.computeBoundingSphere();
            } else {
                var body = meshMap.get(mesh);
                var position = body.GetPosition();
                var rotation = body.GetRotation();

                mesh.position.set(position.GetX(), position.GetY(), position.GetZ());
                mesh.quaternion.set(rotation.GetX(), rotation.GetY(), rotation.GetZ(), rotation.GetW());
            }
        }
    }

    static function animate() {
        window.setInterval(step, 1000 / frameRate);
    }
}

class Main {
    static function main() {
        JoltPhysics.init();
        JoltPhysics.addScene(window.scene);
        JoltPhysics.animate();
    }
}