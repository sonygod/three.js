class PureArrayUniform {

	constructor( id, activeInfo, addr ) {

		this.id = id;
		this.addr = addr;
		this.cache = [];
		this.type = activeInfo.type;
		this.size = activeInfo.size;
		this.setValue = getPureArraySetter( activeInfo.type );

		// this.path = activeInfo.name; // DEBUG

	}

}