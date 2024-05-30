import three.Color;
import three.Matrix3;
import three.Matrix4;
import three.Vector2;
import three.Vector3;
import three.Vector4;

function getCacheKey( object, ?force = false ) {

	var cacheKey = '{';

	if ( object.isNode === true ) {

		cacheKey += object.id;

	}

	for ( child in getNodeChildren( object ) ) {

		cacheKey += ',' + child.property.substr( 0, - 4 ) + ':' + child.childNode.getCacheKey( force );

	}

	cacheKey += '}';

	return cacheKey;

}

function getNodeChildren( node, ?toJSON = false ) {

	for ( property in Reflect.fields(node) ) {

		// Ignore private properties.
		if ( property.startsWith( '_' ) === true ) continue;

		var object = Reflect.field(node, property);

		if ( Std.is(object, Array) ) {

			for ( i in object ) {

				var child = object[i];

				if ( child && ( child.isNode === true || toJSON && Std.is(child.toJSON, Function) ) ) {

					yield { property:property, index:i, childNode:child };

				}

			}

		} else if ( object && object.isNode === true ) {

			yield { property:property, childNode:object };

		} else if ( Std.is(object, Object) ) {

			for ( subProperty in Reflect.fields(object) ) {

				var child = Reflect.field(object, subProperty);

				if ( child && ( child.isNode === true || toJSON && Std.is(child.toJSON, Function) ) ) {

					yield { property:property, index:subProperty, childNode:child };

				}

			}

		}

	}

}

function getValueType( value ) {

	if ( value === null ) return null;

	var typeOf = Std.typeof(value);

	if ( value.isNode === true ) {

		return 'node';

	} else if ( typeOf === 'Float' ) {

		return 'float';

	} else if ( typeOf === 'Bool' ) {

		return 'bool';

	} else if ( typeOf === 'String' ) {

		return 'string';

	} else if ( typeOf === 'Function' ) {

		return 'shader';

	} else if ( value.isVector2 === true ) {

		return 'vec2';

	} else if ( value.isVector3 === true ) {

		return 'vec3';

	} else if ( value.isVector4 === true ) {

		return 'vec4';

	} else if ( value.isMatrix3 === true ) {

		return 'mat3';

	} else if ( value.isMatrix4 === true ) {

		return 'mat4';

	} else if ( value.isColor === true ) {

		return 'color';

	} else if ( Std.is(value, ArrayBuffer) ) {

		return 'ArrayBuffer';

	}

	return null;

}

function getValueFromType( type, params ) {

	var last4 = type ? type.substr( - 4 ) : null;

	if ( params.length === 1 ) { // ensure same behaviour as in NodeBuilder.format()

		if ( last4 === 'vec2' ) params = [ params[0], params[0] ];
		else if ( last4 === 'vec3' ) params = [ params[0], params[0], params[0] ];
		else if ( last4 === 'vec4' ) params = [ params[0], params[0], params[0], params[0] ];

	}

	if ( type === 'color' ) {

		return new Color( params );

	} else if ( last4 === 'vec2' ) {

		return new Vector2( params );

	} else if ( last4 === 'vec3' ) {

		return new Vector3( params );

	} else if ( last4 === 'vec4' ) {

		return new Vector4( params );

	} else if ( last4 === 'mat3' ) {

		return new Matrix3( params );

	} else if ( last4 === 'mat4' ) {

		return new Matrix4( params );

	} else if ( type === 'bool' ) {

		return params[0] || false;

	} else if ( ( type === 'float' ) || ( type === 'int' ) || ( type === 'uint' ) ) {

		return params[0] || 0;

	} else if ( type === 'string' ) {

		return params[0] || '';

	} else if ( type === 'ArrayBuffer' ) {

		return base64ToArrayBuffer( params[0] );

	}

	return null;

}

function arrayBufferToBase64( arrayBuffer ) {

	var chars = '';

	var array = new Uint8Array( arrayBuffer );

	for ( i in array ) {

		chars += String.fromCharCode( array[i] );

	}

	return haxe.Utf8.encode(chars);

}

function base64ToArrayBuffer( base64 ) {

	return haxe.Utf8.decode(base64).toArray();

}