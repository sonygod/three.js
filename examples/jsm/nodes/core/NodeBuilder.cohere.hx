import NodeUniform from './NodeUniform.hx';
import NodeAttribute from './NodeAttribute.hx';
import NodeVarying from './NodeVarying.hx';
import NodeVar from './NodeVar.hx';
import NodeCode from './NodeCode.hx';
import NodeKeywords from './NodeKeywords.hx';
import NodeCache from './NodeCache.hx';
import ParameterNode from './ParameterNode.hx';
import FunctionNode from '../code/FunctionNode.hx';
import { createNodeMaterialFromType, default as NodeMaterial } from '../materials/NodeMaterial.hx';
import { NodeUpdateType, defaultBuildStages, shaderStages } from './constants.hx';

import { FloatNodeUniform, Vector2NodeUniform, Vector3NodeUniform, Vector4NodeUniform, ColorNodeUniform, Matrix3NodeUniform, Matrix4NodeUniform } from '../../renderers/common/nodes/NodeUniform.hx';

import { REVISION, RenderTarget, Color, Vector2, Vector3, Vector4, IntType, UnsignedIntType, Float16BufferAttribute } from 'three';

import { stack } from './StackNode.hx';
import { getCurrentStack, setCurrentStack } from '../shadernode/ShaderNode.hx';

import CubeRenderTarget from '../../renderers/common/CubeRenderTarget.hx';
import ChainMap from '../../renderers/common/ChainMap.hx';

import PMREMGenerator from '../../renderers/common/extras/PMREMGenerator.hx';

const uniformsGroupCache = new ChainMap();

const typeFromLength = new Map([
    [2, 'vec2'],
    [3, 'vec3'],
    [4, 'vec4'],
    [9, 'mat3'],
    [16, 'mat4']
]);

const typeFromArray = new Map([
    [Int8Array, 'int'],
    [Int16Array, 'int'],
    [Int32Array, 'int'],
    [Uint8Array, 'uint'],
    [Uint16Array, 'uint'],
    [Uint32Array, 'uint'],
    [Float32Array, 'float']
]);

function toFloat(value:Float) {
    value = value.toFloat();
    return value + (value % 1 ? '' : '.0');
}

class NodeBuilder {
    public object:Dynamic;
    public material:NodeMaterial;
    public geometry:Dynamic;
    public renderer:Dynamic;
    public parser:Dynamic;
    public scene:Dynamic;
    public nodes:Array<Dynamic>;
    public updateNodes:Array<Dynamic>;
    public updateBeforeNodes:Array<Dynamic>;
    public hashNodes:Map<String, Dynamic>;
    public lightsNode:Dynamic;
    public environmentNode:Dynamic;
    public fogNode:Dynamic;
    public clippingContext:Dynamic;
    public vertexShader:Dynamic;
    public fragmentShader:Dynamic;
    public computeShader:Dynamic;
    public flowNodes:Map<String, Array<Dynamic>>;
    public flowCode:Map<String, String>;
    public uniforms:Map<String, Array<Dynamic>>;
    public index:Int;
    public structs:Map<String, Array<Dynamic>>;
    public bindings:Map<String, Array<Dynamic>>;
    public bindingsOffset:Map<String, Int>;
    public bindingsArray:Dynamic;
    public attributes:Array<Dynamic>;
    public bufferAttributes:Array<Dynamic>;
    public varyings:Array<Dynamic>;
    public codes:Map<String, Array<Dynamic>>;
    public vars:Map<String, Array<Dynamic>>;
    public flow:Map<String, String>;
    public chaining:Array<Dynamic>;
    public stack:Dynamic;
    public stacks:Array<Dynamic>;
    public tab:String;
    public currentFunctionNode:Dynamic;
    public context:Map<String, Dynamic>;
    public cache:NodeCache;
    public globalCache:NodeCache;
    public flowsData:WeakMap<Dynamic, Dynamic>;
    public shaderStage:Dynamic;
    public buildStage:Dynamic;

    public function new(object:Dynamic, renderer:Dynamic, parser:Dynamic, ?scene:Dynamic, ?material:NodeMaterial) {
        this.object = object;
        this.material = material ?? (object?.material ?? null);
        this.geometry = (object?.geometry ?? null);
        this.renderer = renderer;
        this.parser = parser;
        this.scene = scene;

        this.nodes = [];
        this.updateNodes = [];
        this.updateBeforeNodes = [];
        this.hashNodes = new Map();

        this.lightsNode = null;
        this.environmentNode = null;
        this.fogNode = null;

        this.clippingContext = null;

        this.vertexShader = null;
        this.fragmentShader = null;
        this.computeShader = null;

        this.flowNodes = {
            vertex: [],
            fragment: [],
            compute: []
        };
        this.flowCode = {
            vertex: '',
            fragment: '',
            compute: []
        };
        this.uniforms = {
            vertex: [],
            fragment: [],
            compute: [],
            index: 0
        };
        this.structs = {
            vertex: [],
            fragment: [],
            compute: [],
            index: 0
        };
        this.bindings = {
            vertex: [],
            fragment: [],
            compute: []
        };
        this.bindingsOffset = {
            vertex: 0,
            fragment: 0,
            compute: 0
        };
        this.bindingsArray = null;
        this.attributes = [];
        this.bufferAttributes = [];
        this.varyings = [];
        this.codes = {};
        this.vars = {};
        this.flow = {
            code: ''
        };
        this.chaining = [];
        this.stack = stack();
        this.stacks = [];
        this.tab = '\t';

        this.currentFunctionNode = null;

        this.context = {
            keywords: new NodeKeywords(),
            material: this.material
        };

        this.cache = new NodeCache();
        this.globalCache = this.cache;

        this.flowsData = new WeakMap();

        this.shaderStage = null;
        this.buildStage = null;
    }

    public function createRenderTarget(width:Int, height:Int, options:Dynamic) {
        return new RenderTarget(width, height, options);
    }

    public function createCubeRenderTarget(size:Int, options:Dynamic) {
        return new CubeRenderTarget(size, options);
    }

    public function createPMREMGenerator() {
        // TODO: Move Materials.hx to outside of the Nodes.hx in order to remove this function and improve tree-shaking support
        return new PMREMGenerator(this.renderer);
    }

    public function includes(node:Dynamic) {
        return this.nodes.includes(node);
    }

    public function _getSharedBindings(bindings:Dynamic) {
        var shared = [];

        for (binding in bindings) {
            if (binding.shared == true) {
                // nodes is the chainmap key
                var nodes = binding.getNodes();

                var sharedBinding = uniformsGroupCache.get(nodes);

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

    public function getBindings() {
        if (this.bindingsArray == null) {
            var bindings = this.bindings;

            this.bindingsArray = this._getSharedBindings((this.material != null) ? [...bindings.vertex, ...bindings.fragment] : bindings.compute);
        }

        return this.bindingsArray;
    }

    public function setHashNode(node:Dynamic, hash:String) {
        this.hashNodes.set(hash, node);
    }

    public function addNode(node:Dynamic) {
        if (!this.nodes.includes(node)) {
            this.nodes.push(node);
            this.setHashNode(node, node.getHash(this));
        }
    }

    public function buildUpdateNodes() {
        for (node in this.nodes) {
            var updateType = node.getUpdateType();
            var updateBeforeType = node.getUpdateBeforeType();

            if (updateType != NodeUpdateType.NONE) {
                this.updateNodes.push(node.getSelf());
            }

            if (updateBeforeType != NodeUpdateType.NONE) {
                this.updateBeforeNodes.push(node);
            }
        }
    }

    public function get currentNode():Dynamic {
        return this.chaining[this.chaining.length - 1];
    }

    public function addChain(node:Dynamic) {
        /*
        if (this.chaining.indexOf(node) != -1) {
            console.warn('Recursive node: ', node);
        }
        */
        this.chaining.push(node);
    }

    public function removeChain(node:Dynamic) {
        var lastChain = this.chaining.pop();

        if (lastChain != node) {
            throw new Error('NodeBuilder: Invalid node chaining!');
        }
    }

    public function getMethod(method:Dynamic) {
        return method;
    }

    public function getNodeFromHash(hash:String) {
        return this.hashNodes.get(hash);
    }

    public function addFlow(shaderStage:String, node:Dynamic) {
        this.flowNodes.get(shaderStage).push(node);
        return node;
    }

    public function setContext(context:Dynamic) {
        this.context = context;
    }

    public function getContext() {
        return this.context;
    }

    public function setCache(cache:NodeCache) {
        this.cache = cache;
    }

    public function getCache() {
        return this.cache;
    }

    public function isAvailable(/*name*/) {
        return false;
    }

    public function getVertexIndex() {
        throw new Error('Abstract function.');
    }

    public function getInstanceIndex() {
        throw new Error('Abstract function.');
    }

    public function getFrontFacing() {
        throw new Error('Abstract function.');
    }

    public function getFragCoord() {
        throw new Error('Abstract function.');
    }

    public function isFlipY() {
        return false;
    }

    public function generateTexture(/* texture, textureProperty, uvSnippet */) {
        throw new Error('Abstract function.');
    }

    public function generateTextureLod(/* texture, textureProperty, uvSnippet, levelSnippet */) {
        throw new Error('Abstract function.');
    }

    public function generateConst(type:String, ?value:Dynamic) {
        if (value == null) {
            if (type == 'float' || type == 'int' || type == 'uint') value = 0;
            else if (type == 'bool') value = false;
            else if (type == 'color') value = new Color();
            else if (type == 'vec2') value = new Vector2();
            else if (type == 'vec3') value = new Vector3();
            else if (type == 'vec4') value = new Vector4();
        }

        if (type == 'float') return toFloat(value);
        if (type == 'int') return Std.string(value);
        if (type == 'uint') return (value >= 0 ? Std.string(value) : '0u');
        if (type == 'bool') return (value ? 'true' : 'false');
        if (type == 'color') return `${this.getType('vec3')}(${toFloat(value.r)}, ${toFloat(value.g)}, ${toFloat(value.b)})`;

        var typeLength = this.getTypeLength(type);

        var componentType = this.getComponentType(type);

        function generateConst(value:Dynamic) {
            return this.generateConst(componentType, value);
        }

        if (typeLength == 2) {
            return `${this.getType(type)}(${generateConst(value.x)}, ${generateConst(value.y)})`;
        } else if (typeLength == 3) {
            return `${this.getType(type)}(${generateConst(value.x)}, ${generateConst(value.y)}, ${generateConst(value.z)})`;
        } else if (typeLength == 4) {
            return `${this.getType(type)}(${generateConst(value.x)}, ${generateConst(value.y)}, ${generateConst(value.z)}, ${generateConst(value.w)})`;
        } else if (typeLength > 4 && (value?.isMatrix3 ?? value?.isMatrix4)) {
            return `${this.getType(type)}(${value.elements.map(generateConst).join(', ')})`;
        } else if (typeLength > 4) {
            return `${this.getType(type)}()`;
        }

        throw new Error(`NodeBuilder: Type '${type}' not found in generate constant attempt.`);
    }

    public function getType(type:String) {
        if (type == 'color') return 'vec3';

        return type;
    }

    public function generateMethod(method:Dynamic) {
        return method;
    }

    public function hasGeometryAttribute(name:String) {
        return (this.geometry != null) && this.geometry.getAttribute(name) != null;
    }

    public function getAttribute(name:String, type:String) {
        for (attribute in this.attributes) {
            if (attribute.name == name) {
                return attribute;
            }
        }

        // create a new if no exist
        var attribute = new NodeAttribute(name, type);

        this.attributes.push(attribute);

        return attribute;
    }

    public function getPropertyName(node:Dynamic, /*shaderStage*/) {
        return node.name;
    }

    public function isVector(type:String) {
        return /vec\d/.match(type);
    }

    public function isMatrix(type:String) {
        return /mat\d/.match(type);
    }

    public function isReference(type:String) {
        return type == 'void' || type == 'property' || type == 'sampler' || type == 'texture' || type == 'cubeTexture' || type == 'storageTexture';
    }

    public function needsColorSpaceToLinear(/*texture*/) {
        return false;
    }

    public function getComponentTypeFromTexture(texture:Dynamic) {
        var type = texture.type;

        if (texture.isDataTexture) {
            if (type == IntType) return 'int';
            if (type == UnsignedIntType) return 'uint';
        }

        return 'float';
    }

    public function getComponentType(type:String) {
        type = this.getVectorType(type);

        if (type == 'float' || type == 'bool' || type == 'int' || type == 'uint') return type;

        var componentType = /(b|i|u|)(vec|mat)([2-4])/.exec(type);

        if (componentType == null) return null;

        if (componentType[1] == 'b') return 'bool';
        if (componentType[1] == 'i') return 'int';
        if (componentType[1] == 'u') return 'uint';

        return 'float';
    }

    public function getVectorType(type:String) {
        if (type == 'color') return 'vec3';
        if (type == 'texture' || type == 'cubeTexture' || type == 'storageTexture') return 'vec4';

        return type;
    }

    public function getTypeFromLength(length:Int, componentType:String = 'float') {
        if (length == 1) return componentType;

        var baseType = typeFromLength.get(length);
        var prefix = (componentType == 'float' ? '' : componentType[0]);

        return prefix + baseType;
    }

    public function getTypeFromArray(array:Dynamic) {
        return typeFromArray.get(array.constructor);
    }

    public function getTypeFromAttribute(attribute:Dynamic) {
        var dataAttribute = attribute;

        if (attribute.isInterleavedBufferAttribute) dataAttribute = attribute.data;

        var array = dataAttribute.array;
        var itemSize = attribute.itemSize;
        var normalized = attribute.normalized;

        var arrayType:String;

        if (! (attribute instanceof Float16BufferAttribute) && normalized != true) {
            arrayType = this.getTypeFromArray(array);
        }

        return this.getTypeFromLength(itemSize, arrayType);
    }

    public function getTypeLength(type:String) {
        var vecType = this.getVectorType(type);
        var vecNum = /vec([2-4])/.exec(vecType);

        if (vecNum != null) return Std.parseInt(vecNum[1]);
        if (vecType == 'float' || vecType == 'bool' || vecType == 'int' || vecType == 'uint') return 1;
        if (/mat2/.match(type) == true) return 4;
        if (/mat3/.match(type) == true) return 9;
        if (/mat4/.match(type) == true) return 16;

        return 0;
    }

    public function getVectorFromMatrix(type:String) {
        return type.replace('mat', 'vec');
    }

    public function changeComponentType(type:String, newComponentType:String) {
        return this.getTypeFromLength(this.getTypeLength(type), newComponentType);
    }

    public function getIntegerType(type:String) {
        var componentType = this.getComponentType(type);

        if (componentType == 'int' || componentType == 'uint') return type;

        return this.changeComponentType(type, 'int');
    }

    public function addStack() {
        this.stack = stack(this.stack);

        this.stacks.push(getCurrentStack() ?? this.stack);
        setCurrentStack(this.stack);

        return this.stack;
    }

    public function removeStack() {
        var lastStack = this.stack;
        this.stack = lastStack.parent;

        setCurrentStack(this.stacks.pop());

        return lastStack;
    }

    public function getDataFromNode(node:Dynamic, shaderStage:String = this.shaderStage, cache:NodeCache = null) {
        cache = cache ?? (node.isGlobal(this)
? this.globalCache : this.cache);

        var nodeData = cache.getNodeData(node);

        if (nodeData == null) {
            nodeData = {};

            cache.setNodeData(node, nodeData);
        }

        if (nodeData[shaderStage] == null) nodeData[shaderStage] = {};

        return nodeData[shaderStage];
    }

    public function getNodeProperties(node:Dynamic, shaderStage:String = 'any') {
        var nodeData = this.getDataFromNode(node, shaderStage);

        return nodeData.properties ?? (nodeData.properties = { outputNode: null });
    }

    public function getBufferAttributeFromNode(node:Dynamic, type:String) {
        var nodeData = this.getDataFromNode(node);

        var bufferAttribute = nodeData.bufferAttribute;

        if (bufferAttribute == null) {
            var index = this.uniforms.index++;

            bufferAttribute = new NodeAttribute('nodeAttribute' + index, type, node);

            this.bufferAttributes.push(bufferAttribute);

            nodeData.bufferAttribute = bufferAttribute;
        }

        return bufferAttribute;
    }

    public function getStructTypeFromNode(node:Dynamic, shaderStage:String = this.shaderStage) {
        var nodeData = this.getDataFromNode(node, shaderStage);

        if (nodeData.structType == null) {
            var index = this.structs.index++;

            node.name = 'StructType' + index;
            this.structs[shaderStage].push(node);

            nodeData.structType = node;
        }

        return node;
    }

    public function getUniformFromNode(node:Dynamic, type:String, shaderStage:String = this.shaderStage, name:String = null) {
        var nodeData = this.getDataFromNode(node, shaderStage, this.globalCache);

        var nodeUniform = nodeData.uniform;

        if (nodeUniform == null) {
            var index = this.uniforms.index++;

            nodeUniform = new NodeUniform(name ?? ('nodeUniform' + index), type, node);

            this.uniforms[shaderStage].push(nodeUniform);

            nodeData.uniform = nodeUniform;
        }

        return nodeUniform;
    }

    public function getVarFromNode(node:Dynamic, name:String = null, type:String = node.getNodeType(this), shaderStage:String = this.shaderStage) {
        var nodeData = this.getDataFromNode(node, shaderStage);

        var nodeVar = nodeData.variable;

        if (nodeVar == null) {
            var vars = this.vars[shaderStage] ?? (this.vars[shaderStage] = []);

            if (name == null) name = 'nodeVar' + vars.length;

            nodeVar = new NodeVar(name, type);

            vars.push(nodeVar);

            nodeData.variable = nodeVar;
        }

        return nodeVar;
    }

    public function getVaryingFromNode(node:Dynamic, name:String = null, type:String = node.getNodeType(this)) {
        var nodeData = this.getDataFromNode(node, 'any');

        var nodeVarying = nodeData.varying;

        if (nodeVarying == null) {
            var varyings = this.varyings;
            var index = varyings.length;

            if (name == null) name = 'nodeVarying' + index;

            nodeVarying = new NodeVarying(name, type);

            varyings.push(nodeVarying);

            nodeData.varying = nodeVarying;
        }

        return nodeVarying;
    }

    public function getCodeFromNode(node:Dynamic, type:String, shaderStage:String = this.shaderStage) {
        var nodeData = this.getDataFromNode(node);

        var nodeCode = nodeData.code;

        if (nodeCode == null) {
            var codes = this.codes[shaderStage] ?? (this.codes[shaderStage] = []);
            var index = codes.length;

            nodeCode = new NodeCode('nodeCode' + index, type);

            codes.push(nodeCode);

            nodeData.code = nodeCode;
        }

        return nodeCode;
    }

    public function addLineFlowCode(code:String) {
        if (code == '') return this;

        code = this.tab + code;

        if (!/;\s*$/.match(code)) {
            code += ';';
        }

        this.flow.code += code + '\n';

        return this;
    }

    public function addFlowCode(code:String) {
        this.flow.code += code;

        return this;
    }

    public function addFlowTab() {
        this.tab += '\t';

        return this;
    }

    public function removeFlowTab() {
        this.tab = this.tab.substr(0, -1);

        return this;
    }

    public function getFlowData(node:Dynamic, /*shaderStage*/) {
        return this.flowsData.get(node);
    }

    public function flowNode(node:Dynamic) {
        var output = node.getNodeType(this);

        var flowData = this.flowChildNode(node, output);

        this.flowsData.set(node, flowData);

        return flowData;
    }

    public function buildFunctionNode(shaderNode:Dynamic) {
        var fn = new FunctionNode();

        var previous = this.currentFunctionNode;

        this.currentFunctionNode = fn;

        fn.code = this.buildFunctionCode(shaderNode);

        this.currentFunctionNode = previous;

        return fn;
    }

    public function flowShaderNode(shaderNode:Dynamic) {
        var layout = shaderNode.layout;

        var inputs:Array<Dynamic>;

        if (shaderNode.isArrayInput) {
            inputs = [];

            for (input in layout.inputs) {
                inputs.push(new ParameterNode(input.type, input.name));
            }
        } else {
            inputs = {};

            for (input in layout.inputs) {
                inputs[input.name] = new ParameterNode(input.type, input.name);
            }
        }

        //

        shaderNode.layout = null;

        var callNode = shaderNode.call(inputs);
        var flowData = this.flowStagesNode(callNode, layout.type);

        shaderNode.layout = layout;

        return flowData;
    }

    public function flowStagesNode(node:Dynamic, output:Dynamic = null) {
        var previousFlow = this.flow;
        var previousVars = this.vars;
        var previousBuildStage = this.buildStage;

        var flow = {
            code: ''
        };

        this.flow = flow;
        this.vars = {};

        for (buildStage in defaultBuildStages) {
            this.setBuildStage(buildStage);

            flow.result = node.build(this, output);
        }

        flow.vars = this.getVars(this.shaderStage);

        this.flow = previousFlow;
        this.vars = previousVars;
        this.setBuildStage(previousBuildStage);

        return flow;
    }

    public function getFunctionOperator() {
        return null;
    }

    public function flowChildNode(node:Dynamic, output:Dynamic = null) {
        var previousFlow = this.flow;

        var flow = {
            code: ''
        };

        this.flow = flow;

        flow.result = node.build(this, output);

        this.flow = previousFlow;

        return flow;
    }

    public function flowNodeFromShaderStage(shaderStage:String, node:Dynamic, output:Dynamic = null, propertyName:String = null) {
        var previousShaderStage = this.shaderStage;

        this.setShaderStage(shaderStage);

        var flowData = this.flowChildNode(node, output);

        if (propertyName != null) {
            flowData.code += `${this.tab + propertyName} = ${flowData.result};\n`;
        }

        this.flowCode[shaderStage] = this.flowCode[shaderStage] + flowData.code;

        this.setShaderStage(previousShaderStage);

        return flowData;
    }

    public function getAttributesArray() {
        return this.attributes.concat(this.bufferAttributes);
    }

    public function getAttributes(/*shaderStage*/) {
        throw new Error('Abstract function.');
    }

    public function getVaryings(/*shaderStage*/) {
        throw new Error('Abstract function.');
    }

    public function getVar(type:String, name:String) {
        return `${this.getType(type)} ${name}`;
    }

    public function getVars(shaderStage:String) {
        var snippet = '';

        var vars = this.vars[shaderStage];

        if (vars != null) {
            for (variable in vars) {
                snippet += `${this.getVar(variable.type, variable.name)}; `;
            }
        }

        return snippet;
    }

    public function getUniforms(/*shaderStage*/) {
        throw new Error('Abstract function.');
    }

    public function getCodes(shaderStage:String) {
        var codes = this.codes[shaderStage];

        var code = '';

        if (codes != null) {
            for (nodeCode in codes) {
                code += nodeCode.code + '\n';
            }
        }

        return code;
    }

    public function getHash() {
        return this.vertexShader + this.fragmentShader + this.computeShader;
    }

    public function setShaderStage(shaderStage:Dynamic) {
        this.shaderStage = shaderStage;
    }

    public function getShaderStage() {
        return this.shaderStage;
    }

    public function setBuildStage(buildStage:Dynamic) {
        this.buildStage = buildStage;
    }

    public function getBuildStage() {
        return this.buildStage;
    }

    public function buildCode() {
        throw new Error('Abstract function.');
    }

    public function build() {
        var { object, material } = this;

        if (material != null) {
            NodeMaterial.fromMaterial(material).build(this);
        } else {
            this.addFlow('compute', object);
        }

        // setup() -> stage 1: create possible new nodes and returns an output reference node
        // analyze()   -> stage 2: analyze nodes to possible optimization and validation
        // generate()  -> stage 3: generate shader

        for (buildStage in defaultBuildStages) {
            this.setBuildStage(buildStage);

            if (this.context.vertex != null && this.context.vertex.isNode) {
                this.flowNodeFromShaderStage('vertex', this.context.vertex);
            }

            for (shaderStage in shaderStages) {
                this.setShaderStage(shaderStage);

                var flowNodes = this.flowNodes[shaderStage];

                for (node in flowNodes) {
                    if (buildStage == 'generate') {
                        this.flowNode(node);
                    } else {
                        node.build(this);
                    }
                }
            }
        }

        this.setBuildStage(null);
        this.setShaderStage(null);

        // stage 4: build code for a specific output

        this.buildCode();
        this.buildUpdateNodes();

        return this;
    }

    public function getNodeUniform(uniformNode:Dynamic, type:String) {
        if (type == 'float') return new FloatNodeUniform(uniformNode);
        if (type == 'vec2') return new Vector2NodeUniform(uniformNode);
        if (type == 'vec3') return new Vector3NodeUniform(uniformNode);
        if (type == 'vec4') return new Vector4NodeUniform(uniformNode);
        if (type == 'color') return new ColorNodeUniform(uniformNode);
        if (type == 'mat3') return new Matrix3NodeUniform(uniformNode);
        if (type == 'mat4') return new Matrix4NodeUniform(uniformNode);

        throw new Error(`Uniform "${type}" not declared.`);
    }

    public function createNodeMaterial(type:String = 'NodeMaterial') {
        // TODO: Move Materials.hx to outside of the Nodes.hx in order to remove this function and improve tree-shaking support
        return createNodeMaterialFromType(type);
    }

    public function format(snippet:String, fromType:String, toType:String) {
        fromType = this.getVectorType(fromType);
        toType = this.getVectorType(toType);

        if (fromType == toType || toType == null || this.isReference(toType)) {
            return snippet;
        }

        var fromTypeLength = this.getTypeLength(fromType);
        var toTypeLength = this.getTypeLength(toType);

        if (fromTypeLength > 4) { // fromType is matrix-like
            // @TODO: ignore for now
            return snippet;
        }

        if (toTypeLength > 4 || toTypeLength == 0) { // toType is matrix-like or unknown
            // @TODO: ignore for now
            return snippet;
        }

        if (fromTypeLength == toTypeLength) {
            return `${this.getType(toType)}(${snippet})`;
        }

        if (fromTypeLength > toTypeLength) {
            return this.format(`${snippet}.${'xyz'.substr(0, toTypeLength)}`, this.getTypeFromLength(toTypeLength, this.getComponentType(fromType)), toType);
        }

        if (toTypeLength == 4 && fromTypeLength > 1) { // toType is vec4-like
            return `${this.getType(toType)}(${this.format(snippet, fromType, 'vec3')}, 1.0)`;
        }

        if (fromTypeLength == 2) { // fromType is vec2-like and toType is vec3-like
            return `${this.getType(toType)}(${this.format(snippet, fromType, 'vec2')}, 0.0)`;
        }

        if (fromTypeLength == 1 && toTypeLength > 1 && fromType[0] != toType[0]) { // fromType is float-like
            // convert a number value to vector type, e.g:
            // vec3(1u) -> vec3(float(1u))

            snippet = `${this.getType(this.getComponentType(toType))}(${snippet})`;
        }

        return `${this.getType(toType)}(${snippet})`; // fromType is float-like
    }

    public function getSignature() {
        return `// Three.js r${REVISION} - NodeMaterial System\n`;
    }
}

export default NodeBuilder;