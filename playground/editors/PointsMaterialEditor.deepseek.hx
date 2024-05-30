import flow.ColorInput;
import flow.ToggleInput;
import flow.SliderInput;
import flow.LabelElement;
import three.nodes.PointsNodeMaterial;
import three.THREE;
import DataTypeLib.setInputAestheticsFromType;

class PointsMaterialEditor extends MaterialEditor {

	public function new() {

		var material = new PointsNodeMaterial();

		super( 'Points Material', material );

		var color = setInputAestheticsFromType( new LabelElement( 'color' ), 'Color' );
		var opacity = setInputAestheticsFromType( new LabelElement( 'opacity' ), 'Number' );
		var size = setInputAestheticsFromType( new LabelElement( 'size' ), 'Number' );
		var position = setInputAestheticsFromType( new LabelElement( 'position' ), 'Vector3' );
		var sizeAttenuation = setInputAestheticsFromType( new LabelElement( 'Size Attenuation' ), 'Number' );

		color.add( new ColorInput( material.color.getHex() ).onChange( function(input) {

			material.color.setHex( input.getValue() );

		} ) );

		opacity.add( new SliderInput( material.opacity, 0, 1 ).onChange( function(input) {

			material.opacity = input.getValue();

			this.updateTransparent();

		} ) );

		sizeAttenuation.add( new ToggleInput( material.sizeAttenuation ).onClick( function(input) {

			material.sizeAttenuation = input.getValue();
			material.dispose();

		} ) );

		color.onConnect( function() { this.update(); }, true );
		opacity.onConnect( function() { this.update(); }, true );
		size.onConnect( function() { this.update(); }, true );
		position.onConnect( function() { this.update(); }, true );

		this.add( color )
			.add( opacity )
			.add( size )
			.add( position )
			.add( sizeAttenuation );

		this.color = color;
		this.opacity = opacity;
		this.size = size;
		this.position = position;
		this.sizeAttenuation = sizeAttenuation;

		this.update();

	}

	public function update() {

		var material = this.material;
		var color = this.color;
		var opacity = this.opacity;
		var size = this.size;
		var position = this.position;

		color.setEnabledInputs( ! color.getLinkedObject() );
		opacity.setEnabledInputs( ! opacity.getLinkedObject() );

		material.colorNode = color.getLinkedObject();
		material.opacityNode = opacity.getLinkedObject() || null;

		material.sizeNode = size.getLinkedObject() || null;
		material.positionNode = position.getLinkedObject() || null;

		material.dispose();

		this.updateTransparent();

		// TODO: Fix on NodeMaterial System
		material.customProgramCacheKey = function() {

			return THREE.MathUtils.generateUUID();

		};

	}

	public function updateTransparent() {

		var material = this.material;
		var opacity = this.opacity;

		material.transparent = opacity.getLinkedObject() || material.opacity < 1 ? true : false;

		opacity.setIcon( material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract' );

	}

}