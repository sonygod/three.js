package three.js.examples.jsm.physics;

import three.Clock;
import three.Vector3;
import three.Quaternion;
import three.Matrix4;

// Note: JoltPhysics is not a standard Haxe library, so I'll assume it's a custom library
// and use a fictional `jolt` package.
import jolt.Jolt;
import jolt.JoltSettings;
import jolt.JoltInterface;
import jolt.BroadPhaseLayer;
import jolt.BroadPhaseLayerInterfaceTable;
import jolt.ObjectLayerPairFilterTable;
import jolt.ObjectVsBroadPhaseLayerFilterTable;
import jolt.BodyCreationSettings;
import jolt.BodyInterface;
import jolt.Vec3;
import jolt.Quat;

class JoltPhysics {
  static var JOLT_PATH = 'https://cdn.jsdelivr.net/npm/jolt-physics@0.23.0/dist/jolt-physics.wasm-compat.js';
  static var frameRate = 60;

  static var Jolt:Null<jolt.Jolt> = null;

  static function getShape(geometry:Dynamic) {
    var parameters = geometry.parameters;

    if (geometry.type == 'BoxGeometry') {
      var sx = parameters.width !== null ? parameters.width / 2 : 0.5;
      var sy = parameters.height !== null ? parameters.height / 2 : 0.5;
      var sz = parameters.depth !== null ? parameters.depth / 2 : 0.5;

      return new jolt.BoxShape(new jolt.Vec3(sx, sy, sz), 0.05 * Math.min(sx, sy, sz), null);
    } else if (geometry.type == 'SphereGeometry' || geometry.type == 'IcosahedronGeometry') {
      var radius = parameters.radius !== null ? parameters.radius : 1;

      return new jolt.SphereShape(radius, null);
    }

    return null;
  }

  // Object layers
  static var LAYER_NON_MOVING = 0;
  static var LAYER_MOVING = 1;
  static var NUM_OBJECT_LAYERS = 2;

  static function setupCollisionFiltering(settings:jolt.JoltSettings) {
    var objectFilter = new jolt.ObjectLayerPairFilterTable(NUM_OBJECT_LAYERS);
    objectFilter.enableCollision(LAYER_NON_MOVING, LAYER_MOVING);
    objectFilter.enableCollision(LAYER_MOVING, LAYER_MOVING);

    var BP_LAYER_NON_MOVING = new jolt.BroadPhaseLayer(0);
    var BP_LAYER_MOVING = new jolt.BroadPhaseLayer(1);
    var NUM_BROAD_PHASE_LAYERS = 2;

    var bpInterface = new jolt.BroadPhaseLayerInterfaceTable(NUM_OBJECT_LAYERS, NUM_BROAD_PHASE_LAYERS);
    bpInterface.mapObjectToBroadPhaseLayer(LAYER_NON_MOVING, BP_LAYER_NON_MOVING);
    bpInterface.mapObjectToBroadPhaseLayer(LAYER_MOVING, BP_LAYER_MOVING);

    settings.mObjectLayerPairFilter = objectFilter;
    settings.mBroadPhaseLayerInterface = bpInterface;
    settings.mObjectVsBroadPhaseLayerFilter = new jolt.ObjectVsBroadPhaseLayerFilterTable(bpInterface, NUM_BROAD_PHASE_LAYERS, objectFilter, NUM_OBJECT_LAYERS);
  }

  static function initJoltPhysics():{addScene:Dynamic->Void, addMesh:Dynamic->Void, setMeshPosition:Dynamic->Void, setMeshVelocity:Dynamic->Void} {
    if (Jolt == null) {
      // Load Jolt physics library
      var initJolt = js.Lib.load(JOLT_PATH, 'jolt-physics.wasm-compat.js');
      Jolt = initJolt();
    }

    var settings = new jolt.JoltSettings();
    setupCollisionFiltering(settings);

    var joltInterface = new jolt.JoltInterface(settings);
    Jolt.destroy(settings);

    var physicsSystem = joltInterface.getPhysicsSystem();
    var bodyInterface = physicsSystem.getBodyInterface();

    var meshes:Array<Dynamic> = [];
    var meshMap:WeakMap<Dynamic, Dynamic> = new WeakMap();

    var _position = new Vector3();
    var _quaternion = new Quaternion();
    var _scale = new Vector3(1, 1, 1);

    var _matrix = new Matrix4();

    function addScene(scene:Dynamic) {
      scene.traverse(function(child) {
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

      var body:Dynamic;

      if (mesh.isInstancedMesh) {
        body = createInstancedBody(mesh, mass, restitution, shape);
      } else {
        body = createBody(mesh.position, mesh.quaternion, mass, restitution, shape);
      }

      if (mass > 0) {
        meshes.push(mesh);
        meshMap.set(mesh, body);
      }
    }

    function createInstancedBody(mesh:Dynamic, mass:Float, restitution:Float, shape:Dynamic) {
      var array = mesh.instanceMatrix.array;

      var bodies:Array<Dynamic> = [];

      for (i in 0...mesh.count) {
        var position = _position.fromArray(array, i * 16 + 12);
        var quaternion = _quaternion.setFromRotationMatrix(_matrix.fromArray(array, i * 16));

        bodies.push(createBody(position, quaternion, mass, restitution, shape));
      }

      return bodies;
    }

    function createBody(position:Vector3, rotation:Quaternion, mass:Float, restitution:Float, shape:Dynamic) {
      var pos = new jolt.Vec3(position.x, position.y, position.z);
      var rot = new jolt.Quat(rotation.x, rotation.y, rotation.z, rotation.w);

      var motion = mass > 0 ? jolt.EMotionType_Dynamic : jolt.EMotionType_Static;
      var layer = mass > 0 ? LAYER_MOVING : LAYER_NON_MOVING;

      var creationSettings = new jolt.BodyCreationSettings(shape, pos, rot, motion, layer);
      creationSettings.mRestitution = restitution;

      var body = bodyInterface.createBody(creationSettings);

      bodyInterface.addBody(body.GetID(), jolt.EActivation_Activate);

      Jolt.destroy(creationSettings);

      return body;
    }

    function setMeshPosition(mesh:Dynamic, position:Vector3, index:Int = 0) {
      if (mesh.isInstancedMesh) {
        var bodies:Array<Dynamic> = meshMap.get(mesh);

        var body = bodies[index];

        bodyInterface.removeBody(body.GetID());
        bodyInterface.destroyBody(body.GetID());

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
      joltInterface.step(deltaTime, numSteps);

      for (i in 0...meshes.length) {
        var mesh = meshes[i];

        if (mesh.isInstancedMesh) {
          var bodies:Array<Dynamic> = meshMap.get(mesh);

          for (j in 0...bodies.length) {
            var body = bodies[j];

            var position = body.GetPosition();
            var quaternion = body.GetRotation();

            _position.set(position.GetX(), position.GetY(), position.GetZ());
            _quaternion.set(quaternion.GetX(), quaternion.GetY(), quaternion.GetZ(), quaternion.GetW());

            _matrix.compose(_position, _quaternion, _scale).toArray(mesh.instanceMatrix.array, j * 16);

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

    // Animate
    haxe.Timer.delay(step, 1000 / frameRate);

    return {
      addScene: addScene,
      addMesh: addMesh,
      setMeshPosition: setMeshPosition,
      setMeshVelocity: setMeshVelocity
    };
  }
}