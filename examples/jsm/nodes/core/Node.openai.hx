package three.js.nodes.core;

import three.js.events.EventDispatcher;
import three.js.constants.NodeUpdateType;
import three.js.utils.MathUtils;
import three.js.nodes.utils.NodeUtils;

class Node extends EventDispatcher {
    public static var NodeClasses(default, null) = new Map<String,Dynamic>();
    private static var _nodeId = 0;

    public var nodeType(default, null):Null<String>;
    public var updateType(default, null):NodeUpdateType;
    public var updateBeforeType(default, null):NodeUpdateType;
    public var uuid(default, null):String;
    public var version(default, null) = 0;
    public var _cacheKey(default, null):Null<String>;
    public var _cacheKeyVersion(default, null) = 0;
    public var isNode(default, null) = true;

    public function new(nodeType:String = null) {
        super();
        this.nodeType = nodeType;
        this.uuid = MathUtils.generateUUID();
        this.id = _nodeId++;
    }

    public function set_needsUpdate(value:Bool) {
        if (value) {
            this.version++;
        }
    }

    public function get_type():String {
        return this.constructor.type;
    }

    public function onUpdate(callback:Void->Void, updateType:NodeUpdateType):Node {
        this.updateType = updateType;
        this.update = callback.bind(this.getSelf());
        return this;
    }

    public function onFrameUpdate(callback:Void->Void):Node {
        return this.onUpdate(callback, NodeUpdateType.FRAME);
    }

    public function onRenderUpdate(callback:Void->Void):Node {
        return this.onUpdate(callback, NodeUpdateType.RENDER);
    }

    public function onObjectUpdate(callback:Void->Void):Node {
        return this.onUpdate(callback, NodeUpdateType.OBJECT);
    }

    public function onReference(callback:Void->Void):Node {
        this.updateReference = callback.bind(this.getSelf());
        return this;
    }

    public function getSelf():Node {
        return this.self != null ? this.self : this;
    }

    public function updateReference(state:Dynamic):Node {
        return this;
    }

    public function isGlobal(builder:Dynamic):Bool {
        return false;
    }

    public function getChildren():Iterator<Node> {
        for (childNode in NodeUtils.getNodeChildren(this)) {
            yield childNode;
        }
    }

    public function dispose() {
        this.dispatchEvent({ type: 'dispose' });
    }

    public function traverse(callback:Node->Void) {
        callback(this);
        for (childNode in this.getChildren()) {
            childNode.traverse(callback);
        }
    }

    public function getCacheKey(force:Bool = false):String {
        if (force || this.version != this._cacheKeyVersion) {
            this._cacheKey = NodeUtils.getCacheKey(this, force);
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
        return nodeFromHash != null ? nodeFromHash : this;
    }

    public function setup(builder:Dynamic) {
        var nodeProperties = builder.getNodeProperties(this);
        for (childNode in this.getChildren()) {
            nodeProperties['_node' + childNode.id] = childNode;
        }
        return null;
    }

    public function construct(builder:Dynamic) {
        console.warn('THREE.Node: construct() is deprecated. Use setup() instead.');
        return this.setup(builder);
    }

    public function increaseUsage(builder:Dynamic) {
        var nodeData = builder.getDataFromNode(this);
        nodeData.usageCount = nodeData.usageCount == null ? 1 : nodeData.usageCount + 1;
        return nodeData.usageCount;
    }

    public function analyze(builder:Dynamic) {
        var usageCount = this.increaseUsage(builder);
        if (usageCount == 1) {
            var nodeProperties = builder.getNodeProperties(this);
            for (childNode in Object.keys(nodeProperties)) {
                if (childNode != null && childNode.isNode) {
                    childNode.build(builder);
                }
            }
        }
    }

    public function generate(builder:Dynamic, output:Dynamic) {
        var outputNode = builder.getNodeProperties(this).outputNode;
        if (outputNode != null && outputNode.isNode) {
            return outputNode.build(builder, output);
        }
    }

    public function updateBefore(frame:Dynamic) {
        console.warn('Abstract function.');
    }

    public function update(frame:Dynamic) {
        console.warn('Abstract function.');
    }

    public function build(builder:Dynamic, output:Dynamic = null) {
        var refNode = this.getShared(builder);
        if (this != refNode) {
            return refNode.build(builder, output);
        }
        builder.addNode(this);
        builder.addChain(this);
        var result = null;
        var buildStage = builder.getBuildStage();
        if (buildStage == 'setup') {
            this.updateReference(builder);
            var properties = builder.getNodeProperties(this);
            if (properties.initialized == false || builder.context.tempRead == false) {
                properties.initialized = true;
                properties.outputNode = this.setup(builder);
                if (properties.outputNode != null && builder.stack.nodes.length != stackNodesBeforeSetup) {
                    properties.outputNode = builder.stack;
                }
                for (childNode in Object.keys(properties)) {
                    if (childNode != null && childNode.isNode) {
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
                if (result == null /*|| builder.context.tempRead == false*/) {
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
        return NodeUtils.getNodeChildren(this);
    }

    public function serialize(json:Dynamic) {
        var nodeChildren = this.getSerializeChildren();
        var inputNodes = {};
        for (childNode in nodeChildren) {
            if (childNode.index != null) {
                if (inputNodes[childNode.property] == null) {
                    inputNodes[childNode.property] = childNode.index is Int ? [] : {};
                }
                inputNodes[childNode.property][childNode.index] = childNode.uuid;
            } else {
                inputNodes[childNode.property] = childNode.uuid;
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
                if (Std.is(json.inputNodes[property], Array)) {
                    var inputArray = [];
                    for (uuid in json.inputNodes[property]) {
                        inputArray.push(nodes[uuid]);
                    }
                    this[property] = inputArray;
                } else if (Std.is(json.inputNodes[property], Object)) {
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
        var type = this.nodeType;
        var isRoot = meta == null || Std.is(meta, String);
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
                    version: '4.6',
                    type: 'Node',
                    generator: 'Node.toJSON'
                }
            };
            if (!isRoot) {
                meta.nodes[data.uuid] = data;
            }
            this.serialize(data);
            data.meta = null;
        }
        if (isRoot) {
            var textures = [];
            var images = [];
            var nodes = [];
            for (key in meta.textures) {
                textures.push(meta.textures[key]);
            }
            for (key in meta.images) {
                images.push(meta.images[key]);
            }
            for (key in meta.nodes) {
                nodes.push(meta.nodes[key]);
            }
            if (textures.length > 0) {
                data.textures = textures;
            }
            if (images.length > 0) {
                data.images = images;
            }
            if (nodes.length > 0) {
                data.nodes = nodes;
            }
        }
        return data;
    }
}

class NodeUtils {
    public static function getNodeChildren(node:Node):Array<Dynamic> {
        // implementation
    }

    public static function getCacheKey(node:Node, force:Bool = false):String {
        // implementation
    }
}

class MathUtils {
    public static function generateUUID():String {
        // implementation
    }
}