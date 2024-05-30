import js.Node.EventDispatcher;
import js.Node.NodeUtils;
import js.Node.NodeUpdateType;
import js.Node.MathUtils;

class Node extends EventDispatcher {
    var _nodeId:Int;
    static var NodeClasses:Map<Dynamic>;

    public var nodeType:Dynamic;
    public var updateType:NodeUpdateType;
    public var updateBeforeType:NodeUpdateType;
    public var uuid:String;
    public var version:Int;
    public var _cacheKey:Dynamic;
    public var _cacheKeyVersion:Int;
    public var isNode:Bool;
    public var id:Int;

    public function new(nodeType:Dynamic) {
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
        if (value) {
            this.version++;
        }
    }

    public function get type():Dynamic {
        return this.nodeType;
    }

    public function onUpdate(callback:Dynamic, updateType:NodeUpdateType):Dynamic {
        this.updateType = updateType;
        this.update = callback.bind(this.getSelf());
        return this;
    }

    public function onFrameUpdate(callback:Dynamic):Dynamic {
        return this.onUpdate(callback, NodeUpdateType.FRAME);
    }

    public function onRenderUpdate(callback:Dynamic):Dynamic {
        return this.onUpdate(callback, NodeUpdateType.RENDER);
    }

    public function onObjectUpdate(callback:Dynamic):Dynamic {
        return this.onUpdate(callback, NodeUpdateType.OBJECT);
    }

    public function onReference(callback:Dynamic):Dynamic {
        this.updateReference = callback.bind(this.getSelf());
        return this;
    }

    public function getSelf():Dynamic {
        return this.self != null ? this.self : this;
    }

    public function updateReference(/*state*/):Dynamic {
        return this;
    }

    public function isGlobal(/*builder*/):Bool {
        return false;
    }

    public function getChildren():Dynamic {
        return getNodeChildren(this);
    }

    public function dispose():Void {
        this.dispatchEvent( { type: 'dispose' } );
    }

    public function traverse(callback:Dynamic):Void {
        callback(this);
        for (childNode in this.getChildren()) {
            childNode.traverse(callback);
        }
    }

    public function getCacheKey(force:Bool = false):Dynamic {
        if (force || this._cacheKeyVersion != this.version) {
            this._cacheKey = NodeUtils.getCacheKey(this, force);
            this._cacheKeyVersion = this.version;
        }
        return this._cacheKey;
    }

    public function getHash(/*builder*/):Dynamic {
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

    public function getShared(builder:Dynamic):Dynamic {
        var hash = this.getHash(builder);
        var nodeFromHash = builder.getNodeFromHash(hash);
        return nodeFromHash != null ? nodeFromHash : this;
    }

    public function setup(builder:Dynamic):Dynamic {
        var nodeProperties = builder.getNodeProperties(this);
        for (childNode in this.getChildren()) {
            nodeProperties["_node" + childNode.id] = childNode;
        }
        return null;
    }

    public function construct(builder:Dynamic):Dynamic {
        trace("Node: construct() is deprecated. Use setup() instead.");
        return this.setup(builder);
    }

    public function increaseUsage(builder:Dynamic):Int {
        var nodeData = builder.getDataFromNode(this);
        nodeData.usageCount = nodeData.usageCount != null ? nodeData.usageCount + 1 : 1;
        return nodeData.usageCount;
    }

    public function analyze(builder:Dynamic):Void {
        var usageCount = this.increaseUsage(builder);
        if (usageCount == 1) {
            var nodeProperties = builder.getNodeProperties(this);
            for (childNode in nodeProperties) {
                if (childNode.isNode) {
                    childNode.build(builder);
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

    public function updateBefore(/*frame*/):Void {
        trace("Abstract function.");
    }

    public function update(/*frame*/):Void {
        trace("Abstract function.");
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
            if (!properties.initialized || !builder.context.tempRead) {
                var stackNodesBeforeSetup = builder.stack.nodes.length;
                properties.initialized = true;
                properties.outputNode = this.setup(builder);
                if (properties.outputNode != null && builder.stack.nodes.length != stackNodesBeforeSetup) {
                    properties.outputNode = builder.stack;
                }
                for (childNode in properties) {
                    if (childNode.isNode) {
                        childNode.build(builder);
                    }
                }
            }
        } else if (buildStage == "analyze") {
            this.analyze(builder);
        } else if (buildStage == "generate") {
            var isGenerateOnce = this.generate.length == 1;
            if (isGenerateOnce) {
                var type = this.getNodeType(builder);
                var nodeData = builder.getDataFromNode(this);
                result = nodeData.snippet;
                if (result == null || !builder.context.tempRead) {
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

    public function getSerializeChildren():Dynamic {
        return getNodeChildren(this);
    }

    public function serialize(json:Dynamic):Void {
        var nodeChildren = this.getSerializeChildren();
        var inputNodes:Dynamic = new Map();
        for (childNode in nodeChildren) {
            var property = childNode.property;
            var index = childNode.index;
            var childNodeValue = childNode.childNode;
            if (index != null) {
                if (!inputNodes.exists(property)) {
                    inputNodes[property] = [];
                }
                inputNodes[property][index] = childNodeValue.toJSON(json.meta).uuid;
            } else {
                inputNodes[property] = childNodeValue.toJSON(json.meta).uuid;
            }
        }
        if (inputNodes.keys().hasNext()) {
            json.inputNodes = inputNodes;
        }
    }

    public function deserialize(json:Dynamic):Void {
        if (json.inputNodes != null) {
            var nodes = json.meta.nodes;
            for (property in json.inputNodes) {
                var inputNodesProperty = json.inputNodes[property];
                if (inputNodesProperty is Array) {
                    var inputArray:Array<Dynamic> = [];
                    for (uuid in inputNodesProperty) {
                        inputArray.push(nodes[uuid]);
                    }
                    this[property] = inputArray;
                } else if (inputNodesProperty is Map) {
                    var inputObject:Map<Dynamic> = new Map();
                    for (subProperty in inputNodesProperty) {
                        var uuid = inputNodesProperty[subProperty];
                        inputObject[subProperty] = nodes[uuid];
                    }
                    this[property] = inputObject;
                } else {
                    var uuid = inputNodesProperty;
                    this[property] = nodes[uuid];
                }
            }
        }
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var uuid = this.uuid;
        var type = this.type;
        var isRoot = (meta == null || typeof meta == "string");
        if (isRoot) {
            meta = {
                textures: new Map(),
                images: new Map(),
                nodes: new Map()
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
                    type: "Node",
                    generator: "Node.toJSON"
                }
            };
            if (!isRoot) meta.nodes[data.uuid] = data;
            this.serialize(data);
            data.meta = null;
        }
        function extractFromCache(cache:Dynamic):Array<Dynamic> {
            var values:Array<Dynamic> = [];
            for (key in cache) {
                var data = cache[key];
                data.metadata = null;
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

    public static function addNodeClass(type:Dynamic, nodeClass:Dynamic):Void {
        if (!Std.is(nodeClass, Dynamic) || type == null) {
            throw new Error("Node class " + type + " is not a class");
        }
        if (NodeClasses.exists(type)) {
            trace("Redefinition of node class " + type);
            return;
        }
        NodeClasses.set(type, nodeClass);
        nodeClass.type = type;
    }

    public static function createNodeFromType(type:Dynamic):Dynamic {
        var Class = NodeClasses.get(type);
        if (Class != null) {
            return new Class();
        }
    }
}