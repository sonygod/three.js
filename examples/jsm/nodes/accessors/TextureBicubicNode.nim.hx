import TempNode from '../core/TempNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { add, mul, div } from '../math/OperatorNode.hx';
import { floor, ceil, fract, pow } from '../math/MathNode.hx';
import { nodeProxy, addNodeElement, float, vec2, vec4, int } from '../shadernode/ShaderNode.hx';

// Mipped Bicubic Texture Filtering by N8
// https://www.shadertoy.com/view/Dl2SDW

var bC = 1.0 / 6.0;

var w0 = ( a ) -> mul( bC, mul( a, mul( a, a.negate().add( 3.0 ) ).sub( 3.0 ) ).add( 1.0 ) );

var w1 = ( a ) -> mul( bC, mul( a, mul( a, mul( 3.0, a ).sub( 6.0 ) ) ).add( 4.0 ) );

var w2 = ( a ) -> mul( bC, mul( a, mul( a, mul( - 3.0, a ).add( 3.0 ) ).add( 3.0 ) ).add( 1.0 ) );

var w3 = ( a ) -> mul( bC, pow( a, 3 ) );

var g0 = ( a ) -> w0( a ).add( w1( a ) );

var g1 = ( a ) -> w2( a ).add( w3( a ) );

// h0 and h1 are the two offset functions
var h0 = ( a ) -> add( - 1.0, w1( a ).div( w0( a ).add( w1( a ) ) ) );

var h1 = ( a ) -> add( 1.0, w3( a ).div( w2( a ).add( w3( a ) ) ) );

var bicubic = ( textureNode, texelSize, lod ) -> {

	var uv = textureNode.uvNode;
	var uvScaled = mul( uv, texelSize.zw ).add( 0.5 );

	var iuv = floor( uvScaled );
	var fuv = fract( uvScaled );

	var g0x = g0( fuv.x );
	var g1x = g1( fuv.x );
	var h0x = h0( fuv.x );
	var h1x = h1( fuv.x );
	var h0y = h0( fuv.y );
	var h1y = h1( fuv.y );

	var p0 = vec2( iuv.x.add( h0x ), iuv.y.add( h0y ) ).sub( 0.5 ).mul( texelSize.xy );
	var p1 = vec2( iuv.x.add( h1x ), iuv.y.add( h0y ) ).sub( 0.5 ).mul( texelSize.xy );
	var p2 = vec2( iuv.x.add( h0x ), iuv.y.add( h1y ) ).sub( 0.5 ).mul( texelSize.xy );
	var p3 = vec2( iuv.x.add( h1x ), iuv.y.add( h1y ) ).sub( 0.5 ).mul( texelSize.xy );

	var a = g0( fuv.y ).mul( add( g0x.mul( textureNode.uv( p0 ).level( lod ) ), g1x.mul( textureNode.uv( p1 ).level( lod ) ) ) );
	var b = g1( fuv.y ).mul( add( g0x.mul( textureNode.uv( p2 ).level( lod ) ), g1x.mul( textureNode.uv( p3 ).level( lod ) ) ) );

	return a.add( b );

};

var textureBicubicMethod = ( textureNode, lodNode ) -> {

	var fLodSize = vec2( textureNode.size( int( lodNode ) ) );
	var cLodSize = vec2( textureNode.size( int( lodNode.add( 1.0 ) ) ) );
	var fLodSizeInv = div( 1.0, fLodSize );
	var cLodSizeInv = div( 1.0, cLodSize );
	var fSample = bicubic( textureNode, vec4( fLodSizeInv, fLodSize ), floor( lodNode ) );
	var cSample = bicubic( textureNode, vec4( cLodSizeInv, cLodSize ), ceil( lodNode ) );

	return fract( lodNode ).mix( fSample, cSample );

};

class TextureBicubicNode extends TempNode {

	public var textureNode:Dynamic;
	public var blurNode:Dynamic;

	public function new( textureNode:Dynamic, blurNode:Dynamic = float( 3 ) ) {

		super( 'vec4' );

		this.textureNode = textureNode;
		this.blurNode = blurNode;

	}

	public function setup():Dynamic {

		return textureBicubicMethod( this.textureNode, this.blurNode );

	}

}

export default TextureBicubicNode;

export var textureBicubic = nodeProxy( TextureBicubicNode );

addNodeElement( 'bicubic', textureBicubic );

addNodeClass( 'TextureBicubicNode', TextureBicubicNode );