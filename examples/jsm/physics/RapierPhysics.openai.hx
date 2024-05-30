import js.three.Clock;
import js.three.Vector3;
import js.three.Quaternion;
import js.three.Matrix4;

class RapierPhysics {
  static var RAPIER_PATH = "https://cdn.skypack.dev/@dimforge/rapier3d-compat@0.12.0";

  static var frameRate = 60;

  static var _scale = new Vector3(1, 1, 1);
  static var ZERO = new Vector3();

  static var RAPIER:Dynamic = null;

  static function getShape(geometry:js.three.Geometry) {
    var parameters = geometry.parameters;

    if (geometry.type == "BoxGeometry") {
      var sx = parameters.width != null ? parameters.width / 2 : 0.5;
      var sy = parameters.height != null ? parameters.height / 2 : 0.5;
      var sz = parameters.depth != null ? parameters.depth / 2 : 0.5;

      return RAPIER.ColliderDesc.cuboid(sx, sy, sz);
    } else if (geometry.type == "SphereGeometry" || geometry.type == "IcosahedronGeometry") {
      var radius = parameters.radius != null ? parameters.radius : 1;
      return RAPIER.ColliderDesc.ball(radius);
    }

    return null;
  }

  static async function init() {
    if (RAPIER == null) {
      RAPIER = await js.Browser.fetch(RAPIER_PATH + "/dist/rapier.js");
      await RAPIER.init();
    }

    var gravity = new Vector3(0, -9.81, 0);
    var world = new RAPIER.World(gravity);

    var meshes:Array<js.three.Mesh> = [];
    var meshMap:Map<js.three.Mesh, RAPIER.RigidBody> = new Map();

    var _vector = new Vector3();
    var _quaternion = new Quaternion();
    var _matrix = new Matrix4();

    function addScene(scene:js.three.Scene) {
      scene.traverse(function(child) {
        if (child.isMesh) {
          var physics:Dynamic = child.userData.physics;
          if (physics != null) {
            addMesh(child, physics.mass, physics.restitution);
          }
        }
      });
    }

    function addMesh(mesh:js.three.Mesh, mass:Float = 0, restitution:Float = 0) {
      var shape = getShape(mesh.geometry);
      if (shape == null) return;

      shape.setMass(mass);
      shape.setRestitution(restitution);

      var body:RAPIER.RigidBody;
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

    function createInstancedBody(mesh:js.three.Mesh, mass:Float, shape:RAPIER.ColliderDesc) {
      var array:Array<Float> = mesh.instanceMatrix.array;

      var bodies:Array<RAPIER.RigidBody> = [];

      for (i in 0...mesh.count) {
        var position = _vector.fromArray(array, i * 16 + 12);
        bodies.push(createBody(position, null, mass, shape));
      }

      return bodies;
    }

    function createBody(position:Vector3, quaternion:Quaternion, mass:Float, shape:RAPIER.ColliderDesc) {
      var desc:RAPIER.RigidBodyDesc;
      if (mass > 0) {
        desc = RAPIER.RigidBodyDesc.dynamic();
      } else {
        desc = RAPIER.RigidBodyDesc.fixed();
      }
      desc.setTranslation(position.x, position.y, position.z);
      if (quaternion != null) desc.setRotation(quaternion);

      var body = world.createRigidBody(desc);
      world.createCollider(shape, body);

      return body;
    }

    function setMeshPosition(mesh:js.three.Mesh, position:Vector3, index:Int = 0) {
      var body:RAPIER.RigidBody = meshMap.get(mesh);

      if (mesh.isInstancedMesh) {
        body = body[index];
      }

      body.setAngvel(ZERO);
      body.setLinvel(ZERO);
      body.setTranslation(position);
    }

    function setMeshVelocity(mesh:js.three.Mesh, velocity:Vector3, index:Int = 0) {
      var body:RAPIER.RigidBody = meshMap.get(mesh);

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
          var array:Array<Float> = mesh.instanceMatrix.array;
          var bodies:Array<RAPIER.RigidBody> = meshMap.get(mesh);

          for (j in 0...bodies.length) {
            var body:RAPIER.RigidBody = bodies[j];
            var position:Vector3 = body.translation();
            _quaternion.copy(body.rotation());

            _matrix.compose(position, _quaternion, _scale).toArray(array, j * 16);

          }

          mesh.instanceMatrix.needsUpdate = true;
          mesh.computeBoundingSphere();
        } else {
          var body:RAPIER.RigidBody = meshMap.get(mesh);
          mesh.position.copy(body.translation());
          mesh.quaternion.copy(body.rotation());
        }
      }
    }

    // animate
    js.Browser.window.setInterval(step, 1000 / frameRate);

    return {
      addScene: addScene,
      addMesh: addMesh,
      setMeshPosition: setMeshPosition,
      setMeshVelocity: setMeshVelocity
    };
  }
}