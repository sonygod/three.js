import Object3DNode from './Object3DNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { nodeImmutable } from '../shadernode/ShaderNode.hx';

class ModelNode extends Object3DNode {

	public function new( scope = ModelNode.VIEW_MATRIX ) {

		super( scope );

	}

	public function update( frame ) {

		this.object3d = frame.object;

		super.update( frame );

	}

}

export default ModelNode;

export const modelDirection = nodeImmutable( ModelNode, ModelNode.DIRECTION );
export const modelViewMatrix = nodeImmutable( ModelNode, ModelNode.VIEW_MATRIX ).label( 'modelViewMatrix' ).temp( 'ModelViewMatrix' );
export const modelNormalMatrix = nodeImmutable( ModelNode, ModelNode.NORMAL_MATRIX );
export const modelWorldMatrix = nodeImmutable( ModelNode, ModelNode.WORLD_MATRIX );
export const modelPosition = nodeImmutable( ModelNode, ModelNode.POSITION );
export const modelScale = nodeImmutable( ModelNode, ModelNode.SCALE );
export const modelViewPosition = nodeImmutable( ModelNode, ModelNode.VIEW_POSITION );

addNodeClass( 'ModelNode', ModelNode );