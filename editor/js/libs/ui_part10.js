class UICheckbox extends UIElement {

	constructor( boolean ) {

		super( document.createElement( 'input' ) );

		this.dom.className = 'Checkbox';
		this.dom.type = 'checkbox';

		this.dom.addEventListener( 'pointerdown', function ( event ) {

			// Workaround for TransformControls blocking events in Viewport.Controls checkboxes

			event.stopPropagation();

		} );

		this.setValue( boolean );

	}

	getValue() {

		return this.dom.checked;

	}

	setValue( value ) {

		if ( value !== undefined ) {

			this.dom.checked = value;

		}

		return this;

	}

}