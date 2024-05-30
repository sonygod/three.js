import js.Node;
import js.NodeBuilder;
import js.NodeUniformBuffer;
import js.NodeUniformsGroup;
import js.NodeSampledTexture;
import js.NodeSampledCubeTexture;
import js.RedFormat;
import js.RGFormat;
import js.IntType;
import js.DataTexture;
import js.RGBFormat;
import js.RGBAFormat;
import js.FloatType;

class GLSLNodeBuilder extends NodeBuilder {
    public var uniformGroups:Map<String, Dynamic>;
    public var transforms:Array<Dynamic>;

    public function new(object:Dynamic, renderer:Dynamic, ?scene:Dynamic) {
        super(object, renderer, new GLSLNodeParser(), scene);

        this.uniformGroups = Map();
        this.transforms = [];
    }

    public function getMethod(method:String):String {
        if (glslMethods.exists(method)) {
            return glslMethods.get(method);
        } else {
            return method;
        }
    }

    public function getPropertyName(node:Dynamic, shaderStage:String):String {
        if (node.isOutputStructVar != null && node.isOutputStructVar) {
            return "";
        }
        return super.getPropertyName(node, shaderStage);
    }

    public function buildFunctionCode(shaderNode:Dynamic):String {
        var layout = shaderNode.layout;
        var flowData = this.flowShaderNode(shaderNode);

        var parameters = [];
        var inputs = layout.inputs;
        for (input in inputs) {
            parameters.push(this.getType(input.type) + " " + input.name);
        }

        var code = `${this.getType(layout.type)} ${layout.name}(${parameters.join(", ")}) {
            ${flowData.vars}

            ${flowData.code}
            return ${flowData.result};
        }`;

        return code;
    }

    public function setupPBO(storageBufferNode:Dynamic) {
        var attribute = storageBufferNode.value;

        if (attribute.pbo == null) {
            var originalArray = attribute.array;
            var numElements = attribute.count * attribute.itemSize;

            var itemSize = attribute.itemSize;
            var format:Dynamic;
            if (itemSize == 2) {
                format = RGFormat;
            } else if (itemSize == 3) {
                format = RGBFormat;
            } else if (itemSize == 4) {
                format = RGBAFormat;
            }

            var width = Math.pow(2, Math.ceil(Math.log2(Math.sqrt(numElements / itemSize))));
            var height = Math.ceil((numElements / itemSize) / width);
            if (width * height * itemSize < numElements) {
                height++;
            }

            var newSize = width * height * itemSize;
            var newArray = new Float32Array(newSize);
            newArray.set(originalArray, 0);

            attribute.array = newArray;

            var pboTexture = new DataTexture(attribute.array, width, height, format, FloatType);
            pboTexture.needsUpdate = true;
            pboTexture.isPBOTexture = true;

            var pbo = new UniformNode(pboTexture);
            pbo.setPrecision("high");

            attribute.pboNode = pbo;
            attribute.pbo = pbo.value;

            this.getUniformFromNode(attribute.pboNode, "texture", this.shaderStage, this.context.label);
        }
    }

    public function generatePBO(storageArrayElementNode:Dynamic):String {
        var node = storageArrayElementNode.node;
        var indexNode = storageArrayElementNode.indexNode;
        var attribute = node.value;

        if (this.renderer.backend.has(attribute)) {
            var attributeData = this.renderer.backend.get(attribute);
            attributeData.pbo = attribute.pbo;
        }

        var nodeUniform = this.getUniformFromNode(attribute.pboNode, "texture", this.shaderStage, this.context.label);
        var textureName = this.getPropertyName(nodeUniform);

        indexNode.increaseUsage(this);
        var indexSnippet = indexNode.build(this, "uint");

        var elementNodeData = this.getDataFromNode(storageArrayElementNode);
        var propertyName = elementNodeData.propertyName;

        if (propertyName == null) {
            var nodeVar = this.getVarFromNode(storageArrayElementNode);
            propertyName = this.getPropertyName(nodeVar);

            var bufferNodeData = this.getDataFromNode(node);
            var propertySizeName = bufferNodeData.propertySizeName;

            if (propertySizeName == null) {
                propertySizeName = propertyName + "Size";

                this.getVarFromNode(node, propertySizeName, "uint");

                this.addLineFlowCode(`${propertySizeName} = uint(textureSize(${textureName}, 0).x)`);

                bufferNodeData.propertySizeName = propertySizeName;
            }

            var itemSize = attribute.itemSize;
            var channel = vectorComponents.join("").slice(0, itemSize);
            var uvSnippet = `ivec2(${indexSnippet} % ${propertySizeName}, ${indexSnippet} / ${propertySizeName})`;

            var snippet = this.generateTextureLoad(null, textureName, uvSnippet, null, "0");

            this.addLineFlowCode(`${propertyName} = ${snippet + channel}`);

            elementNodeData.propertyName = propertyName;
        }

        return propertyName;
    }

    public function generateTextureLoad(texture:Dynamic, textureProperty:Dynamic, uvIndexSnippet:Dynamic, depthSnippet:Dynamic, ?levelSnippet:String):String {
        if (depthSnippet != null) {
            return `texelFetch(${textureProperty}, ivec3(${uvIndexSnippet}, ${depthSnippet}), ${levelSnippet || "0"})`;
        } else {
            return `texelFetch(${textureProperty}, ${uvIndexSnippet}, ${levelSnippet || "0"})`;
        }
    }

    public function generateTexture(texture:Dynamic, textureProperty:Dynamic, uvSnippet:Dynamic, depthSnippet:Dynamic):String {
        if (texture.isDepthTexture) {
            return `texture(${textureProperty}, ${uvSnippet}).x`;
        } else {
            if (depthSnippet != null) {
                uvSnippet = `vec3(${uvSnippet}, ${depthSnippet})`;
            }
            return `texture(${textureProperty}, ${uvSnippet})`;
        }
    }

    public function generateTextureLevel(texture:Dynamic, textureProperty:Dynamic, uvSnippet:Dynamic, levelSnippet:Dynamic):String {
        return `textureLod(${textureProperty}, ${uvSnippet}, ${levelSnippet})`;
    }

    public function generateTextureGrad(texture:Dynamic, textureProperty:Dynamic, uvSnippet:Dynamic, gradSnippet:Dynamic):String {
        return `textureGrad(${textureProperty}, ${uvSnippet}, ${gradSnippet[0]}, ${gradSnippet[1]})`;
    }

    public function generateTextureCompare(texture:Dynamic, textureProperty:Dynamic, uvSnippet:Dynamic, compareSnippet:Dynamic, depthSnippet:Dynamic, ?shaderStage:String):String {
        if (shaderStage == null) {
            shaderStage = this.shaderStage;
        }

        if (shaderStage == "fragment") {
            return `texture(${textureProperty}, vec3(${uvSnippet}, ${compareSnippet}))`;
        } else {
            console.error("WebGPURenderer: THREE.DepthTexture.compareFunction() does not support ${shaderStage} shader.");
        }
    }

    public function getVars(shaderStage:String):String {
        var snippets = [];
        var vars = this.vars.get(shaderStage);

        if (vars != null) {
            for (var variable in vars) {
                if (variable.isOutputStructVar) {
                    continue;
                }
                snippets.push(`${this.getVar(variable.type, variable.name)};`);
            }
        }

        return snippets.join("\n\t");
    }

    public function getUniforms(shaderStage:String):String {
        var uniforms = this.uniforms.get(shaderStage);

        var bindingSnippets = [];
        var uniformGroups = Map();

        for (var uniform in uniforms) {
            var snippet:String;
            var group:Bool = false;

            if (uniform.type == "texture") {
                var texture = uniform.node.value;

                if (texture.compareFunction) {
                    snippet = "sampler2DShadow " + uniform.name;
                } else if (texture.isDataArrayTexture) {
                    snippet = "sampler2DArray " + uniform.name;
                } else {
                    snippet = "sampler2D " + uniform.name;
                }
            } else if (uniform.type == "cubeTexture") {
                snippet = "samplerCube " + uniform.name;
            } else if (uniform.type == "buffer") {
                var bufferNode = uniform.node;
                var bufferType = this.getType(bufferNode.bufferType);
                var bufferCount = bufferNode.bufferCount;

                var bufferCountSnippet = bufferCount > 0 ? Std.string(bufferCount) : "";
                snippet = `${bufferNode.name} {
                    ${bufferType} ${uniform.name}[${bufferCountSnippet}];
                }`;
            } else {
                var vectorType = this.getVectorType(uniform.type);
                snippet = `${vectorType} ${uniform.name}`;

                group = true;
            }

            var precision = uniform.node.precision;
            if (precision != null) {
                snippet = precisionLib.get(precision) + " " + snippet;
            }

            if (group) {
                snippet = "\t" + snippet;

                var groupName = uniform.groupNode.name;
                var groupSnippets = uniformGroups.get(groupName);
                if (groupSnippets == null) {
                    groupSnippets = [];
                    uniformGroups.set(groupName, groupSnippets);
                }

                groupSnippets.push(snippet);
            } else {
                snippet = "uniform " + snippet;
                bindingSnippets.push(snippet);
            }
        }

        var output = "";
        for (var name in uniformGroups.keys()) {
            var groupSnippets = uniformGroups.get(name);
            output += this._getGLSLUniformStruct(shaderStage + "_" + name, groupSnippets.join("\n"));
        }

        output += bindingSnippets.join("\n");

        return output;
    }

    public function getTypeFromAttribute(attribute:Dynamic):String {
        var nodeType = super.getTypeFromAttribute(attribute);

        if (/^[iu]/.test(nodeType) && attribute.gpuType != IntType) {
            var dataAttribute = attribute;
            if (attribute.isInterleavedBufferAttribute) {
                dataAttribute = attribute.data;
            }

            var array = dataAttribute.array;

            if (!(array instanceof Uint32Array || array instanceof Int32Array || array instanceof Uint16Array || array instanceof Int16Array)) {
                nodeType = nodeType.slice(1);
            }
        }

        return nodeType;
    }

    public function getAttributes(shaderStage:String):String {
        var snippet = "";

        if (shaderStage == "vertex" || shaderStage == "compute") {
            var attributes = this.getAttributesArray();

            var location = 0;
            for (var attribute in attributes) {
                snippet += `layout(location = ${location}) in ${attribute.type} ${attribute.name};\n`;
                location++;
            }
        }

        return snippet;
    }

    public function getStructMembers(struct:Dynamic):String {
        var snippets = [];
        var members = struct.getMemberTypes();

        for (var i = 0; i < members.length; i++) {
            var member = members[i];
            snippets.push(`layout(location = ${i}) out ${member} m${i};`);
        }

        return snippets.join("\n");
    }

    public function getStructs(shaderStage:String):String {
        var snippets = [];
        var structs = this.structs.get(shaderStage);

        if (structs.length == 0) {
            return "layout(location = 0) out vec4 fragColor;\n";
        }

        for (var index = 0; index < structs.length; index++) {
            var struct = structs[index];

            var snippet = "\n";
            snippet += this.getStructMembers(struct);
            snippet += "\n";

            snippets.push(snippet);
        }

        return snippets.join("\n\n");
    }

    public function getVaryings(shaderStage:String):String {
        var snippet = "";

        var varyings = this.varyings;

        if (shaderStage == "vertex" || shaderStage == "compute") {
            for (var varying in varyings) {
                if (shaderStage == "compute") {
                    varying.needsInterpolation = true;
                }
                var type = varying.type;
                var flat = type == "int" || type == "uint" ? "flat " : "";

                snippet += `${flat}${varying.needsInterpolation ? "out" : "/*out*/"} ${type} ${varying.name};\n`;
            }
        } else if (shaderStage == "fragment") {
            for (var varying in varyings) {
                if (varying.needsInterpolation) {
                    var type = varying.type;
                    var flat = type == "int" || type == "uint" ? "flat " : "";

                    snippet += `${flat}in ${type} ${varying.name};\n`;
                }
            }
        }

        return snippet;
    }

    public function getVertexIndex():String {
        return "uint(gl_VertexID)";
    }

    public function getInstanceIndex():String {
        return "uint(gl_InstanceID)";
    }

    public function getFrontFacing():String {
        return "gl_FrontFacing";
    }

    public function getFragCoord():String {
        return "gl_FragCoord";
    }

    public function getFragDepth():String {
        return "gl_FragDepth";
    }

    public function isAvailable(name:String):Bool {
        return supports.exists(name) && supports.get(name);
    }

    public function isFlipY():Bool {
        return true;
    }

    public function registerTransform(varyingName:String, attributeNode:Dynamic) {
        this.transforms.push({varyingName: varyingName, attributeNode: attributeNode});
    }

    public function getTransforms(?shaderStage:String):String {
        var transforms = this.transforms;

        var snippet = "";

        for (var i = 0; i < transforms.length; i++) {
            var transform = transforms[i];

            var attributeName = this.getPropertyName(transform.attributeNode);

            snippet += `${transform.varyingName} = ${attributeName};\n\t`;
        }

        return snippet;
    }

    public function _getGLSLUniformStruct(name:String, vars:String):String {
        return `
            layout(std140) uniform ${name} {
                ${vars}
            };
        `;
    }

    public function _getGLSLVertexCode(shaderData:Dynamic):String {
        return `#version 300 es

            ${this.getSignature()}

            // precision
            ${defaultPrecisions}

            // uniforms
            ${shaderData.uniforms}

            // varyings
            ${shaderData.varyings}

            // attributes
            ${shaderData.attributes}

            // codes
            ${shaderData.codes}

            void main() {
                // vars
                ${shaderData.vars}

                // transforms
                ${shaderData.transforms}

                // flow
                ${shaderData.flow}

                gl_PointSize = 1.0;
            }
        `;
    }

    public function _getGLSLFragmentCode(shaderData:Dynamic):String {
        return `#version 300 es

            ${this.getSignature()}

            // precision
            ${defaultPrecisions}

            // uniforms
            ${shaderData.uniforms}

            // varyings
            ${shaderData.varyings}

            // codes
            ${shaderData.codes}

            ${shaderData.structs}

            void main() {
                // vars
                ${shaderData.vars}

                // flow
                ${shaderData.flow}
            }
        `;
    }

    public function buildCode() {
        var shadersData = this.material != null ? {fragment: {}, vertex: {}} : {compute: {}};

        for (var shaderStage in shadersData) {
            var flow = "// code\n\n";
            flow += this.flowCode.get(shaderStage);

            var flowNodes = this.flowNodes.get(shaderStage);
            var mainNode = flowNodes[flowNodes.length - 1];

            for (var node in flowNodes) {
                var flowSlotData = this.getFlowData(flowNodes[node]);
                var slotName = flowNodes[node].name;

                if (slotName) {
                    if (flow.length > 0) {
                        flow += "\n";
                    }
                    flow += `\t// flow -> ${slotName}\n\t`;
                }

                flow += `${flowSlotData.code}\n\t`;

                if (flowNodes[node] == mainNode && shaderStage != "compute") {
                    flow += "// result\n\t";

                    if (shaderStage == "vertex") {
                        flow += "gl_Position = ";
                        flow += `${flowSlotData.result};`;
                    } else if (shaderStage == "fragment") {
                        if (!flowNodes[node].outputNode.isOutputStructNode) {
                            flow += "fragColor = ";
                            flow += `${flowSlotData.result};`;
                        }
                    }
                }
            }

            var stageData = shadersData.get(shaderStage);

            stageData.uniforms = this.getUniforms(shaderStage);
            stageData.attributes = this.getAttributes(shaderStage);
            stageData.varyings = this.getVaryings(shaderStage);
            stageData.vars = this.getVars(shaderStage);
            stageData.structs = this.getStructs(shaderStage);
            stageData.codes = this.getCodes(shaderStage);
            stageData.transforms = this.getTransforms(shaderStage);
            stageData.flow = flow;
        }

        if (this.material != null) {
            this.vertexShader = this._
.getGLSLVertexCode(shadersData.vertex);
            this.fragmentShader = this._getGLSLFragmentCode(shadersData.fragment);
        } else {
            this.computeShader = this._getGLSLVertexCode(shadersData.compute);
        }
    }

    public function getUniformFromNode(node:Dynamic, type:String, shaderStage:String, ?name:String):Dynamic {
        var uniformNode = super.getUniformFromNode(node, type, shaderStage, name);
        var nodeData = this.getDataFromNode(node, shaderStage, this.globalCache);

        var uniformGPU = nodeData.uniformGPU;
        if (uniformGPU == null) {
            if (type == "texture") {
                uniformGPU = new NodeSampledTexture(uniformNode.name, uniformNode.node);

                this.bindings.get(shaderStage).push(uniformGPU);
            } else if (type == "cubeTexture") {
                uniformGPU = new NodeSampledCubeTexture(uniformNode.name, uniformNode.node);

                this.bindings.get(shaderStage).push(uniformGPU);
            } else if (type == "buffer") {
                node.name = "NodeBuffer_" + node.id;
                uniformNode.name = "buffer" + node.id;

                var buffer = new NodeUniformBuffer(node);
                buffer.name = node.name;

                this.bindings.get(shaderStage).push(buffer);

                uniformGPU = buffer;
            } else {
                var group = node.groupNode;
                var groupName = group.name;

                var uniformsStage = this.uniformGroups.get(shaderStage);
                if (uniformsStage == null) {
                    uniformsStage = Map();
                    this.uniformGroups.set(shaderStage, uniformsStage);
                }

                var uniformsGroup = uniformsStage.get(groupName);
                if (uniformsGroup == null) {
                    uniformsGroup = new NodeUniformsGroup(shaderStage + "_" + groupName, group);
                    uniformsStage.set(groupName, uniformsGroup);

                    this.bindings.get(shaderStage).push(uniformsGroup);
                }

                uniformGPU = this.getNodeUniform(uniformNode, type);

                uniformsGroup.addUniform(uniformGPU);
            }

            nodeData.uniformGPU = uniformGPU;
        }

        return uniformNode;
    }
}