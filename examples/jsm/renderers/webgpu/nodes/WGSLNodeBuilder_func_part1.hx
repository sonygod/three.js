package three.js.examples.jsm.renderers.webgpu.nodes;

import haxe.ds.StringMap;

class WGSLNodeBuilder extends NodeBuilder {
  public var uniformGroups: StringMap<Dynamic>;
  public var builtins: StringMap<Dynamic>;

  public function new(object: Dynamic, renderer: Dynamic, scene: Dynamic = null) {
    super(object, renderer, new WGSLNodeParser(), scene);
    uniformGroups = new StringMap<Dynamic>();
    builtins = new StringMap<Dynamic>();
  }

  public function needsColorSpaceToLinear(texture: Dynamic): Bool {
    return texture.isVideoTexture && texture.colorSpace != NoColorSpace;
  }

  public function _generateTextureSample(texture: Dynamic, textureProperty: String, uvSnippet: String, depthSnippet: String, shaderStage: String = this.shaderStage): String {
    if (shaderStage == 'fragment') {
      if (depthSnippet != null) {
        return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${depthSnippet})';
      } else {
        return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet})';
      }
    } else {
      return generateTextureLod(texture, textureProperty, uvSnippet);
    }
  }

  public function _generateVideoSample(textureProperty: String, uvSnippet: String, shaderStage: String = this.shaderStage): String {
    if (shaderStage == 'fragment') {
      return 'textureSampleBaseClampToEdge(${textureProperty}, ${textureProperty}_sampler, vec2<f32>(${uvSnippet}.x, 1.0 - ${uvSnippet}.y))';
    } else {
      console.error('WebGPURenderer: THREE.VideoTexture does not support ${shaderStage} shader.');
      return null;
    }
  }

  public function generateTextureLod(texture: Dynamic, textureProperty: String, uvSnippet: String, levelSnippet: String = '0'): String {
    _include('repeatWrapping');
    var dimension = 'textureDimensions(${textureProperty}, 0)';
    return 'textureLoad(${textureProperty}, threejs_repeatWrapping(${uvSnippet}, ${dimension}), i32(${levelSnippet}))';
  }

  public function generateTextureLoad(texture: Dynamic, textureProperty: String, uvIndexSnippet: String, depthSnippet: String, levelSnippet: String = '0u'): String {
    if (depthSnippet != null) {
      return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${depthSnippet}, ${levelSnippet})';
    } else {
      return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${levelSnippet})';
    }
  }

  public function generateTextureStore(texture: Dynamic, textureProperty: String, uvIndexSnippet: String, valueSnippet: String): String {
    return 'textureStore(${textureProperty}, ${uvIndexSnippet}, ${valueSnippet})';
  }

  public function isUnfilterable(texture: Dynamic): Bool {
    return getComponentTypeFromTexture(texture) != 'float' || (texture.isDataTexture && texture.type == FloatType);
  }

  public function generateTexture(texture: Dynamic, textureProperty: String, uvSnippet: String, depthSnippet: String, shaderStage: String = this.shaderStage): String {
    var snippet: String = null;
    if (texture.isVideoTexture) {
      snippet = _generateVideoSample(textureProperty, uvSnippet, shaderStage);
    } else if (isUnfilterable(texture)) {
      snippet = generateTextureLod(texture, textureProperty, uvSnippet, '0', depthSnippet, shaderStage);
    } else {
      snippet = _generateTextureSample(texture, textureProperty, uvSnippet, depthSnippet, shaderStage);
    }
    return snippet;
  }

  public function generateTextureGrad(texture: Dynamic, textureProperty: String, uvSnippet: String, gradSnippet: Array<String>, depthSnippet: String, shaderStage: String = this.shaderStage): String {
    if (shaderStage == 'fragment') {
      return 'textureSampleGrad(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${gradSnippet[0]}, ${gradSnippet[1]})';
    } else {
      console.error('WebGPURenderer: THREE.TextureNode.gradient() does not support ${shaderStage} shader.');
      return null;
    }
  }

  public function generateTextureCompare(texture: Dynamic, textureProperty: String, uvSnippet: String, compareSnippet: String, depthSnippet: String, shaderStage: String = this.shaderStage): String {
    if (shaderStage == 'fragment') {
      return 'textureSampleCompare(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${compareSnippet})';
    } else {
      console.error('WebGPURenderer: THREE.DepthTexture.compareFunction() does not support ${shaderStage} shader.');
      return null;
    }
  }

  public function generateTextureLevel(texture: Dynamic, textureProperty: String, uvSnippet: String, levelSnippet: String, depthSnippet: String, shaderStage: String = this.shaderStage): String {
    var snippet: String = null;
    if (texture.isVideoTexture) {
      snippet = _generateVideoSample(textureProperty, uvSnippet, shaderStage);
    } else {
      snippet = _generateTextureSampleLevel(texture, textureProperty, uvSnippet, levelSnippet, depthSnippet, shaderStage);
    }
    return snippet;
  }

  public function getPropertyName(node: Dynamic, shaderStage: String = this.shaderStage): String {
    if (node.isNodeVarying && node.needsInterpolation) {
      if (shaderStage == 'vertex') {
        return 'varyings.${node.name}';
      }
    } else if (node.isNodeUniform) {
      var name = node.name;
      var type = node.type;
      if (type == 'texture' || type == 'cubeTexture' || type == 'storageTexture') {
        return name;
      } else if (type == 'buffer' || type == 'storageBuffer') {
        return 'NodeBuffer_${node.id}.${name}';
      } else {
        return node.groupNode.name + '.' + name;
      }
    }
    return super.getPropertyName(node);
  }

  public function _getUniformGroupCount(shaderStage: String): Int {
    return Object.keys(uniforms[shaderStage]).length;
  }

  public function getFunctionOperator(op: String): String {
    var fnOp = wgslFnOpLib[op];
    if (fnOp != null) {
      _include(fnOp);
      return fnOp;
    }
    return null;
  }

  public function getUniformFromNode(node: Dynamic, type: String, shaderStage: String, name: String = null): Dynamic {
    var uniformNode = super.getUniformFromNode(node, type, shaderStage, name);
    var nodeData = getDataFromNode(node, shaderStage, globalCache);
    if (nodeData.uniformGPU == null) {
      // ...
    }
    return uniformNode;
  }

  public function isReference(type: String): Bool {
    return super.isReference(type) || type == 'texture_2d' || type == 'texture_cube' || type == 'texture_depth_2d' || type == 'texture_storage_2d';
  }

  public function getBuiltin(name: String, property: String, type: String, shaderStage: String = this.shaderStage): String {
    var map = builtins[shaderStage] || (builtins[shaderStage] = new StringMap<Dynamic>());
    if (!map.exists(name)) {
      map.set(name, { name: name, property: property, type: type });
    }
    return property;
  }

  public function getVertexIndex(): String {
    if (shaderStage == 'vertex') {
      return getBuiltin('vertex_index', 'vertexIndex', 'u32', 'attribute');
    }
    return 'vertexIndex';
  }

  public function buildFunctionCode(shaderNode: Dynamic): String {
    var layout = shaderNode.layout;
    var flowData = flowShaderNode(shaderNode);
    var parameters = [];
    for (input in layout.inputs) {
      parameters.push(input.name + ' : ' + getType(input.type));
    }
    var code = 'fn ${layout.name}(${parameters.join(', ')}) -> ${getType(layout.type)} {
${flowData.vars}
${flowData.code}
return ${flowData.result};
}';
    return code;
  }
}