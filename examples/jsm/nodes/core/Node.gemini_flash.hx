import three.extras.EventDispatcher;
import three.math.MathUtils;
import three.constants.NodeUpdateType;
import NodeUtils.getNodeChildren;
import NodeUtils.getCacheKey;

class Node extends EventDispatcher {

	public var nodeType:Dynamic = null;
	public var updateType:NodeUpdateType = NodeUpdateType.NONE;
	public var updateBeforeType:NodeUpdateType = NodeUpdateType.NONE;
	public var uuid:String;
	public var version:Int = 0;
	public var _cacheKey:String = null;
	public var _cacheKeyVersion:Int = 0;
	public var isNode:Bool = true;
	public var id:Int;

	public function new(nodeType:Dynamic = null) {
		super();
		this.nodeType = nodeType;
		this.updateType = NodeUpdateType.NONE;
		this.updateBeforeType = NodeUpdateType.NONE;
		this.uuid = MathUtils.generateUUID();
		this.version = 0;
		this._cacheKey = null;
		this._cacheKeyVersion = 0;
		this.isNode = true;
		this.id = _nodeId++;
	}

	public function set needsUpdate(value:Bool) {
		if (value) this.version++;
	}

	public function get type():String {
		return Type.getClassName(Type.getClass(this));
	}

	public function onUpdate(callback:Dynamic, updateType:NodeUpdateType):Node {
		this.updateType = updateType;
		this.update = callback.bind(this.getSelf());
		return this;
	}

	public function onFrameUpdate(callback:Dynamic):Node {
		return this.onUpdate(callback, NodeUpdateType.FRAME);
	}

	public function onRenderUpdate(callback:Dynamic):Node {
		return this.onUpdate(callback, NodeUpdateType.RENDER);
	}

	public function onObjectUpdate(callback:Dynamic):Node {
		return this.onUpdate(callback, NodeUpdateType.OBJECT);
	}

	public function onReference(callback:Dynamic):Node {
		this.updateReference = callback.bind(this.getSelf());
		return this;
	}

	public function getSelf():Dynamic {
		return this.self || this;
	}

	public function updateReference(state:Dynamic):Node {
		return this;
	}

	public function isGlobal(builder:Dynamic):Bool {
		return false;
	}

	public function getChildren():Iterator<Node> {
		return getNodeChildren(this).map(function(item) return item.childNode);
	}

	public function dispose() {
		this.dispatchEvent({type: "dispose"});
	}

	public function traverse(callback:Dynamic) {
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

	public function getNodeType(builder:Dynamic):Dynamic {
		var nodeProperties = builder.getNodeProperties(this);
		if (nodeProperties.outputNode != null) {
			return nodeProperties.outputNode.getNodeType(builder);
		}
		return this.nodeType;
	}

	public function getShared(builder:Dynamic):Node {
		var hash = this.getHash(builder);
		var nodeFromHash = builder.getNodeFromHash(hash);
		return nodeFromHash || this;
	}

	public function setup(builder:Dynamic):Dynamic {
		var nodeProperties = builder.getNodeProperties(this);
		for (childNode in this.getChildren()) {
			nodeProperties["_node" + childNode.id] = childNode;
		}
		return null;
	}

	public function construct(builder:Dynamic):Dynamic {
		console.warn("THREE.Node: construct() is deprecated. Use setup() instead.");
		return this.setup(builder);
	}

	public function increaseUsage(builder:Dynamic):Int {
		var nodeData = builder.getDataFromNode(this);
		nodeData.usageCount = nodeData.usageCount == null ? 1 : nodeData.usageCount + 1;
		return nodeData.usageCount;
	}

	public function analyze(builder:Dynamic) {
		var usageCount = this.increaseUsage(builder);
		if (usageCount == 1) {
			var nodeProperties = builder.getNodeProperties(this);
			for (childNode in Reflect.fields(nodeProperties)) {
				if (nodeProperties[childNode] != null && nodeProperties[childNode].isNode) {
					nodeProperties[childNode].build(builder);
				}
			}
		}
	}

	public function generate(builder:Dynamic, output:Dynamic = null):Dynamic {
		var outputNode = builder.getNodeProperties(this).outputNode;
		if (outputNode != null && outputNode.isNode) {
			return outputNode.build(builder, output);
		}
	}

	public function updateBefore(frame:Dynamic) {
		console.warn("Abstract function.");
	}

	public function update(frame:Dynamic) {
		console.warn("Abstract function.");
	}

	public function build(builder:Dynamic, output:Dynamic = null):Dynamic {
		var refNode = this.getShared(builder);
		if (this != refNode) {
			return refNode.build(builder, output);
		}
		builder.addNode(this);
		builder.addChain(this);
		var result:Dynamic = null;
		var buildStage = builder.getBuildStage();
		if (buildStage == "setup") {
			this.updateReference(builder);
			var properties = builder.getNodeProperties(this);
			if (properties.initialized != true || builder.context.tempRead != true) {
				var stackNodesBeforeSetup = builder.stack.nodes.length;
				properties.initialized = true;
				properties.outputNode = this.setup(builder);
				if (properties.outputNode != null && builder.stack.nodes.length != stackNodesBeforeSetup) {
					properties.outputNode = builder.stack;
				}
				for (childNode in Reflect.fields(properties)) {
					if (properties[childNode] != null && properties[childNode].isNode) {
						properties[childNode].build(builder);
					}
				}
			}
		} else if (buildStage == "analyze") {
			this.analyze(builder);
		} else if (buildStage == "generate") {
			if (this.generate.length == 1) {
				var type = this.getNodeType(builder);
				var nodeData = builder.getDataFromNode(this);
				result = nodeData.snippet;
				if (result == null || builder.context.tempRead != true) {
					result = this.generate(builder) || "";
					nodeData.snippet = result;
				}
				result = builder.format(result, type, output);
			} else {
				result = this.generate(builder, output) || "";
			}
		}
		builder.removeChain(this);
		return result;
	}

	public function getSerializeChildren():Array<Dynamic> {
		return getNodeChildren(this);
	}

	public function serialize(json:Dynamic) {
		var nodeChildren = this.getSerializeChildren();
		var inputNodes:Dynamic = {};
		for (item in nodeChildren) {
			if (item.index != null) {
				if (inputNodes[item.property] == null) {
					inputNodes[item.property] = Std.is(item.index, Int) ? [] : {};
				}
				inputNodes[item.property][item.index] = item.childNode.toJSON(json.meta).uuid;
			} else {
				inputNodes[item.property] = item.childNode.toJSON(json.meta).uuid;
			}
		}
		if (Reflect.fields(inputNodes).length > 0) {
			json.inputNodes = inputNodes;
		}
	}

	public function deserialize(json:Dynamic) {
		if (json.inputNodes != null) {
			var nodes = json.meta.nodes;
			for (property in json.inputNodes) {
				if (Std.is(json.inputNodes[property], Array)) {
					var inputArray:Array<Dynamic> = [];
					for (uuid in json.inputNodes[property]) {
						inputArray.push(nodes[uuid]);
					}
					this[property] = inputArray;
				} else if (Std.is(json.inputNodes[property], Dynamic)) {
					var inputObject:Dynamic = {};
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
		var isRoot = meta == null || Std.is(meta, String);
		if (isRoot) {
			meta = {
				textures: {},
				images: {},
				nodes: {}
			};
		}
		var data:Dynamic = meta.nodes[uuid];
		if (data == null) {
			data = {
				uuid: uuid,
				type: type,
				meta: meta,
				metadata: {
					version: 4.6,
					type: "Node",
					generator: "Node.toJSON"
				}
			};
			if (!isRoot) meta.nodes[data.uuid] = data;
			this.serialize(data);
			Reflect.deleteField(data, "meta");
		}
		function extractFromCache(cache:Dynamic):Array<Dynamic> {
			var values:Array<Dynamic> = [];
			for (key in cache) {
				var data = cache[key];
				Reflect.deleteField(data, "metadata");
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

}

var NodeClasses:Map<String, Class<Node>> = new Map();
var _nodeId:Int = 0;

public function addNodeClass(type:String, nodeClass:Class<Node>) {
	if (!Std.is(nodeClass, Class) || type == null) throw new Error("Node class " + type + " is not a class");
	if (NodeClasses.exists(type)) {
		console.warn("Redefinition of node class " + type);
		return;
	}
	NodeClasses.set(type, nodeClass);
	nodeClass.type = type;
}

public function createNodeFromType(type:String):Node {
	var Class = NodeClasses.get(type);
	if (Class != null) {
		return new Class();
	}
}