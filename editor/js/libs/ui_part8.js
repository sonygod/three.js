class UITextArea extends UIElement {

	constructor() {

		super( document.createElement( 'textarea' ) );

		this.dom.className = 'TextArea';
		this.dom.style.padding = '2px';
		this.dom.spellcheck = false;

		this.dom.setAttribute( 'autocomplete', 'off' );

		this.dom.addEventListener( 'keydown', function ( event ) {

			event.stopPropagation();

			if ( event.code === 'Tab' ) {

				event.preventDefault();

				const cursor = this.selectionStart;

				this.value = this.value.substring( 0, cursor ) + '\t' + this.value.substring( cursor );
				this.selectionStart = cursor + 1;
				this.selectionEnd = this.selectionStart;

			}

		} );

	}

	getValue() {

		return this.dom.value;

	}

	setValue( value ) {

		this.dom.value = value;

		return this;

	}

}