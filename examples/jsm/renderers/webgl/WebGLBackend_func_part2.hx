package three.js.examples.jsm.renderers.webgl;

import three.js.Lib;
import three.js.geometry.BufferGeometry;
import three.js.renderers.webgl.WebGLBuffer;
import three.js.renderers.webgl.WebGLProgram;
import three.js.renderers.webgl.WebGLTexture;
import three.js.renderers.webgl.WebGLTransformFeedback;
import three.js.utils.AttributeUtils;
import three.js.utils.TextureUtils;

class WebGLBackend {
  private var gl:WebGLRenderingContext;
  private var vaoCache:Map<String, WebGLVertexArrayObject>;
  private var textureUtils:TextureUtils;
  private var attributeUtils:AttributeUtils;
  private var parallel:Bool;

  public function compute(computeGroup:Dynamic, computeNode:Dynamic, bindings:Dynamic, pipeline:Dynamic) {
    var gl = this.gl;
    if (!this.discard) {
      gl.enable(gl.RASTERIZER_DISCARD);
      this.discard = true;
    }
    var programGPU = pipeline.programGPU;
    var transformBuffers = pipeline.transformBuffers;
    var attributes = pipeline.attributes;
    var vaoKey = _getVaoKey(null, attributes);
    var vaoGPU = vaoCache[vaoKey];
    if (vaoGPU == null) {
      _createVao(null, attributes);
    } else {
      gl.bindVertexArray(vaoGPU);
    }
    gl.useProgram(programGPU);
    _bindUniforms(bindings);
    var transformFeedbackGPU = _getTransformFeedback(transformBuffers);
    gl.bindTransformFeedback(gl.TRANSFORM_FEEDBACK, transformFeedbackGPU);
    gl.beginTransformFeedback(gl.POINTS);
    if (attributes[0].isStorageInstancedBufferAttribute) {
      gl.drawArraysInstanced(gl.POINTS, 0, 1, computeNode.count);
    } else {
      gl.drawArrays(gl.POINTS, 0, computeNode.count);
    }
    gl.endTransformFeedback();
    gl.bindTransformFeedback(gl.TRANSFORM_FEEDBACK, null);
    for (i in 0...transformBuffers.length) {
      var dualAttributeData = transformBuffers[i];
      if (dualAttributeData.pbo != null) {
        textureUtils.copyBufferToTexture(dualAttributeData.transformBuffer, dualAttributeData.pbo);
      }
      dualAttributeData.switchBuffers();
    }
  }

  public function finishCompute(computeGroup:Dynamic) {
    var gl = this.gl;
    this.discard = false;
    gl.disable(gl.RASTERIZER_DISCARD);
    prepareTimestampBuffer(computeGroup);
  }

  public function draw(renderObject:Dynamic, info:Dynamic) {
    var gl = this.gl;
    var pipeline = renderObject.pipeline;
    var programGPU = pipeline.programGPU;
    var material = renderObject.material;
    var context = renderObject.context;
    var contextData = get(context);
    _bindUniforms(renderObject.getBindings());
    var frontFaceCW = (renderObject.isMesh && renderObject.matrixWorld.determinant() < 0);
    state.setMaterial(material, frontFaceCW);
    gl.useProgram(programGPU);
    var vaoGPU = renderObject.staticVao;
    if (vaoGPU == null) {
      var vaoKey = _getVaoKey(renderObject.getIndex(), renderObject.getAttributes());
      vaoGPU = vaoCache[vaoKey];
      if (vaoGPU == null) {
        var staticVao:Bool;
        ({ vaoGPU, staticVao } = _createVao(renderObject.getIndex(), renderObject.getAttributes()));
        if (staticVao) renderObject.staticVao = vaoGPU;
      }
    }
    gl.bindVertexArray(vaoGPU);
    // ...
  }

  public function needsRenderUpdate(renderObject:Dynamic) {
    return false;
  }

  public function getRenderCacheKey(renderObject:Dynamic) {
    return renderObject.id;
  }

  public function createDefaultTexture(texture:Dynamic) {
    textureUtils.createDefaultTexture(texture);
  }

  public function createTexture(texture:Dynamic, options:Dynamic) {
    textureUtils.createTexture(texture, options);
  }

  public function updateTexture(texture:Dynamic, options:Dynamic) {
    textureUtils.updateTexture(texture, options);
  }

  public function generateMipmaps(texture:Dynamic) {
    textureUtils.generateMipmaps(texture);
  }

  public function destroyTexture(texture:Dynamic) {
    textureUtils.destroyTexture(texture);
  }

  public function copyTextureToBuffer(texture:Dynamic, x:Int, y:Int, width:Int, height:Int) {
    return textureUtils.copyTextureToBuffer(texture, x, y, width, height);
  }

  public function createSampler(texture:Dynamic) {
    // console.warn('Abstract class.');
  }

  public function destroySampler() {}

  public function createNodeBuilder(object:Dynamic, renderer:Dynamic, scene:Dynamic = null) {
    return new GLSLNodeBuilder(object, renderer, scene);
  }

  public function createProgram(program:Dynamic) {
    var gl = this.gl;
    var shader = gl.createShader(program.stage == 'fragment' ? gl.FRAGMENT_SHADER : gl.VERTEX_SHADER);
    gl.shaderSource(shader, program.code);
    gl.compileShader(shader);
    set(program, { shaderGPU: shader });
  }

  public function destroyProgram(program:Dynamic) {
    // console.warn('Abstract class.');
  }

  public function createRenderPipeline(renderObject:Dynamic, promises:Array<Promise<Dynamic>>) {
    var gl = this.gl;
    var pipeline = renderObject.pipeline;
    var programGPU = gl.createProgram();
    var fragmentShader = get(pipeline.fragmentProgram).shaderGPU;
    var vertexShader = get(pipeline.vertexProgram).shaderGPU;
    gl.attachShader(programGPU, fragmentShader);
    gl.attachShader(programGPU, vertexShader);
    gl.linkProgram(programGPU);
    set(pipeline, { programGPU, fragmentShader, vertexShader });
    if (promises != null && this.parallel) {
      var p = new Promise((resolve, reject) -> {
        var parallel = this.parallel;
        var checkStatus = () -> {
          if (gl.getProgramParameter(programGPU, parallel.COMPLETION_STATUS_KHR)) {
            _completeCompile(renderObject, pipeline);
            resolve();
          } else {
            requestAnimationFrame(checkStatus);
          }
        };
        checkStatus();
      });
      promises.push(p);
      return;
    }
    _completeCompile(renderObject, pipeline);
  }

  public function _completeCompile(renderObject:Dynamic, pipeline:Dynamic) {
    var gl = this.gl;
    var pipelineData = get(pipeline);
    var programGPU = pipelineData.programGPU;
    var fragmentShader = pipelineData.fragmentShader;
    var vertexShader = pipelineData.vertexShader;
    if (!gl.getProgramParameter(programGPU, gl.LINK_STATUS)) {
      console.error('THREE.WebGLBackend:', gl.getProgramInfoLog(programGPU));
      console.error('THREE.WebGLBackend:', gl.getShaderInfoLog(fragmentShader));
      console.error('THREE.WebGLBackend:', gl.getShaderInfoLog(vertexShader));
    }
    gl.useProgram(programGPU);
    _setupBindings(renderObject.getBindings(), programGPU);
    set(pipeline, { programGPU });
  }

  public function createComputePipeline(computePipeline:Dynamic, bindings:Dynamic) {
    var gl = this.gl;
    var fragmentProgram = {
      stage: 'fragment',
      code: '#version 300 es\nprecision highp float;\nvoid main() {}'
    };
    createProgram(fragmentProgram);
    var computeProgram = computePipeline.computeProgram;
    var programGPU = gl.createProgram();
    var fragmentShader = get(fragmentProgram).shaderGPU;
    var vertexShader = get(computeProgram).shaderGPU;
    var transforms = computeProgram.transforms;
    var transformVaryingNames:Array<String> = [];
    var transformAttributeNodes:Array<Dynamic> = [];
    for (i in 0...transforms.length) {
      var transform = transforms[i];
      transformVaryingNames.push(transform.varyingName);
      transformAttributeNodes.push(transform.attributeNode);
    }
    gl.attachShader(programGPU, fragmentShader);
    gl.attachShader(programGPU, vertexShader);
    gl.transformFeedbackVaryings(programGPU, transformVaryingNames, gl.SEPARATE_ATTRIBS);
    gl.linkProgram(programGPU);
    if (!gl.getProgramParameter(programGPU, gl.LINK_STATUS)) {
      console.error('THREE.WebGLBackend:', gl.getProgramInfoLog(programGPU));
      console.error('THREE.WebGLBackend:', gl.getShaderInfoLog(fragmentShader));
      console.error('THREE.WebGLBackend:', gl.getShaderInfoLog(vertexShader));
    }
    gl.useProgram(programGPU);
    createBindings(bindings);
    _setupBindings(bindings, programGPU);
    var attributes:Array<Dynamic> = [];
    var transformBuffers:Array<Dynamic> = [];
    for (i in 0...computeProgram.attributes.length) {
      var attributeNode = computeProgram.attributes[i];
      var attribute = attributeNode.node.attribute;
      attributes.push(attribute);
      if (!has(attribute)) attributeUtils.createAttribute(attribute, gl.ARRAY_BUFFER);
    }
    for (i in 0...transformAttributeNodes.length) {
      var attribute = transformAttributeNodes[i].attribute;
      if (!has(attribute)) attributeUtils.createAttribute(attribute, gl.ARRAY_BUFFER);
      var attributeData = get(attribute);
      transformBuffers.push(attributeData);
    }
    set(computePipeline, { programGPU, transformBuffers, attributes });
  }

  public function createBindings(bindings:Dynamic) {
    updateBindings(bindings);
  }
}