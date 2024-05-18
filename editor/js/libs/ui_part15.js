class UIHorizontalRule extends UIElement {

	constructor() {

		super( document.createElement( 'hr' ) );

		this.dom.className = 'HorizontalRule';

	}

}