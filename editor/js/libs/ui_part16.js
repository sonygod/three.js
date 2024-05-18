class UIButton extends UIElement {

	constructor( value ) {

		super( document.createElement( 'button' ) );

		this.dom.className = 'Button';
		this.dom.textContent = value;

	}

}