class GLTFParser {

	public function new(json?:Dynamic, options?:Dynamic) {
		this.json = json;
		this.extensions = {};
		this.plugins = {};
		this.options = options;
		this.cache = new GLTFRegistry();
		this.associations = new Map<Dynamic, Dynamic>();
		this.primitiveCache = {};
		this.nodeCache = {};
		this.meshCache = { refs:{}, uses:{}};
		this.cameraCache = { refs:{}, uses:{}};
		this.lightCache = { refs:{}, uses:{}};
		this.sourceCache = {};
		this.textureCache = {};
		this.nodeNamesUsed = {};
		this.isSafari = false;
		this.isFirefox = false;
		this.firefoxVersion = -1;
		if (typeof navigator !== 'undefined') {
			this.isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent) === true;
			this.isFirefox = navigator.userAgent.indexOf('Firefox') > -1;
			this.firefoxVersion = this.isFirefox ? navigator.userAgent.match(/Firefox\/([0-9]+)\./)[1] : -1;
		}
		if (typeof createImageBitmap === 'undefined' || this.isSafari || (this.isFirefox && this.firefoxVersion < 98)) {
			this.textureLoader = new TextureLoader(this.options.manager);
		} else {
			this.textureLoader = new ImageBitmapLoader(this.options.manager);
		}
		this.textureLoader.setCrossOrigin(this.options.crossOrigin);
		this.textureLoader.setRequestHeader(this.options.requestHeader);
		this.fileLoader = new FileLoader(this.options.manager);
		this.fileLoader.setResponseType('arraybuffer');
		this.fileLoader.setWithCredentials(this.options.crossOrigin === 'use-credentials');
	}

	public function setExtensions(extensions:Dynamic) {
		this.extensions = extensions;
	}

	public function setPlugins(plugins:Dynamic) {
		this.plugins = plugins;
	}

	public function parse(onLoad:Dynamic, onError:Dynamic) {
		//...
	}

	//...

	public function _invokeAll(func:Dynamic):Array<Dynamic> {
		//...
	}

	public function _invokeOne(func:Dynamic):Dynamic {
		//...
	}

	public function _markDefs() {
		//...
	}

	public function _addNodeRef(cache:Dynamic, index:Int) {
		//...
	}

	public function _getNodeRef(cache:Dynamic, index:Int, object:Dynamic):Dynamic {
		//...
	}

	public function _invokeOne(func:Dynamic):Dynamic {
		//...
	}

	public function _invokeAll(func:Dynamic):Array<Dynamic> {
		//...
	}

	public function getDependency(type:String, index:Int):Dynamic {
		//...
	}

	public function getDependencies(type:String):Array<Dynamic> {
		//...
	}

	public function loadBuffer(bufferIndex:Int):Promise<ArrayBuffer> {
		//...
	}

	public function loadBufferView(bufferViewIndex:Int):Promise<ArrayBuffer> {
		//...
	}

	public function loadAccessor(accessorIndex:Int):Promise<BufferAttribute> {
		//...
	}

	public function loadTexture(textureIndex:Int):Promise<Texture> {
		//...
	}

	public function loadTextureImage(textureIndex:Int, sourceIndex:Int, loader:Dynamic):Promise<Texture> {
		//...
	}

	public function loadImageSource(sourceIndex:Int, loader:Dynamic):Promise<HTMLImageElement> {
		//...
	}

	public function assignTexture(materialParams:Dynamic, mapName:String, mapDef:Dynamic, colorSpace:Dynamic):Promise<Texture> {
		//...
	}

	public function assignFinalMaterial(mesh:Object3D) {
		//...
	}

	public function getMaterialType(materialIndex:Int):Dynamic {
		//...
	}

	public function loadMaterial(materialIndex:Int):Promise<Material> {
		//...
	}

	public function createUniqueName(originalName:String):String {
		//...
	}

	public function loadGeometries(primitives:Array<Dynamic>):Promise<Array<BufferGeometry>> {
		//...
	}

	public function loadMesh(meshIndex:Int):Promise<Group|Mesh|SkinnedMesh> {
		//...
	}

	public function loadCamera(cameraIndex:Int):Promise<Camera> {
		//...
	}

	public function loadSkin(skinIndex:Int):Promise<Skeleton> {
		//...
	}

	public function loadAnimation(animationIndex:Int):Promise<AnimationClip> {
		//...
	}

	public function _loadNodeShallow(nodeIndex:Int):Promise<Object3D> {
		//...
	}

	public function _createAnimationTracks(node:Object3D, inputAccessor:Dynamic, outputAccessor:Dynamic, sampler:Dynamic, target:Dynamic):Array<AnimationTrack> {
		//...
	}

	public function _getArrayFromAccessor(accessor:Dynamic):Array<Dynamic> {
		//...
	}

	public function _createCubicSplineTrackInterpolant(track:AnimationTrack) {
		//...
	}

}