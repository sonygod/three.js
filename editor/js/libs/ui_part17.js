class UIProgress extends UIElement {

	constructor( value ) {

		super( document.createElement( 'progress' ) );

		this.dom.value = value;

	}

	setValue( value ) {

		this.dom.value = value;

	}

}