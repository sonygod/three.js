import core.Node;
import core.TempNode;
import CameraNode;
import ModelNode;
import PositionNode;
import ShaderNode;
import core.VaryingNode;

class ModelViewProjectionNode extends TempNode {

	public var positionNode:Node;

	public function new(positionNode:Node = null) {
		super("vec4");
		this.positionNode = positionNode;
	}

	override public function setup(builder:Node.Builder):Node {
		if (builder.shaderStage == "fragment") {
			return VaryingNode.varying(builder.context.mvp);
		}

		var position = this.positionNode != null ? this.positionNode : PositionNode.positionLocal;

		return CameraNode.cameraProjectionMatrix.mul(ModelNode.modelViewMatrix).mul(position);
	}

}

class ModelViewProjectionProxy extends ShaderNode.ShaderNodeProxy {
	public function new() {
		super(ModelViewProjectionNode);
	}
}

public var modelViewProjection = new ModelViewProjectionProxy();

Node.addNodeClass("ModelViewProjectionNode", ModelViewProjectionNode);