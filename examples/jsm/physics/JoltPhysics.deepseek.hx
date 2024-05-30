import three.Clock;
import three.Vector3;
import three.Quaternion;
import three.Matrix4;

@:expose
class JoltPhysics {

    static var JOLT_PATH = 'https://cdn.jsdelivr.net/npm/jolt-physics@0.23.0/dist/jolt-physics.wasm-compat.js';

    static var frameRate = 60;

    static var Jolt:Dynamic = null;

    static function getShape(geometry:Dynamic):Dynamic {

        var parameters = geometry.parameters;

        if (geometry.type == 'BoxGeometry') {

            var sx = parameters.width != undefined ? parameters.width / 2 : 0.5;
            var sy = parameters.height != undefined ? parameters.height / 2 : 0.5;
            var sz = parameters.depth != undefined ? parameters.depth / 2 : 0.5;

            return new Jolt.BoxShape(new Jolt.Vec3(sx, sy, sz), 0.05 * Math.min(sx, sy, sz), null);

        } else if (geometry.type == 'SphereGeometry' || geometry.type == 'IcosahedronGeometry') {

            var radius = parameters.radius != undefined ? parameters.radius : 1;

            return new Jolt.SphereShape(radius, null);

        }

        return null;

    }

    static var LAYER_NON_MOVING = 0;
    static var LAYER_MOVING = 1;
    static var NUM_OBJECT_LAYERS = 2;

    static function setupCollisionFiltering(settings:Dynamic):Void {

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

    };

    static function JoltPhysics():Dynamic {

        if (Jolt == null) {

            var initJolt = js.Browser.require(JOLT_PATH);
            Jolt = initJolt();

        }

        var settings = new Jolt.JoltSettings();
        setupCollisionFiltering(settings);

        var jolt = new Jolt.JoltInterface(settings);
        Jolt.destroy(settings);

        var physicsSystem = jolt.GetPhysicsSystem();
        var bodyInterface = physicsSystem.GetBodyInterface();

        var meshes = [];
        var meshMap = new js.Map();

        var _position = new Vector3();
        var _quaternion = new Quaternion();
        var _scale = new Vector3(1, 1, 1);

        var _matrix = new Matrix4();

        function addScene(scene:Dynamic):Void {

            scene.traverse(function (child:Dynamic) {

                if (child.isMesh) {

                    var physics = child.userData.physics;

                    if (physics) {

                        addMesh(child, physics.mass, physics.restitution);

                    }

                }

            });

        }

        function addMesh(mesh:Dynamic, mass:Float = 0, restitution:Float = 0):Void {

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

        function createInstancedBody(mesh:Dynamic, mass:Float, restitution:Float, shape:Dynamic):Dynamic {

            var array = mesh.instanceMatrix.array;

            var bodies = [];

            for (i in 0...mesh.count) {

                var position = _position.fromArray(array, i * 16 + 12);
                var quaternion = _quaternion.setFromRotationMatrix(_matrix.fromArray(array, i * 16));
                bodies.push(createBody(position, quaternion, mass, restitution, shape));

            }

            return bodies;

        }

        function createBody(position:Dynamic, rotation:Dynamic, mass:Float, restitution:Float, shape:Dynamic):Dynamic {

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

        function setMeshPosition(mesh:Dynamic, position:Dynamic, index:Int = 0):Void {

            if (mesh.isInstancedMesh) {

                var bodies = meshMap.get(mesh);

                var body = bodies[index];

                bodyInterface.RemoveBody(body.GetID());
                bodyInterface.DestroyBody(body.GetID());

                var physics = mesh.userData.physics;

                var shape = body.GetShape();
                var body2 = createBody(position, {x: 0, y: 0, z: 0, w: 1}, physics.mass, physics.restitution, shape);

                bodies[index] = body2;

            } else {

                // TODO: Implement this

            }

        }

        function setMeshVelocity(mesh:Dynamic, velocity:Dynamic, index:Int = 0):Void {

            // TODO: Implement this

        }

        var clock = new Clock();

        function step():Void {

            var deltaTime = clock.getDelta();

            deltaTime = Math.min(deltaTime, 1.0 / 30.0);

            var numSteps = deltaTime > 1.0 / 55.0 ? 2 : 1;

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

        js.setInterval(step, 1000 / frameRate);

        return {
            addScene: addScene,
            addMesh: addMesh,
            setMeshPosition: setMeshPosition,
            setMeshVelocity: setMeshVelocity
        };

    }

}