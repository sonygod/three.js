import NodeMaterial from './NodeMaterial.hx';
import { addNodeMaterial } from './NodeMaterial.hx';
import { uniform } from '../core/UniformNode.hx';
import { cameraProjectionMatrix } from '../accessors/CameraNode.hx';
import { materialRotation } from '../accessors/MaterialNode.hx';
import { modelViewMatrix, modelWorldMatrix } from '../accessors/ModelNode.hx';
import { positionLocal } from '../accessors/PositionNode.hx';
import { FloatNode, Vec2Node, Vec3Node, Vec4Node } from '../shadernode/ShaderNode.hx';

import SpriteMaterial from 'three/src/materials/SpriteMaterial';

var defaultValues = new SpriteMaterial();

class SpriteNodeMaterial extends NodeMaterial {

	public var isSpriteNodeMaterial:Bool = true;
	public var lights:Bool;
	public var normals:Bool;
	public var positionNode:FloatNode;
	public var rotationNode:FloatNode;
	public var scaleNode:Vec2Node;

	public function new( parameters:Dynamic ) {
		super();
		this.lights = false;
		this.normals = false;
		this.setDefaultValues( defaultValues );
		this.setValues( parameters );
	}

	public function setupPosition( { object, context }: { object:Dynamic, context:Dynamic } ) : Void {

		// < VERTEX STAGE >

		var positionNode = this.positionNode;
		var rotationNode = this.rotationNode;
		var scaleNode = this.scaleNode;

		var vertex = positionLocal;

		var mvPosition = modelViewMatrix.mul( Vec3Node.fromScalar( positionNode as Float, 0.0 ) );

		var scale = Vec2Node.fromScalars( modelWorldMatrix[ 0 ].xyz.length(), modelWorldMatrix[ 1 ].xyz.length() );

		if ( scaleNode != null ) {

			scale = scale.mul( scaleNode );

		}

		var alignedPosition = vertex.xy;

		if ( object.center != null && object.center.isVector2 ) {

			alignedPosition = alignedPosition.sub( uniform( object.center ).sub( 0.5 ) );

		}

		alignedPosition = alignedPosition.mul( scale );

		var rotation = FloatNode.fromFloat( rotationNode as Float, materialRotation as Float );

		var rotatedPosition = alignedPosition.rotate( rotation );

		mvPosition = Vec4Node.fromVec2( mvPosition.xy.add( rotatedPosition ), mvPosition.zw );

		var modelViewProjection = cameraProjectionMatrix.mul( mvPosition );

		context.vertex = vertex;

		return modelViewProjection;

	}

	public function copy( source:SpriteNodeMaterial ) : SpriteNodeMaterial {

		this.positionNode = source.positionNode;
		this.rotationNode = source.rotationNode;
		this.scaleNode = source.scaleNode;

		return super.copy( source );

	}

}

@:expose
class SpriteNodeMaterialExt {
	public static function __init__() {
		addNodeMaterial( 'SpriteNodeMaterial', SpriteNodeMaterial );
	}
}