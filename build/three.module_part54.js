class StructuredUniform {

	constructor( id ) {

		this.id = id;

		this.seq = [];
		this.map = {};

	}

	setValue( gl, value, textures ) {

		const seq = this.seq;

		for ( let i = 0, n = seq.length; i !== n; ++ i ) {

			const u = seq[ i ];
			u.setValue( gl, value[ u.id ], textures );

		}

	}

}