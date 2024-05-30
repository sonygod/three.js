import EventDispatcher.hx;
import MathUtils.hx;
import NodeUpdateType.hx;
import NodeUtils.hx;

class Node extends EventDispatcher {

    public var nodeType:String;
    public var updateType:Int;
    public var updateBeforeType:Int;
    public var uuid:String;
    public var version:Int;
    public var _cacheKey:String;
    public var _cacheKeyVersion:Int;
    public var isNode:Bool;
    public var id:Int;

    public function new(nodeType:String = null) {
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
        if (value == true) {
            this.version++;
        }
    }

    public function get type():String {
        return Type.getClass(this).get();
    }

    public function onUpdate(callback:Dynamic, updateType:Int):Node {
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

    public function updateReference(/*state*/):Node {
        return this;
    }

    public function isGlobal(/*builder*/):Bool {
        return false;
    }

    public function getChildren():Iterator<Dynamic> {
        for (childNode in NodeUtils.getNodeChildren(this)) {
            yield childNode;
        }
    }

    public function dispose() {
        this.dispatchEvent({type: 'dispose'});
    }

    public function traverse(callback:Dynamic) {
        callback(this);
        for (childNode in this.getChildren()) {
            childNode.traverse(callback);
        }
    }

    public function getCacheKey(force:Bool = false):String {
        force = force || this.version != this._cacheKeyVersion;
        if (force == true || this._cacheKey == null) {
            this._cacheKey = NodeUtils.getCacheKey(this, force);
            this._cacheKeyVersion = this.version;
        }
        return this._cacheKey;
    }

    public function getHash(/*builder*/):String {
        return this.uuid;
    }

    public function getUpdateType():Int {
        return this.updateType;
    }

    public function getUpdateBeforeType():Int {
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
        return nodeFromHash || this;
    }

    public function setup(builder:Dynamic):Dynamic {
        var nodeProperties = builder.getNodeProperties(this);
        for (childNode in this.getChildren()) {
            nodeProperties['_node' + childNode.id] = childNode;
        }
        return null;
    }

    public function construct(builder:Dynamic):Dynamic {
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
        if (usageCount == 1) {
            var nodeProperties = builder.getNodeProperties(this);
            for (childNode in nodeProperties.values()) {
                if (childNode && childNode.isNode == true) {
                    childNode.build(builder);
                }
            }
        }
    }

    public function generate(builder:Dynamic, output:Dynamic):String {
        var outputNode = builder.getNodeProperties(this).outputNode;
        if (outputNode && outputNode.isNode == true) {
            return outputNode.build(builder, output);
        }
        return '';
    }

    public function updateBefore(/*frame*/) {
        console.warn('Abstract function.');
    }

    public function update(/*frame*/) {
        console.warn('Abstract function.');
    }

    public function build(builder:Dynamic, output:Dynamic = null):String {
        var refNode = this.getShared(builder);
        if (this != refNode) {
            return refNode.build(builder, output);
        }
        builder.addNode(this);
        builder.addChain(this);
        var result:String;
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
                for (childNode in properties.values()) {
                    if (childNode && childNode.isNode == true) {
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

    public function getSerializeChildren():Iterator<Dynamic> {
        return NodeUtils.getNodeChildren(this);
    }

    public function serialize(json:Dynamic) {
        var nodeChildren = this.getSerializeChildren();
        var inputNodes:Dynamic = new Dynamic();
        for (childNode in nodeChildren) {
            if (childNode.index != null) {
                if (inputNodes[childNode.property] == null) {
                    inputNodes[childNode.property] = Type.createEmptyInstance(Type.getClass(childNode.index));
                }
                inputNodes[childNode.property][childNode.index] = childNode.childNode.toJSON(json.meta).uuid;
            } else {
                inputNodes[childNode.property] = childNode.childNode.toJSON(json.meta).uuid;
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
                if (Reflect.isArray(json.inputNodes[property])) {
                    var inputArray:Array<Dynamic> = [];
                    for (uuid in json.inputNodes[property]) {
                        inputArray.push(nodes[uuid]);
                    }
                    this[property] = inputArray;
                } else if (Reflect.isObject(json.inputNodes[property])) {
                    var inputObject:Dynamic = new Dynamic();
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
        var isRoot = (meta == null || Type.typeof(meta) == TString);
        if (isRoot) {
            meta = {
                textures: new Dynamic(),
                images: new Dynamic(),
                nodes: new Dynamic()
            };
        }
        var data = meta.nodes[uuid];
        if (data == null) {
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
            if (isRoot != true) meta.nodes[data.uuid] = data;
            this.serialize(data);
            delete data.meta;
        }
        if (isRoot) {
            var textures = Reflect.copy(meta.textures);
            var images = Reflect.copy(meta.images);
            var nodes = Reflect.copy(meta.nodes);
            if (Reflect.fields(textures).length > 0) data.textures = textures;
            if (Reflect.fields(images).length > 0) data.images = images;
            if (Reflect.fields(nodes).length > 0) data.nodes = nodes;
        }
        return data;
    }

}

class NodeClasses {
    public static var map:Map<String, Class<Dynamic>> = new Map<String, Class<Dynamic>>();
}

var _nodeId:Int = 0;

function addNodeClass(type:String, nodeClass:Class<Dynamic>) {
    if (Type.typeof(nodeClass) != TClass || !type) throw 'Node class $type is not a class';
    if (NodeClasses.map.exists(type)) {
        console.warn('Redefinition of node class $type');
        return;
    }
    NodeClasses.map.set(type, nodeClass);
    nodeClass.type = type;
}

function createNodeFromType(type:String):Dynamic {
    var Class = NodeClasses.map.get(type);
    if (Class != null) {
        return Type.createInstance(Class, []);
    }
    return null;
}