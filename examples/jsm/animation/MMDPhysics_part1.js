class MMDPhysics {

	/**
	 * @param {THREE.SkinnedMesh} mesh
	 * @param {Array<Object>} rigidBodyParams
	 * @param {Array<Object>} (optional) constraintParams
	 * @param {Object} params - (optional)
	 * @param {Number} params.unitStep - Default is 1 / 65.
	 * @param {Integer} params.maxStepNum - Default is 3.
	 * @param {Vector3} params.gravity - Default is ( 0, - 9.8 * 10, 0 )
	 */
	constructor( mesh, rigidBodyParams, constraintParams = [], params = {} ) {

		if ( typeof Ammo === 'undefined' ) {

			throw new Error( 'THREE.MMDPhysics: Import ammo.js https://github.com/kripken/ammo.js' );

		}

		this.manager = new ResourceManager();

		this.mesh = mesh;

		/*
		 * I don't know why but 1/60 unitStep easily breaks models
		 * so I set it 1/65 so far.
		 * Don't set too small unitStep because
		 * the smaller unitStep can make the performance worse.
		 */
		this.unitStep = ( params.unitStep !== undefined ) ? params.unitStep : 1 / 65;
		this.maxStepNum = ( params.maxStepNum !== undefined ) ? params.maxStepNum : 3;
		this.gravity = new Vector3( 0, - 9.8 * 10, 0 );

		if ( params.gravity !== undefined ) this.gravity.copy( params.gravity );

		this.world = params.world !== undefined ? params.world : null; // experimental

		this.bodies = [];
		this.constraints = [];

		this._init( mesh, rigidBodyParams, constraintParams );

	}

	/**
	 * Advances Physics calculation and updates bones.
	 *
	 * @param {Number} delta - time in second
	 * @return {MMDPhysics}
	 */
	update( delta ) {

		const manager = this.manager;
		const mesh = this.mesh;

		// rigid bodies and constrains are for
		// mesh's world scale (1, 1, 1).
		// Convert to (1, 1, 1) if it isn't.

		let isNonDefaultScale = false;

		const position = manager.allocThreeVector3();
		const quaternion = manager.allocThreeQuaternion();
		const scale = manager.allocThreeVector3();

		mesh.matrixWorld.decompose( position, quaternion, scale );

		if ( scale.x !== 1 || scale.y !== 1 || scale.z !== 1 ) {

			isNonDefaultScale = true;

		}

		let parent;

		if ( isNonDefaultScale ) {

			parent = mesh.parent;

			if ( parent !== null ) mesh.parent = null;

			scale.copy( this.mesh.scale );

			mesh.scale.set( 1, 1, 1 );
			mesh.updateMatrixWorld( true );

		}

		// calculate physics and update bones

		this._updateRigidBodies();
		this._stepSimulation( delta );
		this._updateBones();

		// restore mesh if converted above

		if ( isNonDefaultScale ) {

			if ( parent !== null ) mesh.parent = parent;

			mesh.scale.copy( scale );

		}

		manager.freeThreeVector3( scale );
		manager.freeThreeQuaternion( quaternion );
		manager.freeThreeVector3( position );

		return this;

	}

	/**
	 * Resets rigid bodies transorm to current bone's.
	 *
	 * @return {MMDPhysics}
	 */
	reset() {

		for ( let i = 0, il = this.bodies.length; i < il; i ++ ) {

			this.bodies[ i ].reset();

		}

		return this;

	}

	/**
	 * Warm ups Rigid bodies. Calculates cycles steps.
	 *
	 * @param {Integer} cycles
	 * @return {MMDPhysics}
	 */
	warmup( cycles ) {

		for ( let i = 0; i < cycles; i ++ ) {

			this.update( 1 / 60 );

		}

		return this;

	}

	/**
	 * Sets gravity.
	 *
	 * @param {Vector3} gravity
	 * @return {MMDPhysicsHelper}
	 */
	setGravity( gravity ) {

		this.world.setGravity( new Ammo.btVector3( gravity.x, gravity.y, gravity.z ) );
		this.gravity.copy( gravity );

		return this;

	}

	/**
	 * Creates MMDPhysicsHelper
	 *
	 * @return {MMDPhysicsHelper}
	 */
	createHelper() {

		return new MMDPhysicsHelper( this.mesh, this );

	}

	// private methods

	_init( mesh, rigidBodyParams, constraintParams ) {

		const manager = this.manager;

		// rigid body/constraint parameters are for
		// mesh's default world transform as position(0, 0, 0),
		// quaternion(0, 0, 0, 1) and scale(0, 0, 0)

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

		mesh.updateMatrixWorld( true );

		if ( this.world === null ) {

			this.world = this._createWorld();
			this.setGravity( this.gravity );

		}

		this._initRigidBodies( rigidBodyParams );
		this._initConstraints( constraintParams );

		if ( parent !== null ) mesh.parent = parent;

		mesh.position.copy( currentPosition );
		mesh.quaternion.copy( currentQuaternion );
		mesh.scale.copy( currentScale );

		mesh.updateMatrixWorld( true );

		this.reset();

		manager.freeThreeVector3( currentPosition );
		manager.freeThreeQuaternion( currentQuaternion );
		manager.freeThreeVector3( currentScale );

	}

	_createWorld() {

		const config = new Ammo.btDefaultCollisionConfiguration();
		const dispatcher = new Ammo.btCollisionDispatcher( config );
		const cache = new Ammo.btDbvtBroadphase();
		const solver = new Ammo.btSequentialImpulseConstraintSolver();
		const world = new Ammo.btDiscreteDynamicsWorld( dispatcher, cache, solver, config );
		return world;

	}

	_initRigidBodies( rigidBodies ) {

		for ( let i = 0, il = rigidBodies.length; i < il; i ++ ) {

			this.bodies.push( new RigidBody(
				this.mesh, this.world, rigidBodies[ i ], this.manager ) );

		}

	}

	_initConstraints( constraints ) {

		for ( let i = 0, il = constraints.length; i < il; i ++ ) {

			const params = constraints[ i ];
			const bodyA = this.bodies[ params.rigidBodyIndex1 ];
			const bodyB = this.bodies[ params.rigidBodyIndex2 ];
			this.constraints.push( new Constraint( this.mesh, this.world, bodyA, bodyB, params, this.manager ) );

		}

	}

	_stepSimulation( delta ) {

		const unitStep = this.unitStep;
		let stepTime = delta;
		let maxStepNum = ( ( delta / unitStep ) | 0 ) + 1;

		if ( stepTime < unitStep ) {

			stepTime = unitStep;
			maxStepNum = 1;

		}

		if ( maxStepNum > this.maxStepNum ) {

			maxStepNum = this.maxStepNum;

		}

		this.world.stepSimulation( stepTime, maxStepNum, unitStep );

	}

	_updateRigidBodies() {

		for ( let i = 0, il = this.bodies.length; i < il; i ++ ) {

			this.bodies[ i ].updateFromBone();

		}

	}

	_updateBones() {

		for ( let i = 0, il = this.bodies.length; i < il; i ++ ) {

			this.bodies[ i ].updateBone();

		}

	}

}