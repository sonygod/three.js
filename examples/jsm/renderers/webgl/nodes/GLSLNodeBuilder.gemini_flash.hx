import three.nodes.Nodes;
import three.common.nodes.NodeUniformBuffer;
import three.common.nodes.NodeUniformsGroup;
import three.common.nodes.NodeSampledTexture;
import three.common.nodes.NodeSampledCubeTexture;
import three.math.Vector3;
import three.textures.DataTexture;
import three.math.Matrix4;
import three.renderers.webgpu.WebGPURenderer;
import three.renderers.webgpu.WebGPUShader;

class GLSLNodeBuilder extends Nodes.NodeBuilder {
  public uniformGroups:Map<String,Map<String,Dynamic>> = new Map();
  public transforms:Array<{varyingName:String,attributeNode:Nodes.Node}> = [];
  public constructor(object:Dynamic, renderer:WebGPURenderer, scene:Dynamic = null) {
    super(object, renderer, new Nodes.GLSLNodeParser(), scene);
  }
  public getMethod(method:String):String {
    return switch method {
      case Nodes.MathNode.ATAN2: 'atan';
      case 'textureDimensions': 'textureSize';
      case 'equals': 'equal';
      default: method;
    }
  }
  public getPropertyName(node:Nodes.Node, shaderStage:String):String {
    if (node.isOutputStructVar) return '';
    return super.getPropertyName(node, shaderStage);
  }
  public buildFunctionCode(shaderNode:Nodes.ShaderNode):String {
    var layout = shaderNode.layout;
    var flowData = this.flowShaderNode(shaderNode);
    var parameters:Array<String> = [];
    for (input in layout.inputs) {
      parameters.push(this.getType(input.type) + ' ' + input.name);
    }
    var code = '${this.getType(layout.type)} ${layout.name}(${parameters.join(', ')}) {\n';
    code += '\t${flowData.vars}\n';
    code += '${flowData.code}\n';
    code += '\treturn ${flowData.result};\n';
    code += '}';
    return code;
  }
  public setupPBO(storageBufferNode:Nodes.Node) {
    var attribute = storageBufferNode.value;
    if (attribute.pbo == null) {
      var originalArray = attribute.array;
      var numElements = attribute.count * attribute.itemSize;
      var itemSize = attribute.itemSize;
      var format = DataTexture.RedFormat;
      if (itemSize == 2) format = DataTexture.RGFormat;
      else if (itemSize == 3) format = DataTexture.RGBFormat;
      else if (itemSize == 4) format = DataTexture.RGBAFormat;
      var width = Math.pow(2, Math.ceil(Math.log2(Math.sqrt(numElements / itemSize))));
      var height = Math.ceil((numElements / itemSize) / width);
      if (width * height * itemSize < numElements) height++;
      var newSize = width * height * itemSize;
      var newArray = new Float32Array(newSize);
      newArray.set(originalArray, 0);
      attribute.array = newArray;
      var pboTexture = new DataTexture(attribute.array, width, height, format, DataTexture.FloatType);
      pboTexture.needsUpdate = true;
      pboTexture.isPBOTexture = true;
      var pbo = new Nodes.UniformNode(pboTexture);
      pbo.setPrecision('high');
      attribute.pboNode = pbo;
      attribute.pbo = pbo.value;
      this.getUniformFromNode(attribute.pboNode, 'texture', this.shaderStage, this.context.label);
    }
  }
  public generatePBO(storageArrayElementNode:Nodes.Node):String {
    var node = storageArrayElementNode.node;
    var indexNode = storageArrayElementNode.indexNode;
    var attribute = node.value;
    if (this.renderer.backend.has(attribute)) {
      var attributeData = this.renderer.backend.get(attribute);
      attributeData.pbo = attribute.pbo;
    }
    var nodeUniform = this.getUniformFromNode(attribute.pboNode, 'texture', this.shaderStage, this.context.label);
    var textureName = this.getPropertyName(nodeUniform);
    indexNode.increaseUsage(this);
    var indexSnippet = indexNode.build(this, 'uint');
    var elementNodeData = this.getDataFromNode(storageArrayElementNode);
    var propertyName = elementNodeData.propertyName;
    if (propertyName == null) {
      var nodeVar = this.getVarFromNode(storageArrayElementNode);
      propertyName = this.getPropertyName(nodeVar);
      var bufferNodeData = this.getDataFromNode(node);
      var propertySizeName = bufferNodeData.propertySizeName;
      if (propertySizeName == null) {
        propertySizeName = propertyName + 'Size';
        this.getVarFromNode(node, propertySizeName, 'uint');
        this.addLineFlowCode('${propertySizeName} = uint(textureSize(${textureName}, 0).x)');
        bufferNodeData.propertySizeName = propertySizeName;
      }
      var itemSize = attribute.itemSize;
      var channel = '.' + Vector3.components.join('').slice(0, itemSize);
      var uvSnippet = 'ivec2(${indexSnippet} % ${propertySizeName}, ${indexSnippet} / ${propertySizeName})';
      var snippet = this.generateTextureLoad(null, textureName, uvSnippet, null, '0');
      this.addLineFlowCode('${propertyName} = ${snippet + channel}');
      elementNodeData.propertyName = propertyName;
    }
    return propertyName;
  }
  public generateTextureLoad(texture:Dynamic, textureProperty:String, uvIndexSnippet:String, depthSnippet:String, levelSnippet:String = '0'):String {
    if (depthSnippet != null) {
      return 'texelFetch(${textureProperty}, ivec3(${uvIndexSnippet}, ${depthSnippet}), ${levelSnippet})';
    } else {
      return 'texelFetch(${textureProperty}, ${uvIndexSnippet}, ${levelSnippet})';
    }
  }
  public generateTexture(texture:Dynamic, textureProperty:String, uvSnippet:String, depthSnippet:String):String {
    if (texture.isDepthTexture) {
      return 'texture(${textureProperty}, ${uvSnippet}).x';
    } else {
      if (depthSnippet != null) uvSnippet = 'vec3(${uvSnippet}, ${depthSnippet})';
      return 'texture(${textureProperty}, ${uvSnippet})';
    }
  }
  public generateTextureLevel(texture:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String):String {
    return 'textureLod(${textureProperty}, ${uvSnippet}, ${levelSnippet})';
  }
  public generateTextureGrad(texture:Dynamic, textureProperty:String, uvSnippet:String, gradSnippet:Array<String>):String {
    return 'textureGrad(${textureProperty}, ${uvSnippet}, ${gradSnippet[0]}, ${gradSnippet[1]})';
  }
  public generateTextureCompare(texture:Dynamic, textureProperty:String, uvSnippet:String, compareSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage):String {
    if (shaderStage == 'fragment') {
      return 'texture(${textureProperty}, vec3(${uvSnippet}, ${compareSnippet}))';
    } else {
      console.error('WebGPURenderer: THREE.DepthTexture.compareFunction() does not support ${shaderStage} shader.');
      return '';
    }
  }
  public getVars(shaderStage:String):String {
    var snippets:Array<String> = [];
    var vars = this.vars[shaderStage];
    if (vars != null) {
      for (variable in vars) {
        if (variable.isOutputStructVar) continue;
        snippets.push('${this.getVar(variable.type, variable.name)};');
      }
    }
    return snippets.join('\n\t');
  }
  public getUniforms(shaderStage:String):String {
    var uniforms = this.uniforms[shaderStage];
    var bindingSnippets:Array<String> = [];
    var uniformGroups:Map<String,Array<String>> = new Map();
    for (uniform in uniforms) {
      var snippet:String = null;
      var group = false;
      if (uniform.type == 'texture') {
        var texture = uniform.node.value;
        if (texture.compareFunction) {
          snippet = 'sampler2DShadow ${uniform.name};';
        } else if (texture.isDataArrayTexture) {
          snippet = 'sampler2DArray ${uniform.name};';
        } else {
          snippet = 'sampler2D ${uniform.name};';
        }
      } else if (uniform.type == 'cubeTexture') {
        snippet = 'samplerCube ${uniform.name};';
      } else if (uniform.type == 'buffer') {
        var bufferNode = uniform.node;
        var bufferType = this.getType(bufferNode.bufferType);
        var bufferCount = bufferNode.bufferCount;
        var bufferCountSnippet = bufferCount > 0 ? bufferCount : '';
        snippet = '${bufferNode.name} {\n\t${bufferType} ${uniform.name}[${bufferCountSnippet}];\n};\n';
      } else {
        var vectorType = this.getVectorType(uniform.type);
        snippet = '${vectorType} ${uniform.name};';
        group = true;
      }
      var precision = uniform.node.precision;
      if (precision != null) {
        snippet = '${precisionLib[precision]} ${snippet}';
      }
      if (group) {
        snippet = '\t' + snippet;
        var groupName = uniform.groupNode.name;
        var groupSnippets = uniformGroups.get(groupName);
        if (groupSnippets == null) groupSnippets = [];
        groupSnippets.push(snippet);
        uniformGroups.set(groupName, groupSnippets);
      } else {
        snippet = 'uniform ' + snippet;
        bindingSnippets.push(snippet);
      }
    }
    var output = '';
    for (name in uniformGroups.keys()) {
      var groupSnippets = uniformGroups.get(name);
      output += this._getGLSLUniformStruct(shaderStage + '_' + name, groupSnippets.join('\n')) + '\n';
    }
    output += bindingSnippets.join('\n');
    return output;
  }
  public getTypeFromAttribute(attribute:Dynamic):String {
    var nodeType = super.getTypeFromAttribute(attribute);
    if (/^[iu]/.test(nodeType) && attribute.gpuType != DataTexture.IntType) {
      var dataAttribute = attribute;
      if (attribute.isInterleavedBufferAttribute) dataAttribute = attribute.data;
      var array = dataAttribute.array;
      if (!((array instanceof Uint32Array) || (array instanceof Int32Array) || (array instanceof Uint16Array) || (array instanceof Int16Array))) {
        nodeType = nodeType.slice(1);
      }
    }
    return nodeType;
  }
  public getAttributes(shaderStage:String):String {
    var snippet = '';
    if (shaderStage == 'vertex' || shaderStage == 'compute') {
      var attributes = this.getAttributesArray();
      var location = 0;
      for (attribute in attributes) {
        snippet += 'layout( location = ${location++} ) in ${attribute.type} ${attribute.name};\n';
      }
    }
    return snippet;
  }
  public getStructMembers(struct:Dynamic):String {
    var snippets:Array<String> = [];
    var members = struct.getMemberTypes();
    for (i in 0...members.length) {
      var member = members[i];
      snippets.push('layout( location = ${i} ) out ${member} m${i};');
    }
    return snippets.join('\n');
  }
  public getStructs(shaderStage:String):String {
    var snippets:Array<String> = [];
    var structs = this.structs[shaderStage];
    if (structs.length == 0) {
      return 'layout( location = 0 ) out vec4 fragColor;\n';
    }
    for (index in 0...structs.length) {
      var struct = structs[index];
      var snippet = '\n';
      snippet += this.getStructMembers(struct);
      snippet += '\n';
      snippets.push(snippet);
    }
    return snippets.join('\n\n');
  }
  public getVaryings(shaderStage:String):String {
    var snippet = '';
    var varyings = this.varyings;
    if (shaderStage == 'vertex' || shaderStage == 'compute') {
      for (varying in varyings) {
        if (shaderStage == 'compute') varying.needsInterpolation = true;
        var type = varying.type;
        var flat = type == 'int' || type == 'uint' ? 'flat ' : '';
        snippet += '${flat}${varying.needsInterpolation ? 'out' : '/*out*/'} ${type} ${varying.name};\n';
      }
    } else if (shaderStage == 'fragment') {
      for (varying in varyings) {
        if (varying.needsInterpolation) {
          var type = varying.type;
          var flat = type == 'int' || type == 'uint' ? 'flat ' : '';
          snippet += '${flat}in ${type} ${varying.name};\n';
        }
      }
    }
    return snippet;
  }
  public getVertexIndex():String {
    return 'uint( gl_VertexID )';
  }
  public getInstanceIndex():String {
    return 'uint( gl_InstanceID )';
  }
  public getFrontFacing():String {
    return 'gl_FrontFacing';
  }
  public getFragCoord():String {
    return 'gl_FragCoord';
  }
  public getFragDepth():String {
    return 'gl_FragDepth';
  }
  public isAvailable(name:String):Bool {
    return switch name {
      case 'instance': true;
      case 'swizzleAssign': true;
      default: false;
    }
  }
  public isFlipY():Bool {
    return true;
  }
  public registerTransform(varyingName:String, attributeNode:Nodes.Node) {
    this.transforms.push({varyingName: varyingName, attributeNode: attributeNode});
  }
  public getTransforms(shaderStage:String):String {
    var transforms = this.transforms;
    var snippet = '';
    for (i in 0...transforms.length) {
      var transform = transforms[i];
      var attributeName = this.getPropertyName(transform.attributeNode);
      snippet += '${transform.varyingName} = ${attributeName};\n\t';
    }
    return snippet;
  }
  public _getGLSLUniformStruct(name:String, vars:String):String {
    return '\nlayout( std140 ) uniform ${name} {\n${vars}\n};';
  }
  public _getGLSLVertexCode(shaderData:Dynamic):String {
    return '#version 300 es\n\n${this.getSignature()}\n\n// precision\n${defaultPrecisions}\n\n// uniforms\n${shaderData.uniforms}\n\n// varyings\n${shaderData.varyings}\n\n// attributes\n${shaderData.attributes}\n\n// codes\n${shaderData.codes}\n\nvoid main() {\n\n\t// vars\n${shaderData.vars}\n\n\t// transforms\n${shaderData.transforms}\n\n\t// flow\n${shaderData.flow}\n\n\tgl_PointSize = 1.0;\n\n}';
  }
  public _getGLSLFragmentCode(shaderData:Dynamic):String {
    return '#version 300 es\n\n${this.getSignature()}\n\n// precision\n${defaultPrecisions}\n\n// uniforms\n${shaderData.uniforms}\n\n// varyings\n${shaderData.varyings}\n\n// codes\n${shaderData.codes}\n\n${shaderData.structs}\n\nvoid main() {\n\n\t// vars\n${shaderData.vars}\n\n\t// flow\n${shaderData.flow}\n\n}';
  }
  public buildCode() {
    var shadersData = this.material != null ? {fragment: {}, vertex: {}} : {compute: {}};
    for (shaderStage in shadersData.keys()) {
      var flow = '// code\n\n';
      flow += this.flowCode[shaderStage];
      var flowNodes = this.flowNodes[shaderStage];
      var mainNode = flowNodes[flowNodes.length - 1];
      for (node in flowNodes) {
        var flowSlotData = this.getFlowData(node);
        var slotName = node.name;
        if (slotName != null) {
          if (flow.length > 0) flow += '\n';
          flow += '\t// flow -> ${slotName}\n\t';
        }
        flow += '${flowSlotData.code}\n\t';
        if (node == mainNode && shaderStage != 'compute') {
          flow += '// result\n\t';
          if (shaderStage == 'vertex') {
            flow += 'gl_Position = ';
            flow += '${flowSlotData.result};';
          } else if (shaderStage == 'fragment') {
            if (!node.outputNode.isOutputStructNode) {
              flow += 'fragColor = ';
              flow += '${flowSlotData.result};';
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
      this.vertexShader = this._getGLSLVertexCode(shadersData.get('vertex'));
      this.fragmentShader = this._getGLSLFragmentCode(shadersData.get('fragment'));
    } else {
      this.computeShader = this._getGLSLVertexCode(shadersData.get('compute'));
    }
  }
  public getUniformFromNode(node:Nodes.Node, type:String, shaderStage:String, name:String = null):Nodes.Node {
    var uniformNode = super.getUniformFromNode(node, type, shaderStage, name);
    var nodeData = this.getDataFromNode(node, shaderStage, this.globalCache);
    var uniformGPU = nodeData.uniformGPU;
    if (uniformGPU == null) {
      if (type == 'texture') {
        uniformGPU = new NodeSampledTexture(uniformNode.name, uniformNode.node);
        this.bindings[shaderStage].push(uniformGPU);
      } else if (type == 'cubeTexture') {
        uniformGPU = new NodeSampledCubeTexture(uniformNode.name, uniformNode.node);
        this.bindings[shaderStage].push(uniformGPU);
      } else if (type == 'buffer') {
        node.name = 'NodeBuffer_${node.id}';
        uniformNode.name = 'buffer${node.id}';
        var buffer = new NodeUniformBuffer(node);
        buffer.name = node.name;
        this.bindings[shaderStage].push(buffer);
        uniformGPU = buffer;
      } else {
        var group = node.groupNode;
        var groupName = group.name;
        var uniformsStage = this.uniformGroups.get(shaderStage);
        if (uniformsStage == null) uniformsStage = new Map();
        var uniformsGroup = uniformsStage.get(groupName);
        if (uniformsGroup == null) {
          uniformsGroup = new NodeUniformsGroup(shaderStage + '_' + groupName, group);
          uniformsStage.set(groupName, uniformsGroup);
          this.bindings[shaderStage].push(uniformsGroup);
        }
        uniformGPU = this.getNodeUniform(uniformNode, type);
        uniformsGroup.addUniform(uniformGPU);
      }
      nodeData.uniformGPU = uniformGPU;
    }
    return uniformNode;
  }
  static public var defaultPrecisions:String = 'precision highp float;\nprecision highp int;\nprecision mediump sampler2DArray;\nprecision lowp sampler2DShadow;';
  static public var precisionLib:Map<String,String> = new Map([
    ['low', 'lowp'],
    ['medium', 'mediump'],
    ['high', 'highp'],
  ]);
}