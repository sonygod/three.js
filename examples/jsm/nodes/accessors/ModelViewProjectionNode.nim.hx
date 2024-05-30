import three.examples.jsm.nodes.core.Node.addNodeClass;
import three.examples.jsm.nodes.core.TempNode;
import three.examples.jsm.nodes.accessors.CameraNode.cameraProjectionMatrix;
import three.examples.jsm.nodes.accessors.ModelNode.modelViewMatrix;
import three.examples.jsm.nodes.accessors.PositionNode.positionLocal;
import three.examples.jsm.nodes.shadernode.ShaderNode.nodeProxy;
import three.examples.jsm.nodes.core.VaryingNode.varying;

class ModelViewProjectionNode extends TempNode {

	public var positionNode:Null<Dynamic>;

	public function new( positionNode:Null<Dynamic> = null ) {

		super('vec4');

		this.positionNode = positionNode;

	}

	public function setup( builder:Dynamic ) {

		if ( builder.shaderStage == 'fragment' ) {

			return varying( builder.context.mvp );

		}

		var position:Dynamic = this.positionNode ?? positionLocal;

		return cameraProjectionMatrix.mul( modelViewMatrix ).mul( position );

	}

}

export default ModelViewProjectionNode;

export var modelViewProjection:Dynamic = nodeProxy( ModelViewProjectionNode );

addNodeClass( 'ModelViewProjectionNode', ModelViewProjectionNode );