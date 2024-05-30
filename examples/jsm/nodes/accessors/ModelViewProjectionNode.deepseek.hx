import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.accessors.CameraNode;
import three.js.examples.jsm.nodes.accessors.ModelNode;
import three.js.examples.jsm.nodes.accessors.PositionNode;
import three.js.examples.jsm.shadernode.ShaderNode;
import three.js.examples.jsm.core.VaryingNode;

class ModelViewProjectionNode extends TempNode {

	public function new( positionNode:Null<PositionNode> = null ) {

		super('vec4');

		this.positionNode = positionNode;

	}

	public function setup( builder:ShaderNode.Builder ) {

		if ( builder.shaderStage === 'fragment' ) {

			return VaryingNode.varying( builder.context.mvp );

		}

		var position = this.positionNode != null ? this.positionNode : PositionNode.positionLocal;

		return CameraNode.cameraProjectionMatrix.mul( ModelNode.modelViewMatrix ).mul( position );

	}

}

static public var modelViewProjection:ShaderNode.NodeProxy<ModelViewProjectionNode> = ShaderNode.nodeProxy( ModelViewProjectionNode );

Node.addNodeClass( 'ModelViewProjectionNode', ModelViewProjectionNode );