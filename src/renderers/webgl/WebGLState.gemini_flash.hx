import haxe.ds.WeakMap;
import three.math.Color;
import three.math.Vector4;
import three.constants.*;

class WebGLState {
  private var gl: WebGLRenderingContext;
  private var colorBuffer: ColorBuffer;
  private var depthBuffer: DepthBuffer;
  private var stencilBuffer: StencilBuffer;
  private var uboBindings: WeakMap<WebGLProgram, Int>;
  private var uboProgramMap: WeakMap<WebGLProgram, WeakMap<String, Int>>;
  private var enabledCapabilities: Map<Int, Bool>;
  private var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
  private var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
  private var defaultDrawbuffers: Array<Int>;
  private var currentProgram: WebGLProgram;
  private var currentBlendingEnabled: Bool;
  private var currentBlending: Int;
  private var currentBlendEquation: Int;
  private var currentBlendSrc: Int;
  private var currentBlendDst: Int;
  private var currentBlendEquationAlpha: Int;
  private var currentBlendSrcAlpha: Int;
  private var currentBlendDstAlpha: Int;
  private var currentBlendColor: Color;
  private var currentBlendAlpha: Float;
  private var currentPremultipledAlpha: Bool;
  private var currentFlipSided: Bool;
  private var currentCullFace: Int;
  private var currentLineWidth: Float;
  private var currentPolygonOffsetFactor: Float;
  private var currentPolygonOffsetUnits: Float;
  private var maxTextures: Int;
  private var lineWidthAvailable: Bool;
  private var version: Float;
  private var currentTextureSlot: Int;
  private var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;
  private var scissorParam: Array<Int>;
  private var viewportParam: Array<Int>;
  private var currentScissor: Vector4;
  private var currentViewport: Vector4;
  private var emptyTextures: Map<Int, WebGLTexture>;

  public function new(gl: WebGLRenderingContext) {
    this.gl = gl;

    this.colorBuffer = new ColorBuffer();
    this.depthBuffer = new DepthBuffer();
    this.stencilBuffer = new StencilBuffer();

    this.uboBindings = new WeakMap();
    this.uboProgramMap = new WeakMap();

    this.enabledCapabilities = new Map();

    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];

    this.currentProgram = null;

    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;

    this.currentFlipSided = null;
    this.currentCullFace = null;

    this.currentLineWidth = null;

    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;

    this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

    this.lineWidthAvailable = false;
    this.version = 0;
    var glVersion = gl.getParameter(gl.VERSION);

    if (glVersion.indexOf("WebGL") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^WebGL (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 1.0;
    } else if (glVersion.indexOf("OpenGL ES") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^OpenGL ES (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 2.0;
    }

    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();

    this.scissorParam = gl.getParameter(gl.SCISSOR_BOX);
    this.viewportParam = gl.getParameter(gl.VIEWPORT);

    this.currentScissor = new Vector4().fromArray(this.scissorParam);
    this.currentViewport = new Vector4().fromArray(this.viewportParam);

    this.emptyTextures = new Map();
    this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
    this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
    this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
    this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

    this.colorBuffer.setClear(0, 0, 0, 1);
    this.depthBuffer.setClear(1);
    this.stencilBuffer.setClear(0);

    this.enable(gl.DEPTH_TEST);
    this.depthBuffer.setFunc(LessEqualDepth);

    this.setFlipSided(false);
    this.setCullFace(CullFaceBack);
    this.enable(gl.CULL_FACE);

    this.setBlending(NoBlending);
  }

  private function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {
    var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    var texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (var i = 0; i < count; i++) {
      if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }

  public function enable(id: Int): Void {
    if (!this.enabledCapabilities.exists(id) || !this.enabledCapabilities.get(id)) {
      gl.enable(id);
      this.enabledCapabilities.set(id, true);
    }
  }

  public function disable(id: Int): Void {
    if (this.enabledCapabilities.exists(id) && this.enabledCapabilities.get(id)) {
      gl.disable(id);
      this.enabledCapabilities.set(id, false);
    }
  }

  public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {
    if (this.currentBoundFramebuffers.get(target) != framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      this.currentBoundFramebuffers.set(target, framebuffer);
      if (target == gl.DRAW_FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);
      }
      if (target == gl.FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);
      }
      return true;
    }
    return false;
  }

  public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {
    var drawBuffers = this.defaultDrawbuffers;
    var needsUpdate = false;
    if (renderTarget != null) {
      drawBuffers = this.currentDrawbuffers.get(framebuffer);
      if (drawBuffers == null) {
        drawBuffers = [];
        this.currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      var textures = cast renderTarget.textures;
      if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
        for (var i = 0; i < textures.length; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] != gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }

  public function useProgram(program: WebGLProgram): Bool {
    if (this.currentProgram != program) {
      gl.useProgram(program);
      this.currentProgram = program;
      return true;
    }
    return false;
  }

  public function setBlending(
    blending: Int,
    blendEquation: Int = AddEquation,
    blendSrc: Int = SrcAlphaFactor,
    blendDst: Int = OneMinusSrcAlphaFactor,
    blendEquationAlpha: Int = null,
    blendSrcAlpha: Int = null,
    blendDstAlpha: Int = null,
    blendColor: Color = null,
    blendAlpha: Float = 0,
    premultipliedAlpha: Bool = false
  ): Void {
    if (blending == NoBlending) {
      if (this.currentBlendingEnabled) {
        this.disable(gl.BLEND);
        this.currentBlendingEnabled = false;
      }
      return;
    }
    if (!this.currentBlendingEnabled) {
      this.enable(gl.BLEND);
      this.currentBlendingEnabled = true;
    }
    if (blending != CustomBlending) {
      if (this.currentBlending != blending || this.currentPremultipledAlpha != premultipliedAlpha) {
        if (this.currentBlendEquation != AddEquation || this.currentBlendEquationAlpha != AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          this.currentBlendEquation = AddEquation;
          this.currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        }
        this.currentBlendSrc = null;
        this.currentBlendDst = null;
        this.currentBlendSrcAlpha = null;
        this.currentBlendDstAlpha = null;
        this.currentBlendColor.set(0, 0, 0);
        this.currentBlendAlpha = 0;
        this.currentBlending = blending;
        this.currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }
    blendEquationAlpha = blendEquationAlpha == null ? blendEquation : blendEquationAlpha;
    blendSrcAlpha = blendSrcAlpha == null ? blendSrc : blendSrcAlpha;
    blendDstAlpha = blendDstAlpha == null ? blendDst : blendDstAlpha;
    if (this.currentBlendEquation != blendEquation || this.currentBlendEquationAlpha != blendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      this.currentBlendEquation = blendEquation;
      this.currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (
      this.currentBlendSrc != blendSrc ||
      this.currentBlendDst != blendDst ||
      this.currentBlendSrcAlpha != blendSrcAlpha ||
      this.currentBlendDstAlpha != blendDstAlpha
    ) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      this.currentBlendSrc = blendSrc;
      this.currentBlendDst = blendDst;
      this.currentBlendSrcAlpha = blendSrcAlpha;
      this.currentBlendDstAlpha = blendDstAlpha;
    }
    if (this.currentBlendColor.equals(blendColor) == false || this.currentBlendAlpha != blendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      this.currentBlendColor.copy(blendColor);
      this.currentBlendAlpha = blendAlpha;
    }
    this.currentBlending = blending;
    this.currentPremultipledAlpha = false;
  }

  public function setMaterial(material: Dynamic, frontFaceCW: Bool = false): Void {
    if (material.side == DoubleSide) {
      this.disable(gl.CULL_FACE);
    } else {
      this.enable(gl.CULL_FACE);
    }
    var flipSided = material.side == BackSide;
    if (frontFaceCW) {
      flipSided = !flipSided;
    }
    this.setFlipSided(flipSided);
    if (material.blending == NormalBlending && material.transparent == false) {
      this.setBlending(NoBlending);
    } else {
      this.setBlending(
        material.blending,
        material.blendEquation,
        material.blendSrc,
        material.blendDst,
        material.blendEquationAlpha,
        material.blendSrcAlpha,
        material.blendDstAlpha,
        material.blendColor,
        material.blendAlpha,
        material.premultipliedAlpha
      );
    }
    this.depthBuffer.setFunc(material.depthFunc);
    this.depthBuffer.setTest(material.depthTest);
    this.depthBuffer.setMask(material.depthWrite);
    this.colorBuffer.setMask(material.colorWrite);
    var stencilWrite = material.stencilWrite;
    this.stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      this.stencilBuffer.setMask(material.stencilWriteMask);
      this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    if (material.alphaToCoverage) {
      this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    } else {
      this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    }
  }

  public function setFlipSided(flipSided: Bool): Void {
    if (this.currentFlipSided != flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      this.currentFlipSided = flipSided;
    }
  }

  public function setCullFace(cullFace: Int): Void {
    if (cullFace != CullFaceNone) {
      this.enable(gl.CULL_FACE);
      if (this.currentCullFace != cullFace) {
        if (cullFace == CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace == CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      this.disable(gl.CULL_FACE);
    }
    this.currentCullFace = cullFace;
  }

  public function setLineWidth(width: Float): Void {
    if (this.currentLineWidth != width) {
      if (this.lineWidthAvailable) {
        gl.lineWidth(width);
      }
      this.currentLineWidth = width;
    }
  }

  public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {
    if (polygonOffset) {
      this.enable(gl.POLYGON_OFFSET_FILL);
      if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {
        gl.polygonOffset(factor, units);
        this.currentPolygonOffsetFactor = factor;
        this.currentPolygonOffsetUnits = units;
      }
    } else {
      this.disable(gl.POLYGON_OFFSET_FILL);
    }
  }

  public function setScissorTest(scissorTest: Bool): Void {
    if (scissorTest) {
      this.enable(gl.SCISSOR_TEST);
    } else {
      this.disable(gl.SCISSOR_TEST);
    }
  }

  public function activeTexture(webglSlot: Int = null): Void {
    if (webglSlot == null) {
      webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
    }
    if (this.currentTextureSlot != webglSlot) {
      gl.activeTexture(webglSlot);
      this.currentTextureSlot = webglSlot;
    }
  }

  public function bindTexture(webglType: Int, webglTexture: WebGLTexture = null, webglSlot: Int = null): Void {
    if (webglSlot == null) {
      if (this.currentTextureSlot == null) {
        webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
      } else {
        webglSlot = this.currentTextureSlot;
      }
    }
    var boundTexture = this.currentBoundTextures.get(webglSlot);
    if (boundTexture == null) {
      boundTexture = {type: null, texture: null};
      this.currentBoundTextures.set(webglSlot, boundTexture);
    }
    if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
      if (this.currentTextureSlot != webglSlot) {
        gl.activeTexture(webglSlot);
        this.currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture == null ? this.emptyTextures[webglType] : webglTexture);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }

  public function unbindTexture(): Void {
    var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);
    if (boundTexture != null && boundTexture.type != null) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = null;
      boundTexture.texture = null;
    }
  }

  public function compressedTexImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage2D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int
  ): Void {
    try {
      gl.texStorage2D(target, levels, internalformat, width, height);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage3D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int
  ): Void {
    try {
      gl.texStorage3D(target, levels, internalformat, width, height, depth);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function scissor(scissor: Vector4): Void {
    if (this.currentScissor.equals(scissor) == false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      this.currentScissor.copy(scissor);
    }
  }

  public function viewport(viewport: Vector4): Void {
    if (this.currentViewport.equals(viewport) == false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      this.currentViewport.copy(viewport);
    }
  }

  public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    if (mapping == null) {
      mapping = new WeakMap();
      this.uboProgramMap.set(program, mapping);
    }
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (blockIndex == null) {
      blockIndex = gl.getUniformBlockIndex(program, cast uniformsGroup.name);
      mapping.set(cast uniformsGroup.name, blockIndex);
    }
  }

  public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (this.uboBindings.get(program) != blockIndex) {
      gl.uniformBlockBinding(program, blockIndex, cast uniformsGroup.__bindingPointIndex);
      this.uboBindings.set(program, blockIndex);
    }
  }

  public function reset(): Void {
    gl.disable(gl.BLEND);
    gl.disable(gl.CULL_FACE);
    gl.disable(gl.DEPTH_TEST);
    gl.disable(gl.POLYGON_OFFSET_FILL);
    gl.disable(gl.SCISSOR_TEST);
    gl.disable(gl.STENCIL_TEST);
    gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    gl.blendEquation(gl.FUNC_ADD);
    gl.blendFunc(gl.ONE, gl.ZERO);
    gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
    gl.blendColor(0, 0, 0, 0);
    gl.colorMask(true, true, true, true);
    gl.clearColor(0, 0, 0, 0);
    gl.depthMask(true);
    gl.depthFunc(gl.LESS);
    gl.clearDepth(1);
    gl.stencilMask(0xffffffff);
    gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
    gl.clearStencil(0);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CCW);
    gl.polygonOffset(0, 0);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
    gl.useProgram(null);
    gl.lineWidth(1);
    gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    this.enabledCapabilities = new Map();
    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();
    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];
    this.currentProgram = null;
    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;
    this.currentFlipSided = null;
    this.currentCullFace = null;
    this.currentLineWidth = null;
    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;
    this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.colorBuffer.reset();
    this.depthBuffer.reset();
    this.stencilBuffer.reset();
  }

  public var buffers: { color: ColorBuffer, depth: DepthBuffer, stencil: StencilBuffer };

  private static var equationToGL: Map<Int, Int> = new Map();
  private static var factorToGL: Map<Int, Int> = new Map();

  static function init() {
    equationToGL[AddEquation] = gl.FUNC_ADD;
    equationToGL[SubtractEquation] = gl.FUNC_SUBTRACT;
    equationToGL[ReverseSubtractEquation] = gl.FUNC_REVERSE_SUBTRACT;
    equationToGL[MinEquation] = gl.MIN;
    equationToGL[MaxEquation] = gl.MAX;
    factorToGL[ZeroFactor] = gl.ZERO;
    factorToGL[OneFactor] = gl.ONE;
    factorToGL[SrcColorFactor] = gl.SRC_COLOR;
    factorToGL[SrcAlphaFactor] = gl.SRC_ALPHA;
    factorToGL[SrcAlphaSaturateFactor] = gl.SRC_ALPHA_SATURATE;
    factorToGL[DstColorFactor] = gl.DST_COLOR;
    factorToGL[DstAlphaFactor] = gl.DST_ALPHA;
    factorToGL[OneMinusSrcColorFactor] = gl.ONE_MINUS_SRC_COLOR;
    factorToGL[OneMinusSrcAlphaFactor] = gl.ONE_MINUS_SRC_ALPHA;
    factorToGL[OneMinusDstColorFactor] = gl.ONE_MINUS_DST_COLOR;
    factorToGL[OneMinusDstAlphaFactor] = gl.ONE_MINUS_DST_ALPHA;
    factorToGL[ConstantColorFactor] = gl.CONSTANT_COLOR;
    factorToGL[OneMinusConstantColorFactor] = gl.ONE_MINUS_CONSTANT_COLOR;
    factorToGL[ConstantAlphaFactor] = gl.CONSTANT_ALPHA;
    factorToGL[OneMinusConstantAlphaFactor] = gl.ONE_MINUS_CONSTANT_ALPHA;
  }

  private class ColorBuffer {
    private var locked: Bool;
    private var color: Vector4;
    private var currentColorMask: Bool;
    private var currentColorClear: Vector4;

    public function new() {
      this.locked = false;
      this.color = new Vector4();
      this.currentColorMask = null;
      this.currentColorClear = new Vector4(0, 0, 0, 0);
    }

    public function setMask(colorMask: Bool): Void {
      if (this.currentColorMask != colorMask && !this.locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        this.currentColorMask = colorMask;
      }
    }

    public function setLocked(lock: Bool): Void {
      this.locked = lock;
    }

    public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {
      if (premultipliedAlpha) {
        r *= a;
        g *= a;
        b *= a;
      }
      this.color.set(r, g, b, a);
      if (this.currentColorClear.equals(this.color) == false) {
        gl.clearColor(r, g, b, a);
        this.currentColorClear.copy(this.color);
      }
    }

    public function reset(): Void {
      this.locked = false;
      this.currentColorMask = null;
      this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  }

  private class DepthBuffer {
    private var locked: Bool;
    private var currentDepthMask: Bool;
    private var currentDepthFunc: Int;
    private var currentDepthClear: Float;

    public function new() {
      this.locked = false;
      this.currentDepthMask = null
import haxe.ds.WeakMap;
import three.math.Color;
import three.math.Vector4;
import three.constants.*;

class WebGLState {
  private var gl: WebGLRenderingContext;
  private var colorBuffer: ColorBuffer;
  private var depthBuffer: DepthBuffer;
  private var stencilBuffer: StencilBuffer;
  private var uboBindings: WeakMap<WebGLProgram, Int>;
  private var uboProgramMap: WeakMap<WebGLProgram, WeakMap<String, Int>>;
  private var enabledCapabilities: Map<Int, Bool>;
  private var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
  private var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
  private var defaultDrawbuffers: Array<Int>;
  private var currentProgram: WebGLProgram;
  private var currentBlendingEnabled: Bool;
  private var currentBlending: Int;
  private var currentBlendEquation: Int;
  private var currentBlendSrc: Int;
  private var currentBlendDst: Int;
  private var currentBlendEquationAlpha: Int;
  private var currentBlendSrcAlpha: Int;
  private var currentBlendDstAlpha: Int;
  private var currentBlendColor: Color;
  private var currentBlendAlpha: Float;
  private var currentPremultipledAlpha: Bool;
  private var currentFlipSided: Bool;
  private var currentCullFace: Int;
  private var currentLineWidth: Float;
  private var currentPolygonOffsetFactor: Float;
  private var currentPolygonOffsetUnits: Float;
  private var maxTextures: Int;
  private var lineWidthAvailable: Bool;
  private var version: Float;
  private var currentTextureSlot: Int;
  private var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;
  private var scissorParam: Array<Int>;
  private var viewportParam: Array<Int>;
  private var currentScissor: Vector4;
  private var currentViewport: Vector4;
  private var emptyTextures: Map<Int, WebGLTexture>;

  public function new(gl: WebGLRenderingContext) {
    this.gl = gl;

    this.colorBuffer = new ColorBuffer();
    this.depthBuffer = new DepthBuffer();
    this.stencilBuffer = new StencilBuffer();

    this.uboBindings = new WeakMap();
    this.uboProgramMap = new WeakMap();

    this.enabledCapabilities = new Map();

    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];

    this.currentProgram = null;

    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;

    this.currentFlipSided = null;
    this.currentCullFace = null;

    this.currentLineWidth = null;

    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;

    this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

    this.lineWidthAvailable = false;
    this.version = 0;
    var glVersion = gl.getParameter(gl.VERSION);

    if (glVersion.indexOf("WebGL") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^WebGL (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 1.0;
    } else if (glVersion.indexOf("OpenGL ES") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^OpenGL ES (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 2.0;
    }

    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();

    this.scissorParam = gl.getParameter(gl.SCISSOR_BOX);
    this.viewportParam = gl.getParameter(gl.VIEWPORT);

    this.currentScissor = new Vector4().fromArray(this.scissorParam);
    this.currentViewport = new Vector4().fromArray(this.viewportParam);

    this.emptyTextures = new Map();
    this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
    this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
    this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
    this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

    this.colorBuffer.setClear(0, 0, 0, 1);
    this.depthBuffer.setClear(1);
    this.stencilBuffer.setClear(0);

    this.enable(gl.DEPTH_TEST);
    this.depthBuffer.setFunc(LessEqualDepth);

    this.setFlipSided(false);
    this.setCullFace(CullFaceBack);
    this.enable(gl.CULL_FACE);

    this.setBlending(NoBlending);
  }

  private function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {
    var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    var texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (var i = 0; i < count; i++) {
      if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }

  public function enable(id: Int): Void {
    if (!this.enabledCapabilities.exists(id) || !this.enabledCapabilities.get(id)) {
      gl.enable(id);
      this.enabledCapabilities.set(id, true);
    }
  }

  public function disable(id: Int): Void {
    if (this.enabledCapabilities.exists(id) && this.enabledCapabilities.get(id)) {
      gl.disable(id);
      this.enabledCapabilities.set(id, false);
    }
  }

  public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {
    if (this.currentBoundFramebuffers.get(target) != framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      this.currentBoundFramebuffers.set(target, framebuffer);
      if (target == gl.DRAW_FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);
      }
      if (target == gl.FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);
      }
      return true;
    }
    return false;
  }

  public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {
    var drawBuffers = this.defaultDrawbuffers;
    var needsUpdate = false;
    if (renderTarget != null) {
      drawBuffers = this.currentDrawbuffers.get(framebuffer);
      if (drawBuffers == null) {
        drawBuffers = [];
        this.currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      var textures = cast renderTarget.textures;
      if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
        for (var i = 0; i < textures.length; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] != gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }

  public function useProgram(program: WebGLProgram): Bool {
    if (this.currentProgram != program) {
      gl.useProgram(program);
      this.currentProgram = program;
      return true;
    }
    return false;
  }

  public function setBlending(
    blending: Int,
    blendEquation: Int = AddEquation,
    blendSrc: Int = SrcAlphaFactor,
    blendDst: Int = OneMinusSrcAlphaFactor,
    blendEquationAlpha: Int = null,
    blendSrcAlpha: Int = null,
    blendDstAlpha: Int = null,
    blendColor: Color = null,
    blendAlpha: Float = 0,
    premultipliedAlpha: Bool = false
  ): Void {
    if (blending == NoBlending) {
      if (this.currentBlendingEnabled) {
        this.disable(gl.BLEND);
        this.currentBlendingEnabled = false;
      }
      return;
    }
    if (!this.currentBlendingEnabled) {
      this.enable(gl.BLEND);
      this.currentBlendingEnabled = true;
    }
    if (blending != CustomBlending) {
      if (this.currentBlending != blending || this.currentPremultipledAlpha != premultipliedAlpha) {
        if (this.currentBlendEquation != AddEquation || this.currentBlendEquationAlpha != AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          this.currentBlendEquation = AddEquation;
          this.currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        }
        this.currentBlendSrc = null;
        this.currentBlendDst = null;
        this.currentBlendSrcAlpha = null;
        this.currentBlendDstAlpha = null;
        this.currentBlendColor.set(0, 0, 0);
        this.currentBlendAlpha = 0;
        this.currentBlending = blending;
        this.currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }
    blendEquationAlpha = blendEquationAlpha == null ? blendEquation : blendEquationAlpha;
    blendSrcAlpha = blendSrcAlpha == null ? blendSrc : blendSrcAlpha;
    blendDstAlpha = blendDstAlpha == null ? blendDst : blendDstAlpha;
    if (this.currentBlendEquation != blendEquation || this.currentBlendEquationAlpha != blendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      this.currentBlendEquation = blendEquation;
      this.currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (
      this.currentBlendSrc != blendSrc ||
      this.currentBlendDst != blendDst ||
      this.currentBlendSrcAlpha != blendSrcAlpha ||
      this.currentBlendDstAlpha != blendDstAlpha
    ) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      this.currentBlendSrc = blendSrc;
      this.currentBlendDst = blendDst;
      this.currentBlendSrcAlpha = blendSrcAlpha;
      this.currentBlendDstAlpha = blendDstAlpha;
    }
    if (this.currentBlendColor.equals(blendColor) == false || this.currentBlendAlpha != blendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      this.currentBlendColor.copy(blendColor);
      this.currentBlendAlpha = blendAlpha;
    }
    this.currentBlending = blending;
    this.currentPremultipledAlpha = false;
  }

  public function setMaterial(material: Dynamic, frontFaceCW: Bool = false): Void {
    if (material.side == DoubleSide) {
      this.disable(gl.CULL_FACE);
    } else {
      this.enable(gl.CULL_FACE);
    }
    var flipSided = material.side == BackSide;
    if (frontFaceCW) {
      flipSided = !flipSided;
    }
    this.setFlipSided(flipSided);
    if (material.blending == NormalBlending && material.transparent == false) {
      this.setBlending(NoBlending);
    } else {
      this.setBlending(
        material.blending,
        material.blendEquation,
        material.blendSrc,
        material.blendDst,
        material.blendEquationAlpha,
        material.blendSrcAlpha,
        material.blendDstAlpha,
        material.blendColor,
        material.blendAlpha,
        material.premultipliedAlpha
      );
    }
    this.depthBuffer.setFunc(material.depthFunc);
    this.depthBuffer.setTest(material.depthTest);
    this.depthBuffer.setMask(material.depthWrite);
    this.colorBuffer.setMask(material.colorWrite);
    var stencilWrite = material.stencilWrite;
    this.stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      this.stencilBuffer.setMask(material.stencilWriteMask);
      this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    if (material.alphaToCoverage) {
      this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    } else {
      this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    }
  }

  public function setFlipSided(flipSided: Bool): Void {
    if (this.currentFlipSided != flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      this.currentFlipSided = flipSided;
    }
  }

  public function setCullFace(cullFace: Int): Void {
    if (cullFace != CullFaceNone) {
      this.enable(gl.CULL_FACE);
      if (this.currentCullFace != cullFace) {
        if (cullFace == CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace == CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      this.disable(gl.CULL_FACE);
    }
    this.currentCullFace = cullFace;
  }

  public function setLineWidth(width: Float): Void {
    if (this.currentLineWidth != width) {
      if (this.lineWidthAvailable) {
        gl.lineWidth(width);
      }
      this.currentLineWidth = width;
    }
  }

  public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {
    if (polygonOffset) {
      this.enable(gl.POLYGON_OFFSET_FILL);
      if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {
        gl.polygonOffset(factor, units);
        this.currentPolygonOffsetFactor = factor;
        this.currentPolygonOffsetUnits = units;
      }
    } else {
      this.disable(gl.POLYGON_OFFSET_FILL);
    }
  }

  public function setScissorTest(scissorTest: Bool): Void {
    if (scissorTest) {
      this.enable(gl.SCISSOR_TEST);
    } else {
      this.disable(gl.SCISSOR_TEST);
    }
  }

  public function activeTexture(webglSlot: Int = null): Void {
    if (webglSlot == null) {
      webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
    }
    if (this.currentTextureSlot != webglSlot) {
      gl.activeTexture(webglSlot);
      this.currentTextureSlot = webglSlot;
    }
  }

  public function bindTexture(webglType: Int, webglTexture: WebGLTexture = null, webglSlot: Int = null): Void {
    if (webglSlot == null) {
      if (this.currentTextureSlot == null) {
        webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
      } else {
        webglSlot = this.currentTextureSlot;
      }
    }
    var boundTexture = this.currentBoundTextures.get(webglSlot);
    if (boundTexture == null) {
      boundTexture = {type: null, texture: null};
      this.currentBoundTextures.set(webglSlot, boundTexture);
    }
    if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
      if (this.currentTextureSlot != webglSlot) {
        gl.activeTexture(webglSlot);
        this.currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture == null ? this.emptyTextures[webglType] : webglTexture);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }

  public function unbindTexture(): Void {
    var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);
    if (boundTexture != null && boundTexture.type != null) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = null;
      boundTexture.texture = null;
    }
  }

  public function compressedTexImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage2D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int
  ): Void {
    try {
      gl.texStorage2D(target, levels, internalformat, width, height);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage3D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int
  ): Void {
    try {
      gl.texStorage3D(target, levels, internalformat, width, height, depth);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function scissor(scissor: Vector4): Void {
    if (this.currentScissor.equals(scissor) == false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      this.currentScissor.copy(scissor);
    }
  }

  public function viewport(viewport: Vector4): Void {
    if (this.currentViewport.equals(viewport) == false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      this.currentViewport.copy(viewport);
    }
  }

  public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    if (mapping == null) {
      mapping = new WeakMap();
      this.uboProgramMap.set(program, mapping);
    }
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (blockIndex == null) {
      blockIndex = gl.getUniformBlockIndex(program, cast uniformsGroup.name);
      mapping.set(cast uniformsGroup.name, blockIndex);
    }
  }

  public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (this.uboBindings.get(program) != blockIndex) {
      gl.uniformBlockBinding(program, blockIndex, cast uniformsGroup.__bindingPointIndex);
      this.uboBindings.set(program, blockIndex);
    }
  }

  public function reset(): Void {
    gl.disable(gl.BLEND);
    gl.disable(gl.CULL_FACE);
    gl.disable(gl.DEPTH_TEST);
    gl.disable(gl.POLYGON_OFFSET_FILL);
    gl.disable(gl.SCISSOR_TEST);
    gl.disable(gl.STENCIL_TEST);
    gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    gl.blendEquation(gl.FUNC_ADD);
    gl.blendFunc(gl.ONE, gl.ZERO);
    gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
    gl.blendColor(0, 0, 0, 0);
    gl.colorMask(true, true, true, true);
    gl.clearColor(0, 0, 0, 0);
    gl.depthMask(true);
    gl.depthFunc(gl.LESS);
    gl.clearDepth(1);
    gl.stencilMask(0xffffffff);
    gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
    gl.clearStencil(0);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CCW);
    gl.polygonOffset(0, 0);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
    gl.useProgram(null);
    gl.lineWidth(1);
    gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    this.enabledCapabilities = new Map();
    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();
    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];
    this.currentProgram = null;
    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;
    this.currentFlipSided = null;
    this.currentCullFace = null;
    this.currentLineWidth = null;
    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;
    this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.colorBuffer.reset();
    this.depthBuffer.reset();
    this.stencilBuffer.reset();
  }

  public var buffers: { color: ColorBuffer, depth: DepthBuffer, stencil: StencilBuffer };

  private static var equationToGL: Map<Int, Int> = new Map();
  private static var factorToGL: Map<Int, Int> = new Map();

  static function init() {
    equationToGL[AddEquation] = gl.FUNC_ADD;
    equationToGL[SubtractEquation] = gl.FUNC_SUBTRACT;
    equationToGL[ReverseSubtractEquation] = gl.FUNC_REVERSE_SUBTRACT;
    equationToGL[MinEquation] = gl.MIN;
    equationToGL[MaxEquation] = gl.MAX;
    factorToGL[ZeroFactor] = gl.ZERO;
    factorToGL[OneFactor] = gl.ONE;
    factorToGL[SrcColorFactor] = gl.SRC_COLOR;
    factorToGL[SrcAlphaFactor] = gl.SRC_ALPHA;
    factorToGL[SrcAlphaSaturateFactor] = gl.SRC_ALPHA_SATURATE;
    factorToGL[DstColorFactor] = gl.DST_COLOR;
    factorToGL[DstAlphaFactor] = gl.DST_ALPHA;
    factorToGL[OneMinusSrcColorFactor] = gl.ONE_MINUS_SRC_COLOR;
    factorToGL[OneMinusSrcAlphaFactor] = gl.ONE_MINUS_SRC_ALPHA;
    factorToGL[OneMinusDstColorFactor] = gl.ONE_MINUS_DST_COLOR;
    factorToGL[OneMinusDstAlphaFactor] = gl.ONE_MINUS_DST_ALPHA;
    factorToGL[ConstantColorFactor] = gl.CONSTANT_COLOR;
    factorToGL[OneMinusConstantColorFactor] = gl.ONE_MINUS_CONSTANT_COLOR;
    factorToGL[ConstantAlphaFactor] = gl.CONSTANT_ALPHA;
    factorToGL[OneMinusConstantAlphaFactor] = gl.ONE_MINUS_CONSTANT_ALPHA;
  }

  private class ColorBuffer {
    private var locked: Bool;
    private var color: Vector4;
    private var currentColorMask: Bool;
    private var currentColorClear: Vector4;

    public function new() {
      this.locked = false;
      this.color = new Vector4();
      this.currentColorMask = null;
      this.currentColorClear = new Vector4(0, 0, 0, 0);
    }

    public function setMask(colorMask: Bool): Void {
      if (this.currentColorMask != colorMask && !this.locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        this.currentColorMask = colorMask;
      }
    }

    public function setLocked(lock: Bool): Void {
      this.locked = lock;
    }

    public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {
      if (premultipliedAlpha) {
        r *= a;
        g *= a;
        b *= a;
      }
      this.color.set(r, g, b, a);
      if (this.currentColorClear.equals(this.color) == false) {
        gl.clearColor(r, g, b, a);
        this.currentColorClear.copy(this.color);
      }
    }

    public function reset(): Void {
      this.locked = false;
      this.currentColorMask = null;
      this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  }

  private class DepthBuffer {
    private var locked: Bool;
    private var currentDepthMask: Bool;
    private var currentDepthFunc: Int;
    private var currentDepthClear: Float;

    public function new() {
      this.locked = false;
      this.currentDepthMask = null
import haxe.ds.WeakMap;
import three.math.Color;
import three.math.Vector4;
import three.constants.*;

class WebGLState {
  private var gl: WebGLRenderingContext;
  private var colorBuffer: ColorBuffer;
  private var depthBuffer: DepthBuffer;
  private var stencilBuffer: StencilBuffer;
  private var uboBindings: WeakMap<WebGLProgram, Int>;
  private var uboProgramMap: WeakMap<WebGLProgram, WeakMap<String, Int>>;
  private var enabledCapabilities: Map<Int, Bool>;
  private var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
  private var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
  private var defaultDrawbuffers: Array<Int>;
  private var currentProgram: WebGLProgram;
  private var currentBlendingEnabled: Bool;
  private var currentBlending: Int;
  private var currentBlendEquation: Int;
  private var currentBlendSrc: Int;
  private var currentBlendDst: Int;
  private var currentBlendEquationAlpha: Int;
  private var currentBlendSrcAlpha: Int;
  private var currentBlendDstAlpha: Int;
  private var currentBlendColor: Color;
  private var currentBlendAlpha: Float;
  private var currentPremultipledAlpha: Bool;
  private var currentFlipSided: Bool;
  private var currentCullFace: Int;
  private var currentLineWidth: Float;
  private var currentPolygonOffsetFactor: Float;
  private var currentPolygonOffsetUnits: Float;
  private var maxTextures: Int;
  private var lineWidthAvailable: Bool;
  private var version: Float;
  private var currentTextureSlot: Int;
  private var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;
  private var scissorParam: Array<Int>;
  private var viewportParam: Array<Int>;
  private var currentScissor: Vector4;
  private var currentViewport: Vector4;
  private var emptyTextures: Map<Int, WebGLTexture>;

  public function new(gl: WebGLRenderingContext) {
    this.gl = gl;

    this.colorBuffer = new ColorBuffer();
    this.depthBuffer = new DepthBuffer();
    this.stencilBuffer = new StencilBuffer();

    this.uboBindings = new WeakMap();
    this.uboProgramMap = new WeakMap();

    this.enabledCapabilities = new Map();

    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];

    this.currentProgram = null;

    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;

    this.currentFlipSided = null;
    this.currentCullFace = null;

    this.currentLineWidth = null;

    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;

    this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

    this.lineWidthAvailable = false;
    this.version = 0;
    var glVersion = gl.getParameter(gl.VERSION);

    if (glVersion.indexOf("WebGL") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^WebGL (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 1.0;
    } else if (glVersion.indexOf("OpenGL ES") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^OpenGL ES (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 2.0;
    }

    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();

    this.scissorParam = gl.getParameter(gl.SCISSOR_BOX);
    this.viewportParam = gl.getParameter(gl.VIEWPORT);

    this.currentScissor = new Vector4().fromArray(this.scissorParam);
    this.currentViewport = new Vector4().fromArray(this.viewportParam);

    this.emptyTextures = new Map();
    this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
    this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
    this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
    this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

    this.colorBuffer.setClear(0, 0, 0, 1);
    this.depthBuffer.setClear(1);
    this.stencilBuffer.setClear(0);

    this.enable(gl.DEPTH_TEST);
    this.depthBuffer.setFunc(LessEqualDepth);

    this.setFlipSided(false);
    this.setCullFace(CullFaceBack);
    this.enable(gl.CULL_FACE);

    this.setBlending(NoBlending);
  }

  private function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {
    var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    var texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (var i = 0; i < count; i++) {
      if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }

  public function enable(id: Int): Void {
    if (!this.enabledCapabilities.exists(id) || !this.enabledCapabilities.get(id)) {
      gl.enable(id);
      this.enabledCapabilities.set(id, true);
    }
  }

  public function disable(id: Int): Void {
    if (this.enabledCapabilities.exists(id) && this.enabledCapabilities.get(id)) {
      gl.disable(id);
      this.enabledCapabilities.set(id, false);
    }
  }

  public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {
    if (this.currentBoundFramebuffers.get(target) != framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      this.currentBoundFramebuffers.set(target, framebuffer);
      if (target == gl.DRAW_FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);
      }
      if (target == gl.FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);
      }
      return true;
    }
    return false;
  }

  public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {
    var drawBuffers = this.defaultDrawbuffers;
    var needsUpdate = false;
    if (renderTarget != null) {
      drawBuffers = this.currentDrawbuffers.get(framebuffer);
      if (drawBuffers == null) {
        drawBuffers = [];
        this.currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      var textures = cast renderTarget.textures;
      if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
        for (var i = 0; i < textures.length; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] != gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }

  public function useProgram(program: WebGLProgram): Bool {
    if (this.currentProgram != program) {
      gl.useProgram(program);
      this.currentProgram = program;
      return true;
    }
    return false;
  }

  public function setBlending(
    blending: Int,
    blendEquation: Int = AddEquation,
    blendSrc: Int = SrcAlphaFactor,
    blendDst: Int = OneMinusSrcAlphaFactor,
    blendEquationAlpha: Int = null,
    blendSrcAlpha: Int = null,
    blendDstAlpha: Int = null,
    blendColor: Color = null,
    blendAlpha: Float = 0,
    premultipliedAlpha: Bool = false
  ): Void {
    if (blending == NoBlending) {
      if (this.currentBlendingEnabled) {
        this.disable(gl.BLEND);
        this.currentBlendingEnabled = false;
      }
      return;
    }
    if (!this.currentBlendingEnabled) {
      this.enable(gl.BLEND);
      this.currentBlendingEnabled = true;
    }
    if (blending != CustomBlending) {
      if (this.currentBlending != blending || this.currentPremultipledAlpha != premultipliedAlpha) {
        if (this.currentBlendEquation != AddEquation || this.currentBlendEquationAlpha != AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          this.currentBlendEquation = AddEquation;
          this.currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        }
        this.currentBlendSrc = null;
        this.currentBlendDst = null;
        this.currentBlendSrcAlpha = null;
        this.currentBlendDstAlpha = null;
        this.currentBlendColor.set(0, 0, 0);
        this.currentBlendAlpha = 0;
        this.currentBlending = blending;
        this.currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }
    blendEquationAlpha = blendEquationAlpha == null ? blendEquation : blendEquationAlpha;
    blendSrcAlpha = blendSrcAlpha == null ? blendSrc : blendSrcAlpha;
    blendDstAlpha = blendDstAlpha == null ? blendDst : blendDstAlpha;
    if (this.currentBlendEquation != blendEquation || this.currentBlendEquationAlpha != blendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      this.currentBlendEquation = blendEquation;
      this.currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (
      this.currentBlendSrc != blendSrc ||
      this.currentBlendDst != blendDst ||
      this.currentBlendSrcAlpha != blendSrcAlpha ||
      this.currentBlendDstAlpha != blendDstAlpha
    ) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      this.currentBlendSrc = blendSrc;
      this.currentBlendDst = blendDst;
      this.currentBlendSrcAlpha = blendSrcAlpha;
      this.currentBlendDstAlpha = blendDstAlpha;
    }
    if (this.currentBlendColor.equals(blendColor) == false || this.currentBlendAlpha != blendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      this.currentBlendColor.copy(blendColor);
      this.currentBlendAlpha = blendAlpha;
    }
    this.currentBlending = blending;
    this.currentPremultipledAlpha = false;
  }

  public function setMaterial(material: Dynamic, frontFaceCW: Bool = false): Void {
    if (material.side == DoubleSide) {
      this.disable(gl.CULL_FACE);
    } else {
      this.enable(gl.CULL_FACE);
    }
    var flipSided = material.side == BackSide;
    if (frontFaceCW) {
      flipSided = !flipSided;
    }
    this.setFlipSided(flipSided);
    if (material.blending == NormalBlending && material.transparent == false) {
      this.setBlending(NoBlending);
    } else {
      this.setBlending(
        material.blending,
        material.blendEquation,
        material.blendSrc,
        material.blendDst,
        material.blendEquationAlpha,
        material.blendSrcAlpha,
        material.blendDstAlpha,
        material.blendColor,
        material.blendAlpha,
        material.premultipliedAlpha
      );
    }
    this.depthBuffer.setFunc(material.depthFunc);
    this.depthBuffer.setTest(material.depthTest);
    this.depthBuffer.setMask(material.depthWrite);
    this.colorBuffer.setMask(material.colorWrite);
    var stencilWrite = material.stencilWrite;
    this.stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      this.stencilBuffer.setMask(material.stencilWriteMask);
      this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    if (material.alphaToCoverage) {
      this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    } else {
      this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    }
  }

  public function setFlipSided(flipSided: Bool): Void {
    if (this.currentFlipSided != flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      this.currentFlipSided = flipSided;
    }
  }

  public function setCullFace(cullFace: Int): Void {
    if (cullFace != CullFaceNone) {
      this.enable(gl.CULL_FACE);
      if (this.currentCullFace != cullFace) {
        if (cullFace == CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace == CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      this.disable(gl.CULL_FACE);
    }
    this.currentCullFace = cullFace;
  }

  public function setLineWidth(width: Float): Void {
    if (this.currentLineWidth != width) {
      if (this.lineWidthAvailable) {
        gl.lineWidth(width);
      }
      this.currentLineWidth = width;
    }
  }

  public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {
    if (polygonOffset) {
      this.enable(gl.POLYGON_OFFSET_FILL);
      if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {
        gl.polygonOffset(factor, units);
        this.currentPolygonOffsetFactor = factor;
        this.currentPolygonOffsetUnits = units;
      }
    } else {
      this.disable(gl.POLYGON_OFFSET_FILL);
    }
  }

  public function setScissorTest(scissorTest: Bool): Void {
    if (scissorTest) {
      this.enable(gl.SCISSOR_TEST);
    } else {
      this.disable(gl.SCISSOR_TEST);
    }
  }

  public function activeTexture(webglSlot: Int = null): Void {
    if (webglSlot == null) {
      webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
    }
    if (this.currentTextureSlot != webglSlot) {
      gl.activeTexture(webglSlot);
      this.currentTextureSlot = webglSlot;
    }
  }

  public function bindTexture(webglType: Int, webglTexture: WebGLTexture = null, webglSlot: Int = null): Void {
    if (webglSlot == null) {
      if (this.currentTextureSlot == null) {
        webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
      } else {
        webglSlot = this.currentTextureSlot;
      }
    }
    var boundTexture = this.currentBoundTextures.get(webglSlot);
    if (boundTexture == null) {
      boundTexture = {type: null, texture: null};
      this.currentBoundTextures.set(webglSlot, boundTexture);
    }
    if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
      if (this.currentTextureSlot != webglSlot) {
        gl.activeTexture(webglSlot);
        this.currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture == null ? this.emptyTextures[webglType] : webglTexture);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }

  public function unbindTexture(): Void {
    var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);
    if (boundTexture != null && boundTexture.type != null) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = null;
      boundTexture.texture = null;
    }
  }

  public function compressedTexImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage2D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int
  ): Void {
    try {
      gl.texStorage2D(target, levels, internalformat, width, height);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage3D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int
  ): Void {
    try {
      gl.texStorage3D(target, levels, internalformat, width, height, depth);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function scissor(scissor: Vector4): Void {
    if (this.currentScissor.equals(scissor) == false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      this.currentScissor.copy(scissor);
    }
  }

  public function viewport(viewport: Vector4): Void {
    if (this.currentViewport.equals(viewport) == false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      this.currentViewport.copy(viewport);
    }
  }

  public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    if (mapping == null) {
      mapping = new WeakMap();
      this.uboProgramMap.set(program, mapping);
    }
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (blockIndex == null) {
      blockIndex = gl.getUniformBlockIndex(program, cast uniformsGroup.name);
      mapping.set(cast uniformsGroup.name, blockIndex);
    }
  }

  public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (this.uboBindings.get(program) != blockIndex) {
      gl.uniformBlockBinding(program, blockIndex, cast uniformsGroup.__bindingPointIndex);
      this.uboBindings.set(program, blockIndex);
    }
  }

  public function reset(): Void {
    gl.disable(gl.BLEND);
    gl.disable(gl.CULL_FACE);
    gl.disable(gl.DEPTH_TEST);
    gl.disable(gl.POLYGON_OFFSET_FILL);
    gl.disable(gl.SCISSOR_TEST);
    gl.disable(gl.STENCIL_TEST);
    gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    gl.blendEquation(gl.FUNC_ADD);
    gl.blendFunc(gl.ONE, gl.ZERO);
    gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
    gl.blendColor(0, 0, 0, 0);
    gl.colorMask(true, true, true, true);
    gl.clearColor(0, 0, 0, 0);
    gl.depthMask(true);
    gl.depthFunc(gl.LESS);
    gl.clearDepth(1);
    gl.stencilMask(0xffffffff);
    gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
    gl.clearStencil(0);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CCW);
    gl.polygonOffset(0, 0);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
    gl.useProgram(null);
    gl.lineWidth(1);
    gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    this.enabledCapabilities = new Map();
    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();
    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];
    this.currentProgram = null;
    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;
    this.currentFlipSided = null;
    this.currentCullFace = null;
    this.currentLineWidth = null;
    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;
    this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.colorBuffer.reset();
    this.depthBuffer.reset();
    this.stencilBuffer.reset();
  }

  public var buffers: { color: ColorBuffer, depth: DepthBuffer, stencil: StencilBuffer };

  private static var equationToGL: Map<Int, Int> = new Map();
  private static var factorToGL: Map<Int, Int> = new Map();

  static function init() {
    equationToGL[AddEquation] = gl.FUNC_ADD;
    equationToGL[SubtractEquation] = gl.FUNC_SUBTRACT;
    equationToGL[ReverseSubtractEquation] = gl.FUNC_REVERSE_SUBTRACT;
    equationToGL[MinEquation] = gl.MIN;
    equationToGL[MaxEquation] = gl.MAX;
    factorToGL[ZeroFactor] = gl.ZERO;
    factorToGL[OneFactor] = gl.ONE;
    factorToGL[SrcColorFactor] = gl.SRC_COLOR;
    factorToGL[SrcAlphaFactor] = gl.SRC_ALPHA;
    factorToGL[SrcAlphaSaturateFactor] = gl.SRC_ALPHA_SATURATE;
    factorToGL[DstColorFactor] = gl.DST_COLOR;
    factorToGL[DstAlphaFactor] = gl.DST_ALPHA;
    factorToGL[OneMinusSrcColorFactor] = gl.ONE_MINUS_SRC_COLOR;
    factorToGL[OneMinusSrcAlphaFactor] = gl.ONE_MINUS_SRC_ALPHA;
    factorToGL[OneMinusDstColorFactor] = gl.ONE_MINUS_DST_COLOR;
    factorToGL[OneMinusDstAlphaFactor] = gl.ONE_MINUS_DST_ALPHA;
    factorToGL[ConstantColorFactor] = gl.CONSTANT_COLOR;
    factorToGL[OneMinusConstantColorFactor] = gl.ONE_MINUS_CONSTANT_COLOR;
    factorToGL[ConstantAlphaFactor] = gl.CONSTANT_ALPHA;
    factorToGL[OneMinusConstantAlphaFactor] = gl.ONE_MINUS_CONSTANT_ALPHA;
  }

  private class ColorBuffer {
    private var locked: Bool;
    private var color: Vector4;
    private var currentColorMask: Bool;
    private var currentColorClear: Vector4;

    public function new() {
      this.locked = false;
      this.color = new Vector4();
      this.currentColorMask = null;
      this.currentColorClear = new Vector4(0, 0, 0, 0);
    }

    public function setMask(colorMask: Bool): Void {
      if (this.currentColorMask != colorMask && !this.locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        this.currentColorMask = colorMask;
      }
    }

    public function setLocked(lock: Bool): Void {
      this.locked = lock;
    }

    public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {
      if (premultipliedAlpha) {
        r *= a;
        g *= a;
        b *= a;
      }
      this.color.set(r, g, b, a);
      if (this.currentColorClear.equals(this.color) == false) {
        gl.clearColor(r, g, b, a);
        this.currentColorClear.copy(this.color);
      }
    }

    public function reset(): Void {
      this.locked = false;
      this.currentColorMask = null;
      this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  }

  private class DepthBuffer {
    private var locked: Bool;
    private var currentDepthMask: Bool;
    private var currentDepthFunc: Int;
    private var currentDepthClear: Float;

    public function new() {
      this.locked = false;
      this.currentDepthMask = null
import haxe.ds.WeakMap;
import three.math.Color;
import three.math.Vector4;
import three.constants.*;

class WebGLState {
  private var gl: WebGLRenderingContext;
  private var colorBuffer: ColorBuffer;
  private var depthBuffer: DepthBuffer;
  private var stencilBuffer: StencilBuffer;
  private var uboBindings: WeakMap<WebGLProgram, Int>;
  private var uboProgramMap: WeakMap<WebGLProgram, WeakMap<String, Int>>;
  private var enabledCapabilities: Map<Int, Bool>;
  private var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
  private var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
  private var defaultDrawbuffers: Array<Int>;
  private var currentProgram: WebGLProgram;
  private var currentBlendingEnabled: Bool;
  private var currentBlending: Int;
  private var currentBlendEquation: Int;
  private var currentBlendSrc: Int;
  private var currentBlendDst: Int;
  private var currentBlendEquationAlpha: Int;
  private var currentBlendSrcAlpha: Int;
  private var currentBlendDstAlpha: Int;
  private var currentBlendColor: Color;
  private var currentBlendAlpha: Float;
  private var currentPremultipledAlpha: Bool;
  private var currentFlipSided: Bool;
  private var currentCullFace: Int;
  private var currentLineWidth: Float;
  private var currentPolygonOffsetFactor: Float;
  private var currentPolygonOffsetUnits: Float;
  private var maxTextures: Int;
  private var lineWidthAvailable: Bool;
  private var version: Float;
  private var currentTextureSlot: Int;
  private var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;
  private var scissorParam: Array<Int>;
  private var viewportParam: Array<Int>;
  private var currentScissor: Vector4;
  private var currentViewport: Vector4;
  private var emptyTextures: Map<Int, WebGLTexture>;

  public function new(gl: WebGLRenderingContext) {
    this.gl = gl;

    this.colorBuffer = new ColorBuffer();
    this.depthBuffer = new DepthBuffer();
    this.stencilBuffer = new StencilBuffer();

    this.uboBindings = new WeakMap();
    this.uboProgramMap = new WeakMap();

    this.enabledCapabilities = new Map();

    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];

    this.currentProgram = null;

    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;

    this.currentFlipSided = null;
    this.currentCullFace = null;

    this.currentLineWidth = null;

    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;

    this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

    this.lineWidthAvailable = false;
    this.version = 0;
    var glVersion = gl.getParameter(gl.VERSION);

    if (glVersion.indexOf("WebGL") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^WebGL (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 1.0;
    } else if (glVersion.indexOf("OpenGL ES") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^OpenGL ES (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 2.0;
    }

    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();

    this.scissorParam = gl.getParameter(gl.SCISSOR_BOX);
    this.viewportParam = gl.getParameter(gl.VIEWPORT);

    this.currentScissor = new Vector4().fromArray(this.scissorParam);
    this.currentViewport = new Vector4().fromArray(this.viewportParam);

    this.emptyTextures = new Map();
    this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
    this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
    this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
    this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

    this.colorBuffer.setClear(0, 0, 0, 1);
    this.depthBuffer.setClear(1);
    this.stencilBuffer.setClear(0);

    this.enable(gl.DEPTH_TEST);
    this.depthBuffer.setFunc(LessEqualDepth);

    this.setFlipSided(false);
    this.setCullFace(CullFaceBack);
    this.enable(gl.CULL_FACE);

    this.setBlending(NoBlending);
  }

  private function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {
    var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    var texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (var i = 0; i < count; i++) {
      if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }

  public function enable(id: Int): Void {
    if (!this.enabledCapabilities.exists(id) || !this.enabledCapabilities.get(id)) {
      gl.enable(id);
      this.enabledCapabilities.set(id, true);
    }
  }

  public function disable(id: Int): Void {
    if (this.enabledCapabilities.exists(id) && this.enabledCapabilities.get(id)) {
      gl.disable(id);
      this.enabledCapabilities.set(id, false);
    }
  }

  public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {
    if (this.currentBoundFramebuffers.get(target) != framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      this.currentBoundFramebuffers.set(target, framebuffer);
      if (target == gl.DRAW_FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);
      }
      if (target == gl.FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);
      }
      return true;
    }
    return false;
  }

  public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {
    var drawBuffers = this.defaultDrawbuffers;
    var needsUpdate = false;
    if (renderTarget != null) {
      drawBuffers = this.currentDrawbuffers.get(framebuffer);
      if (drawBuffers == null) {
        drawBuffers = [];
        this.currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      var textures = cast renderTarget.textures;
      if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
        for (var i = 0; i < textures.length; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] != gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }

  public function useProgram(program: WebGLProgram): Bool {
    if (this.currentProgram != program) {
      gl.useProgram(program);
      this.currentProgram = program;
      return true;
    }
    return false;
  }

  public function setBlending(
    blending: Int,
    blendEquation: Int = AddEquation,
    blendSrc: Int = SrcAlphaFactor,
    blendDst: Int = OneMinusSrcAlphaFactor,
    blendEquationAlpha: Int = null,
    blendSrcAlpha: Int = null,
    blendDstAlpha: Int = null,
    blendColor: Color = null,
    blendAlpha: Float = 0,
    premultipliedAlpha: Bool = false
  ): Void {
    if (blending == NoBlending) {
      if (this.currentBlendingEnabled) {
        this.disable(gl.BLEND);
        this.currentBlendingEnabled = false;
      }
      return;
    }
    if (!this.currentBlendingEnabled) {
      this.enable(gl.BLEND);
      this.currentBlendingEnabled = true;
    }
    if (blending != CustomBlending) {
      if (this.currentBlending != blending || this.currentPremultipledAlpha != premultipliedAlpha) {
        if (this.currentBlendEquation != AddEquation || this.currentBlendEquationAlpha != AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          this.currentBlendEquation = AddEquation;
          this.currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        }
        this.currentBlendSrc = null;
        this.currentBlendDst = null;
        this.currentBlendSrcAlpha = null;
        this.currentBlendDstAlpha = null;
        this.currentBlendColor.set(0, 0, 0);
        this.currentBlendAlpha = 0;
        this.currentBlending = blending;
        this.currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }
    blendEquationAlpha = blendEquationAlpha == null ? blendEquation : blendEquationAlpha;
    blendSrcAlpha = blendSrcAlpha == null ? blendSrc : blendSrcAlpha;
    blendDstAlpha = blendDstAlpha == null ? blendDst : blendDstAlpha;
    if (this.currentBlendEquation != blendEquation || this.currentBlendEquationAlpha != blendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      this.currentBlendEquation = blendEquation;
      this.currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (
      this.currentBlendSrc != blendSrc ||
      this.currentBlendDst != blendDst ||
      this.currentBlendSrcAlpha != blendSrcAlpha ||
      this.currentBlendDstAlpha != blendDstAlpha
    ) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      this.currentBlendSrc = blendSrc;
      this.currentBlendDst = blendDst;
      this.currentBlendSrcAlpha = blendSrcAlpha;
      this.currentBlendDstAlpha = blendDstAlpha;
    }
    if (this.currentBlendColor.equals(blendColor) == false || this.currentBlendAlpha != blendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      this.currentBlendColor.copy(blendColor);
      this.currentBlendAlpha = blendAlpha;
    }
    this.currentBlending = blending;
    this.currentPremultipledAlpha = false;
  }

  public function setMaterial(material: Dynamic, frontFaceCW: Bool = false): Void {
    if (material.side == DoubleSide) {
      this.disable(gl.CULL_FACE);
    } else {
      this.enable(gl.CULL_FACE);
    }
    var flipSided = material.side == BackSide;
    if (frontFaceCW) {
      flipSided = !flipSided;
    }
    this.setFlipSided(flipSided);
    if (material.blending == NormalBlending && material.transparent == false) {
      this.setBlending(NoBlending);
    } else {
      this.setBlending(
        material.blending,
        material.blendEquation,
        material.blendSrc,
        material.blendDst,
        material.blendEquationAlpha,
        material.blendSrcAlpha,
        material.blendDstAlpha,
        material.blendColor,
        material.blendAlpha,
        material.premultipliedAlpha
      );
    }
    this.depthBuffer.setFunc(material.depthFunc);
    this.depthBuffer.setTest(material.depthTest);
    this.depthBuffer.setMask(material.depthWrite);
    this.colorBuffer.setMask(material.colorWrite);
    var stencilWrite = material.stencilWrite;
    this.stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      this.stencilBuffer.setMask(material.stencilWriteMask);
      this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    if (material.alphaToCoverage) {
      this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    } else {
      this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    }
  }

  public function setFlipSided(flipSided: Bool): Void {
    if (this.currentFlipSided != flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      this.currentFlipSided = flipSided;
    }
  }

  public function setCullFace(cullFace: Int): Void {
    if (cullFace != CullFaceNone) {
      this.enable(gl.CULL_FACE);
      if (this.currentCullFace != cullFace) {
        if (cullFace == CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace == CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      this.disable(gl.CULL_FACE);
    }
    this.currentCullFace = cullFace;
  }

  public function setLineWidth(width: Float): Void {
    if (this.currentLineWidth != width) {
      if (this.lineWidthAvailable) {
        gl.lineWidth(width);
      }
      this.currentLineWidth = width;
    }
  }

  public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {
    if (polygonOffset) {
      this.enable(gl.POLYGON_OFFSET_FILL);
      if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {
        gl.polygonOffset(factor, units);
        this.currentPolygonOffsetFactor = factor;
        this.currentPolygonOffsetUnits = units;
      }
    } else {
      this.disable(gl.POLYGON_OFFSET_FILL);
    }
  }

  public function setScissorTest(scissorTest: Bool): Void {
    if (scissorTest) {
      this.enable(gl.SCISSOR_TEST);
    } else {
      this.disable(gl.SCISSOR_TEST);
    }
  }

  public function activeTexture(webglSlot: Int = null): Void {
    if (webglSlot == null) {
      webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
    }
    if (this.currentTextureSlot != webglSlot) {
      gl.activeTexture(webglSlot);
      this.currentTextureSlot = webglSlot;
    }
  }

  public function bindTexture(webglType: Int, webglTexture: WebGLTexture = null, webglSlot: Int = null): Void {
    if (webglSlot == null) {
      if (this.currentTextureSlot == null) {
        webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
      } else {
        webglSlot = this.currentTextureSlot;
      }
    }
    var boundTexture = this.currentBoundTextures.get(webglSlot);
    if (boundTexture == null) {
      boundTexture = {type: null, texture: null};
      this.currentBoundTextures.set(webglSlot, boundTexture);
    }
    if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
      if (this.currentTextureSlot != webglSlot) {
        gl.activeTexture(webglSlot);
        this.currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture == null ? this.emptyTextures[webglType] : webglTexture);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }

  public function unbindTexture(): Void {
    var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);
    if (boundTexture != null && boundTexture.type != null) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = null;
      boundTexture.texture = null;
    }
  }

  public function compressedTexImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage2D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int
  ): Void {
    try {
      gl.texStorage2D(target, levels, internalformat, width, height);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage3D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int
  ): Void {
    try {
      gl.texStorage3D(target, levels, internalformat, width, height, depth);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function scissor(scissor: Vector4): Void {
    if (this.currentScissor.equals(scissor) == false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      this.currentScissor.copy(scissor);
    }
  }

  public function viewport(viewport: Vector4): Void {
    if (this.currentViewport.equals(viewport) == false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      this.currentViewport.copy(viewport);
    }
  }

  public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    if (mapping == null) {
      mapping = new WeakMap();
      this.uboProgramMap.set(program, mapping);
    }
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (blockIndex == null) {
      blockIndex = gl.getUniformBlockIndex(program, cast uniformsGroup.name);
      mapping.set(cast uniformsGroup.name, blockIndex);
    }
  }

  public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (this.uboBindings.get(program) != blockIndex) {
      gl.uniformBlockBinding(program, blockIndex, cast uniformsGroup.__bindingPointIndex);
      this.uboBindings.set(program, blockIndex);
    }
  }

  public function reset(): Void {
    gl.disable(gl.BLEND);
    gl.disable(gl.CULL_FACE);
    gl.disable(gl.DEPTH_TEST);
    gl.disable(gl.POLYGON_OFFSET_FILL);
    gl.disable(gl.SCISSOR_TEST);
    gl.disable(gl.STENCIL_TEST);
    gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    gl.blendEquation(gl.FUNC_ADD);
    gl.blendFunc(gl.ONE, gl.ZERO);
    gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
    gl.blendColor(0, 0, 0, 0);
    gl.colorMask(true, true, true, true);
    gl.clearColor(0, 0, 0, 0);
    gl.depthMask(true);
    gl.depthFunc(gl.LESS);
    gl.clearDepth(1);
    gl.stencilMask(0xffffffff);
    gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
    gl.clearStencil(0);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CCW);
    gl.polygonOffset(0, 0);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
    gl.useProgram(null);
    gl.lineWidth(1);
    gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    this.enabledCapabilities = new Map();
    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();
    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];
    this.currentProgram = null;
    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;
    this.currentFlipSided = null;
    this.currentCullFace = null;
    this.currentLineWidth = null;
    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;
    this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.colorBuffer.reset();
    this.depthBuffer.reset();
    this.stencilBuffer.reset();
  }

  public var buffers: { color: ColorBuffer, depth: DepthBuffer, stencil: StencilBuffer };

  private static var equationToGL: Map<Int, Int> = new Map();
  private static var factorToGL: Map<Int, Int> = new Map();

  static function init() {
    equationToGL[AddEquation] = gl.FUNC_ADD;
    equationToGL[SubtractEquation] = gl.FUNC_SUBTRACT;
    equationToGL[ReverseSubtractEquation] = gl.FUNC_REVERSE_SUBTRACT;
    equationToGL[MinEquation] = gl.MIN;
    equationToGL[MaxEquation] = gl.MAX;
    factorToGL[ZeroFactor] = gl.ZERO;
    factorToGL[OneFactor] = gl.ONE;
    factorToGL[SrcColorFactor] = gl.SRC_COLOR;
    factorToGL[SrcAlphaFactor] = gl.SRC_ALPHA;
    factorToGL[SrcAlphaSaturateFactor] = gl.SRC_ALPHA_SATURATE;
    factorToGL[DstColorFactor] = gl.DST_COLOR;
    factorToGL[DstAlphaFactor] = gl.DST_ALPHA;
    factorToGL[OneMinusSrcColorFactor] = gl.ONE_MINUS_SRC_COLOR;
    factorToGL[OneMinusSrcAlphaFactor] = gl.ONE_MINUS_SRC_ALPHA;
    factorToGL[OneMinusDstColorFactor] = gl.ONE_MINUS_DST_COLOR;
    factorToGL[OneMinusDstAlphaFactor] = gl.ONE_MINUS_DST_ALPHA;
    factorToGL[ConstantColorFactor] = gl.CONSTANT_COLOR;
    factorToGL[OneMinusConstantColorFactor] = gl.ONE_MINUS_CONSTANT_COLOR;
    factorToGL[ConstantAlphaFactor] = gl.CONSTANT_ALPHA;
    factorToGL[OneMinusConstantAlphaFactor] = gl.ONE_MINUS_CONSTANT_ALPHA;
  }

  private class ColorBuffer {
    private var locked: Bool;
    private var color: Vector4;
    private var currentColorMask: Bool;
    private var currentColorClear: Vector4;

    public function new() {
      this.locked = false;
      this.color = new Vector4();
      this.currentColorMask = null;
      this.currentColorClear = new Vector4(0, 0, 0, 0);
    }

    public function setMask(colorMask: Bool): Void {
      if (this.currentColorMask != colorMask && !this.locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        this.currentColorMask = colorMask;
      }
    }

    public function setLocked(lock: Bool): Void {
      this.locked = lock;
    }

    public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {
      if (premultipliedAlpha) {
        r *= a;
        g *= a;
        b *= a;
      }
      this.color.set(r, g, b, a);
      if (this.currentColorClear.equals(this.color) == false) {
        gl.clearColor(r, g, b, a);
        this.currentColorClear.copy(this.color);
      }
    }

    public function reset(): Void {
      this.locked = false;
      this.currentColorMask = null;
      this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  }

  private class DepthBuffer {
    private var locked: Bool;
    private var currentDepthMask: Bool;
    private var currentDepthFunc: Int;
    private var currentDepthClear: Float;

    public function new() {
      this.locked = false;
      this.currentDepthMask = null
import haxe.ds.WeakMap;
import three.math.Color;
import three.math.Vector4;
import three.constants.*;

class WebGLState {
  private var gl: WebGLRenderingContext;
  private var colorBuffer: ColorBuffer;
  private var depthBuffer: DepthBuffer;
  private var stencilBuffer: StencilBuffer;
  private var uboBindings: WeakMap<WebGLProgram, Int>;
  private var uboProgramMap: WeakMap<WebGLProgram, WeakMap<String, Int>>;
  private var enabledCapabilities: Map<Int, Bool>;
  private var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
  private var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
  private var defaultDrawbuffers: Array<Int>;
  private var currentProgram: WebGLProgram;
  private var currentBlendingEnabled: Bool;
  private var currentBlending: Int;
  private var currentBlendEquation: Int;
  private var currentBlendSrc: Int;
  private var currentBlendDst: Int;
  private var currentBlendEquationAlpha: Int;
  private var currentBlendSrcAlpha: Int;
  private var currentBlendDstAlpha: Int;
  private var currentBlendColor: Color;
  private var currentBlendAlpha: Float;
  private var currentPremultipledAlpha: Bool;
  private var currentFlipSided: Bool;
  private var currentCullFace: Int;
  private var currentLineWidth: Float;
  private var currentPolygonOffsetFactor: Float;
  private var currentPolygonOffsetUnits: Float;
  private var maxTextures: Int;
  private var lineWidthAvailable: Bool;
  private var version: Float;
  private var currentTextureSlot: Int;
  private var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;
  private var scissorParam: Array<Int>;
  private var viewportParam: Array<Int>;
  private var currentScissor: Vector4;
  private var currentViewport: Vector4;
  private var emptyTextures: Map<Int, WebGLTexture>;

  public function new(gl: WebGLRenderingContext) {
    this.gl = gl;

    this.colorBuffer = new ColorBuffer();
    this.depthBuffer = new DepthBuffer();
    this.stencilBuffer = new StencilBuffer();

    this.uboBindings = new WeakMap();
    this.uboProgramMap = new WeakMap();

    this.enabledCapabilities = new Map();

    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];

    this.currentProgram = null;

    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;

    this.currentFlipSided = null;
    this.currentCullFace = null;

    this.currentLineWidth = null;

    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;

    this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

    this.lineWidthAvailable = false;
    this.version = 0;
    var glVersion = gl.getParameter(gl.VERSION);

    if (glVersion.indexOf("WebGL") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^WebGL (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 1.0;
    } else if (glVersion.indexOf("OpenGL ES") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^OpenGL ES (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 2.0;
    }

    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();

    this.scissorParam = gl.getParameter(gl.SCISSOR_BOX);
    this.viewportParam = gl.getParameter(gl.VIEWPORT);

    this.currentScissor = new Vector4().fromArray(this.scissorParam);
    this.currentViewport = new Vector4().fromArray(this.viewportParam);

    this.emptyTextures = new Map();
    this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
    this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
    this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
    this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

    this.colorBuffer.setClear(0, 0, 0, 1);
    this.depthBuffer.setClear(1);
    this.stencilBuffer.setClear(0);

    this.enable(gl.DEPTH_TEST);
    this.depthBuffer.setFunc(LessEqualDepth);

    this.setFlipSided(false);
    this.setCullFace(CullFaceBack);
    this.enable(gl.CULL_FACE);

    this.setBlending(NoBlending);
  }

  private function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {
    var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    var texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (var i = 0; i < count; i++) {
      if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }

  public function enable(id: Int): Void {
    if (!this.enabledCapabilities.exists(id) || !this.enabledCapabilities.get(id)) {
      gl.enable(id);
      this.enabledCapabilities.set(id, true);
    }
  }

  public function disable(id: Int): Void {
    if (this.enabledCapabilities.exists(id) && this.enabledCapabilities.get(id)) {
      gl.disable(id);
      this.enabledCapabilities.set(id, false);
    }
  }

  public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {
    if (this.currentBoundFramebuffers.get(target) != framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      this.currentBoundFramebuffers.set(target, framebuffer);
      if (target == gl.DRAW_FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);
      }
      if (target == gl.FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);
      }
      return true;
    }
    return false;
  }

  public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {
    var drawBuffers = this.defaultDrawbuffers;
    var needsUpdate = false;
    if (renderTarget != null) {
      drawBuffers = this.currentDrawbuffers.get(framebuffer);
      if (drawBuffers == null) {
        drawBuffers = [];
        this.currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      var textures = cast renderTarget.textures;
      if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
        for (var i = 0; i < textures.length; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] != gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }

  public function useProgram(program: WebGLProgram): Bool {
    if (this.currentProgram != program) {
      gl.useProgram(program);
      this.currentProgram = program;
      return true;
    }
    return false;
  }

  public function setBlending(
    blending: Int,
    blendEquation: Int = AddEquation,
    blendSrc: Int = SrcAlphaFactor,
    blendDst: Int = OneMinusSrcAlphaFactor,
    blendEquationAlpha: Int = null,
    blendSrcAlpha: Int = null,
    blendDstAlpha: Int = null,
    blendColor: Color = null,
    blendAlpha: Float = 0,
    premultipliedAlpha: Bool = false
  ): Void {
    if (blending == NoBlending) {
      if (this.currentBlendingEnabled) {
        this.disable(gl.BLEND);
        this.currentBlendingEnabled = false;
      }
      return;
    }
    if (!this.currentBlendingEnabled) {
      this.enable(gl.BLEND);
      this.currentBlendingEnabled = true;
    }
    if (blending != CustomBlending) {
      if (this.currentBlending != blending || this.currentPremultipledAlpha != premultipliedAlpha) {
        if (this.currentBlendEquation != AddEquation || this.currentBlendEquationAlpha != AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          this.currentBlendEquation = AddEquation;
          this.currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        }
        this.currentBlendSrc = null;
        this.currentBlendDst = null;
        this.currentBlendSrcAlpha = null;
        this.currentBlendDstAlpha = null;
        this.currentBlendColor.set(0, 0, 0);
        this.currentBlendAlpha = 0;
        this.currentBlending = blending;
        this.currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }
    blendEquationAlpha = blendEquationAlpha == null ? blendEquation : blendEquationAlpha;
    blendSrcAlpha = blendSrcAlpha == null ? blendSrc : blendSrcAlpha;
    blendDstAlpha = blendDstAlpha == null ? blendDst : blendDstAlpha;
    if (this.currentBlendEquation != blendEquation || this.currentBlendEquationAlpha != blendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      this.currentBlendEquation = blendEquation;
      this.currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (
      this.currentBlendSrc != blendSrc ||
      this.currentBlendDst != blendDst ||
      this.currentBlendSrcAlpha != blendSrcAlpha ||
      this.currentBlendDstAlpha != blendDstAlpha
    ) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      this.currentBlendSrc = blendSrc;
      this.currentBlendDst = blendDst;
      this.currentBlendSrcAlpha = blendSrcAlpha;
      this.currentBlendDstAlpha = blendDstAlpha;
    }
    if (this.currentBlendColor.equals(blendColor) == false || this.currentBlendAlpha != blendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      this.currentBlendColor.copy(blendColor);
      this.currentBlendAlpha = blendAlpha;
    }
    this.currentBlending = blending;
    this.currentPremultipledAlpha = false;
  }

  public function setMaterial(material: Dynamic, frontFaceCW: Bool = false): Void {
    if (material.side == DoubleSide) {
      this.disable(gl.CULL_FACE);
    } else {
      this.enable(gl.CULL_FACE);
    }
    var flipSided = material.side == BackSide;
    if (frontFaceCW) {
      flipSided = !flipSided;
    }
    this.setFlipSided(flipSided);
    if (material.blending == NormalBlending && material.transparent == false) {
      this.setBlending(NoBlending);
    } else {
      this.setBlending(
        material.blending,
        material.blendEquation,
        material.blendSrc,
        material.blendDst,
        material.blendEquationAlpha,
        material.blendSrcAlpha,
        material.blendDstAlpha,
        material.blendColor,
        material.blendAlpha,
        material.premultipliedAlpha
      );
    }
    this.depthBuffer.setFunc(material.depthFunc);
    this.depthBuffer.setTest(material.depthTest);
    this.depthBuffer.setMask(material.depthWrite);
    this.colorBuffer.setMask(material.colorWrite);
    var stencilWrite = material.stencilWrite;
    this.stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      this.stencilBuffer.setMask(material.stencilWriteMask);
      this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    if (material.alphaToCoverage) {
      this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    } else {
      this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    }
  }

  public function setFlipSided(flipSided: Bool): Void {
    if (this.currentFlipSided != flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      this.currentFlipSided = flipSided;
    }
  }

  public function setCullFace(cullFace: Int): Void {
    if (cullFace != CullFaceNone) {
      this.enable(gl.CULL_FACE);
      if (this.currentCullFace != cullFace) {
        if (cullFace == CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace == CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      this.disable(gl.CULL_FACE);
    }
    this.currentCullFace = cullFace;
  }

  public function setLineWidth(width: Float): Void {
    if (this.currentLineWidth != width) {
      if (this.lineWidthAvailable) {
        gl.lineWidth(width);
      }
      this.currentLineWidth = width;
    }
  }

  public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {
    if (polygonOffset) {
      this.enable(gl.POLYGON_OFFSET_FILL);
      if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {
        gl.polygonOffset(factor, units);
        this.currentPolygonOffsetFactor = factor;
        this.currentPolygonOffsetUnits = units;
      }
    } else {
      this.disable(gl.POLYGON_OFFSET_FILL);
    }
  }

  public function setScissorTest(scissorTest: Bool): Void {
    if (scissorTest) {
      this.enable(gl.SCISSOR_TEST);
    } else {
      this.disable(gl.SCISSOR_TEST);
    }
  }

  public function activeTexture(webglSlot: Int = null): Void {
    if (webglSlot == null) {
      webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
    }
    if (this.currentTextureSlot != webglSlot) {
      gl.activeTexture(webglSlot);
      this.currentTextureSlot = webglSlot;
    }
  }

  public function bindTexture(webglType: Int, webglTexture: WebGLTexture = null, webglSlot: Int = null): Void {
    if (webglSlot == null) {
      if (this.currentTextureSlot == null) {
        webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
      } else {
        webglSlot = this.currentTextureSlot;
      }
    }
    var boundTexture = this.currentBoundTextures.get(webglSlot);
    if (boundTexture == null) {
      boundTexture = {type: null, texture: null};
      this.currentBoundTextures.set(webglSlot, boundTexture);
    }
    if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
      if (this.currentTextureSlot != webglSlot) {
        gl.activeTexture(webglSlot);
        this.currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture == null ? this.emptyTextures[webglType] : webglTexture);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }

  public function unbindTexture(): Void {
    var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);
    if (boundTexture != null && boundTexture.type != null) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = null;
      boundTexture.texture = null;
    }
  }

  public function compressedTexImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage2D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int
  ): Void {
    try {
      gl.texStorage2D(target, levels, internalformat, width, height);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage3D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int
  ): Void {
    try {
      gl.texStorage3D(target, levels, internalformat, width, height, depth);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function scissor(scissor: Vector4): Void {
    if (this.currentScissor.equals(scissor) == false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      this.currentScissor.copy(scissor);
    }
  }

  public function viewport(viewport: Vector4): Void {
    if (this.currentViewport.equals(viewport) == false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      this.currentViewport.copy(viewport);
    }
  }

  public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    if (mapping == null) {
      mapping = new WeakMap();
      this.uboProgramMap.set(program, mapping);
    }
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (blockIndex == null) {
      blockIndex = gl.getUniformBlockIndex(program, cast uniformsGroup.name);
      mapping.set(cast uniformsGroup.name, blockIndex);
    }
  }

  public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (this.uboBindings.get(program) != blockIndex) {
      gl.uniformBlockBinding(program, blockIndex, cast uniformsGroup.__bindingPointIndex);
      this.uboBindings.set(program, blockIndex);
    }
  }

  public function reset(): Void {
    gl.disable(gl.BLEND);
    gl.disable(gl.CULL_FACE);
    gl.disable(gl.DEPTH_TEST);
    gl.disable(gl.POLYGON_OFFSET_FILL);
    gl.disable(gl.SCISSOR_TEST);
    gl.disable(gl.STENCIL_TEST);
    gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    gl.blendEquation(gl.FUNC_ADD);
    gl.blendFunc(gl.ONE, gl.ZERO);
    gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
    gl.blendColor(0, 0, 0, 0);
    gl.colorMask(true, true, true, true);
    gl.clearColor(0, 0, 0, 0);
    gl.depthMask(true);
    gl.depthFunc(gl.LESS);
    gl.clearDepth(1);
    gl.stencilMask(0xffffffff);
    gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
    gl.clearStencil(0);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CCW);
    gl.polygonOffset(0, 0);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
    gl.useProgram(null);
    gl.lineWidth(1);
    gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    this.enabledCapabilities = new Map();
    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();
    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];
    this.currentProgram = null;
    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;
    this.currentFlipSided = null;
    this.currentCullFace = null;
    this.currentLineWidth = null;
    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;
    this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.colorBuffer.reset();
    this.depthBuffer.reset();
    this.stencilBuffer.reset();
  }

  public var buffers: { color: ColorBuffer, depth: DepthBuffer, stencil: StencilBuffer };

  private static var equationToGL: Map<Int, Int> = new Map();
  private static var factorToGL: Map<Int, Int> = new Map();

  static function init() {
    equationToGL[AddEquation] = gl.FUNC_ADD;
    equationToGL[SubtractEquation] = gl.FUNC_SUBTRACT;
    equationToGL[ReverseSubtractEquation] = gl.FUNC_REVERSE_SUBTRACT;
    equationToGL[MinEquation] = gl.MIN;
    equationToGL[MaxEquation] = gl.MAX;
    factorToGL[ZeroFactor] = gl.ZERO;
    factorToGL[OneFactor] = gl.ONE;
    factorToGL[SrcColorFactor] = gl.SRC_COLOR;
    factorToGL[SrcAlphaFactor] = gl.SRC_ALPHA;
    factorToGL[SrcAlphaSaturateFactor] = gl.SRC_ALPHA_SATURATE;
    factorToGL[DstColorFactor] = gl.DST_COLOR;
    factorToGL[DstAlphaFactor] = gl.DST_ALPHA;
    factorToGL[OneMinusSrcColorFactor] = gl.ONE_MINUS_SRC_COLOR;
    factorToGL[OneMinusSrcAlphaFactor] = gl.ONE_MINUS_SRC_ALPHA;
    factorToGL[OneMinusDstColorFactor] = gl.ONE_MINUS_DST_COLOR;
    factorToGL[OneMinusDstAlphaFactor] = gl.ONE_MINUS_DST_ALPHA;
    factorToGL[ConstantColorFactor] = gl.CONSTANT_COLOR;
    factorToGL[OneMinusConstantColorFactor] = gl.ONE_MINUS_CONSTANT_COLOR;
    factorToGL[ConstantAlphaFactor] = gl.CONSTANT_ALPHA;
    factorToGL[OneMinusConstantAlphaFactor] = gl.ONE_MINUS_CONSTANT_ALPHA;
  }

  private class ColorBuffer {
    private var locked: Bool;
    private var color: Vector4;
    private var currentColorMask: Bool;
    private var currentColorClear: Vector4;

    public function new() {
      this.locked = false;
      this.color = new Vector4();
      this.currentColorMask = null;
      this.currentColorClear = new Vector4(0, 0, 0, 0);
    }

    public function setMask(colorMask: Bool): Void {
      if (this.currentColorMask != colorMask && !this.locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        this.currentColorMask = colorMask;
      }
    }

    public function setLocked(lock: Bool): Void {
      this.locked = lock;
    }

    public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {
      if (premultipliedAlpha) {
        r *= a;
        g *= a;
        b *= a;
      }
      this.color.set(r, g, b, a);
      if (this.currentColorClear.equals(this.color) == false) {
        gl.clearColor(r, g, b, a);
        this.currentColorClear.copy(this.color);
      }
    }

    public function reset(): Void {
      this.locked = false;
      this.currentColorMask = null;
      this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  }

  private class DepthBuffer {
    private var locked: Bool;
    private var currentDepthMask: Bool;
    private var currentDepthFunc: Int;
    private var currentDepthClear: Float;

    public function new() {
      this.locked = false;
      this.currentDepthMask = null
import haxe.ds.WeakMap;
import three.math.Color;
import three.math.Vector4;
import three.constants.*;

class WebGLState {
  private var gl: WebGLRenderingContext;
  private var colorBuffer: ColorBuffer;
  private var depthBuffer: DepthBuffer;
  private var stencilBuffer: StencilBuffer;
  private var uboBindings: WeakMap<WebGLProgram, Int>;
  private var uboProgramMap: WeakMap<WebGLProgram, WeakMap<String, Int>>;
  private var enabledCapabilities: Map<Int, Bool>;
  private var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
  private var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
  private var defaultDrawbuffers: Array<Int>;
  private var currentProgram: WebGLProgram;
  private var currentBlendingEnabled: Bool;
  private var currentBlending: Int;
  private var currentBlendEquation: Int;
  private var currentBlendSrc: Int;
  private var currentBlendDst: Int;
  private var currentBlendEquationAlpha: Int;
  private var currentBlendSrcAlpha: Int;
  private var currentBlendDstAlpha: Int;
  private var currentBlendColor: Color;
  private var currentBlendAlpha: Float;
  private var currentPremultipledAlpha: Bool;
  private var currentFlipSided: Bool;
  private var currentCullFace: Int;
  private var currentLineWidth: Float;
  private var currentPolygonOffsetFactor: Float;
  private var currentPolygonOffsetUnits: Float;
  private var maxTextures: Int;
  private var lineWidthAvailable: Bool;
  private var version: Float;
  private var currentTextureSlot: Int;
  private var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;
  private var scissorParam: Array<Int>;
  private var viewportParam: Array<Int>;
  private var currentScissor: Vector4;
  private var currentViewport: Vector4;
  private var emptyTextures: Map<Int, WebGLTexture>;

  public function new(gl: WebGLRenderingContext) {
    this.gl = gl;

    this.colorBuffer = new ColorBuffer();
    this.depthBuffer = new DepthBuffer();
    this.stencilBuffer = new StencilBuffer();

    this.uboBindings = new WeakMap();
    this.uboProgramMap = new WeakMap();

    this.enabledCapabilities = new Map();

    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];

    this.currentProgram = null;

    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;

    this.currentFlipSided = null;
    this.currentCullFace = null;

    this.currentLineWidth = null;

    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;

    this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

    this.lineWidthAvailable = false;
    this.version = 0;
    var glVersion = gl.getParameter(gl.VERSION);

    if (glVersion.indexOf("WebGL") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^WebGL (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 1.0;
    } else if (glVersion.indexOf("OpenGL ES") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^OpenGL ES (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 2.0;
    }

    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();

    this.scissorParam = gl.getParameter(gl.SCISSOR_BOX);
    this.viewportParam = gl.getParameter(gl.VIEWPORT);

    this.currentScissor = new Vector4().fromArray(this.scissorParam);
    this.currentViewport = new Vector4().fromArray(this.viewportParam);

    this.emptyTextures = new Map();
    this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
    this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
    this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
    this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

    this.colorBuffer.setClear(0, 0, 0, 1);
    this.depthBuffer.setClear(1);
    this.stencilBuffer.setClear(0);

    this.enable(gl.DEPTH_TEST);
    this.depthBuffer.setFunc(LessEqualDepth);

    this.setFlipSided(false);
    this.setCullFace(CullFaceBack);
    this.enable(gl.CULL_FACE);

    this.setBlending(NoBlending);
  }

  private function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {
    var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    var texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (var i = 0; i < count; i++) {
      if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }

  public function enable(id: Int): Void {
    if (!this.enabledCapabilities.exists(id) || !this.enabledCapabilities.get(id)) {
      gl.enable(id);
      this.enabledCapabilities.set(id, true);
    }
  }

  public function disable(id: Int): Void {
    if (this.enabledCapabilities.exists(id) && this.enabledCapabilities.get(id)) {
      gl.disable(id);
      this.enabledCapabilities.set(id, false);
    }
  }

  public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {
    if (this.currentBoundFramebuffers.get(target) != framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      this.currentBoundFramebuffers.set(target, framebuffer);
      if (target == gl.DRAW_FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);
      }
      if (target == gl.FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);
      }
      return true;
    }
    return false;
  }

  public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {
    var drawBuffers = this.defaultDrawbuffers;
    var needsUpdate = false;
    if (renderTarget != null) {
      drawBuffers = this.currentDrawbuffers.get(framebuffer);
      if (drawBuffers == null) {
        drawBuffers = [];
        this.currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      var textures = cast renderTarget.textures;
      if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
        for (var i = 0; i < textures.length; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] != gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }

  public function useProgram(program: WebGLProgram): Bool {
    if (this.currentProgram != program) {
      gl.useProgram(program);
      this.currentProgram = program;
      return true;
    }
    return false;
  }

  public function setBlending(
    blending: Int,
    blendEquation: Int = AddEquation,
    blendSrc: Int = SrcAlphaFactor,
    blendDst: Int = OneMinusSrcAlphaFactor,
    blendEquationAlpha: Int = null,
    blendSrcAlpha: Int = null,
    blendDstAlpha: Int = null,
    blendColor: Color = null,
    blendAlpha: Float = 0,
    premultipliedAlpha: Bool = false
  ): Void {
    if (blending == NoBlending) {
      if (this.currentBlendingEnabled) {
        this.disable(gl.BLEND);
        this.currentBlendingEnabled = false;
      }
      return;
    }
    if (!this.currentBlendingEnabled) {
      this.enable(gl.BLEND);
      this.currentBlendingEnabled = true;
    }
    if (blending != CustomBlending) {
      if (this.currentBlending != blending || this.currentPremultipledAlpha != premultipliedAlpha) {
        if (this.currentBlendEquation != AddEquation || this.currentBlendEquationAlpha != AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          this.currentBlendEquation = AddEquation;
          this.currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        }
        this.currentBlendSrc = null;
        this.currentBlendDst = null;
        this.currentBlendSrcAlpha = null;
        this.currentBlendDstAlpha = null;
        this.currentBlendColor.set(0, 0, 0);
        this.currentBlendAlpha = 0;
        this.currentBlending = blending;
        this.currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }
    blendEquationAlpha = blendEquationAlpha == null ? blendEquation : blendEquationAlpha;
    blendSrcAlpha = blendSrcAlpha == null ? blendSrc : blendSrcAlpha;
    blendDstAlpha = blendDstAlpha == null ? blendDst : blendDstAlpha;
    if (this.currentBlendEquation != blendEquation || this.currentBlendEquationAlpha != blendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      this.currentBlendEquation = blendEquation;
      this.currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (
      this.currentBlendSrc != blendSrc ||
      this.currentBlendDst != blendDst ||
      this.currentBlendSrcAlpha != blendSrcAlpha ||
      this.currentBlendDstAlpha != blendDstAlpha
    ) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      this.currentBlendSrc = blendSrc;
      this.currentBlendDst = blendDst;
      this.currentBlendSrcAlpha = blendSrcAlpha;
      this.currentBlendDstAlpha = blendDstAlpha;
    }
    if (this.currentBlendColor.equals(blendColor) == false || this.currentBlendAlpha != blendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      this.currentBlendColor.copy(blendColor);
      this.currentBlendAlpha = blendAlpha;
    }
    this.currentBlending = blending;
    this.currentPremultipledAlpha = false;
  }

  public function setMaterial(material: Dynamic, frontFaceCW: Bool = false): Void {
    if (material.side == DoubleSide) {
      this.disable(gl.CULL_FACE);
    } else {
      this.enable(gl.CULL_FACE);
    }
    var flipSided = material.side == BackSide;
    if (frontFaceCW) {
      flipSided = !flipSided;
    }
    this.setFlipSided(flipSided);
    if (material.blending == NormalBlending && material.transparent == false) {
      this.setBlending(NoBlending);
    } else {
      this.setBlending(
        material.blending,
        material.blendEquation,
        material.blendSrc,
        material.blendDst,
        material.blendEquationAlpha,
        material.blendSrcAlpha,
        material.blendDstAlpha,
        material.blendColor,
        material.blendAlpha,
        material.premultipliedAlpha
      );
    }
    this.depthBuffer.setFunc(material.depthFunc);
    this.depthBuffer.setTest(material.depthTest);
    this.depthBuffer.setMask(material.depthWrite);
    this.colorBuffer.setMask(material.colorWrite);
    var stencilWrite = material.stencilWrite;
    this.stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      this.stencilBuffer.setMask(material.stencilWriteMask);
      this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    if (material.alphaToCoverage) {
      this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    } else {
      this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    }
  }

  public function setFlipSided(flipSided: Bool): Void {
    if (this.currentFlipSided != flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      this.currentFlipSided = flipSided;
    }
  }

  public function setCullFace(cullFace: Int): Void {
    if (cullFace != CullFaceNone) {
      this.enable(gl.CULL_FACE);
      if (this.currentCullFace != cullFace) {
        if (cullFace == CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace == CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      this.disable(gl.CULL_FACE);
    }
    this.currentCullFace = cullFace;
  }

  public function setLineWidth(width: Float): Void {
    if (this.currentLineWidth != width) {
      if (this.lineWidthAvailable) {
        gl.lineWidth(width);
      }
      this.currentLineWidth = width;
    }
  }

  public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {
    if (polygonOffset) {
      this.enable(gl.POLYGON_OFFSET_FILL);
      if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {
        gl.polygonOffset(factor, units);
        this.currentPolygonOffsetFactor = factor;
        this.currentPolygonOffsetUnits = units;
      }
    } else {
      this.disable(gl.POLYGON_OFFSET_FILL);
    }
  }

  public function setScissorTest(scissorTest: Bool): Void {
    if (scissorTest) {
      this.enable(gl.SCISSOR_TEST);
    } else {
      this.disable(gl.SCISSOR_TEST);
    }
  }

  public function activeTexture(webglSlot: Int = null): Void {
    if (webglSlot == null) {
      webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
    }
    if (this.currentTextureSlot != webglSlot) {
      gl.activeTexture(webglSlot);
      this.currentTextureSlot = webglSlot;
    }
  }

  public function bindTexture(webglType: Int, webglTexture: WebGLTexture = null, webglSlot: Int = null): Void {
    if (webglSlot == null) {
      if (this.currentTextureSlot == null) {
        webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
      } else {
        webglSlot = this.currentTextureSlot;
      }
    }
    var boundTexture = this.currentBoundTextures.get(webglSlot);
    if (boundTexture == null) {
      boundTexture = {type: null, texture: null};
      this.currentBoundTextures.set(webglSlot, boundTexture);
    }
    if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
      if (this.currentTextureSlot != webglSlot) {
        gl.activeTexture(webglSlot);
        this.currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture == null ? this.emptyTextures[webglType] : webglTexture);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }

  public function unbindTexture(): Void {
    var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);
    if (boundTexture != null && boundTexture.type != null) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = null;
      boundTexture.texture = null;
    }
  }

  public function compressedTexImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage2D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int
  ): Void {
    try {
      gl.texStorage2D(target, levels, internalformat, width, height);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage3D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int
  ): Void {
    try {
      gl.texStorage3D(target, levels, internalformat, width, height, depth);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function scissor(scissor: Vector4): Void {
    if (this.currentScissor.equals(scissor) == false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      this.currentScissor.copy(scissor);
    }
  }

  public function viewport(viewport: Vector4): Void {
    if (this.currentViewport.equals(viewport) == false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      this.currentViewport.copy(viewport);
    }
  }

  public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    if (mapping == null) {
      mapping = new WeakMap();
      this.uboProgramMap.set(program, mapping);
    }
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (blockIndex == null) {
      blockIndex = gl.getUniformBlockIndex(program, cast uniformsGroup.name);
      mapping.set(cast uniformsGroup.name, blockIndex);
    }
  }

  public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (this.uboBindings.get(program) != blockIndex) {
      gl.uniformBlockBinding(program, blockIndex, cast uniformsGroup.__bindingPointIndex);
      this.uboBindings.set(program, blockIndex);
    }
  }

  public function reset(): Void {
    gl.disable(gl.BLEND);
    gl.disable(gl.CULL_FACE);
    gl.disable(gl.DEPTH_TEST);
    gl.disable(gl.POLYGON_OFFSET_FILL);
    gl.disable(gl.SCISSOR_TEST);
    gl.disable(gl.STENCIL_TEST);
    gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    gl.blendEquation(gl.FUNC_ADD);
    gl.blendFunc(gl.ONE, gl.ZERO);
    gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
    gl.blendColor(0, 0, 0, 0);
    gl.colorMask(true, true, true, true);
    gl.clearColor(0, 0, 0, 0);
    gl.depthMask(true);
    gl.depthFunc(gl.LESS);
    gl.clearDepth(1);
    gl.stencilMask(0xffffffff);
    gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
    gl.clearStencil(0);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CCW);
    gl.polygonOffset(0, 0);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
    gl.useProgram(null);
    gl.lineWidth(1);
    gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    this.enabledCapabilities = new Map();
    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();
    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];
    this.currentProgram = null;
    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;
    this.currentFlipSided = null;
    this.currentCullFace = null;
    this.currentLineWidth = null;
    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;
    this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.colorBuffer.reset();
    this.depthBuffer.reset();
    this.stencilBuffer.reset();
  }

  public var buffers: { color: ColorBuffer, depth: DepthBuffer, stencil: StencilBuffer };

  private static var equationToGL: Map<Int, Int> = new Map();
  private static var factorToGL: Map<Int, Int> = new Map();

  static function init() {
    equationToGL[AddEquation] = gl.FUNC_ADD;
    equationToGL[SubtractEquation] = gl.FUNC_SUBTRACT;
    equationToGL[ReverseSubtractEquation] = gl.FUNC_REVERSE_SUBTRACT;
    equationToGL[MinEquation] = gl.MIN;
    equationToGL[MaxEquation] = gl.MAX;
    factorToGL[ZeroFactor] = gl.ZERO;
    factorToGL[OneFactor] = gl.ONE;
    factorToGL[SrcColorFactor] = gl.SRC_COLOR;
    factorToGL[SrcAlphaFactor] = gl.SRC_ALPHA;
    factorToGL[SrcAlphaSaturateFactor] = gl.SRC_ALPHA_SATURATE;
    factorToGL[DstColorFactor] = gl.DST_COLOR;
    factorToGL[DstAlphaFactor] = gl.DST_ALPHA;
    factorToGL[OneMinusSrcColorFactor] = gl.ONE_MINUS_SRC_COLOR;
    factorToGL[OneMinusSrcAlphaFactor] = gl.ONE_MINUS_SRC_ALPHA;
    factorToGL[OneMinusDstColorFactor] = gl.ONE_MINUS_DST_COLOR;
    factorToGL[OneMinusDstAlphaFactor] = gl.ONE_MINUS_DST_ALPHA;
    factorToGL[ConstantColorFactor] = gl.CONSTANT_COLOR;
    factorToGL[OneMinusConstantColorFactor] = gl.ONE_MINUS_CONSTANT_COLOR;
    factorToGL[ConstantAlphaFactor] = gl.CONSTANT_ALPHA;
    factorToGL[OneMinusConstantAlphaFactor] = gl.ONE_MINUS_CONSTANT_ALPHA;
  }

  private class ColorBuffer {
    private var locked: Bool;
    private var color: Vector4;
    private var currentColorMask: Bool;
    private var currentColorClear: Vector4;

    public function new() {
      this.locked = false;
      this.color = new Vector4();
      this.currentColorMask = null;
      this.currentColorClear = new Vector4(0, 0, 0, 0);
    }

    public function setMask(colorMask: Bool): Void {
      if (this.currentColorMask != colorMask && !this.locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        this.currentColorMask = colorMask;
      }
    }

    public function setLocked(lock: Bool): Void {
      this.locked = lock;
    }

    public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {
      if (premultipliedAlpha) {
        r *= a;
        g *= a;
        b *= a;
      }
      this.color.set(r, g, b, a);
      if (this.currentColorClear.equals(this.color) == false) {
        gl.clearColor(r, g, b, a);
        this.currentColorClear.copy(this.color);
      }
    }

    public function reset(): Void {
      this.locked = false;
      this.currentColorMask = null;
      this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  }

  private class DepthBuffer {
    private var locked: Bool;
    private var currentDepthMask: Bool;
    private var currentDepthFunc: Int;
    private var currentDepthClear: Float;

    public function new() {
      this.locked = false;
      this.currentDepthMask = null
import haxe.ds.WeakMap;
import three.math.Color;
import three.math.Vector4;
import three.constants.*;

class WebGLState {
  private var gl: WebGLRenderingContext;
  private var colorBuffer: ColorBuffer;
  private var depthBuffer: DepthBuffer;
  private var stencilBuffer: StencilBuffer;
  private var uboBindings: WeakMap<WebGLProgram, Int>;
  private var uboProgramMap: WeakMap<WebGLProgram, WeakMap<String, Int>>;
  private var enabledCapabilities: Map<Int, Bool>;
  private var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
  private var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
  private var defaultDrawbuffers: Array<Int>;
  private var currentProgram: WebGLProgram;
  private var currentBlendingEnabled: Bool;
  private var currentBlending: Int;
  private var currentBlendEquation: Int;
  private var currentBlendSrc: Int;
  private var currentBlendDst: Int;
  private var currentBlendEquationAlpha: Int;
  private var currentBlendSrcAlpha: Int;
  private var currentBlendDstAlpha: Int;
  private var currentBlendColor: Color;
  private var currentBlendAlpha: Float;
  private var currentPremultipledAlpha: Bool;
  private var currentFlipSided: Bool;
  private var currentCullFace: Int;
  private var currentLineWidth: Float;
  private var currentPolygonOffsetFactor: Float;
  private var currentPolygonOffsetUnits: Float;
  private var maxTextures: Int;
  private var lineWidthAvailable: Bool;
  private var version: Float;
  private var currentTextureSlot: Int;
  private var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;
  private var scissorParam: Array<Int>;
  private var viewportParam: Array<Int>;
  private var currentScissor: Vector4;
  private var currentViewport: Vector4;
  private var emptyTextures: Map<Int, WebGLTexture>;

  public function new(gl: WebGLRenderingContext) {
    this.gl = gl;

    this.colorBuffer = new ColorBuffer();
    this.depthBuffer = new DepthBuffer();
    this.stencilBuffer = new StencilBuffer();

    this.uboBindings = new WeakMap();
    this.uboProgramMap = new WeakMap();

    this.enabledCapabilities = new Map();

    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];

    this.currentProgram = null;

    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;

    this.currentFlipSided = null;
    this.currentCullFace = null;

    this.currentLineWidth = null;

    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;

    this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

    this.lineWidthAvailable = false;
    this.version = 0;
    var glVersion = gl.getParameter(gl.VERSION);

    if (glVersion.indexOf("WebGL") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^WebGL (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 1.0;
    } else if (glVersion.indexOf("OpenGL ES") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^OpenGL ES (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 2.0;
    }

    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();

    this.scissorParam = gl.getParameter(gl.SCISSOR_BOX);
    this.viewportParam = gl.getParameter(gl.VIEWPORT);

    this.currentScissor = new Vector4().fromArray(this.scissorParam);
    this.currentViewport = new Vector4().fromArray(this.viewportParam);

    this.emptyTextures = new Map();
    this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
    this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
    this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
    this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

    this.colorBuffer.setClear(0, 0, 0, 1);
    this.depthBuffer.setClear(1);
    this.stencilBuffer.setClear(0);

    this.enable(gl.DEPTH_TEST);
    this.depthBuffer.setFunc(LessEqualDepth);

    this.setFlipSided(false);
    this.setCullFace(CullFaceBack);
    this.enable(gl.CULL_FACE);

    this.setBlending(NoBlending);
  }

  private function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {
    var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    var texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (var i = 0; i < count; i++) {
      if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }

  public function enable(id: Int): Void {
    if (!this.enabledCapabilities.exists(id) || !this.enabledCapabilities.get(id)) {
      gl.enable(id);
      this.enabledCapabilities.set(id, true);
    }
  }

  public function disable(id: Int): Void {
    if (this.enabledCapabilities.exists(id) && this.enabledCapabilities.get(id)) {
      gl.disable(id);
      this.enabledCapabilities.set(id, false);
    }
  }

  public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {
    if (this.currentBoundFramebuffers.get(target) != framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      this.currentBoundFramebuffers.set(target, framebuffer);
      if (target == gl.DRAW_FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);
      }
      if (target == gl.FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);
      }
      return true;
    }
    return false;
  }

  public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {
    var drawBuffers = this.defaultDrawbuffers;
    var needsUpdate = false;
    if (renderTarget != null) {
      drawBuffers = this.currentDrawbuffers.get(framebuffer);
      if (drawBuffers == null) {
        drawBuffers = [];
        this.currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      var textures = cast renderTarget.textures;
      if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
        for (var i = 0; i < textures.length; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] != gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }

  public function useProgram(program: WebGLProgram): Bool {
    if (this.currentProgram != program) {
      gl.useProgram(program);
      this.currentProgram = program;
      return true;
    }
    return false;
  }

  public function setBlending(
    blending: Int,
    blendEquation: Int = AddEquation,
    blendSrc: Int = SrcAlphaFactor,
    blendDst: Int = OneMinusSrcAlphaFactor,
    blendEquationAlpha: Int = null,
    blendSrcAlpha: Int = null,
    blendDstAlpha: Int = null,
    blendColor: Color = null,
    blendAlpha: Float = 0,
    premultipliedAlpha: Bool = false
  ): Void {
    if (blending == NoBlending) {
      if (this.currentBlendingEnabled) {
        this.disable(gl.BLEND);
        this.currentBlendingEnabled = false;
      }
      return;
    }
    if (!this.currentBlendingEnabled) {
      this.enable(gl.BLEND);
      this.currentBlendingEnabled = true;
    }
    if (blending != CustomBlending) {
      if (this.currentBlending != blending || this.currentPremultipledAlpha != premultipliedAlpha) {
        if (this.currentBlendEquation != AddEquation || this.currentBlendEquationAlpha != AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          this.currentBlendEquation = AddEquation;
          this.currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        }
        this.currentBlendSrc = null;
        this.currentBlendDst = null;
        this.currentBlendSrcAlpha = null;
        this.currentBlendDstAlpha = null;
        this.currentBlendColor.set(0, 0, 0);
        this.currentBlendAlpha = 0;
        this.currentBlending = blending;
        this.currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }
    blendEquationAlpha = blendEquationAlpha == null ? blendEquation : blendEquationAlpha;
    blendSrcAlpha = blendSrcAlpha == null ? blendSrc : blendSrcAlpha;
    blendDstAlpha = blendDstAlpha == null ? blendDst : blendDstAlpha;
    if (this.currentBlendEquation != blendEquation || this.currentBlendEquationAlpha != blendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      this.currentBlendEquation = blendEquation;
      this.currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (
      this.currentBlendSrc != blendSrc ||
      this.currentBlendDst != blendDst ||
      this.currentBlendSrcAlpha != blendSrcAlpha ||
      this.currentBlendDstAlpha != blendDstAlpha
    ) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      this.currentBlendSrc = blendSrc;
      this.currentBlendDst = blendDst;
      this.currentBlendSrcAlpha = blendSrcAlpha;
      this.currentBlendDstAlpha = blendDstAlpha;
    }
    if (this.currentBlendColor.equals(blendColor) == false || this.currentBlendAlpha != blendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      this.currentBlendColor.copy(blendColor);
      this.currentBlendAlpha = blendAlpha;
    }
    this.currentBlending = blending;
    this.currentPremultipledAlpha = false;
  }

  public function setMaterial(material: Dynamic, frontFaceCW: Bool = false): Void {
    if (material.side == DoubleSide) {
      this.disable(gl.CULL_FACE);
    } else {
      this.enable(gl.CULL_FACE);
    }
    var flipSided = material.side == BackSide;
    if (frontFaceCW) {
      flipSided = !flipSided;
    }
    this.setFlipSided(flipSided);
    if (material.blending == NormalBlending && material.transparent == false) {
      this.setBlending(NoBlending);
    } else {
      this.setBlending(
        material.blending,
        material.blendEquation,
        material.blendSrc,
        material.blendDst,
        material.blendEquationAlpha,
        material.blendSrcAlpha,
        material.blendDstAlpha,
        material.blendColor,
        material.blendAlpha,
        material.premultipliedAlpha
      );
    }
    this.depthBuffer.setFunc(material.depthFunc);
    this.depthBuffer.setTest(material.depthTest);
    this.depthBuffer.setMask(material.depthWrite);
    this.colorBuffer.setMask(material.colorWrite);
    var stencilWrite = material.stencilWrite;
    this.stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      this.stencilBuffer.setMask(material.stencilWriteMask);
      this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    if (material.alphaToCoverage) {
      this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    } else {
      this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    }
  }

  public function setFlipSided(flipSided: Bool): Void {
    if (this.currentFlipSided != flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      this.currentFlipSided = flipSided;
    }
  }

  public function setCullFace(cullFace: Int): Void {
    if (cullFace != CullFaceNone) {
      this.enable(gl.CULL_FACE);
      if (this.currentCullFace != cullFace) {
        if (cullFace == CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace == CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      this.disable(gl.CULL_FACE);
    }
    this.currentCullFace = cullFace;
  }

  public function setLineWidth(width: Float): Void {
    if (this.currentLineWidth != width) {
      if (this.lineWidthAvailable) {
        gl.lineWidth(width);
      }
      this.currentLineWidth = width;
    }
  }

  public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {
    if (polygonOffset) {
      this.enable(gl.POLYGON_OFFSET_FILL);
      if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {
        gl.polygonOffset(factor, units);
        this.currentPolygonOffsetFactor = factor;
        this.currentPolygonOffsetUnits = units;
      }
    } else {
      this.disable(gl.POLYGON_OFFSET_FILL);
    }
  }

  public function setScissorTest(scissorTest: Bool): Void {
    if (scissorTest) {
      this.enable(gl.SCISSOR_TEST);
    } else {
      this.disable(gl.SCISSOR_TEST);
    }
  }

  public function activeTexture(webglSlot: Int = null): Void {
    if (webglSlot == null) {
      webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
    }
    if (this.currentTextureSlot != webglSlot) {
      gl.activeTexture(webglSlot);
      this.currentTextureSlot = webglSlot;
    }
  }

  public function bindTexture(webglType: Int, webglTexture: WebGLTexture = null, webglSlot: Int = null): Void {
    if (webglSlot == null) {
      if (this.currentTextureSlot == null) {
        webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
      } else {
        webglSlot = this.currentTextureSlot;
      }
    }
    var boundTexture = this.currentBoundTextures.get(webglSlot);
    if (boundTexture == null) {
      boundTexture = {type: null, texture: null};
      this.currentBoundTextures.set(webglSlot, boundTexture);
    }
    if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
      if (this.currentTextureSlot != webglSlot) {
        gl.activeTexture(webglSlot);
        this.currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture == null ? this.emptyTextures[webglType] : webglTexture);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }

  public function unbindTexture(): Void {
    var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);
    if (boundTexture != null && boundTexture.type != null) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = null;
      boundTexture.texture = null;
    }
  }

  public function compressedTexImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage2D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int
  ): Void {
    try {
      gl.texStorage2D(target, levels, internalformat, width, height);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage3D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int
  ): Void {
    try {
      gl.texStorage3D(target, levels, internalformat, width, height, depth);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function scissor(scissor: Vector4): Void {
    if (this.currentScissor.equals(scissor) == false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      this.currentScissor.copy(scissor);
    }
  }

  public function viewport(viewport: Vector4): Void {
    if (this.currentViewport.equals(viewport) == false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      this.currentViewport.copy(viewport);
    }
  }

  public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    if (mapping == null) {
      mapping = new WeakMap();
      this.uboProgramMap.set(program, mapping);
    }
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (blockIndex == null) {
      blockIndex = gl.getUniformBlockIndex(program, cast uniformsGroup.name);
      mapping.set(cast uniformsGroup.name, blockIndex);
    }
  }

  public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (this.uboBindings.get(program) != blockIndex) {
      gl.uniformBlockBinding(program, blockIndex, cast uniformsGroup.__bindingPointIndex);
      this.uboBindings.set(program, blockIndex);
    }
  }

  public function reset(): Void {
    gl.disable(gl.BLEND);
    gl.disable(gl.CULL_FACE);
    gl.disable(gl.DEPTH_TEST);
    gl.disable(gl.POLYGON_OFFSET_FILL);
    gl.disable(gl.SCISSOR_TEST);
    gl.disable(gl.STENCIL_TEST);
    gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    gl.blendEquation(gl.FUNC_ADD);
    gl.blendFunc(gl.ONE, gl.ZERO);
    gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
    gl.blendColor(0, 0, 0, 0);
    gl.colorMask(true, true, true, true);
    gl.clearColor(0, 0, 0, 0);
    gl.depthMask(true);
    gl.depthFunc(gl.LESS);
    gl.clearDepth(1);
    gl.stencilMask(0xffffffff);
    gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
    gl.clearStencil(0);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CCW);
    gl.polygonOffset(0, 0);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
    gl.useProgram(null);
    gl.lineWidth(1);
    gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    this.enabledCapabilities = new Map();
    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();
    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];
    this.currentProgram = null;
    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;
    this.currentFlipSided = null;
    this.currentCullFace = null;
    this.currentLineWidth = null;
    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;
    this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.colorBuffer.reset();
    this.depthBuffer.reset();
    this.stencilBuffer.reset();
  }

  public var buffers: { color: ColorBuffer, depth: DepthBuffer, stencil: StencilBuffer };

  private static var equationToGL: Map<Int, Int> = new Map();
  private static var factorToGL: Map<Int, Int> = new Map();

  static function init() {
    equationToGL[AddEquation] = gl.FUNC_ADD;
    equationToGL[SubtractEquation] = gl.FUNC_SUBTRACT;
    equationToGL[ReverseSubtractEquation] = gl.FUNC_REVERSE_SUBTRACT;
    equationToGL[MinEquation] = gl.MIN;
    equationToGL[MaxEquation] = gl.MAX;
    factorToGL[ZeroFactor] = gl.ZERO;
    factorToGL[OneFactor] = gl.ONE;
    factorToGL[SrcColorFactor] = gl.SRC_COLOR;
    factorToGL[SrcAlphaFactor] = gl.SRC_ALPHA;
    factorToGL[SrcAlphaSaturateFactor] = gl.SRC_ALPHA_SATURATE;
    factorToGL[DstColorFactor] = gl.DST_COLOR;
    factorToGL[DstAlphaFactor] = gl.DST_ALPHA;
    factorToGL[OneMinusSrcColorFactor] = gl.ONE_MINUS_SRC_COLOR;
    factorToGL[OneMinusSrcAlphaFactor] = gl.ONE_MINUS_SRC_ALPHA;
    factorToGL[OneMinusDstColorFactor] = gl.ONE_MINUS_DST_COLOR;
    factorToGL[OneMinusDstAlphaFactor] = gl.ONE_MINUS_DST_ALPHA;
    factorToGL[ConstantColorFactor] = gl.CONSTANT_COLOR;
    factorToGL[OneMinusConstantColorFactor] = gl.ONE_MINUS_CONSTANT_COLOR;
    factorToGL[ConstantAlphaFactor] = gl.CONSTANT_ALPHA;
    factorToGL[OneMinusConstantAlphaFactor] = gl.ONE_MINUS_CONSTANT_ALPHA;
  }

  private class ColorBuffer {
    private var locked: Bool;
    private var color: Vector4;
    private var currentColorMask: Bool;
    private var currentColorClear: Vector4;

    public function new() {
      this.locked = false;
      this.color = new Vector4();
      this.currentColorMask = null;
      this.currentColorClear = new Vector4(0, 0, 0, 0);
    }

    public function setMask(colorMask: Bool): Void {
      if (this.currentColorMask != colorMask && !this.locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        this.currentColorMask = colorMask;
      }
    }

    public function setLocked(lock: Bool): Void {
      this.locked = lock;
    }

    public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {
      if (premultipliedAlpha) {
        r *= a;
        g *= a;
        b *= a;
      }
      this.color.set(r, g, b, a);
      if (this.currentColorClear.equals(this.color) == false) {
        gl.clearColor(r, g, b, a);
        this.currentColorClear.copy(this.color);
      }
    }

    public function reset(): Void {
      this.locked = false;
      this.currentColorMask = null;
      this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  }

  private class DepthBuffer {
    private var locked: Bool;
    private var currentDepthMask: Bool;
    private var currentDepthFunc: Int;
    private var currentDepthClear: Float;

    public function new() {
      this.locked = false;
      this.currentDepthMask = null
import haxe.ds.WeakMap;
import three.math.Color;
import three.math.Vector4;
import three.constants.*;

class WebGLState {
  private var gl: WebGLRenderingContext;
  private var colorBuffer: ColorBuffer;
  private var depthBuffer: DepthBuffer;
  private var stencilBuffer: StencilBuffer;
  private var uboBindings: WeakMap<WebGLProgram, Int>;
  private var uboProgramMap: WeakMap<WebGLProgram, WeakMap<String, Int>>;
  private var enabledCapabilities: Map<Int, Bool>;
  private var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
  private var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
  private var defaultDrawbuffers: Array<Int>;
  private var currentProgram: WebGLProgram;
  private var currentBlendingEnabled: Bool;
  private var currentBlending: Int;
  private var currentBlendEquation: Int;
  private var currentBlendSrc: Int;
  private var currentBlendDst: Int;
  private var currentBlendEquationAlpha: Int;
  private var currentBlendSrcAlpha: Int;
  private var currentBlendDstAlpha: Int;
  private var currentBlendColor: Color;
  private var currentBlendAlpha: Float;
  private var currentPremultipledAlpha: Bool;
  private var currentFlipSided: Bool;
  private var currentCullFace: Int;
  private var currentLineWidth: Float;
  private var currentPolygonOffsetFactor: Float;
  private var currentPolygonOffsetUnits: Float;
  private var maxTextures: Int;
  private var lineWidthAvailable: Bool;
  private var version: Float;
  private var currentTextureSlot: Int;
  private var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;
  private var scissorParam: Array<Int>;
  private var viewportParam: Array<Int>;
  private var currentScissor: Vector4;
  private var currentViewport: Vector4;
  private var emptyTextures: Map<Int, WebGLTexture>;

  public function new(gl: WebGLRenderingContext) {
    this.gl = gl;

    this.colorBuffer = new ColorBuffer();
    this.depthBuffer = new DepthBuffer();
    this.stencilBuffer = new StencilBuffer();

    this.uboBindings = new WeakMap();
    this.uboProgramMap = new WeakMap();

    this.enabledCapabilities = new Map();

    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];

    this.currentProgram = null;

    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;

    this.currentFlipSided = null;
    this.currentCullFace = null;

    this.currentLineWidth = null;

    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;

    this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

    this.lineWidthAvailable = false;
    this.version = 0;
    var glVersion = gl.getParameter(gl.VERSION);

    if (glVersion.indexOf("WebGL") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^WebGL (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 1.0;
    } else if (glVersion.indexOf("OpenGL ES") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^OpenGL ES (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 2.0;
    }

    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();

    this.scissorParam = gl.getParameter(gl.SCISSOR_BOX);
    this.viewportParam = gl.getParameter(gl.VIEWPORT);

    this.currentScissor = new Vector4().fromArray(this.scissorParam);
    this.currentViewport = new Vector4().fromArray(this.viewportParam);

    this.emptyTextures = new Map();
    this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
    this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
    this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
    this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

    this.colorBuffer.setClear(0, 0, 0, 1);
    this.depthBuffer.setClear(1);
    this.stencilBuffer.setClear(0);

    this.enable(gl.DEPTH_TEST);
    this.depthBuffer.setFunc(LessEqualDepth);

    this.setFlipSided(false);
    this.setCullFace(CullFaceBack);
    this.enable(gl.CULL_FACE);

    this.setBlending(NoBlending);
  }

  private function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {
    var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    var texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (var i = 0; i < count; i++) {
      if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }

  public function enable(id: Int): Void {
    if (!this.enabledCapabilities.exists(id) || !this.enabledCapabilities.get(id)) {
      gl.enable(id);
      this.enabledCapabilities.set(id, true);
    }
  }

  public function disable(id: Int): Void {
    if (this.enabledCapabilities.exists(id) && this.enabledCapabilities.get(id)) {
      gl.disable(id);
      this.enabledCapabilities.set(id, false);
    }
  }

  public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {
    if (this.currentBoundFramebuffers.get(target) != framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      this.currentBoundFramebuffers.set(target, framebuffer);
      if (target == gl.DRAW_FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);
      }
      if (target == gl.FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);
      }
      return true;
    }
    return false;
  }

  public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {
    var drawBuffers = this.defaultDrawbuffers;
    var needsUpdate = false;
    if (renderTarget != null) {
      drawBuffers = this.currentDrawbuffers.get(framebuffer);
      if (drawBuffers == null) {
        drawBuffers = [];
        this.currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      var textures = cast renderTarget.textures;
      if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
        for (var i = 0; i < textures.length; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] != gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }

  public function useProgram(program: WebGLProgram): Bool {
    if (this.currentProgram != program) {
      gl.useProgram(program);
      this.currentProgram = program;
      return true;
    }
    return false;
  }

  public function setBlending(
    blending: Int,
    blendEquation: Int = AddEquation,
    blendSrc: Int = SrcAlphaFactor,
    blendDst: Int = OneMinusSrcAlphaFactor,
    blendEquationAlpha: Int = null,
    blendSrcAlpha: Int = null,
    blendDstAlpha: Int = null,
    blendColor: Color = null,
    blendAlpha: Float = 0,
    premultipliedAlpha: Bool = false
  ): Void {
    if (blending == NoBlending) {
      if (this.currentBlendingEnabled) {
        this.disable(gl.BLEND);
        this.currentBlendingEnabled = false;
      }
      return;
    }
    if (!this.currentBlendingEnabled) {
      this.enable(gl.BLEND);
      this.currentBlendingEnabled = true;
    }
    if (blending != CustomBlending) {
      if (this.currentBlending != blending || this.currentPremultipledAlpha != premultipliedAlpha) {
        if (this.currentBlendEquation != AddEquation || this.currentBlendEquationAlpha != AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          this.currentBlendEquation = AddEquation;
          this.currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        }
        this.currentBlendSrc = null;
        this.currentBlendDst = null;
        this.currentBlendSrcAlpha = null;
        this.currentBlendDstAlpha = null;
        this.currentBlendColor.set(0, 0, 0);
        this.currentBlendAlpha = 0;
        this.currentBlending = blending;
        this.currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }
    blendEquationAlpha = blendEquationAlpha == null ? blendEquation : blendEquationAlpha;
    blendSrcAlpha = blendSrcAlpha == null ? blendSrc : blendSrcAlpha;
    blendDstAlpha = blendDstAlpha == null ? blendDst : blendDstAlpha;
    if (this.currentBlendEquation != blendEquation || this.currentBlendEquationAlpha != blendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      this.currentBlendEquation = blendEquation;
      this.currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (
      this.currentBlendSrc != blendSrc ||
      this.currentBlendDst != blendDst ||
      this.currentBlendSrcAlpha != blendSrcAlpha ||
      this.currentBlendDstAlpha != blendDstAlpha
    ) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      this.currentBlendSrc = blendSrc;
      this.currentBlendDst = blendDst;
      this.currentBlendSrcAlpha = blendSrcAlpha;
      this.currentBlendDstAlpha = blendDstAlpha;
    }
    if (this.currentBlendColor.equals(blendColor) == false || this.currentBlendAlpha != blendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      this.currentBlendColor.copy(blendColor);
      this.currentBlendAlpha = blendAlpha;
    }
    this.currentBlending = blending;
    this.currentPremultipledAlpha = false;
  }

  public function setMaterial(material: Dynamic, frontFaceCW: Bool = false): Void {
    if (material.side == DoubleSide) {
      this.disable(gl.CULL_FACE);
    } else {
      this.enable(gl.CULL_FACE);
    }
    var flipSided = material.side == BackSide;
    if (frontFaceCW) {
      flipSided = !flipSided;
    }
    this.setFlipSided(flipSided);
    if (material.blending == NormalBlending && material.transparent == false) {
      this.setBlending(NoBlending);
    } else {
      this.setBlending(
        material.blending,
        material.blendEquation,
        material.blendSrc,
        material.blendDst,
        material.blendEquationAlpha,
        material.blendSrcAlpha,
        material.blendDstAlpha,
        material.blendColor,
        material.blendAlpha,
        material.premultipliedAlpha
      );
    }
    this.depthBuffer.setFunc(material.depthFunc);
    this.depthBuffer.setTest(material.depthTest);
    this.depthBuffer.setMask(material.depthWrite);
    this.colorBuffer.setMask(material.colorWrite);
    var stencilWrite = material.stencilWrite;
    this.stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      this.stencilBuffer.setMask(material.stencilWriteMask);
      this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    if (material.alphaToCoverage) {
      this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    } else {
      this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    }
  }

  public function setFlipSided(flipSided: Bool): Void {
    if (this.currentFlipSided != flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      this.currentFlipSided = flipSided;
    }
  }

  public function setCullFace(cullFace: Int): Void {
    if (cullFace != CullFaceNone) {
      this.enable(gl.CULL_FACE);
      if (this.currentCullFace != cullFace) {
        if (cullFace == CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace == CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      this.disable(gl.CULL_FACE);
    }
    this.currentCullFace = cullFace;
  }

  public function setLineWidth(width: Float): Void {
    if (this.currentLineWidth != width) {
      if (this.lineWidthAvailable) {
        gl.lineWidth(width);
      }
      this.currentLineWidth = width;
    }
  }

  public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {
    if (polygonOffset) {
      this.enable(gl.POLYGON_OFFSET_FILL);
      if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {
        gl.polygonOffset(factor, units);
        this.currentPolygonOffsetFactor = factor;
        this.currentPolygonOffsetUnits = units;
      }
    } else {
      this.disable(gl.POLYGON_OFFSET_FILL);
    }
  }

  public function setScissorTest(scissorTest: Bool): Void {
    if (scissorTest) {
      this.enable(gl.SCISSOR_TEST);
    } else {
      this.disable(gl.SCISSOR_TEST);
    }
  }

  public function activeTexture(webglSlot: Int = null): Void {
    if (webglSlot == null) {
      webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
    }
    if (this.currentTextureSlot != webglSlot) {
      gl.activeTexture(webglSlot);
      this.currentTextureSlot = webglSlot;
    }
  }

  public function bindTexture(webglType: Int, webglTexture: WebGLTexture = null, webglSlot: Int = null): Void {
    if (webglSlot == null) {
      if (this.currentTextureSlot == null) {
        webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
      } else {
        webglSlot = this.currentTextureSlot;
      }
    }
    var boundTexture = this.currentBoundTextures.get(webglSlot);
    if (boundTexture == null) {
      boundTexture = {type: null, texture: null};
      this.currentBoundTextures.set(webglSlot, boundTexture);
    }
    if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
      if (this.currentTextureSlot != webglSlot) {
        gl.activeTexture(webglSlot);
        this.currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture == null ? this.emptyTextures[webglType] : webglTexture);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }

  public function unbindTexture(): Void {
    var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);
    if (boundTexture != null && boundTexture.type != null) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = null;
      boundTexture.texture = null;
    }
  }

  public function compressedTexImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage2D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int
  ): Void {
    try {
      gl.texStorage2D(target, levels, internalformat, width, height);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage3D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int
  ): Void {
    try {
      gl.texStorage3D(target, levels, internalformat, width, height, depth);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function scissor(scissor: Vector4): Void {
    if (this.currentScissor.equals(scissor) == false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      this.currentScissor.copy(scissor);
    }
  }

  public function viewport(viewport: Vector4): Void {
    if (this.currentViewport.equals(viewport) == false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      this.currentViewport.copy(viewport);
    }
  }

  public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    if (mapping == null) {
      mapping = new WeakMap();
      this.uboProgramMap.set(program, mapping);
    }
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (blockIndex == null) {
      blockIndex = gl.getUniformBlockIndex(program, cast uniformsGroup.name);
      mapping.set(cast uniformsGroup.name, blockIndex);
    }
  }

  public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (this.uboBindings.get(program) != blockIndex) {
      gl.uniformBlockBinding(program, blockIndex, cast uniformsGroup.__bindingPointIndex);
      this.uboBindings.set(program, blockIndex);
    }
  }

  public function reset(): Void {
    gl.disable(gl.BLEND);
    gl.disable(gl.CULL_FACE);
    gl.disable(gl.DEPTH_TEST);
    gl.disable(gl.POLYGON_OFFSET_FILL);
    gl.disable(gl.SCISSOR_TEST);
    gl.disable(gl.STENCIL_TEST);
    gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    gl.blendEquation(gl.FUNC_ADD);
    gl.blendFunc(gl.ONE, gl.ZERO);
    gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
    gl.blendColor(0, 0, 0, 0);
    gl.colorMask(true, true, true, true);
    gl.clearColor(0, 0, 0, 0);
    gl.depthMask(true);
    gl.depthFunc(gl.LESS);
    gl.clearDepth(1);
    gl.stencilMask(0xffffffff);
    gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
    gl.clearStencil(0);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CCW);
    gl.polygonOffset(0, 0);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
    gl.useProgram(null);
    gl.lineWidth(1);
    gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    this.enabledCapabilities = new Map();
    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();
    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];
    this.currentProgram = null;
    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;
    this.currentFlipSided = null;
    this.currentCullFace = null;
    this.currentLineWidth = null;
    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;
    this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.colorBuffer.reset();
    this.depthBuffer.reset();
    this.stencilBuffer.reset();
  }

  public var buffers: { color: ColorBuffer, depth: DepthBuffer, stencil: StencilBuffer };

  private static var equationToGL: Map<Int, Int> = new Map();
  private static var factorToGL: Map<Int, Int> = new Map();

  static function init() {
    equationToGL[AddEquation] = gl.FUNC_ADD;
    equationToGL[SubtractEquation] = gl.FUNC_SUBTRACT;
    equationToGL[ReverseSubtractEquation] = gl.FUNC_REVERSE_SUBTRACT;
    equationToGL[MinEquation] = gl.MIN;
    equationToGL[MaxEquation] = gl.MAX;
    factorToGL[ZeroFactor] = gl.ZERO;
    factorToGL[OneFactor] = gl.ONE;
    factorToGL[SrcColorFactor] = gl.SRC_COLOR;
    factorToGL[SrcAlphaFactor] = gl.SRC_ALPHA;
    factorToGL[SrcAlphaSaturateFactor] = gl.SRC_ALPHA_SATURATE;
    factorToGL[DstColorFactor] = gl.DST_COLOR;
    factorToGL[DstAlphaFactor] = gl.DST_ALPHA;
    factorToGL[OneMinusSrcColorFactor] = gl.ONE_MINUS_SRC_COLOR;
    factorToGL[OneMinusSrcAlphaFactor] = gl.ONE_MINUS_SRC_ALPHA;
    factorToGL[OneMinusDstColorFactor] = gl.ONE_MINUS_DST_COLOR;
    factorToGL[OneMinusDstAlphaFactor] = gl.ONE_MINUS_DST_ALPHA;
    factorToGL[ConstantColorFactor] = gl.CONSTANT_COLOR;
    factorToGL[OneMinusConstantColorFactor] = gl.ONE_MINUS_CONSTANT_COLOR;
    factorToGL[ConstantAlphaFactor] = gl.CONSTANT_ALPHA;
    factorToGL[OneMinusConstantAlphaFactor] = gl.ONE_MINUS_CONSTANT_ALPHA;
  }

  private class ColorBuffer {
    private var locked: Bool;
    private var color: Vector4;
    private var currentColorMask: Bool;
    private var currentColorClear: Vector4;

    public function new() {
      this.locked = false;
      this.color = new Vector4();
      this.currentColorMask = null;
      this.currentColorClear = new Vector4(0, 0, 0, 0);
    }

    public function setMask(colorMask: Bool): Void {
      if (this.currentColorMask != colorMask && !this.locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        this.currentColorMask = colorMask;
      }
    }

    public function setLocked(lock: Bool): Void {
      this.locked = lock;
    }

    public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {
      if (premultipliedAlpha) {
        r *= a;
        g *= a;
        b *= a;
      }
      this.color.set(r, g, b, a);
      if (this.currentColorClear.equals(this.color) == false) {
        gl.clearColor(r, g, b, a);
        this.currentColorClear.copy(this.color);
      }
    }

    public function reset(): Void {
      this.locked = false;
      this.currentColorMask = null;
      this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  }

  private class DepthBuffer {
    private var locked: Bool;
    private var currentDepthMask: Bool;
    private var currentDepthFunc: Int;
    private var currentDepthClear: Float;

    public function new() {
      this.locked = false;
      this.currentDepthMask = null
import haxe.ds.WeakMap;
import three.math.Color;
import three.math.Vector4;
import three.constants.*;

class WebGLState {
  private var gl: WebGLRenderingContext;
  private var colorBuffer: ColorBuffer;
  private var depthBuffer: DepthBuffer;
  private var stencilBuffer: StencilBuffer;
  private var uboBindings: WeakMap<WebGLProgram, Int>;
  private var uboProgramMap: WeakMap<WebGLProgram, WeakMap<String, Int>>;
  private var enabledCapabilities: Map<Int, Bool>;
  private var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
  private var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
  private var defaultDrawbuffers: Array<Int>;
  private var currentProgram: WebGLProgram;
  private var currentBlendingEnabled: Bool;
  private var currentBlending: Int;
  private var currentBlendEquation: Int;
  private var currentBlendSrc: Int;
  private var currentBlendDst: Int;
  private var currentBlendEquationAlpha: Int;
  private var currentBlendSrcAlpha: Int;
  private var currentBlendDstAlpha: Int;
  private var currentBlendColor: Color;
  private var currentBlendAlpha: Float;
  private var currentPremultipledAlpha: Bool;
  private var currentFlipSided: Bool;
  private var currentCullFace: Int;
  private var currentLineWidth: Float;
  private var currentPolygonOffsetFactor: Float;
  private var currentPolygonOffsetUnits: Float;
  private var maxTextures: Int;
  private var lineWidthAvailable: Bool;
  private var version: Float;
  private var currentTextureSlot: Int;
  private var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;
  private var scissorParam: Array<Int>;
  private var viewportParam: Array<Int>;
  private var currentScissor: Vector4;
  private var currentViewport: Vector4;
  private var emptyTextures: Map<Int, WebGLTexture>;

  public function new(gl: WebGLRenderingContext) {
    this.gl = gl;

    this.colorBuffer = new ColorBuffer();
    this.depthBuffer = new DepthBuffer();
    this.stencilBuffer = new StencilBuffer();

    this.uboBindings = new WeakMap();
    this.uboProgramMap = new WeakMap();

    this.enabledCapabilities = new Map();

    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];

    this.currentProgram = null;

    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;

    this.currentFlipSided = null;
    this.currentCullFace = null;

    this.currentLineWidth = null;

    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;

    this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

    this.lineWidthAvailable = false;
    this.version = 0;
    var glVersion = gl.getParameter(gl.VERSION);

    if (glVersion.indexOf("WebGL") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^WebGL (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 1.0;
    } else if (glVersion.indexOf("OpenGL ES") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^OpenGL ES (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 2.0;
    }

    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();

    this.scissorParam = gl.getParameter(gl.SCISSOR_BOX);
    this.viewportParam = gl.getParameter(gl.VIEWPORT);

    this.currentScissor = new Vector4().fromArray(this.scissorParam);
    this.currentViewport = new Vector4().fromArray(this.viewportParam);

    this.emptyTextures = new Map();
    this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
    this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
    this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
    this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

    this.colorBuffer.setClear(0, 0, 0, 1);
    this.depthBuffer.setClear(1);
    this.stencilBuffer.setClear(0);

    this.enable(gl.DEPTH_TEST);
    this.depthBuffer.setFunc(LessEqualDepth);

    this.setFlipSided(false);
    this.setCullFace(CullFaceBack);
    this.enable(gl.CULL_FACE);

    this.setBlending(NoBlending);
  }

  private function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {
    var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    var texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (var i = 0; i < count; i++) {
      if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }

  public function enable(id: Int): Void {
    if (!this.enabledCapabilities.exists(id) || !this.enabledCapabilities.get(id)) {
      gl.enable(id);
      this.enabledCapabilities.set(id, true);
    }
  }

  public function disable(id: Int): Void {
    if (this.enabledCapabilities.exists(id) && this.enabledCapabilities.get(id)) {
      gl.disable(id);
      this.enabledCapabilities.set(id, false);
    }
  }

  public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {
    if (this.currentBoundFramebuffers.get(target) != framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      this.currentBoundFramebuffers.set(target, framebuffer);
      if (target == gl.DRAW_FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);
      }
      if (target == gl.FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);
      }
      return true;
    }
    return false;
  }

  public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {
    var drawBuffers = this.defaultDrawbuffers;
    var needsUpdate = false;
    if (renderTarget != null) {
      drawBuffers = this.currentDrawbuffers.get(framebuffer);
      if (drawBuffers == null) {
        drawBuffers = [];
        this.currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      var textures = cast renderTarget.textures;
      if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
        for (var i = 0; i < textures.length; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] != gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }

  public function useProgram(program: WebGLProgram): Bool {
    if (this.currentProgram != program) {
      gl.useProgram(program);
      this.currentProgram = program;
      return true;
    }
    return false;
  }

  public function setBlending(
    blending: Int,
    blendEquation: Int = AddEquation,
    blendSrc: Int = SrcAlphaFactor,
    blendDst: Int = OneMinusSrcAlphaFactor,
    blendEquationAlpha: Int = null,
    blendSrcAlpha: Int = null,
    blendDstAlpha: Int = null,
    blendColor: Color = null,
    blendAlpha: Float = 0,
    premultipliedAlpha: Bool = false
  ): Void {
    if (blending == NoBlending) {
      if (this.currentBlendingEnabled) {
        this.disable(gl.BLEND);
        this.currentBlendingEnabled = false;
      }
      return;
    }
    if (!this.currentBlendingEnabled) {
      this.enable(gl.BLEND);
      this.currentBlendingEnabled = true;
    }
    if (blending != CustomBlending) {
      if (this.currentBlending != blending || this.currentPremultipledAlpha != premultipliedAlpha) {
        if (this.currentBlendEquation != AddEquation || this.currentBlendEquationAlpha != AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          this.currentBlendEquation = AddEquation;
          this.currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        }
        this.currentBlendSrc = null;
        this.currentBlendDst = null;
        this.currentBlendSrcAlpha = null;
        this.currentBlendDstAlpha = null;
        this.currentBlendColor.set(0, 0, 0);
        this.currentBlendAlpha = 0;
        this.currentBlending = blending;
        this.currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }
    blendEquationAlpha = blendEquationAlpha == null ? blendEquation : blendEquationAlpha;
    blendSrcAlpha = blendSrcAlpha == null ? blendSrc : blendSrcAlpha;
    blendDstAlpha = blendDstAlpha == null ? blendDst : blendDstAlpha;
    if (this.currentBlendEquation != blendEquation || this.currentBlendEquationAlpha != blendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      this.currentBlendEquation = blendEquation;
      this.currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (
      this.currentBlendSrc != blendSrc ||
      this.currentBlendDst != blendDst ||
      this.currentBlendSrcAlpha != blendSrcAlpha ||
      this.currentBlendDstAlpha != blendDstAlpha
    ) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      this.currentBlendSrc = blendSrc;
      this.currentBlendDst = blendDst;
      this.currentBlendSrcAlpha = blendSrcAlpha;
      this.currentBlendDstAlpha = blendDstAlpha;
    }
    if (this.currentBlendColor.equals(blendColor) == false || this.currentBlendAlpha != blendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      this.currentBlendColor.copy(blendColor);
      this.currentBlendAlpha = blendAlpha;
    }
    this.currentBlending = blending;
    this.currentPremultipledAlpha = false;
  }

  public function setMaterial(material: Dynamic, frontFaceCW: Bool = false): Void {
    if (material.side == DoubleSide) {
      this.disable(gl.CULL_FACE);
    } else {
      this.enable(gl.CULL_FACE);
    }
    var flipSided = material.side == BackSide;
    if (frontFaceCW) {
      flipSided = !flipSided;
    }
    this.setFlipSided(flipSided);
    if (material.blending == NormalBlending && material.transparent == false) {
      this.setBlending(NoBlending);
    } else {
      this.setBlending(
        material.blending,
        material.blendEquation,
        material.blendSrc,
        material.blendDst,
        material.blendEquationAlpha,
        material.blendSrcAlpha,
        material.blendDstAlpha,
        material.blendColor,
        material.blendAlpha,
        material.premultipliedAlpha
      );
    }
    this.depthBuffer.setFunc(material.depthFunc);
    this.depthBuffer.setTest(material.depthTest);
    this.depthBuffer.setMask(material.depthWrite);
    this.colorBuffer.setMask(material.colorWrite);
    var stencilWrite = material.stencilWrite;
    this.stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      this.stencilBuffer.setMask(material.stencilWriteMask);
      this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    if (material.alphaToCoverage) {
      this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    } else {
      this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    }
  }

  public function setFlipSided(flipSided: Bool): Void {
    if (this.currentFlipSided != flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      this.currentFlipSided = flipSided;
    }
  }

  public function setCullFace(cullFace: Int): Void {
    if (cullFace != CullFaceNone) {
      this.enable(gl.CULL_FACE);
      if (this.currentCullFace != cullFace) {
        if (cullFace == CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace == CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      this.disable(gl.CULL_FACE);
    }
    this.currentCullFace = cullFace;
  }

  public function setLineWidth(width: Float): Void {
    if (this.currentLineWidth != width) {
      if (this.lineWidthAvailable) {
        gl.lineWidth(width);
      }
      this.currentLineWidth = width;
    }
  }

  public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {
    if (polygonOffset) {
      this.enable(gl.POLYGON_OFFSET_FILL);
      if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {
        gl.polygonOffset(factor, units);
        this.currentPolygonOffsetFactor = factor;
        this.currentPolygonOffsetUnits = units;
      }
    } else {
      this.disable(gl.POLYGON_OFFSET_FILL);
    }
  }

  public function setScissorTest(scissorTest: Bool): Void {
    if (scissorTest) {
      this.enable(gl.SCISSOR_TEST);
    } else {
      this.disable(gl.SCISSOR_TEST);
    }
  }

  public function activeTexture(webglSlot: Int = null): Void {
    if (webglSlot == null) {
      webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
    }
    if (this.currentTextureSlot != webglSlot) {
      gl.activeTexture(webglSlot);
      this.currentTextureSlot = webglSlot;
    }
  }

  public function bindTexture(webglType: Int, webglTexture: WebGLTexture = null, webglSlot: Int = null): Void {
    if (webglSlot == null) {
      if (this.currentTextureSlot == null) {
        webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
      } else {
        webglSlot = this.currentTextureSlot;
      }
    }
    var boundTexture = this.currentBoundTextures.get(webglSlot);
    if (boundTexture == null) {
      boundTexture = {type: null, texture: null};
      this.currentBoundTextures.set(webglSlot, boundTexture);
    }
    if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
      if (this.currentTextureSlot != webglSlot) {
        gl.activeTexture(webglSlot);
        this.currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture == null ? this.emptyTextures[webglType] : webglTexture);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }

  public function unbindTexture(): Void {
    var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);
    if (boundTexture != null && boundTexture.type != null) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = null;
      boundTexture.texture = null;
    }
  }

  public function compressedTexImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage2D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int
  ): Void {
    try {
      gl.texStorage2D(target, levels, internalformat, width, height);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage3D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int
  ): Void {
    try {
      gl.texStorage3D(target, levels, internalformat, width, height, depth);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function scissor(scissor: Vector4): Void {
    if (this.currentScissor.equals(scissor) == false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      this.currentScissor.copy(scissor);
    }
  }

  public function viewport(viewport: Vector4): Void {
    if (this.currentViewport.equals(viewport) == false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      this.currentViewport.copy(viewport);
    }
  }

  public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    if (mapping == null) {
      mapping = new WeakMap();
      this.uboProgramMap.set(program, mapping);
    }
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (blockIndex == null) {
      blockIndex = gl.getUniformBlockIndex(program, cast uniformsGroup.name);
      mapping.set(cast uniformsGroup.name, blockIndex);
    }
  }

  public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (this.uboBindings.get(program) != blockIndex) {
      gl.uniformBlockBinding(program, blockIndex, cast uniformsGroup.__bindingPointIndex);
      this.uboBindings.set(program, blockIndex);
    }
  }

  public function reset(): Void {
    gl.disable(gl.BLEND);
    gl.disable(gl.CULL_FACE);
    gl.disable(gl.DEPTH_TEST);
    gl.disable(gl.POLYGON_OFFSET_FILL);
    gl.disable(gl.SCISSOR_TEST);
    gl.disable(gl.STENCIL_TEST);
    gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    gl.blendEquation(gl.FUNC_ADD);
    gl.blendFunc(gl.ONE, gl.ZERO);
    gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
    gl.blendColor(0, 0, 0, 0);
    gl.colorMask(true, true, true, true);
    gl.clearColor(0, 0, 0, 0);
    gl.depthMask(true);
    gl.depthFunc(gl.LESS);
    gl.clearDepth(1);
    gl.stencilMask(0xffffffff);
    gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
    gl.clearStencil(0);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CCW);
    gl.polygonOffset(0, 0);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
    gl.useProgram(null);
    gl.lineWidth(1);
    gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    this.enabledCapabilities = new Map();
    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();
    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];
    this.currentProgram = null;
    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;
    this.currentFlipSided = null;
    this.currentCullFace = null;
    this.currentLineWidth = null;
    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;
    this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.colorBuffer.reset();
    this.depthBuffer.reset();
    this.stencilBuffer.reset();
  }

  public var buffers: { color: ColorBuffer, depth: DepthBuffer, stencil: StencilBuffer };

  private static var equationToGL: Map<Int, Int> = new Map();
  private static var factorToGL: Map<Int, Int> = new Map();

  static function init() {
    equationToGL[AddEquation] = gl.FUNC_ADD;
    equationToGL[SubtractEquation] = gl.FUNC_SUBTRACT;
    equationToGL[ReverseSubtractEquation] = gl.FUNC_REVERSE_SUBTRACT;
    equationToGL[MinEquation] = gl.MIN;
    equationToGL[MaxEquation] = gl.MAX;
    factorToGL[ZeroFactor] = gl.ZERO;
    factorToGL[OneFactor] = gl.ONE;
    factorToGL[SrcColorFactor] = gl.SRC_COLOR;
    factorToGL[SrcAlphaFactor] = gl.SRC_ALPHA;
    factorToGL[SrcAlphaSaturateFactor] = gl.SRC_ALPHA_SATURATE;
    factorToGL[DstColorFactor] = gl.DST_COLOR;
    factorToGL[DstAlphaFactor] = gl.DST_ALPHA;
    factorToGL[OneMinusSrcColorFactor] = gl.ONE_MINUS_SRC_COLOR;
    factorToGL[OneMinusSrcAlphaFactor] = gl.ONE_MINUS_SRC_ALPHA;
    factorToGL[OneMinusDstColorFactor] = gl.ONE_MINUS_DST_COLOR;
    factorToGL[OneMinusDstAlphaFactor] = gl.ONE_MINUS_DST_ALPHA;
    factorToGL[ConstantColorFactor] = gl.CONSTANT_COLOR;
    factorToGL[OneMinusConstantColorFactor] = gl.ONE_MINUS_CONSTANT_COLOR;
    factorToGL[ConstantAlphaFactor] = gl.CONSTANT_ALPHA;
    factorToGL[OneMinusConstantAlphaFactor] = gl.ONE_MINUS_CONSTANT_ALPHA;
  }

  private class ColorBuffer {
    private var locked: Bool;
    private var color: Vector4;
    private var currentColorMask: Bool;
    private var currentColorClear: Vector4;

    public function new() {
      this.locked = false;
      this.color = new Vector4();
      this.currentColorMask = null;
      this.currentColorClear = new Vector4(0, 0, 0, 0);
    }

    public function setMask(colorMask: Bool): Void {
      if (this.currentColorMask != colorMask && !this.locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        this.currentColorMask = colorMask;
      }
    }

    public function setLocked(lock: Bool): Void {
      this.locked = lock;
    }

    public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {
      if (premultipliedAlpha) {
        r *= a;
        g *= a;
        b *= a;
      }
      this.color.set(r, g, b, a);
      if (this.currentColorClear.equals(this.color) == false) {
        gl.clearColor(r, g, b, a);
        this.currentColorClear.copy(this.color);
      }
    }

    public function reset(): Void {
      this.locked = false;
      this.currentColorMask = null;
      this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  }

  private class DepthBuffer {
    private var locked: Bool;
    private var currentDepthMask: Bool;
    private var currentDepthFunc: Int;
    private var currentDepthClear: Float;

    public function new() {
      this.locked = false;
      this.currentDepthMask = null
import haxe.ds.WeakMap;
import three.math.Color;
import three.math.Vector4;
import three.constants.*;

class WebGLState {
  private var gl: WebGLRenderingContext;
  private var colorBuffer: ColorBuffer;
  private var depthBuffer: DepthBuffer;
  private var stencilBuffer: StencilBuffer;
  private var uboBindings: WeakMap<WebGLProgram, Int>;
  private var uboProgramMap: WeakMap<WebGLProgram, WeakMap<String, Int>>;
  private var enabledCapabilities: Map<Int, Bool>;
  private var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
  private var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
  private var defaultDrawbuffers: Array<Int>;
  private var currentProgram: WebGLProgram;
  private var currentBlendingEnabled: Bool;
  private var currentBlending: Int;
  private var currentBlendEquation: Int;
  private var currentBlendSrc: Int;
  private var currentBlendDst: Int;
  private var currentBlendEquationAlpha: Int;
  private var currentBlendSrcAlpha: Int;
  private var currentBlendDstAlpha: Int;
  private var currentBlendColor: Color;
  private var currentBlendAlpha: Float;
  private var currentPremultipledAlpha: Bool;
  private var currentFlipSided: Bool;
  private var currentCullFace: Int;
  private var currentLineWidth: Float;
  private var currentPolygonOffsetFactor: Float;
  private var currentPolygonOffsetUnits: Float;
  private var maxTextures: Int;
  private var lineWidthAvailable: Bool;
  private var version: Float;
  private var currentTextureSlot: Int;
  private var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;
  private var scissorParam: Array<Int>;
  private var viewportParam: Array<Int>;
  private var currentScissor: Vector4;
  private var currentViewport: Vector4;
  private var emptyTextures: Map<Int, WebGLTexture>;

  public function new(gl: WebGLRenderingContext) {
    this.gl = gl;

    this.colorBuffer = new ColorBuffer();
    this.depthBuffer = new DepthBuffer();
    this.stencilBuffer = new StencilBuffer();

    this.uboBindings = new WeakMap();
    this.uboProgramMap = new WeakMap();

    this.enabledCapabilities = new Map();

    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];

    this.currentProgram = null;

    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;

    this.currentFlipSided = null;
    this.currentCullFace = null;

    this.currentLineWidth = null;

    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;

    this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

    this.lineWidthAvailable = false;
    this.version = 0;
    var glVersion = gl.getParameter(gl.VERSION);

    if (glVersion.indexOf("WebGL") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^WebGL (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 1.0;
    } else if (glVersion.indexOf("OpenGL ES") != -1) {
      this.version = Std.parseFloat(glVersion.match(new EReg("^OpenGL ES (\\d)", ""))[1]);
      this.lineWidthAvailable = this.version >= 2.0;
    }

    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();

    this.scissorParam = gl.getParameter(gl.SCISSOR_BOX);
    this.viewportParam = gl.getParameter(gl.VIEWPORT);

    this.currentScissor = new Vector4().fromArray(this.scissorParam);
    this.currentViewport = new Vector4().fromArray(this.viewportParam);

    this.emptyTextures = new Map();
    this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
    this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
    this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
    this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

    this.colorBuffer.setClear(0, 0, 0, 1);
    this.depthBuffer.setClear(1);
    this.stencilBuffer.setClear(0);

    this.enable(gl.DEPTH_TEST);
    this.depthBuffer.setFunc(LessEqualDepth);

    this.setFlipSided(false);
    this.setCullFace(CullFaceBack);
    this.enable(gl.CULL_FACE);

    this.setBlending(NoBlending);
  }

  private function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {
    var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    var texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (var i = 0; i < count; i++) {
      if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }

  public function enable(id: Int): Void {
    if (!this.enabledCapabilities.exists(id) || !this.enabledCapabilities.get(id)) {
      gl.enable(id);
      this.enabledCapabilities.set(id, true);
    }
  }

  public function disable(id: Int): Void {
    if (this.enabledCapabilities.exists(id) && this.enabledCapabilities.get(id)) {
      gl.disable(id);
      this.enabledCapabilities.set(id, false);
    }
  }

  public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {
    if (this.currentBoundFramebuffers.get(target) != framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      this.currentBoundFramebuffers.set(target, framebuffer);
      if (target == gl.DRAW_FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);
      }
      if (target == gl.FRAMEBUFFER) {
        this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);
      }
      return true;
    }
    return false;
  }

  public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {
    var drawBuffers = this.defaultDrawbuffers;
    var needsUpdate = false;
    if (renderTarget != null) {
      drawBuffers = this.currentDrawbuffers.get(framebuffer);
      if (drawBuffers == null) {
        drawBuffers = [];
        this.currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      var textures = cast renderTarget.textures;
      if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
        for (var i = 0; i < textures.length; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] != gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }

  public function useProgram(program: WebGLProgram): Bool {
    if (this.currentProgram != program) {
      gl.useProgram(program);
      this.currentProgram = program;
      return true;
    }
    return false;
  }

  public function setBlending(
    blending: Int,
    blendEquation: Int = AddEquation,
    blendSrc: Int = SrcAlphaFactor,
    blendDst: Int = OneMinusSrcAlphaFactor,
    blendEquationAlpha: Int = null,
    blendSrcAlpha: Int = null,
    blendDstAlpha: Int = null,
    blendColor: Color = null,
    blendAlpha: Float = 0,
    premultipliedAlpha: Bool = false
  ): Void {
    if (blending == NoBlending) {
      if (this.currentBlendingEnabled) {
        this.disable(gl.BLEND);
        this.currentBlendingEnabled = false;
      }
      return;
    }
    if (!this.currentBlendingEnabled) {
      this.enable(gl.BLEND);
      this.currentBlendingEnabled = true;
    }
    if (blending != CustomBlending) {
      if (this.currentBlending != blending || this.currentPremultipledAlpha != premultipliedAlpha) {
        if (this.currentBlendEquation != AddEquation || this.currentBlendEquationAlpha != AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          this.currentBlendEquation = AddEquation;
          this.currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            default:
              console.error("THREE.WebGLState: Invalid blending: ", blending);
          }
        }
        this.currentBlendSrc = null;
        this.currentBlendDst = null;
        this.currentBlendSrcAlpha = null;
        this.currentBlendDstAlpha = null;
        this.currentBlendColor.set(0, 0, 0);
        this.currentBlendAlpha = 0;
        this.currentBlending = blending;
        this.currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }
    blendEquationAlpha = blendEquationAlpha == null ? blendEquation : blendEquationAlpha;
    blendSrcAlpha = blendSrcAlpha == null ? blendSrc : blendSrcAlpha;
    blendDstAlpha = blendDstAlpha == null ? blendDst : blendDstAlpha;
    if (this.currentBlendEquation != blendEquation || this.currentBlendEquationAlpha != blendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      this.currentBlendEquation = blendEquation;
      this.currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (
      this.currentBlendSrc != blendSrc ||
      this.currentBlendDst != blendDst ||
      this.currentBlendSrcAlpha != blendSrcAlpha ||
      this.currentBlendDstAlpha != blendDstAlpha
    ) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      this.currentBlendSrc = blendSrc;
      this.currentBlendDst = blendDst;
      this.currentBlendSrcAlpha = blendSrcAlpha;
      this.currentBlendDstAlpha = blendDstAlpha;
    }
    if (this.currentBlendColor.equals(blendColor) == false || this.currentBlendAlpha != blendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      this.currentBlendColor.copy(blendColor);
      this.currentBlendAlpha = blendAlpha;
    }
    this.currentBlending = blending;
    this.currentPremultipledAlpha = false;
  }

  public function setMaterial(material: Dynamic, frontFaceCW: Bool = false): Void {
    if (material.side == DoubleSide) {
      this.disable(gl.CULL_FACE);
    } else {
      this.enable(gl.CULL_FACE);
    }
    var flipSided = material.side == BackSide;
    if (frontFaceCW) {
      flipSided = !flipSided;
    }
    this.setFlipSided(flipSided);
    if (material.blending == NormalBlending && material.transparent == false) {
      this.setBlending(NoBlending);
    } else {
      this.setBlending(
        material.blending,
        material.blendEquation,
        material.blendSrc,
        material.blendDst,
        material.blendEquationAlpha,
        material.blendSrcAlpha,
        material.blendDstAlpha,
        material.blendColor,
        material.blendAlpha,
        material.premultipliedAlpha
      );
    }
    this.depthBuffer.setFunc(material.depthFunc);
    this.depthBuffer.setTest(material.depthTest);
    this.depthBuffer.setMask(material.depthWrite);
    this.colorBuffer.setMask(material.colorWrite);
    var stencilWrite = material.stencilWrite;
    this.stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      this.stencilBuffer.setMask(material.stencilWriteMask);
      this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    if (material.alphaToCoverage) {
      this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    } else {
      this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    }
  }

  public function setFlipSided(flipSided: Bool): Void {
    if (this.currentFlipSided != flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      this.currentFlipSided = flipSided;
    }
  }

  public function setCullFace(cullFace: Int): Void {
    if (cullFace != CullFaceNone) {
      this.enable(gl.CULL_FACE);
      if (this.currentCullFace != cullFace) {
        if (cullFace == CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace == CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      this.disable(gl.CULL_FACE);
    }
    this.currentCullFace = cullFace;
  }

  public function setLineWidth(width: Float): Void {
    if (this.currentLineWidth != width) {
      if (this.lineWidthAvailable) {
        gl.lineWidth(width);
      }
      this.currentLineWidth = width;
    }
  }

  public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {
    if (polygonOffset) {
      this.enable(gl.POLYGON_OFFSET_FILL);
      if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {
        gl.polygonOffset(factor, units);
        this.currentPolygonOffsetFactor = factor;
        this.currentPolygonOffsetUnits = units;
      }
    } else {
      this.disable(gl.POLYGON_OFFSET_FILL);
    }
  }

  public function setScissorTest(scissorTest: Bool): Void {
    if (scissorTest) {
      this.enable(gl.SCISSOR_TEST);
    } else {
      this.disable(gl.SCISSOR_TEST);
    }
  }

  public function activeTexture(webglSlot: Int = null): Void {
    if (webglSlot == null) {
      webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
    }
    if (this.currentTextureSlot != webglSlot) {
      gl.activeTexture(webglSlot);
      this.currentTextureSlot = webglSlot;
    }
  }

  public function bindTexture(webglType: Int, webglTexture: WebGLTexture = null, webglSlot: Int = null): Void {
    if (webglSlot == null) {
      if (this.currentTextureSlot == null) {
        webglSlot = gl.TEXTURE0 + this.maxTextures - 1;
      } else {
        webglSlot = this.currentTextureSlot;
      }
    }
    var boundTexture = this.currentBoundTextures.get(webglSlot);
    if (boundTexture == null) {
      boundTexture = {type: null, texture: null};
      this.currentBoundTextures.set(webglSlot, boundTexture);
    }
    if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
      if (this.currentTextureSlot != webglSlot) {
        gl.activeTexture(webglSlot);
        this.currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture == null ? this.emptyTextures[webglType] : webglTexture);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }

  public function unbindTexture(): Void {
    var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);
    if (boundTexture != null && boundTexture.type != null) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = null;
      boundTexture.texture = null;
    }
  }

  public function compressedTexImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    type: Int,
    pixels: ArrayBufferView
  ): Void {
    try {
      gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage2D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    width: Int,
    height: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function compressedTexSubImage3D(
    target: Int,
    level: Int,
    xoffset: Int,
    yoffset: Int,
    zoffset: Int,
    width: Int,
    height: Int,
    depth: Int,
    format: Int,
    data: ArrayBufferView
  ): Void {
    try {
      gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage2D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int
  ): Void {
    try {
      gl.texStorage2D(target, levels, internalformat, width, height);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texStorage3D(
    target: Int,
    levels: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int
  ): Void {
    try {
      gl.texStorage3D(target, levels, internalformat, width, height, depth);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage2D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function texImage3D(
    target: Int,
    level: Int,
    internalformat: Int,
    width: Int,
    height: Int,
    depth: Int,
    border: Int = 0,
    format: Int = null,
    type: Int = null,
    pixels: ArrayBufferView = null
  ): Void {
    try {
      gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels);
    } catch (e: Dynamic) {
      console.error("THREE.WebGLState:", e);
    }
  }

  public function scissor(scissor: Vector4): Void {
    if (this.currentScissor.equals(scissor) == false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      this.currentScissor.copy(scissor);
    }
  }

  public function viewport(viewport: Vector4): Void {
    if (this.currentViewport.equals(viewport) == false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      this.currentViewport.copy(viewport);
    }
  }

  public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    if (mapping == null) {
      mapping = new WeakMap();
      this.uboProgramMap.set(program, mapping);
    }
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (blockIndex == null) {
      blockIndex = gl.getUniformBlockIndex(program, cast uniformsGroup.name);
      mapping.set(cast uniformsGroup.name, blockIndex);
    }
  }

  public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {
    var mapping = this.uboProgramMap.get(program);
    var blockIndex = mapping.get(cast uniformsGroup.name);
    if (this.uboBindings.get(program) != blockIndex) {
      gl.uniformBlockBinding(program, blockIndex, cast uniformsGroup.__bindingPointIndex);
      this.uboBindings.set(program, blockIndex);
    }
  }

  public function reset(): Void {
    gl.disable(gl.BLEND);
    gl.disable(gl.CULL_FACE);
    gl.disable(gl.DEPTH_TEST);
    gl.disable(gl.POLYGON_OFFSET_FILL);
    gl.disable(gl.SCISSOR_TEST);
    gl.disable(gl.STENCIL_TEST);
    gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
    gl.blendEquation(gl.FUNC_ADD);
    gl.blendFunc(gl.ONE, gl.ZERO);
    gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
    gl.blendColor(0, 0, 0, 0);
    gl.colorMask(true, true, true, true);
    gl.clearColor(0, 0, 0, 0);
    gl.depthMask(true);
    gl.depthFunc(gl.LESS);
    gl.clearDepth(1);
    gl.stencilMask(0xffffffff);
    gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
    gl.clearStencil(0);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CCW);
    gl.polygonOffset(0, 0);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
    gl.useProgram(null);
    gl.lineWidth(1);
    gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    this.enabledCapabilities = new Map();
    this.currentTextureSlot = null;
    this.currentBoundTextures = new Map();
    this.currentBoundFramebuffers = new Map();
    this.currentDrawbuffers = new WeakMap();
    this.defaultDrawbuffers = [];
    this.currentProgram = null;
    this.currentBlendingEnabled = false;
    this.currentBlending = null;
    this.currentBlendEquation = null;
    this.currentBlendSrc = null;
    this.currentBlendDst = null;
    this.currentBlendEquationAlpha = null;
    this.currentBlendSrcAlpha = null;
    this.currentBlendDstAlpha = null;
    this.currentBlendColor = new Color(0, 0, 0);
    this.currentBlendAlpha = 0;
    this.currentPremultipledAlpha = false;
    this.currentFlipSided = null;
    this.currentCullFace = null;
    this.currentLineWidth = null;
    this.currentPolygonOffsetFactor = null;
    this.currentPolygonOffsetUnits = null;
    this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    this.colorBuffer.reset();
    this.depthBuffer.reset();
    this.stencilBuffer.reset();
  }

  public var buffers: { color: ColorBuffer, depth: DepthBuffer, stencil: StencilBuffer };

  private static var equationToGL: Map<Int, Int> = new Map();
  private static var factorToGL: Map<Int, Int> = new Map();

  static function init() {
    equationToGL[AddEquation] = gl.FUNC_ADD;
    equationToGL[SubtractEquation] = gl.FUNC_SUBTRACT;
    equationToGL[ReverseSubtractEquation] = gl.FUNC_REVERSE_SUBTRACT;
    equationToGL[MinEquation] = gl.MIN;
    equationToGL[MaxEquation] = gl.MAX;
    factorToGL[ZeroFactor] = gl.ZERO;
    factorToGL[OneFactor] = gl.ONE;
    factorToGL[SrcColorFactor] = gl.SRC_COLOR;
    factorToGL[SrcAlphaFactor] = gl.SRC_ALPHA;
    factorToGL[SrcAlphaSaturateFactor] = gl.SRC_ALPHA_SATURATE;
    factorToGL[DstColorFactor] = gl.DST_COLOR;
    factorToGL[DstAlphaFactor] = gl.DST_ALPHA;
    factorToGL[OneMinusSrcColorFactor] = gl.ONE_MINUS_SRC_COLOR;
    factorToGL[OneMinusSrcAlphaFactor] = gl.ONE_MINUS_SRC_ALPHA;
    factorToGL[OneMinusDstColorFactor] = gl.ONE_MINUS_DST_COLOR;
    factorToGL[OneMinusDstAlphaFactor] = gl.ONE_MINUS_DST_ALPHA;
    factorToGL[ConstantColorFactor] = gl.CONSTANT_COLOR;
    factorToGL[OneMinusConstantColorFactor] = gl.ONE_MINUS_CONSTANT_COLOR;
    factorToGL[ConstantAlphaFactor] = gl.CONSTANT_ALPHA;
    factorToGL[OneMinusConstantAlphaFactor] = gl.ONE_MINUS_CONSTANT_ALPHA;
  }

  private class ColorBuffer {
    private var locked: Bool;
    private var color: Vector4;
    private var currentColorMask: Bool;
    private var currentColorClear: Vector4;

    public function new() {
      this.locked = false;
      this.color = new Vector4();
      this.currentColorMask = null;
      this.currentColorClear = new Vector4(0, 0, 0, 0);
    }

    public function setMask(colorMask: Bool): Void {
      if (this.currentColorMask != colorMask && !this.locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        this.currentColorMask = colorMask;
      }
    }

    public function setLocked(lock: Bool): Void {
      this.locked = lock;
    }

    public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {
      if (premultipliedAlpha) {
        r *= a;
        g *= a;
        b *= a;
      }
      this.color.set(r, g, b, a);
      if (this.currentColorClear.equals(this.color) == false) {
        gl.clearColor(r, g, b, a);
        this.currentColorClear.copy(this.color);
      }
    }

    public function reset(): Void {
      this.locked = false;
      this.currentColorMask = null;
      this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  }

  private class DepthBuffer {
    private var locked: Bool;
    private var currentDepthMask: Bool;
    private var currentDepthFunc: Int;
    private var currentDepthClear: Float;

    public function new() {
      this.locked = false;
      this.currentDepthMask = null