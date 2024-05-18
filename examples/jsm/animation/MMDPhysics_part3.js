class RigidBody {

	constructor( mesh, world, params, manager ) {

		this.mesh = mesh;
		this.world = world;
		this.params = params;
		this.manager = manager;

		this.body = null;
		this.bone = null;
		this.boneOffsetForm = null;
		this.boneOffsetFormInverse = null;

		this._init();

	}

	/**
	 * Resets rigid body transform to the current bone's.
	 *
	 * @return {RigidBody}
	 */
	reset() {

		this._setTransformFromBone();
		return this;

	}

	/**
	 * Updates rigid body's transform from the current bone.
	 *
	 * @return {RidigBody}
	 */
	updateFromBone() {

		if ( this.params.boneIndex !== - 1 && this.params.type === 0 ) {

			this._setTransformFromBone();

		}

		return this;

	}

	/**
	 * Updates bone from the current ridid body's transform.
	 *
	 * @return {RidigBody}
	 */
	updateBone() {

		if ( this.params.type === 0 || this.params.boneIndex === - 1 ) {

			return this;

		}

		this._updateBoneRotation();

		if ( this.params.type === 1 ) {

			this._updateBonePosition();

		}

		this.bone.updateMatrixWorld( true );

		if ( this.params.type === 2 ) {

			this._setPositionFromBone();

		}

		return this;

	}

	// private methods

	_init() {

		function generateShape( p ) {

			switch ( p.shapeType ) {

				case 0:
					return new Ammo.btSphereShape( p.width );

				case 1:
					return new Ammo.btBoxShape( new Ammo.btVector3( p.width, p.height, p.depth ) );

				case 2:
					return new Ammo.btCapsuleShape( p.width, p.height );

				default:
					throw new Error( 'unknown shape type ' + p.shapeType );

			}

		}

		const manager = this.manager;
		const params = this.params;
		const bones = this.mesh.skeleton.bones;
		const bone = ( params.boneIndex === - 1 )
			? new Bone()
			: bones[ params.boneIndex ];

		const shape = generateShape( params );
		const weight = ( params.type === 0 ) ? 0 : params.weight;
		const localInertia = manager.allocVector3();
		localInertia.setValue( 0, 0, 0 );

		if ( weight !== 0 ) {

			shape.calculateLocalInertia( weight, localInertia );

		}

		const boneOffsetForm = manager.allocTransform();
		manager.setIdentity( boneOffsetForm );
		manager.setOriginFromArray3( boneOffsetForm, params.position );
		manager.setBasisFromArray3( boneOffsetForm, params.rotation );

		const vector = manager.allocThreeVector3();
		const boneForm = manager.allocTransform();
		manager.setIdentity( boneForm );
		manager.setOriginFromThreeVector3( boneForm, bone.getWorldPosition( vector ) );

		const form = manager.multiplyTransforms( boneForm, boneOffsetForm );
		const state = new Ammo.btDefaultMotionState( form );

		const info = new Ammo.btRigidBodyConstructionInfo( weight, state, shape, localInertia );
		info.set_m_friction( params.friction );
		info.set_m_restitution( params.restitution );

		const body = new Ammo.btRigidBody( info );

		if ( params.type === 0 ) {

			body.setCollisionFlags( body.getCollisionFlags() | 2 );

			/*
			 * It'd be better to comment out this line though in general I should call this method
			 * because I'm not sure why but physics will be more like MMD's
			 * if I comment out.
			 */
			body.setActivationState( 4 );

		}

		body.setDamping( params.positionDamping, params.rotationDamping );
		body.setSleepingThresholds( 0, 0 );

		this.world.addRigidBody( body, 1 << params.groupIndex, params.groupTarget );

		this.body = body;
		this.bone = bone;
		this.boneOffsetForm = boneOffsetForm;
		this.boneOffsetFormInverse = manager.inverseTransform( boneOffsetForm );

		manager.freeVector3( localInertia );
		manager.freeTransform( form );
		manager.freeTransform( boneForm );
		manager.freeThreeVector3( vector );

	}

	_getBoneTransform() {

		const manager = this.manager;
		const p = manager.allocThreeVector3();
		const q = manager.allocThreeQuaternion();
		const s = manager.allocThreeVector3();

		this.bone.matrixWorld.decompose( p, q, s );

		const tr = manager.allocTransform();
		manager.setOriginFromThreeVector3( tr, p );
		manager.setBasisFromThreeQuaternion( tr, q );

		const form = manager.multiplyTransforms( tr, this.boneOffsetForm );

		manager.freeTransform( tr );
		manager.freeThreeVector3( s );
		manager.freeThreeQuaternion( q );
		manager.freeThreeVector3( p );

		return form;

	}

	_getWorldTransformForBone() {

		const manager = this.manager;
		const tr = this.body.getCenterOfMassTransform();
		return manager.multiplyTransforms( tr, this.boneOffsetFormInverse );

	}

	_setTransformFromBone() {

		const manager = this.manager;
		const form = this._getBoneTransform();

		// TODO: check the most appropriate way to set
		//this.body.setWorldTransform( form );
		this.body.setCenterOfMassTransform( form );
		this.body.getMotionState().setWorldTransform( form );

		manager.freeTransform( form );

	}

	_setPositionFromBone() {

		const manager = this.manager;
		const form = this._getBoneTransform();

		const tr = manager.allocTransform();
		this.body.getMotionState().getWorldTransform( tr );
		manager.copyOrigin( tr, form );

		// TODO: check the most appropriate way to set
		//this.body.setWorldTransform( tr );
		this.body.setCenterOfMassTransform( tr );
		this.body.getMotionState().setWorldTransform( tr );

		manager.freeTransform( tr );
		manager.freeTransform( form );

	}

	_updateBoneRotation() {

		const manager = this.manager;

		const tr = this._getWorldTransformForBone();
		const q = manager.getBasis( tr );

		const thQ = manager.allocThreeQuaternion();
		const thQ2 = manager.allocThreeQuaternion();
		const thQ3 = manager.allocThreeQuaternion();

		thQ.set( q.x(), q.y(), q.z(), q.w() );
		thQ2.setFromRotationMatrix( this.bone.matrixWorld );
		thQ2.conjugate();
		thQ2.multiply( thQ );

		//this.bone.quaternion.multiply( thQ2 );

		thQ3.setFromRotationMatrix( this.bone.matrix );

		// Renormalizing quaternion here because repeatedly transforming
		// quaternion continuously accumulates floating point error and
		// can end up being overflow. See #15335
		this.bone.quaternion.copy( thQ2.multiply( thQ3 ).normalize() );

		manager.freeThreeQuaternion( thQ );
		manager.freeThreeQuaternion( thQ2 );
		manager.freeThreeQuaternion( thQ3 );

		manager.freeQuaternion( q );
		manager.freeTransform( tr );

	}

	_updateBonePosition() {

		const manager = this.manager;

		const tr = this._getWorldTransformForBone();

		const thV = manager.allocThreeVector3();

		const o = manager.getOrigin( tr );
		thV.set( o.x(), o.y(), o.z() );

		if ( this.bone.parent ) {

			this.bone.parent.worldToLocal( thV );

		}

		this.bone.position.copy( thV );

		manager.freeThreeVector3( thV );

		manager.freeTransform( tr );

	}

}