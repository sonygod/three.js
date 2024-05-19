class GLTFWriter {

	public var plugins:Array<Dynamic>;
	public var options:Dynamic;
	public var pending:Array<Dynamic>;
	public var buffers:Array<ArrayBuffer>;

	public var byteOffset:Int;
	public var nodeMap:Map<Dynamic, Int>;
	public var skins:Array<Dynamic>;

	public var extensionsUsed:Dynamic;
	public var extensionsRequired:Dynamic;

	public var uids:Map<Dynamic, Map<Dynamic, Int>>;
	public var uid:Int;

	public var json:Dynamic;
	public var cache:Dynamic;

	public function new() {
		this.plugins = [];
		this.options = {};
		this.pending = [];
		this.buffers = [];
		this.byteOffset = 0;
		this.nodeMap = new Map<Dynamic, Int>();
		this.skins = [];
		this.extensionsUsed = {};
		this.extensionsRequired = {};
		this.uids = new Map<Dynamic, Map<Dynamic, Int>>();
		this.uid = 0;
		this.json = {
			asset: {
				version: '2.0',
				generator: 'THREE.GLTFExporter r' + REVISION
			}
		};
		this.cache = {
			meshes: new Map<Dynamic, Dynamic>(),
			attributes: new Map<Dynamic, Dynamic>(),
			attributesNormalized: new Map<Dynamic, Dynamic>(),
			materials: new Map<Dynamic, Dynamic>(),
			textures: new Map<Dynamic, Dynamic>(),
			images: new Map<Dynamic, Dynamic>()
		};
	}

	public function setPlugins(plugins:Array<Dynamic>) {
		this.plugins = plugins;
	}

	/**
	 * Parse scenes and generate GLTF output
	 * @param  {Scene or [THREE.Scenes]} input   Scene or Array of THREE.Scenes
	 * @param  {Function} onDone  Callback on completed
	 * @param  {Object} options options
	 */
	public async function write(input:Dynamic, onDone:Dynamic, options:Dynamic = {}) {
		this.options = Object.assign( {
			// default options
			binary: false,
			trs: false,
			onlyVisible: true,
			maxTextureSize: Int.MAX_VALUE,
			animations: [],
			includeCustomExtensions: false
		}, options );

		if (this.options.animations.length > 0) {

			// Only TRS properties, and not matrices, may be targeted by animation.
			this.options.trs = true;

		}

		this.processInput(input);

		await Promise.all(this.pending);

		var writer = this;
		var buffers = writer.buffers;
		var json = writer.json;
		var options = writer.options;

		var extensionsUsed = writer.extensionsUsed;
		var extensionsRequired = writer.extensionsRequired;

		// Merge buffers.
		var blob = new Blob(buffers, { type: 'application/octet-stream' });

		// Declare extensions.
		var extensionsUsedList = Object.keys(extensionsUsed);
		var extensionsRequiredList = Object.keys(extensionsRequired);

		if (extensionsUsedList.length > 0) json.extensionsUsed = extensionsUsedList;
		if (extensionsRequiredList.length > 0) json.extensionsRequired = extensionsRequiredList;

		// Update bytelength of the single buffer.
		if (json.buffers && json.buffers.length > 0) json.buffers[0].byteLength = blob.size;

		if (options.binary === true) {

			// https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#glb-file-format-specification

			var reader = new FileReader();
			reader.readAsArrayBuffer(blob);
			reader.onloadend = function () {

				// Binary chunk.
				var binaryChunk = getPaddedArrayBuffer(reader.result);
				var binaryChunkPrefix = new DataView(new ArrayBuffer(GLB_CHUNK_PREFIX_BYTES));
				binaryChunkPrefix.setUint32(0, binaryChunk.byteLength, true);
				binaryChunkPrefix.setUint32(4, GLB_CHUNK_TYPE_BIN, true);

				// JSON chunk.
				var jsonChunk = getPaddedArrayBuffer(stringToArrayBuffer(JSON.stringify(json)), 0x20);
				var jsonChunkPrefix = new DataView(new ArrayBuffer(GLB_CHUNK_PREFIX_BYTES));
				jsonChunkPrefix.setUint32(0, jsonChunk.byteLength, true);
				jsonChunkPrefix.setUint32(4, GLB_CHUNK_TYPE_JSON, true);

				// GLB header.
				var header = new ArrayBuffer(GLB_HEADER_BYTES);
				var headerView = new DataView(header);
				headerView.setUint32(0, GLB_HEADER_MAGIC, true);
				headerView.setUint32(4, GLB_VERSION, true);
				var totalByteLength = GLB_HEADER_BYTES + jsonChunkPrefix.byteLength + jsonChunk.byteLength + binaryChunkPrefix.byteLength + binaryChunk.byteLength;
				headerView.setUint32(8, totalByteLength, true);

				var glbBlob = new Blob(