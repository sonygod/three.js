package three.js.examples.jsm.physics;

import js.Browser;
import js.html.performance.Performance;
import Ammo.*;

class AmmoPhysics {
  static async function init():Promise<AmmoPhysics> {
    if (!Browser.window.Ammo) {
      Browser.console.error('AmmoPhysics: Couldn\'t find Ammo.js');
      return null;
    }

    var AmmoLib:Ammo = await Ammo();

    var frameRate:Int = 60;

    var collisionConfiguration:btDefaultCollisionConfiguration = new btDefaultCollisionConfiguration();
    var dispatcher:btCollisionDispatcher = new btCollisionDispatcher(collisionConfiguration);
    var broadphase:btDbvtBroadphase = new btDbvtBroadphase();
    var solver:btSequentialImpulseConstraintSolver = new btSequentialImpulseConstraintSolver();
    var world:btDiscreteDynamicsWorld = new btDiscreteDynamicsWorld(dispatcher, broadphase, solver, collisionConfiguration);
    world.setGravity(new btVector3(0, -9.8, 0));

    var worldTransform:btTransform = new btTransform();

    var meshes:Array<Mesh> = [];
    var meshMap:WeakMap<Mesh, btRigidBody> = new WeakMap();

    function getShape(geometry:Geometry):btCollisionShape {
      // ...
    }

    function addScene(scene:Object3D):Void {
      scene.traverse(function(child:Object3D) {
        if (child.isMesh) {
          var physics:Physics = child.userData.physics;
          if (physics) {
            addMesh(child, physics.mass);
          }
        }
      });
    }

    function addMesh(mesh:Mesh, mass:Float = 0):Void {
      var shape:btCollisionShape = getShape(mesh.geometry);
      if (shape != null) {
        if (mesh.isInstancedMesh) {
          handleInstancedMesh(mesh, mass, shape);
        } else if (mesh.isMesh) {
          handleMesh(mesh, mass, shape);
        }
      }
    }

    function handleMesh(mesh:Mesh, mass:Float, shape:btCollisionShape):Void {
      // ...
    }

    function handleInstancedMesh(mesh:InstancedMesh, mass:Float, shape:btCollisionShape):Void {
      // ...
    }

    function setMeshPosition(mesh:Mesh, position:Vector3, index:Int = 0):Void {
      // ...
    }

    var lastTime:Float = 0;

    function step():Void {
      var time:Float = Browser.performance.now().getTime();
      if (lastTime > 0) {
        var delta:Float = (time - lastTime) / 1000;
        world.stepSimulation(delta, 10);

        for (mesh in meshes) {
          // ...
        }
      }
      lastTime = time;
    }

    Browser/setInterval(step, 1000 / frameRate);

    return {
      addScene: addScene,
      addMesh: addMesh,
      setMeshPosition: setMeshPosition
    };
  }
}