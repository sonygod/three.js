package three.js.examples.jsm.nodes.core;

class NodeBuilder {
    // ...

    public function getTypeFromArray(array:Array<Dynamic>):String {
        return typeFromArray.get(array.constructor);
    }

    public function getTypeFromAttribute(attribute:Dynamic):String {
        var dataAttribute:Dynamic = attribute;
        if (attribute.isInterleavedBufferAttribute) dataAttribute = attribute.data;
        var array:Array<Dynamic> = dataAttribute.array;
        var itemSize:Int = attribute.itemSize;
        var normalized:Bool = attribute.normalized;

        var arrayType:String;
        if (!(attribute instanceof Float16BufferAttribute) && normalized != true) {
            arrayType = this.getTypeFromArray(array);
        }

        return this.getTypeFromLength(itemSize, arrayType);
    }

    public function getTypeLength(type:String):Int {
        var vecType:String = this.getVectorType(type);
        var vecNum:Array<String> = ~/vec([2-4])/.exec(vecType);

        if (vecNum != null) return Std.parseInt(vecNum[1]);
        if (vecType == 'float' || vecType == 'bool' || vecType == 'int' || vecType == 'uint') return 1;
        if (~/(mat2)/.test(vecType)) return 4;
        if (~/(mat3)/.test(vecType)) return 9;
        if (~/(mat4)/.test(vecType)) return 16;

        return 0;
    }

    public function getVectorType(type:String):String {
        return type.replace('mat', 'vec');
    }

    public function changeComponentType(type:String, newComponentType:String):String {
        return this.getTypeFromLength(this.getTypeLength(type), newComponentType);
    }

    public function getIntegerType(type:String):String {
        var componentType:String = this.getComponentType(type);

        if (componentType == 'int' || componentType == 'uint') return type;

        return this.changeComponentType(type, 'int');
    }

    public function addStack():Void {
        this.stack = stack(this.stack);

        this.stacks.push(getCurrentStack() || this.stack);
        setCurrentStack(this.stack);
    }

    public function removeStack():Void {
        var lastStack:Dynamic = this.stack;
        this.stack = lastStack.parent;

        setCurrentStack(this.stacks.pop());
    }

    public function getDataFromNode(node:Dynamic, shaderStage:String = this.shaderStage, cache:Dynamic = null):Dynamic {
        cache = cache == null ? (node.isGlobal(this) ? this.globalCache : this.cache) : cache;

        var nodeData:Dynamic = cache.getNodeData(node);

        if (nodeData == null) {
            nodeData = {};

            cache.setNodeData(node, nodeData);
        }

        if (nodeData[shaderStage] == null) nodeData[shaderStage] = {};

        return nodeData[shaderStage];
    }

    public function getNodeProperties(node:Dynamic, shaderStage:String = 'any'):Dynamic {
        var nodeData:Dynamic = this.getDataFromNode(node, shaderStage);

        return nodeData.properties == null ? (nodeData.properties = { outputNode: null }) : nodeData.properties;
    }

    public function getBufferAttributeFromNode(node:Dynamic, type:String):Dynamic {
        var nodeData:Dynamic = this.getDataFromNode(node);

        var bufferAttribute:Dynamic = nodeData.bufferAttribute;

        if (bufferAttribute == null) {
            var index:Int = this.uniforms.index++;

            bufferAttribute = new NodeAttribute('nodeAttribute' + index, type, node);

            this.bufferAttributes.push(bufferAttribute);

            nodeData.bufferAttribute = bufferAttribute;
        }

        return bufferAttribute;
    }

    public function getStructTypeFromNode(node:Dynamic, shaderStage:String = this.shaderStage):Dynamic {
        var nodeData:Dynamic = this.getDataFromNode(node, shaderStage);

        if (nodeData.structType == null) {
            var index:Int = this.structs.index++;

            node.name = 'StructType' + index;
            this.structs[shaderStage].push(node);

            nodeData.structType = node;
        }

        return node;
    }

    public function getUniformFromNode(node:Dynamic, type:String, shaderStage:String = this.shaderStage, name:String = null):Dynamic {
        var nodeData:Dynamic = this.getDataFromNode(node, shaderStage, this.globalCache);

        var nodeUniform:Dynamic = nodeData.uniform;

        if (nodeUniform == null) {
            var index:Int = this.uniforms.index++;

            nodeUniform = new NodeUniform(name == null ? 'nodeUniform' + index : name, type, node);

            this.uniforms[shaderStage].push(nodeUniform);

            nodeData.uniform = nodeUniform;
        }

        return nodeUniform;
    }

    public function getVarFromNode(node:Dynamic, name:String = null, type:String = node.getNodeType(this), shaderStage:String = this.shaderStage):Dynamic {
        var nodeData:Dynamic = this.getDataFromNode(node, shaderStage);

        var nodeVar:Dynamic = nodeData.variable;

        if (nodeVar == null) {
            var vars:Array<Dynamic> = this.vars[shaderStage] == null ? (this.vars[shaderStage] = []) : this.vars[shaderStage];

            if (name == null) name = 'nodeVar' + vars.length;

            nodeVar = new NodeVar(name, type);

            vars.push(nodeVar);

            nodeData.variable = nodeVar;
        }

        return nodeVar;
    }

    public function getVaryingFromNode(node:Dynamic, name:String = null, type:String = node.getNodeType(this)):Dynamic {
        var nodeData:Dynamic = this.getDataFromNode(node, 'any');

        var nodeVarying:Dynamic = nodeData.varying;

        if (nodeVarying == null) {
            var varyings:Array<Dynamic> = this.varyings;
            var index:Int = varyings.length;

            if (name == null) name = 'nodeVarying' + index;

            nodeVarying = new NodeVarying(name, type);

            varyings.push(nodeVarying);

            nodeData.varying = nodeVarying;
        }

        return nodeVarying;
    }

    public function getCodeFromNode(node:Dynamic, type:String, shaderStage:String = this.shaderStage):Dynamic {
        var nodeData:Dynamic = this.getDataFromNode(node);

        var nodeCode:Dynamic = nodeData.code;

        if (nodeCode == null) {
            var codes:Array<Dynamic> = this.codes[shaderStage] == null ? (this.codes[shaderStage] = []) : this.codes[shaderStage];
            var index:Int = codes.length;

            nodeCode = new NodeCode('nodeCode' + index, type);

            codes.push(nodeCode);

            nodeData.code = nodeCode;
        }

        return nodeCode;
    }

    public function addLineFlowCode(code:String):NodeBuilder {
        if (code == '') return this;

        code = this.tab + code;

        if (!~/;\s*$/.test(code)) {
            code += ';\n';
        }

        this.flow.code += code;

        return this;
    }

    public function addFlowCode(code:String):NodeBuilder {
        this.flow.code += code;

        return this;
    }

    public function addFlowTab():NodeBuilder {
        this.tab += '\t';

        return this;
    }

    public function removeFlowTab():NodeBuilder {
        this.tab = this.tab.substring(0, this.tab.length - 1);

        return this;
    }

    public function getFlowData(node:Dynamic/*, shaderStage:String*/):Dynamic {
        return this.flowsData.get(node);
    }

    public function flowNode(node:Dynamic):Dynamic {
        var output:String = node.getNodeType(this);

        var flowData:Dynamic = this.flowChildNode(node, output);

        this.flowsData.set(node, flowData);

        return flowData;
    }

    public function buildFunctionNode(shaderNode:Dynamic):Dynamic {
        var fn:Dynamic = new FunctionNode();

        var previous:Dynamic = this.currentFunctionNode;

        this.currentFunctionNode = fn;

        fn.code = this.buildFunctionCode(shaderNode);

        this.currentFunctionNode = previous;

        return fn;
    }

    public function flowShaderNode(shaderNode:Dynamic):Dynamic {
        var layout:Dynamic = shaderNode.layout;

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

        shaderNode.layout = null;

        var callNode:Dynamic = shaderNode.call(inputs);
        var flowData:Dynamic = this.flowStagesNode(callNode, layout.type);

        shaderNode.layout = layout;

        return flowData;
    }

    public function flowStagesNode(node:Dynamic, output:String = null):Dynamic {
        var previousFlow:Dynamic = this.flow;
        var previousVars:Array<Dynamic> = this.vars;
        var previousBuildStage:String = this.buildStage;

        var flow:Dynamic = {
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

    public function getFunctionOperator():Null<Dynamic> {
        return null;
    }

    public function flowChildNode(node:Dynamic, output:String = null):Dynamic {
        var previousFlow:Dynamic = this.flow;

        var flow:Dynamic = {
            code: ''
        };

        this.flow = flow;

        flow.result = node.build(this, output);

        this.flow = previousFlow;

        return flow;
    }

    public function flowNodeFromShaderStage(shaderStage:String, node:Dynamic, output:String = null, propertyName:String = null):Dynamic {
        var previousShaderStage:String = this.shaderStage;

        this.setShaderStage(shaderStage);

        var flowData:Dynamic = this.flowChildNode(node, output);

        if (propertyName != null) {
            flowData.code += this.tab + propertyName + ' = ' + flowData.result + ';\n';
        }

        this.flowCode[shaderStage] = this.flowCode[shaderStage] + flowData.code;

        this.setShaderStage(previousShaderStage);

        return flowData;
    }

    public function getAttributesArray():Array<Dynamic> {
        return this.attributes.concat(this.bufferAttributes);
    }

    public function getAttributes(/*shaderStage:String*/):Void {
        console.warn('Abstract function.');
    }

    public function getVaryings(/*shaderStage:String*/):Void {
        console.warn('Abstract function.');
    }

    public function getVar(type:String, name:String):String {
        return this.getType(type) + ' ' + name;
    }

    public function getVars(shaderStage:String):String {
        var snippet:String = '';

        var vars:Array<Dynamic> = this.vars[shaderStage];

        if (vars != null) {
            for (variable in vars) {
                snippet += this.getVar(variable.type, variable.name) + '; ';
            }
        }

        return snippet;
    }

    public function getUniforms(/*shaderStage:String*/):Void {
        console.warn('Abstract function.');
    }

    public function getCodes(shaderStage:String):String {
        var codes:Array<Dynamic> = this.codes[shaderStage];

        var code:String = '';

        if (codes != null) {
            for (nodeCode in codes) {
                code += nodeCode.code + '\n';
            }
        }

        return code;
    }

    public function getHash():String {
        return this.vertexShader + this.fragmentShader + this.computeShader;
    }

    public function setShaderStage(shaderStage:String):Void {
        this.shaderStage = shaderStage;
    }

    public function getShaderStage():String {
        return this.shaderStage;
    }

    public function setBuildStage(buildStage:String):Void {
        this.buildStage = buildStage;
    }

    public function getBuildStage():String {
        return this.buildStage;
    }

    public function buildCode():Void {
        console.warn('Abstract function.');
    }

    public function build():Void {
        var object:Dynamic = this.object;
        var material:Dynamic = this.material;

        if (material != null) {
            NodeMaterial.fromMaterial(material).build(this);
        } else {
            this.addFlow('compute', object);
        }

        for (buildStage in defaultBuildStages) {
            this.setBuildStage(buildStage);

            if (this.context.vertex != null && this.context.vertex.isNode) {
                this.flowNodeFromShaderStage('vertex', this.context.vertex);
            }

            for (shaderStage in shaderStages) {
                this.setShaderStage(shaderStage);

                var flowNodes:Array<Dynamic> = this.flowNodes[shaderStage];

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

        this.buildCode();
        this.buildUpdateNodes();
    }

    public function getNodeUniform(uniformNode:Dynamic, type:String):Dynamic {
        if (type == 'float') return new FloatNodeUniform(uniformNode);
        if (type == 'vec2') return new Vector2NodeUniform(uniformNode);
        if (type == 'vec3') return new Vector3NodeUniform(uniformNode);
        if (type == 'vec4') return new Vector4NodeUniform(uniformNode);
        if (type == 'color') return new ColorNodeUniform(uniformNode);
        if (type == 'mat3') return new Matrix3NodeUniform(uniformNode);
        if (type == 'mat4') return new Matrix4NodeUniform(uniformNode);

        throw new Error('Uniform "' + type + '" not declared.');
    }

    public function createNodeMaterial(type:String = 'NodeMaterial'):Dynamic {
        // TODO: Move Materials.js to outside of the Nodes.js in order to remove this function and improve tree-shaking support

        return createNodeMaterialFromType(type);
    }

    public function format(snippet:String, fromType:String, toType:String):String {
        fromType = this.getVectorType(fromType);
        toType = this.getVectorType(toType);

        if (fromType == toType || toType == null || this.isReference(toType)) {
            return snippet;
        }

        var fromTypeLength:Int = this.getTypeLength(fromType);
        var toTypeLength:Int = this.getTypeLength(toType);

        if (fromTypeLength > 4) { // fromType is matrix-like
            // @TODO: ignore for now
            return snippet;
        }

        if (toTypeLength > 4 || toTypeLength == 0) { // toType is matrix-like or unknown
            // @TODO: ignore for now
            return snippet;
        }

        if (fromTypeLength == toTypeLength) {
            return this.getType(toType) + '(' + snippet + ')';
        }

        if (fromTypeLength > toTypeLength) {
            return this.format(snippet + '.' + 'xyz'.substr(0, toTypeLength), this.getTypeFromLength(toTypeLength, this.getComponentType(fromType)), toType);
        }

        if (toTypeLength == 4 && fromTypeLength > 1) { // toType is vec4-like
            return this.getType(toType) + '(' + this.format(snippet, fromType, 'vec3') + ', 1.0)';
        }

        if (fromTypeLength == 2) { // fromType is vec2-like and toType is vec3-like
            return this.getType(toType) + '(' + this.format(snippet, fromType, 'vec2') + ', 0.0)';
        }

        if (fromTypeLength == 1 && toTypeLength > 1 && fromType.charAt(0) != toType.charAt(0)) { // fromType is float-like
            // convert a number value to vector type, e.g:
            // vec3( 1u ) -> vec3( float( 1u ) )
            snippet = this.getType(this.getComponentType(toType)) + '(' + snippet + ')';

            return snippet; // fromType is float-like
        }

        return this.getType(toType) + '(' + snippet + ')';
    }

    public function getSignature():String {
        return '// Three.js r' + REVISION + ' - NodeMaterial System\n';
    }
}