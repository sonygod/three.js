package three.js.examples.jsm.physics;

import js.html.Vector3;
import js.html.Quaternion;
import js.html.Matrix4;
import js.lib.Promise;

// Define constants
inline final JOLT_PATH = 'https://cdn.jsdelivr.net/npm/jolt-physics@0.23.0/dist/jolt-physics.wasm-compat.js';
inline final FRAME_RATE = 60;

class JoltPhysics {
  static var jolt:Dynamic = null;

  static function getShape(geometry:Any):Dynamic {
    // ...
  }

  static function setupCollisionFiltering(settings:Any) {
    // ...
  }

  static async function initJolt() {
    if (jolt == null) {
      var initJolt:Dynamic = await Js.import_(JOLT_PATH);
      jolt = await initJolt();
    }
  }

  static function createJoltInterface(settings:Any) {
    initJolt().then(_ -> {
      var joltInterface = new jolt.JoltInterface(settings);
      Jolt.destroy(settings);
      return joltInterface;
    });
  }

  static function addScene(scene:Any) {
    // ...
  }

  static function addMesh(mesh:Any, mass:Float = 0, restitution:Float = 0) {
    // ...
  }

  static function createInstancedBody(mesh:Any, mass:Float, restitution:Float, shape:Any) {
    // ...
  }

  static function createBody(position:Any, rotation:Any, mass:Float, restitution:Float, shape:Any) {
    // ...
  }

  static function setMeshPosition(mesh:Any, position:Any, index:Int = 0) {
    // ...
  }

  static function setMeshVelocity(mesh:Any, velocity:Any, index:Int = 0) {
    // ...
  }

  static function step(clock:Clock) {
    // ...
  }

  public static function main() {
    var clock = new Clock();
    var meshes:Array<Any> = [];
    var meshMap:WeakMap<Any, Any> = new WeakMap();

    createJoltInterface(new jolt.JoltSettings()).then(joltInterface -> {
      var physicsSystem = joltInterface.GetPhysicsSystem();
      var bodyInterface = physicsSystem.GetBodyInterface();

      // ...

      var stepFunction = function() {
        step(clock);
        haxe.Timer.delay(stepFunction, 1000 / FRAME_RATE);
      };
      stepFunction();
    });
  }
}