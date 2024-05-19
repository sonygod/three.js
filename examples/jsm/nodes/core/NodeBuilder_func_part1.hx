package three.js.examples.jsm.nodes.core;

import NodeUniform from './NodeUniform';
import NodeAttribute from './NodeAttribute';
import NodeVarying from './NodeVarying';
import NodeVar from './NodeVar';
import NodeCode from './NodeCode';
import NodeKeywords from './NodeKeywords';
import NodeCache from './NodeCache';
import ParameterNode from './ParameterNode';
import FunctionNode from '../code/FunctionNode';
import NodeMaterial from '../materials/NodeMaterial';

import FloatNodeUniform from '../../renderers/common/nodes/NodeUniform';
import Vector2NodeUniform from '../../renderers/common/nodes/NodeUniform';
import Vector3NodeUniform from '../../renderers/common/nodes/NodeUniform';
import Vector4NodeUniform from '../../renderers/common/nodes/NodeUniform';
import ColorNodeUniform from '../../renderers/common/nodes/NodeUniform';
import Matrix3NodeUniform from '../../renderers/common/nodes/NodeUniform';
import Matrix4NodeUniform from '../../renderers/common/nodes/NodeUniform';

import REVISION from 'three';
import RenderTarget from 'three';
import Color from 'three';
import Vector2 from 'three';
import Vector3 from 'three';
import Vector4 from 'three';
import IntType from 'three';
import UnsignedIntType from 'three';
import Float16BufferAttribute from 'three';

import stack from './StackNode';
import getCurrentStack from '../shadernode/ShaderNode';
import setCurrentStack from '../shadernode/ShaderNode';

import CubeRenderTarget from '../../renderers/common/CubeRenderTarget';
import ChainMap from '../../renderers/common/ChainMap';
import PMREMGenerator from '../../renderers/common/extras/PMREMGenerator';

class NodeBuilder {
    private var object:Object;
    private var material:NodeMaterial;
    private var geometry:Object;
    private var renderer:Object;
    private var parser:Object;
    private var scene:Object;
    private var nodes:Array<Node>;
    private var updateNodes:Array<Node>;
    private var updateBeforeNodes:Array<Node>;
    private var hashNodes:Map<String, Node>;
    private var lightsNode:Node;
    private var environmentNode:Node;
    private var fogNode:Node;
    private var clippingContext:Object;
    private var vertexShader:String;
    private var fragmentShader:String;
    private var computeShader:String;
    private var flowNodes:Map<String, Array<Node>>;
    private var flowCode:Map<String, String>;
    private var uniforms:Map<String, Array<Node>>;
    private var structs:Map<String, Array<Node>>;
    private var bindings:Map<String, Array<Node>>;
    private var bindingsOffset:Map<String, Int>;
    private var bindingsArray:Array<Node>;
    private var attributes:Array<NodeAttribute>;
    private var bufferAttributes:Array<NodeAttribute>;
    private var varyings:Array<NodeVarying>;
    private var codes:Map<String, NodeCode>;
    private var vars:Map<String, NodeVar>;
    private var flow:String;
    private var chaining:Array<Node>;
    private var stack:Array<Node>;
    private var stacks:Array<Array<Node>>;
    private var tab:String;
    private var currentFunctionNode:Node;
    private var context:NodeKeywords;
    private var cache:NodeCache;
    private var globalCache:NodeCache;
    private var flowsData:WeakMap<Node, Dynamic>;
    private var shaderStage:Null<Node>;
    private var buildStage:Null<Node>;

    public function new(object:Object, renderer:Object, parser:Object, scene:Object = null, material:NodeMaterial = null) {
        this.object = object;
        this.material = material != null ? material : (object != null ? object.material : null);
        this.geometry = object != null ? object.geometry : null;
        this.renderer = renderer;
        this.parser = parser;
        this.scene = scene;
        this.nodes = [];
        this.updateNodes = [];
        this.updateBeforeNodes = [];
        this.hashNodes = new Map<String, Node>();
        this.lightsNode = null;
        this.environmentNode = null;
        this.fogNode = null;
        this.clippingContext = null;
        this.vertexShader = null;
        this.fragmentShader = null;
        this.computeShader = null;
        this.flowNodes = [vertex => [], fragment => [], compute => []];
        this.flowCode = [vertex => '', fragment => '', compute => ''];
        this.uniforms = [vertex => [], fragment => [], compute => [], index => 0];
        this.structs = [vertex => [], fragment => [], compute => [], index => 0];
        this.bindings = [vertex => [], fragment => [], compute => []];
        this.bindingsOffset = [vertex => 0, fragment => 0, compute => 0];
        this.bindingsArray = null;
        this.attributes = [];
        this.bufferAttributes = [];
        this.varyings = [];
        this.codes = new Map<String, NodeCode>();
        this.vars = new Map<String, NodeVar>();
        this.flow = '';
        this.chaining = [];
        this.stack = stack();
        this.stacks = [];
        this.tab = '\t';
        this.currentFunctionNode = null;
        this.context = { keywords: new NodeKeywords(), material: this.material };
        this.cache = new NodeCache();
        this.globalCache = this.cache;
        this.flowsData = new WeakMap<Node, Dynamic>();
        this.shaderStage = null;
        this.buildStage = null;
    }

    public function createRenderTarget(width:Int, height:Int, options:Object):RenderTarget {
        return new RenderTarget(width, height, options);
    }

    public function createCubeRenderTarget(size:Int, options:Object):CubeRenderTarget {
        return new CubeRenderTarget(size, options);
    }

    public function createPMREMGenerator():PMREMGenerator {
        return new PMREMGenerator(this.renderer);
    }

    public function includes(node:Node):Bool {
        return this.nodes.includes(node);
    }

    private function _getSharedBindings(bindings:Array<Node>):Array<Node> {
        var shared:Array<Node> = [];
        for (binding in bindings) {
            if (binding.shared) {
                var nodes:Array<Node> = binding.getNodes();
                var sharedBinding:Node = uniformsGroupCache.get(nodes);
                if (sharedBinding == null) {
                    uniformsGroupCache.set(nodes, binding);
                    sharedBinding = binding;
                }
                shared.push(sharedBinding);
            } else {
                shared.push(binding);
            }
        }
        return shared;
    }

    public function getBindings():Array<Node> {
        if (bindingsArray == null) {
            var bindings:Array<Node> = this.bindings;
            bindingsArray = _getSharedBindings((material != null) ? [...bindings.vertex, ...bindings.fragment] : bindings.compute);
        }
        return bindingsArray;
    }

    public function setHashNode(node:Node, hash:String) {
        this.hashNodes.set(hash, node);
    }

    public function addNode(node:Node) {
        if (!this.nodes.includes(node)) {
            this.nodes.push(node);
            this.setHashNode(node, node.getHash(this));
        }
    }

    public function buildUpdateNodes() {
        for (node in this.nodes) {
            var updateType:Int = node.getUpdateType();
            var updateBeforeType:Int = node.getUpdateBeforeType();
            if (updateType != NodeUpdateType.NONE) {
                this.updateNodes.push(node.getSelf());
            }
            if (updateBeforeType != NodeUpdateType.NONE) {
                this.updateBeforeNodes.push(node);
            }
        }
    }

    public function get_currentNode():Node {
        return this.chaining[this.chaining.length - 1];
    }

    public function addChain(node:Node) {
        if (this.chaining.indexOf(node) != -1) {
            Console.warn('Recursive node: ', node);
        }
        this.chaining.push(node);
    }

    public function removeChain(node:Node) {
        var lastChain:Node = this.chaining.pop();
        if (lastChain != node) {
            throw new Error('NodeBuilder: Invalid node chaining!');
        }
    }

    public function getMethod(method:Dynamic) {
        return method;
    }

    public function getNodeFromHash(hash:String):Node {
        return this.hashNodes.get(hash);
    }

    public function addFlow(shaderStage:String, node:Node) {
        this.flowNodes.get(shaderStage).push(node);
        return node;
    }

    public function setContext(context:NodeKeywords) {
        this.context = context;
    }

    public function getContext():NodeKeywords {
        return this.context;
    }

    public function setCache(cache:NodeCache) {
        this.cache = cache;
    }

    public function getCache():NodeCache {
        return this.cache;
    }

    public function isAvailable(name:String):Bool {
        return false;
    }

    public function getVertexIndex():Int {
        Console.warn('Abstract function.');
        return 0;
    }

    public function getInstanceIndex():Int {
        Console.warn('Abstract function.');
        return 0;
    }

    public function getFrontFacing():Bool {
        Console.warn('Abstract function.');
        return false;
    }

    public function getFragCoord():Dynamic {
        Console.warn('Abstract function.');
        return null;
    }

    public function isFlipY():Bool {
        return false;
    }

    public function generateTexture(texture:Dynamic, textureProperty:Dynamic, uvSnippet:Dynamic):Dynamic {
        Console.warn('Abstract function.');
        return null;
    }

    public function generateTextureLod(texture:Dynamic, textureProperty:Dynamic, uvSnippet:Dynamic, levelSnippet:Dynamic):Dynamic {
        Console.warn('Abstract function.');
        return null;
    }

    public function generateConst(type:String, value:Dynamic = null):String {
        if (value == null) {
            switch (type) {
                case 'float', 'int', 'uint':
                    value = 0;
                case 'bool':
                    value = false;
                case 'color':
                    value = new Color();
                case 'vec2':
                    value = new Vector2();
                case 'vec3':
                    value = new Vector3();
                case 'vec4':
                    value = new Vector4();
            }
        }
        switch (type) {
            case 'float':
                return toFloat(value);
            case 'int':
                return '${Math.round(value)}';
            case 'uint':
                return value >= 0 ? '${Math.round(value)}u' : '0u';
            case 'bool':
                return value ? 'true' : 'false';
            case 'color':
                return '${this.getType('vec3')}( ${toFloat(value.r)}, ${toFloat(value.g)}, ${toFloat(value.b)} )';
            default:
                var typeLength:Int = this.getTypeLength(type);
                var componentType:String = this.getComponentType(type);
                var generateConst:Dynamic = function(value:Dynamic) {
                    return this.generateConst(componentType, value);
                };
                switch (typeLength) {
                    case 2:
                        return '${this.getType(type)}( ${generateConst(value.x)}, ${generateConst(value.y)} )';
                    case 3:
                        return '${this.getType(type)}( ${generateConst(value.x)}, ${generateConst(value.y)}, ${generateConst(value.z)} )';
                    case 4:
                        return '${this.getType(type)}( ${generateConst(value.x)}, ${generateConst(value.y)}, ${generateConst(value.z)}, ${generateConst(value.w)} )';
                    default:
                        throw new Error('NodeBuilder: Type \'' + type + '\' not found in generate constant attempt.');
                }
        }
    }

    public function getType(type:String):String {
        if (type == 'color') return 'vec3';
        return type;
    }

    public function generateMethod(method:Dynamic) {
        return method;
    }

    public function hasGeometryAttribute(name:String):Bool {
        return this.geometry != null && this.geometry.getAttribute(name) != null;
    }

    public function getAttribute(name:String, type:String):NodeAttribute {
        var attributes:Array<NodeAttribute> = this.attributes;
        for (attribute in attributes) {
            if (attribute.name == name) {
                return attribute;
            }
        }
        var attribute:NodeAttribute = new NodeAttribute(name, type);
        attributes.push(attribute);
        return attribute;
    }

    public function getPropertyName(node:Node/*, shaderStage:String*/):String {
        return node.name;
    }

    public function isVector(type:String):Bool {
        return ~/vec\d/.test(type);
    }

    public function isMatrix(type:String):Bool {
        return ~/mat\d/.test(type);
    }

    public function isReference(type:String):Bool {
        return type == 'void' || type == 'property' || type == 'sampler' || type == 'texture' || type == 'cubeTexture' || type == 'storageTexture';
    }

    public function needsColorSpaceToLinear(texture:Dynamic):Bool {
        return false;
    }

    public function getComponentTypeFromTexture(texture:Dynamic):String {
        var type:String = texture.type;
        if (texture.isDataTexture) {
            if (type == IntType) return 'int';
            if (type == UnsignedIntType) return 'uint';
        }
        return 'float';
    }

    public function getComponentType(type:String):String {
        type = this.getVectorType(type);
        if (type == 'float' || type == 'bool' || type == 'int' || type == 'uint') return type;
        var componentType:String = ~/^(b|i|u)?(vec|mat)([2-4])$/.exec(type);
        if (componentType == null) return null;
        if (componentType[1] == 'b') return 'bool';
        if (componentType[1] == 'i') return 'int';
        if (componentType[1] == 'u') return 'uint';
        return 'float';
    }

    public function getVectorType(type:String):String {
        if (type == 'color') return 'vec3';
        if (type == 'texture' || type == 'cubeTexture' || type == 'storageTexture') return 'vec4';
        return type;
    }

    public function getTypeFromLength(length:Int, componentType:String = 'float'):String {
        if (length == 1) return componentType;
        var baseType:String = typeFromLength.get(length);
        var prefix:String = componentType == 'float' ? '' : componentType.charAt(0);
        return prefix + baseType;
    }
}