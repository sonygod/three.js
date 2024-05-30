import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.Node.addNodeClass;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.addNodeElement;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.nodeProxy;

class TextureSizeNode extends Node {

	public function new( textureNode:Dynamic, levelNode:Dynamic = null ) {

		super( 'uvec2' );

		this.isTextureSizeNode = true;

		this.textureNode = textureNode;
		this.levelNode = levelNode;

	}

	public function generate( builder:Dynamic, output:Dynamic ) {

		var textureProperty = this.textureNode.build( builder, 'property' );
		var levelNode = this.levelNode.build( builder, 'int' );

		return builder.format( `${ builder.getMethod( 'textureDimensions' ) }( ${ textureProperty }, ${ levelNode } )`, this.getNodeType( builder ), output );

	}

}

static var textureSize = nodeProxy( TextureSizeNode );

addNodeElement( 'textureSize', textureSize );

addNodeClass( 'TextureSizeNode', TextureSizeNode );