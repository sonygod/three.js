package three.js.examples.jsm.animation;

import three.js.core.Bone;
import three.js.geometries.BoxGeometry;
import three.js.geometries.CapsuleGeometry;
import three.js.maths.Color;
import three.js.maths.Euler;
import three.js.maths.Matrix4;
import three.js.objects.Mesh;
import three.js.objects.MeshBasicMaterial;
import three.js.objects.Object3D;
import three.js.maths.Quaternion;
import three.js.geometries.SphereGeometry;
import three.js.maths.Vector3;

class MMDPhysics
{
	private var _manager:ResourceManager;
	private var _mesh:THREE.SkinnedMesh;
	private var _unitStep:Float = 1 / 65;
	private var _maxStepNum:Int = 3;
	private var _gravity:Vector3 = new Vector3( 0, -9.8 * 10, 0 );
	private var _world:Ammo.btDiscreteDynamicsWorld;
	private var _bodies:Array<RigidBody>;
	private var _constraints:Array<Constraint>;

	public function new(mesh:THREE.SkinnedMesh, rigidBodyParams:Array<Dynamic>, constraintParams:Array<Dynamic>=null, params:Dynamic=null)
	{
		if ( typeof Ammo === "undefined" )
		{
	        throw new Error( "THREE.MMDPhysics: Import ammo.js https://github.com/kripken/ammo.js" );
		}
	
		this._manager = new ResourceManager();
		this._mesh = mesh;
		this._world = ( params.world !== undefined ) ? params.world : null;
		this._bodies = [];
		this._constraints = [];
		this._init( mesh, rigidBodyParams, constraintParams );
	}

	public function update(delta:Float)
	{
		const manager = this._manager;
		const mesh = this._mesh;

		let isNonDefaultScale = false;

		var position = manager.allocThreeVector3();
		var quaternion = manager.allocThreeQuaternion();
		var scale = manager.allocThreeVector3();

		mesh.matrixWorld.decompose( position, quaternion, scale );

		if ( scale.x !== 1 || scale.y !== 1 || scale.z !== 1 )
		{
			isNonDefaultScale = true;
		}

		var parent = mesh.parent;

		if ( isNonDefaultScale )
		{
			if ( parent !== null ) mesh.parent = null;

			scale.copy( this._mesh.scale );

			mesh.scale.set( 1, 1, 1 );
			mesh.updateMatrixWorld( true );
		}

		this._updateRigidBodies();
		this._stepSimulation( delta );
		this._updateBones();

		if ( isNonDefaultScale )
		{
			if ( parent !== null ) mesh.parent = parent;

			mesh.scale.copy( scale );
		}

		manager.freeThreeVector3( scale );
		manager.freeThreeQuaternion( quaternion );
		manager.freeThreeVector3( position );
	}

	public function reset()
	{
		for ( var i = 0, il = this._bodies.length; i < il; i ++ )
		{
			this._bodies[ i ].reset();
		}
		return this;
	}

	public function warmup(cycles:Int)
	{
		for ( var i = 0; i < cycles; i ++ )
		{
			this.update( 1 / 60 );
		}
		return this;
	}

	public function setGravity(gravity:Vector3)
	{
		this._world.setGravity( new Ammo.btVector3( gravity.x, gravity.y, gravity.z ) );
		this._gravity.copy( gravity );
		return this;
	}

	private function _init(mesh, rigidBodyParams, constraintParams)
	{
		const manager = this._manager;

		const parent = mesh.parent;

		if ( parent !== null ) mesh.parent = null;

		const currentPosition = manager.allocThreeVector3();
		const currentQuaternion = manager.allocThreeQuaternion();
		const currentScale = manager.allocThreeVector3();

		currentPosition.copy( mesh.position );
		currentQuaternion.copy( mesh.quaternion );
		currentScale.copy( mesh.scale );

		mesh.position.set( 0, 0, 0 );
		mesh.quaternion.set( 0, 0, 0, 1 );
		mesh.scale.set( 1, 1, 1 );

		this._initRigidBodies( rigidBodyParams );
		this._initConstraints( constraintParams );

		if ( parent !== null ) mesh.parent = parent;

		mesh.position.copy( currentPosition );
		mesh.quaternion.copy( currentQuaternion );
		mesh.scale.copy( currentScale );

		mesh.updateMatrixWorld( true );

		manager.freeThreeVector3( currentPosition );
		manager.freeThreeQuaternion( currentQuaternion );
		manager.freeThreeVector3( currentScale );
	}

	private function _createWorld()
	{
		const config = new Ammo.btDefaultCollisionConfiguration();
		const dispatcher = new Ammo.btCollisionDispatcher( config );
		const cache = new Ammo.btDbvtBroadphase();
		const solver = new Ammo.btSequentialImpulseConstraintSolver();
		const world = new Ammo.btDiscreteDynamicsWorld( dispatcher, cache, solver, config );
		return world;
	}

	private function _initRigidBodies(rigidBodies)
	{
		for ( var i = 0, il = rigidBodies.length; i < il; i ++ )
		{
			this._bodies.push( new RigidBody( this._mesh, this._world, rigidBodies[ i ], this._manager ) );
		}
	}

	private function _initConstraints(constraints)
	{
		for ( var i = 0, il = constraints.length; i < il; i ++ )
		{
			const params = constraints[ i ];
			const bodyA = this._bodies[ params.rigidBodyIndex1 ];
			const bodyB = this._bodies[ params.rigidBodyIndex2 ];
			this._constraints.push( new Constraint( this._mesh, this._world, bodyA, bodyB, params, this._manager ) );
		}
	}

	private function _stepSimulation(delta)
	{
		const unitStep = this._unitStep;
		let stepTime = delta;
		let maxStepNum = ( delta / unitStep ) | 0 + 1;

		if ( stepTime < unitStep )
		{
			stepTime = unitStep;
			maxStepNum = 1;
		}

		if ( maxStepNum > this._maxStepNum )
		{
			maxStepNum = this._maxStepNum;
		}

		this._world.stepSimulation( stepTime, maxStepNum, unitStep );
	}

	private function _updateRigidBodies()
	{
		for ( var i = 0, il = this._bodies.length; i < il; i ++ )
		{
			this._bodies[ i ].updateFromBone();
		}
	}

	private function _updateBones()
	{
		for ( var i = 0, il = this._bodies.length; i < il; i ++ )
		{
			this._bodies[ i ].updateBone();
		}
	}
}

class ResourceManager
{
	private var _threeVector3s:Array<Vector3>;
	private var _threeMatrix4s:Array<Matrix4>;
	private var _threeQuaternions:Array<Quaternion>;
	private var _threeEulers:Array<Euler>;
	private var _transforms:Array<Ammo.btTransform>;
	private var _quaternions:Array<Ammo.btQuaternion>;
	private var _vector3s:Array<Ammo.btVector3>;

	public function new()
	{
		this._threeVector3s = [];
		this._threeMatrix4s = [];
		this._threeQuaternions = [];
		this._threeEulers = [];
		this._transforms = [];
		this._quaternions = [];
		this._vector3s = [];
	}

	public function allocThreeVector3():Vector3
	{
		return ( this._threeVector3s.length > 0 ) ? this._threeVector3s.pop() : new Vector3();
	}

	public function freeThreeVector3(v:Vector3)
	{
		this._threeVector3s.push( v );
	}

	public function allocThreeMatrix4():Matrix4
	{
		return ( this._threeMatrix4s.length > 0 ) ? this._threeMatrix4s.pop() : new Matrix4();
	}

	public function freeThreeMatrix4(m:Matrix4)
	{
		this._threeMatrix4s.push( m );
	}

	public function allocThreeQuaternion():Quaternion
	{
		return ( this._threeQuaternions.length > 0 ) ? this._threeQuaternions.pop() : new Quaternion();
	}

	public function freeThreeQuaternion(q:Quaternion)
	{
		this._threeQuaternions.push( q );
	}

	public function allocThreeEuler():Euler
	{
		return ( this._threeEulers.length > 0 ) ? this._threeEulers.pop() : new Euler();
	}

	public function freeThreeEuler(e:Euler)
	{
		this._threeEulers.push( e );
	}

	public function allocTransform():Ammo.btTransform