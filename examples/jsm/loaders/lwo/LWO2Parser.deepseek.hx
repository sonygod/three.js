class LWO2Parser {

	var IFF:IFFParser;

	public function new(IFFParser) {
		this.IFF = IFFParser;
	}

	public function parseBlock() {

		this.IFF.debugger.offset = this.IFF.reader.offset;
		this.IFF.debugger.closeForms();

		var blockID = this.IFF.reader.getIDTag();
		var length = this.IFF.reader.getUint32(); // size of data in bytes
		if (length > this.IFF.reader.dv.byteLength - this.IFF.reader.offset) {

			this.IFF.reader.offset -= 4;
			length = this.IFF.reader.getUint16();

		}

		this.IFF.debugger.dataOffset = this.IFF.reader.offset;
		this.IFF.debugger.length = length;

		switch (blockID) {

			case 'FORM': // form blocks may consist of sub -chunks or sub-forms
				this.IFF.parseForm(length);
				break;

			// SKIPPED CHUNKS
			// MISC skipped
			// normal maps can be specified, normally on models imported from other applications. Currently ignored
			// Image Map Layer skipped
			// Procedural Textures skipped
			// Gradient Textures skipped
			// Texture Mapping Form skipped
			// Surface CHUNKs skipped
			// Car Material CHUNKS
			// Texture node chunks (not in spec)
			// Misc CHUNKS
			// LWO2 Spec chunks: these are needed since the SURF FORMs are often in LWO2 format
			// LWO2 USE
			// BLOK
			// default

			default:
				this.IFF.parseUnknownCHUNK(blockID, length);

		}

		if (blockID != 'FORM') {

			this.IFF.debugger.node = 1;
			this.IFF.debugger.nodeID = blockID;
			this.IFF.debugger.log();

		}

		if (this.IFF.reader.offset >= this.IFF.currentFormEnd) {

			this.IFF.currentForm = this.IFF.parentForm;

		}

	}

}