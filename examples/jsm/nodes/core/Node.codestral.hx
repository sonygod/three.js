import three.math.MathUtils;
import three.core.EventDispatcher;
import NodeUpdateType;
import NodeUtils;

class Node extends EventDispatcher {
    public var nodeType:Dynamic;
    public var updateType:NodeUpdateType;
    public var updateBeforeType:NodeUpdateType;
    public var uuid:String;
    public var version:Int;
    private var _cacheKey:String;
    private var _cacheKeyVersion:Int;
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
        this.id = _nodeId++;
    }

    public function set_needsUpdate(value:Bool):Void {
        if (value === true) {
            this.version++;
        }
    }

    public function get_type():String {
        return Type.getClass(this).getField("type", null);
    }

    public function onUpdate(callback:Dynamic -> Void, updateType:NodeUpdateType):Node {
        this.updateType = updateType;
        this.update = callback.bind(this.getSelf());
        return this;
    }

    public function onFrameUpdate(callback:Dynamic -> Void):Node {
        return this.onUpdate(callback, NodeUpdateType.FRAME);
    }

    public function onRenderUpdate(callback:Dynamic -> Void):Node {
        return this.onUpdate(callback, NodeUpdateType.RENDER);
    }

    public function onObjectUpdate(callback:Dynamic -> Void):Node {
        return this.onUpdate(callback, NodeUpdateType.OBJECT);
    }

    public function onReference(callback:Dynamic -> Void):Node {
        this.updateReference = callback.bind(this.getSelf());
        return this;
    }

    public function getSelf():Node {
        return this.self || this;
    }

    public function updateReference(/*state*/):Node {
        return this;
    }

    public function isGlobal(/*builder*/):Bool {
        return false;
    }

    public function getChildren():Iterator<Node> {
        for (childNode in NodeUtils.getNodeChildren(this)) {
            yield childNode.childNode;
        }
    }

    public function dispose():Void {
        this.dispatchEvent({ type: 'dispose' });
    }

    public function traverse(callback:Node -> Void):Void {
        callback(this);
        for (childNode in this.getChildren()) {
            childNode.traverse(callback);
        }
    }

    public function getCacheKey(force:Bool = false):String {
        force = force || this.version !== this._cacheKeyVersion;
        if (force === true || this._cacheKey === null) {
            this._cacheKey = NodeUtils.getCacheKey(this, force);
            this._cacheKeyVersion = this.version;
        }
        return this._cacheKey;
    }

    public function getHash(/*builder*/):String {
        return this.uuid;
    }

    public function getUpdateType():NodeUpdateType {
        return this.updateType;
    }

    public function getUpdateBeforeType():NodeUpdateType {
        return this.updateBeforeType;
    }

    public function getNodeType(builder):Dynamic {
        var nodeProperties = builder.getNodeProperties(this);
        if (nodeProperties.outputNode) {
            return nodeProperties.outputNode.getNodeType(builder);
        }
        return this.nodeType;
    }

    public function getShared(builder):Node {
        var hash = this.getHash(builder);
        var nodeFromHash = builder.getNodeFromHash(hash);
        return nodeFromHash || this;
    }

    public function setup(builder):Node {
        var nodeProperties = builder.getNodeProperties(this);
        for (childNode in this.getChildren()) {
            nodeProperties['_node' + childNode.id] = childNode;
        }
        return null;
    }

    public function construct(builder):Node {
        trace('THREE.Node: construct() is deprecated. Use setup() instead.');
        return this.setup(builder);
    }

    public function increaseUsage(builder):Int {
        var nodeData = builder.getDataFromNode(this);
        nodeData.usageCount = nodeData.usageCount === null ? 1 : nodeData.usageCount + 1;
        return nodeData.usageCount;
    }

    public function analyze(builder):Void {
        var usageCount = this.increaseUsage(builder);
        if (usageCount === 1) {
            var nodeProperties = builder.getNodeProperties(this);
            for (childNode in Reflect.fields(nodeProperties)) {
                if (Reflect.field(nodeProperties, childNode) && Reflect.field(nodeProperties, childNode).isNode === true) {
                    Reflect.field(nodeProperties, childNode).build(builder);
                }
            }
        }
    }

    public function generate(builder, output:Dynamic = null):String {
        var outputNode = builder.getNodeProperties(this).outputNode;
        if (outputNode && outputNode.isNode === true) {
            return outputNode.build(builder, output);
        }
        return null;
    }

    public function updateBefore(/*frame*/):Void {
        trace('Abstract function.');
    }

    public function update(/*frame*/):Void {
        trace('Abstract function.');
    }

    public function build(builder, output:Dynamic = null):String {
        var refNode = this.getShared(builder);
        if (this !== refNode) {
            return refNode.build(builder, output);
        }
        builder.addNode(this);
        builder.addChain(this);
        var result = null;
        var buildStage = builder.getBuildStage();
        if (buildStage === 'setup') {
            this.updateReference(builder);
            var properties = builder.getNodeProperties(this);
            if (properties.initialized !== true || builder.context.tempRead === false) {
                var stackNodesBeforeSetup = builder.stack.nodes.length;
                properties.initialized = true;
                properties.outputNode = this.setup(builder);
                if (properties.outputNode !== null && builder.stack.nodes.length !== stackNodesBeforeSetup) {
                    properties.outputNode = builder.stack;
                }
                for (childNode in Reflect.fields(properties)) {
                    if (Reflect.field(properties, childNode) && Reflect.field(properties, childNode).isNode === true) {
                        Reflect.field(properties, childNode).build(builder);
                    }
                }
            }
        } else if (buildStage === 'analyze') {
            this.analyze(builder);
        } else if (buildStage === 'generate') {
            var isGenerateOnce = Reflect.getField(this, 'generate').length === 1;
            if (isGenerateOnce) {
                var type = this.getNodeType(builder);
                var nodeData = builder.getDataFromNode(this);
                result = nodeData.snippet;
                if (result === null /*|| builder.context.tempRead === false*/) {
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

    public function serialize(json:Dynamic):Void {
        var nodeChildren = this.getSerializeChildren();
        var inputNodes = Dynamic.createEmptyObject();
        for (child in nodeChildren) {
            var property = child.property;
            var index = child.index;
            var childNode = child.childNode;
            if (index !== null) {
                if (inputNodes[property] === null) {
                    inputNodes[property] = Std.is(index, Int) ? [] : Dynamic.createEmptyObject();
                }
                inputNodes[property][index] = childNode.toJSON(json.meta).uuid;
            } else {
                inputNodes[property] = childNode.toJSON(json.meta).uuid;
            }
        }
        if (Reflect.fields(inputNodes).length > 0) {
            json.inputNodes = inputNodes;
        }
    }

    public function deserialize(json:Dynamic):Void {
        if (json.inputNodes !== null) {
            var nodes = json.meta.nodes;
            for (property in Reflect.fields(json.inputNodes)) {
                if (Std.is(json.inputNodes[property], Array)) {
                    var inputArray = [];
                    for (uuid in json.inputNodes[property]) {
                        inputArray.push(nodes[uuid]);
                    }
                    this[property] = inputArray;
                } else if (Std.is(json.inputNodes[property], Dynamic)) {
                    var inputObject = Dynamic.createEmptyObject();
                    for (subProperty in Reflect.fields(json.inputNodes[property])) {
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
        var isRoot = (meta === null || Std.is(meta, String));
        if (isRoot) {
            meta = {
                textures: Dynamic.createEmptyObject(),
                images: Dynamic.createEmptyObject(),
                nodes: Dynamic.createEmptyObject()
            };
        }
        var data = meta.nodes[uuid];
        if (data === null) {
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
            if (isRoot !== true) meta.nodes[data.uuid] = data;
            this.serialize(data);
            Reflect.deleteField(data, 'meta');
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

    private function extractFromCache(cache:Dynamic):Array<Dynamic> {
        var values = [];
        for (key in Reflect.fields(cache)) {
            var data = cache[key];
            Reflect.deleteField(data, 'metadata');
            values.push(data);
        }
        return values;
    }
}

var NodeClasses = new haxe.ds.StringMap<Class<Node>>();
var _nodeId = 0;

function addNodeClass(type:String, nodeClass:Class<Node>):Void {
    if (!Std.is(nodeClass, Class) || !type) throw new haxe.Exception('Node class ${type} is not a class');
    if (NodeClasses.exists(type)) {
        trace('Redefinition of node class ${type}');
        return;
    }
    NodeClasses.set(type, nodeClass);
    Type.setClassField(nodeClass, 'type', type);
}

function createNodeFromType(type:String):Node {
    var Class = NodeClasses.get(type);
    if (Class !== null) {
        return Type.createEmptyInstance(Class, []);
    }
    return null;
}