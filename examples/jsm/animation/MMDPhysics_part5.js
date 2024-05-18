class MMDPhysicsHelper extends Object3D {

	/**
	 * Visualize Rigid bodies
	 *
	 * @param {THREE.SkinnedMesh} mesh
	 * @param {Physics} physics
	 */
	constructor( mesh, physics ) {

		super();

		this.root = mesh;
		this.physics = physics;

		this.matrix.copy( mesh.matrixWorld );
		this.matrixAutoUpdate = false;

		this.materials = [];

		this.materials.push(
			new MeshBasicMaterial( {
				color: new Color( 0xff8888 ),
				wireframe: true,
				depthTest: false,
				depthWrite: false,
				opacity: 0.25,
				transparent: true
			} )
		);

		this.materials.push(
			new MeshBasicMaterial( {
				color: new Color( 0x88ff88 ),
				wireframe: true,
				depthTest: false,
				depthWrite: false,
				opacity: 0.25,
				transparent: true
			} )
		);

		this.materials.push(
			new MeshBasicMaterial( {
				color: new Color( 0x8888ff ),
				wireframe: true,
				depthTest: false,
				depthWrite: false,
				opacity: 0.25,
				transparent: true
			} )
		);

		this._init();

	}


	/**
	 * Frees the GPU-related resources allocated by this instance. Call this method whenever this instance is no longer used in your app.
	 */
	dispose() {

		const materials = this.materials;
		const children = this.children;

		for ( let i = 0; i < materials.length; i ++ ) {

			materials[ i ].dispose();

		}

		for ( let i = 0; i < children.length; i ++ ) {

			const child = children[ i ];

			if ( child.isMesh ) child.geometry.dispose();

		}

	}

	/**
	 * Updates Rigid Bodies visualization.
	 */
	updateMatrixWorld( force ) {

		var mesh = this.root;

		if ( this.visible ) {

			var bodies = this.physics.bodies;

			_matrixWorldInv
				.copy( mesh.matrixWorld )
				.decompose( _position, _quaternion, _scale )
				.compose( _position, _quaternion, _scale.set( 1, 1, 1 ) )
				.invert();

			for ( var i = 0, il = bodies.length; i < il; i ++ ) {

				var body = bodies[ i ].body;
				var child = this.children[ i ];

				var tr = body.getCenterOfMassTransform();
				var origin = tr.getOrigin();
				var rotation = tr.getRotation();

				child.position
					.set( origin.x(), origin.y(), origin.z() )
					.applyMatrix4( _matrixWorldInv );

				child.quaternion
					.setFromRotationMatrix( _matrixWorldInv )
					.multiply(
						_quaternion.set( rotation.x(), rotation.y(), rotation.z(), rotation.w() )
					);

			}

		}

		this.matrix
			.copy( mesh.matrixWorld )
			.decompose( _position, _quaternion, _scale )
			.compose( _position, _quaternion, _scale.set( 1, 1, 1 ) );

		super.updateMatrixWorld( force );

	}

	// private method

	_init() {

		var bodies = this.physics.bodies;

		function createGeometry( param ) {

			switch ( param.shapeType ) {

				case 0:
					return new SphereGeometry( param.width, 16, 8 );

				case 1:
					return new BoxGeometry( param.width * 2, param.height * 2, param.depth * 2, 8, 8, 8 );

				case 2:
					return new CapsuleGeometry( param.width, param.height, 8, 16 );

				default:
					return null;

			}

		}

		for ( var i = 0, il = bodies.length; i < il; i ++ ) {

			var param = bodies[ i ].params;
			this.add( new Mesh( createGeometry( param ), this.materials[ param.type ] ) );

		}

	}

}