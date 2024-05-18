import MathUtils from 'three/math/MathUtils';
import EventDispatcher from 'three/events/EventDispatcher';
import { NodeUpdateType } from './constants';
import { getNodeChildren, getCacheKey } from './NodeUtils';

class Node extends EventDispatcher {

	public nodeType:Dynamic;
	public updateType:Int;
	public updateBeforeType:Int;
	public uuid:String;
	public version:Int;
	public _cacheKey:Dynamic;
	public _cacheKeyVersion:Int;
	public isNode:Bool;
	public id:Int;

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

		Object.defineProperty(this, 'id', { value: _nodeId++ });
	}

	@:generic
	public function set needsUpdate(value:Bool) {
		if (value === true) {
			this.version++;
		}
	}

	public function get type():String {
		return this.constructor.type;
	}

	public function onUpdate(callback:Void -> Void, updateType:Int) {
		this.updateType = updateType;
		this.update = callback.bind(this.getSelf());

		return this;
	}

	public function onFrameUpdate(callback:Void -> Void) {
		return this.onUpdate(callback, NodeUpdateType.FRAME);
	}

	public function onRenderUpdate(callback:Void -> Void) {
		return this.onUpdate(callback, NodeUpdateType.RENDER);
	}

	public function onObjectUpdate(callback:Void -> Void) {
		return this.onUpdate(callback, NodeUpdateType.OBJECT);
	}

	public function onReference(callback:Dynamic -> Void) {
		this.updateReference = callback.bind(this.getSelf());

		return this;
	}

	public function getSelf():Dynamic {
		// Returns non-node object.

		return this.self != null ? this.self : this;
	}

	public function updateReference(state:Dynamic) {
		return this;
	}

	public function isGlobal(builder:Dynamic):Bool {
		return false;
	}

	@:generic
	public function *getChildren() {
		for (childNode in getNodeChildren(this)) {
			yield childNode.childNode;
		}
	}

	public function dispose() {
		this.dispatchEvent( { type: 'dispose' } );
	}

	public function traverse(callback:Dynamic -> Void) {
		callback(this);

		for (childNode in this.getChildren()) {
			childNode.traverse(callback);
		}
	}

	public function getCacheKey(force:Bool = false):String {
		force = force || this.version !== this._cacheKeyVersion;

		if (force === true || this._cacheKey === null) {
			this._cacheKey = getCacheKey(this, force);
			this._cacheKeyVersion = this.version;
		}

		return this._cacheKey;
	}

	public function getHash(builder:Dynamic):String {
		return this.uuid;
	}

	public function getUpdateType():Int {
		return this.updateType;
	}

	public function getUpdateBeforeType():Int {
		return this.updateBeforeType;
	}

	public function getNodeType(builder:Dynamic):Dynamic {
		var nodeProperties = builder.getNodeProperties(this);

		if (nodeProperties.outputNode != null) {
			return nodeProperties.outputNode.getNodeType(builder);
		}

		return this.nodeType;
	}

	public function getShared(builder:Dynamic):Dynamic {
		var hash = this.getHash(builder);
		var nodeFromHash = builder.getNodeFromHash(hash);

		return nodeFromHash != null ? nodeFromHash : this;
	}

	public function setup(builder:Dynamic) {
		var nodeProperties = builder.getNodeProperties(this);

		for (childNode in this.getChildren()) {
			nodeProperties['_node' + childNode.id] = childNode;
		}

		// return a outputNode if exists
		return null;
	}

	@:deprecated("r157")
	public function construct(builder:Dynamic):Dynamic { // @deprecated, r157
		console.warn('THREE.Node: construct() is deprecated. Use setup() instead.');

		return this.setup(builder);
	}

	public function increaseUsage(builder:Dynamic):Int {
		var nodeData = builder.getDataFromNode(this);
		nodeData.usageCount = nodeData.usageCount == null ? 1 : nodeData.usageCount + 1;

		return nodeData.usageCount;
	}

	public function analyze(builder:Dynamic) {
		var usageCount = this.increaseUsage(builder);

		if (usageCount === 1) {
			// node flow children

			var nodeProperties = builder.getNodeProperties(this);

			for (childNode in nodeProperties) {
				if (childNode != null && childNode.isNode === true) {
					childNode.build(builder);
				}
			}
		}
	}

	public function generate(builder:Dynamic, output:Dynamic):String {
		var { outputNode } = builder.getNodeProperties(this);

		if (outputNode != null && outputNode.isNode === true) {
			return outputNode.build(builder, output);
		}

		return '';
	}

	public function updateBefore(frame:Dynamic) {
		console.warn('Abstract function.');
	}

	public function update(frame:Dynamic) {
		console.warn('Abstract function.');
	}

	public function build(builder:Dynamic, output:Dynamic = null) {
		var refNode = this.getShared(builder);

		if (this !== refNode) {
			return refNode.build(builder, output);
		}

		builder.addNode(this);
		builder.addChain(this);

		/* Build stages expected results:
			- "setup"		-> Node
			- "analyze"		-> null
			- "generate"	-> String
		*/
		var result:Dynamic = null;

		var buildStage = builder.getBuildStage();

		if (buildStage === 'setup') {
			this.updateReference(builder);

			var properties = builder.getNodeProperties(this);

			if (properties.initialized != true || builder.context.tempRead === false) {
				var stackNodesBeforeSetup = builder.stack.nodes.length;

				properties.initialized = true;
				properties.outputNode = this.setup(builder);

				if (properties.outputNode != null && builder.stack.nodes.length !== stackNodesBeforeSetup) {
					properties.outputNode = builder.stack;
				}

				for (childNode in properties) {
					if (childNode != null && childNode.isNode === true) {
						childNode.build(builder);
					}
				}
			}
		} else if (buildStage === 'analyze') {
			this.analyze(builder);
		} else if (buildStage === 'generate') {
			var isGenerateOnce = this.generate.length === 1;

			if (isGenerateOnce) {
				var type = this.getNodeType(builder);
				var nodeData = builder.getDataFromNode(this);

				result = nodeData.snippet;

				if (result == null /*|| builder.context.tempRead === false*/ ) {
					result = this.generate(builder) || '';

					nodeData.snippet = result;
				}

				result = builder.format(result, type, output);

			} else {
				result = this.generate(builder, output) || '';
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

		var inputNodes = {};

		for (child in nodeChildren) {
			var { property, index, childNode } = child;

			if (index != null) {
				if (inputNodes[property] == null) {
					inputNodes[property] = [];
				}

				inputNodes[property][index] = childNode.toJSON(json.meta).uuid;

			} else {
				inputNodes[property] = childNode.toJSON(json.meta).uuid;
			}
		}

		if (Object.keys(inputNodes).length > 0) {
			json.inputNodes = inputNodes;
		}
	}

	public function deserialize(json:Dynamic) {
		if (json.inputNodes != null) {
			var nodes = json.meta.nodes;

			for (property in json.inputNodes) {
				if (Array.isArray(json.inputNodes[property])) {
					var inputArray = [];

					for (uuid of json.inputNodes[property]) {
						inputArray.push(nodes[uuid]);
					}

					this[property] = inputArray;

				} else if (typeof json.inputNodes[property] === 'object') {
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
		var { uuid, type } = this;
		var isRoot = (meta === undefined || typeof meta === 'string');

		if (isRoot) {
			meta = {
				textures: {},
				images: {},
				nodes: {}
			};
		}

		// serialize

		var data = meta.nodes[uuid];

		if (data === undefined) {
			data = {
				uuid,
				type,
				meta,
				metadata: {
					version: 4.6,
					type: 'Node',
					generator: 'Node.toJSON'
				}
			};

			if (isRoot !== true) meta.nodes[data.uuid] = data;

			this.serialize(data);

			delete data.meta;

		}

		// TODO: Copied from Object3D.toJSON

		function extractFromCache(cache:Dynamic) {
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

}

class NodeBuilder {
	public nodes:Array<Dynamic>;
	public chains:Array<Dynamic>;
	public stack:Dynamic;
	public getBuildStage():String {
		return "setup";
	}
	public addNode(node:Dynamic) {}
	public addChain(node:Dynamic) {}
	public getNodeProperties(node:Dynamic):Dynamic {
		return {};
	}
	public getDataFromNode(node:Dynamic):Dynamic {
		return { usageCount: 0 };
	}
	public getNodeFromHash(hash:String):Dynamic {
		return null;
	}
	public format(snippet:String, type:String, output:Dynamic):String {
		return snippet;
	}
	public tempRead:Bool;
	public context:Dynamic;
}

var _nodeId = 0;

export default Node;

export function addNodeClass(type:String, nodeClass:Class<Dynamic>) {}

export function createNodeFromType(type:String):Dynamic {}