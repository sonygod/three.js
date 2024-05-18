class Constraint {

	/**
	 * @param {THREE.SkinnedMesh} mesh
	 * @param {Ammo.btDiscreteDynamicsWorld} world
	 * @param {RigidBody} bodyA
	 * @param {RigidBody} bodyB
	 * @param {Object} params
	 * @param {ResourceManager} manager
	 */
	constructor( mesh, world, bodyA, bodyB, params, manager ) {

		this.mesh = mesh;
		this.world = world;
		this.bodyA = bodyA;
		this.bodyB = bodyB;
		this.params = params;
		this.manager = manager;

		this.constraint = null;

		this._init();

	}

	// private method

	_init() {

		const manager = this.manager;
		const params = this.params;
		const bodyA = this.bodyA;
		const bodyB = this.bodyB;

		const form = manager.allocTransform();
		manager.setIdentity( form );
		manager.setOriginFromArray3( form, params.position );
		manager.setBasisFromArray3( form, params.rotation );

		const formA = manager.allocTransform();
		const formB = manager.allocTransform();

		bodyA.body.getMotionState().getWorldTransform( formA );
		bodyB.body.getMotionState().getWorldTransform( formB );

		const formInverseA = manager.inverseTransform( formA );
		const formInverseB = manager.inverseTransform( formB );

		const formA2 = manager.multiplyTransforms( formInverseA, form );
		const formB2 = manager.multiplyTransforms( formInverseB, form );

		const constraint = new Ammo.btGeneric6DofSpringConstraint( bodyA.body, bodyB.body, formA2, formB2, true );

		const lll = manager.allocVector3();
		const lul = manager.allocVector3();
		const all = manager.allocVector3();
		const aul = manager.allocVector3();

		lll.setValue( params.translationLimitation1[ 0 ],
		              params.translationLimitation1[ 1 ],
		              params.translationLimitation1[ 2 ] );
		lul.setValue( params.translationLimitation2[ 0 ],
		              params.translationLimitation2[ 1 ],
		              params.translationLimitation2[ 2 ] );
		all.setValue( params.rotationLimitation1[ 0 ],
		              params.rotationLimitation1[ 1 ],
		              params.rotationLimitation1[ 2 ] );
		aul.setValue( params.rotationLimitation2[ 0 ],
		              params.rotationLimitation2[ 1 ],
		              params.rotationLimitation2[ 2 ] );

		constraint.setLinearLowerLimit( lll );
		constraint.setLinearUpperLimit( lul );
		constraint.setAngularLowerLimit( all );
		constraint.setAngularUpperLimit( aul );

		for ( let i = 0; i < 3; i ++ ) {

			if ( params.springPosition[ i ] !== 0 ) {

				constraint.enableSpring( i, true );
				constraint.setStiffness( i, params.springPosition[ i ] );

			}

		}

		for ( let i = 0; i < 3; i ++ ) {

			if ( params.springRotation[ i ] !== 0 ) {

				constraint.enableSpring( i + 3, true );
				constraint.setStiffness( i + 3, params.springRotation[ i ] );

			}

		}

		/*
		 * Currently(10/31/2016) official ammo.js doesn't support
		 * btGeneric6DofSpringConstraint.setParam method.
		 * You need custom ammo.js (add the method into idl) if you wanna use.
		 * By setting this parameter, physics will be more like MMD's
		 */
		if ( constraint.setParam !== undefined ) {

			for ( let i = 0; i < 6; i ++ ) {

				constraint.setParam( 2, 0.475, i );

			}

		}

		this.world.addConstraint( constraint, true );
		this.constraint = constraint;

		manager.freeTransform( form );
		manager.freeTransform( formA );
		manager.freeTransform( formB );
		manager.freeTransform( formInverseA );
		manager.freeTransform( formInverseB );
		manager.freeTransform( formA2 );
		manager.freeTransform( formB2 );
		manager.freeVector3( lll );
		manager.freeVector3( lul );
		manager.freeVector3( all );
		manager.freeVector3( aul );

	}

}