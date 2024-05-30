import Node, { addNodeClass } from '../core/Node.hx';
import { NodeUpdateType } from '../core/constants.hx';
import UniformNode from '../core/UniformNode.hx';
import { nodeProxy } from '../shadernode/ShaderNode.hx';

import Vector3 from 'three';

class Object3DNode extends Node {

	public var scope:String;
	public var object3d:Dynamic;

	public var updateType:NodeUpdateType;

	private var _uniformNode:UniformNode;

	public function new( scope:String = Object3DNode.VIEW_MATRIX, object3d:Dynamic = null ) {

		super();

		this.scope = scope;
		this.object3d = object3d;

		this.updateType = NodeUpdateType.OBJECT;

		this._uniformNode = new UniformNode( null );

	}

	public function getNodeType():String {

		const scope = this.scope;

		if ( scope === Object3DNode.WORLD_MATRIX || scope === Object3DNode.VIEW_MATRIX ) {

			return 'mat4';

		} else if ( scope === Object3DNode.NORMAL_MATRIX ) {

			return 'mat3';

		} else if ( scope === Object3DNode.POSITION || scope === Object3DNode.VIEW_POSITION || scope === Object3DNode.DIRECTION || scope === Object3DNode.SCALE ) {

			return 'vec3';

		}

	}

	public function update( frame:Dynamic ) {

		const object = this.object3d;
		const uniformNode = this._uniformNode;
		const scope = this.scope;

		if ( scope === Object3DNode.VIEW_MATRIX ) {

			uniformNode.value = object.modelViewMatrix;

		} else if ( scope === Object3DNode.NORMAL_MATRIX ) {

			uniformNode.value = object.normalMatrix;

		} else if ( scope === Object3DNode.WORLD_MATRIX ) {

			uniformNode.value = object.matrixWorld;

		} else if ( scope === Object3DNode.POSITION ) {

			uniformNode.value = uniformNode.value || new Vector3();

			uniformNode.value.setFromMatrixPosition( object.matrixWorld );

		} else if ( scope === Object3DNode.SCALE ) {

			uniformNode.value = uniformNode.value || new Vector3();

			uniformNode.value.setFromMatrixScale( object.matrixWorld );

		} else if ( scope === Object3DNode.DIRECTION ) {

			uniformNode.value = uniformNode.value || new Vector3();

			object.getWorldDirection( uniformNode.value );

		} else if ( scope === Object3DNode.VIEW_POSITION ) {

			const camera = frame.camera;

			uniformNode.value = uniformNode.value || new Vector3();
			uniformNode.value.setFromMatrixPosition( object.matrixWorld );

			uniformNode.value.applyMatrix4( camera.matrixWorldInverse );

		}

	}

	public function generate( builder:Dynamic ) {

		const scope = this.scope;

		if ( scope === Object3DNode.WORLD_MATRIX || scope === Object3DNode.VIEW_MATRIX ) {

			this._uniformNode.nodeType = 'mat4';

		} else if ( scope === Object3DNode.NORMAL_MATRIX ) {

			this._uniformNode.nodeType = 'mat3';

		} else if ( scope === Object3DNode.POSITION || scope === Object3DNode.VIEW_POSITION || scope === Object3DNode.DIRECTION || scope === Object3DNode.SCALE ) {

			this._uniformNode.nodeType = 'vec3';

		}

		return this._uniformNode.build( builder );

	}

	public function serialize( data:Dynamic ) {

		super.serialize( data );

		data.scope = this.scope;

	}

	public function deserialize( data:Dynamic ) {

		super.deserialize( data );

		this.scope = data.scope;

	}

}

Object3DNode.VIEW_MATRIX = 'viewMatrix';
Object3DNode.NORMAL_MATRIX = 'normalMatrix';
Object3DNode.WORLD_MATRIX = 'worldMatrix';
Object3DNode.POSITION = 'position';
Object3DNode.SCALE = 'scale';
Object3DNode.VIEW_POSITION = 'viewPosition';
Object3DNode.DIRECTION = 'direction';

export default Object3DNode;

export const objectDirection = nodeProxy( Object3DNode, Object3DNode.DIRECTION );
export const objectViewMatrix = nodeProxy( Object3DNode, Object3DNode.VIEW_MATRIX );
export const objectNormalMatrix = nodeProxy( Object3DNode, Object3DNode.NORMAL_MATRIX );
export const objectWorldMatrix = nodeProxy( Object3DNode, Object3DNode.WORLD_MATRIX );
export const objectPosition = nodeProxy( Object3DNode, Object3DNode.POSITION );
export const objectScale = nodeProxy( Object3DNode, Object3DNode.SCALE );
export const objectViewPosition = nodeProxy( Object3DNode, Object3DNode.VIEW_POSITION );

addNodeClass( 'Object3DNode', Object3DNode );