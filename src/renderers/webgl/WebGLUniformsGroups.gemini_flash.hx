import three.WebGLProgram;
import three.WebGLRenderer;
import three.core.Event;
import three.core.EventDispatcher;
import three.math.Color;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.renderers.gl.WebGLInfo;
import three.renderers.gl.WebGLState;
import three.textures.Texture;
import js.lib.Float32Array;

class WebGLUniformsGroups {

	public function new( gl : Dynamic, info : WebGLInfo, capabilities : Dynamic, state : WebGLState ) {

		var buffers : Map<Int, Dynamic> = new Map();
		var updateList : Map<Int, Int> = new Map();
		var allocatedBindingPoints : Array<Int> = [];

		var maxBindingPoints = gl.getParameter( gl.MAX_UNIFORM_BUFFER_BINDINGS ); // binding points are global whereas block indices are per shader program

		function bind( uniformsGroup : Dynamic, program : WebGLProgram ) : Void {

			var webglProgram = program.program;
			state.uniformBlockBinding( uniformsGroup, webglProgram );

		}

		function update( uniformsGroup : Dynamic, program : WebGLProgram ) : Void {

			var buffer = buffers.get( uniformsGroup.id );

			if ( buffer == null ) {

				prepareUniformsGroup( uniformsGroup );

				buffer = createBuffer( uniformsGroup );
				buffers.set( uniformsGroup.id, buffer );

				uniformsGroup.addEventListener( 'dispose', onUniformsGroupsDispose );

			}

			// ensure to update the binding points/block indices mapping for this program

			var webglProgram = program.program;
			state.updateUBOMapping( uniformsGroup, webglProgram );

			// update UBO once per frame

			var frame = info.render.frame;

			if ( updateList.get( uniformsGroup.id ) != frame ) {

				updateBufferData( uniformsGroup );

				updateList.set( uniformsGroup.id, frame );

			}

		}

		function createBuffer( uniformsGroup : Dynamic ) : Dynamic {

			// the setup of an UBO is independent of a particular shader program but global

			var bindingPointIndex = allocateBindingPointIndex();
			uniformsGroup.__bindingPointIndex = bindingPointIndex;

			var buffer = gl.createBuffer();
			var size = uniformsGroup.__size;
			var usage = uniformsGroup.usage;

			gl.bindBuffer( gl.UNIFORM_BUFFER, buffer );
			gl.bufferData( gl.UNIFORM_BUFFER, size, usage );
			gl.bindBuffer( gl.UNIFORM_BUFFER, null );
			gl.bindBufferBase( gl.UNIFORM_BUFFER, bindingPointIndex, buffer );

			return buffer;

		}

		function allocateBindingPointIndex() : Int {

			for ( i in 0...maxBindingPoints ) {

				if ( allocatedBindingPoints.indexOf( i ) == - 1 ) {

					allocatedBindingPoints.push( i );
					return i;

				}

			}

			trace( 'THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached.' );

			return 0;

		}

		function updateBufferData( uniformsGroup : Dynamic ) : Void {

			var buffer = buffers.get( uniformsGroup.id );
			var uniforms : Array<Dynamic> = uniformsGroup.uniforms;
			var cache : Map<String, Dynamic> = uniformsGroup.__cache;

			gl.bindBuffer( gl.UNIFORM_BUFFER, buffer );

			for ( i in 0...uniforms.length ) {

				var uniformArray = (Std.isOfType(uniforms[ i ], Array) ? uniforms[ i ] : [ uniforms[ i ] ]);

				for ( j in 0...uniformArray.length ) {

					var uniform = uniformArray[ j ];

					if ( hasUniformChanged( uniform, i, j, cache ) ) {

						var offset = uniform.__offset;

						var values = (Std.isOfType(uniform.value, Array) ? uniform.value : [ uniform.value ]);

						var arrayOffset = 0;

						for ( k in 0...values.length ) {

							var value = values[ k ];

							var info = getUniformSize( value );

							// TODO add integer and struct support
							if ( Std.isOfType(value, Float) || Std.isOfType(value, Bool) ) {

								(cast uniform.__data : Float32Array)[ 0 ] = value;
								gl.bufferSubData( gl.UNIFORM_BUFFER, offset + arrayOffset, uniform.__data );

							} else if ( Std.isOfType(value, Matrix3) ) {

								// manually converting 3x3 to 3x4
								var mat3 = cast value;

								(cast uniform.__data : Float32Array)[ 0 ] = mat3.elements[ 0 ];
								(cast uniform.__data : Float32Array)[ 1 ] = mat3.elements[ 1 ];
								(cast uniform.__data : Float32Array)[ 2 ] = mat3.elements[ 2 ];
								(cast uniform.__data : Float32Array)[ 3 ] = 0;
								(cast uniform.__data : Float32Array)[ 4 ] = mat3.elements[ 3 ];
								(cast uniform.__data : Float32Array)[ 5 ] = mat3.elements[ 4 ];
								(cast uniform.__data : Float32Array)[ 6 ] = mat3.elements[ 5 ];
								(cast uniform.__data : Float32Array)[ 7 ] = 0;
								(cast uniform.__data : Float32Array)[ 8 ] = mat3.elements[ 6 ];
								(cast uniform.__data : Float32Array)[ 9 ] = mat3.elements[ 7 ];
								(cast uniform.__data : Float32Array)[ 10 ] = mat3.elements[ 8 ];
								(cast uniform.__data : Float32Array)[ 11 ] = 0;

							} else {

								value.toArray( uniform.__data, arrayOffset );

								arrayOffset += Std.int(info.storage / Float32Array.BYTES_PER_ELEMENT);

							}

						}

						gl.bufferSubData( gl.UNIFORM_BUFFER, offset, uniform.__data );

					}

				}

			}

			gl.bindBuffer( gl.UNIFORM_BUFFER, null );

		}

		function hasUniformChanged( uniform : Dynamic, index : Int, indexArray : Int, cache : Map<String, Dynamic> ) : Bool {

			var value = uniform.value;
			var indexString = '$index_' + indexArray;

			if ( !cache.exists(indexString) ) {

				// cache entry does not exist so far

				if ( Std.isOfType(value, Float) || Std.isOfType(value, Bool) ) {

					cache.set( indexString, value );

				} else {

					cache.set( indexString, Reflect.callMethod(value, Reflect.field(value, "clone"), []) );

				}

				return true;

			} else {

				var cachedObject = cache.get( indexString );

				// compare current value with cached entry

				if ( Std.isOfType(value, Float) || Std.isOfType(value, Bool) ) {

					if ( cachedObject != value ) {

						cache.set( indexString, value );
						return true;

					}

				} else {
					
					if ( !Reflect.callMethod(cachedObject, Reflect.field(cachedObject, "equals"), [value]) ) {

						Reflect.callMethod(cachedObject, Reflect.field(cachedObject, "copy"), [value]);
						return true;

					}

				}

			}

			return false;

		}

		function prepareUniformsGroup( uniformsGroup : Dynamic ) : Void {

			// determine total buffer size according to the STD140 layout
			// Hint: STD140 is the only supported layout in WebGL 2

			var uniforms : Array<Dynamic> = uniformsGroup.uniforms;

			var offset = 0; // global buffer offset in bytes
			var chunkSize = 16; // size of a chunk in bytes

			for ( i in 0...uniforms.length ) {

				var uniformArray = (Std.isOfType(uniforms[ i ], Array) ? uniforms[ i ] : [ uniforms[ i ] ]);

				for ( j in 0...uniformArray.length ) {

					var uniform = uniformArray[ j ];

					var values = (Std.isOfType(uniform.value, Array) ? uniform.value : [ uniform.value ]);

					for ( k in 0...values.length ) {

						var value = values[ k ];

						var info = getUniformSize( value );

						// Calculate the chunk offset
						var chunkOffsetUniform = offset % chunkSize;

						// Check for chunk overflow
						if ( chunkOffsetUniform != 0 && ( chunkSize - chunkOffsetUniform ) < info.boundary ) {

							// Add padding and adjust offset
							offset += ( chunkSize - chunkOffsetUniform );

						}

						// the following two properties will be used for partial buffer updates

						uniform.__data = new Float32Array( Std.int(info.storage / Float32Array.BYTES_PER_ELEMENT) );
						uniform.__offset = offset;


						// Update the global offset
						offset += info.storage;


					}

				}

			}

			// ensure correct final padding

			var chunkOffset = offset % chunkSize;

			if ( chunkOffset > 0 ) offset += ( chunkSize - chunkOffset );

			//

			uniformsGroup.__size = offset;
			uniformsGroup.__cache = new Map();

		}

		function getUniformSize( value : Dynamic ) : { boundary : Int, storage : Int } {

			var info = {
				boundary: 0, // bytes
				storage: 0 // bytes
			};

			// determine sizes according to STD140

			if ( Std.isOfType(value, Float) || Std.isOfType(value, Bool) ) {

				// float/int/bool

				info.boundary = 4;
				info.storage = 4;

			} else if ( Std.isOfType(value, Vector2) ) {

				// vec2

				info.boundary = 8;
				info.storage = 8;

			} else if ( Std.isOfType(value, Vector3) || Std.isOfType(value, Color) ) {

				// vec3

				info.boundary = 16;
				info.storage = 12; // evil: vec3 must start on a 16-byte boundary but it only consumes 12 bytes

			} else if ( Std.isOfType(value, Vector4) ) {

				// vec4

				info.boundary = 16;
				info.storage = 16;

			} else if ( Std.isOfType(value, Matrix3) ) {

				// mat3 (in STD140 a 3x3 matrix is represented as 3x4)

				info.boundary = 48;
				info.storage = 48;

			} else if ( Std.isOfType(value, Matrix4) ) {

				// mat4

				info.boundary = 64;
				info.storage = 64;

			} else if ( Std.isOfType(value, Texture) ) {

				trace( 'THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.' );

			} else {

				trace( 'THREE.WebGLRenderer: Unsupported uniform value type.', value );

			}

			return info;

		}

		function onUniformsGroupsDispose( event : Event ) : Void {

			var uniformsGroup = event.target;

			uniformsGroup.removeEventListener( 'dispose', onUniformsGroupsDispose );

			var index = allocatedBindingPoints.indexOf( uniformsGroup.__bindingPointIndex );
			allocatedBindingPoints.splice( index, 1 );

			gl.deleteBuffer( buffers.get( uniformsGroup.id ) );

			buffers.remove( uniformsGroup.id );
			updateList.remove( uniformsGroup.id );

		}

		function dispose() : Void {

			for ( id in buffers.keys() ) {

				gl.deleteBuffer( buffers.get( id ) );

			}

			allocatedBindingPoints = [];
			buffers = new Map();
			updateList = new Map();

		}

		this.bind = bind;
		this.update = update;
		this.dispose = dispose;

	}

}