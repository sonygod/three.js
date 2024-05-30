import tslFn.If;
import tslFn.int;
import tslFn.float;
import tslFn.vec2;
import tslFn.vec3;
import tslFn.vec4;
import tslFn.cond;
import tslFn.loop;
import tslFn.Break;
import tslFn.mul;
import tslFn.cos;
import tslFn.sin;
import tslFn.abs;
import tslFn.max;
import tslFn.exp2;
import tslFn.log2;
import tslFn.clamp;
import tslFn.fract;
import tslFn.mix;
import tslFn.floor;
import tslFn.normalize;
import tslFn.cross;
import tslFn.all;

// These defines must match with PMREMGenerator

const cubeUV_r0 = float( 1.0 );
const cubeUV_m0 = float( - 2.0 );
const cubeUV_r1 = float( 0.8 );
const cubeUV_m1 = float( - 1.0 );
const cubeUV_r4 = float( 0.4 );
const cubeUV_m4 = float( 2.0 );
const cubeUV_r5 = float( 0.305 );
const cubeUV_m5 = float( 3.0 );
const cubeUV_r6 = float( 0.21 );
const cubeUV_m6 = float( 4.0 );

const cubeUV_minMipLevel = float( 4.0 );
const cubeUV_minTileSize = float( 16.0 );

// These shader functions convert between the UV coordinates of a single face of
// a cubemap, the 0-5 integer index of a cube face, and the direction vector for
// sampling a textureCube (not generally normalized ).

const getFace = tslFn( ( [ direction ] ) -> {

	const absDirection = vec3( abs( direction ) );
	const face = float( - 1.0 );

	If( absDirection.x > absDirection.z, () -> {

		If( absDirection.x > absDirection.y, () -> {

			face = cond( direction.x > 0.0, 0.0, 3.0 );

		} ).else( () -> {

			face = cond( direction.y > 0.0, 1.0, 4.0 );

		} );

	} ).else( () -> {

		If( absDirection.z > absDirection.y, () -> {

			face = cond( direction.z > 0.0, 2.0, 5.0 );

		} ).else( () -> {

			face = cond( direction.y > 0.0, 1.0, 4.0 );

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

// RH coordinate system; PMREM face-indexing convention
const getUV = tslFn( ( [ direction, face ] ) -> {

	const uv = vec2();

	If( face == 0.0, () -> {

		uv = vec2( direction.z, direction.y ).div( abs( direction.x ) ); // pos x

	} ).elseif( face == 1.0, () -> {

		uv = vec2( direction.x.negate(), direction.z.negate() ).div( abs( direction.y ) ); // pos y

	} ).elseif( face == 2.0, () -> {

		uv = vec2( direction.x.negate(), direction.y ).div( abs( direction.z ) ); // pos z

	} ).elseif( face == 3.0, () -> {

		uv = vec2( direction.z.negate(), direction.y ).div( abs( direction.x ) ); // neg x

	} ).elseif( face == 4.0, () -> {

		uv = vec2( direction.x.negate(), direction.z ).div( abs( direction.y ) ); // neg y

	} ).else( () -> {

		uv = vec2( direction.x, direction.y ).div( abs( direction.z ) ); // neg z

	} );

	return mul( 0.5, uv.add( 1.0 ) );

} ).setLayout( {
	name: 'getUV',
	type: 'vec2',
	inputs: [
		{ name: 'direction', type: 'vec3' },
		{ name: 'face', type: 'float' }
	]
} );

const roughnessToMip = tslFn( ( [ roughness ] ) -> {

	const mip = float( 0.0 );

	If( roughness >= cubeUV_r1, () -> {

		mip = cubeUV_r0.sub( roughness ).mul( cubeUV_m1.sub( cubeUV_m0 ) ).div( cubeUV_r0.sub( cubeUV_r1 ) ).add( cubeUV_m0 );

	} ).elseif( roughness >= cubeUV_r4, () -> {

		mip = cubeUV_r1.sub( roughness ).mul( cubeUV_m4.sub( cubeUV_m1 ) ).div( cubeUV_r1.sub( cubeUV_r4 ) ).add( cubeUV_m1 );

	} ).elseif( roughness >= cubeUV_r5, () -> {

		mip = cubeUV_r4.sub( roughness ).mul( cubeUV_m5.sub( cubeUV_m4 ) ).div( cubeUV_r4.sub( cubeUV_r5 ) ).add( cubeUV_m4 );

	} ).elseif( roughness >= cubeUV_r6, () -> {

		mip = cubeUV_r5.sub( roughness ).mul( cubeUV_m6.sub( cubeUV_m5 ) ).div( cubeUV_r5.sub( cubeUV_r6 ) ).add( cubeUV_m5 );

	} ).else( () -> {

		mip = float( - 2.0 ).mul( log2( mul( 1.16, roughness ) ) ); // 1.16 = 1.79^0.25

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
export const getDirection = tslFn( ( [ uv_immutable, face ] ) -> {

	const uv = uv_immutable;
	uv = mul( 2.0, uv ).sub( 1.0 );
	const direction = vec3( uv, 1.0 );

	If( face == 0.0, () -> {

		direction = direction.zyx; // ( 1, v, u ) pos x

	} ).elseif( face == 1.0, () -> {

		direction = direction.xzy;
		direction.xz = -1.0; // ( -u, 1, -v ) pos y

	} ).elseif( face == 2.0, () -> {

		direction.x = -1.0; // ( -u, v, 1 ) pos z

	} ).elseif( face == 3.0, () -> {

		direction = direction.zyx;
		direction.xz = -1.0; // ( -1, v, -u ) neg x

	} ).elseif( face == 4.0, () -> {

		direction = direction.xzy;
		direction.xy = -1.0; // ( -u, -1, v ) neg y

	} ).elseif( face == 5.0, () -> {

		direction.z = -1.0; // ( u, v, -1 ) neg zS

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

export const textureCubeUV = tslFn( ( [ envMap, sampleDir_immutable, roughness_immutable, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP ] ) -> {

	const roughness = float( roughness_immutable );
	const sampleDir = vec3( sampleDir_immutable );

	const mip = clamp( roughnessToMip( roughness ), cubeUV_m0, CUBEUV_MAX_MIP );
	const mipF = fract( mip );
	const mipInt = floor( mip );
	const color0 = vec3( bilinearCubeUV( envMap, sampleDir, mipInt, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP ) );

	If( mipF != 0.0, () -> {

		const color1 = vec3( bilinearCubeUV( envMap, sampleDir, mipInt.add( 1.0 ), CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP ) );

		color0 = mix( color0, color1, mipF );

	} );

	return color0;

} );

const bilinearCubeUV = tslFn( ( [ envMap, direction_immutable, mipInt_immutable, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP ] ) -> {

	const mipInt = float( mipInt_immutable );
	const direction = vec3( direction_immutable );
	const face = float( getFace( direction ) );
	const filterInt = float( max( cubeUV_minMipLevel.sub( mipInt ), 0.0 ) );
	mipInt = max( mipInt, cubeUV_minMipLevel );
	const faceSize = float( exp2( mipInt ) );
	const uv = vec2( getUV( direction, face ).mul( faceSize.sub( 2.0 ) ).add( 1.0 ) );

	If( face > 2.0, () -> {

		uv.y += faceSize;
		face -= 3.0;

	} );

	uv.x += face * faceSize;
	uv.x += filterInt * mul( 3.0, cubeUV_minTileSize );
	uv.y += mul( 4.0, exp2( CUBEUV_MAX_MIP ).sub( faceSize ) );
	uv.x *= CUBEUV_TEXEL_WIDTH;
	uv.y *= CUBEUV_TEXEL_HEIGHT;

	return envMap.uv( uv ).grad( vec2(), vec2() ); // disable anisotropic filtering

} );

const getSample = tslFn( ( { envMap, mipInt, outputDirection, theta, axis, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP } ) -> {

	const cosTheta = cos( theta );

	// Rodrigues' axis-angle rotation
	const sampleDirection = outputDirection.mul( cosTheta )
		.add( axis.cross( outputDirection ).mul( sin( theta ) ) )
		.add( axis.mul( axis.dot( outputDirection ).mul( cosTheta.oneMinus() ) ) );

	return bilinearCubeUV( envMap, sampleDirection, mipInt, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP );

} );

export const blur = tslFn( ( { n, latitudinal, poleAxis, outputDirection, weights, samples, dTheta, mipInt, envMap, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP } ) -> {

	const axis = vec3( cond( latitudinal, poleAxis, cross( poleAxis, outputDirection ) ) );

	If( all( axis.equals( vec3( 0.0 ) ) ), () -> {

		axis = vec3( outputDirection.z, 0.0, outputDirection.x.negate() );

	} );

	axis = normalize( axis );

	const gl_FragColor = vec3();
	gl_FragColor.add( weights.element( int( 0 ) ).mul( getSample( { theta: 0.0, axis, outputDirection, mipInt, envMap, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP } ) ) );

	loop( { start: int( 1 ), end: n }, ( { i } ) -> {

		If( i >= samples, () -> {

			Break();

		} );

		const theta = float( dTheta.mul( float( i ) ) );
		gl_FragColor.add( weights.element( i ).mul( getSample( { theta: theta.mul( - 1.0 ), axis, outputDirection, mipInt, envMap, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP } ) ) );
		gl_FragColor.add( weights.element( i ).mul( getSample( { theta, axis, outputDirection, mipInt, envMap, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP } ) ) );

	} );

	return vec4( gl_FragColor, 1 );

} );