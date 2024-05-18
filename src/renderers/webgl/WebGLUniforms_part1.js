class SingleUniform {

	constructor( id, activeInfo, addr ) {

		this.id = id;
		this.addr = addr;
		this.cache = [];
		this.type = activeInfo.type;
		this.setValue = getSingularSetter( activeInfo.type );

		// this.path = activeInfo.name; // DEBUG

	}

}