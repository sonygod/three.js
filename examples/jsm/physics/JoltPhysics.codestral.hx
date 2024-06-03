import js.html.Window;
import js.html.WebSocket;
import js.html.WebSocketExt;
import js.html.WebSocketFlags;
import three.Clock;
import three.Vector3;
import three.Quaternion;
import three.Matrix4;

class JoltPhysics {
    static var JOLT_PATH:String = "https://cdn.jsdelivr.net/npm/jolt-physics@0.23.0/dist/jolt-physics.wasm-compat.js";
    static var frameRate:Int = 60;
    static var Jolt:Dynamic = null;

    static function getShape(geometry:Dynamic):Dynamic {
        var parameters = geometry.parameters;

        if (geometry.type == 'BoxGeometry') {
            var sx = parameters.hasOwnProperty('width') ? parameters.width / 2 : 0.5;
            var sy = parameters.hasOwnProperty('height') ? parameters.height / 2 : 0.5;
            var sz = parameters.hasOwnProperty('depth') ? parameters.depth / 2 : 0.5;

            return new Jolt.BoxShape(new Jolt.Vec3(sx, sy, sz), 0.05 * Math.min(sx, sy, sz), null);
        } else if (geometry.type == 'SphereGeometry' || geometry.type == 'IcosahedronGeometry') {
            var radius = parameters.hasOwnProperty('radius') ? parameters.radius : 1;

            return new Jolt.SphereShape(radius, null);
        }

        return null;
    }

    static var LAYER_NON_MOVING:Int = 0;
    static var LAYER_MOVING:Int = 1;
    static var NUM_OBJECT_LAYERS:Int = 2;

    static function setupCollisionFiltering(settings:Dynamic) {
        var objectFilter = new Jolt.ObjectLayerPairFilterTable(NUM_OBJECT_LAYERS);
        objectFilter.EnableCollision(LAYER_NON_MOVING, LAYER_MOVING);
        objectFilter.EnableCollision(LAYER_MOVING, LAYER_MOVING);

        var BP_LAYER_NON_MOVING = new Jolt.BroadPhaseLayer(0);
        var BP_LAYER_MOVING = new Jolt.BroadPhaseLayer(1);
        var NUM_BROAD_PHASE_LAYERS = 2;

        var bpInterface = new Jolt.BroadPhaseLayerInterfaceTable(NUM_OBJECT_LAYERS, NUM_BROAD_PHASE_LAYERS);
        bpInterface.MapObjectToBroadPhaseLayer(LAYER_NON_MOVING, BP_LAYER_NON_MOVING);
        bpInterface.MapObjectToBroadPhaseLayer(LAYER_MOVING, BP_LAYER_MOVING);

        settings.mObjectLayerPairFilter = objectFilter;
        settings.mBroadPhaseLayerInterface = bpInterface;
        settings.mObjectVsBroadPhaseLayerFilter = new Jolt.ObjectVsBroadPhaseLayerFilterTable(settings.mBroadPhaseLayerInterface, NUM_BROAD_PHASE_LAYERS, settings.mObjectLayerPairFilter, NUM_OBJECT_LAYERS);
    }

    static async function init() {
        if (Jolt == null) {
            var ws = new WebSocket(JOLT_PATH);
            ws.onopen = function(_) {
                ws.send("init");
            };
            ws.onmessage = function(e) {
                Jolt = js.JSON.parse(e.data);
                JoltPhysics.setup();
            };
        } else {
            JoltPhysics.setup();
        }
    }

    static function setup() {
        var settings = new Jolt.JoltSettings();
        setupCollisionFiltering(settings);

        var jolt = new Jolt.JoltInterface(settings);
        Jolt.destroy(settings);

        var physicsSystem = jolt.GetPhysicsSystem();
        var bodyInterface = physicsSystem.GetBodyInterface();

        var meshes = [];
        var meshMap = new haxe.ds.WeakMap();

        var _position = new Vector3();
        var _quaternion = new Quaternion();
        var _scale = new Vector3(1, 1, 1);

        var _matrix = new Matrix4();

        function addScene(scene:Dynamic) {
            scene.traverse(function(child:Dynamic) {
                if (child.isMesh) {
                    var physics = child.userData.physics;

                    if (physics) {
                        addMesh(child, physics.mass, physics.restitution);
                    }
                }
            });
        }

        function addMesh(mesh:Dynamic, mass:Float = 0, restitution:Float = 0) {
            var shape = getShape(mesh.geometry);

            if (shape == null) return;

            var body = mesh.isInstancedMesh
                        ? createInstancedBody(mesh, mass, restitution, shape)
                        : createBody(mesh.position, mesh.quaternion, mass, restitution, shape);

            if (mass > 0) {
                meshes.push(mesh);
                meshMap.set(mesh, body);
            }
        }

        function createInstancedBody(mesh:Dynamic, mass:Float, restitution:Float, shape:Dynamic) {
            var array = mesh.instanceMatrix.array;

            var bodies = [];

            for (var i = 0; i < mesh.count; i++) {
                var position = _position.fromArray(array, i * 16 + 12);
                var quaternion = _quaternion.setFromRotationMatrix(_matrix.fromArray(array, i * 16));
                bodies.push(createBody(position, quaternion, mass, restitution, shape));
            }

            return bodies;
        }

        function createBody(position:Vector3, rotation:Quaternion, mass:Float, restitution:Float, shape:Dynamic) {
            var pos = new Jolt.Vec3(position.x, position.y, position.z);
            var rot = new Jolt.Quat(rotation.x, rotation.y, rotation.z, rotation.w);

            var motion = mass > 0 ? Jolt.EMotionType_Dynamic : Jolt.EMotionType_Static;
            var layer = mass > 0 ? LAYER_MOVING : LAYER_NON_MOVING;

            var creationSettings = new Jolt.BodyCreationSettings(shape, pos, rot, motion, layer);
            creationSettings.mRestitution = restitution;

            var body = bodyInterface.CreateBody(creationSettings);

            bodyInterface.AddBody(body.GetID(), Jolt.EActivation_Activate);

            Jolt.destroy(creationSettings);

            return body;
        }

        function setMeshPosition(mesh:Dynamic, position:Vector3, index:Int = 0) {
            if (mesh.isInstancedMesh) {
                var bodies = meshMap.get(mesh);

                var body = bodies[index];

                bodyInterface.RemoveBody(body.GetID());
                bodyInterface.DestroyBody(body.GetID());

                var physics = mesh.userData.physics;

                var shape = body.GetShape();
                var body2 = createBody(position, new Quaternion(0, 0, 0, 1), physics.mass, physics.restitution, shape);

                bodies[index] = body2;
            } else {
                // TODO: Implement this
            }
        }

        function setMeshVelocity(mesh:Dynamic, velocity:Vector3, index:Int = 0) {
            // TODO: Implement this
        }

        var clock = new Clock();

        function step() {
            var deltaTime = clock.getDelta();

            // Don't go below 30 Hz to prevent spiral of death
            deltaTime = Math.min(deltaTime, 1.0 / 30.0);

            // When running below 55 Hz, do 2 steps instead of 1
            var numSteps = deltaTime > 1.0 / 55.0 ? 2 : 1;

            // Step the physics world
            jolt.Step(deltaTime, numSteps);

            for (var i = 0, l = meshes.length; i < l; i++) {
                var mesh = meshes[i];

                if (mesh.isInstancedMesh) {
                    var array = mesh.instanceMatrix.array;
                    var bodies = meshMap.get(mesh);

                    for (var j = 0; j < bodies.length; j++) {
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

        // animate
        new haxe.Timer(1000 / frameRate).run = step;

        return {
            addScene: addScene,
            addMesh: addMesh,
            setMeshPosition: setMeshPosition,
            setMeshVelocity: setMeshVelocity
        };
    }
}

class Main {
    static function main() {
        JoltPhysics.init();
    }
}