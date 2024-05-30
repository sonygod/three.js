import TempNode from '../core/TempNode.js';
import { addNodeClass } from '../core/Node.js';
import { texture } from '../accessors/TextureNode.js';
import { textureCubeUV } from './PMREMUtils.js';
import { uniform } from '../core/UniformNode.js';
import { NodeUpdateType } from '../core/constants.js';
import { nodeProxy, vec3 } from '../shadernode/ShaderNode.js';
import { WebGLCoordinateSystem } from 'three';

var _generator:Null<Dynamic> = null;

var _cache:WeakMap<Dynamic, Dynamic> = new WeakMap();

function _generateCubeUVSize( imageHeight:Int ) {

	var maxMip:Int = Math.log2( imageHeight ) - 2;

	var texelHeight:Float = 1.0 / imageHeight;

	var texelWidth:Float = 1.0 / ( 3 * Math.max( Math.pow( 2, maxMip ), 7 * 16 ) );

	return { texelWidth, texelHeight, maxMip };

}

function _getPMREMFromTexture( texture:Dynamic ) {

	var cacheTexture:Dynamic = _cache.get( texture );

	var pmremVersion:Int = cacheTexture !== undefined ? cacheTexture.pmremVersion : - 1;

	if ( pmremVersion !== texture.pmremVersion ) {

		if ( texture.isCubeTexture ) {

			if ( texture.source.data.some( ( texture:Dynamic ) => texture === undefined ) ) {

				throw new Error( 'PMREMNode: Undefined texture in CubeTexture. Use onLoad callback or async loader' );

			}

			cacheTexture = _generator.fromCubemap( texture, cacheTexture );

		} else {

			if ( texture.image === undefined ) {

				throw new Error( 'PMREMNode: Undefined image in Texture. Use onLoad callback or async loader' );

			}

			cacheTexture = _generator.fromEquirectangular( texture, cacheTexture );

		}

		cacheTexture.pmremVersion = texture.pmremVersion;

		_cache.set( texture, cacheTexture );

	}

	return cacheTexture.texture;

}

class PMREMNode extends TempNode {

	public var _value:Dynamic;
	public var _pmrem:Null<Dynamic>;

	public var uvNode:Null<Dynamic>;
	public var levelNode:Null<Dynamic>;

	public var _generator:Null<Dynamic>;
	public var _texture:Dynamic;
	public var _width:Dynamic;
	public var _height:Dynamic;
	public var _maxMip:Dynamic;

	public function new( value:Dynamic, uvNode:Null<Dynamic> = null, levelNode:Null<Dynamic> = null ) {

		super( 'vec3' );

		this._value = value;
		this._pmrem = null;

		this.uvNode = uvNode;
		this.levelNode = levelNode;

		this._generator = null;
		this._texture = texture( null );
		this._width = uniform( 0 );
		this._height = uniform( 0 );
		this._maxMip = uniform( 0 );

		this.updateBeforeType = NodeUpdateType.RENDER;

	}

	public function set value( value:Dynamic ) {

		this._value = value;
		this._pmrem = null;

	}

	public function get value():Dynamic {

		return this._value;

	}

	public function updateFromTexture( texture:Dynamic ) {

		var cubeUVSize:Dynamic = _generateCubeUVSize( texture.image.height );

		this._texture.value = texture;
		this._width.value = cubeUVSize.texelWidth;
		this._height.value = cubeUVSize.texelHeight;
		this._maxMip.value = cubeUVSize.maxMip;

	}

	public function updateBefore() {

		var pmrem:Dynamic = this._pmrem;

		var pmremVersion:Int = pmrem ? pmrem.pmremVersion : - 1;
		var texture:Dynamic = this._value;

		if ( pmremVersion !== texture.pmremVersion ) {

			if ( texture.isPMREMTexture === true ) {

				pmrem = texture;

			} else {

				pmrem = _getPMREMFromTexture( texture );

			}

			this._pmrem = pmrem;

			this.updateFromTexture( pmrem );

		}

	}

	public function setup( builder:Dynamic ) {

		if ( _generator === null ) {

			_generator = builder.createPMREMGenerator();

		}

		//

		this.updateBefore( builder );

		//

		var uvNode:Dynamic = this.uvNode;

		if ( uvNode === null && builder.context.getUV ) {

			uvNode = builder.context.getUV( this );

		}

		//

		var texture:Dynamic = this.value;

		if ( builder.renderer.coordinateSystem === WebGLCoordinateSystem && texture.isPMREMTexture !== true && texture.isRenderTargetTexture === true ) {

			uvNode = vec3( uvNode.x.negate(), uvNode.yz );

		}

		//

		var levelNode:Dynamic = this.levelNode;

		if ( levelNode === null && builder.context.getTextureLevel ) {

			levelNode = builder.context.getTextureLevel( this );

		}

		//

		return textureCubeUV( this._texture, uvNode, levelNode, this._width, this._height, this._maxMip );

	}

}

export const pmremTexture:Dynamic = nodeProxy( PMREMNode );

addNodeClass( 'PMREMNode', PMREMNode );

export default PMREMNode;