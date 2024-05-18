class WebGLUniforms {

	constructor( gl, program ) {

		this.seq = [];
		this.map = {};

		const n = gl.getProgramParameter( program, gl.ACTIVE_UNIFORMS );

		for ( let i = 0; i < n; ++ i ) {

			const info = gl.getActiveUniform( program, i ),
				addr = gl.getUniformLocation( program, info.name );

			parseUniform( info, addr, this );

		}

	}

	setValue( gl, name, value, textures ) {

		const u = this.map[ name ];

		if ( u !== undefined ) u.setValue( gl, value, textures );

	}

	setOptional( gl, object, name ) {

		const v = object[ name ];

		if ( v !== undefined ) this.setValue( gl, name, v );

	}

	static upload( gl, seq, values, textures ) {

		for ( let i = 0, n = seq.length; i !== n; ++ i ) {

			const u = seq[ i ],
				v = values[ u.id ];

			if ( v.needsUpdate !== false ) {

				// note: always updating when .needsUpdate is undefined
				u.setValue( gl, v.value, textures );

			}

		}

	}

	static seqWithValue( seq, values ) {

		const r = [];

		for ( let i = 0, n = seq.length; i !== n; ++ i ) {

			const u = seq[ i ];
			if ( u.id in values ) r.push( u );

		}

		return r;

	}

}