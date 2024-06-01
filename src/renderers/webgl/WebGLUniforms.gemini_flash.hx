import three.textures.CubeTexture;
import three.textures.Texture;
import three.textures.DataArrayTexture;
import three.textures.Data3DTexture;
import three.textures.DepthTexture;
import three.constants.LessEqualCompare;
import js.lib.Float32Array;
import js.lib.Int32Array;
import three.math.Matrix4;
import three.math.Matrix3;
import three.math.Matrix2;
import three.core.Vector4;
import three.core.Vector3;
import three.core.Vector2;

/**
 * Uniforms of a program.
 * Those form a tree structure with a special top-level container for the root,
 * which you get by calling 'new WebGLUniforms( gl, program )'.
 *
 *
 * Properties of inner nodes including the top-level container:
 *
 * .seq - array of nested uniforms
 * .map - nested uniforms by name
 *
 *
 * Methods of all nodes except the top-level container:
 *
 * .setValue( gl, value, [textures] )
 *
 * 		uploads a uniform value(s)
 *  	the 'textures' parameter is needed for sampler uniforms
 *
 *
 * Static methods of the top-level container (textures factorizations):
 *
 * .upload( gl, seq, values, textures )
 *
 * 		sets uniforms in 'seq' to 'values[id].value'
 *
 * .seqWithValue( seq, values ) : filteredSeq
 *
 * 		filters 'seq' entries with corresponding entry in values
 *
 *
 * Methods of the top-level container (textures factorizations):
 *
 * .setValue( gl, name, value, textures )
 *
 * 		sets uniform with  name 'name' to 'value'
 *
 * .setOptional( gl, obj, prop )
 *
 * 		like .set for an optional property of the object
 *
 */

class WebGLUniforms {

	public var seq : Array<IUniform>;
	public var map : Map<String, IUniform>;
	
	public function new( gl : WebGLRenderingContext, program : WebGLProgram ) {
		
		this.seq = [];
		this.map = new Map();

		var n = gl.getProgramParameter( program, gl.ACTIVE_UNIFORMS );

		for ( i in 0...n ) {

			var info = gl.getActiveUniform( program, i );
			var addr = gl.getUniformLocation( program, info.name );

			parseUniform( info, addr, this );

		}

	}
	
	public function setValue( gl : WebGLRenderingContext, name : String, value : Dynamic, textures : WebGLTextures ) : Void {

		var u = this.map.get( name );

		if ( u != null ) u.setValue( gl, value, textures );

	}

	public function setOptional( gl : WebGLRenderingContext, object : Dynamic, name : String ) : Void {

		if ( Reflect.hasField( object, name ) ) this.setValue( gl, name, Reflect.field( object, name ) );

	}

	public static function upload( gl : WebGLRenderingContext, seq : Array<IUniform>, values : Dynamic, textures : WebGLTextures ) : Void {

		for ( i in 0...seq.length ) {

			var u = seq[ i ];
			
			if( ! Reflect.hasField( values, u.id ) ) {
				continue;
			}
			
			var v = Reflect.field( values, u.id );
			
			if (  ( Reflect.hasField( v, "needsUpdate" ) && v.needsUpdate != false) || ! Reflect.hasField( v, "needsUpdate" )  ) {
				// note: always updating when .needsUpdate is undefined
				u.setValue( gl, v.value, textures );
			}

		}

	}

	public static function seqWithValue( seq : Array<IUniform>, values : Dynamic ) : Array<IUniform> {

		var r = [];

		for ( i in 0...seq.length ) {

			var u = seq[ i ];
			if ( Reflect.hasField( values, u.id ) ) r.push( u );

		}

		return r;

	}

}

interface IUniform {
	
	var id : String;
	
	function setValue( gl : WebGLRenderingContext, value : Dynamic, textures : WebGLTextures ) : Void;
	
}

class SingleUniform implements IUniform {

	public var id(default, null) : String;
	var addr : WebGLUniformLocation;
	var cache : Array<Dynamic>;
	var type : Int;
	public var setValue : ( gl : WebGLRenderingContext, value : Dynamic, textures : WebGLTextures ) -> Void;

	public function new( id : String, activeInfo : Dynamic, addr : WebGLUniformLocation ) {

		this.id = id;
		this.addr = addr;
		this.cache = [];
		this.type = activeInfo.type;
		this.setValue = getSingularSetter( activeInfo.type );

		// this.path = activeInfo.name; // DEBUG

	}

}

class PureArrayUniform implements IUniform {

	public var id(default, null) : String;
	var addr : WebGLUniformLocation;
	var cache : Array<Dynamic>;
	var type : Int;
	var size : Int;
	public var setValue : ( gl : WebGLRenderingContext, value : Dynamic, textures : WebGLTextures ) -> Void;

	public function new( id : String, activeInfo : Dynamic, addr : WebGLUniformLocation ) {

		this.id = id;
		this.addr = addr;
		this.cache = [];
		this.type = activeInfo.type;
		this.size = activeInfo.size;
		this.setValue = getPureArraySetter( activeInfo.type );

		// this.path = activeInfo.name; // DEBUG

	}

}

class StructuredUniform implements IUniform {

	public var id(default, null) : String;
	var seq : Array<IUniform>;
	var map : Map<String, IUniform>;

	public function new( id : String ) {

		this.id = id;

		this.seq = [];
		this.map = new Map();

	}

	public function setValue( gl : WebGLRenderingContext, value : Dynamic, textures : WebGLTextures ) : Void {
		
		if( value == null ) {
			return;
		}

		for ( i in 0...this.seq.length ) {

			var u = this.seq[ i ];
			
			if( ! Reflect.hasField( value, u.id ) ) {
				continue;
			}
			
			u.setValue( gl, Reflect.field( value, u.id ), textures );

		}

	}

}


// --- Utilities ---

// Array Caches (provide typed arrays for temporary by size)

var arrayCacheF32 = new Map<Int, Float32Array>();
var arrayCacheI32 = new Map<Int, Int32Array>();

// Float32Array caches used for uploading Matrix uniforms

var mat4array = new Float32Array( 16 );
var mat3array = new Float32Array( 9 );
var mat2array = new Float32Array( 4 );

// Flattening for arrays of vectors and matrices

function flatten( array : Array<Dynamic>, nBlocks : Int, blockSize : Int ) : Float32Array {
	
	if( array.length == 0 ) {
		return new Float32Array(0);
	}

	var firstElem = array[ 0 ];

	if ( firstElem <= 0 || firstElem > 0 ) return new Float32Array(array);
	// unoptimized: ! isNaN( firstElem )
	// see http://jacksondunstan.com/articles/983

	var n = nBlocks * blockSize;
	
	var r  = arrayCacheF32.get( n );

	if ( r == null ) {

		r = new Float32Array( n );
		arrayCacheF32.set( n, r );

	}

	if ( nBlocks != 0 ) {
		
		if( Std.isOfType( firstElem, Vector2 ) ) {
			(cast firstElem:Vector2).toArray( r, 0 );
		} else if( Std.isOfType( firstElem, Vector3 ) ) {
			(cast firstElem:Vector3).toArray( r, 0 );
		} else if( Std.isOfType( firstElem, Vector4 ) ) {
			(cast firstElem:Vector4).toArray( r, 0 );
		} else if( Std.isOfType( firstElem, Matrix4 ) ) {
			(cast firstElem:Matrix4).toArray( r, 0 );
		} else if( Std.isOfType( firstElem, Matrix3 ) ) {
			(cast firstElem:Matrix3).toArray( r, 0 );
		} else if( Std.isOfType( firstElem, Matrix2 ) ) {
			(cast firstElem:Matrix2).toArray( r, 0 );
		} else {
			r.set( array, 0 );
		}

		for ( i in 1...nBlocks ) {

			var offset = i * blockSize;
			
			if( Std.isOfType( array[i], Vector2 ) ) {
				(cast array[i]:Vector2).toArray( r, offset );
			} else if( Std.isOfType( array[i], Vector3 ) ) {
				(cast array[i]:Vector3).toArray( r, offset );
			} else if( Std.isOfType( array[i], Vector4 ) ) {
				(cast array[i]:Vector4).toArray( r, offset );
			} else if( Std.isOfType( array[i], Matrix4 ) ) {
				(cast array[i]:Matrix4).toArray( r, offset );
			} else if( Std.isOfType( array[i], Matrix3 ) ) {
				(cast array[i]:Matrix3).toArray( r, offset );
			} else if( Std.isOfType( array[i], Matrix2 ) ) {
				(cast array[i]:Matrix2).toArray( r, offset );
			} else {
				r.set( array, offset );
			}

		}

	}

	return r;

}

function arraysEqual( a : Dynamic, b : Dynamic ) : Bool {
	
	if( a == null && b == null ) {
		return true;
	} else if ( a == null || b == null ) {
		return false;
	}
	
	if( a.length != b.length ) {
		return false;
	}

	for ( i in 0...a.length ) {
		if ( a[ i ] != b[ i ] ) {
			return false;
		}
	}

	return true;

}

function copyArray( a : Dynamic, b : Dynamic ) : Void {
	
	if( b == null ) {
		return;
	}

	for ( i in 0...b.length ) {
		a[ i ] = b[ i ];
	}

}

// Texture unit allocation

function allocTexUnits( textures : WebGLTextures, n : Int ) : Int32Array {

	var r = arrayCacheI32.get( n );

	if ( r == null ) {

		r = new Int32Array( n );
		arrayCacheI32.set( n, r );

	}

	for ( i in 0...n ) {
		r[ i ] = textures.allocateTextureUnit();
	}

	return r;

}

// --- Setters ---

// Note: Defining these methods externally, because they come in a bunch
// and this way their names minify.

// Single scalar

function setValueV1f( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;

	if ( cache[ 0 ] == v ) return;

	gl.uniform1f( this.addr, v );

	cache[ 0 ] = v;

}

// Single float vector (from flat array or THREE.VectorN)

function setValueV2f( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	
	if( Std.isOfType( v, Vector2 ) ) {
		var v2 = (cast v:Vector2);
		if ( cache[ 0 ] != v2.x || cache[ 1 ] != v2.y ) {

			gl.uniform2f( this.addr, v2.x, v2.y );

			cache[ 0 ] = v2.x;
			cache[ 1 ] = v2.y;

		}
	} else {

		if ( arraysEqual( cache, v ) ) return;

		gl.uniform2fv( this.addr, v );

		copyArray( cache, v );

	}

}

function setValueV3f( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;

	if(  Std.isOfType( v, Vector3 ) ) {
		
		var v3 = (cast v:Vector3);
		
		if ( cache[ 0 ] != v3.x || cache[ 1 ] != v3.y || cache[ 2 ] != v3.z ) {

			gl.uniform3f( this.addr, v3.x, v3.y, v3.z );

			cache[ 0 ] = v3.x;
			cache[ 1 ] = v3.y;
			cache[ 2 ] = v3.z;

		}
	} else {

		if ( arraysEqual( cache, v ) ) return;

		gl.uniform3fv( this.addr, v );

		copyArray( cache, v );

	}

}

function setValueV4f( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;

	if( Std.isOfType( v, Vector4 ) ) {
		
		var v4 = (cast v:Vector4);
		
		if ( cache[ 0 ] != v4.x || cache[ 1 ] != v4.y || cache[ 2 ] != v4.z || cache[ 3 ] != v4.w ) {

			gl.uniform4f( this.addr, v4.x, v4.y, v4.z, v4.w );

			cache[ 0 ] = v4.x;
			cache[ 1 ] = v4.y;
			cache[ 2 ] = v4.z;
			cache[ 3 ] = v4.w;

		}
	} else {

		if ( arraysEqual( cache, v ) ) return;

		gl.uniform4fv( this.addr, v );

		copyArray( cache, v );

	}

}

// Single matrix (from flat array or THREE.MatrixN)

function setValueM2( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	
	var elements = null;
	
	if( Std.isOfType( v, Matrix2 ) ) {
		elements = (cast v:Matrix2).elements;
	}
	
	if ( elements == null ) {

		if ( arraysEqual( cache, v ) ) return;

		gl.uniformMatrix2fv( this.addr, false, v );

		copyArray( cache, v );

	} else {

		if ( arraysEqual( cache, elements ) ) return;

		mat2array.set( elements );

		gl.uniformMatrix2fv( this.addr, false, mat2array );

		copyArray( cache, elements );

	}

}

function setValueM3( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	
	var elements = null;
	
	if( Std.isOfType( v, Matrix3 ) ) {
		elements = (cast v:Matrix3).elements;
	}

	if ( elements == null ) {

		if ( arraysEqual( cache, v ) ) return;

		gl.uniformMatrix3fv( this.addr, false, v );

		copyArray( cache, v );

	} else {

		if ( arraysEqual( cache, elements ) ) return;

		mat3array.set( elements );

		gl.uniformMatrix3fv( this.addr, false, mat3array );

		copyArray( cache, elements );

	}

}

function setValueM4( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	
	var elements = null;
	
	if( Std.isOfType( v, Matrix4 ) ) {
		elements = (cast v:Matrix4).elements;
	}

	if ( elements == null ) {

		if ( arraysEqual( cache, v ) ) return;

		gl.uniformMatrix4fv( this.addr, false, v );

		copyArray( cache, v );

	} else {

		if ( arraysEqual( cache, elements ) ) return;

		mat4array.set( elements );

		gl.uniformMatrix4fv( this.addr, false, mat4array );

		copyArray( cache, elements );

	}

}

// Single integer / boolean

function setValueV1i( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;

	if ( cache[ 0 ] == v ) return;

	gl.uniform1i( this.addr, v );

	cache[ 0 ] = v;

}

// Single integer / boolean vector (from flat array or THREE.VectorN)

function setValueV2i( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	
	if( Std.isOfType( v, Vector2 ) ) {
		
		var v2 = (cast v:Vector2);
		
		if ( cache[ 0 ] != v2.x || cache[ 1 ] != v2.y ) {

			gl.uniform2i( this.addr, Std.int(v2.x), Std.int(v2.y) );

			cache[ 0 ] = v2.x;
			cache[ 1 ] = v2.y;

		}
	} else {

		if ( arraysEqual( cache, v ) ) return;

		gl.uniform2iv( this.addr, v );

		copyArray( cache, v );

	}

}

function setValueV3i( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;

	if( Std.isOfType( v, Vector3 ) ) {
		
		var v3 = (cast v:Vector3);
		
		if ( cache[ 0 ] != v3.x || cache[ 1 ] != v3.y || cache[ 2 ] != v3.z ) {

			gl.uniform3i( this.addr, Std.int(v3.x), Std.int(v3.y), Std.int(v3.z) );

			cache[ 0 ] = v3.x;
			cache[ 1 ] = v3.y;
			cache[ 2 ] = v3.z;

		}
	} else {

		if ( arraysEqual( cache, v ) ) return;

		gl.uniform3iv( this.addr, v );

		copyArray( cache, v );

	}

}

function setValueV4i( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;

	if( Std.isOfType( v, Vector4 ) ) {
		
		var v4 = (cast v:Vector4);
		
		if ( cache[ 0 ] != v4.x || cache[ 1 ] != v4.y || cache[ 2 ] != v4.z || cache[ 3 ] != v4.w ) {

			gl.uniform4i( this.addr, Std.int(v4.x), Std.int(v4.y), Std.int(v4.z), Std.int(v4.w) );

			cache[ 0 ] = v4.x;
			cache[ 1 ] = v4.y;
			cache[ 2 ] = v4.z;
			cache[ 3 ] = v4.w;

		}
	} else {

		if ( arraysEqual( cache, v ) ) return;

		gl.uniform4iv( this.addr, v );

		copyArray( cache, v );

	}

}

// Single unsigned integer

function setValueV1ui( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;

	if ( cache[ 0 ] == v ) return;

	gl.uniform1ui( this.addr, v );

	cache[ 0 ] = v;

}

// Single unsigned integer vector (from flat array or THREE.VectorN)

function setValueV2ui( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;

	if ( v.x !== undefined ) {

		if ( cache[ 0 ] !== v.x || cache[ 1 ] !== v.y ) {

			gl.uniform2ui( this.addr, v.x, v.y );

			cache[ 0 ] = v.x;
			cache[ 1 ] = v.y;

		}

	} else {

		if ( arraysEqual( cache, v ) ) return;

		gl.uniform2uiv( this.addr, v );

		copyArray( cache, v );

	}

}

function setValueV3ui( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;

	if ( v.x !== undefined ) {

		if ( cache[ 0 ] !== v.x || cache[ 1 ] !== v.y || cache[ 2 ] !== v.z ) {

			gl.uniform3ui( this.addr, v.x, v.y, v.z );

			cache[ 0 ] = v.x;
			cache[ 1 ] = v.y;
			cache[ 2 ] = v.z;

		}

	} else {

		if ( arraysEqual( cache, v ) ) return;

		gl.uniform3uiv( this.addr, v );

		copyArray( cache, v );

	}

}

function setValueV4ui( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;

	if ( v.x !== undefined ) {

		if ( cache[ 0 ] !== v.x || cache[ 1 ] !== v.y || cache[ 2 ] !== v.z || cache[ 3 ] !== v.w ) {

			gl.uniform4ui( this.addr, v.x, v.y, v.z, v.w );

			cache[ 0 ] = v.x;
			cache[ 1 ] = v.y;
			cache[ 2 ] = v.z;
			cache[ 3 ] = v.w;

		}

	} else {

		if ( arraysEqual( cache, v ) ) return;

		gl.uniform4uiv( this.addr, v );

		copyArray( cache, v );

	}

}


// Single texture (2D / Cube)

function setValueT1( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	var unit = textures.allocateTextureUnit();

	if ( cache[ 0 ] != unit ) {

		gl.uniform1i( this.addr, unit );
		cache[ 0 ] = unit;

	}

	var emptyTexture2D = ( this.type == gl.SAMPLER_2D_SHADOW ) ? emptyShadowTexture : emptyTexture;

	textures.setTexture2D( v != null ? (cast v:Texture) : emptyTexture2D, unit );

}

function setValueT3D1( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	var unit = textures.allocateTextureUnit();

	if ( cache[ 0 ] != unit ) {

		gl.uniform1i( this.addr, unit );
		cache[ 0 ] = unit;

	}

	textures.setTexture3D( v != null ? (cast v:Data3DTexture) : empty3dTexture, unit );

}

function setValueT6( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	var unit = textures.allocateTextureUnit();

	if ( cache[ 0 ] != unit ) {

		gl.uniform1i( this.addr, unit );
		cache[ 0 ] = unit;

	}

	textures.setTextureCube( v != null ? (cast v:CubeTexture) : emptyCubeTexture, unit );

}

function setValueT2DArray1( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	var unit = textures.allocateTextureUnit();

	if ( cache[ 0 ] != unit ) {

		gl.uniform1i( this.addr, unit );
		cache[ 0 ] = unit;

	}

	textures.setTexture2DArray( v != null ? (cast v:DataArrayTexture) : emptyArrayTexture, unit );

}

// Helper to pick the right setter for the singular case

function getSingularSetter( type : Int ) : ( gl : WebGLRenderingContext, value : Dynamic, textures : WebGLTextures ) -> Void {

	switch ( type ) {

		case 0x1406: return setValueV1f; // FLOAT
		case 0x8b50: return setValueV2f; // _VEC2
		case 0x8b51: return setValueV3f; // _VEC3
		case 0x8b52: return setValueV4f; // _VEC4

		case 0x8b5a: return setValueM2; // _MAT2
		case 0x8b5b: return setValueM3; // _MAT3
		case 0x8b5c: return setValueM4; // _MAT4

		case 0x1404: case 0x8b56: return setValueV1i; // INT, BOOL
		case 0x8b53: case 0x8b57: return setValueV2i; // _VEC2
		case 0x8b54: case 0x8b58: return setValueV3i; // _VEC3
		case 0x8b55: case 0x8b59: return setValueV4i; // _VEC4

		case 0x1405: return setValueV1ui; // UINT
		case 0x8dc6: return setValueV2ui; // _VEC2
		case 0x8dc7: return setValueV3ui; // _VEC3
		case 0x8dc8: return setValueV4ui; // _VEC4

		case 0x8b5e: // SAMPLER_2D
		case 0x8d66: // SAMPLER_EXTERNAL_OES
		case 0x8dca: // INT_SAMPLER_2D
		case 0x8dd2: // UNSIGNED_INT_SAMPLER_2D
		case 0x8b62: // SAMPLER_2D_SHADOW
			return setValueT1;

		case 0x8b5f: // SAMPLER_3D
		case 0x8dcb: // INT_SAMPLER_3D
		case 0x8dd3: // UNSIGNED_INT_SAMPLER_3D
			return setValueT3D1;

		case 0x8b60: // SAMPLER_CUBE
		case 0x8dcc: // INT_SAMPLER_CUBE
		case 0x8dd4: // UNSIGNED_INT_SAMPLER_CUBE
		case 0x8dc5: // SAMPLER_CUBE_SHADOW
			return setValueT6;

		case 0x8dc1: // SAMPLER_2D_ARRAY
		case 0x8dcf: // INT_SAMPLER_2D_ARRAY
		case 0x8dd7: // UNSIGNED_INT_SAMPLER_2D_ARRAY
		case 0x8dc4: // SAMPLER_2D_ARRAY_SHADOW
			return setValueT2DArray1;

		default: 
			return null;

	}

}


// Array of scalars

function setValueV1fArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	gl.uniform1fv( this.addr, v );

}

// Array of vectors (from flat array or array of THREE.VectorN)

function setValueV2fArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var data = flatten( v, this.size, 2 );

	gl.uniform2fv( this.addr, data );

}

function setValueV3fArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var data = flatten( v, this.size, 3 );

	gl.uniform3fv( this.addr, data );

}

function setValueV4fArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var data = flatten( v, this.size, 4 );

	gl.uniform4fv( this.addr, data );

}

// Array of matrices (from flat array or array of THREE.MatrixN)

function setValueM2Array( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var data = flatten( v, this.size, 4 );

	gl.uniformMatrix2fv( this.addr, false, data );

}

function setValueM3Array( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var data = flatten( v, this.size, 9 );

	gl.uniformMatrix3fv( this.addr, false, data );

}

function setValueM4Array( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var data = flatten( v, this.size, 16 );

	gl.uniformMatrix4fv( this.addr, false, data );

}

// Array of integer / boolean

function setValueV1iArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	gl.uniform1iv( this.addr, v );

}

// Array of integer / boolean vectors (from flat array)

function setValueV2iArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	gl.uniform2iv( this.addr, v );

}

function setValueV3iArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	gl.uniform3iv( this.addr, v );

}

function setValueV4iArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	gl.uniform4iv( this.addr, v );

}

// Array of unsigned integer

function setValueV1uiArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	gl.uniform1uiv( this.addr, v );

}

// Array of unsigned integer vectors (from flat array)

function setValueV2uiArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	gl.uniform2uiv( this.addr, v );

}

function setValueV3uiArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	gl.uniform3uiv( this.addr, v );

}

function setValueV4uiArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	gl.uniform4uiv( this.addr, v );

}


// Array of textures (2D / 3D / Cube / 2DArray)

function setValueT1Array( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	
	var n = 0;
	if( v != null ) {
		n = v.length;
	}

	var units = allocTexUnits( textures, n );

	if ( ! arraysEqual( cache, units ) ) {

		gl.uniform1iv( this.addr, units );

		copyArray( cache, units );

	}

	for ( i in 0...n ) {
		textures.setTexture2D( i < v.length && v[ i ] != null ? (cast v[i]:Texture) : emptyTexture, units[ i ] );
	}

}

function setValueT3DArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	
	var n = 0;
	if( v != null ) {
		n = v.length;
	}

	var units = allocTexUnits( textures, n );

	if ( ! arraysEqual( cache, units ) ) {

		gl.uniform1iv( this.addr, units );

		copyArray( cache, units );

	}

	for ( i in 0...n ) {

		textures.setTexture3D( i < v.length && v[ i ] != null ? (cast v[ i ]:Data3DTexture) : empty3dTexture, units[ i ] );

	}

}

function setValueT6Array( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	
	var n = 0;
	if( v != null ) {
		n = v.length;
	}

	var units = allocTexUnits( textures, n );

	if ( ! arraysEqual( cache, units ) ) {

		gl.uniform1iv( this.addr, units );

		copyArray( cache, units );

	}

	for ( i in 0...n ) {
		textures.setTextureCube(  i < v.length && v[ i ] != null ? (cast v[ i ]:CubeTexture) : emptyCubeTexture, units[ i ] );
	}

}

function setValueT2DArrayArray( gl : WebGLRenderingContext, v : Dynamic, textures : WebGLTextures ) : Void {

	var cache = this.cache;
	
	var n = 0;
	if( v
	if( v != null ) {
		n = v.length;
	}

	var units = allocTexUnits( textures, n );

	if ( ! arraysEqual( cache, units ) ) {

		gl.uniform1iv( this.addr, units );

		copyArray( cache, units );

	}

	for ( i in 0...n ) {
		textures.setTexture2DArray(  i < v.length && v[ i ] != null ? (cast v[ i ]:DataArrayTexture) : emptyArrayTexture, units[ i ] );
	}

}


// Helper to pick the right setter for a pure (bottom-level) array

function getPureArraySetter( type : Int ) : ( gl : WebGLRenderingContext, value : Dynamic, textures : WebGLTextures ) -> Void {

	switch ( type ) {

		case 0x1406: return setValueV1fArray; // FLOAT
		case 0x8b50: return setValueV2fArray; // _VEC2
		case 0x8b51: return setValueV3fArray; // _VEC3
		case 0x8b52: return setValueV4fArray; // _VEC4

		case 0x8b5a: return setValueM2Array; // _MAT2
		case 0x8b5b: return setValueM3Array; // _MAT3
		case 0x8b5c: return setValueM4Array; // _MAT4

		case 0x1404: case 0x8b56: return setValueV1iArray; // INT, BOOL
		case 0x8b53: case 0x8b57: return setValueV2iArray; // _VEC2
		case 0x8b54: case 0x8b58: return setValueV3iArray; // _VEC3
		case 0x8b55: case 0x8b59: return setValueV4iArray; // _VEC4

		case 0x1405: return setValueV1uiArray; // UINT
		case 0x8dc6: return setValueV2uiArray; // _VEC2
		case 0x8dc7: return setValueV3uiArray; // _VEC3
		case 0x8dc8: return setValueV4uiArray; // _VEC4

		case 0x8b5e: // SAMPLER_2D
		case 0x8d66: // SAMPLER_EXTERNAL_OES
		case 0x8dca: // INT_SAMPLER_2D
		case 0x8dd2: // UNSIGNED_INT_SAMPLER_2D
		case 0x8b62: // SAMPLER_2D_SHADOW
			return setValueT1Array;

		case 0x8b5f: // SAMPLER_3D
		case 0x8dcb: // INT_SAMPLER_3D
		case 0x8dd3: // UNSIGNED_INT_SAMPLER_3D
			return setValueT3DArray;

		case 0x8b60: // SAMPLER_CUBE
		case 0x8dcc: // INT_SAMPLER_CUBE
		case 0x8dd4: // UNSIGNED_INT_SAMPLER_CUBE
		case 0x8dc5: // SAMPLER_CUBE_SHADOW
			return setValueT6Array;

		case 0x8dc1: // SAMPLER_2D_ARRAY
		case 0x8dcf: // INT_SAMPLER_2D_ARRAY
		case 0x8dd7: // UNSIGNED_INT_SAMPLER_2D_ARRAY
		case 0x8dc4: // SAMPLER_2D_ARRAY_SHADOW
			return setValueT2DArrayArray;

		default: 
			return null;

	}

}


// --- Uniform Classes ---



// --- Top-level ---

// Parser - builds up the property tree from the path strings

var RePathPart = ~/(\w+)(\])?(\[|\.)?/g;

// extracts
// 	- the identifier (member name or array index)
//  - followed by an optional right bracket (found when array index)
//  - followed by an optional left bracket or dot (type of subscript)
//
// Note: These portions can be read in a non-overlapping fashion and
// allow straightforward parsing of the hierarchy that WebGL encodes
// in the uniform names.

function addUniform( container : { seq : Array<IUniform>, map : Map<String, IUniform> }, uniformObject : IUniform ) : Void {

	container.seq.push( uniformObject );
	container.map.set( uniformObject.id, uniformObject );

}

function parseUniform( activeInfo : Dynamic, addr : WebGLUniformLocation, container : { seq : Array<IUniform>, map : Map<String, IUniform> } ) : Void {

	var path : String = activeInfo.name;
	var pathLength = path.length;

	// reset RegExp object, because of the early exit of a previous run
	RePathPart.lastIndex = 0;

	while ( true ) {

		var match = RePathPart.match( path );
		
		if( match == null ) {
			break;
		}
		var matchEnd = RePathPart.lastIndex;

		var id = match[ 1 ];
		var idIsIndex = match[ 2 ] == "]";
		var subscript = match[ 3 ];

		if ( idIsIndex ) id = Std.parseInt(id); // convert to integer

		if ( subscript == null || (subscript == "[" && matchEnd + 2 == pathLength) ) {
			// bare name or "pure" bottom-level array "[0]" suffix
			
			var uniform : IUniform = null;
			if( subscript == null ) {
				uniform = new SingleUniform( id, activeInfo, addr );
			} else {
				uniform = new PureArrayUniform( id, activeInfo, addr );
			}
			addUniform( container, uniform );

			break;

		} else {

			// step into inner node / create it in case it doesn't exist

			var map = container.map;
			var next = map.get( id );

			if ( next == null ) {

				next = new StructuredUniform( id );
				addUniform( container, next );

			}

			container = { seq : next.seq, map : next.map };

		}

	}

}


var emptyTexture = new Texture();

var emptyShadowTexture = new DepthTexture( 1, 1 );
emptyShadowTexture.compareFunction = LessEqualCompare;

var emptyArrayTexture = new DataArrayTexture();
var empty3dTexture = new Data3DTexture();
var emptyCubeTexture = new CubeTexture();