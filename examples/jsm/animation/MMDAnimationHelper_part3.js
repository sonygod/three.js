class GrantSolver {

	constructor( mesh, grants = [] ) {

		this.mesh = mesh;
		this.grants = grants;

	}

	/**
	 * Solve all the grant bones
	 * @return {GrantSolver}
	 */
	update() {

		const grants = this.grants;

		for ( let i = 0, il = grants.length; i < il; i ++ ) {

			this.updateOne( grants[ i ] );

		}

		return this;

	}

	/**
	 * Solve a grant bone
	 * @param {Object} grant - grant parameter
	 * @return {GrantSolver}
	 */
	updateOne( grant ) {

		const bones = this.mesh.skeleton.bones;
		const bone = bones[ grant.index ];
		const parentBone = bones[ grant.parentIndex ];

		if ( grant.isLocal ) {

			// TODO: implement
			if ( grant.affectPosition ) {

			}

			// TODO: implement
			if ( grant.affectRotation ) {

			}

		} else {

			// TODO: implement
			if ( grant.affectPosition ) {

			}

			if ( grant.affectRotation ) {

				this.addGrantRotation( bone, parentBone.quaternion, grant.ratio );

			}

		}

		return this;

	}

	addGrantRotation( bone, q, ratio ) {

		_q.set( 0, 0, 0, 1 );
		_q.slerp( q, ratio );
		bone.quaternion.multiply( _q );

		return this;

	}

}