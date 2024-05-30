import three.EventDispatcher;
import three.MathUtils;
import NodeUtils.getNodeChildren;
import NodeUtils.getCacheKey;
import constants.NodeUpdateType;

class Node extends EventDispatcher {

	var nodeType:Null<String>;
	var updateType:NodeUpdateType;
	var updateBeforeType:NodeUpdateType;
	var uuid:String;
	var version:Int;
	var _cacheKey:Null<String>;
	var _cacheKeyVersion:Int;
	var isNode:Bool = true;
	var id:Int;

	public function new(nodeType:Null<String> = null) {
		super();
		this.nodeType = nodeType;
		this.updateType = NodeUpdateType.NONE;
		this.updateBeforeType = NodeUpdateType.NONE;
		this.uuid = MathUtils.generateUUID();
		this.version = 0;
		this._cacheKey = null;
		this._cacheKeyVersion = 0;
		this.id = _nodeId++;
	}

	public function set needsUpdate(value:Bool) {
		if (value == true) {
			this.version++;
		}
	}

	public inline function get type():String {
		return this.constructor.type;
	}

	public function onUpdate(callback:Dynamic->Void, updateType:NodeUpdateType):Node {
		this.updateType = updateType;
		this.update = callback.bind(this.getSelf());
		return this;
	}

	public function onFrameUpdate(callback:Dynamic->Void):Node {
		return this.onUpdate(callback, NodeUpdateType.FRAME);
	}

	public function onRenderUpdate(callback:Dynamic->Void):Node {
		return this.onUpdate(callback, NodeUpdateType.RENDER);
	}

	public function onObjectUpdate(callback:Dynamic->Void):Node {
		return this.onUpdate(callback, NodeUpdateType.OBJECT);
	}

	public function onReference(callback:Dynamic->Void):Node {
		this.updateReference = callback.bind(this.getSelf());
		return this;
	}

	public inline function getSelf():Dynamic {
		return this.self ? this.self : this;
	}

	public function updateReference(state:Dynamic):Node {
		return this;
	}

	public function isGlobal(builder:Dynamic):Bool {
		return false;
	}

	public function getChildren():Iterator<Dynamic> {
		for (childNode in getNodeChildren(this)) {
			yield childNode;
		}
	}

	public function dispose():Void {
		this.dispatchEvent({type: 'dispose'});
	}

	public function traverse(callback:Dynamic->Void):Void {
		callback(this);
		for (childNode in this.getChildren()) {
			childNode.traverse(callback);
		}
	}

	public function getCacheKey(force:Bool = false):String {
		force = force || this.version != this._cacheKeyVersion;
		if (force || this._cacheKey == null) {
			this._cacheKey = getCacheKey(this, force);
			this._cacheKeyVersion = this.version;
		}
		return this._cacheKey;
	}

	public function getHash(builder:Dynamic):String {
		return this.uuid;
	}

	public function getUpdateType():NodeUpdateType {
		return this.updateType;
	}

	public function getUpdateBeforeType():NodeUpdateType {
		return this.updateBeforeType;
	}

	public function getNodeType(builder:Dynamic):String {
		var nodeProperties = builder.getNodeProperties(this);
		if (nodeProperties.outputNode) {
			return nodeProperties.outputNode.getNodeType(builder);
		}
		return this.nodeType;
	}

	public function getShared(builder:Dynamic):Node {
		var hash = this.getHash(builder);
		var nodeFromHash = builder.getNodeFromHash(hash);
		return nodeFromHash ? nodeFromHash : this;
	}

	public function setup(builder:Dynamic):Dynamic {
		var nodeProperties = builder.getNodeProperties(this);
		for (childNode in this.getChildren()) {
			nodeProperties['_node' + childNode.id] = childNode;
		}
		return null;
	}

	public function construct(builder:Dynamic):Dynamic {
		trace('THREE.Node: construct() is deprecated. Use setup() instead.');
		return this.setup(builder);
	}

	public function increaseUsage(builder:Dynamic):Int {
		var nodeData = builder.getDataFromNode(this);
		nodeData.usageCount = nodeData.usageCount == null ? 1 : nodeData.usageCount + 1;
		return nodeData.usageCount;
	}

	public function analyze(builder:Dynamic):Void {
		var usageCount = this.increaseUsage(builder);
		if (usageCount == 1) {
			var nodeProperties = builder.getNodeProperties(this);
			for (childNode in Object.keys(nodeProperties)) {
				if (childNode && childNode.isNode) {
					childNode.build(builder);
				}
			}
		}
	}

	public function generate(builder:Dynamic, output:Dynamic):String {
		var outputNode = builder.getNodeProperties(this).outputNode;
		if (outputNode && outputNode.isNode) {
			return outputNode.build(builder, output) ?? '';
		}
		return '';
	}

	public function updateBefore(frame:Dynamic):Void {
		trace('Abstract function.');
	}

	public function update(frame:Dynamic):Void {
		trace('Abstract function.');
	}

	public function build(builder:Dynamic, output:Null<Dynamic> = null):Dynamic {
		var refNode = this.getShared(builder);
		if (this != refNode) {
			return refNode.build(builder, output);
		}
		builder.addNode(this);
		builder.addChain(this);
		var result:Null<Dynamic> = null;
		var buildStage = builder.getBuildStage();
		if (buildStage == 'setup') {
			this.updateReference(builder);
			var properties = builder.getNodeProperties(this);
			if (properties.initialized != true || builder.context.tempRead == false) {
				var stackNodesBeforeSetup = builder.stack.nodes.length;
				properties.initialized = true;
				properties.outputNode = this.setup(builder);
				if (properties.outputNode != null && builder.stack.nodes.length != stackNodesBeforeSetup) {
					properties.outputNode = builder.stack;
				}
				for (childNode in Object.values(properties)) {
					if (childNode && childNode.isNode) {
						childNode.build(builder);
					}
				}
			}
		} else if (buildStage == 'analyze') {
			this.analyze(builder);
		} else if (buildStage == 'generate') {
			var isGenerateOnce = this.generate.length == 1;
			if (isGenerateOnce) {
				var type = this.getNodeType(builder);
				var nodeData = builder.getDataFromNode(this);
				result = nodeData.snippet;
				if (result == null || builder.context.tempRead == false) {
					result = this.generate(builder) ?? '';
					nodeData.snippet = result;
				}
				result = builder.format(result, type, output);
			} else {
				result = this.generate(builder, output) ?? '';
			}
		}
		builder.removeChain(this);
		return result;
	}

	public function getSerializeChildren():Array<Dynamic> {
		return getNodeChildren(this);
	}

	public function serialize(json:Dynamic):Void {
		var nodeChildren = this.getSerializeChildren();
		var inputNodes = {};
		for (childNode in nodeChildren) {
			if (childNode.index != null) {
				if (inputNodes[childNode.property] == null) {
					inputNodes[childNode.property] = Number.isInteger(childNode.index) ? [] : {};
				}
				inputNodes[childNode.property][childNode.index] = childNode.childNode.toJSON(json.meta).uuid;
			} else {
				inputNodes[childNode.property] = childNode.childNode.toJSON(json.meta).uuid;
			}
		}
		if (Object.keys(inputNodes).length > 0) {
			json.inputNodes = inputNodes;
		}
	}

	public function deserialize(json:Dynamic):Void {
		if (json.inputNodes != null) {
			var nodes = json.meta.nodes;
			for (property in json.inputNodes) {
				if (Array.isArray(json.inputNodes[property])) {
					var inputArray = [];
					for (uuid in json.inputNodes[property]) {
						inputArray.push(nodes[uuid]);
					}
					this[property] = inputArray;
				} else if (typeof json.inputNodes[property] == 'object') {
					var inputObject = {};
					for (subProperty in json.inputNodes[property]) {
						var uuid = json.inputNodes[property][subProperty];
						inputObject[subProperty] = nodes[uuid];
					}
					this[property] = inputObject;
				} else {
					var uuid = json.inputNodes[property];
					this[property] = nodes[uuid];
				}
			}
		}
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var uuid = this.uuid;
		var type = this.type;
		var isRoot = (meta == null || typeof meta == 'string');
		if (isRoot) {
			meta = {
				textures: {},
				images: {},
				nodes: {}
			};
		}
		var data = meta.nodes[uuid];
		if (data == null) {
			data = {
				uuid: uuid,
				type: type,
				meta: meta,
				metadata: {
					version: 4.6,
					type: 'Node',
					generator: 'Node.toJSON'
				}
			};
			if (isRoot != true) meta.nodes[data.uuid] = data;
			this.serialize(data);
			delete data.meta;
		}
		function extractFromCache(cache:Dynamic):Array<Dynamic> {
			var values = [];
			for (key in cache) {
				var data = cache[key];
				delete data.metadata;
				values.push(data);
			}
			return values;
		}
		if (isRoot) {
			var textures = extractFromCache(meta.textures);
			var images = extractFromCache(meta.images);
			var nodes = extractFromCache(meta.nodes);
			if (textures.length > 0) data.textures = textures;
			if (images.length > 0) data.images = images;
			if (nodes.length > 0) data.nodes = nodes;
		}
		return data;
	}

	static var NodeClasses:Map<String, Dynamic->Void> = new Map();
	static var _nodeId:Int = 0;

	public static function addNodeClass(type:String, nodeClass:Dynamic->Void):Void {
		if (typeof nodeClass != 'function' || !type) throw 'Node class $type is not a class';
		if (NodeClasses.exists(type)) {
			trace('Redefinition of node class $type');
			return;
		}
		NodeClasses.set(type, nodeClass);
		nodeClass.type = type;
	}

	public static function createNodeFromType(type:String):Node {
		var Class = NodeClasses.get(type);
		if (Class != null) {
			return new Class();
		}
		return null;
	}
}