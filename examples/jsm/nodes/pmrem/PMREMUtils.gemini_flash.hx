import shadernode.ShaderNode;
import math.MathNode;
import math.OperatorNode;
import math.CondNode;
import utils.LoopNode;

class PMREMGenerator {

	static var cubeUV_r0:Float = 1.0;
	static var cubeUV_m0:Float = - 2.0;
	static var cubeUV_r1:Float = 0.8;
	static var cubeUV_m1:Float = - 1.0;
	static var cubeUV_r4:Float = 0.4;
	static var cubeUV_m4:Float = 2.0;
	static var cubeUV_r5:Float = 0.305;
	static var cubeUV_m5:Float = 3.0;
	static var cubeUV_r6:Float = 0.21;
	static var cubeUV_m6:Float = 4.0;

	static var cubeUV_minMipLevel:Float = 4.0;
	static var cubeUV_minTileSize:Float = 16.0;

	static var getFace = ShaderNode.tslFn( ( [ direction ] ) => {

		var absDirection = ShaderNode.vec3( MathNode.abs( direction ) );
		var face = ShaderNode.float( - 1.0 );

		ShaderNode.If( absDirection.x.greaterThan( absDirection.z ), () => {

			ShaderNode.If( absDirection.x.greaterThan( absDirection.y ), () => {

				face.assign( CondNode.cond( direction.x.greaterThan( 0.0 ), 0.0, 3.0 ) );

			} ).else( () => {

				face.assign( CondNode.cond( direction.y.greaterThan( 0.0 ), 1.0, 4.0 ) );

			} );

		} ).else( () => {

			ShaderNode.If( absDirection.z.greaterThan( absDirection.y ), () => {

				face.assign( CondNode.cond( direction.z.greaterThan( 0.0 ), 2.0, 5.0 ) );

			} ).else( () => {

				face.assign( CondNode.cond( direction.y.greaterThan( 0.0 ), 1.0, 4.0 ) );

			} );

		} );

		return face;

	} ).setLayout( {
		name: 'getFace',
		type: 'float',
		inputs: [
			{ name: 'direction', type: 'vec3' }
		]
	} );

	static var getUV = ShaderNode.tslFn( ( [ direction, face ] ) => {

		var uv = ShaderNode.vec2();

		ShaderNode.If( face.equal( 0.0 ), () => {

			uv.assign( ShaderNode.vec2( direction.z, direction.y ).div( MathNode.abs( direction.x ) ) ); // pos x

		} ).elseif( face.equal( 1.0 ), () => {

			uv.assign( ShaderNode.vec2( direction.x.negate(), direction.z.negate() ).div( MathNode.abs( direction.y ) ) ); // pos y

		} ).elseif( face.equal( 2.0 ), () => {

			uv.assign( ShaderNode.vec2( direction.x.negate(), direction.y ).div( MathNode.abs( direction.z ) ) ); // pos z

		} ).elseif( face.equal( 3.0 ), () => {

			uv.assign( ShaderNode.vec2( direction.z.negate(), direction.y ).div( MathNode.abs( direction.x ) ) ); // neg x

		} ).elseif( face.equal( 4.0 ), () => {

			uv.assign( ShaderNode.vec2( direction.x.negate(), direction.z ).div( MathNode.abs( direction.y ) ) ); // neg y

		} ).else( () => {

			uv.assign( ShaderNode.vec2( direction.x, direction.y ).div( MathNode.abs( direction.z ) ) ); // neg z

		} );

		return OperatorNode.mul( 0.5, uv.add( 1.0 ) );

	} ).setLayout( {
		name: 'getUV',
		type: 'vec2',
		inputs: [
			{ name: 'direction', type: 'vec3' },
			{ name: 'face', type: 'float' }
		]
	} );

	static var roughnessToMip = ShaderNode.tslFn( ( [ roughness ] ) => {

		var mip = ShaderNode.float( 0.0 );

		ShaderNode.If( roughness.greaterThanEqual( cubeUV_r1 ), () => {

			mip.assign( cubeUV_r0.sub( roughness ).mul( cubeUV_m1.sub( cubeUV_m0 ) ).div( cubeUV_r0.sub( cubeUV_r1 ) ).add( cubeUV_m0 ) );

		} ).elseif( roughness.greaterThanEqual( cubeUV_r4 ), () => {

			mip.assign( cubeUV_r1.sub( roughness ).mul( cubeUV_m4.sub( cubeUV_m1 ) ).div( cubeUV_r1.sub( cubeUV_r4 ) ).add( cubeUV_m1 ) );

		} ).elseif( roughness.greaterThanEqual( cubeUV_r5 ), () => {

			mip.assign( cubeUV_r4.sub( roughness ).mul( cubeUV_m5.sub( cubeUV_m4 ) ).div( cubeUV_r4.sub( cubeUV_r5 ) ).add( cubeUV_m4 ) );

		} ).elseif( roughness.greaterThanEqual( cubeUV_r6 ), () => {

			mip.assign( cubeUV_r5.sub( roughness ).mul( cubeUV_m6.sub( cubeUV_m5 ) ).div( cubeUV_r5.sub( cubeUV_r6 ) ).add( cubeUV_m5 ) );

		} ).else( () => {

			mip.assign( ShaderNode.float( - 2.0 ).mul( MathNode.log2( OperatorNode.mul( 1.16, roughness ) ) ) ); // 1.16 = 1.79^0.25

		} );

		return mip;

	} ).setLayout( {
		name: 'roughnessToMip',
		type: 'float',
		inputs: [
			{ name: 'roughness', type: 'float' }
		]
	} );

	// RH coordinate system; PMREM face-indexing convention
	static var getDirection = ShaderNode.tslFn( ( [ uv_immutable, face ] ) => {

		var uv = uv_immutable.toVar();
		uv.assign( OperatorNode.mul( 2.0, uv ).sub( 1.0 ) );
		var direction = ShaderNode.vec3( uv, 1.0 );

		ShaderNode.If( face.equal( 0.0 ), () => {

			direction.assign( direction.zyx ); // ( 1, v, u ) pos x

		} ).elseif( face.equal( 1.0 ), () => {

			direction.assign( direction.xzy );
			direction.xz.mulAssign( - 1.0 ); // ( -u, 1, -v ) pos y

		} ).elseif( face.equal( 2.0 ), () => {

			direction.x.mulAssign( - 1.0 ); // ( -u, v, 1 ) pos z

		} ).elseif( face.equal( 3.0 ), () => {

			direction.assign( direction.zyx );
			direction.xz.mulAssign( - 1.0 ); // ( -1, v, -u ) neg x

		} ).elseif( face.equal( 4.0 ), () => {

			direction.assign( direction.xzy );
			direction.xy.mulAssign( - 1.0 ); // ( -u, -1, v ) neg y

		} ).elseif( face.equal( 5.0 ), () => {

			direction.z.mulAssign( - 1.0 ); // ( u, v, -1 ) neg zS

		} );

		return direction;

	} ).setLayout( {
		name: 'getDirection',
		type: 'vec3',
		inputs: [
			{ name: 'uv', type: 'vec2' },
			{ name: 'face', type: 'float' }
		]
	} );

	//

	static var textureCubeUV = ShaderNode.tslFn( ( [ envMap, sampleDir_immutable, roughness_immutable, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP ] ) => {

		var roughness = ShaderNode.float( roughness_immutable );
		var sampleDir = ShaderNode.vec3( sampleDir_immutable );

		var mip = MathNode.clamp( roughnessToMip( roughness ), cubeUV_m0, CUBEUV_MAX_MIP );
		var mipF = MathNode.fract( mip );
		var mipInt = MathNode.floor( mip );
		var color0 = ShaderNode.vec3( bilinearCubeUV( envMap, sampleDir, mipInt, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP ) );

		ShaderNode.If( mipF.notEqual( 0.0 ), () => {

			var color1 = ShaderNode.vec3( bilinearCubeUV( envMap, sampleDir, mipInt.add( 1.0 ), CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP ) );

			color0.assign( MathNode.mix( color0, color1, mipF ) );

		} );

		return color0;

	} );

	static var bilinearCubeUV = ShaderNode.tslFn( ( [ envMap, direction_immutable, mipInt_immutable, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP ] ) => {

		var mipInt = ShaderNode.float( mipInt_immutable );
		var direction = ShaderNode.vec3( direction_immutable );
		var face = ShaderNode.float( getFace( direction ) );
		var filterInt = ShaderNode.float( MathNode.max( cubeUV_minMipLevel.sub( mipInt ), 0.0 ) );
		mipInt.assign( MathNode.max( mipInt, cubeUV_minMipLevel ) );
		var faceSize = ShaderNode.float( MathNode.exp2( mipInt ) );
		var uv = ShaderNode.vec2( getUV( direction, face ).mul( faceSize.sub( 2.0 ) ).add( 1.0 ) );

		ShaderNode.If( face.greaterThan( 2.0 ), () => {

			uv.y.addAssign( faceSize );
			face.subAssign( 3.0 );

		} );

		uv.x.addAssign( face.mul( faceSize ) );
		uv.x.addAssign( filterInt.mul( OperatorNode.mul( 3.0, cubeUV_minTileSize ) ) );
		uv.y.addAssign( OperatorNode.mul( 4.0, MathNode.exp2( CUBEUV_MAX_MIP ).sub( faceSize ) ) );
		uv.x.mulAssign( CUBEUV_TEXEL_WIDTH );
		uv.y.mulAssign( CUBEUV_TEXEL_HEIGHT );

		return envMap.uv( uv ).grad( ShaderNode.vec2(), ShaderNode.vec2() ); // disable anisotropic filtering

	} );

	static var getSample = ShaderNode.tslFn( ( { envMap, mipInt, outputDirection, theta, axis, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP } ) => {

		var cosTheta = MathNode.cos( theta );

		// Rodrigues' axis-angle rotation
		var sampleDirection = outputDirection.mul( cosTheta )
			.add( axis.cross( outputDirection ).mul( MathNode.sin( theta ) ) )
			.add( axis.mul( axis.dot( outputDirection ).mul( MathNode.oneMinus( cosTheta ) ) ) );

		return bilinearCubeUV( envMap, sampleDirection, mipInt, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP );

	} );

	static var blur = ShaderNode.tslFn( ( { n, latitudinal, poleAxis, outputDirection, weights, samples, dTheta, mipInt, envMap, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP } ) => {

		var axis = ShaderNode.vec3( CondNode.cond( latitudinal, poleAxis, OperatorNode.cross( poleAxis, outputDirection ) ) );

		ShaderNode.If( MathNode.all( axis.equals( ShaderNode.vec3( 0.0 ) ) ), () => {

			axis.assign( ShaderNode.vec3( outputDirection.z, 0.0, outputDirection.x.negate() ) );

		} );

		axis.assign( MathNode.normalize( axis ) );

		var gl_FragColor = ShaderNode.vec3();
		gl_FragColor.addAssign( weights.element( ShaderNode.int( 0 ) ).mul( getSample( { theta: 0.0, axis, outputDirection, mipInt, envMap, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP } ) ) );

		LoopNode.loop( { start: ShaderNode.int( 1 ), end: n }, ( { i } ) => {

			ShaderNode.If( i.greaterThanEqual( samples ), () => {

				LoopNode.Break();

			} );

			var theta = ShaderNode.float( dTheta.mul( ShaderNode.float( i ) ) );
			gl_FragColor.addAssign( weights.element( i ).mul( getSample( { theta: theta.mul( - 1.0 ), axis, outputDirection, mipInt, envMap, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP } ) ) );
			gl_FragColor.addAssign( weights.element( i ).mul( getSample( { theta, axis, outputDirection, mipInt, envMap, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP } ) ) );

		} );

		return ShaderNode.vec4( gl_FragColor, 1 );

	} );

}