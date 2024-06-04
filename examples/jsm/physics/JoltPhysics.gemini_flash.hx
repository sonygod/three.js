import three.core.Clock;
import three.math.Vector3;
import three.math.Quaternion;
import three.math.Matrix4;
import three.objects.Mesh;
import three.objects.InstancedMesh;
import three.scenes.Scene;
import three.geometries.BoxGeometry;
import three.geometries.SphereGeometry;
import three.geometries.IcosahedronGeometry;

class JoltPhysics {

	static JOLT_PATH:String = "https://cdn.jsdelivr.net/npm/jolt-physics@0.23.0/dist/jolt-physics.wasm-compat.js";

	static frameRate:Int = 60;

	static Jolt:Dynamic = null;

	static getShape(geometry:Dynamic):Dynamic {

		var parameters = geometry.parameters;

		if (cast geometry.type == "BoxGeometry") {

			var sx = parameters.width != null ? parameters.width / 2 : 0.5;
			var sy = parameters.height != null ? parameters.height / 2 : 0.5;
			var sz = parameters.depth != null ? parameters.depth / 2 : 0.5;

			return new Jolt.BoxShape(new Jolt.Vec3(sx, sy, sz), 0.05 * Math.min(sx, sy, sz), null);

		} else if (cast geometry.type == "SphereGeometry" || cast geometry.type == "IcosahedronGeometry") {

			var radius = parameters.radius != null ? parameters.radius : 1;

			return new Jolt.SphereShape(radius, null);

		}

		return null;

	}

	static LAYER_NON_MOVING:Int = 0;
	static LAYER_MOVING:Int = 1;
	static NUM_OBJECT_LAYERS:Int = 2;

	static setupCollisionFiltering(settings:Dynamic) {

		var objectFilter = new Jolt.ObjectLayerPairFilterTable(NUM_OBJECT_LAYERS);
		objectFilter.EnableCollision(LAYER_NON_MOVING, LAYER_MOVING);
		objectFilter.EnableCollision(LAYER_MOVING, LAYER_MOVING);

		var BP_LAYER_NON_MOVING = new Jolt.BroadPhaseLayer(0);
		var BP_LAYER_MOVING = new Jolt.BroadPhaseLayer(1);
		var NUM_BROAD_PHASE_LAYERS:Int = 2;

		var bpInterface = new Jolt.BroadPhaseLayerInterfaceTable(NUM_OBJECT_LAYERS, NUM_BROAD_PHASE_LAYERS);
		bpInterface.MapObjectToBroadPhaseLayer(LAYER_NON_MOVING, BP_LAYER_NON_MOVING);
		bpInterface.MapObjectToBroadPhaseLayer(LAYER_MOVING, BP_LAYER_MOVING);

		settings.mObjectLayerPairFilter = objectFilter;
		settings.mBroadPhaseLayerInterface = bpInterface;
		settings.mObjectVsBroadPhaseLayerFilter = new Jolt.ObjectVsBroadPhaseLayerFilterTable(settings.mBroadPhaseLayerInterface, NUM_BROAD_PHASE_LAYERS, settings.mObjectLayerPairFilter, NUM_OBJECT_LAYERS);

	}

	static async init():Dynamic {

		if (Jolt == null) {

			var {default: initJolt} = await import(JOLT_PATH);
			Jolt = await initJolt();

		}

		var settings = new Jolt.JoltSettings();
		setupCollisionFiltering(settings);

		var jolt = new Jolt.JoltInterface(settings);
		Jolt.destroy(settings);

		var physicsSystem = jolt.GetPhysicsSystem();
		var bodyInterface = physicsSystem.GetBodyInterface();

		var meshes:Array<Mesh> = [];
		var meshMap = new WeakMap();

		var _position = new Vector3();
		var _quaternion = new Quaternion();
		var _scale = new Vector3(1, 1, 1);

		var _matrix = new Matrix4();

		function addScene(scene:Scene) {

			scene.traverse(function(child:Dynamic) {

				if (cast child.isMesh) {

					var physics = child.userData.physics;

					if (physics != null) {

						addMesh(child, physics.mass, physics.restitution);

					}

				}

			});

		}

		function addMesh(mesh:Mesh, mass:Float = 0, restitution:Float = 0) {

			var shape = getShape(mesh.geometry);

			if (shape == null) return;

			var body = cast mesh.isInstancedMesh ? createInstancedBody(mesh, mass, restitution, shape) : createBody(mesh.position, mesh.quaternion, mass, restitution, shape);

			if (mass > 0) {

				meshes.push(mesh);
				meshMap.set(mesh, body);

			}

		}

		function createInstancedBody(mesh:InstancedMesh, mass:Float, restitution:Float, shape:Dynamic):Array<Dynamic> {

			var array = mesh.instanceMatrix.array;

			var bodies:Array<Dynamic> = [];

			for (var i = 0; i < mesh.count; i++) {

				var position = _position.fromArray(array, i * 16 + 12);
				var quaternion = _quaternion.setFromRotationMatrix(_matrix.fromArray(array, i * 16)); // TODO Copilot did this
				bodies.push(createBody(position, quaternion, mass, restitution, shape));

			}

			return bodies;

		}

		function createBody(position:Vector3, rotation:Quaternion, mass:Float, restitution:Float, shape:Dynamic):Dynamic {

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

		function setMeshPosition(mesh:Mesh, position:Vector3, index:Int = 0) {

			if (cast mesh.isInstancedMesh) {

				var bodies = cast meshMap.get(mesh);

				var body = bodies[index];

				bodyInterface.RemoveBody(body.GetID());
				bodyInterface.DestroyBody(body.GetID());

				var physics = cast mesh.userData.physics;

				var shape = body.GetShape();
				var body2 = createBody(position, {x: 0, y: 0, z: 0, w: 1}, physics.mass, physics.restitution, shape);

				bodies[index] = body2;

			} else {

				// TODO: Implement this

			}

		}

		function setMeshVelocity(mesh:Mesh, velocity:Vector3, index:Int = 0) {

			/*
			let body = meshMap.get( mesh );

			if ( mesh.isInstancedMesh ) {

				body = body[ index ];

			}

			body.setLinvel( velocity );
			*/

		}

		//

		var clock = new Clock();

		function step() {

			var deltaTime = clock.getDelta();

			// Don't go below 30 Hz to prevent spiral of death
			deltaTime = Math.min(deltaTime, 1.0 / 30.0);

			// When running below 55 Hz, do 2 steps instead of 1
			var numSteps = deltaTime > 1.0 / 55.0 ? 2 : 1;

			// Step the physics world
			jolt.Step(deltaTime, numSteps);

			//

			for (var i = 0; i < meshes.length; i++) {

				var mesh = meshes[i];

				if (cast mesh.isInstancedMesh) {

					var array = mesh.instanceMatrix.array;
					var bodies = cast meshMap.get(mesh);

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

					var body = cast meshMap.get(mesh);

					var position = body.GetPosition();
					var rotation = body.GetRotation();

					mesh.position.set(position.GetX(), position.GetY(), position.GetZ());
					mesh.quaternion.set(rotation.GetX(), rotation.GetY(), rotation.GetZ(), rotation.GetW());

				}

			}

		}

		// animate

		setInterval(step, 1000 / frameRate);

		return {
			addScene: addScene,
			addMesh: addMesh,
			setMeshPosition: setMeshPosition,
			setMeshVelocity: setMeshVelocity
		};

	}

}

class JoltPhysicsSettings {

	mObjectLayerPairFilter:Dynamic;
	mBroadPhaseLayerInterface:Dynamic;
	mObjectVsBroadPhaseLayerFilter:Dynamic;

	new() {
		mObjectLayerPairFilter = null;
		mBroadPhaseLayerInterface = null;
		mObjectVsBroadPhaseLayerFilter = null;
	}

}

export {JoltPhysics};