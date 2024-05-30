import three.examples.jsm.nodes.materials.NodeMaterial;
import three.examples.jsm.nodes.accessors.NormalNode;
import three.examples.jsm.nodes.accessors.PositionNode;
import three.examples.jsm.nodes.functions.PhysicalLightingModel;
import three.examples.jsm.nodes.materials.MeshPhysicalNodeMaterial;
import three.examples.jsm.shadernode.ShaderNode;

class SSSLightingModel extends PhysicalLightingModel {

	public var useSSS:Bool;

	public function new( useClearcoat:Bool, useSheen:Bool, useIridescence:Bool, useSSS:Bool ) {

		super( useClearcoat, useSheen, useIridescence );

		this.useSSS = useSSS;

	}

	public function direct( lightDirection:Dynamic, lightColor:Dynamic, reflectedLight:Dynamic, stack:Dynamic, builder:Dynamic ) {

		if ( this.useSSS ) {

			var material = builder.material;

			var thicknessColorNode = material.thicknessColorNode;
			var thicknessDistortionNode = material.thicknessDistortionNode;
			var thicknessAmbientNode = material.thicknessAmbientNode;
			var thicknessAttenuationNode = material.thicknessAttenuationNode;
			var thicknessPowerNode = material.thicknessPowerNode;
			var thicknessScaleNode = material.thicknessScaleNode;

			var scatteringHalf = lightDirection.add( NormalNode.transformedNormalView.mul( thicknessDistortionNode ) ).normalize();
			var scatteringDot = ShaderNode.float( PositionNode.positionViewDirection.dot( scatteringHalf.negate() ).saturate().pow( thicknessPowerNode ).mul( thicknessScaleNode ) );
			var scatteringIllu = ShaderNode.vec3( scatteringDot.add( thicknessAmbientNode ).mul( thicknessColorNode ) );

			reflectedLight.directDiffuse.addAssign( scatteringIllu.mul( thicknessAttenuationNode.mul( lightColor ) ) );

		}

		super.direct( lightDirection, lightColor, reflectedLight, stack, builder );

	}

}

class MeshSSSNodeMaterial extends MeshPhysicalNodeMaterial {

	public var thicknessColorNode:Dynamic;
	public var thicknessDistortionNode:Dynamic;
	public var thicknessAmbientNode:Dynamic;
	public var thicknessAttenuationNode:Dynamic;
	public var thicknessPowerNode:Dynamic;
	public var thicknessScaleNode:Dynamic;

	public function new( parameters:Dynamic ) {

		super( parameters );

		this.thicknessColorNode = null;
		this.thicknessDistortionNode = ShaderNode.float( 0.1 );
		this.thicknessAmbientNode = ShaderNode.float( 0.0 );
		this.thicknessAttenuationNode = ShaderNode.float( .1 );
		this.thicknessPowerNode = ShaderNode.float( 2.0 );
		this.thicknessScaleNode = ShaderNode.float( 10.0 );

	}

	public function get useSSS() {

		return this.thicknessColorNode != null;

	}

	public function setupLightingModel( builder:Dynamic ) {

		return new SSSLightingModel( this.useClearcoat, this.useSheen, this.useIridescence, this.useSSS );

	}

	public function copy( source:Dynamic ) {

		this.thicknessColorNode = source.thicknessColorNode;
		this.thicknessDistortionNode = source.thicknessDistortionNode;
		this.thicknessAmbientNode = source.thicknessAmbientNode;
		this.thicknessAttenuationNode = source.thicknessAttenuationNode;
		this.thicknessPowerNode = source.thicknessPowerNode;
		this.thicknessScaleNode = source.thicknessScaleNode;

		return super.copy( source );

	}

}

NodeMaterial.addNodeMaterial( 'MeshSSSNodeMaterial', MeshSSSNodeMaterial );