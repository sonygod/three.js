class TreeViewInput extends Input {

	constructor( options = [] ) {

		const dom = document.createElement( 'f-treeview' );
		super( dom );

		const childrenDOM = document.createElement( 'f-treeview-children' );
		dom.append( childrenDOM );

		dom.setAttribute( 'type', 'tree' );

		this.childrenDOM = childrenDOM;

		this.children = [];

	}

	add( node ) {

		this.children.push( node );
		this.childrenDOM.append( node.dom );

		return this;

	}

	serialize( data ) {

		//data.options = [ ...this.options ];

		super.serialize( data );

	}

	deserialize( data ) {

		/*const currentOptions = this.options;

		if ( currentOptions.length === 0 ) {

			this.setOptions( data.options );

		}*/

		super.deserialize( data );

	}

}