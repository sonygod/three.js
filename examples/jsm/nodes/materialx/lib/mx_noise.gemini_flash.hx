// Three.js Transpiler
// https://raw.githubusercontent.com/AcademySoftwareFoundation/MaterialX/main/libraries/stdlib/genglsl/lib/mx_noise.glsl

import shadernode.ShaderNode;
import math.CondNode;
import math.OperatorNode;
import math.MathNode;
import utils.FunctionOverloadingNode;
import utils.LoopNode;

class MXNoise {

	static var mx_select = ShaderNode.tslFn( ( [ b_immutable, t_immutable, f_immutable ] ) => {

		var f = ShaderNode.float( f_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var b = ShaderNode.bool( b_immutable ).toVar();

		return CondNode.cond( b, t, f );

	} );

	static var mx_negate_if = ShaderNode.tslFn( ( [ val_immutable, b_immutable ] ) => {

		var b = ShaderNode.bool( b_immutable ).toVar();
		var val = ShaderNode.float( val_immutable ).toVar();

		return CondNode.cond( b, val.negate(), val );

	} );

	static var mx_floor = ShaderNode.tslFn( ( [ x_immutable ] ) => {

		var x = ShaderNode.float( x_immutable ).toVar();

		return ShaderNode.int( MathNode.floor( x ) );

	} );

	static var mx_floorfrac = ShaderNode.tslFn( ( [ x_immutable, i ] ) => {

		var x = ShaderNode.float( x_immutable ).toVar();
		i.assign( MXNoise.mx_floor( x ) );

		return x.sub( ShaderNode.float( i ) );

	} );

	static var mx_bilerp_0 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, s_immutable, t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v3 = ShaderNode.float( v3_immutable ).toVar();
		var v2 = ShaderNode.float( v2_immutable ).toVar();
		var v1 = ShaderNode.float( v1_immutable ).toVar();
		var v0 = ShaderNode.float( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();

		return OperatorNode.sub( 1.0, t ).mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) );

	} );

	static var mx_bilerp_1 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, s_immutable, t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v3 = ShaderNode.vec3( v3_immutable ).toVar();
		var v2 = ShaderNode.vec3( v2_immutable ).toVar();
		var v1 = ShaderNode.vec3( v1_immutable ).toVar();
		var v0 = ShaderNode.vec3( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();

		return OperatorNode.sub( 1.0, t ).mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) );

	} );

	static var mx_bilerp = FunctionOverloadingNode.overloadingFn( [ mx_bilerp_0, mx_bilerp_1 ] );

	static var mx_trilerp_0 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, v4_immutable, v5_immutable, v6_immutable, v7_immutable, s_immutable, t_immutable, r_immutable ] ) => {

		var r = ShaderNode.float( r_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v7 = ShaderNode.float( v7_immutable ).toVar();
		var v6 = ShaderNode.float( v6_immutable ).toVar();
		var v5 = ShaderNode.float( v5_immutable ).toVar();
		var v4 = ShaderNode.float( v4_immutable ).toVar();
		var v3 = ShaderNode.float( v3_immutable ).toVar();
		var v2 = ShaderNode.float( v2_immutable ).toVar();
		var v1 = ShaderNode.float( v1_immutable ).toVar();
		var v0 = ShaderNode.float( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();
		var t1 = ShaderNode.float( OperatorNode.sub( 1.0, t ) ).toVar();
		var r1 = ShaderNode.float( OperatorNode.sub( 1.0, r ) ).toVar();

		return r1.mul( t1.mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) ) ).add( r.mul( t1.mul( v4.mul( s1 ).add( v5.mul( s ) ) ).add( t.mul( v6.mul( s1 ).add( v7.mul( s ) ) ) ) ) );

	} );

	static var mx_trilerp_1 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, v4_immutable, v5_immutable, v6_immutable, v7_immutable, s_immutable, t_immutable, r_immutable ] ) => {

		var r = ShaderNode.float( r_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v7 = ShaderNode.vec3( v7_immutable ).toVar();
		var v6 = ShaderNode.vec3( v6_immutable ).toVar();
		var v5 = ShaderNode.vec3( v5_immutable ).toVar();
		var v4 = ShaderNode.vec3( v4_immutable ).toVar();
		var v3 = ShaderNode.vec3( v3_immutable ).toVar();
		var v2 = ShaderNode.vec3( v2_immutable ).toVar();
		var v1 = ShaderNode.vec3( v1_immutable ).toVar();
		var v0 = ShaderNode.vec3( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();
		var t1 = ShaderNode.float( OperatorNode.sub( 1.0, t ) ).toVar();
		var r1 = ShaderNode.float( OperatorNode.sub( 1.0, r ) ).toVar();

		return r1.mul( t1.mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) ) ).add( r.mul( t1.mul( v4.mul( s1 ).add( v5.mul( s ) ) ).add( t.mul( v6.mul( s1 ).add( v7.mul( s ) ) ) ) ) );

	} );

	static var mx_trilerp = FunctionOverloadingNode.overloadingFn( [ mx_trilerp_0, mx_trilerp_1 ] );

	static var mx_gradient_float_0 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable ] ) => {

		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uint( hash_immutable ).toVar();
		var h = ShaderNode.uint( hash.bitAnd( ShaderNode.uint( 7 ) ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), x, y ) ).toVar();
		var v = ShaderNode.float( OperatorNode.mul( 2.0, MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), y, x ) ) ).toVar();

		return MXNoise.mx_negate_if( u, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 1 ) ) ) ).add( MXNoise.mx_negate_if( v, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 2 ) ) ) ) );

	} );

	static var mx_gradient_float_1 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.float( z_immutable ).toVar();
		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uint( hash_immutable ).toVar();
		var h = ShaderNode.uint( hash.bitAnd( ShaderNode.uint( 15 ) ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 8 ) ), x, y ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), y, MXNoise.mx_select( h.equal( ShaderNode.uint( 12 ) ).or( h.equal( ShaderNode.uint( 14 ) ) ), x, z ) ) ).toVar();

		return MXNoise.mx_negate_if( u, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 1 ) ) ) ).add( MXNoise.mx_negate_if( v, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 2 ) ) ) ) );

	} );

	static var mx_gradient_float = FunctionOverloadingNode.overloadingFn( [ mx_gradient_float_0, mx_gradient_float_1 ] );

	static var mx_gradient_vec3_0 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable ] ) => {

		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uvec3( hash_immutable ).toVar();

		return ShaderNode.vec3( MXNoise.mx_gradient_float( hash.x, x, y ), MXNoise.mx_gradient_float( hash.y, x, y ), MXNoise.mx_gradient_float( hash.z, x, y ) );

	} );

	static var mx_gradient_vec3_1 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.float( z_immutable ).toVar();
		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uvec3( hash_immutable ).toVar();

		return ShaderNode.vec3( MXNoise.mx_gradient_float( hash.x, x, y, z ), MXNoise.mx_gradient_float( hash.y, x, y, z ), MXNoise.mx_gradient_float( hash.z, x, y, z ) );

	} );

	static var mx_gradient_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_gradient_vec3_0, mx_gradient_vec3_1 ] );

	static var mx_gradient_scale2d_0 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.float( v_immutable ).toVar();

		return OperatorNode.mul( 0.6616, v );

	} );

	static var mx_gradient_scale3d_0 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.float( v_immutable ).toVar();

		return OperatorNode.mul( 0.9820, v );

	} );

	static var mx_gradient_scale2d_1 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.vec3( v_immutable ).toVar();

		return OperatorNode.mul( 0.6616, v );

	} );

	static var mx_gradient_scale2d = FunctionOverloadingNode.overloadingFn( [ mx_gradient_scale2d_0, mx_gradient_scale2d_1 ] );

	static var mx_gradient_scale3d_1 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.vec3( v_immutable ).toVar();

		return OperatorNode.mul( 0.9820, v );

	} );

	static var mx_gradient_scale3d = FunctionOverloadingNode.overloadingFn( [ mx_gradient_scale3d_0, mx_gradient_scale3d_1 ] );

	static var mx_rotl32 = ShaderNode.tslFn( ( [ x_immutable, k_immutable ] ) => {

		var k = ShaderNode.int( k_immutable ).toVar();
		var x = ShaderNode.uint( x_immutable ).toVar();

		return x.shiftLeft( k ).bitOr( x.shiftRight( ShaderNode.int( 32 ).sub( k ) ) );

	} );

	static var mx_bjmix = ShaderNode.tslFn( ( [ a, b, c ] ) => {

		a.subAssign( c );
		a.bitXorAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 4 ) ) );
		c.addAssign( b );
		b.subAssign( a );
		b.bitXorAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 6 ) ) );
		a.addAssign( c );
		c.subAssign( b );
		c.bitXorAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 8 ) ) );
		b.addAssign( a );
		a.subAssign( c );
		a.bitXorAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 16 ) ) );
		c.addAssign( b );
		b.subAssign( a );
		b.bitXorAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 19 ) ) );
		a.addAssign( c );
		c.subAssign( b );
		c.bitXorAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 4 ) ) );
		b.addAssign( a );

	} );

	static var mx_bjfinal = ShaderNode.tslFn( ( [ a_immutable, b_immutable, c_immutable ] ) => {

		var c = ShaderNode.uint( c_immutable ).toVar();
		var b = ShaderNode.uint( b_immutable ).toVar();
		var a = ShaderNode.uint( a_immutable ).toVar();
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 14 ) ) );
		a.bitXorAssign( c );
		a.subAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 11 ) ) );
		b.bitXorAssign( a );
		b.subAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 25 ) ) );
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 16 ) ) );
		a.bitXorAssign( c );
		a.subAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 4 ) ) );
		b.bitXorAssign( a );
		b.subAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 14 ) ) );
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 24 ) ) );

		return c;

	} );

	static var mx_bits_to_01 = ShaderNode.tslFn( ( [ bits_immutable ] ) => {

		var bits = ShaderNode.uint( bits_immutable ).toVar();

		return ShaderNode.float( bits ).div( ShaderNode.float( ShaderNode.uint( ShaderNode.int( 0xffffffff ) ) ) );

	} );

	static var mx_fade = ShaderNode.tslFn( ( [ t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();

		return t.mul( t.mul( t.mul( t.mul( t.mul( 6.0 ).sub( 15.0 ) ).add( 10.0 ) ) ) );

	} );

	static var mx_hash_int_0 = ShaderNode.tslFn( ( [ x_immutable ] ) => {

		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 1 ) ).toVar();
		var seed = ShaderNode.uint( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ).toVar();

		return MXNoise.mx_bjfinal( seed.add( ShaderNode.uint( x ) ), seed, seed );

	} );

	static var mx_hash_int_1 = ShaderNode.tslFn( ( [ x_immutable, y_immutable ] ) => {

		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 2 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_2 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 3 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_3 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable, xx_immutable ] ) => {

		var xx = ShaderNode.int( xx_immutable ).toVar();
		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 4 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );
		MXNoise.mx_bjmix( a, b, c );
		a.addAssign( ShaderNode.uint( xx ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_4 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable, xx_immutable, yy_immutable ] ) => {

		var yy = ShaderNode.int( yy_immutable ).toVar();
		var xx = ShaderNode.int( xx_immutable ).toVar();
		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 5 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );
		MXNoise.mx_bjmix( a, b, c );
		a.addAssign( ShaderNode.uint( xx ) );
		b.addAssign( ShaderNode.uint( yy ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int = FunctionOverloadingNode.overloadingFn( [ mx_hash_int_0, mx_hash_int_1, mx_hash_int_2, mx_hash_int_3, mx_hash_int_4 ] );

	static var mx_hash_vec3_0 = ShaderNode.tslFn( ( [ x_immutable, y_immutable ] ) => {

		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var h = ShaderNode.uint( MXNoise.mx_hash_int( x, y ) ).toVar();
		var result = ShaderNode.uvec3().toVar();
		result.x.assign( h.bitAnd( ShaderNode.int( 0xFF ) ) );
		result.y.assign( h.shiftRight( ShaderNode.int( 8 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );
		result.z.assign( h.shiftRight( ShaderNode.int( 16 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );

		return result;

	} );

	static var mx_hash_vec3_1 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var h = ShaderNode.uint( MXNoise.mx_hash_int( x, y, z ) ).toVar();
		var result = ShaderNode.uvec3().toVar();
		result.x.assign( h.bitAnd( ShaderNode.int( 0xFF ) ) );
		result.y.assign( h.shiftRight( ShaderNode.int( 8 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );
		result.z.assign( h.shiftRight( ShaderNode.int( 16 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );

		return result;

	} );

	static var mx_hash_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_hash_vec3_0, mx_hash_vec3_1 ] );

	static var mx_perlin_noise_float_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec2( p_immutable ).toVar();
		var X = ShaderNode.int().toVar(), Y = ShaderNode.int().toVar();
		var fx = ShaderNode.float( MXNoise.mx_floorfrac( p.x, X ) ).toVar();
		var fy = ShaderNode.float( MXNoise.mx_floorfrac( p.y, Y ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_fade( fx ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_fade( fy ) ).toVar();
		var result = ShaderNode.float( MXNoise.mx_bilerp( MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y ), fx, fy ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y ), fx.sub( 1.0 ), fy ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y.add( ShaderNode.int( 1 ) ) ), fx, fy.sub( 1.0 ) ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy.sub( 1.0 ) ), u, v ) ).toVar();

		return MXNoise.mx_gradient_scale2d( result );

	} );

	static var mx_perlin_noise_float_1 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec3( p_immutable ).toVar();
		var X = ShaderNode.int().toVar(), Y = ShaderNode.int().toVar(), Z = ShaderNode.int().toVar();
		var fx = ShaderNode.float( MXNoise.mx_floorfrac( p.x, X ) ).toVar();
		var fy = ShaderNode.float( MXNoise.mx_floorfrac( p.y, Y ) ).toVar();
		var fz = ShaderNode.float( MXNoise.mx_floorfrac( p.z, Z ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_fade( fx ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_fade( fy ) ).toVar();
		var w = ShaderNode.float( MXNoise.mx_fade( fz ) ).toVar();
		var result = ShaderNode.float( MXNoise.mx_trilerp( MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y, Z ), fx, fy, fz ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y, Z ), fx.sub( 1.0 ), fy, fz ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y.add( ShaderNode.int( 1 ) ), Z ), fx, fy.sub( 1.0 ), fz ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ), Z ), fx.sub( 1.0 ), fy.sub( 1.0 ), fz ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y, Z.add( ShaderNode.int( 1 ) ) ), fx, fy, fz.sub( 1.0 ) ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y, Z.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy, fz.sub( 1.0 ) ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y.add( ShaderNode.int( 1 ) ), Z.add( ShaderNode.int( 1 ) ) ), fx, fy.sub( 1.0 ), fz.sub( 1.0 ) ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ), Z.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy.sub( 1.0 ), fz.sub( 1.0 ) ), u, v, w ) ).toVar();

		return MXNoise.mx_gradient_scale3d( result );

	} );

	static var mx_perlin_noise_float = FunctionOverloadingNode.overloadingFn( [ mx_perlin_noise_float_0, mx_perlin_noise_float_1 ] );

	static var mx_perlin_noise_vec3_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec2( p_immutable ).toVar();
		var X = ShaderNode.int().toVar(), Y = ShaderNode.int().toVar();
		var fx = ShaderNode.float( MXNoise.mx_floorfrac( p.x, X ) ).toVar();
		var fy = ShaderNode.float( MXNoise.mx_floorfrac( p.y, Y ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_fade( fx ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_fade( fy ) ).toVar();
		var result = ShaderNode.vec3( MXNoise.mx_bilerp( MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y ), fx, fy ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y ), fx.sub( 1.0 ), fy ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y.add( ShaderNode.int( 1 ) ) ), fx, fy.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy.sub( 1.0 ) ), u, v ) ).toVar();

		return MXNoise.mx_gradient_scale2d( result );

	} );

	static var mx_perlin_noise_vec3_1 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec3( p_immutable ).toVar();
		var X = ShaderNode.int().toVar(), Y = ShaderNode.int().toVar(), Z = ShaderNode.int().toVar();
		var fx = ShaderNode.float( MXNoise.mx_floorfrac( p.x, X ) ).toVar();
		var fy = ShaderNode.float( MXNoise.mx_floorfrac( p.y, Y ) ).toVar();
		var fz = ShaderNode.float( MXNoise.mx_floorfrac( p.z, Z ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_fade( fx ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_fade( fy ) ).toVar();
		var w = ShaderNode.float( MXNoise.mx_fade( fz ) ).toVar();
		var result = ShaderNode.vec3( MXNoise.mx_trilerp( MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y, Z ), fx, fy, fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y, Z ), fx.sub( 1.0 ), fy, fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash
// Three.js Transpiler
// https://raw.githubusercontent.com/AcademySoftwareFoundation/MaterialX/main/libraries/stdlib/genglsl/lib/mx_noise.glsl

import shadernode.ShaderNode;
import math.CondNode;
import math.OperatorNode;
import math.MathNode;
import utils.FunctionOverloadingNode;
import utils.LoopNode;

class MXNoise {

	static var mx_select = ShaderNode.tslFn( ( [ b_immutable, t_immutable, f_immutable ] ) => {

		var f = ShaderNode.float( f_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var b = ShaderNode.bool( b_immutable ).toVar();

		return CondNode.cond( b, t, f );

	} );

	static var mx_negate_if = ShaderNode.tslFn( ( [ val_immutable, b_immutable ] ) => {

		var b = ShaderNode.bool( b_immutable ).toVar();
		var val = ShaderNode.float( val_immutable ).toVar();

		return CondNode.cond( b, val.negate(), val );

	} );

	static var mx_floor = ShaderNode.tslFn( ( [ x_immutable ] ) => {

		var x = ShaderNode.float( x_immutable ).toVar();

		return ShaderNode.int( MathNode.floor( x ) );

	} );

	static var mx_floorfrac = ShaderNode.tslFn( ( [ x_immutable, i ] ) => {

		var x = ShaderNode.float( x_immutable ).toVar();
		i.assign( MXNoise.mx_floor( x ) );

		return x.sub( ShaderNode.float( i ) );

	} );

	static var mx_bilerp_0 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, s_immutable, t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v3 = ShaderNode.float( v3_immutable ).toVar();
		var v2 = ShaderNode.float( v2_immutable ).toVar();
		var v1 = ShaderNode.float( v1_immutable ).toVar();
		var v0 = ShaderNode.float( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();

		return OperatorNode.sub( 1.0, t ).mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) );

	} );

	static var mx_bilerp_1 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, s_immutable, t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v3 = ShaderNode.vec3( v3_immutable ).toVar();
		var v2 = ShaderNode.vec3( v2_immutable ).toVar();
		var v1 = ShaderNode.vec3( v1_immutable ).toVar();
		var v0 = ShaderNode.vec3( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();

		return OperatorNode.sub( 1.0, t ).mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) );

	} );

	static var mx_bilerp = FunctionOverloadingNode.overloadingFn( [ mx_bilerp_0, mx_bilerp_1 ] );

	static var mx_trilerp_0 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, v4_immutable, v5_immutable, v6_immutable, v7_immutable, s_immutable, t_immutable, r_immutable ] ) => {

		var r = ShaderNode.float( r_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v7 = ShaderNode.float( v7_immutable ).toVar();
		var v6 = ShaderNode.float( v6_immutable ).toVar();
		var v5 = ShaderNode.float( v5_immutable ).toVar();
		var v4 = ShaderNode.float( v4_immutable ).toVar();
		var v3 = ShaderNode.float( v3_immutable ).toVar();
		var v2 = ShaderNode.float( v2_immutable ).toVar();
		var v1 = ShaderNode.float( v1_immutable ).toVar();
		var v0 = ShaderNode.float( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();
		var t1 = ShaderNode.float( OperatorNode.sub( 1.0, t ) ).toVar();
		var r1 = ShaderNode.float( OperatorNode.sub( 1.0, r ) ).toVar();

		return r1.mul( t1.mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) ) ).add( r.mul( t1.mul( v4.mul( s1 ).add( v5.mul( s ) ) ).add( t.mul( v6.mul( s1 ).add( v7.mul( s ) ) ) ) ) );

	} );

	static var mx_trilerp_1 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, v4_immutable, v5_immutable, v6_immutable, v7_immutable, s_immutable, t_immutable, r_immutable ] ) => {

		var r = ShaderNode.float( r_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v7 = ShaderNode.vec3( v7_immutable ).toVar();
		var v6 = ShaderNode.vec3( v6_immutable ).toVar();
		var v5 = ShaderNode.vec3( v5_immutable ).toVar();
		var v4 = ShaderNode.vec3( v4_immutable ).toVar();
		var v3 = ShaderNode.vec3( v3_immutable ).toVar();
		var v2 = ShaderNode.vec3( v2_immutable ).toVar();
		var v1 = ShaderNode.vec3( v1_immutable ).toVar();
		var v0 = ShaderNode.vec3( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();
		var t1 = ShaderNode.float( OperatorNode.sub( 1.0, t ) ).toVar();
		var r1 = ShaderNode.float( OperatorNode.sub( 1.0, r ) ).toVar();

		return r1.mul( t1.mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) ) ).add( r.mul( t1.mul( v4.mul( s1 ).add( v5.mul( s ) ) ).add( t.mul( v6.mul( s1 ).add( v7.mul( s ) ) ) ) ) );

	} );

	static var mx_trilerp = FunctionOverloadingNode.overloadingFn( [ mx_trilerp_0, mx_trilerp_1 ] );

	static var mx_gradient_float_0 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable ] ) => {

		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uint( hash_immutable ).toVar();
		var h = ShaderNode.uint( hash.bitAnd( ShaderNode.uint( 7 ) ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), x, y ) ).toVar();
		var v = ShaderNode.float( OperatorNode.mul( 2.0, MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), y, x ) ) ).toVar();

		return MXNoise.mx_negate_if( u, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 1 ) ) ) ).add( MXNoise.mx_negate_if( v, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 2 ) ) ) ) );

	} );

	static var mx_gradient_float_1 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.float( z_immutable ).toVar();
		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uint( hash_immutable ).toVar();
		var h = ShaderNode.uint( hash.bitAnd( ShaderNode.uint( 15 ) ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 8 ) ), x, y ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), y, MXNoise.mx_select( h.equal( ShaderNode.uint( 12 ) ).or( h.equal( ShaderNode.uint( 14 ) ) ), x, z ) ) ).toVar();

		return MXNoise.mx_negate_if( u, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 1 ) ) ) ).add( MXNoise.mx_negate_if( v, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 2 ) ) ) ) );

	} );

	static var mx_gradient_float = FunctionOverloadingNode.overloadingFn( [ mx_gradient_float_0, mx_gradient_float_1 ] );

	static var mx_gradient_vec3_0 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable ] ) => {

		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uvec3( hash_immutable ).toVar();

		return ShaderNode.vec3( MXNoise.mx_gradient_float( hash.x, x, y ), MXNoise.mx_gradient_float( hash.y, x, y ), MXNoise.mx_gradient_float( hash.z, x, y ) );

	} );

	static var mx_gradient_vec3_1 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.float( z_immutable ).toVar();
		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uvec3( hash_immutable ).toVar();

		return ShaderNode.vec3( MXNoise.mx_gradient_float( hash.x, x, y, z ), MXNoise.mx_gradient_float( hash.y, x, y, z ), MXNoise.mx_gradient_float( hash.z, x, y, z ) );

	} );

	static var mx_gradient_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_gradient_vec3_0, mx_gradient_vec3_1 ] );

	static var mx_gradient_scale2d_0 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.float( v_immutable ).toVar();

		return OperatorNode.mul( 0.6616, v );

	} );

	static var mx_gradient_scale3d_0 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.float( v_immutable ).toVar();

		return OperatorNode.mul( 0.9820, v );

	} );

	static var mx_gradient_scale2d_1 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.vec3( v_immutable ).toVar();

		return OperatorNode.mul( 0.6616, v );

	} );

	static var mx_gradient_scale2d = FunctionOverloadingNode.overloadingFn( [ mx_gradient_scale2d_0, mx_gradient_scale2d_1 ] );

	static var mx_gradient_scale3d_1 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.vec3( v_immutable ).toVar();

		return OperatorNode.mul( 0.9820, v );

	} );

	static var mx_gradient_scale3d = FunctionOverloadingNode.overloadingFn( [ mx_gradient_scale3d_0, mx_gradient_scale3d_1 ] );

	static var mx_rotl32 = ShaderNode.tslFn( ( [ x_immutable, k_immutable ] ) => {

		var k = ShaderNode.int( k_immutable ).toVar();
		var x = ShaderNode.uint( x_immutable ).toVar();

		return x.shiftLeft( k ).bitOr( x.shiftRight( ShaderNode.int( 32 ).sub( k ) ) );

	} );

	static var mx_bjmix = ShaderNode.tslFn( ( [ a, b, c ] ) => {

		a.subAssign( c );
		a.bitXorAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 4 ) ) );
		c.addAssign( b );
		b.subAssign( a );
		b.bitXorAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 6 ) ) );
		a.addAssign( c );
		c.subAssign( b );
		c.bitXorAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 8 ) ) );
		b.addAssign( a );
		a.subAssign( c );
		a.bitXorAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 16 ) ) );
		c.addAssign( b );
		b.subAssign( a );
		b.bitXorAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 19 ) ) );
		a.addAssign( c );
		c.subAssign( b );
		c.bitXorAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 4 ) ) );
		b.addAssign( a );

	} );

	static var mx_bjfinal = ShaderNode.tslFn( ( [ a_immutable, b_immutable, c_immutable ] ) => {

		var c = ShaderNode.uint( c_immutable ).toVar();
		var b = ShaderNode.uint( b_immutable ).toVar();
		var a = ShaderNode.uint( a_immutable ).toVar();
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 14 ) ) );
		a.bitXorAssign( c );
		a.subAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 11 ) ) );
		b.bitXorAssign( a );
		b.subAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 25 ) ) );
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 16 ) ) );
		a.bitXorAssign( c );
		a.subAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 4 ) ) );
		b.bitXorAssign( a );
		b.subAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 14 ) ) );
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 24 ) ) );

		return c;

	} );

	static var mx_bits_to_01 = ShaderNode.tslFn( ( [ bits_immutable ] ) => {

		var bits = ShaderNode.uint( bits_immutable ).toVar();

		return ShaderNode.float( bits ).div( ShaderNode.float( ShaderNode.uint( ShaderNode.int( 0xffffffff ) ) ) );

	} );

	static var mx_fade = ShaderNode.tslFn( ( [ t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();

		return t.mul( t.mul( t.mul( t.mul( t.mul( 6.0 ).sub( 15.0 ) ).add( 10.0 ) ) ) );

	} );

	static var mx_hash_int_0 = ShaderNode.tslFn( ( [ x_immutable ] ) => {

		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 1 ) ).toVar();
		var seed = ShaderNode.uint( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ).toVar();

		return MXNoise.mx_bjfinal( seed.add( ShaderNode.uint( x ) ), seed, seed );

	} );

	static var mx_hash_int_1 = ShaderNode.tslFn( ( [ x_immutable, y_immutable ] ) => {

		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 2 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_2 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 3 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_3 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable, xx_immutable ] ) => {

		var xx = ShaderNode.int( xx_immutable ).toVar();
		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 4 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );
		MXNoise.mx_bjmix( a, b, c );
		a.addAssign( ShaderNode.uint( xx ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_4 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable, xx_immutable, yy_immutable ] ) => {

		var yy = ShaderNode.int( yy_immutable ).toVar();
		var xx = ShaderNode.int( xx_immutable ).toVar();
		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 5 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );
		MXNoise.mx_bjmix( a, b, c );
		a.addAssign( ShaderNode.uint( xx ) );
		b.addAssign( ShaderNode.uint( yy ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int = FunctionOverloadingNode.overloadingFn( [ mx_hash_int_0, mx_hash_int_1, mx_hash_int_2, mx_hash_int_3, mx_hash_int_4 ] );

	static var mx_hash_vec3_0 = ShaderNode.tslFn( ( [ x_immutable, y_immutable ] ) => {

		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var h = ShaderNode.uint( MXNoise.mx_hash_int( x, y ) ).toVar();
		var result = ShaderNode.uvec3().toVar();
		result.x.assign( h.bitAnd( ShaderNode.int( 0xFF ) ) );
		result.y.assign( h.shiftRight( ShaderNode.int( 8 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );
		result.z.assign( h.shiftRight( ShaderNode.int( 16 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );

		return result;

	} );

	static var mx_hash_vec3_1 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var h = ShaderNode.uint( MXNoise.mx_hash_int( x, y, z ) ).toVar();
		var result = ShaderNode.uvec3().toVar();
		result.x.assign( h.bitAnd( ShaderNode.int( 0xFF ) ) );
		result.y.assign( h.shiftRight( ShaderNode.int( 8 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );
		result.z.assign( h.shiftRight( ShaderNode.int( 16 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );

		return result;

	} );

	static var mx_hash_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_hash_vec3_0, mx_hash_vec3_1 ] );

	static var mx_perlin_noise_float_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec2( p_immutable ).toVar();
		var X = ShaderNode.int().toVar(), Y = ShaderNode.int().toVar();
		var fx = ShaderNode.float( MXNoise.mx_floorfrac( p.x, X ) ).toVar();
		var fy = ShaderNode.float( MXNoise.mx_floorfrac( p.y, Y ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_fade( fx ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_fade( fy ) ).toVar();
		var result = ShaderNode.float( MXNoise.mx_bilerp( MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y ), fx, fy ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y ), fx.sub( 1.0 ), fy ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y.add( ShaderNode.int( 1 ) ) ), fx, fy.sub( 1.0 ) ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy.sub( 1.0 ) ), u, v ) ).toVar();

		return MXNoise.mx_gradient_scale2d( result );

	} );

	static var mx_perlin_noise_float_1 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec3( p_immutable ).toVar();
		var X = ShaderNode.int().toVar(), Y = ShaderNode.int().toVar(), Z = ShaderNode.int().toVar();
		var fx = ShaderNode.float( MXNoise.mx_floorfrac( p.x, X ) ).toVar();
		var fy = ShaderNode.float( MXNoise.mx_floorfrac( p.y, Y ) ).toVar();
		var fz = ShaderNode.float( MXNoise.mx_floorfrac( p.z, Z ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_fade( fx ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_fade( fy ) ).toVar();
		var w = ShaderNode.float( MXNoise.mx_fade( fz ) ).toVar();
		var result = ShaderNode.vec3( MXNoise.mx_trilerp( MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y, Z ), fx, fy, fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y, Z ), fx.sub( 1.0 ), fy, fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y.add( ShaderNode.int( 1 ) ), Z ), fx, fy.sub( 1.0 ), fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ), Z ), fx.sub( 1.0 ), fy.sub( 1.0 ), fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y, Z.add( ShaderNode.int( 1 ) ) ), fx, fy, fz.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y, Z.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy, fz.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y.add( ShaderNode.int( 1 ) ), Z.add( ShaderNode.int( 1 ) ) ), fx, fy.sub( 1.0 ), fz.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ), Z.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy.sub( 1.0 ), fz.sub( 1.0 ) ), u, v, w ) ).toVar();

		return MXNoise.mx_gradient_scale3d( result );

	} );

	static var mx_perlin_noise_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_perlin_noise_vec3_0, mx_perlin_noise_vec3_1 ] );

	static var mx_cell_noise_float_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.float( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix ) );

	} );

	static var mx_cell_noise_float_1 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec2( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p.x ) ).toVar();
		var iy = ShaderNode.int( MXNoise.mx_floor( p.y ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, iy ) );

	} );

	static var mx_cell_noise_float_2 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec3( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p.x ) ).toVar();
		var iy = ShaderNode.int( MXNoise.mx_floor( p.y ) ).toVar();
		var iz = ShaderNode.int( MXNoise.mx_floor( p.z ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, iy, iz ) );

	} );

	static var mx_cell_noise_float_3 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec4( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p.x ) ).toVar();
		var iy = ShaderNode.int( MXNoise.mx_floor( p.y ) ).toVar();
		var iz = ShaderNode.int( MXNoise.mx_floor( p.z ) ).toVar();
		var iw = ShaderNode.int( MXNoise.mx_floor( p.w ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, iy, iz, iw ) );

	} );

	static var mx_cell_noise_float = FunctionOverloadingNode.overloadingFn( [ mx_cell_noise_float_0, mx_cell_noise_float_1, mx_cell_noise_float_2, mx_cell_noise_float_3 ] );

	static var mx_cell_noise_vec3_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.float( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p ) ).toVar();

		return ShaderNode.vec3( MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, ShaderNode.
// Three.js Transpiler
// https://raw.githubusercontent.com/AcademySoftwareFoundation/MaterialX/main/libraries/stdlib/genglsl/lib/mx_noise.glsl

import shadernode.ShaderNode;
import math.CondNode;
import math.OperatorNode;
import math.MathNode;
import utils.FunctionOverloadingNode;
import utils.LoopNode;

class MXNoise {

	static var mx_select = ShaderNode.tslFn( ( [ b_immutable, t_immutable, f_immutable ] ) => {

		var f = ShaderNode.float( f_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var b = ShaderNode.bool( b_immutable ).toVar();

		return CondNode.cond( b, t, f );

	} );

	static var mx_negate_if = ShaderNode.tslFn( ( [ val_immutable, b_immutable ] ) => {

		var b = ShaderNode.bool( b_immutable ).toVar();
		var val = ShaderNode.float( val_immutable ).toVar();

		return CondNode.cond( b, val.negate(), val );

	} );

	static var mx_floor = ShaderNode.tslFn( ( [ x_immutable ] ) => {

		var x = ShaderNode.float( x_immutable ).toVar();

		return ShaderNode.int( MathNode.floor( x ) );

	} );

	static var mx_floorfrac = ShaderNode.tslFn( ( [ x_immutable, i ] ) => {

		var x = ShaderNode.float( x_immutable ).toVar();
		i.assign( MXNoise.mx_floor( x ) );

		return x.sub( ShaderNode.float( i ) );

	} );

	static var mx_bilerp_0 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, s_immutable, t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v3 = ShaderNode.float( v3_immutable ).toVar();
		var v2 = ShaderNode.float( v2_immutable ).toVar();
		var v1 = ShaderNode.float( v1_immutable ).toVar();
		var v0 = ShaderNode.float( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();

		return OperatorNode.sub( 1.0, t ).mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) );

	} );

	static var mx_bilerp_1 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, s_immutable, t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v3 = ShaderNode.vec3( v3_immutable ).toVar();
		var v2 = ShaderNode.vec3( v2_immutable ).toVar();
		var v1 = ShaderNode.vec3( v1_immutable ).toVar();
		var v0 = ShaderNode.vec3( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();

		return OperatorNode.sub( 1.0, t ).mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) );

	} );

	static var mx_bilerp = FunctionOverloadingNode.overloadingFn( [ mx_bilerp_0, mx_bilerp_1 ] );

	static var mx_trilerp_0 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, v4_immutable, v5_immutable, v6_immutable, v7_immutable, s_immutable, t_immutable, r_immutable ] ) => {

		var r = ShaderNode.float( r_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v7 = ShaderNode.float( v7_immutable ).toVar();
		var v6 = ShaderNode.float( v6_immutable ).toVar();
		var v5 = ShaderNode.float( v5_immutable ).toVar();
		var v4 = ShaderNode.float( v4_immutable ).toVar();
		var v3 = ShaderNode.float( v3_immutable ).toVar();
		var v2 = ShaderNode.float( v2_immutable ).toVar();
		var v1 = ShaderNode.float( v1_immutable ).toVar();
		var v0 = ShaderNode.float( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();
		var t1 = ShaderNode.float( OperatorNode.sub( 1.0, t ) ).toVar();
		var r1 = ShaderNode.float( OperatorNode.sub( 1.0, r ) ).toVar();

		return r1.mul( t1.mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) ) ).add( r.mul( t1.mul( v4.mul( s1 ).add( v5.mul( s ) ) ).add( t.mul( v6.mul( s1 ).add( v7.mul( s ) ) ) ) ) );

	} );

	static var mx_trilerp_1 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, v4_immutable, v5_immutable, v6_immutable, v7_immutable, s_immutable, t_immutable, r_immutable ] ) => {

		var r = ShaderNode.float( r_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v7 = ShaderNode.vec3( v7_immutable ).toVar();
		var v6 = ShaderNode.vec3( v6_immutable ).toVar();
		var v5 = ShaderNode.vec3( v5_immutable ).toVar();
		var v4 = ShaderNode.vec3( v4_immutable ).toVar();
		var v3 = ShaderNode.vec3( v3_immutable ).toVar();
		var v2 = ShaderNode.vec3( v2_immutable ).toVar();
		var v1 = ShaderNode.vec3( v1_immutable ).toVar();
		var v0 = ShaderNode.vec3( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();
		var t1 = ShaderNode.float( OperatorNode.sub( 1.0, t ) ).toVar();
		var r1 = ShaderNode.float( OperatorNode.sub( 1.0, r ) ).toVar();

		return r1.mul( t1.mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) ) ).add( r.mul( t1.mul( v4.mul( s1 ).add( v5.mul( s ) ) ).add( t.mul( v6.mul( s1 ).add( v7.mul( s ) ) ) ) ) );

	} );

	static var mx_trilerp = FunctionOverloadingNode.overloadingFn( [ mx_trilerp_0, mx_trilerp_1 ] );

	static var mx_gradient_float_0 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable ] ) => {

		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uint( hash_immutable ).toVar();
		var h = ShaderNode.uint( hash.bitAnd( ShaderNode.uint( 7 ) ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), x, y ) ).toVar();
		var v = ShaderNode.float( OperatorNode.mul( 2.0, MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), y, x ) ) ).toVar();

		return MXNoise.mx_negate_if( u, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 1 ) ) ) ).add( MXNoise.mx_negate_if( v, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 2 ) ) ) ) );

	} );

	static var mx_gradient_float_1 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.float( z_immutable ).toVar();
		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uint( hash_immutable ).toVar();
		var h = ShaderNode.uint( hash.bitAnd( ShaderNode.uint( 15 ) ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 8 ) ), x, y ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), y, MXNoise.mx_select( h.equal( ShaderNode.uint( 12 ) ).or( h.equal( ShaderNode.uint( 14 ) ) ), x, z ) ) ).toVar();

		return MXNoise.mx_negate_if( u, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 1 ) ) ) ).add( MXNoise.mx_negate_if( v, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 2 ) ) ) ) );

	} );

	static var mx_gradient_float = FunctionOverloadingNode.overloadingFn( [ mx_gradient_float_0, mx_gradient_float_1 ] );

	static var mx_gradient_vec3_0 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable ] ) => {

		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uvec3( hash_immutable ).toVar();

		return ShaderNode.vec3( MXNoise.mx_gradient_float( hash.x, x, y ), MXNoise.mx_gradient_float( hash.y, x, y ), MXNoise.mx_gradient_float( hash.z, x, y ) );

	} );

	static var mx_gradient_vec3_1 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.float( z_immutable ).toVar();
		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uvec3( hash_immutable ).toVar();

		return ShaderNode.vec3( MXNoise.mx_gradient_float( hash.x, x, y, z ), MXNoise.mx_gradient_float( hash.y, x, y, z ), MXNoise.mx_gradient_float( hash.z, x, y, z ) );

	} );

	static var mx_gradient_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_gradient_vec3_0, mx_gradient_vec3_1 ] );

	static var mx_gradient_scale2d_0 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.float( v_immutable ).toVar();

		return OperatorNode.mul( 0.6616, v );

	} );

	static var mx_gradient_scale3d_0 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.float( v_immutable ).toVar();

		return OperatorNode.mul( 0.9820, v );

	} );

	static var mx_gradient_scale2d_1 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.vec3( v_immutable ).toVar();

		return OperatorNode.mul( 0.6616, v );

	} );

	static var mx_gradient_scale2d = FunctionOverloadingNode.overloadingFn( [ mx_gradient_scale2d_0, mx_gradient_scale2d_1 ] );

	static var mx_gradient_scale3d_1 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.vec3( v_immutable ).toVar();

		return OperatorNode.mul( 0.9820, v );

	} );

	static var mx_gradient_scale3d = FunctionOverloadingNode.overloadingFn( [ mx_gradient_scale3d_0, mx_gradient_scale3d_1 ] );

	static var mx_rotl32 = ShaderNode.tslFn( ( [ x_immutable, k_immutable ] ) => {

		var k = ShaderNode.int( k_immutable ).toVar();
		var x = ShaderNode.uint( x_immutable ).toVar();

		return x.shiftLeft( k ).bitOr( x.shiftRight( ShaderNode.int( 32 ).sub( k ) ) );

	} );

	static var mx_bjmix = ShaderNode.tslFn( ( [ a, b, c ] ) => {

		a.subAssign( c );
		a.bitXorAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 4 ) ) );
		c.addAssign( b );
		b.subAssign( a );
		b.bitXorAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 6 ) ) );
		a.addAssign( c );
		c.subAssign( b );
		c.bitXorAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 8 ) ) );
		b.addAssign( a );
		a.subAssign( c );
		a.bitXorAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 16 ) ) );
		c.addAssign( b );
		b.subAssign( a );
		b.bitXorAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 19 ) ) );
		a.addAssign( c );
		c.subAssign( b );
		c.bitXorAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 4 ) ) );
		b.addAssign( a );

	} );

	static var mx_bjfinal = ShaderNode.tslFn( ( [ a_immutable, b_immutable, c_immutable ] ) => {

		var c = ShaderNode.uint( c_immutable ).toVar();
		var b = ShaderNode.uint( b_immutable ).toVar();
		var a = ShaderNode.uint( a_immutable ).toVar();
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 14 ) ) );
		a.bitXorAssign( c );
		a.subAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 11 ) ) );
		b.bitXorAssign( a );
		b.subAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 25 ) ) );
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 16 ) ) );
		a.bitXorAssign( c );
		a.subAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 4 ) ) );
		b.bitXorAssign( a );
		b.subAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 14 ) ) );
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 24 ) ) );

		return c;

	} );

	static var mx_bits_to_01 = ShaderNode.tslFn( ( [ bits_immutable ] ) => {

		var bits = ShaderNode.uint( bits_immutable ).toVar();

		return ShaderNode.float( bits ).div( ShaderNode.float( ShaderNode.uint( ShaderNode.int( 0xffffffff ) ) ) );

	} );

	static var mx_fade = ShaderNode.tslFn( ( [ t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();

		return t.mul( t.mul( t.mul( t.mul( t.mul( 6.0 ).sub( 15.0 ) ).add( 10.0 ) ) ) );

	} );

	static var mx_hash_int_0 = ShaderNode.tslFn( ( [ x_immutable ] ) => {

		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 1 ) ).toVar();
		var seed = ShaderNode.uint( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ).toVar();

		return MXNoise.mx_bjfinal( seed.add( ShaderNode.uint( x ) ), seed, seed );

	} );

	static var mx_hash_int_1 = ShaderNode.tslFn( ( [ x_immutable, y_immutable ] ) => {

		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 2 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_2 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 3 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_3 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable, xx_immutable ] ) => {

		var xx = ShaderNode.int( xx_immutable ).toVar();
		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 4 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );
		MXNoise.mx_bjmix( a, b, c );
		a.addAssign( ShaderNode.uint( xx ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_4 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable, xx_immutable, yy_immutable ] ) => {

		var yy = ShaderNode.int( yy_immutable ).toVar();
		var xx = ShaderNode.int( xx_immutable ).toVar();
		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 5 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );
		MXNoise.mx_bjmix( a, b, c );
		a.addAssign( ShaderNode.uint( xx ) );
		b.addAssign( ShaderNode.uint( yy ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int = FunctionOverloadingNode.overloadingFn( [ mx_hash_int_0, mx_hash_int_1, mx_hash_int_2, mx_hash_int_3, mx_hash_int_4 ] );

	static var mx_hash_vec3_0 = ShaderNode.tslFn( ( [ x_immutable, y_immutable ] ) => {

		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var h = ShaderNode.uint( MXNoise.mx_hash_int( x, y ) ).toVar();
		var result = ShaderNode.uvec3().toVar();
		result.x.assign( h.bitAnd( ShaderNode.int( 0xFF ) ) );
		result.y.assign( h.shiftRight( ShaderNode.int( 8 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );
		result.z.assign( h.shiftRight( ShaderNode.int( 16 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );

		return result;

	} );

	static var mx_hash_vec3_1 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var h = ShaderNode.uint( MXNoise.mx_hash_int( x, y, z ) ).toVar();
		var result = ShaderNode.uvec3().toVar();
		result.x.assign( h.bitAnd( ShaderNode.int( 0xFF ) ) );
		result.y.assign( h.shiftRight( ShaderNode.int( 8 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );
		result.z.assign( h.shiftRight( ShaderNode.int( 16 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );

		return result;

	} );

	static var mx_hash_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_hash_vec3_0, mx_hash_vec3_1 ] );

	static var mx_perlin_noise_float_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec2( p_immutable ).toVar();
		var X = ShaderNode.int().toVar(), Y = ShaderNode.int().toVar();
		var fx = ShaderNode.float( MXNoise.mx_floorfrac( p.x, X ) ).toVar();
		var fy = ShaderNode.float( MXNoise.mx_floorfrac( p.y, Y ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_fade( fx ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_fade( fy ) ).toVar();
		var result = ShaderNode.float( MXNoise.mx_bilerp( MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y ), fx, fy ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y ), fx.sub( 1.0 ), fy ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y.add( ShaderNode.int( 1 ) ) ), fx, fy.sub( 1.0 ) ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy.sub( 1.0 ) ), u, v ) ).toVar();

		return MXNoise.mx_gradient_scale2d( result );

	} );

	static var mx_perlin_noise_float_1 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec3( p_immutable ).toVar();
		var X = ShaderNode.int().toVar(), Y = ShaderNode.int().toVar(), Z = ShaderNode.int().toVar();
		var fx = ShaderNode.float( MXNoise.mx_floorfrac( p.x, X ) ).toVar();
		var fy = ShaderNode.float( MXNoise.mx_floorfrac( p.y, Y ) ).toVar();
		var fz = ShaderNode.float( MXNoise.mx_floorfrac( p.z, Z ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_fade( fx ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_fade( fy ) ).toVar();
		var w = ShaderNode.float( MXNoise.mx_fade( fz ) ).toVar();
		var result = ShaderNode.vec3( MXNoise.mx_trilerp( MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y, Z ), fx, fy, fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y, Z ), fx.sub( 1.0 ), fy, fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y.add( ShaderNode.int( 1 ) ), Z ), fx, fy.sub( 1.0 ), fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ), Z ), fx.sub( 1.0 ), fy.sub( 1.0 ), fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y, Z.add( ShaderNode.int( 1 ) ) ), fx, fy, fz.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y, Z.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy, fz.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y.add( ShaderNode.int( 1 ) ), Z.add( ShaderNode.int( 1 ) ) ), fx, fy.sub( 1.0 ), fz.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ), Z.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy.sub( 1.0 ), fz.sub( 1.0 ) ), u, v, w ) ).toVar();

		return MXNoise.mx_gradient_scale3d( result );

	} );

	static var mx_perlin_noise_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_perlin_noise_vec3_0, mx_perlin_noise_vec3_1 ] );

	static var mx_cell_noise_float_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.float( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix ) );

	} );

	static var mx_cell_noise_float_1 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec2( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p.x ) ).toVar();
		var iy = ShaderNode.int( MXNoise.mx_floor( p.y ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, iy ) );

	} );

	static var mx_cell_noise_float_2 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec3( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p.x ) ).toVar();
		var iy = ShaderNode.int( MXNoise.mx_floor( p.y ) ).toVar();
		var iz = ShaderNode.int( MXNoise.mx_floor( p.z ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, iy, iz ) );

	} );

	static var mx_cell_noise_float_3 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec4( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p.x ) ).toVar();
		var iy = ShaderNode.int( MXNoise.mx_floor( p.y ) ).toVar();
		var iz = ShaderNode.int( MXNoise.mx_floor( p.z ) ).toVar();
		var iw = ShaderNode.int( MXNoise.mx_floor( p.w ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, iy, iz, iw ) );

	} );

	static var mx_cell_noise_float = FunctionOverloadingNode.overloadingFn( [ mx_cell_noise_float_0, mx_cell_noise_float_1, mx_cell_noise_float_2, mx_cell_noise_float_3 ] );

	static var mx_cell_noise_vec3_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.float( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p ) ).toVar();

		return ShaderNode.vec3( MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, ShaderNode.
// Three.js Transpiler
// https://raw.githubusercontent.com/AcademySoftwareFoundation/MaterialX/main/libraries/stdlib/genglsl/lib/mx_noise.glsl

import shadernode.ShaderNode;
import math.CondNode;
import math.OperatorNode;
import math.MathNode;
import utils.FunctionOverloadingNode;
import utils.LoopNode;

class MXNoise {

	static var mx_select = ShaderNode.tslFn( ( [ b_immutable, t_immutable, f_immutable ] ) => {

		var f = ShaderNode.float( f_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var b = ShaderNode.bool( b_immutable ).toVar();

		return CondNode.cond( b, t, f );

	} );

	static var mx_negate_if = ShaderNode.tslFn( ( [ val_immutable, b_immutable ] ) => {

		var b = ShaderNode.bool( b_immutable ).toVar();
		var val = ShaderNode.float( val_immutable ).toVar();

		return CondNode.cond( b, val.negate(), val );

	} );

	static var mx_floor = ShaderNode.tslFn( ( [ x_immutable ] ) => {

		var x = ShaderNode.float( x_immutable ).toVar();

		return ShaderNode.int( MathNode.floor( x ) );

	} );

	static var mx_floorfrac = ShaderNode.tslFn( ( [ x_immutable, i ] ) => {

		var x = ShaderNode.float( x_immutable ).toVar();
		i.assign( MXNoise.mx_floor( x ) );

		return x.sub( ShaderNode.float( i ) );

	} );

	static var mx_bilerp_0 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, s_immutable, t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v3 = ShaderNode.float( v3_immutable ).toVar();
		var v2 = ShaderNode.float( v2_immutable ).toVar();
		var v1 = ShaderNode.float( v1_immutable ).toVar();
		var v0 = ShaderNode.float( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();

		return OperatorNode.sub( 1.0, t ).mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) );

	} );

	static var mx_bilerp_1 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, s_immutable, t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v3 = ShaderNode.vec3( v3_immutable ).toVar();
		var v2 = ShaderNode.vec3( v2_immutable ).toVar();
		var v1 = ShaderNode.vec3( v1_immutable ).toVar();
		var v0 = ShaderNode.vec3( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();

		return OperatorNode.sub( 1.0, t ).mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) );

	} );

	static var mx_bilerp = FunctionOverloadingNode.overloadingFn( [ mx_bilerp_0, mx_bilerp_1 ] );

	static var mx_trilerp_0 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, v4_immutable, v5_immutable, v6_immutable, v7_immutable, s_immutable, t_immutable, r_immutable ] ) => {

		var r = ShaderNode.float( r_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v7 = ShaderNode.float( v7_immutable ).toVar();
		var v6 = ShaderNode.float( v6_immutable ).toVar();
		var v5 = ShaderNode.float( v5_immutable ).toVar();
		var v4 = ShaderNode.float( v4_immutable ).toVar();
		var v3 = ShaderNode.float( v3_immutable ).toVar();
		var v2 = ShaderNode.float( v2_immutable ).toVar();
		var v1 = ShaderNode.float( v1_immutable ).toVar();
		var v0 = ShaderNode.float( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();
		var t1 = ShaderNode.float( OperatorNode.sub( 1.0, t ) ).toVar();
		var r1 = ShaderNode.float( OperatorNode.sub( 1.0, r ) ).toVar();

		return r1.mul( t1.mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) ) ).add( r.mul( t1.mul( v4.mul( s1 ).add( v5.mul( s ) ) ).add( t.mul( v6.mul( s1 ).add( v7.mul( s ) ) ) ) ) );

	} );

	static var mx_trilerp_1 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, v4_immutable, v5_immutable, v6_immutable, v7_immutable, s_immutable, t_immutable, r_immutable ] ) => {

		var r = ShaderNode.float( r_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v7 = ShaderNode.vec3( v7_immutable ).toVar();
		var v6 = ShaderNode.vec3( v6_immutable ).toVar();
		var v5 = ShaderNode.vec3( v5_immutable ).toVar();
		var v4 = ShaderNode.vec3( v4_immutable ).toVar();
		var v3 = ShaderNode.vec3( v3_immutable ).toVar();
		var v2 = ShaderNode.vec3( v2_immutable ).toVar();
		var v1 = ShaderNode.vec3( v1_immutable ).toVar();
		var v0 = ShaderNode.vec3( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();
		var t1 = ShaderNode.float( OperatorNode.sub( 1.0, t ) ).toVar();
		var r1 = ShaderNode.float( OperatorNode.sub( 1.0, r ) ).toVar();

		return r1.mul( t1.mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) ) ).add( r.mul( t1.mul( v4.mul( s1 ).add( v5.mul( s ) ) ).add( t.mul( v6.mul( s1 ).add( v7.mul( s ) ) ) ) ) );

	} );

	static var mx_trilerp = FunctionOverloadingNode.overloadingFn( [ mx_trilerp_0, mx_trilerp_1 ] );

	static var mx_gradient_float_0 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable ] ) => {

		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uint( hash_immutable ).toVar();
		var h = ShaderNode.uint( hash.bitAnd( ShaderNode.uint( 7 ) ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), x, y ) ).toVar();
		var v = ShaderNode.float( OperatorNode.mul( 2.0, MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), y, x ) ) ).toVar();

		return MXNoise.mx_negate_if( u, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 1 ) ) ) ).add( MXNoise.mx_negate_if( v, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 2 ) ) ) ) );

	} );

	static var mx_gradient_float_1 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.float( z_immutable ).toVar();
		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uint( hash_immutable ).toVar();
		var h = ShaderNode.uint( hash.bitAnd( ShaderNode.uint( 15 ) ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 8 ) ), x, y ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), y, MXNoise.mx_select( h.equal( ShaderNode.uint( 12 ) ).or( h.equal( ShaderNode.uint( 14 ) ) ), x, z ) ) ).toVar();

		return MXNoise.mx_negate_if( u, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 1 ) ) ) ).add( MXNoise.mx_negate_if( v, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 2 ) ) ) ) );

	} );

	static var mx_gradient_float = FunctionOverloadingNode.overloadingFn( [ mx_gradient_float_0, mx_gradient_float_1 ] );

	static var mx_gradient_vec3_0 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable ] ) => {

		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uvec3( hash_immutable ).toVar();

		return ShaderNode.vec3( MXNoise.mx_gradient_float( hash.x, x, y ), MXNoise.mx_gradient_float( hash.y, x, y ), MXNoise.mx_gradient_float( hash.z, x, y ) );

	} );

	static var mx_gradient_vec3_1 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.float( z_immutable ).toVar();
		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uvec3( hash_immutable ).toVar();

		return ShaderNode.vec3( MXNoise.mx_gradient_float( hash.x, x, y, z ), MXNoise.mx_gradient_float( hash.y, x, y, z ), MXNoise.mx_gradient_float( hash.z, x, y, z ) );

	} );

	static var mx_gradient_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_gradient_vec3_0, mx_gradient_vec3_1 ] );

	static var mx_gradient_scale2d_0 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.float( v_immutable ).toVar();

		return OperatorNode.mul( 0.6616, v );

	} );

	static var mx_gradient_scale3d_0 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.float( v_immutable ).toVar();

		return OperatorNode.mul( 0.9820, v );

	} );

	static var mx_gradient_scale2d_1 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.vec3( v_immutable ).toVar();

		return OperatorNode.mul( 0.6616, v );

	} );

	static var mx_gradient_scale2d = FunctionOverloadingNode.overloadingFn( [ mx_gradient_scale2d_0, mx_gradient_scale2d_1 ] );

	static var mx_gradient_scale3d_1 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.vec3( v_immutable ).toVar();

		return OperatorNode.mul( 0.9820, v );

	} );

	static var mx_gradient_scale3d = FunctionOverloadingNode.overloadingFn( [ mx_gradient_scale3d_0, mx_gradient_scale3d_1 ] );

	static var mx_rotl32 = ShaderNode.tslFn( ( [ x_immutable, k_immutable ] ) => {

		var k = ShaderNode.int( k_immutable ).toVar();
		var x = ShaderNode.uint( x_immutable ).toVar();

		return x.shiftLeft( k ).bitOr( x.shiftRight( ShaderNode.int( 32 ).sub( k ) ) );

	} );

	static var mx_bjmix = ShaderNode.tslFn( ( [ a, b, c ] ) => {

		a.subAssign( c );
		a.bitXorAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 4 ) ) );
		c.addAssign( b );
		b.subAssign( a );
		b.bitXorAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 6 ) ) );
		a.addAssign( c );
		c.subAssign( b );
		c.bitXorAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 8 ) ) );
		b.addAssign( a );
		a.subAssign( c );
		a.bitXorAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 16 ) ) );
		c.addAssign( b );
		b.subAssign( a );
		b.bitXorAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 19 ) ) );
		a.addAssign( c );
		c.subAssign( b );
		c.bitXorAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 4 ) ) );
		b.addAssign( a );

	} );

	static var mx_bjfinal = ShaderNode.tslFn( ( [ a_immutable, b_immutable, c_immutable ] ) => {

		var c = ShaderNode.uint( c_immutable ).toVar();
		var b = ShaderNode.uint( b_immutable ).toVar();
		var a = ShaderNode.uint( a_immutable ).toVar();
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 14 ) ) );
		a.bitXorAssign( c );
		a.subAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 11 ) ) );
		b.bitXorAssign( a );
		b.subAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 25 ) ) );
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 16 ) ) );
		a.bitXorAssign( c );
		a.subAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 4 ) ) );
		b.bitXorAssign( a );
		b.subAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 14 ) ) );
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 24 ) ) );

		return c;

	} );

	static var mx_bits_to_01 = ShaderNode.tslFn( ( [ bits_immutable ] ) => {

		var bits = ShaderNode.uint( bits_immutable ).toVar();

		return ShaderNode.float( bits ).div( ShaderNode.float( ShaderNode.uint( ShaderNode.int( 0xffffffff ) ) ) );

	} );

	static var mx_fade = ShaderNode.tslFn( ( [ t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();

		return t.mul( t.mul( t.mul( t.mul( t.mul( 6.0 ).sub( 15.0 ) ).add( 10.0 ) ) ) );

	} );

	static var mx_hash_int_0 = ShaderNode.tslFn( ( [ x_immutable ] ) => {

		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 1 ) ).toVar();
		var seed = ShaderNode.uint( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ).toVar();

		return MXNoise.mx_bjfinal( seed.add( ShaderNode.uint( x ) ), seed, seed );

	} );

	static var mx_hash_int_1 = ShaderNode.tslFn( ( [ x_immutable, y_immutable ] ) => {

		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 2 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_2 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 3 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_3 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable, xx_immutable ] ) => {

		var xx = ShaderNode.int( xx_immutable ).toVar();
		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 4 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );
		MXNoise.mx_bjmix( a, b, c );
		a.addAssign( ShaderNode.uint( xx ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_4 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable, xx_immutable, yy_immutable ] ) => {

		var yy = ShaderNode.int( yy_immutable ).toVar();
		var xx = ShaderNode.int( xx_immutable ).toVar();
		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 5 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );
		MXNoise.mx_bjmix( a, b, c );
		a.addAssign( ShaderNode.uint( xx ) );
		b.addAssign( ShaderNode.uint( yy ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int = FunctionOverloadingNode.overloadingFn( [ mx_hash_int_0, mx_hash_int_1, mx_hash_int_2, mx_hash_int_3, mx_hash_int_4 ] );

	static var mx_hash_vec3_0 = ShaderNode.tslFn( ( [ x_immutable, y_immutable ] ) => {

		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var h = ShaderNode.uint( MXNoise.mx_hash_int( x, y ) ).toVar();
		var result = ShaderNode.uvec3().toVar();
		result.x.assign( h.bitAnd( ShaderNode.int( 0xFF ) ) );
		result.y.assign( h.shiftRight( ShaderNode.int( 8 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );
		result.z.assign( h.shiftRight( ShaderNode.int( 16 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );

		return result;

	} );

	static var mx_hash_vec3_1 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var h = ShaderNode.uint( MXNoise.mx_hash_int( x, y, z ) ).toVar();
		var result = ShaderNode.uvec3().toVar();
		result.x.assign( h.bitAnd( ShaderNode.int( 0xFF ) ) );
		result.y.assign( h.shiftRight( ShaderNode.int( 8 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );
		result.z.assign( h.shiftRight( ShaderNode.int( 16 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );

		return result;

	} );

	static var mx_hash_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_hash_vec3_0, mx_hash_vec3_1 ] );

	static var mx_perlin_noise_float_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec2( p_immutable ).toVar();
		var X = ShaderNode.int().toVar(), Y = ShaderNode.int().toVar();
		var fx = ShaderNode.float( MXNoise.mx_floorfrac( p.x, X ) ).toVar();
		var fy = ShaderNode.float( MXNoise.mx_floorfrac( p.y, Y ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_fade( fx ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_fade( fy ) ).toVar();
		var result = ShaderNode.float( MXNoise.mx_bilerp( MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y ), fx, fy ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y ), fx.sub( 1.0 ), fy ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y.add( ShaderNode.int( 1 ) ) ), fx, fy.sub( 1.0 ) ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy.sub( 1.0 ) ), u, v ) ).toVar();

		return MXNoise.mx_gradient_scale2d( result );

	} );

	static var mx_perlin_noise_float_1 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec3( p_immutable ).toVar();
		var X = ShaderNode.int().toVar(), Y = ShaderNode.int().toVar(), Z = ShaderNode.int().toVar();
		var fx = ShaderNode.float( MXNoise.mx_floorfrac( p.x, X ) ).toVar();
		var fy = ShaderNode.float( MXNoise.mx_floorfrac( p.y, Y ) ).toVar();
		var fz = ShaderNode.float( MXNoise.mx_floorfrac( p.z, Z ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_fade( fx ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_fade( fy ) ).toVar();
		var w = ShaderNode.float( MXNoise.mx_fade( fz ) ).toVar();
		var result = ShaderNode.vec3( MXNoise.mx_trilerp( MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y, Z ), fx, fy, fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y, Z ), fx.sub( 1.0 ), fy, fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y.add( ShaderNode.int( 1 ) ), Z ), fx, fy.sub( 1.0 ), fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ), Z ), fx.sub( 1.0 ), fy.sub( 1.0 ), fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y, Z.add( ShaderNode.int( 1 ) ) ), fx, fy, fz.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y, Z.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy, fz.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y.add( ShaderNode.int( 1 ) ), Z.add( ShaderNode.int( 1 ) ) ), fx, fy.sub( 1.0 ), fz.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ), Z.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy.sub( 1.0 ), fz.sub( 1.0 ) ), u, v, w ) ).toVar();

		return MXNoise.mx_gradient_scale3d( result );

	} );

	static var mx_perlin_noise_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_perlin_noise_vec3_0, mx_perlin_noise_vec3_1 ] );

	static var mx_cell_noise_float_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.float( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix ) );

	} );

	static var mx_cell_noise_float_1 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec2( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p.x ) ).toVar();
		var iy = ShaderNode.int( MXNoise.mx_floor( p.y ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, iy ) );

	} );

	static var mx_cell_noise_float_2 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec3( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p.x ) ).toVar();
		var iy = ShaderNode.int( MXNoise.mx_floor( p.y ) ).toVar();
		var iz = ShaderNode.int( MXNoise.mx_floor( p.z ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, iy, iz ) );

	} );

	static var mx_cell_noise_float_3 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec4( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p.x ) ).toVar();
		var iy = ShaderNode.int( MXNoise.mx_floor( p.y ) ).toVar();
		var iz = ShaderNode.int( MXNoise.mx_floor( p.z ) ).toVar();
		var iw = ShaderNode.int( MXNoise.mx_floor( p.w ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, iy, iz, iw ) );

	} );

	static var mx_cell_noise_float = FunctionOverloadingNode.overloadingFn( [ mx_cell_noise_float_0, mx_cell_noise_float_1, mx_cell_noise_float_2, mx_cell_noise_float_3 ] );

	static var mx_cell_noise_vec3_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.float( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p ) ).toVar();

		return ShaderNode.vec3( MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, ShaderNode.
// Three.js Transpiler
// https://raw.githubusercontent.com/AcademySoftwareFoundation/MaterialX/main/libraries/stdlib/genglsl/lib/mx_noise.glsl

import shadernode.ShaderNode;
import math.CondNode;
import math.OperatorNode;
import math.MathNode;
import utils.FunctionOverloadingNode;
import utils.LoopNode;

class MXNoise {

	static var mx_select = ShaderNode.tslFn( ( [ b_immutable, t_immutable, f_immutable ] ) => {

		var f = ShaderNode.float( f_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var b = ShaderNode.bool( b_immutable ).toVar();

		return CondNode.cond( b, t, f );

	} );

	static var mx_negate_if = ShaderNode.tslFn( ( [ val_immutable, b_immutable ] ) => {

		var b = ShaderNode.bool( b_immutable ).toVar();
		var val = ShaderNode.float( val_immutable ).toVar();

		return CondNode.cond( b, val.negate(), val );

	} );

	static var mx_floor = ShaderNode.tslFn( ( [ x_immutable ] ) => {

		var x = ShaderNode.float( x_immutable ).toVar();

		return ShaderNode.int( MathNode.floor( x ) );

	} );

	static var mx_floorfrac = ShaderNode.tslFn( ( [ x_immutable, i ] ) => {

		var x = ShaderNode.float( x_immutable ).toVar();
		i.assign( MXNoise.mx_floor( x ) );

		return x.sub( ShaderNode.float( i ) );

	} );

	static var mx_bilerp_0 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, s_immutable, t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v3 = ShaderNode.float( v3_immutable ).toVar();
		var v2 = ShaderNode.float( v2_immutable ).toVar();
		var v1 = ShaderNode.float( v1_immutable ).toVar();
		var v0 = ShaderNode.float( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();

		return OperatorNode.sub( 1.0, t ).mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) );

	} );

	static var mx_bilerp_1 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, s_immutable, t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v3 = ShaderNode.vec3( v3_immutable ).toVar();
		var v2 = ShaderNode.vec3( v2_immutable ).toVar();
		var v1 = ShaderNode.vec3( v1_immutable ).toVar();
		var v0 = ShaderNode.vec3( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();

		return OperatorNode.sub( 1.0, t ).mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) );

	} );

	static var mx_bilerp = FunctionOverloadingNode.overloadingFn( [ mx_bilerp_0, mx_bilerp_1 ] );

	static var mx_trilerp_0 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, v4_immutable, v5_immutable, v6_immutable, v7_immutable, s_immutable, t_immutable, r_immutable ] ) => {

		var r = ShaderNode.float( r_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v7 = ShaderNode.float( v7_immutable ).toVar();
		var v6 = ShaderNode.float( v6_immutable ).toVar();
		var v5 = ShaderNode.float( v5_immutable ).toVar();
		var v4 = ShaderNode.float( v4_immutable ).toVar();
		var v3 = ShaderNode.float( v3_immutable ).toVar();
		var v2 = ShaderNode.float( v2_immutable ).toVar();
		var v1 = ShaderNode.float( v1_immutable ).toVar();
		var v0 = ShaderNode.float( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();
		var t1 = ShaderNode.float( OperatorNode.sub( 1.0, t ) ).toVar();
		var r1 = ShaderNode.float( OperatorNode.sub( 1.0, r ) ).toVar();

		return r1.mul( t1.mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) ) ).add( r.mul( t1.mul( v4.mul( s1 ).add( v5.mul( s ) ) ).add( t.mul( v6.mul( s1 ).add( v7.mul( s ) ) ) ) ) );

	} );

	static var mx_trilerp_1 = ShaderNode.tslFn( ( [ v0_immutable, v1_immutable, v2_immutable, v3_immutable, v4_immutable, v5_immutable, v6_immutable, v7_immutable, s_immutable, t_immutable, r_immutable ] ) => {

		var r = ShaderNode.float( r_immutable ).toVar();
		var t = ShaderNode.float( t_immutable ).toVar();
		var s = ShaderNode.float( s_immutable ).toVar();
		var v7 = ShaderNode.vec3( v7_immutable ).toVar();
		var v6 = ShaderNode.vec3( v6_immutable ).toVar();
		var v5 = ShaderNode.vec3( v5_immutable ).toVar();
		var v4 = ShaderNode.vec3( v4_immutable ).toVar();
		var v3 = ShaderNode.vec3( v3_immutable ).toVar();
		var v2 = ShaderNode.vec3( v2_immutable ).toVar();
		var v1 = ShaderNode.vec3( v1_immutable ).toVar();
		var v0 = ShaderNode.vec3( v0_immutable ).toVar();
		var s1 = ShaderNode.float( OperatorNode.sub( 1.0, s ) ).toVar();
		var t1 = ShaderNode.float( OperatorNode.sub( 1.0, t ) ).toVar();
		var r1 = ShaderNode.float( OperatorNode.sub( 1.0, r ) ).toVar();

		return r1.mul( t1.mul( v0.mul( s1 ).add( v1.mul( s ) ) ).add( t.mul( v2.mul( s1 ).add( v3.mul( s ) ) ) ) ).add( r.mul( t1.mul( v4.mul( s1 ).add( v5.mul( s ) ) ).add( t.mul( v6.mul( s1 ).add( v7.mul( s ) ) ) ) ) );

	} );

	static var mx_trilerp = FunctionOverloadingNode.overloadingFn( [ mx_trilerp_0, mx_trilerp_1 ] );

	static var mx_gradient_float_0 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable ] ) => {

		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uint( hash_immutable ).toVar();
		var h = ShaderNode.uint( hash.bitAnd( ShaderNode.uint( 7 ) ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), x, y ) ).toVar();
		var v = ShaderNode.float( OperatorNode.mul( 2.0, MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), y, x ) ) ).toVar();

		return MXNoise.mx_negate_if( u, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 1 ) ) ) ).add( MXNoise.mx_negate_if( v, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 2 ) ) ) ) );

	} );

	static var mx_gradient_float_1 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.float( z_immutable ).toVar();
		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uint( hash_immutable ).toVar();
		var h = ShaderNode.uint( hash.bitAnd( ShaderNode.uint( 15 ) ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 8 ) ), x, y ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_select( h.lessThan( ShaderNode.uint( 4 ) ), y, MXNoise.mx_select( h.equal( ShaderNode.uint( 12 ) ).or( h.equal( ShaderNode.uint( 14 ) ) ), x, z ) ) ).toVar();

		return MXNoise.mx_negate_if( u, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 1 ) ) ) ).add( MXNoise.mx_negate_if( v, ShaderNode.bool( h.bitAnd( ShaderNode.uint( 2 ) ) ) ) );

	} );

	static var mx_gradient_float = FunctionOverloadingNode.overloadingFn( [ mx_gradient_float_0, mx_gradient_float_1 ] );

	static var mx_gradient_vec3_0 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable ] ) => {

		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uvec3( hash_immutable ).toVar();

		return ShaderNode.vec3( MXNoise.mx_gradient_float( hash.x, x, y ), MXNoise.mx_gradient_float( hash.y, x, y ), MXNoise.mx_gradient_float( hash.z, x, y ) );

	} );

	static var mx_gradient_vec3_1 = ShaderNode.tslFn( ( [ hash_immutable, x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.float( z_immutable ).toVar();
		var y = ShaderNode.float( y_immutable ).toVar();
		var x = ShaderNode.float( x_immutable ).toVar();
		var hash = ShaderNode.uvec3( hash_immutable ).toVar();

		return ShaderNode.vec3( MXNoise.mx_gradient_float( hash.x, x, y, z ), MXNoise.mx_gradient_float( hash.y, x, y, z ), MXNoise.mx_gradient_float( hash.z, x, y, z ) );

	} );

	static var mx_gradient_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_gradient_vec3_0, mx_gradient_vec3_1 ] );

	static var mx_gradient_scale2d_0 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.float( v_immutable ).toVar();

		return OperatorNode.mul( 0.6616, v );

	} );

	static var mx_gradient_scale3d_0 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.float( v_immutable ).toVar();

		return OperatorNode.mul( 0.9820, v );

	} );

	static var mx_gradient_scale2d_1 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.vec3( v_immutable ).toVar();

		return OperatorNode.mul( 0.6616, v );

	} );

	static var mx_gradient_scale2d = FunctionOverloadingNode.overloadingFn( [ mx_gradient_scale2d_0, mx_gradient_scale2d_1 ] );

	static var mx_gradient_scale3d_1 = ShaderNode.tslFn( ( [ v_immutable ] ) => {

		var v = ShaderNode.vec3( v_immutable ).toVar();

		return OperatorNode.mul( 0.9820, v );

	} );

	static var mx_gradient_scale3d = FunctionOverloadingNode.overloadingFn( [ mx_gradient_scale3d_0, mx_gradient_scale3d_1 ] );

	static var mx_rotl32 = ShaderNode.tslFn( ( [ x_immutable, k_immutable ] ) => {

		var k = ShaderNode.int( k_immutable ).toVar();
		var x = ShaderNode.uint( x_immutable ).toVar();

		return x.shiftLeft( k ).bitOr( x.shiftRight( ShaderNode.int( 32 ).sub( k ) ) );

	} );

	static var mx_bjmix = ShaderNode.tslFn( ( [ a, b, c ] ) => {

		a.subAssign( c );
		a.bitXorAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 4 ) ) );
		c.addAssign( b );
		b.subAssign( a );
		b.bitXorAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 6 ) ) );
		a.addAssign( c );
		c.subAssign( b );
		c.bitXorAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 8 ) ) );
		b.addAssign( a );
		a.subAssign( c );
		a.bitXorAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 16 ) ) );
		c.addAssign( b );
		b.subAssign( a );
		b.bitXorAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 19 ) ) );
		a.addAssign( c );
		c.subAssign( b );
		c.bitXorAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 4 ) ) );
		b.addAssign( a );

	} );

	static var mx_bjfinal = ShaderNode.tslFn( ( [ a_immutable, b_immutable, c_immutable ] ) => {

		var c = ShaderNode.uint( c_immutable ).toVar();
		var b = ShaderNode.uint( b_immutable ).toVar();
		var a = ShaderNode.uint( a_immutable ).toVar();
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 14 ) ) );
		a.bitXorAssign( c );
		a.subAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 11 ) ) );
		b.bitXorAssign( a );
		b.subAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 25 ) ) );
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 16 ) ) );
		a.bitXorAssign( c );
		a.subAssign( MXNoise.mx_rotl32( c, ShaderNode.int( 4 ) ) );
		b.bitXorAssign( a );
		b.subAssign( MXNoise.mx_rotl32( a, ShaderNode.int( 14 ) ) );
		c.bitXorAssign( b );
		c.subAssign( MXNoise.mx_rotl32( b, ShaderNode.int( 24 ) ) );

		return c;

	} );

	static var mx_bits_to_01 = ShaderNode.tslFn( ( [ bits_immutable ] ) => {

		var bits = ShaderNode.uint( bits_immutable ).toVar();

		return ShaderNode.float( bits ).div( ShaderNode.float( ShaderNode.uint( ShaderNode.int( 0xffffffff ) ) ) );

	} );

	static var mx_fade = ShaderNode.tslFn( ( [ t_immutable ] ) => {

		var t = ShaderNode.float( t_immutable ).toVar();

		return t.mul( t.mul( t.mul( t.mul( t.mul( 6.0 ).sub( 15.0 ) ).add( 10.0 ) ) ) );

	} );

	static var mx_hash_int_0 = ShaderNode.tslFn( ( [ x_immutable ] ) => {

		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 1 ) ).toVar();
		var seed = ShaderNode.uint( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ).toVar();

		return MXNoise.mx_bjfinal( seed.add( ShaderNode.uint( x ) ), seed, seed );

	} );

	static var mx_hash_int_1 = ShaderNode.tslFn( ( [ x_immutable, y_immutable ] ) => {

		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 2 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_2 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 3 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_3 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable, xx_immutable ] ) => {

		var xx = ShaderNode.int( xx_immutable ).toVar();
		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 4 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );
		MXNoise.mx_bjmix( a, b, c );
		a.addAssign( ShaderNode.uint( xx ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int_4 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable, xx_immutable, yy_immutable ] ) => {

		var yy = ShaderNode.int( yy_immutable ).toVar();
		var xx = ShaderNode.int( xx_immutable ).toVar();
		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var len = ShaderNode.uint( ShaderNode.uint( 5 ) ).toVar();
		var a = ShaderNode.uint().toVar(), b = ShaderNode.uint().toVar(), c = ShaderNode.uint().toVar();
		a.assign( b.assign( c.assign( ShaderNode.uint( ShaderNode.int( 0xdeadbeef ) ).add( len.shiftLeft( ShaderNode.uint( 2 ) ).add( ShaderNode.uint( 13 ) ) ) ) ) );
		a.addAssign( ShaderNode.uint( x ) );
		b.addAssign( ShaderNode.uint( y ) );
		c.addAssign( ShaderNode.uint( z ) );
		MXNoise.mx_bjmix( a, b, c );
		a.addAssign( ShaderNode.uint( xx ) );
		b.addAssign( ShaderNode.uint( yy ) );

		return MXNoise.mx_bjfinal( a, b, c );

	} );

	static var mx_hash_int = FunctionOverloadingNode.overloadingFn( [ mx_hash_int_0, mx_hash_int_1, mx_hash_int_2, mx_hash_int_3, mx_hash_int_4 ] );

	static var mx_hash_vec3_0 = ShaderNode.tslFn( ( [ x_immutable, y_immutable ] ) => {

		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var h = ShaderNode.uint( MXNoise.mx_hash_int( x, y ) ).toVar();
		var result = ShaderNode.uvec3().toVar();
		result.x.assign( h.bitAnd( ShaderNode.int( 0xFF ) ) );
		result.y.assign( h.shiftRight( ShaderNode.int( 8 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );
		result.z.assign( h.shiftRight( ShaderNode.int( 16 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );

		return result;

	} );

	static var mx_hash_vec3_1 = ShaderNode.tslFn( ( [ x_immutable, y_immutable, z_immutable ] ) => {

		var z = ShaderNode.int( z_immutable ).toVar();
		var y = ShaderNode.int( y_immutable ).toVar();
		var x = ShaderNode.int( x_immutable ).toVar();
		var h = ShaderNode.uint( MXNoise.mx_hash_int( x, y, z ) ).toVar();
		var result = ShaderNode.uvec3().toVar();
		result.x.assign( h.bitAnd( ShaderNode.int( 0xFF ) ) );
		result.y.assign( h.shiftRight( ShaderNode.int( 8 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );
		result.z.assign( h.shiftRight( ShaderNode.int( 16 ) ).bitAnd( ShaderNode.int( 0xFF ) ) );

		return result;

	} );

	static var mx_hash_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_hash_vec3_0, mx_hash_vec3_1 ] );

	static var mx_perlin_noise_float_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec2( p_immutable ).toVar();
		var X = ShaderNode.int().toVar(), Y = ShaderNode.int().toVar();
		var fx = ShaderNode.float( MXNoise.mx_floorfrac( p.x, X ) ).toVar();
		var fy = ShaderNode.float( MXNoise.mx_floorfrac( p.y, Y ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_fade( fx ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_fade( fy ) ).toVar();
		var result = ShaderNode.float( MXNoise.mx_bilerp( MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y ), fx, fy ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y ), fx.sub( 1.0 ), fy ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X, Y.add( ShaderNode.int( 1 ) ) ), fx, fy.sub( 1.0 ) ), MXNoise.mx_gradient_float( MXNoise.mx_hash_int( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy.sub( 1.0 ) ), u, v ) ).toVar();

		return MXNoise.mx_gradient_scale2d( result );

	} );

	static var mx_perlin_noise_float_1 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec3( p_immutable ).toVar();
		var X = ShaderNode.int().toVar(), Y = ShaderNode.int().toVar(), Z = ShaderNode.int().toVar();
		var fx = ShaderNode.float( MXNoise.mx_floorfrac( p.x, X ) ).toVar();
		var fy = ShaderNode.float( MXNoise.mx_floorfrac( p.y, Y ) ).toVar();
		var fz = ShaderNode.float( MXNoise.mx_floorfrac( p.z, Z ) ).toVar();
		var u = ShaderNode.float( MXNoise.mx_fade( fx ) ).toVar();
		var v = ShaderNode.float( MXNoise.mx_fade( fy ) ).toVar();
		var w = ShaderNode.float( MXNoise.mx_fade( fz ) ).toVar();
		var result = ShaderNode.vec3( MXNoise.mx_trilerp( MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y, Z ), fx, fy, fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y, Z ), fx.sub( 1.0 ), fy, fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y.add( ShaderNode.int( 1 ) ), Z ), fx, fy.sub( 1.0 ), fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ), Z ), fx.sub( 1.0 ), fy.sub( 1.0 ), fz ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y, Z.add( ShaderNode.int( 1 ) ) ), fx, fy, fz.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y, Z.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy, fz.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X, Y.add( ShaderNode.int( 1 ) ), Z.add( ShaderNode.int( 1 ) ) ), fx, fy.sub( 1.0 ), fz.sub( 1.0 ) ), MXNoise.mx_gradient_vec3( MXNoise.mx_hash_vec3( X.add( ShaderNode.int( 1 ) ), Y.add( ShaderNode.int( 1 ) ), Z.add( ShaderNode.int( 1 ) ) ), fx.sub( 1.0 ), fy.sub( 1.0 ), fz.sub( 1.0 ) ), u, v, w ) ).toVar();

		return MXNoise.mx_gradient_scale3d( result );

	} );

	static var mx_perlin_noise_vec3 = FunctionOverloadingNode.overloadingFn( [ mx_perlin_noise_vec3_0, mx_perlin_noise_vec3_1 ] );

	static var mx_cell_noise_float_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.float( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix ) );

	} );

	static var mx_cell_noise_float_1 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec2( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p.x ) ).toVar();
		var iy = ShaderNode.int( MXNoise.mx_floor( p.y ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, iy ) );

	} );

	static var mx_cell_noise_float_2 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec3( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p.x ) ).toVar();
		var iy = ShaderNode.int( MXNoise.mx_floor( p.y ) ).toVar();
		var iz = ShaderNode.int( MXNoise.mx_floor( p.z ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, iy, iz ) );

	} );

	static var mx_cell_noise_float_3 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.vec4( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p.x ) ).toVar();
		var iy = ShaderNode.int( MXNoise.mx_floor( p.y ) ).toVar();
		var iz = ShaderNode.int( MXNoise.mx_floor( p.z ) ).toVar();
		var iw = ShaderNode.int( MXNoise.mx_floor( p.w ) ).toVar();

		return MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, iy, iz, iw ) );

	} );

	static var mx_cell_noise_float = FunctionOverloadingNode.overloadingFn( [ mx_cell_noise_float_0, mx_cell_noise_float_1, mx_cell_noise_float_2, mx_cell_noise_float_3 ] );

	static var mx_cell_noise_vec3_0 = ShaderNode.tslFn( ( [ p_immutable ] ) => {

		var p = ShaderNode.float( p_immutable ).toVar();
		var ix = ShaderNode.int( MXNoise.mx_floor( p ) ).toVar();

		return ShaderNode.vec3( MXNoise.mx_bits_to_01( MXNoise.mx_hash_int( ix, ShaderNode.