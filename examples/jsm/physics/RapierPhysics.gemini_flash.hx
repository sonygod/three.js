import three.core.Clock;
import three.math.Vector3;
import three.math.Quaternion;
import three.math.Matrix4;

class RapierPhysics {

	static RAPIER_PATH:String = "https://cdn.skypack.dev/@dimforge/rapier3d-compat@0.12.0";
	static FRAME_RATE:Int = 60;
	static _SCALE:Vector3 = new Vector3(1, 1, 1);
	static ZERO:Vector3 = new Vector3();

	static RAPIER:Dynamic = null;

	public static function getShape(geometry:three.core.Geometry):Dynamic {

		var parameters = geometry.parameters;

		// TODO change type to is*

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

	public static function init():Dynamic {

		if (RAPIER == null) {

			RAPIER = js.Browser.window.import(RAPIER_PATH);
			RAPIER.init();

		}

		// Docs: https://rapier.rs/docs/api/javascript/JavaScript3D/

		var gravity = new Vector3(0.0, -9.81, 0.0);
		var world = new RAPIER.World(gravity);

		var meshes:Array<three.objects.Mesh> = [];
		var meshMap:WeakMap<three.objects.Mesh, Dynamic> = new WeakMap();

		var _vector = new Vector3();
		var _quaternion = new Quaternion();
		var _matrix = new Matrix4();

		function addScene(scene:three.scenes.Scene) {

			scene.traverse(function(child:three.core.Object3D) {

				if (child.isMesh) {

					var physics = child.userData.physics;

					if (physics != null) {

						addMesh(child, physics.mass, physics.restitution);

					}

				}

			});

		}

		function addMesh(mesh:three.objects.Mesh, mass:Float = 0, restitution:Float = 0) {

			var shape = getShape(mesh.geometry);

			if (shape == null) return;

			shape.setMass(mass);
			shape.setRestitution(restitution);

			var body = mesh.isInstancedMesh
							? createInstancedBody(mesh, mass, shape)
							: createBody(mesh.position, mesh.quaternion, mass, shape);

			if (mass > 0) {

				meshes.push(mesh);
				meshMap.set(mesh, body);

			}

		}

		function createInstancedBody(mesh:three.objects.Mesh, mass:Float, shape:Dynamic):Array<Dynamic> {

			var array = mesh.instanceMatrix.array;

			var bodies:Array<Dynamic> = [];

			for (var i = 0; i < mesh.count; i++) {

				var position = _vector.fromArray(array, i * 16 + 12);
				bodies.push(createBody(position, null, mass, shape));

			}

			return bodies;

		}

		function createBody(position:Vector3, quaternion:Quaternion, mass:Float, shape:Dynamic):Dynamic {

			var desc = mass > 0 ? RAPIER.RigidBodyDesc.dynamic() : RAPIER.RigidBodyDesc.fixed();
			desc.setTranslation(position.x, position.y, position.z);
			if (quaternion != null) desc.setRotation(quaternion);

			var body = world.createRigidBody(desc);
			world.createCollider(shape, body);

			return body;

		}

		function setMeshPosition(mesh:three.objects.Mesh, position:Vector3, index:Int = 0) {

			var body = meshMap.get(mesh);

			if (mesh.isInstancedMesh) {

				body = body[index];

			}

			body.setAngvel(ZERO);
			body.setLinvel(ZERO);
			body.setTranslation(position.x, position.y, position.z);

		}

		function setMeshVelocity(mesh:three.objects.Mesh, velocity:Vector3, index:Int = 0) {

			var body = meshMap.get(mesh);

			if (mesh.isInstancedMesh) {

				body = body[index];

			}

			body.setLinvel(velocity);

		}

		//

		var clock = new Clock();

		function step() {

			world.timestep = clock.getDelta();
			world.step();

			//

			for (var i = 0; i < meshes.length; i++) {

				var mesh = meshes[i];

				if (mesh.isInstancedMesh) {

					var array = mesh.instanceMatrix.array;
					var bodies = meshMap.get(mesh);

					for (var j = 0; j < bodies.length; j++) {

						var body = bodies[j];

						var position = body.translation();
						_quaternion.copy(body.rotation());

						_matrix.compose(position, _quaternion, _SCALE).toArray(array, j * 16);

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

		// animate

		js.Browser.window.setInterval(step, 1000 / FRAME_RATE);

		return {
			addScene: addScene,
			addMesh: addMesh,
			setMeshPosition: setMeshPosition,
			setMeshVelocity: setMeshVelocity
		};

	}

}