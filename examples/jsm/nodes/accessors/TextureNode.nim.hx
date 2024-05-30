import UniformNode, { uniform } from '../core/UniformNode.hx';
import { uv } from './UVNode.hx';
import { textureSize } from './TextureSizeNode.hx';
import { colorSpaceToLinear } from '../display/ColorSpaceNode.hx';
import { expression } from '../code/ExpressionNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { maxMipLevel } from '../utils/MaxMipLevelNode.hx';
import { addNodeElement, nodeProxy, vec3, nodeObject } from '../shadernode/ShaderNode.hx';
import { NodeUpdateType } from '../core/constants.hx';

class TextureNode extends UniformNode {

	public var isTextureNode:Bool = true;
	public var uvNode:Dynamic;
	public var levelNode:Dynamic;
	public var compareNode:Dynamic;
	public var depthNode:Dynamic;
	public var gradNode:Dynamic;

	public var sampler:Bool = true;
	public var updateMatrix:Bool = false;
	public var updateType:NodeUpdateType = NodeUpdateType.NONE;

	public var referenceNode:Dynamic;

	private var _value:Dynamic;

	public function new( value:Dynamic, uvNode:Dynamic = null, levelNode:Dynamic = null ) {
		super( value );

		this.setUpdateMatrix( uvNode === null );
	}

	public function set value( value:Dynamic ) {
		if ( this.referenceNode ) {
			this.referenceNode.value = value;
		} else {
			this._value = value;
		}
	}

	public function get value():Dynamic {
		return this.referenceNode ? this.referenceNode.value : this._value;
	}

	public function getUniformHash( /*builder*/ ) {
		return this.value.uuid;
	}

	public function getNodeType( /*builder*/ ) {
		if ( this.value.isDepthTexture === true ) return 'float';
		return 'vec4';
	}

	public function getInputType( /*builder*/ ) {
		return 'texture';
	}

	public function getDefaultUV() {
		return uv( this.value.channel );
	}

	public function updateReference( /*state*/ ) {
		return this.value;
	}

	public function getTransformedUV( uvNode:Dynamic ) {
		const texture = this.value;
		return uniform( texture.matrix ).mul( vec3( uvNode, 1 ) ).xy;
	}

	public function setUpdateMatrix( value:Bool ) {
		this.updateMatrix = value;
		this.updateType = value ? NodeUpdateType.FRAME : NodeUpdateType.NONE;
		return this;
	}

	public function setupUV( builder:Dynamic, uvNode:Dynamic ) {
		const texture = this.value;

		if ( builder.isFlipY() && ( texture.isRenderTargetTexture === true || texture.isFramebufferTexture === true || texture.isDepthTexture === true ) ) {
			uvNode = uvNode.setY( uvNode.y.oneMinus() );
		}

		return uvNode;
	}

	public function setup( builder:Dynamic ) {
		const properties = builder.getNodeProperties( this );

		let uvNode = this.uvNode;

		if ( ( uvNode === null || builder.context.forceUVContext === true ) && builder.context.getUV ) {
			uvNode = builder.context.getUV( this );
		}

		if ( ! uvNode ) uvNode = this.getDefaultUV();

		if ( this.updateMatrix === true ) {
			uvNode = this.getTransformedUV( uvNode );
		}

		uvNode = this.setupUV( builder, uvNode );

		let levelNode = this.levelNode;

		if ( levelNode === null && builder.context.getTextureLevel ) {
			levelNode = builder.context.getTextureLevel( this );
		}

		properties.uvNode = uvNode;
		properties.levelNode = levelNode;
		properties.compareNode = this.compareNode;
		properties.gradNode = this.gradNode;
		properties.depthNode = this.depthNode;
	}

	public function generateUV( builder:Dynamic, uvNode:Dynamic ) {
		return uvNode.build( builder, this.sampler === true ? 'vec2' : 'ivec2' );
	}

	public function generateSnippet( builder:Dynamic, textureProperty:Dynamic, uvSnippet:Dynamic, levelSnippet:Dynamic, depthSnippet:Dynamic, compareSnippet:Dynamic, gradSnippet:Dynamic ) {
		const texture = this.value;

		let snippet;

		if ( levelSnippet ) {
			snippet = builder.generateTextureLevel( texture, textureProperty, uvSnippet, levelSnippet, depthSnippet );
		} else if ( gradSnippet ) {
			snippet = builder.generateTextureGrad( texture, textureProperty, uvSnippet, gradSnippet, depthSnippet );
		} else if ( compareSnippet ) {
			snippet = builder.generateTextureCompare( texture, textureProperty, uvSnippet, compareSnippet, depthSnippet );
		} else if ( this.sampler === false ) {
			snippet = builder.generateTextureLoad( texture, textureProperty, uvSnippet, depthSnippet );
		} else {
			snippet = builder.generateTexture( texture, textureProperty, uvSnippet, depthSnippet );
		}

		return snippet;
	}

	public function generate( builder:Dynamic, output:Dynamic ) {
		const properties = builder.getNodeProperties( this );

		const texture = this.value;

		if ( ! texture || texture.isTexture !== true ) {
			throw new Error( 'TextureNode: Need a three.js texture.' );
		}

		const textureProperty = super.generate( builder, 'property' );

		if ( output === 'sampler' ) {
			return textureProperty + '_sampler';
		} else if ( builder.isReference( output ) ) {
			return textureProperty;
		} else {
			const nodeData = builder.getDataFromNode( this );

			let propertyName = nodeData.propertyName;

			if ( propertyName === undefined ) {
				const { uvNode, levelNode, compareNode, depthNode, gradNode } = properties;

				const uvSnippet = this.generateUV( builder, uvNode );
				const levelSnippet = levelNode ? levelNode.build( builder, 'float' ) : null;
				const depthSnippet = depthNode ? depthNode.build( builder, 'int' ) : null;
				const compareSnippet = compareNode ? compareNode.build( builder, 'float' ) : null;
				const gradSnippet = gradNode ? [ gradNode[ 0 ].build( builder, 'vec2' ), gradNode[ 1 ].build( builder, 'vec2' ) ] : null;

				const nodeVar = builder.getVarFromNode( this );

				propertyName = builder.getPropertyName( nodeVar );

				const snippet = this.generateSnippet( builder, textureProperty, uvSnippet, levelSnippet, depthSnippet, compareSnippet, gradSnippet );

				builder.addLineFlowCode( `${propertyName} = ${snippet}` );

				if ( builder.context.tempWrite !== false ) {
					nodeData.snippet = snippet;
					nodeData.propertyName = propertyName;
				}
			}

			let snippet = propertyName;
			const nodeType = this.getNodeType( builder );

			if ( builder.needsColorSpaceToLinear( texture ) ) {
				snippet = colorSpaceToLinear( expression( snippet, nodeType ), texture.colorSpace ).setup( builder ).build( builder, nodeType );
			}

			return builder.format( snippet, nodeType, output );
		}
	}

	public function setSampler( value:Bool ) {
		this.sampler = value;
		return this;
	}

	public function getSampler() {
		return this.sampler;
	}

	public function uv( uvNode:Dynamic ) {
		const textureNode = this.clone();
		textureNode.uvNode = uvNode;
		textureNode.referenceNode = this;

		return nodeObject( textureNode );
	}

	public function blur( levelNode:Dynamic ) {
		const textureNode = this.clone();
		textureNode.levelNode = levelNode.mul( maxMipLevel( textureNode ) );
		textureNode.referenceNode = this;

		return nodeObject( textureNode );
	}

	public function level( levelNode:Dynamic ) {
		const textureNode = this.clone();
		textureNode.levelNode = levelNode;
		textureNode.referenceNode = this;

		return textureNode;
	}

	public function size( levelNode:Dynamic ) {
		return textureSize( this, levelNode );
	}

	public function compare( compareNode:Dynamic ) {
		const textureNode = this.clone();
		textureNode.compareNode = nodeObject( compareNode );
		textureNode.referenceNode = this;

		return nodeObject( textureNode );
	}

	public function grad( gradNodeX:Dynamic, gradNodeY:Dynamic ) {
		const textureNode = this.clone();
		textureNode.gradNode = [ nodeObject( gradNodeX ), nodeObject( gradNodeY ) ];

		textureNode.referenceNode = this;

		return nodeObject( textureNode );
	}

	public function depth( depthNode:Dynamic ) {
		const textureNode = this.clone();
		textureNode.depthNode = nodeObject( depthNode );
		textureNode.referenceNode = this;

		return nodeObject( textureNode );
	}

	public function serialize( data:Dynamic ) {
		super.serialize( data );

		data.value = this.value.toJSON( data.meta ).uuid;
	}

	public function deserialize( data:Dynamic ) {
		super.deserialize( data );

		this.value = data.meta.textures[ data.value ];
	}

	public function update() {
		const texture = this.value;

		if ( texture.matrixAutoUpdate === true ) {
			texture.updateMatrix();
		}
	}

	public function clone() {
		const newNode = new this.constructor( this.value, this.uvNode, this.levelNode );
		newNode.sampler = this.sampler;

		return newNode;
	}
}

export default TextureNode;

export var texture = nodeProxy( TextureNode );
export var textureLoad = ( ...params ) => texture( ...params ).setSampler( false );

//export const textureLevel = ( value, uv, level ) => texture( value, uv ).level( level );

export var sampler = ( aTexture ) => ( aTexture.isNode === true ? aTexture : texture( aTexture ) ).convert( 'sampler' );

addNodeElement( 'texture', texture );
//addNodeElement( 'textureLevel', textureLevel );

addNodeClass( 'TextureNode', TextureNode );