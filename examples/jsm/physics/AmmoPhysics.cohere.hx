import js.Browser.window;
import js.html.Performance;

typedef AmmoLib = {
	btDefaultCollisionConfiguration: @:native("Ammo.btDefaultCollisionConfiguration"),
	btCollisionDispatcher: @:native("Ammo.btCollisionDispatcher"),
	btDbvtBroadphase: @:native("Ammo.btDbvtBroadphase"),
	btSequentialImpulseConstraintSolver: @:native("Ammo.btSequentialImpulseConstraintSolver"),
	btDiscreteDynamicsWorld: @:native("Ammo.btDiscreteDynamicsWorld"),
	btVector3: @:native("Ammo.btVector3"),
	btTransform: @:native("Ammo.btTransform"),
	btBoxShape: @:native("Ammo.btBoxShape"),
	btSphereShape: @:native("Ammo.btSphereShape"),
	btDefaultMotionState: @:native("Ammo.btDefaultMotionState"),
	btRigidBodyConstructionInfo: @:native("Ammo.btRigidBodyConstructionInfo"),
	btRigidBody: @:native("Ammo.btRigidBody"),
};

async function AmmoPhysics() {
	if (!Reflect.field(window, 'Ammo')) {
		trace('AmmoPhysics: Couldn\'t find Ammo.js');
		return;
	}

	var AmmoLib = await Ammo();

	var frameRate = 60;
	var collisionConfiguration = new AmmoLib.btDefaultCollisionConfiguration();
	var dispatcher = new AmmoLib.btCollisionDispatcher(collisionConfiguration);
	var broadphase = new AmmoLib.btDbvtBroadphase();
	var solver = new AmmoLib.btSequentialImpulseConstraintSolver();
	var world = new AmmoLib.btDiscreteDynamicsWorld(dispatcher, broadphase, solver, collisionConfiguration);
	world.setGravity(new AmmoLib.btVector3(0, -9.8, 0));

	var worldTransform = new AmmoLib.btTransform();

	function getShape(geometry:Dynamic) : AmmoLib.btBoxShape/{
		var parameters = geometry.parameters;

		if (Reflect.hasField(geometry, 'type') && geometry.type == 'BoxGeometry') {
			var sx = parameters.width != null ? parameters.width / 2 : 0.5;
			var sy = parameters.height != null ? parameters.height / 2 : 0.5;
			var sz = parameters.depth != null ? parameters.depth / 2 : 0.5;

			var shape = new AmmoLib.btBoxShape(new AmmoLib.btVector3(sx, sy, sz));
			shape.setMargin(0.05);
			return shape;
		} else if (Reflect.hasField(geometry, 'type') && (geometry.type == 'SphereGeometry' || geometry.type == 'IcosahedronGeometry')) {
			var radius = parameters.radius != null ? parameters.radius : 1;

			var shape = new AmmoLib.btSphereShape(radius);
			shape.setMargin(0.05);
			return shape;
		}
		return null;
	}

	var meshes = [];
	var meshMap = new WeakMap<Dynamic, AmmoLib.btRigidBody>();

	function addScene(scene:Dynamic) {
		scene.traverse(function (child:Dynamic) {
			if (Reflect.hasField(child, 'isMesh') && child.isMesh) {
				var physics = Reflect.field(child, 'userData')?.physics;
				if (physics != null) {
					addMesh(child, physics.mass);
				}
			}
		});
	}

	function addMesh(mesh:Dynamic, mass:Float = 0.) {
		var shape = getShape(mesh.geometry);
		if (shape != null) {
			if (Reflect.hasField(mesh, 'isInstancedMesh') && mesh.isInstancedMesh) {
				handleInstancedMesh(mesh, mass, shape);
			} else if (Reflect.hasField(mesh, 'isMesh') && mesh.isMesh) {
				handleMesh(mesh, mass, shape);
			}
		}
	}

	function handleMesh(mesh:Dynamic, mass:Float, shape:AmmoLib.btBoxShape/) {
		var position = mesh.position;
		var quaternion = mesh.quaternion;

		var transform = new AmmoLib.btTransform();
		transform.setIdentity();
		transform.setOrigin(new AmmoLib.btVector3(position.x, position.y, position.z));
		transform.setRotation(new AmmoLib.btQuaternion(quaternion.x, quaternion.y, quaternion.z, quaternion.w));

		var motionState = new AmmoLib.btDefaultMotionState(transform);

		var localInertia = new AmmoLib.btVector3(0, 0, 0);
		shape.calculateLocalInertia(mass, localInertia);

		var rbInfo = new AmmoLib.btRigidBodyConstructionInfo(mass, motionState, shape, localInertia);

		var body = new AmmoLib.btRigidBody(rbInfo);
		// body.setFriction(4);
		world.addRigidBody(body);

		if (mass > 0) {
			meshes.push(mesh);
			meshMap.set(mesh, body);
		}
	}

	function handleInstancedMesh(mesh:Dynamic, mass:Float, shape:AmmoLib.btBoxShape/) {
		var array = mesh.instanceMatrix.array;

		var bodies = [];

		for (i in 0...mesh.count) {
			var index = i * 16;

			var transform = new AmmoLib.btTransform();
			transform.setFromOpenGLMatrix(array.slice(index, index + 16));

			var motionState = new AmmoLib.btDefaultMotionState(transform);

			var localInertia = new AmmoLib.btVector3(0, 0, 0);
			shape.calculateLocalInertia(mass, localInertia);

			var rbInfo = new AmmoLib.btRigidBodyConstructionInfo(mass, motionState, shape, localInertia);

			var body = new AmmoLib.btRigidBody(rbInfo);
			world.addRigidBody(body);

			bodies.push(body);
		}

		if (mass > 0) {
			meshes.push(mesh);
			meshMap.set(mesh, bodies);
		}
	}

	function setMeshPosition(mesh:Dynamic, position:Dynamic, index:Int = 0) {
		if (Reflect.hasField(mesh, 'isInstancedMesh') && mesh.isInstancedMesh) {
			var bodies = meshMap.get(mesh);
			var body = bodies[index];

			body.setAngularVelocity(new AmmoLib.btVector3(0, 0, 0));
			body.setLinearVelocity(new AmmoLib.btVector3(0, 0, 0));

			worldTransform.setIdentity();
			worldTransform.setOrigin(new AmmoLib.btVector3(position.x, position.y, position.z));
			body.setWorldTransform(worldTransform);
		} else if (Reflect.hasField(mesh, 'isMesh') && mesh.isMesh) {
			var body = meshMap.get(mesh);

			body.setAngularVelocity(new AmmoLib.btVector3(0, 0, 0));
			body.setLinearVelocity(new AmmoLib.btVector3(0, 0, 0));

			worldTransform.setIdentity();
			worldTransform.setOrigin(new AmmoLib.btVector3(position.x, position.y, position.z));
			body.setWorldTransform(worldTransform);
		}
	}

	var lastTime = 0.;

	function step() {
		var time = Performance.now();

		if (lastTime > 0) {
			var delta = (time - lastTime) / 1000;

			world.stepSimulation(delta, 10);

			for (i in 0...meshes.length) {
				var mesh = meshes[i];

				if (Reflect.hasField(mesh, 'isInstancedMesh') && mesh.isInstancedMesh) {
					var array = mesh.instanceMatrix.array;
					var bodies = meshMap.get(mesh);

					for (j in 0...bodies.length) {
						var body = bodies[j];

						var motionState = body.getMotionState();
						motionState.getWorldTransform(worldTransform);

						var position = worldTransform.getOrigin();
						var quaternion = worldTransform.getRotation();

						compose(position, quaternion, array, j * 16);
					}

					mesh.instanceMatrix.needsUpdate = true;
					mesh.computeBoundingSphere();
				} else if (Reflect.hasField(mesh, 'isMesh') && mesh.isMesh) {
					var body = meshMap.get(mesh);

					var motionState = body.getMotionState();
					motionState.getWorldTransform(worldTransform);

					var position = worldTransform.getOrigin();
					var quaternion = worldTransform.getRotation();
					mesh.position.set(position.x(), position.y(), position.z());
					mesh.quaternion.set(quaternion.x(), quaternion.y(), quaternion.z(), quaternion.w());
				}
			}
		}

		lastTime = time;
	}

	setInterval(step, Std.int(1000 / frameRate));

	return {
		addScene: addScene,
		addMesh: addMesh,
		setMeshPosition: setMeshPosition,
	};
}

function compose(position:Dynamic, quaternion:Dynamic, array:Array<Float>, index:Int) {
	var x = quaternion.x(), y = quaternion.y(), z = quaternion.z(), w = quaternion.w();
	var x2 = x + x, y2 = y + y, z2 = z + z;
	var xx = x * x2, xy = x * y2, xz = x * z2;
	var yy = y * y2, yz = y * z2, zz = z * z2;
	var wx = w * x2, wy = w * y2, wz = w * z2;

	array[index + 0] = 1 - (yy + zz);
	array[index + 1] = xy + wz;
	array[index + 2] = xz - wy;
	array[index + 3] = 0;

	array[index + 4] = xy - wz;
	array[index + 5] = 1 - (xx + zz);
	array[index + 6] = yz + wx;
	array[index + 7] = 0;

	array[index + 8] = xz + wy;
	array[index + 9] = yz - wx;
	array[index + 10] = 1 - (xx + yy);
	array[index + 11] = 0;

	array[index + 12] = position.x();
	array[index + 13] = position.y();
	array[index + 14] = position.z();
	array[index + 15] = 1;
}

class AmmoPhysicsExport {
	public static var AmmoPhysics = AmmoPhysics;
}