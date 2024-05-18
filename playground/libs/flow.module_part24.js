class TreeViewNode {

	constructor( name = '' ) {

		const dom = document.createElement( 'f-treeview-node' );
		const labelDOM = document.createElement( 'f-treeview-label' );
		const inputDOM = document.createElement( 'input' );

		const labelSpam = document.createElement( 'spam' );
		labelDOM.append( labelSpam );

		labelSpam.innerText = name;

		inputDOM.type = 'checkbox';

		dom.append( inputDOM );
		dom.append( labelDOM );

		this.dom = dom;
		this.childrenDOM = null;
		this.labelSpam = labelSpam;
		this.labelDOM = labelDOM;
		this.inputDOM = inputDOM;
		this.iconDOM = null;

		this.parent = null;
		this.children = [];

		this.selected = false;

		this.events = {
			'change': [],
			'click': []
		};

		dom.addEventListener( 'click', ( ) => {

			dispatchEventList( this.events.click, this );

		} );

	}

	setLabel( value ) {

		this.labelSpam.innerText = value;

		return this;

	}

	getLabel() {

		return this.labelSpam.innerText;

	}

	add( node ) {

		let childrenDOM = this.childrenDOM;

		if ( this.childrenDOM === null ) {

			const dom = this.dom;

			const arrowDOM = document.createElement( 'f-arrow' );
			childrenDOM = document.createElement( 'f-treeview-children' );

			dom.append( arrowDOM );
			dom.append( childrenDOM );

			this.childrenDOM = childrenDOM;

		}

		this.children.push( node );
		childrenDOM.append( node.dom );

		node.parent = this;

		return this;

	}

	setOpened( value ) {

		this.inputDOM.checked = value;

		return this;

	}

	getOpened() {

		return this.inputDOM.checkbox;

	}

	setIcon( value ) {

		this.iconDOM = this.iconDOM || document.createElement( 'i' );
		this.iconDOM.className = value;

		if ( value ) this.labelDOM.prepend( this.iconDOM );
		else this.iconDOM.remove();

		return this;

	}

	getIcon() {

		return this.iconDOM ? this.iconDOM.className : null;

	}

	setVisible( value ) {

		this.dom.style.display = value ? '' : 'none';

		return this;

	}

	setSelected( value ) {

		if ( this.selected === value ) return this;

		if ( value ) this.dom.classList.add( 'selected' );
		else this.dom.classList.remove( 'selected' );

		this.selected = value;

		return this;

	}

	onClick( callback ) {

		this.events.click.push( callback );

		return this;

	}

}