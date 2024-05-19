import { NotEqualDepth, GreaterDepth, GreaterEqualDepth, EqualDepth, LessEqualDepth, LessDepth, AlwaysDepth, NeverDepth, CullFaceFront, CullFaceBack, CullFaceNone, DoubleSide, BackSide, CustomBlending, MultiplyBlending, SubtractiveBlending, AdditiveBlending, NoBlending, NormalBlending, AddEquation, SubtractEquation, ReverseSubtractEquation, MinEquation, MaxEquation, ZeroFactor, OneFactor, SrcColorFactor, SrcAlphaFactor, SrcAlphaSaturateFactor, DstColorFactor, DstAlphaFactor, OneMinusSrcColorFactor, OneMinusSrcAlphaFactor, OneMinusDstColorFactor, OneMinusDstAlphaFactor, ConstantColorFactor, OneMinusConstantColorFactor, ConstantAlphaFactor, OneMinusConstantAlphaFactor } from '../../constants.js';
import { Color } from '../../math/Color.js';
import { Vector4 } from '../../math/Vector4.js';
function WebGLState(gl) {
  function ColorBuffer() {
    let locked = false;
    const color = new Vector4();
    let currentColorMask = null;
    const currentColorClear = new Vector4(0, 0, 0, 0);
    return {
      setMask: function (colorMask) {
        if (currentColorMask !== colorMask && !locked) {
          gl.colorMask(colorMask, colorMask, colorMask, colorMask);
          currentColorMask = colorMask;
        }
      },
      setLocked: function (lock) {
        locked = lock;
      },
      setClear: function (r, g, b, a, premultipliedAlpha) {
        if (premultipliedAlpha === true) {
          r *= a;
          g *= a;
          b *= a;
        }
        color.set(r, g, b, a);
        if (currentColorClear.equals(color) === false) {
          gl.clearColor(r, g, b, a);
          currentColorClear.copy(color);
        }
      },
      reset: function () {
        locked = false;
        currentColorMask = null;
        currentColorClear.set(-1, 0, 0, 0); // set to invalid state
      }
    };
  }
  function DepthBuffer() {
    let locked = false;
    let currentDepthMask = null;
    let currentDepthFunc = null;
    let currentDepthClear = null;
    return {
      setTest: function (depthTest) {
        if (depthTest) {
          enable(gl.DEPTH_TEST);
        } else {
          disable(gl.DEPTH_TEST);
        }
      },
      setMask: function (depthMask) {
        if (currentDepthMask !== depthMask && !locked) {
          gl.depthMask(depthMask);
          currentDepthMask = depthMask;
        }
      },
      setFunc: function (depthFunc) {
        if (currentDepthFunc !== depthFunc) {
          switch (depthFunc) {
            case NeverDepth:
              gl.depthFunc(gl.NEVER);
              break;
            case AlwaysDepth:
              gl.depthFunc(gl.ALWAYS);
              break;
            case LessDepth:
              gl.depthFunc(gl.LESS);
              break;
            case LessEqualDepth:
              gl.depthFunc(gl.LEQUAL);
              break;
            case EqualDepth:
              gl.depthFunc(gl.EQUAL);
              break;
            case GreaterEqualDepth:
              gl.depthFunc(gl.GEQUAL);
              break;
            case GreaterDepth:
              gl.depthFunc(gl.GREATER);
              break;
            case NotEqualDepth:
              gl.depthFunc(gl.NOTEQUAL);
              break;
            default:
              gl.depthFunc(gl.LEQUAL);
          }
          currentDepthFunc = depthFunc;
        }
      },
      setLocked: function (lock) {
        locked = lock;
      },
      setClear: function (depth) {
        if (currentDepthClear !== depth) {
          gl.clearDepth(depth);
          currentDepthClear = depth;
        }
      },
      reset: function () {
        locked = false;
        currentDepthMask = null;
        currentDepthFunc = null;
        currentDepthClear = null;
      }
    };
  }
  function StencilBuffer() {
    let locked = false;
    let currentStencilMask = null;
    let currentStencilFunc = null;
    let currentStencilRef = null;
    let currentStencilFuncMask = null;
    let currentStencilFail = null;
    let currentStencilZFail = null;
    let currentStencilZPass = null;
    let currentStencilClear = null;
    return {
      setTest: function (stencilTest) {
        if (!locked) {
          if (stencilTest) {
            enable(gl.STENCIL_TEST);
          } else {
            disable(gl.STENCIL_TEST);
          }
        }
      },
      setMask: function (stencilMask) {
        if (currentStencilMask !== stencilMask && !locked) {
          gl.stencilMask(stencilMask);
          currentStencilMask = stencilMask;
        }
      },
      setFunc: function (stencilFunc, stencilRef, stencilMask) {
        if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
          gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
          currentStencilFunc = stencilFunc;
          currentStencilRef = stencilRef;
          currentStencilFuncMask = stencilMask;
        }
      },
      setOp: function (stencilFail, stencilZFail, stencilZPass) {
        if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
          gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
          currentStencilFail = stencilFail;
          currentStencilZFail = stencilZFail;
          currentStencilZPass = stencilZPass;
        }
      },
      setLocked: function (lock) {
        locked = lock;
      },
      setClear: function (stencil) {
        if (currentStencilClear !== stencil) {
          gl.clearStencil(stencil);
          currentStencilClear = stencil;
        }
      },
      reset: function () {
        locked = false;
        currentStencilMask = null;
        currentStencilFunc = null;
        currentStencilRef = null;
        currentStencilFuncMask = null;
        currentStencilFail = null;
        currentStencilZFail = null;
        currentStencilZPass = null;
        currentStencilClear = null;
      }
    };
  }

  //

  const colorBuffer = new ColorBuffer();
  const depthBuffer = new DepthBuffer();
  const stencilBuffer = new StencilBuffer();
  const uboBindings = new WeakMap();
  const uboProgramMap = new WeakMap();
  let enabledCapabilities = {};
  let currentBoundFramebuffers = {};
  let currentDrawbuffers = new WeakMap();
  let defaultDrawbuffers = [];
  let currentProgram = null;
  let currentBlendingEnabled = false;
  let currentBlending = null;
  let currentBlendEquation = null;
  let currentBlendSrc = null;
  let currentBlendDst = null;
  let currentBlendEquationAlpha = null;
  let currentBlendSrcAlpha = null;
  let currentBlendDstAlpha = null;
  let currentBlendColor = new Color(0, 0, 0);
  let currentBlendAlpha = 0;
  let currentPremultipledAlpha = false;
  let currentFlipSided = null;
  let currentCullFace = null;
  let currentLineWidth = null;
  let currentPolygonOffsetFactor = null;
  let currentPolygonOffsetUnits = null;
  const maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);
  let lineWidthAvailable = false;
  let version = 0;
  const glVersion = gl.getParameter(gl.VERSION);
  if (glVersion.indexOf('WebGL') !== -1) {
    version = parseFloat(/^WebGL (\d)/.exec(glVersion)[1]);
    lineWidthAvailable = version >= 1.0;
  } else if (glVersion.indexOf('OpenGL ES') !== -1) {
    version = parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1]);
    lineWidthAvailable = version >= 2.0;
  }
  let currentTextureSlot = null;
  let currentBoundTextures = {};
  const scissorParam = gl.getParameter(gl.SCISSOR_BOX);
  const viewportParam = gl.getParameter(gl.VIEWPORT);
  const currentScissor = new Vector4().fromArray(scissorParam);
  const currentViewport = new Vector4().fromArray(viewportParam);
  function createTexture(type, target, count, dimensions) {
    const data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    const texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (let i = 0; i < count; i++) {
      if (type === gl.TEXTURE_3D || type === gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }
  const emptyTextures = {};
  emptyTextures[gl.TEXTURE_2D] = createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
  emptyTextures[gl.TEXTURE_CUBE_MAP] = createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
  emptyTextures[gl.TEXTURE_2D_ARRAY] = createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
  emptyTextures[gl.TEXTURE_3D] = createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

  // init

  colorBuffer.setClear(0, 0, 0, 1);
  depthBuffer.setClear(1);
  stencilBuffer.setClear(0);
  enable(gl.DEPTH_TEST);
  depthBuffer.setFunc(LessEqualDepth);
  setFlipSided(false);
  setCullFace(CullFaceBack);
  enable(gl.CULL_FACE);
  setBlending(NoBlending);

  //

  function enable(id) {
    if (enabledCapabilities[id] !== true) {
      gl.enable(id);
      enabledCapabilities[id] = true;
    }
  }
  function disable(id) {
    if (enabledCapabilities[id] !== false) {
      gl.disable(id);
      enabledCapabilities[id] = false;
    }
  }
  function bindFramebuffer(target, framebuffer) {
    if (currentBoundFramebuffers[target] !== framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      currentBoundFramebuffers[target] = framebuffer;

      // gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

      if (target === gl.DRAW_FRAMEBUFFER) {
        currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
      }
      if (target === gl.FRAMEBUFFER) {
        currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
      }
      return true;
    }
    return false;
  }
  function drawBuffers(renderTarget, framebuffer) {
    let drawBuffers = defaultDrawbuffers;
    let needsUpdate = false;
    if (renderTarget) {
      drawBuffers = currentDrawbuffers.get(framebuffer);
      if (drawBuffers === undefined) {
        drawBuffers = [];
        currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      const textures = renderTarget.textures;
      if (drawBuffers.length !== textures.length || drawBuffers[0] !== gl.COLOR_ATTACHMENT0) {
        for (let i = 0, il = textures.length; i < il; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] !== gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }
  function useProgram(program) {
    if (currentProgram !== program) {
      gl.useProgram(program);
      currentProgram = program;
      return true;
    }
    return false;
  }
  const equationToGL = {
    [AddEquation]: gl.FUNC_ADD,
    [SubtractEquation]: gl.FUNC_SUBTRACT,
    [ReverseSubtractEquation]: gl.FUNC_REVERSE_SUBTRACT
  };
  equationToGL[MinEquation] = gl.MIN;
  equationToGL[MaxEquation] = gl.MAX;
  const factorToGL = {
    [ZeroFactor]: gl.ZERO,
    [OneFactor]: gl.ONE,
    [SrcColorFactor]: gl.SRC_COLOR,
    [SrcAlphaFactor]: gl.SRC_ALPHA,
    [SrcAlphaSaturateFactor]: gl.SRC_ALPHA_SATURATE,
    [DstColorFactor]: gl.DST_COLOR,
    [DstAlphaFactor]: gl.DST_ALPHA,
    [OneMinusSrcColorFactor]: gl.ONE_MINUS_SRC_COLOR,
    [OneMinusSrcAlphaFactor]: gl.ONE_MINUS_SRC_ALPHA,
    [OneMinusDstColorFactor]: gl.ONE_MINUS_DST_COLOR,
    [OneMinusDstAlphaFactor]: gl.ONE_MINUS_DST_ALPHA,
    [ConstantColorFactor]: gl.CONSTANT_COLOR,
    [OneMinusConstantColorFactor]: gl.ONE_MINUS_CONSTANT_COLOR,
    [ConstantAlphaFactor]: gl.CONSTANT_ALPHA,
    [OneMinusConstantAlphaFactor]: gl.ONE_MINUS_CONSTANT_ALPHA
  };
  function setBlending(blending, blendEquation, blendSrc, blendDst, blendEquationAlpha, blendSrcAlpha, blendDstAlpha, blendColor, blendAlpha, premultipliedAlpha) {
    if (blending === NoBlending) {
      if (currentBlendingEnabled === true) {
        disable(gl.BLEND);
        currentBlendingEnabled = false;
      }
      return;
    }
    if (currentBlendingEnabled === false) {
      enable(gl.BLEND);
      currentBlendingEnabled = true;
    }
    if (blending !== CustomBlending) {
      if (blending !== currentBlending || premultipliedAlpha !== currentPremultipledAlpha) {
        if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          currentBlendEquation = AddEquation;
          currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
              break;
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
              break;
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
              break;
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
              break;
            default:
              console.error('THREE.WebGLState: Invalid blending: ', blending);
              break;
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
              break;
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
              break;
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
              break;
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
              break;
            default:
              console.error('THREE.WebGLState: Invalid blending: ', blending);
              break;
          }
        }
        currentBlendSrc = null;
        currentBlendDst = null;
        currentBlendSrcAlpha = null;
        currentBlendDstAlpha = null;
        currentBlendColor.set(0, 0, 0);
        currentBlendAlpha = 0;
        currentBlending = blending;
        currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }

    // custom blending

    blendEquationAlpha = blendEquationAlpha || blendEquation;
    blendSrcAlpha = blendSrcAlpha || blendSrc;
    blendDstAlpha = blendDstAlpha || blendDst;
    if (blendEquation !== currentBlendEquation || blendEquationAlpha !== currentBlendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      currentBlendEquation = blendEquation;
      currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (blendSrc !== currentBlendSrc || blendDst !== currentBlendDst || blendSrcAlpha !== currentBlendSrcAlpha || blendDstAlpha !== currentBlendDstAlpha) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      currentBlendSrc = blendSrc;
      currentBlendDst = blendDst;
      currentBlendSrcAlpha = blendSrcAlpha;
      currentBlendDstAlpha = blendDstAlpha;
    }
    if (blendColor.equals(currentBlendColor) === false || blendAlpha !== currentBlendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      currentBlendColor.copy(blendColor);
      currentBlendAlpha = blendAlpha;
    }
    currentBlending = blending;
    currentPremultipledAlpha = false;
  }
  function setMaterial(material, frontFaceCW) {
    material.side === DoubleSide ? disable(gl.CULL_FACE) : enable(gl.CULL_FACE);
    let flipSided = material.side === BackSide;
    if (frontFaceCW) flipSided = !flipSided;
    setFlipSided(flipSided);
    material.blending === NormalBlending && material.transparent === false ? setBlending(NoBlending) : setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);
    depthBuffer.setFunc(material.depthFunc);
    depthBuffer.setTest(material.depthTest);
    depthBuffer.setMask(material.depthWrite);
    colorBuffer.setMask(material.colorWrite);
    const stencilWrite = material.stencilWrite;
    stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      stencilBuffer.setMask(material.stencilWriteMask);
      stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    material.alphaToCoverage === true ? enable(gl.SAMPLE_ALPHA_TO_COVERAGE) : disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
  }

  //

  function setFlipSided(flipSided) {
    if (currentFlipSided !== flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      currentFlipSided = flipSided;
    }
  }
  function setCullFace(cullFace) {
    if (cullFace !== CullFaceNone) {
      enable(gl.CULL_FACE);
      if (cullFace !== currentCullFace) {
        if (cullFace === CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace === CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      disable(gl.CULL_FACE);
    }
    currentCullFace = cullFace;
  }
  function setLineWidth(width) {
    if (width !== currentLineWidth) {
      if (lineWidthAvailable) gl.lineWidth(width);
      currentLineWidth = width;
    }
  }
  function setPolygonOffset(polygonOffset, factor, units) {
    if (polygonOffset) {
      enable(gl.POLYGON_OFFSET_FILL);
      if (currentPolygonOffsetFactor !== factor || currentPolygonOffsetUnits !== units) {
        gl.polygonOffset(factor, units);
        currentPolygonOffsetFactor = factor;
        currentPolygonOffsetUnits = units;
      }
    } else {
      disable(gl.POLYGON_OFFSET_FILL);
    }
  }
  function setScissorTest(scissorTest) {
    if (scissorTest) {
      enable(gl.SCISSOR_TEST);
    } else {
      disable(gl.SCISSOR_TEST);
    }
  }

  // texture

  function activeTexture(webglSlot) {
    if (webglSlot === undefined) webglSlot = gl.TEXTURE0 + maxTextures - 1;
    if (currentTextureSlot !== webglSlot) {
      gl.activeTexture(webglSlot);
      currentTextureSlot = webglSlot;
    }
  }
  function bindTexture(webglType, webglTexture, webglSlot) {
    if (webglSlot === undefined) {
      if (currentTextureSlot === null) {
        webglSlot = gl.TEXTURE0 + maxTextures - 1;
      } else {
        webglSlot = currentTextureSlot;
      }
    }
    let boundTexture = currentBoundTextures[webglSlot];
    if (boundTexture === undefined) {
      boundTexture = {
        type: undefined,
        texture: undefined
      };
      currentBoundTextures[webglSlot] = boundTexture;
    }
    if (boundTexture.type !== webglType || boundTexture.texture !== webglTexture) {
      if (currentTextureSlot !== webglSlot) {
        gl.activeTexture(webglSlot);
        currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture || emptyTextures[webglType]);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }
  function unbindTexture() {
    const boundTexture = currentBoundTextures[currentTextureSlot];
    if (boundTexture !== undefined && boundTexture.type !== undefined) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = undefined;
      boundTexture.texture = undefined;
    }
  }
  function compressedTexImage2D() {
    try {
      gl.compressedTexImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function compressedTexImage3D() {
    try {
      gl.compressedTexImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texSubImage2D() {
    try {
      gl.texSubImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texSubImage3D() {
    try {
      gl.texSubImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function compressedTexSubImage2D() {
    try {
      gl.compressedTexSubImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function compressedTexSubImage3D() {
    try {
      gl.compressedTexSubImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texStorage2D() {
    try {
      gl.texStorage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texStorage3D() {
    try {
      gl.texStorage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texImage2D() {
    try {
      gl.texImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texImage3D() {
    try {
      gl.texImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }

  //

  function scissor(scissor) {
    if (currentScissor.equals(scissor) === false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      currentScissor.copy(scissor);
    }
  }
  function viewport(viewport) {
    if (currentViewport.equals(viewport) === false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      currentViewport.copy(viewport);
    }
  }
  function updateUBOMapping(uniformsGroup, program) {
    let mapping = uboProgramMap.get(program);
    if (mapping === undefined) {
      mapping = new WeakMap();
      uboProgramMap.set(program, mapping);
    }
    let blockIndex = mapping.get(uniformsGroup);
    if (blockIndex === undefined) {
      blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);
      mapping.set(uniformsGroup, blockIndex);
    }
  }
  function uniformBlockBinding(uniformsGroup, program) {
    const mapping = uboProgramMap.get(program);
    const blockIndex = mapping.get(uniformsGroup);
    if (uboBindings.get(program) !== blockIndex) {
      // bind shader specific block index to global block point
      gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);
      uboBindings.set(program, blockIndex);
    }
  }

  //

  function reset() {
    // reset state

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

    // reset internals

    enabledCapabilities = {};
    currentTextureSlot = null;
    currentBoundTextures = {};
    currentBoundFramebuffers = {};
    currentDrawbuffers = new WeakMap();
    defaultDrawbuffers = [];
    currentProgram = null;
    currentBlendingEnabled = false;
    currentBlending = null;
    currentBlendEquation = null;
    currentBlendSrc = null;
    currentBlendDst = null;
    currentBlendEquationAlpha = null;
    currentBlendSrcAlpha = null;
    currentBlendDstAlpha = null;
    currentBlendColor = new Color(0, 0, 0);
    currentBlendAlpha = 0;
    currentPremultipledAlpha = false;
    currentFlipSided = null;
    currentCullFace = null;
    currentLineWidth = null;
    currentPolygonOffsetFactor = null;
    currentPolygonOffsetUnits = null;
    currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    colorBuffer.reset();
    depthBuffer.reset();
    stencilBuffer.reset();
  }
  return {
    buffers: {
      color: colorBuffer,
      depth: depthBuffer,
      stencil: stencilBuffer
    },
    enable: enable,
    disable: disable,
    bindFramebuffer: bindFramebuffer,
    drawBuffers: drawBuffers,
    useProgram: useProgram,
    setBlending: setBlending,
    setMaterial: setMaterial,
    setFlipSided: setFlipSided,
    setCullFace: setCullFace,
    setLineWidth: setLineWidth,
    setPolygonOffset: setPolygonOffset,
    setScissorTest: setScissorTest,
    activeTexture: activeTexture,
    bindTexture: bindTexture,
    unbindTexture: unbindTexture,
    compressedTexImage2D: compressedTexImage2D,
    compressedTexImage3D: compressedTexImage3D,
    texImage2D: texImage2D,
    texImage3D: texImage3D,
    updateUBOMapping: updateUBOMapping,
    uniformBlockBinding: uniformBlockBinding,
    texStorage2D: texStorage2D,
    texStorage3D: texStorage3D,
    texSubImage2D: texSubImage2D,
    texSubImage3D: texSubImage3D,
    compressedTexSubImage2D: compressedTexSubImage2D,
    compressedTexSubImage3D: compressedTexSubImage3D,
    scissor: scissor,
    viewport: viewport,
    reset: reset
  };
}
export { WebGLState };
import { NotEqualDepth, GreaterDepth, GreaterEqualDepth, EqualDepth, LessEqualDepth, LessDepth, AlwaysDepth, NeverDepth, CullFaceFront, CullFaceBack, CullFaceNone, DoubleSide, BackSide, CustomBlending, MultiplyBlending, SubtractiveBlending, AdditiveBlending, NoBlending, NormalBlending, AddEquation, SubtractEquation, ReverseSubtractEquation, MinEquation, MaxEquation, ZeroFactor, OneFactor, SrcColorFactor, SrcAlphaFactor, SrcAlphaSaturateFactor, DstColorFactor, DstAlphaFactor, OneMinusSrcColorFactor, OneMinusSrcAlphaFactor, OneMinusDstColorFactor, OneMinusDstAlphaFactor, ConstantColorFactor, OneMinusConstantColorFactor, ConstantAlphaFactor, OneMinusConstantAlphaFactor } from '../../constants.js';
NotEqualDepth
NotEqualDepth
NotEqualDepth
GreaterDepth
GreaterDepth
GreaterDepth
GreaterEqualDepth
GreaterEqualDepth
GreaterEqualDepth
EqualDepth
EqualDepth
EqualDepth
LessEqualDepth
LessEqualDepth
LessEqualDepth
LessDepth
LessDepth
LessDepth
AlwaysDepth
AlwaysDepth
AlwaysDepth
NeverDepth
NeverDepth
NeverDepth
CullFaceFront
CullFaceFront
CullFaceFront
CullFaceBack
CullFaceBack
CullFaceBack
CullFaceNone
CullFaceNone
CullFaceNone
DoubleSide
DoubleSide
DoubleSide
BackSide
BackSide
BackSide
CustomBlending
CustomBlending
CustomBlending
MultiplyBlending
MultiplyBlending
MultiplyBlending
SubtractiveBlending
SubtractiveBlending
SubtractiveBlending
AdditiveBlending
AdditiveBlending
AdditiveBlending
NoBlending
NoBlending
NoBlending
NormalBlending
NormalBlending
NormalBlending
AddEquation
AddEquation
AddEquation
SubtractEquation
SubtractEquation
SubtractEquation
ReverseSubtractEquation
ReverseSubtractEquation
ReverseSubtractEquation
MinEquation
MinEquation
MinEquation
MaxEquation
MaxEquation
MaxEquation
ZeroFactor
ZeroFactor
ZeroFactor
OneFactor
OneFactor
OneFactor
SrcColorFactor
SrcColorFactor
SrcColorFactor
SrcAlphaFactor
SrcAlphaFactor
SrcAlphaFactor
SrcAlphaSaturateFactor
SrcAlphaSaturateFactor
SrcAlphaSaturateFactor
DstColorFactor
DstColorFactor
DstColorFactor
DstAlphaFactor
DstAlphaFactor
DstAlphaFactor
OneMinusSrcColorFactor
OneMinusSrcColorFactor
OneMinusSrcColorFactor
OneMinusSrcAlphaFactor
OneMinusSrcAlphaFactor
OneMinusSrcAlphaFactor
OneMinusDstColorFactor
OneMinusDstColorFactor
OneMinusDstColorFactor
OneMinusDstAlphaFactor
OneMinusDstAlphaFactor
OneMinusDstAlphaFactor
ConstantColorFactor
ConstantColorFactor
ConstantColorFactor
OneMinusConstantColorFactor
OneMinusConstantColorFactor
OneMinusConstantColorFactor
ConstantAlphaFactor
ConstantAlphaFactor
ConstantAlphaFactor
OneMinusConstantAlphaFactor
OneMinusConstantAlphaFactor
OneMinusConstantAlphaFactor
'../../constants.js'
import { Color } from '../../math/Color.js';
Color
Color
Color
'../../math/Color.js'
import { Vector4 } from '../../math/Vector4.js';
Vector4
Vector4
Vector4
'../../math/Vector4.js'
function WebGLState(gl) {
  function ColorBuffer() {
    let locked = false;
    const color = new Vector4();
    let currentColorMask = null;
    const currentColorClear = new Vector4(0, 0, 0, 0);
    return {
      setMask: function (colorMask) {
        if (currentColorMask !== colorMask && !locked) {
          gl.colorMask(colorMask, colorMask, colorMask, colorMask);
          currentColorMask = colorMask;
        }
      },
      setLocked: function (lock) {
        locked = lock;
      },
      setClear: function (r, g, b, a, premultipliedAlpha) {
        if (premultipliedAlpha === true) {
          r *= a;
          g *= a;
          b *= a;
        }
        color.set(r, g, b, a);
        if (currentColorClear.equals(color) === false) {
          gl.clearColor(r, g, b, a);
          currentColorClear.copy(color);
        }
      },
      reset: function () {
        locked = false;
        currentColorMask = null;
        currentColorClear.set(-1, 0, 0, 0); // set to invalid state
      }
    };
  }
  function DepthBuffer() {
    let locked = false;
    let currentDepthMask = null;
    let currentDepthFunc = null;
    let currentDepthClear = null;
    return {
      setTest: function (depthTest) {
        if (depthTest) {
          enable(gl.DEPTH_TEST);
        } else {
          disable(gl.DEPTH_TEST);
        }
      },
      setMask: function (depthMask) {
        if (currentDepthMask !== depthMask && !locked) {
          gl.depthMask(depthMask);
          currentDepthMask = depthMask;
        }
      },
      setFunc: function (depthFunc) {
        if (currentDepthFunc !== depthFunc) {
          switch (depthFunc) {
            case NeverDepth:
              gl.depthFunc(gl.NEVER);
              break;
            case AlwaysDepth:
              gl.depthFunc(gl.ALWAYS);
              break;
            case LessDepth:
              gl.depthFunc(gl.LESS);
              break;
            case LessEqualDepth:
              gl.depthFunc(gl.LEQUAL);
              break;
            case EqualDepth:
              gl.depthFunc(gl.EQUAL);
              break;
            case GreaterEqualDepth:
              gl.depthFunc(gl.GEQUAL);
              break;
            case GreaterDepth:
              gl.depthFunc(gl.GREATER);
              break;
            case NotEqualDepth:
              gl.depthFunc(gl.NOTEQUAL);
              break;
            default:
              gl.depthFunc(gl.LEQUAL);
          }
          currentDepthFunc = depthFunc;
        }
      },
      setLocked: function (lock) {
        locked = lock;
      },
      setClear: function (depth) {
        if (currentDepthClear !== depth) {
          gl.clearDepth(depth);
          currentDepthClear = depth;
        }
      },
      reset: function () {
        locked = false;
        currentDepthMask = null;
        currentDepthFunc = null;
        currentDepthClear = null;
      }
    };
  }
  function StencilBuffer() {
    let locked = false;
    let currentStencilMask = null;
    let currentStencilFunc = null;
    let currentStencilRef = null;
    let currentStencilFuncMask = null;
    let currentStencilFail = null;
    let currentStencilZFail = null;
    let currentStencilZPass = null;
    let currentStencilClear = null;
    return {
      setTest: function (stencilTest) {
        if (!locked) {
          if (stencilTest) {
            enable(gl.STENCIL_TEST);
          } else {
            disable(gl.STENCIL_TEST);
          }
        }
      },
      setMask: function (stencilMask) {
        if (currentStencilMask !== stencilMask && !locked) {
          gl.stencilMask(stencilMask);
          currentStencilMask = stencilMask;
        }
      },
      setFunc: function (stencilFunc, stencilRef, stencilMask) {
        if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
          gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
          currentStencilFunc = stencilFunc;
          currentStencilRef = stencilRef;
          currentStencilFuncMask = stencilMask;
        }
      },
      setOp: function (stencilFail, stencilZFail, stencilZPass) {
        if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
          gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
          currentStencilFail = stencilFail;
          currentStencilZFail = stencilZFail;
          currentStencilZPass = stencilZPass;
        }
      },
      setLocked: function (lock) {
        locked = lock;
      },
      setClear: function (stencil) {
        if (currentStencilClear !== stencil) {
          gl.clearStencil(stencil);
          currentStencilClear = stencil;
        }
      },
      reset: function () {
        locked = false;
        currentStencilMask = null;
        currentStencilFunc = null;
        currentStencilRef = null;
        currentStencilFuncMask = null;
        currentStencilFail = null;
        currentStencilZFail = null;
        currentStencilZPass = null;
        currentStencilClear = null;
      }
    };
  }

  //

  const colorBuffer = new ColorBuffer();
  const depthBuffer = new DepthBuffer();
  const stencilBuffer = new StencilBuffer();
  const uboBindings = new WeakMap();
  const uboProgramMap = new WeakMap();
  let enabledCapabilities = {};
  let currentBoundFramebuffers = {};
  let currentDrawbuffers = new WeakMap();
  let defaultDrawbuffers = [];
  let currentProgram = null;
  let currentBlendingEnabled = false;
  let currentBlending = null;
  let currentBlendEquation = null;
  let currentBlendSrc = null;
  let currentBlendDst = null;
  let currentBlendEquationAlpha = null;
  let currentBlendSrcAlpha = null;
  let currentBlendDstAlpha = null;
  let currentBlendColor = new Color(0, 0, 0);
  let currentBlendAlpha = 0;
  let currentPremultipledAlpha = false;
  let currentFlipSided = null;
  let currentCullFace = null;
  let currentLineWidth = null;
  let currentPolygonOffsetFactor = null;
  let currentPolygonOffsetUnits = null;
  const maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);
  let lineWidthAvailable = false;
  let version = 0;
  const glVersion = gl.getParameter(gl.VERSION);
  if (glVersion.indexOf('WebGL') !== -1) {
    version = parseFloat(/^WebGL (\d)/.exec(glVersion)[1]);
    lineWidthAvailable = version >= 1.0;
  } else if (glVersion.indexOf('OpenGL ES') !== -1) {
    version = parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1]);
    lineWidthAvailable = version >= 2.0;
  }
  let currentTextureSlot = null;
  let currentBoundTextures = {};
  const scissorParam = gl.getParameter(gl.SCISSOR_BOX);
  const viewportParam = gl.getParameter(gl.VIEWPORT);
  const currentScissor = new Vector4().fromArray(scissorParam);
  const currentViewport = new Vector4().fromArray(viewportParam);
  function createTexture(type, target, count, dimensions) {
    const data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    const texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (let i = 0; i < count; i++) {
      if (type === gl.TEXTURE_3D || type === gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }
  const emptyTextures = {};
  emptyTextures[gl.TEXTURE_2D] = createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
  emptyTextures[gl.TEXTURE_CUBE_MAP] = createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
  emptyTextures[gl.TEXTURE_2D_ARRAY] = createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
  emptyTextures[gl.TEXTURE_3D] = createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

  // init

  colorBuffer.setClear(0, 0, 0, 1);
  depthBuffer.setClear(1);
  stencilBuffer.setClear(0);
  enable(gl.DEPTH_TEST);
  depthBuffer.setFunc(LessEqualDepth);
  setFlipSided(false);
  setCullFace(CullFaceBack);
  enable(gl.CULL_FACE);
  setBlending(NoBlending);

  //

  function enable(id) {
    if (enabledCapabilities[id] !== true) {
      gl.enable(id);
      enabledCapabilities[id] = true;
    }
  }
  function disable(id) {
    if (enabledCapabilities[id] !== false) {
      gl.disable(id);
      enabledCapabilities[id] = false;
    }
  }
  function bindFramebuffer(target, framebuffer) {
    if (currentBoundFramebuffers[target] !== framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      currentBoundFramebuffers[target] = framebuffer;

      // gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

      if (target === gl.DRAW_FRAMEBUFFER) {
        currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
      }
      if (target === gl.FRAMEBUFFER) {
        currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
      }
      return true;
    }
    return false;
  }
  function drawBuffers(renderTarget, framebuffer) {
    let drawBuffers = defaultDrawbuffers;
    let needsUpdate = false;
    if (renderTarget) {
      drawBuffers = currentDrawbuffers.get(framebuffer);
      if (drawBuffers === undefined) {
        drawBuffers = [];
        currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      const textures = renderTarget.textures;
      if (drawBuffers.length !== textures.length || drawBuffers[0] !== gl.COLOR_ATTACHMENT0) {
        for (let i = 0, il = textures.length; i < il; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] !== gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }
  function useProgram(program) {
    if (currentProgram !== program) {
      gl.useProgram(program);
      currentProgram = program;
      return true;
    }
    return false;
  }
  const equationToGL = {
    [AddEquation]: gl.FUNC_ADD,
    [SubtractEquation]: gl.FUNC_SUBTRACT,
    [ReverseSubtractEquation]: gl.FUNC_REVERSE_SUBTRACT
  };
  equationToGL[MinEquation] = gl.MIN;
  equationToGL[MaxEquation] = gl.MAX;
  const factorToGL = {
    [ZeroFactor]: gl.ZERO,
    [OneFactor]: gl.ONE,
    [SrcColorFactor]: gl.SRC_COLOR,
    [SrcAlphaFactor]: gl.SRC_ALPHA,
    [SrcAlphaSaturateFactor]: gl.SRC_ALPHA_SATURATE,
    [DstColorFactor]: gl.DST_COLOR,
    [DstAlphaFactor]: gl.DST_ALPHA,
    [OneMinusSrcColorFactor]: gl.ONE_MINUS_SRC_COLOR,
    [OneMinusSrcAlphaFactor]: gl.ONE_MINUS_SRC_ALPHA,
    [OneMinusDstColorFactor]: gl.ONE_MINUS_DST_COLOR,
    [OneMinusDstAlphaFactor]: gl.ONE_MINUS_DST_ALPHA,
    [ConstantColorFactor]: gl.CONSTANT_COLOR,
    [OneMinusConstantColorFactor]: gl.ONE_MINUS_CONSTANT_COLOR,
    [ConstantAlphaFactor]: gl.CONSTANT_ALPHA,
    [OneMinusConstantAlphaFactor]: gl.ONE_MINUS_CONSTANT_ALPHA
  };
  function setBlending(blending, blendEquation, blendSrc, blendDst, blendEquationAlpha, blendSrcAlpha, blendDstAlpha, blendColor, blendAlpha, premultipliedAlpha) {
    if (blending === NoBlending) {
      if (currentBlendingEnabled === true) {
        disable(gl.BLEND);
        currentBlendingEnabled = false;
      }
      return;
    }
    if (currentBlendingEnabled === false) {
      enable(gl.BLEND);
      currentBlendingEnabled = true;
    }
    if (blending !== CustomBlending) {
      if (blending !== currentBlending || premultipliedAlpha !== currentPremultipledAlpha) {
        if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          currentBlendEquation = AddEquation;
          currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
              break;
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
              break;
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
              break;
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
              break;
            default:
              console.error('THREE.WebGLState: Invalid blending: ', blending);
              break;
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
              break;
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
              break;
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
              break;
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
              break;
            default:
              console.error('THREE.WebGLState: Invalid blending: ', blending);
              break;
          }
        }
        currentBlendSrc = null;
        currentBlendDst = null;
        currentBlendSrcAlpha = null;
        currentBlendDstAlpha = null;
        currentBlendColor.set(0, 0, 0);
        currentBlendAlpha = 0;
        currentBlending = blending;
        currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }

    // custom blending

    blendEquationAlpha = blendEquationAlpha || blendEquation;
    blendSrcAlpha = blendSrcAlpha || blendSrc;
    blendDstAlpha = blendDstAlpha || blendDst;
    if (blendEquation !== currentBlendEquation || blendEquationAlpha !== currentBlendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      currentBlendEquation = blendEquation;
      currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (blendSrc !== currentBlendSrc || blendDst !== currentBlendDst || blendSrcAlpha !== currentBlendSrcAlpha || blendDstAlpha !== currentBlendDstAlpha) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      currentBlendSrc = blendSrc;
      currentBlendDst = blendDst;
      currentBlendSrcAlpha = blendSrcAlpha;
      currentBlendDstAlpha = blendDstAlpha;
    }
    if (blendColor.equals(currentBlendColor) === false || blendAlpha !== currentBlendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      currentBlendColor.copy(blendColor);
      currentBlendAlpha = blendAlpha;
    }
    currentBlending = blending;
    currentPremultipledAlpha = false;
  }
  function setMaterial(material, frontFaceCW) {
    material.side === DoubleSide ? disable(gl.CULL_FACE) : enable(gl.CULL_FACE);
    let flipSided = material.side === BackSide;
    if (frontFaceCW) flipSided = !flipSided;
    setFlipSided(flipSided);
    material.blending === NormalBlending && material.transparent === false ? setBlending(NoBlending) : setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);
    depthBuffer.setFunc(material.depthFunc);
    depthBuffer.setTest(material.depthTest);
    depthBuffer.setMask(material.depthWrite);
    colorBuffer.setMask(material.colorWrite);
    const stencilWrite = material.stencilWrite;
    stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      stencilBuffer.setMask(material.stencilWriteMask);
      stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    material.alphaToCoverage === true ? enable(gl.SAMPLE_ALPHA_TO_COVERAGE) : disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
  }

  //

  function setFlipSided(flipSided) {
    if (currentFlipSided !== flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      currentFlipSided = flipSided;
    }
  }
  function setCullFace(cullFace) {
    if (cullFace !== CullFaceNone) {
      enable(gl.CULL_FACE);
      if (cullFace !== currentCullFace) {
        if (cullFace === CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace === CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      disable(gl.CULL_FACE);
    }
    currentCullFace = cullFace;
  }
  function setLineWidth(width) {
    if (width !== currentLineWidth) {
      if (lineWidthAvailable) gl.lineWidth(width);
      currentLineWidth = width;
    }
  }
  function setPolygonOffset(polygonOffset, factor, units) {
    if (polygonOffset) {
      enable(gl.POLYGON_OFFSET_FILL);
      if (currentPolygonOffsetFactor !== factor || currentPolygonOffsetUnits !== units) {
        gl.polygonOffset(factor, units);
        currentPolygonOffsetFactor = factor;
        currentPolygonOffsetUnits = units;
      }
    } else {
      disable(gl.POLYGON_OFFSET_FILL);
    }
  }
  function setScissorTest(scissorTest) {
    if (scissorTest) {
      enable(gl.SCISSOR_TEST);
    } else {
      disable(gl.SCISSOR_TEST);
    }
  }

  // texture

  function activeTexture(webglSlot) {
    if (webglSlot === undefined) webglSlot = gl.TEXTURE0 + maxTextures - 1;
    if (currentTextureSlot !== webglSlot) {
      gl.activeTexture(webglSlot);
      currentTextureSlot = webglSlot;
    }
  }
  function bindTexture(webglType, webglTexture, webglSlot) {
    if (webglSlot === undefined) {
      if (currentTextureSlot === null) {
        webglSlot = gl.TEXTURE0 + maxTextures - 1;
      } else {
        webglSlot = currentTextureSlot;
      }
    }
    let boundTexture = currentBoundTextures[webglSlot];
    if (boundTexture === undefined) {
      boundTexture = {
        type: undefined,
        texture: undefined
      };
      currentBoundTextures[webglSlot] = boundTexture;
    }
    if (boundTexture.type !== webglType || boundTexture.texture !== webglTexture) {
      if (currentTextureSlot !== webglSlot) {
        gl.activeTexture(webglSlot);
        currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture || emptyTextures[webglType]);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }
  function unbindTexture() {
    const boundTexture = currentBoundTextures[currentTextureSlot];
    if (boundTexture !== undefined && boundTexture.type !== undefined) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = undefined;
      boundTexture.texture = undefined;
    }
  }
  function compressedTexImage2D() {
    try {
      gl.compressedTexImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function compressedTexImage3D() {
    try {
      gl.compressedTexImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texSubImage2D() {
    try {
      gl.texSubImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texSubImage3D() {
    try {
      gl.texSubImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function compressedTexSubImage2D() {
    try {
      gl.compressedTexSubImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function compressedTexSubImage3D() {
    try {
      gl.compressedTexSubImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texStorage2D() {
    try {
      gl.texStorage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texStorage3D() {
    try {
      gl.texStorage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texImage2D() {
    try {
      gl.texImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texImage3D() {
    try {
      gl.texImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }

  //

  function scissor(scissor) {
    if (currentScissor.equals(scissor) === false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      currentScissor.copy(scissor);
    }
  }
  function viewport(viewport) {
    if (currentViewport.equals(viewport) === false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      currentViewport.copy(viewport);
    }
  }
  function updateUBOMapping(uniformsGroup, program) {
    let mapping = uboProgramMap.get(program);
    if (mapping === undefined) {
      mapping = new WeakMap();
      uboProgramMap.set(program, mapping);
    }
    let blockIndex = mapping.get(uniformsGroup);
    if (blockIndex === undefined) {
      blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);
      mapping.set(uniformsGroup, blockIndex);
    }
  }
  function uniformBlockBinding(uniformsGroup, program) {
    const mapping = uboProgramMap.get(program);
    const blockIndex = mapping.get(uniformsGroup);
    if (uboBindings.get(program) !== blockIndex) {
      // bind shader specific block index to global block point
      gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);
      uboBindings.set(program, blockIndex);
    }
  }

  //

  function reset() {
    // reset state

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

    // reset internals

    enabledCapabilities = {};
    currentTextureSlot = null;
    currentBoundTextures = {};
    currentBoundFramebuffers = {};
    currentDrawbuffers = new WeakMap();
    defaultDrawbuffers = [];
    currentProgram = null;
    currentBlendingEnabled = false;
    currentBlending = null;
    currentBlendEquation = null;
    currentBlendSrc = null;
    currentBlendDst = null;
    currentBlendEquationAlpha = null;
    currentBlendSrcAlpha = null;
    currentBlendDstAlpha = null;
    currentBlendColor = new Color(0, 0, 0);
    currentBlendAlpha = 0;
    currentPremultipledAlpha = false;
    currentFlipSided = null;
    currentCullFace = null;
    currentLineWidth = null;
    currentPolygonOffsetFactor = null;
    currentPolygonOffsetUnits = null;
    currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    colorBuffer.reset();
    depthBuffer.reset();
    stencilBuffer.reset();
  }
  return {
    buffers: {
      color: colorBuffer,
      depth: depthBuffer,
      stencil: stencilBuffer
    },
    enable: enable,
    disable: disable,
    bindFramebuffer: bindFramebuffer,
    drawBuffers: drawBuffers,
    useProgram: useProgram,
    setBlending: setBlending,
    setMaterial: setMaterial,
    setFlipSided: setFlipSided,
    setCullFace: setCullFace,
    setLineWidth: setLineWidth,
    setPolygonOffset: setPolygonOffset,
    setScissorTest: setScissorTest,
    activeTexture: activeTexture,
    bindTexture: bindTexture,
    unbindTexture: unbindTexture,
    compressedTexImage2D: compressedTexImage2D,
    compressedTexImage3D: compressedTexImage3D,
    texImage2D: texImage2D,
    texImage3D: texImage3D,
    updateUBOMapping: updateUBOMapping,
    uniformBlockBinding: uniformBlockBinding,
    texStorage2D: texStorage2D,
    texStorage3D: texStorage3D,
    texSubImage2D: texSubImage2D,
    texSubImage3D: texSubImage3D,
    compressedTexSubImage2D: compressedTexSubImage2D,
    compressedTexSubImage3D: compressedTexSubImage3D,
    scissor: scissor,
    viewport: viewport,
    reset: reset
  };
}
function WebGLState(gl) {
  function ColorBuffer() {
    let locked = false;
    const color = new Vector4();
    let currentColorMask = null;
    const currentColorClear = new Vector4(0, 0, 0, 0);
    return {
      setMask: function (colorMask) {
        if (currentColorMask !== colorMask && !locked) {
          gl.colorMask(colorMask, colorMask, colorMask, colorMask);
          currentColorMask = colorMask;
        }
      },
      setLocked: function (lock) {
        locked = lock;
      },
      setClear: function (r, g, b, a, premultipliedAlpha) {
        if (premultipliedAlpha === true) {
          r *= a;
          g *= a;
          b *= a;
        }
        color.set(r, g, b, a);
        if (currentColorClear.equals(color) === false) {
          gl.clearColor(r, g, b, a);
          currentColorClear.copy(color);
        }
      },
      reset: function () {
        locked = false;
        currentColorMask = null;
        currentColorClear.set(-1, 0, 0, 0); // set to invalid state
      }
    };
  }
  function DepthBuffer() {
    let locked = false;
    let currentDepthMask = null;
    let currentDepthFunc = null;
    let currentDepthClear = null;
    return {
      setTest: function (depthTest) {
        if (depthTest) {
          enable(gl.DEPTH_TEST);
        } else {
          disable(gl.DEPTH_TEST);
        }
      },
      setMask: function (depthMask) {
        if (currentDepthMask !== depthMask && !locked) {
          gl.depthMask(depthMask);
          currentDepthMask = depthMask;
        }
      },
      setFunc: function (depthFunc) {
        if (currentDepthFunc !== depthFunc) {
          switch (depthFunc) {
            case NeverDepth:
              gl.depthFunc(gl.NEVER);
              break;
            case AlwaysDepth:
              gl.depthFunc(gl.ALWAYS);
              break;
            case LessDepth:
              gl.depthFunc(gl.LESS);
              break;
            case LessEqualDepth:
              gl.depthFunc(gl.LEQUAL);
              break;
            case EqualDepth:
              gl.depthFunc(gl.EQUAL);
              break;
            case GreaterEqualDepth:
              gl.depthFunc(gl.GEQUAL);
              break;
            case GreaterDepth:
              gl.depthFunc(gl.GREATER);
              break;
            case NotEqualDepth:
              gl.depthFunc(gl.NOTEQUAL);
              break;
            default:
              gl.depthFunc(gl.LEQUAL);
          }
          currentDepthFunc = depthFunc;
        }
      },
      setLocked: function (lock) {
        locked = lock;
      },
      setClear: function (depth) {
        if (currentDepthClear !== depth) {
          gl.clearDepth(depth);
          currentDepthClear = depth;
        }
      },
      reset: function () {
        locked = false;
        currentDepthMask = null;
        currentDepthFunc = null;
        currentDepthClear = null;
      }
    };
  }
  function StencilBuffer() {
    let locked = false;
    let currentStencilMask = null;
    let currentStencilFunc = null;
    let currentStencilRef = null;
    let currentStencilFuncMask = null;
    let currentStencilFail = null;
    let currentStencilZFail = null;
    let currentStencilZPass = null;
    let currentStencilClear = null;
    return {
      setTest: function (stencilTest) {
        if (!locked) {
          if (stencilTest) {
            enable(gl.STENCIL_TEST);
          } else {
            disable(gl.STENCIL_TEST);
          }
        }
      },
      setMask: function (stencilMask) {
        if (currentStencilMask !== stencilMask && !locked) {
          gl.stencilMask(stencilMask);
          currentStencilMask = stencilMask;
        }
      },
      setFunc: function (stencilFunc, stencilRef, stencilMask) {
        if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
          gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
          currentStencilFunc = stencilFunc;
          currentStencilRef = stencilRef;
          currentStencilFuncMask = stencilMask;
        }
      },
      setOp: function (stencilFail, stencilZFail, stencilZPass) {
        if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
          gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
          currentStencilFail = stencilFail;
          currentStencilZFail = stencilZFail;
          currentStencilZPass = stencilZPass;
        }
      },
      setLocked: function (lock) {
        locked = lock;
      },
      setClear: function (stencil) {
        if (currentStencilClear !== stencil) {
          gl.clearStencil(stencil);
          currentStencilClear = stencil;
        }
      },
      reset: function () {
        locked = false;
        currentStencilMask = null;
        currentStencilFunc = null;
        currentStencilRef = null;
        currentStencilFuncMask = null;
        currentStencilFail = null;
        currentStencilZFail = null;
        currentStencilZPass = null;
        currentStencilClear = null;
      }
    };
  }

  //

  const colorBuffer = new ColorBuffer();
  const depthBuffer = new DepthBuffer();
  const stencilBuffer = new StencilBuffer();
  const uboBindings = new WeakMap();
  const uboProgramMap = new WeakMap();
  let enabledCapabilities = {};
  let currentBoundFramebuffers = {};
  let currentDrawbuffers = new WeakMap();
  let defaultDrawbuffers = [];
  let currentProgram = null;
  let currentBlendingEnabled = false;
  let currentBlending = null;
  let currentBlendEquation = null;
  let currentBlendSrc = null;
  let currentBlendDst = null;
  let currentBlendEquationAlpha = null;
  let currentBlendSrcAlpha = null;
  let currentBlendDstAlpha = null;
  let currentBlendColor = new Color(0, 0, 0);
  let currentBlendAlpha = 0;
  let currentPremultipledAlpha = false;
  let currentFlipSided = null;
  let currentCullFace = null;
  let currentLineWidth = null;
  let currentPolygonOffsetFactor = null;
  let currentPolygonOffsetUnits = null;
  const maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);
  let lineWidthAvailable = false;
  let version = 0;
  const glVersion = gl.getParameter(gl.VERSION);
  if (glVersion.indexOf('WebGL') !== -1) {
    version = parseFloat(/^WebGL (\d)/.exec(glVersion)[1]);
    lineWidthAvailable = version >= 1.0;
  } else if (glVersion.indexOf('OpenGL ES') !== -1) {
    version = parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1]);
    lineWidthAvailable = version >= 2.0;
  }
  let currentTextureSlot = null;
  let currentBoundTextures = {};
  const scissorParam = gl.getParameter(gl.SCISSOR_BOX);
  const viewportParam = gl.getParameter(gl.VIEWPORT);
  const currentScissor = new Vector4().fromArray(scissorParam);
  const currentViewport = new Vector4().fromArray(viewportParam);
  function createTexture(type, target, count, dimensions) {
    const data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    const texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (let i = 0; i < count; i++) {
      if (type === gl.TEXTURE_3D || type === gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }
  const emptyTextures = {};
  emptyTextures[gl.TEXTURE_2D] = createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
  emptyTextures[gl.TEXTURE_CUBE_MAP] = createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
  emptyTextures[gl.TEXTURE_2D_ARRAY] = createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
  emptyTextures[gl.TEXTURE_3D] = createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

  // init

  colorBuffer.setClear(0, 0, 0, 1);
  depthBuffer.setClear(1);
  stencilBuffer.setClear(0);
  enable(gl.DEPTH_TEST);
  depthBuffer.setFunc(LessEqualDepth);
  setFlipSided(false);
  setCullFace(CullFaceBack);
  enable(gl.CULL_FACE);
  setBlending(NoBlending);

  //

  function enable(id) {
    if (enabledCapabilities[id] !== true) {
      gl.enable(id);
      enabledCapabilities[id] = true;
    }
  }
  function disable(id) {
    if (enabledCapabilities[id] !== false) {
      gl.disable(id);
      enabledCapabilities[id] = false;
    }
  }
  function bindFramebuffer(target, framebuffer) {
    if (currentBoundFramebuffers[target] !== framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      currentBoundFramebuffers[target] = framebuffer;

      // gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

      if (target === gl.DRAW_FRAMEBUFFER) {
        currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
      }
      if (target === gl.FRAMEBUFFER) {
        currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
      }
      return true;
    }
    return false;
  }
  function drawBuffers(renderTarget, framebuffer) {
    let drawBuffers = defaultDrawbuffers;
    let needsUpdate = false;
    if (renderTarget) {
      drawBuffers = currentDrawbuffers.get(framebuffer);
      if (drawBuffers === undefined) {
        drawBuffers = [];
        currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      const textures = renderTarget.textures;
      if (drawBuffers.length !== textures.length || drawBuffers[0] !== gl.COLOR_ATTACHMENT0) {
        for (let i = 0, il = textures.length; i < il; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] !== gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }
  function useProgram(program) {
    if (currentProgram !== program) {
      gl.useProgram(program);
      currentProgram = program;
      return true;
    }
    return false;
  }
  const equationToGL = {
    [AddEquation]: gl.FUNC_ADD,
    [SubtractEquation]: gl.FUNC_SUBTRACT,
    [ReverseSubtractEquation]: gl.FUNC_REVERSE_SUBTRACT
  };
  equationToGL[MinEquation] = gl.MIN;
  equationToGL[MaxEquation] = gl.MAX;
  const factorToGL = {
    [ZeroFactor]: gl.ZERO,
    [OneFactor]: gl.ONE,
    [SrcColorFactor]: gl.SRC_COLOR,
    [SrcAlphaFactor]: gl.SRC_ALPHA,
    [SrcAlphaSaturateFactor]: gl.SRC_ALPHA_SATURATE,
    [DstColorFactor]: gl.DST_COLOR,
    [DstAlphaFactor]: gl.DST_ALPHA,
    [OneMinusSrcColorFactor]: gl.ONE_MINUS_SRC_COLOR,
    [OneMinusSrcAlphaFactor]: gl.ONE_MINUS_SRC_ALPHA,
    [OneMinusDstColorFactor]: gl.ONE_MINUS_DST_COLOR,
    [OneMinusDstAlphaFactor]: gl.ONE_MINUS_DST_ALPHA,
    [ConstantColorFactor]: gl.CONSTANT_COLOR,
    [OneMinusConstantColorFactor]: gl.ONE_MINUS_CONSTANT_COLOR,
    [ConstantAlphaFactor]: gl.CONSTANT_ALPHA,
    [OneMinusConstantAlphaFactor]: gl.ONE_MINUS_CONSTANT_ALPHA
  };
  function setBlending(blending, blendEquation, blendSrc, blendDst, blendEquationAlpha, blendSrcAlpha, blendDstAlpha, blendColor, blendAlpha, premultipliedAlpha) {
    if (blending === NoBlending) {
      if (currentBlendingEnabled === true) {
        disable(gl.BLEND);
        currentBlendingEnabled = false;
      }
      return;
    }
    if (currentBlendingEnabled === false) {
      enable(gl.BLEND);
      currentBlendingEnabled = true;
    }
    if (blending !== CustomBlending) {
      if (blending !== currentBlending || premultipliedAlpha !== currentPremultipledAlpha) {
        if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          currentBlendEquation = AddEquation;
          currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
              break;
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
              break;
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
              break;
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
              break;
            default:
              console.error('THREE.WebGLState: Invalid blending: ', blending);
              break;
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
              break;
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
              break;
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
              break;
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
              break;
            default:
              console.error('THREE.WebGLState: Invalid blending: ', blending);
              break;
          }
        }
        currentBlendSrc = null;
        currentBlendDst = null;
        currentBlendSrcAlpha = null;
        currentBlendDstAlpha = null;
        currentBlendColor.set(0, 0, 0);
        currentBlendAlpha = 0;
        currentBlending = blending;
        currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }

    // custom blending

    blendEquationAlpha = blendEquationAlpha || blendEquation;
    blendSrcAlpha = blendSrcAlpha || blendSrc;
    blendDstAlpha = blendDstAlpha || blendDst;
    if (blendEquation !== currentBlendEquation || blendEquationAlpha !== currentBlendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      currentBlendEquation = blendEquation;
      currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (blendSrc !== currentBlendSrc || blendDst !== currentBlendDst || blendSrcAlpha !== currentBlendSrcAlpha || blendDstAlpha !== currentBlendDstAlpha) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      currentBlendSrc = blendSrc;
      currentBlendDst = blendDst;
      currentBlendSrcAlpha = blendSrcAlpha;
      currentBlendDstAlpha = blendDstAlpha;
    }
    if (blendColor.equals(currentBlendColor) === false || blendAlpha !== currentBlendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      currentBlendColor.copy(blendColor);
      currentBlendAlpha = blendAlpha;
    }
    currentBlending = blending;
    currentPremultipledAlpha = false;
  }
  function setMaterial(material, frontFaceCW) {
    material.side === DoubleSide ? disable(gl.CULL_FACE) : enable(gl.CULL_FACE);
    let flipSided = material.side === BackSide;
    if (frontFaceCW) flipSided = !flipSided;
    setFlipSided(flipSided);
    material.blending === NormalBlending && material.transparent === false ? setBlending(NoBlending) : setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);
    depthBuffer.setFunc(material.depthFunc);
    depthBuffer.setTest(material.depthTest);
    depthBuffer.setMask(material.depthWrite);
    colorBuffer.setMask(material.colorWrite);
    const stencilWrite = material.stencilWrite;
    stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      stencilBuffer.setMask(material.stencilWriteMask);
      stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    material.alphaToCoverage === true ? enable(gl.SAMPLE_ALPHA_TO_COVERAGE) : disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
  }

  //

  function setFlipSided(flipSided) {
    if (currentFlipSided !== flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      currentFlipSided = flipSided;
    }
  }
  function setCullFace(cullFace) {
    if (cullFace !== CullFaceNone) {
      enable(gl.CULL_FACE);
      if (cullFace !== currentCullFace) {
        if (cullFace === CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace === CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      disable(gl.CULL_FACE);
    }
    currentCullFace = cullFace;
  }
  function setLineWidth(width) {
    if (width !== currentLineWidth) {
      if (lineWidthAvailable) gl.lineWidth(width);
      currentLineWidth = width;
    }
  }
  function setPolygonOffset(polygonOffset, factor, units) {
    if (polygonOffset) {
      enable(gl.POLYGON_OFFSET_FILL);
      if (currentPolygonOffsetFactor !== factor || currentPolygonOffsetUnits !== units) {
        gl.polygonOffset(factor, units);
        currentPolygonOffsetFactor = factor;
        currentPolygonOffsetUnits = units;
      }
    } else {
      disable(gl.POLYGON_OFFSET_FILL);
    }
  }
  function setScissorTest(scissorTest) {
    if (scissorTest) {
      enable(gl.SCISSOR_TEST);
    } else {
      disable(gl.SCISSOR_TEST);
    }
  }

  // texture

  function activeTexture(webglSlot) {
    if (webglSlot === undefined) webglSlot = gl.TEXTURE0 + maxTextures - 1;
    if (currentTextureSlot !== webglSlot) {
      gl.activeTexture(webglSlot);
      currentTextureSlot = webglSlot;
    }
  }
  function bindTexture(webglType, webglTexture, webglSlot) {
    if (webglSlot === undefined) {
      if (currentTextureSlot === null) {
        webglSlot = gl.TEXTURE0 + maxTextures - 1;
      } else {
        webglSlot = currentTextureSlot;
      }
    }
    let boundTexture = currentBoundTextures[webglSlot];
    if (boundTexture === undefined) {
      boundTexture = {
        type: undefined,
        texture: undefined
      };
      currentBoundTextures[webglSlot] = boundTexture;
    }
    if (boundTexture.type !== webglType || boundTexture.texture !== webglTexture) {
      if (currentTextureSlot !== webglSlot) {
        gl.activeTexture(webglSlot);
        currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture || emptyTextures[webglType]);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }
  function unbindTexture() {
    const boundTexture = currentBoundTextures[currentTextureSlot];
    if (boundTexture !== undefined && boundTexture.type !== undefined) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = undefined;
      boundTexture.texture = undefined;
    }
  }
  function compressedTexImage2D() {
    try {
      gl.compressedTexImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function compressedTexImage3D() {
    try {
      gl.compressedTexImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texSubImage2D() {
    try {
      gl.texSubImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texSubImage3D() {
    try {
      gl.texSubImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function compressedTexSubImage2D() {
    try {
      gl.compressedTexSubImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function compressedTexSubImage3D() {
    try {
      gl.compressedTexSubImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texStorage2D() {
    try {
      gl.texStorage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texStorage3D() {
    try {
      gl.texStorage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texImage2D() {
    try {
      gl.texImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texImage3D() {
    try {
      gl.texImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }

  //

  function scissor(scissor) {
    if (currentScissor.equals(scissor) === false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      currentScissor.copy(scissor);
    }
  }
  function viewport(viewport) {
    if (currentViewport.equals(viewport) === false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      currentViewport.copy(viewport);
    }
  }
  function updateUBOMapping(uniformsGroup, program) {
    let mapping = uboProgramMap.get(program);
    if (mapping === undefined) {
      mapping = new WeakMap();
      uboProgramMap.set(program, mapping);
    }
    let blockIndex = mapping.get(uniformsGroup);
    if (blockIndex === undefined) {
      blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);
      mapping.set(uniformsGroup, blockIndex);
    }
  }
  function uniformBlockBinding(uniformsGroup, program) {
    const mapping = uboProgramMap.get(program);
    const blockIndex = mapping.get(uniformsGroup);
    if (uboBindings.get(program) !== blockIndex) {
      // bind shader specific block index to global block point
      gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);
      uboBindings.set(program, blockIndex);
    }
  }

  //

  function reset() {
    // reset state

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

    // reset internals

    enabledCapabilities = {};
    currentTextureSlot = null;
    currentBoundTextures = {};
    currentBoundFramebuffers = {};
    currentDrawbuffers = new WeakMap();
    defaultDrawbuffers = [];
    currentProgram = null;
    currentBlendingEnabled = false;
    currentBlending = null;
    currentBlendEquation = null;
    currentBlendSrc = null;
    currentBlendDst = null;
    currentBlendEquationAlpha = null;
    currentBlendSrcAlpha = null;
    currentBlendDstAlpha = null;
    currentBlendColor = new Color(0, 0, 0);
    currentBlendAlpha = 0;
    currentPremultipledAlpha = false;
    currentFlipSided = null;
    currentCullFace = null;
    currentLineWidth = null;
    currentPolygonOffsetFactor = null;
    currentPolygonOffsetUnits = null;
    currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    colorBuffer.reset();
    depthBuffer.reset();
    stencilBuffer.reset();
  }
  return {
    buffers: {
      color: colorBuffer,
      depth: depthBuffer,
      stencil: stencilBuffer
    },
    enable: enable,
    disable: disable,
    bindFramebuffer: bindFramebuffer,
    drawBuffers: drawBuffers,
    useProgram: useProgram,
    setBlending: setBlending,
    setMaterial: setMaterial,
    setFlipSided: setFlipSided,
    setCullFace: setCullFace,
    setLineWidth: setLineWidth,
    setPolygonOffset: setPolygonOffset,
    setScissorTest: setScissorTest,
    activeTexture: activeTexture,
    bindTexture: bindTexture,
    unbindTexture: unbindTexture,
    compressedTexImage2D: compressedTexImage2D,
    compressedTexImage3D: compressedTexImage3D,
    texImage2D: texImage2D,
    texImage3D: texImage3D,
    updateUBOMapping: updateUBOMapping,
    uniformBlockBinding: uniformBlockBinding,
    texStorage2D: texStorage2D,
    texStorage3D: texStorage3D,
    texSubImage2D: texSubImage2D,
    texSubImage3D: texSubImage3D,
    compressedTexSubImage2D: compressedTexSubImage2D,
    compressedTexSubImage3D: compressedTexSubImage3D,
    scissor: scissor,
    viewport: viewport,
    reset: reset
  };
}
function ColorBuffer() {
  let locked = false;
  const color = new Vector4();
  let currentColorMask = null;
  const currentColorClear = new Vector4(0, 0, 0, 0);
  return {
    setMask: function (colorMask) {
      if (currentColorMask !== colorMask && !locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        currentColorMask = colorMask;
      }
    },
    setLocked: function (lock) {
      locked = lock;
    },
    setClear: function (r, g, b, a, premultipliedAlpha) {
      if (premultipliedAlpha === true) {
        r *= a;
        g *= a;
        b *= a;
      }
      color.set(r, g, b, a);
      if (currentColorClear.equals(color) === false) {
        gl.clearColor(r, g, b, a);
        currentColorClear.copy(color);
      }
    },
    reset: function () {
      locked = false;
      currentColorMask = null;
      currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  };
}
function (colorMask) {
  if (currentColorMask !== colorMask && !locked) {
    gl.colorMask(colorMask, colorMask, colorMask, colorMask);
    currentColorMask = colorMask;
  }
}
colorMask
{
  if (currentColorMask !== colorMask && !locked) {
    gl.colorMask(colorMask, colorMask, colorMask, colorMask);
    currentColorMask = colorMask;
  }
}
if (currentColorMask !== colorMask && !locked) {
  gl.colorMask(colorMask, colorMask, colorMask, colorMask);
  currentColorMask = colorMask;
}
currentColorMask !== colorMask && !locked
currentColorMask !== colorMask
currentColorMask
colorMask
!locked
locked
{
  gl.colorMask(colorMask, colorMask, colorMask, colorMask);
  currentColorMask = colorMask;
}
gl.colorMask(colorMask, colorMask, colorMask, colorMask);
gl.colorMask(colorMask, colorMask, colorMask, colorMask)
gl.colorMask
gl
colorMask
colorMask
colorMask
colorMask
colorMask
currentColorMask = colorMask;
currentColorMask = colorMask
currentColorMask
colorMask
setLocked: function (lock) {
  locked = lock;
}
setLocked
function (lock) {
  locked = lock;
}
function (lock) {
  locked = lock;
}
lock
{
  locked = lock;
}
locked = lock;
locked = lock
locked
lock
setClear: function (r, g, b, a, premultipliedAlpha) {
  if (premultipliedAlpha === true) {
    r *= a;
    g *= a;
    b *= a;
  }
  color.set(r, g, b, a);
  if (currentColorClear.equals(color) === false) {
    gl.clearColor(r, g, b, a);
    currentColorClear.copy(color);
  }
}
setClear
function (r, g, b, a, premultipliedAlpha) {
  if (premultipliedAlpha === true) {
    r *= a;
    g *= a;
    b *= a;
  }
  color.set(r, g, b, a);
  if (currentColorClear.equals(color) === false) {
    gl.clearColor(r, g, b, a);
    currentColorClear.copy(color);
  }
}
function (r, g, b, a, premultipliedAlpha) {
  if (premultipliedAlpha === true) {
    r *= a;
    g *= a;
    b *= a;
  }
  color.set(r, g, b, a);
  if (currentColorClear.equals(color) === false) {
    gl.clearColor(r, g, b, a);
    currentColorClear.copy(color);
  }
}
r
g
b
a
premultipliedAlpha
{
  if (premultipliedAlpha === true) {
    r *= a;
    g *= a;
    b *= a;
  }
  color.set(r, g, b, a);
  if (currentColorClear.equals(color) === false) {
    gl.clearColor(r, g, b, a);
    currentColorClear.copy(color);
  }
}
if (premultipliedAlpha === true) {
  r *= a;
  g *= a;
  b *= a;
}
premultipliedAlpha === true
premultipliedAlpha
true
{
  r *= a;
  g *= a;
  b *= a;
}
r *= a;
r *= a
r
a
g *= a;
g *= a
g
a
b *= a;
b *= a
b
a
color.set(r, g, b, a);
color.set(r, g, b, a)
color.set
color
set
r
g
b
a
if (currentColorClear.equals(color) === false) {
  gl.clearColor(r, g, b, a);
  currentColorClear.copy(color);
}
currentColorClear.equals(color) === false
currentColorClear.equals(color)
currentColorClear.equals
currentColorClear
equals
color
false
{
  gl.clearColor(r, g, b, a);
  currentColorClear.copy(color);
}
gl.clearColor(r, g, b, a);
gl.clearColor(r, g, b, a)
gl.clearColor
gl
clearColor
r
g
b
a
currentColorClear.copy(color);
currentColorClear.copy(color)
currentColorClear.copy
currentColorClear
copy
color
reset: function () {
  locked = false;
  currentColorMask = null;
  currentColorClear.set(-1, 0, 0, 0); // set to invalid state
}
reset
function () {
  locked = false;
  currentColorMask = null;
  currentColorClear.set(-1, 0, 0, 0); // set to invalid state
}
function () {
  locked = false;
  currentColorMask = null;
  currentColorClear.set(-1, 0, 0, 0); // set to invalid state
}
{
  locked = false;
  currentColorMask = null;
  currentColorClear.set(-1, 0, 0, 0); // set to invalid state
}
locked = false;
locked = false
locked
false
currentColorMask = null;
currentColorMask = null
currentColorMask
null
currentColorClear.set(-1, 0, 0, 0); // set to invalid state
currentColorClear.set(-1, 0, 0, 0)
currentColorClear.set
currentColorClear
set
-1
1
0
0
0
function DepthBuffer() {
  let locked = false;
  let currentDepthMask = null;
  let currentDepthFunc = null;
  let currentDepthClear = null;
  return {
    setTest: function (depthTest) {
      if (depthTest) {
        enable(gl.DEPTH_TEST);
      } else {
        disable(gl.DEPTH_TEST);
      }
    },
    setMask: function (depthMask) {
      if (currentDepthMask !== depthMask && !locked) {
        gl.depthMask(depthMask);
        currentDepthMask = depthMask;
      }
    },
    setFunc: function (depthFunc) {
      if (currentDepthFunc !== depthFunc) {
        switch (depthFunc) {
          case NeverDepth:
            gl.depthFunc(gl.NEVER);
            break;
          case AlwaysDepth:
            gl.depthFunc(gl.ALWAYS);
            break;
          case LessDepth:
            gl.depthFunc(gl.LESS);
            break;
          case LessEqualDepth:
            gl.depthFunc(gl.LEQUAL);
            break;
          case EqualDepth:
            gl.depthFunc(gl.EQUAL);
            break;
          case GreaterEqualDepth:
            gl.depthFunc(gl.GEQUAL);
            break;
          case GreaterDepth:
            gl.depthFunc(gl.GREATER);
            break;
          case NotEqualDepth:
            gl.depthFunc(gl.NOTEQUAL);
            break;
          default:
            gl.depthFunc(gl.LEQUAL);
        }
        currentDepthFunc = depthFunc;
      }
    },
    setLocked: function (lock) {
      locked = lock;
    },
    setClear: function (depth) {
      if (currentDepthClear !== depth) {
        gl.clearDepth(depth);
        currentDepthClear = depth;
      }
    },
    reset: function () {
      locked = false;
      currentDepthMask = null;
      currentDepthFunc = null;
      currentDepthClear = null;
    }
  };
}
ColorBuffer
{
  let locked = false;
  const color = new Vector4();
  let currentColorMask = null;
  const currentColorClear = new Vector4(0, 0, 0, 0);
  return {
    setMask: function (colorMask) {
      if (currentColorMask !== colorMask && !locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        currentColorMask = colorMask;
      }
    },
    setLocked: function (lock) {
      locked = lock;
    },
    setClear: function (r, g, b, a, premultipliedAlpha) {
      if (premultipliedAlpha === true) {
        r *= a;
        g *= a;
        b *= a;
      }
      color.set(r, g, b, a);
      if (currentColorClear.equals(color) === false) {
        gl.clearColor(r, g, b, a);
        currentColorClear.copy(color);
      }
    },
    reset: function () {
      locked = false;
      currentColorMask = null;
      currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  };
}
let locked = false;
locked = false
locked
false
const color = new Vector4();
color = new Vector4()
color
new Vector4()
Vector4
let currentColorMask = null;
currentColorMask = null
currentColorMask
null
const currentColorClear = new Vector4(0, 0, 0, 0);
currentColorClear = new Vector4(0, 0, 0, 0)
currentColorClear
new Vector4(0, 0, 0, 0)
Vector4
0
0
0
0
return {
  setMask: function (colorMask) {
    if (currentColorMask !== colorMask && !locked) {
      gl.colorMask(colorMask, colorMask, colorMask, colorMask);
      currentColorMask = colorMask;
    }
  },
  setLocked: function (lock) {
    locked = lock;
  },
  setClear: function (r, g, b, a, premultipliedAlpha) {
    if (premultipliedAlpha === true) {
      r *= a;
      g *= a;
      b *= a;
    }
    color.set(r, g, b, a);
    if (currentColorClear.equals(color) === false) {
      gl.clearColor(r, g, b, a);
      currentColorClear.copy(color);
    }
  },
  reset: function () {
    locked = false;
    currentColorMask = null;
    currentColorClear.set(-1, 0, 0, 0); // set to invalid state
  }
};
{
  setMask: function (colorMask) {
    if (currentColorMask !== colorMask && !locked) {
      gl.colorMask(colorMask, colorMask, colorMask, colorMask);
      currentColorMask = colorMask;
    }
  },
  setLocked: function (lock) {
    locked = lock;
  },
  setClear: function (r, g, b, a, premultipliedAlpha) {
    if (premultipliedAlpha === true) {
      r *= a;
      g *= a;
      b *= a;
    }
    color.set(r, g, b, a);
    if (currentColorClear.equals(color) === false) {
      gl.clearColor(r, g, b, a);
      currentColorClear.copy(color);
    }
  },
  reset: function () {
    locked = false;
    currentColorMask = null;
    currentColorClear.set(-1, 0, 0, 0); // set to invalid state
  }
}
setMask: function (colorMask) {
  if (currentColorMask !== colorMask && !locked) {
    gl.colorMask(colorMask, colorMask, colorMask, colorMask);
    currentColorMask = colorMask;
  }
}
setMask
function (colorMask) {
  if (currentColorMask !== colorMask && !locked) {
    gl.colorMask(colorMask, colorMask, colorMask, colorMask);
    currentColorMask = colorMask;
  }
}
function DepthBuffer() {
  let locked = false;
  let currentDepthMask = null;
  let currentDepthFunc = null;
  let currentDepthClear = null;
  return {
    setTest: function (depthTest) {
      if (depthTest) {
        enable(gl.DEPTH_TEST);
      } else {
        disable(gl.DEPTH_TEST);
      }
    },
    setMask: function (depthMask) {
      if (currentDepthMask !== depthMask && !locked) {
        gl.depthMask(depthMask);
        currentDepthMask = depthMask;
      }
    },
    setFunc: function (depthFunc) {
      if (currentDepthFunc !== depthFunc) {
        switch (depthFunc) {
          case NeverDepth:
            gl.depthFunc(gl.NEVER);
            break;
          case AlwaysDepth:
            gl.depthFunc(gl.ALWAYS);
            break;
          case LessDepth:
            gl.depthFunc(gl.LESS);
            break;
          case LessEqualDepth:
            gl.depthFunc(gl.LEQUAL);
            break;
          case EqualDepth:
            gl.depthFunc(gl.EQUAL);
            break;
          case GreaterEqualDepth:
            gl.depthFunc(gl.GEQUAL);
            break;
          case GreaterDepth:
            gl.depthFunc(gl.GREATER);
            break;
          case NotEqualDepth:
            gl.depthFunc(gl.NOTEQUAL);
            break;
          default:
            gl.depthFunc(gl.LEQUAL);
        }
        currentDepthFunc = depthFunc;
      }
    },
    setLocked: function (lock) {
      locked = lock;
    },
    setClear: function (depth) {
      if (currentDepthClear !== depth) {
        gl.clearDepth(depth);
        currentDepthClear = depth;
      }
    },
    reset: function () {
      locked = false;
      currentDepthMask = null;
      currentDepthFunc = null;
      currentDepthClear = null;
    }
  };
}
function (depthTest) {
  if (depthTest) {
    enable(gl.DEPTH_TEST);
  } else {
    disable(gl.DEPTH_TEST);
  }
}
depthTest
{
  if (depthTest) {
    enable(gl.DEPTH_TEST);
  } else {
    disable(gl.DEPTH_TEST);
  }
}
if (depthTest) {
  enable(gl.DEPTH_TEST);
} else {
  disable(gl.DEPTH_TEST);
}
depthTest
{
  enable(gl.DEPTH_TEST);
}
enable(gl.DEPTH_TEST);
enable(gl.DEPTH_TEST)
enable
gl.DEPTH_TEST
gl
DEPTH_TEST
{
  disable(gl.DEPTH_TEST);
}
disable(gl.DEPTH_TEST);
disable(gl.DEPTH_TEST)
disable
gl.DEPTH_TEST
gl
DEPTH_TEST
setMask: function (depthMask) {
  if (currentDepthMask !== depthMask && !locked) {
    gl.depthMask(depthMask);
    currentDepthMask = depthMask;
  }
}
setMask
function (depthMask) {
  if (currentDepthMask !== depthMask && !locked) {
    gl.depthMask(depthMask);
    currentDepthMask = depthMask;
  }
}
function (depthMask) {
  if (currentDepthMask !== depthMask && !locked) {
    gl.depthMask(depthMask);
    currentDepthMask = depthMask;
  }
}
depthMask
{
  if (currentDepthMask !== depthMask && !locked) {
    gl.depthMask(depthMask);
    currentDepthMask = depthMask;
  }
}
if (currentDepthMask !== depthMask && !locked) {
  gl.depthMask(depthMask);
  currentDepthMask = depthMask;
}
currentDepthMask !== depthMask && !locked
currentDepthMask !== depthMask
currentDepthMask
depthMask
!locked
locked
{
  gl.depthMask(depthMask);
  currentDepthMask = depthMask;
}
gl.depthMask(depthMask);
gl.depthMask(depthMask)
gl.depthMask
gl
depthMask
depthMask
currentDepthMask = depthMask;
currentDepthMask = depthMask
currentDepthMask
depthMask
setFunc: function (depthFunc) {
  if (currentDepthFunc !== depthFunc) {
    switch (depthFunc) {
      case NeverDepth:
        gl.depthFunc(gl.NEVER);
        break;
      case AlwaysDepth:
        gl.depthFunc(gl.ALWAYS);
        break;
      case LessDepth:
        gl.depthFunc(gl.LESS);
        break;
      case LessEqualDepth:
        gl.depthFunc(gl.LEQUAL);
        break;
      case EqualDepth:
        gl.depthFunc(gl.EQUAL);
        break;
      case GreaterEqualDepth:
        gl.depthFunc(gl.GEQUAL);
        break;
      case GreaterDepth:
        gl.depthFunc(gl.GREATER);
        break;
      case NotEqualDepth:
        gl.depthFunc(gl.NOTEQUAL);
        break;
      default:
        gl.depthFunc(gl.LEQUAL);
    }
    currentDepthFunc = depthFunc;
  }
}
setFunc
function (depthFunc) {
  if (currentDepthFunc !== depthFunc) {
    switch (depthFunc) {
      case NeverDepth:
        gl.depthFunc(gl.NEVER);
        break;
      case AlwaysDepth:
        gl.depthFunc(gl.ALWAYS);
        break;
      case LessDepth:
        gl.depthFunc(gl.LESS);
        break;
      case LessEqualDepth:
        gl.depthFunc(gl.LEQUAL);
        break;
      case EqualDepth:
        gl.depthFunc(gl.EQUAL);
        break;
      case GreaterEqualDepth:
        gl.depthFunc(gl.GEQUAL);
        break;
      case GreaterDepth:
        gl.depthFunc(gl.GREATER);
        break;
      case NotEqualDepth:
        gl.depthFunc(gl.NOTEQUAL);
        break;
      default:
        gl.depthFunc(gl.LEQUAL);
    }
    currentDepthFunc = depthFunc;
  }
}
function (depthFunc) {
  if (currentDepthFunc !== depthFunc) {
    switch (depthFunc) {
      case NeverDepth:
        gl.depthFunc(gl.NEVER);
        break;
      case AlwaysDepth:
        gl.depthFunc(gl.ALWAYS);
        break;
      case LessDepth:
        gl.depthFunc(gl.LESS);
        break;
      case LessEqualDepth:
        gl.depthFunc(gl.LEQUAL);
        break;
      case EqualDepth:
        gl.depthFunc(gl.EQUAL);
        break;
      case GreaterEqualDepth:
        gl.depthFunc(gl.GEQUAL);
        break;
      case GreaterDepth:
        gl.depthFunc(gl.GREATER);
        break;
      case NotEqualDepth:
        gl.depthFunc(gl.NOTEQUAL);
        break;
      default:
        gl.depthFunc(gl.LEQUAL);
    }
    currentDepthFunc = depthFunc;
  }
}
depthFunc
{
  if (currentDepthFunc !== depthFunc) {
    switch (depthFunc) {
      case NeverDepth:
        gl.depthFunc(gl.NEVER);
        break;
      case AlwaysDepth:
        gl.depthFunc(gl.ALWAYS);
        break;
      case LessDepth:
        gl.depthFunc(gl.LESS);
        break;
      case LessEqualDepth:
        gl.depthFunc(gl.LEQUAL);
        break;
      case EqualDepth:
        gl.depthFunc(gl.EQUAL);
        break;
      case GreaterEqualDepth:
        gl.depthFunc(gl.GEQUAL);
        break;
      case GreaterDepth:
        gl.depthFunc(gl.GREATER);
        break;
      case NotEqualDepth:
        gl.depthFunc(gl.NOTEQUAL);
        break;
      default:
        gl.depthFunc(gl.LEQUAL);
    }
    currentDepthFunc = depthFunc;
  }
}
if (currentDepthFunc !== depthFunc) {
  switch (depthFunc) {
    case NeverDepth:
      gl.depthFunc(gl.NEVER);
      break;
    case AlwaysDepth:
      gl.depthFunc(gl.ALWAYS);
      break;
    case LessDepth:
      gl.depthFunc(gl.LESS);
      break;
    case LessEqualDepth:
      gl.depthFunc(gl.LEQUAL);
      break;
    case EqualDepth:
      gl.depthFunc(gl.EQUAL);
      break;
    case GreaterEqualDepth:
      gl.depthFunc(gl.GEQUAL);
      break;
    case GreaterDepth:
      gl.depthFunc(gl.GREATER);
      break;
    case NotEqualDepth:
      gl.depthFunc(gl.NOTEQUAL);
      break;
    default:
      gl.depthFunc(gl.LEQUAL);
  }
  currentDepthFunc = depthFunc;
}
currentDepthFunc !== depthFunc
currentDepthFunc
depthFunc
{
  switch (depthFunc) {
    case NeverDepth:
      gl.depthFunc(gl.NEVER);
      break;
    case AlwaysDepth:
      gl.depthFunc(gl.ALWAYS);
      break;
    case LessDepth:
      gl.depthFunc(gl.LESS);
      break;
    case LessEqualDepth:
      gl.depthFunc(gl.LEQUAL);
      break;
    case EqualDepth:
      gl.depthFunc(gl.EQUAL);
      break;
    case GreaterEqualDepth:
      gl.depthFunc(gl.GEQUAL);
      break;
    case GreaterDepth:
      gl.depthFunc(gl.GREATER);
      break;
    case NotEqualDepth:
      gl.depthFunc(gl.NOTEQUAL);
      break;
    default:
      gl.depthFunc(gl.LEQUAL);
  }
  currentDepthFunc = depthFunc;
}
switch (depthFunc) {
  case NeverDepth:
    gl.depthFunc(gl.NEVER);
    break;
  case AlwaysDepth:
    gl.depthFunc(gl.ALWAYS);
    break;
  case LessDepth:
    gl.depthFunc(gl.LESS);
    break;
  case LessEqualDepth:
    gl.depthFunc(gl.LEQUAL);
    break;
  case EqualDepth:
    gl.depthFunc(gl.EQUAL);
    break;
  case GreaterEqualDepth:
    gl.depthFunc(gl.GEQUAL);
    break;
  case GreaterDepth:
    gl.depthFunc(gl.GREATER);
    break;
  case NotEqualDepth:
    gl.depthFunc(gl.NOTEQUAL);
    break;
  default:
    gl.depthFunc(gl.LEQUAL);
}
depthFunc
case NeverDepth:
  gl.depthFunc(gl.NEVER);
  break;
NeverDepth
gl.depthFunc(gl.NEVER);
gl.depthFunc(gl.NEVER)
gl.depthFunc
gl
depthFunc
gl.NEVER
gl
NEVER
break;
case AlwaysDepth:
  gl.depthFunc(gl.ALWAYS);
  break;
AlwaysDepth
gl.depthFunc(gl.ALWAYS);
gl.depthFunc(gl.ALWAYS)
gl.depthFunc
gl
depthFunc
gl.ALWAYS
gl
ALWAYS
break;
case LessDepth:
  gl.depthFunc(gl.LESS);
  break;
LessDepth
gl.depthFunc(gl.LESS);
gl.depthFunc(gl.LESS)
gl.depthFunc
gl
depthFunc
gl.LESS
gl
LESS
break;
case LessEqualDepth:
  gl.depthFunc(gl.LEQUAL);
  break;
LessEqualDepth
gl.depthFunc(gl.LEQUAL);
gl.depthFunc(gl.LEQUAL)
gl.depthFunc
gl
depthFunc
gl.LEQUAL
gl
LEQUAL
break;
case EqualDepth:
  gl.depthFunc(gl.EQUAL);
  break;
EqualDepth
gl.depthFunc(gl.EQUAL);
gl.depthFunc(gl.EQUAL)
gl.depthFunc
gl
depthFunc
gl.EQUAL
gl
EQUAL
break;
case GreaterEqualDepth:
  gl.depthFunc(gl.GEQUAL);
  break;
GreaterEqualDepth
gl.depthFunc(gl.GEQUAL);
gl.depthFunc(gl.GEQUAL)
gl.depthFunc
gl
depthFunc
gl.GEQUAL
gl
GEQUAL
break;
case GreaterDepth:
  gl.depthFunc(gl.GREATER);
  break;
GreaterDepth
gl.depthFunc(gl.GREATER);
gl.depthFunc(gl.GREATER)
gl.depthFunc
gl
depthFunc
gl.GREATER
gl
GREATER
break;
case NotEqualDepth:
  gl.depthFunc(gl.NOTEQUAL);
  break;
NotEqualDepth
gl.depthFunc(gl.NOTEQUAL);
gl.depthFunc(gl.NOTEQUAL)
gl.depthFunc
gl
depthFunc
gl.NOTEQUAL
gl
NOTEQUAL
break;
default:
  gl.depthFunc(gl.LEQUAL);
gl.depthFunc(gl.LEQUAL);
gl.depthFunc(gl.LEQUAL)
gl.depthFunc
gl
depthFunc
gl.LEQUAL
gl
LEQUAL
currentDepthFunc = depthFunc;
currentDepthFunc = depthFunc
currentDepthFunc
depthFunc
setLocked: function (lock) {
  locked = lock;
}
setLocked
function (lock) {
  locked = lock;
}
function (lock) {
  locked = lock;
}
lock
{
  locked = lock;
}
locked = lock;
locked = lock
locked
lock
setClear: function (depth) {
  if (currentDepthClear !== depth) {
    gl.clearDepth(depth);
    currentDepthClear = depth;
  }
}
setClear
function (depth) {
  if (currentDepthClear !== depth) {
    gl.clearDepth(depth);
    currentDepthClear = depth;
  }
}
function (depth) {
  if (currentDepthClear !== depth) {
    gl.clearDepth(depth);
    currentDepthClear = depth;
  }
}
depth
{
  if (currentDepthClear !== depth) {
    gl.clearDepth(depth);
    currentDepthClear = depth;
  }
}
if (currentDepthClear !== depth) {
  gl.clearDepth(depth);
  currentDepthClear = depth;
}
currentDepthClear !== depth
currentDepthClear
depth
{
  gl.clearDepth(depth);
  currentDepthClear = depth;
}
gl.clearDepth(depth);
gl.clearDepth(depth)
gl.clearDepth
gl
clearDepth
depth
currentDepthClear = depth;
currentDepthClear = depth
currentDepthClear
depth
reset: function () {
  locked = false;
  currentDepthMask = null;
  currentDepthFunc = null;
  currentDepthClear = null;
}
reset
function () {
  locked = false;
  currentDepthMask = null;
  currentDepthFunc = null;
  currentDepthClear = null;
}
function () {
  locked = false;
  currentDepthMask = null;
  currentDepthFunc = null;
  currentDepthClear = null;
}
{
  locked = false;
  currentDepthMask = null;
  currentDepthFunc = null;
  currentDepthClear = null;
}
locked = false;
locked = false
locked
false
currentDepthMask = null;
currentDepthMask = null
currentDepthMask
null
currentDepthFunc = null;
currentDepthFunc = null
currentDepthFunc
null
currentDepthClear = null;
currentDepthClear = null
currentDepthClear
null
function StencilBuffer() {
  let locked = false;
  let currentStencilMask = null;
  let currentStencilFunc = null;
  let currentStencilRef = null;
  let currentStencilFuncMask = null;
  let currentStencilFail = null;
  let currentStencilZFail = null;
  let currentStencilZPass = null;
  let currentStencilClear = null;
  return {
    setTest: function (stencilTest) {
      if (!locked) {
        if (stencilTest) {
          enable(gl.STENCIL_TEST);
        } else {
          disable(gl.STENCIL_TEST);
        }
      }
    },
    setMask: function (stencilMask) {
      if (currentStencilMask !== stencilMask && !locked) {
        gl.stencilMask(stencilMask);
        currentStencilMask = stencilMask;
      }
    },
    setFunc: function (stencilFunc, stencilRef, stencilMask) {
      if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
        gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
        currentStencilFunc = stencilFunc;
        currentStencilRef = stencilRef;
        currentStencilFuncMask = stencilMask;
      }
    },
    setOp: function (stencilFail, stencilZFail, stencilZPass) {
      if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
        gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
        currentStencilFail = stencilFail;
        currentStencilZFail = stencilZFail;
        currentStencilZPass = stencilZPass;
      }
    },
    setLocked: function (lock) {
      locked = lock;
    },
    setClear: function (stencil) {
      if (currentStencilClear !== stencil) {
        gl.clearStencil(stencil);
        currentStencilClear = stencil;
      }
    },
    reset: function () {
      locked = false;
      currentStencilMask = null;
      currentStencilFunc = null;
      currentStencilRef = null;
      currentStencilFuncMask = null;
      currentStencilFail = null;
      currentStencilZFail = null;
      currentStencilZPass = null;
      currentStencilClear = null;
    }
  };
}

//
DepthBuffer
{
  let locked = false;
  let currentDepthMask = null;
  let currentDepthFunc = null;
  let currentDepthClear = null;
  return {
    setTest: function (depthTest) {
      if (depthTest) {
        enable(gl.DEPTH_TEST);
      } else {
        disable(gl.DEPTH_TEST);
      }
    },
    setMask: function (depthMask) {
      if (currentDepthMask !== depthMask && !locked) {
        gl.depthMask(depthMask);
        currentDepthMask = depthMask;
      }
    },
    setFunc: function (depthFunc) {
      if (currentDepthFunc !== depthFunc) {
        switch (depthFunc) {
          case NeverDepth:
            gl.depthFunc(gl.NEVER);
            break;
          case AlwaysDepth:
            gl.depthFunc(gl.ALWAYS);
            break;
          case LessDepth:
            gl.depthFunc(gl.LESS);
            break;
          case LessEqualDepth:
            gl.depthFunc(gl.LEQUAL);
            break;
          case EqualDepth:
            gl.depthFunc(gl.EQUAL);
            break;
          case GreaterEqualDepth:
            gl.depthFunc(gl.GEQUAL);
            break;
          case GreaterDepth:
            gl.depthFunc(gl.GREATER);
            break;
          case NotEqualDepth:
            gl.depthFunc(gl.NOTEQUAL);
            break;
          default:
            gl.depthFunc(gl.LEQUAL);
        }
        currentDepthFunc = depthFunc;
      }
    },
    setLocked: function (lock) {
      locked = lock;
    },
    setClear: function (depth) {
      if (currentDepthClear !== depth) {
        gl.clearDepth(depth);
        currentDepthClear = depth;
      }
    },
    reset: function () {
      locked = false;
      currentDepthMask = null;
      currentDepthFunc = null;
      currentDepthClear = null;
    }
  };
}
let locked = false;
locked = false
locked
false
let currentDepthMask = null;
currentDepthMask = null
currentDepthMask
null
let currentDepthFunc = null;
currentDepthFunc = null
currentDepthFunc
null
let currentDepthClear = null;
currentDepthClear = null
currentDepthClear
null
return {
  setTest: function (depthTest) {
    if (depthTest) {
      enable(gl.DEPTH_TEST);
    } else {
      disable(gl.DEPTH_TEST);
    }
  },
  setMask: function (depthMask) {
    if (currentDepthMask !== depthMask && !locked) {
      gl.depthMask(depthMask);
      currentDepthMask = depthMask;
    }
  },
  setFunc: function (depthFunc) {
    if (currentDepthFunc !== depthFunc) {
      switch (depthFunc) {
        case NeverDepth:
          gl.depthFunc(gl.NEVER);
          break;
        case AlwaysDepth:
          gl.depthFunc(gl.ALWAYS);
          break;
        case LessDepth:
          gl.depthFunc(gl.LESS);
          break;
        case LessEqualDepth:
          gl.depthFunc(gl.LEQUAL);
          break;
        case EqualDepth:
          gl.depthFunc(gl.EQUAL);
          break;
        case GreaterEqualDepth:
          gl.depthFunc(gl.GEQUAL);
          break;
        case GreaterDepth:
          gl.depthFunc(gl.GREATER);
          break;
        case NotEqualDepth:
          gl.depthFunc(gl.NOTEQUAL);
          break;
        default:
          gl.depthFunc(gl.LEQUAL);
      }
      currentDepthFunc = depthFunc;
    }
  },
  setLocked: function (lock) {
    locked = lock;
  },
  setClear: function (depth) {
    if (currentDepthClear !== depth) {
      gl.clearDepth(depth);
      currentDepthClear = depth;
    }
  },
  reset: function () {
    locked = false;
    currentDepthMask = null;
    currentDepthFunc = null;
    currentDepthClear = null;
  }
};
{
  setTest: function (depthTest) {
    if (depthTest) {
      enable(gl.DEPTH_TEST);
    } else {
      disable(gl.DEPTH_TEST);
    }
  },
  setMask: function (depthMask) {
    if (currentDepthMask !== depthMask && !locked) {
      gl.depthMask(depthMask);
      currentDepthMask = depthMask;
    }
  },
  setFunc: function (depthFunc) {
    if (currentDepthFunc !== depthFunc) {
      switch (depthFunc) {
        case NeverDepth:
          gl.depthFunc(gl.NEVER);
          break;
        case AlwaysDepth:
          gl.depthFunc(gl.ALWAYS);
          break;
        case LessDepth:
          gl.depthFunc(gl.LESS);
          break;
        case LessEqualDepth:
          gl.depthFunc(gl.LEQUAL);
          break;
        case EqualDepth:
          gl.depthFunc(gl.EQUAL);
          break;
        case GreaterEqualDepth:
          gl.depthFunc(gl.GEQUAL);
          break;
        case GreaterDepth:
          gl.depthFunc(gl.GREATER);
          break;
        case NotEqualDepth:
          gl.depthFunc(gl.NOTEQUAL);
          break;
        default:
          gl.depthFunc(gl.LEQUAL);
      }
      currentDepthFunc = depthFunc;
    }
  },
  setLocked: function (lock) {
    locked = lock;
  },
  setClear: function (depth) {
    if (currentDepthClear !== depth) {
      gl.clearDepth(depth);
      currentDepthClear = depth;
    }
  },
  reset: function () {
    locked = false;
    currentDepthMask = null;
    currentDepthFunc = null;
    currentDepthClear = null;
  }
}
setTest: function (depthTest) {
  if (depthTest) {
    enable(gl.DEPTH_TEST);
  } else {
    disable(gl.DEPTH_TEST);
  }
}
setTest
function (depthTest) {
  if (depthTest) {
    enable(gl.DEPTH_TEST);
  } else {
    disable(gl.DEPTH_TEST);
  }
}
function StencilBuffer() {
  let locked = false;
  let currentStencilMask = null;
  let currentStencilFunc = null;
  let currentStencilRef = null;
  let currentStencilFuncMask = null;
  let currentStencilFail = null;
  let currentStencilZFail = null;
  let currentStencilZPass = null;
  let currentStencilClear = null;
  return {
    setTest: function (stencilTest) {
      if (!locked) {
        if (stencilTest) {
          enable(gl.STENCIL_TEST);
        } else {
          disable(gl.STENCIL_TEST);
        }
      }
    },
    setMask: function (stencilMask) {
      if (currentStencilMask !== stencilMask && !locked) {
        gl.stencilMask(stencilMask);
        currentStencilMask = stencilMask;
      }
    },
    setFunc: function (stencilFunc, stencilRef, stencilMask) {
      if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
        gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
        currentStencilFunc = stencilFunc;
        currentStencilRef = stencilRef;
        currentStencilFuncMask = stencilMask;
      }
    },
    setOp: function (stencilFail, stencilZFail, stencilZPass) {
      if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
        gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
        currentStencilFail = stencilFail;
        currentStencilZFail = stencilZFail;
        currentStencilZPass = stencilZPass;
      }
    },
    setLocked: function (lock) {
      locked = lock;
    },
    setClear: function (stencil) {
      if (currentStencilClear !== stencil) {
        gl.clearStencil(stencil);
        currentStencilClear = stencil;
      }
    },
    reset: function () {
      locked = false;
      currentStencilMask = null;
      currentStencilFunc = null;
      currentStencilRef = null;
      currentStencilFuncMask = null;
      currentStencilFail = null;
      currentStencilZFail = null;
      currentStencilZPass = null;
      currentStencilClear = null;
    }
  };
}

//
function (stencilTest) {
  if (!locked) {
    if (stencilTest) {
      enable(gl.STENCIL_TEST);
    } else {
      disable(gl.STENCIL_TEST);
    }
  }
}
stencilTest
{
  if (!locked) {
    if (stencilTest) {
      enable(gl.STENCIL_TEST);
    } else {
      disable(gl.STENCIL_TEST);
    }
  }
}
if (!locked) {
  if (stencilTest) {
    enable(gl.STENCIL_TEST);
  } else {
    disable(gl.STENCIL_TEST);
  }
}
!locked
locked
{
  if (stencilTest) {
    enable(gl.STENCIL_TEST);
  } else {
    disable(gl.STENCIL_TEST);
  }
}
if (stencilTest) {
  enable(gl.STENCIL_TEST);
} else {
  disable(gl.STENCIL_TEST);
}
stencilTest
{
  enable(gl.STENCIL_TEST);
}
enable(gl.STENCIL_TEST);
enable(gl.STENCIL_TEST)
enable
gl.STENCIL_TEST
gl
STENCIL_TEST
{
  disable(gl.STENCIL_TEST);
}
disable(gl.STENCIL_TEST);
disable(gl.STENCIL_TEST)
disable
gl.STENCIL_TEST
gl
STENCIL_TEST
setMask: function (stencilMask) {
  if (currentStencilMask !== stencilMask && !locked) {
    gl.stencilMask(stencilMask);
    currentStencilMask = stencilMask;
  }
}
setMask
function (stencilMask) {
  if (currentStencilMask !== stencilMask && !locked) {
    gl.stencilMask(stencilMask);
    currentStencilMask = stencilMask;
  }
}
function (stencilMask) {
  if (currentStencilMask !== stencilMask && !locked) {
    gl.stencilMask(stencilMask);
    currentStencilMask = stencilMask;
  }
}
stencilMask
{
  if (currentStencilMask !== stencilMask && !locked) {
    gl.stencilMask(stencilMask);
    currentStencilMask = stencilMask;
  }
}
if (currentStencilMask !== stencilMask && !locked) {
  gl.stencilMask(stencilMask);
  currentStencilMask = stencilMask;
}
currentStencilMask !== stencilMask && !locked
currentStencilMask !== stencilMask
currentStencilMask
stencilMask
!locked
locked
{
  gl.stencilMask(stencilMask);
  currentStencilMask = stencilMask;
}
gl.stencilMask(stencilMask);
gl.stencilMask(stencilMask)
gl.stencilMask
gl
stencilMask
stencilMask
currentStencilMask = stencilMask;
currentStencilMask = stencilMask
currentStencilMask
stencilMask
setFunc: function (stencilFunc, stencilRef, stencilMask) {
  if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
    gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
    currentStencilFunc = stencilFunc;
    currentStencilRef = stencilRef;
    currentStencilFuncMask = stencilMask;
  }
}
setFunc
function (stencilFunc, stencilRef, stencilMask) {
  if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
    gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
    currentStencilFunc = stencilFunc;
    currentStencilRef = stencilRef;
    currentStencilFuncMask = stencilMask;
  }
}
function (stencilFunc, stencilRef, stencilMask) {
  if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
    gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
    currentStencilFunc = stencilFunc;
    currentStencilRef = stencilRef;
    currentStencilFuncMask = stencilMask;
  }
}
stencilFunc
stencilRef
stencilMask
{
  if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
    gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
    currentStencilFunc = stencilFunc;
    currentStencilRef = stencilRef;
    currentStencilFuncMask = stencilMask;
  }
}
if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
  gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
  currentStencilFunc = stencilFunc;
  currentStencilRef = stencilRef;
  currentStencilFuncMask = stencilMask;
}
currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask
currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef
currentStencilFunc !== stencilFunc
currentStencilFunc
stencilFunc
currentStencilRef !== stencilRef
currentStencilRef
stencilRef
currentStencilFuncMask !== stencilMask
currentStencilFuncMask
stencilMask
{
  gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
  currentStencilFunc = stencilFunc;
  currentStencilRef = stencilRef;
  currentStencilFuncMask = stencilMask;
}
gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
gl.stencilFunc(stencilFunc, stencilRef, stencilMask)
gl.stencilFunc
gl
stencilFunc
stencilFunc
stencilRef
stencilMask
currentStencilFunc = stencilFunc;
currentStencilFunc = stencilFunc
currentStencilFunc
stencilFunc
currentStencilRef = stencilRef;
currentStencilRef = stencilRef
currentStencilRef
stencilRef
currentStencilFuncMask = stencilMask;
currentStencilFuncMask = stencilMask
currentStencilFuncMask
stencilMask
setOp: function (stencilFail, stencilZFail, stencilZPass) {
  if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
    gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
    currentStencilFail = stencilFail;
    currentStencilZFail = stencilZFail;
    currentStencilZPass = stencilZPass;
  }
}
setOp
function (stencilFail, stencilZFail, stencilZPass) {
  if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
    gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
    currentStencilFail = stencilFail;
    currentStencilZFail = stencilZFail;
    currentStencilZPass = stencilZPass;
  }
}
function (stencilFail, stencilZFail, stencilZPass) {
  if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
    gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
    currentStencilFail = stencilFail;
    currentStencilZFail = stencilZFail;
    currentStencilZPass = stencilZPass;
  }
}
stencilFail
stencilZFail
stencilZPass
{
  if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
    gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
    currentStencilFail = stencilFail;
    currentStencilZFail = stencilZFail;
    currentStencilZPass = stencilZPass;
  }
}
if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
  gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
  currentStencilFail = stencilFail;
  currentStencilZFail = stencilZFail;
  currentStencilZPass = stencilZPass;
}
currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass
currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail
currentStencilFail !== stencilFail
currentStencilFail
stencilFail
currentStencilZFail !== stencilZFail
currentStencilZFail
stencilZFail
currentStencilZPass !== stencilZPass
currentStencilZPass
stencilZPass
{
  gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
  currentStencilFail = stencilFail;
  currentStencilZFail = stencilZFail;
  currentStencilZPass = stencilZPass;
}
gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
gl.stencilOp(stencilFail, stencilZFail, stencilZPass)
gl.stencilOp
gl
stencilOp
stencilFail
stencilZFail
stencilZPass
currentStencilFail = stencilFail;
currentStencilFail = stencilFail
currentStencilFail
stencilFail
currentStencilZFail = stencilZFail;
currentStencilZFail = stencilZFail
currentStencilZFail
stencilZFail
currentStencilZPass = stencilZPass;
currentStencilZPass = stencilZPass
currentStencilZPass
stencilZPass
setLocked: function (lock) {
  locked = lock;
}
setLocked
function (lock) {
  locked = lock;
}
function (lock) {
  locked = lock;
}
lock
{
  locked = lock;
}
locked = lock;
locked = lock
locked
lock
setClear: function (stencil) {
  if (currentStencilClear !== stencil) {
    gl.clearStencil(stencil);
    currentStencilClear = stencil;
  }
}
setClear
function (stencil) {
  if (currentStencilClear !== stencil) {
    gl.clearStencil(stencil);
    currentStencilClear = stencil;
  }
}
function (stencil) {
  if (currentStencilClear !== stencil) {
    gl.clearStencil(stencil);
    currentStencilClear = stencil;
  }
}
stencil
{
  if (currentStencilClear !== stencil) {
    gl.clearStencil(stencil);
    currentStencilClear = stencil;
  }
}
if (currentStencilClear !== stencil) {
  gl.clearStencil(stencil);
  currentStencilClear = stencil;
}
currentStencilClear !== stencil
currentStencilClear
stencil
{
  gl.clearStencil(stencil);
  currentStencilClear = stencil;
}
gl.clearStencil(stencil);
gl.clearStencil(stencil)
gl.clearStencil
gl
clearStencil
stencil
currentStencilClear = stencil;
currentStencilClear = stencil
currentStencilClear
stencil
reset: function () {
  locked = false;
  currentStencilMask = null;
  currentStencilFunc = null;
  currentStencilRef = null;
  currentStencilFuncMask = null;
  currentStencilFail = null;
  currentStencilZFail = null;
  currentStencilZPass = null;
  currentStencilClear = null;
}
reset
function () {
  locked = false;
  currentStencilMask = null;
  currentStencilFunc = null;
  currentStencilRef = null;
  currentStencilFuncMask = null;
  currentStencilFail = null;
  currentStencilZFail = null;
  currentStencilZPass = null;
  currentStencilClear = null;
}
function () {
  locked = false;
  currentStencilMask = null;
  currentStencilFunc = null;
  currentStencilRef = null;
  currentStencilFuncMask = null;
  currentStencilFail = null;
  currentStencilZFail = null;
  currentStencilZPass = null;
  currentStencilClear = null;
}
{
  locked = false;
  currentStencilMask = null;
  currentStencilFunc = null;
  currentStencilRef = null;
  currentStencilFuncMask = null;
  currentStencilFail = null;
  currentStencilZFail = null;
  currentStencilZPass = null;
  currentStencilClear = null;
}
locked = false;
locked = false
locked
false
currentStencilMask = null;
currentStencilMask = null
currentStencilMask
null
currentStencilFunc = null;
currentStencilFunc = null
currentStencilFunc
null
currentStencilRef = null;
currentStencilRef = null
currentStencilRef
null
currentStencilFuncMask = null;
currentStencilFuncMask = null
currentStencilFuncMask
null
currentStencilFail = null;
currentStencilFail = null
currentStencilFail
null
currentStencilZFail = null;
currentStencilZFail = null
currentStencilZFail
null
currentStencilZPass = null;
currentStencilZPass = null
currentStencilZPass
null
currentStencilClear = null;
currentStencilClear = null
currentStencilClear
null
//

const colorBuffer = new ColorBuffer();
colorBuffer = new ColorBuffer()
colorBuffer
new ColorBuffer()
ColorBuffer
const depthBuffer = new DepthBuffer();
depthBuffer = new DepthBuffer()
depthBuffer
new DepthBuffer()
DepthBuffer
const stencilBuffer = new StencilBuffer();
stencilBuffer = new StencilBuffer()
stencilBuffer
new StencilBuffer()
StencilBuffer
const uboBindings = new WeakMap();
uboBindings = new WeakMap()
uboBindings
new WeakMap()
WeakMap
const uboProgramMap = new WeakMap();
uboProgramMap = new WeakMap()
uboProgramMap
new WeakMap()
WeakMap
let enabledCapabilities = {};
enabledCapabilities = {}
enabledCapabilities
{}
let currentBoundFramebuffers = {};
currentBoundFramebuffers = {}
currentBoundFramebuffers
{}
let currentDrawbuffers = new WeakMap();
currentDrawbuffers = new WeakMap()
currentDrawbuffers
new WeakMap()
WeakMap
let defaultDrawbuffers = [];
defaultDrawbuffers = []
defaultDrawbuffers
[]
let currentProgram = null;
currentProgram = null
currentProgram
null
let currentBlendingEnabled = false;
currentBlendingEnabled = false
currentBlendingEnabled
false
let currentBlending = null;
currentBlending = null
currentBlending
null
let currentBlendEquation = null;
currentBlendEquation = null
currentBlendEquation
null
let currentBlendSrc = null;
currentBlendSrc = null
currentBlendSrc
null
let currentBlendDst = null;
currentBlendDst = null
currentBlendDst
null
let currentBlendEquationAlpha = null;
currentBlendEquationAlpha = null
currentBlendEquationAlpha
null
let currentBlendSrcAlpha = null;
currentBlendSrcAlpha = null
currentBlendSrcAlpha
null
let currentBlendDstAlpha = null;
currentBlendDstAlpha = null
currentBlendDstAlpha
null
let currentBlendColor = new Color(0, 0, 0);
currentBlendColor = new Color(0, 0, 0)
currentBlendColor
new Color(0, 0, 0)
Color
0
0
0
let currentBlendAlpha = 0;
currentBlendAlpha = 0
currentBlendAlpha
0
let currentPremultipledAlpha = false;
currentPremultipledAlpha = false
currentPremultipledAlpha
false
let currentFlipSided = null;
currentFlipSided = null
currentFlipSided
null
let currentCullFace = null;
currentCullFace = null
currentCullFace
null
let currentLineWidth = null;
currentLineWidth = null
currentLineWidth
null
let currentPolygonOffsetFactor = null;
currentPolygonOffsetFactor = null
currentPolygonOffsetFactor
null
let currentPolygonOffsetUnits = null;
currentPolygonOffsetUnits = null
currentPolygonOffsetUnits
null
const maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);
maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS)
maxTextures
gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS)
gl.getParameter
gl
getParameter
gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS
gl
MAX_COMBINED_TEXTURE_IMAGE_UNITS
let lineWidthAvailable = false;
lineWidthAvailable = false
lineWidthAvailable
false
let version = 0;
version = 0
version
0
const glVersion = gl.getParameter(gl.VERSION);
glVersion = gl.getParameter(gl.VERSION)
glVersion
gl.getParameter(gl.VERSION)
gl.getParameter
gl
getParameter
gl.VERSION
gl
VERSION
if (glVersion.indexOf('WebGL') !== -1) {
  version = parseFloat(/^WebGL (\d)/.exec(glVersion)[1]);
  lineWidthAvailable = version >= 1.0;
} else if (glVersion.indexOf('OpenGL ES') !== -1) {
  version = parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1]);
  lineWidthAvailable = version >= 2.0;
}
glVersion.indexOf('WebGL') !== -1
glVersion.indexOf('WebGL')
glVersion.indexOf
glVersion
indexOf
'WebGL'
-1
1
{
  version = parseFloat(/^WebGL (\d)/.exec(glVersion)[1]);
  lineWidthAvailable = version >= 1.0;
}
version = parseFloat(/^WebGL (\d)/.exec(glVersion)[1]);
version = parseFloat(/^WebGL (\d)/.exec(glVersion)[1])
version
parseFloat(/^WebGL (\d)/.exec(glVersion)[1])
parseFloat
/^WebGL (\d)/.exec(glVersion)[1]
/^WebGL (\d)/.exec(glVersion)
/^WebGL (\d)/.exec
/^WebGL (\d)/
exec
glVersion
1
lineWidthAvailable = version >= 1.0;
lineWidthAvailable = version >= 1.0
lineWidthAvailable
version >= 1.0
version
1.0
if (glVersion.indexOf('OpenGL ES') !== -1) {
  version = parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1]);
  lineWidthAvailable = version >= 2.0;
}
glVersion.indexOf('OpenGL ES') !== -1
glVersion.indexOf('OpenGL ES')
glVersion.indexOf
glVersion
indexOf
'OpenGL ES'
-1
1
{
  version = parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1]);
  lineWidthAvailable = version >= 2.0;
}
version = parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1]);
version = parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1])
version
parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1])
parseFloat
/^OpenGL ES (\d)/.exec(glVersion)[1]
/^OpenGL ES (\d)/.exec(glVersion)
/^OpenGL ES (\d)/.exec
/^OpenGL ES (\d)/
exec
glVersion
1
lineWidthAvailable = version >= 2.0;
lineWidthAvailable = version >= 2.0
lineWidthAvailable
version >= 2.0
version
2.0
let currentTextureSlot = null;
currentTextureSlot = null
currentTextureSlot
null
let currentBoundTextures = {};
currentBoundTextures = {}
currentBoundTextures
{}
const scissorParam = gl.getParameter(gl.SCISSOR_BOX);
scissorParam = gl.getParameter(gl.SCISSOR_BOX)
scissorParam
gl.getParameter(gl.SCISSOR_BOX)
gl.getParameter
gl
getParameter
gl.SCISSOR_BOX
gl
SCISSOR_BOX
const viewportParam = gl.getParameter(gl.VIEWPORT);
viewportParam = gl.getParameter(gl.VIEWPORT)
viewportParam
gl.getParameter(gl.VIEWPORT)
gl.getParameter
gl
getParameter
gl.VIEWPORT
gl
VIEWPORT
const currentScissor = new Vector4().fromArray(scissorParam);
currentScissor = new Vector4().fromArray(scissorParam)
currentScissor
new Vector4().fromArray(scissorParam)
new Vector4().fromArray
new Vector4()
Vector4
fromArray
scissorParam
const currentViewport = new Vector4().fromArray(viewportParam);
currentViewport = new Vector4().fromArray(viewportParam)
currentViewport
new Vector4().fromArray(viewportParam)
new Vector4().fromArray
new Vector4()
Vector4
fromArray
viewportParam
function createTexture(type, target, count, dimensions) {
  const data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
  const texture = gl.createTexture();
  gl.bindTexture(type, texture);
  gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  for (let i = 0; i < count; i++) {
    if (type === gl.TEXTURE_3D || type === gl.TEXTURE_2D_ARRAY) {
      gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
    } else {
      gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
    }
  }
  return texture;
}
StencilBuffer
{
  let locked = false;
  let currentStencilMask = null;
  let currentStencilFunc = null;
  let currentStencilRef = null;
  let currentStencilFuncMask = null;
  let currentStencilFail = null;
  let currentStencilZFail = null;
  let currentStencilZPass = null;
  let currentStencilClear = null;
  return {
    setTest: function (stencilTest) {
      if (!locked) {
        if (stencilTest) {
          enable(gl.STENCIL_TEST);
        } else {
          disable(gl.STENCIL_TEST);
        }
      }
    },
    setMask: function (stencilMask) {
      if (currentStencilMask !== stencilMask && !locked) {
        gl.stencilMask(stencilMask);
        currentStencilMask = stencilMask;
      }
    },
    setFunc: function (stencilFunc, stencilRef, stencilMask) {
      if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
        gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
        currentStencilFunc = stencilFunc;
        currentStencilRef = stencilRef;
        currentStencilFuncMask = stencilMask;
      }
    },
    setOp: function (stencilFail, stencilZFail, stencilZPass) {
      if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
        gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
        currentStencilFail = stencilFail;
        currentStencilZFail = stencilZFail;
        currentStencilZPass = stencilZPass;
      }
    },
    setLocked: function (lock) {
      locked = lock;
    },
    setClear: function (stencil) {
      if (currentStencilClear !== stencil) {
        gl.clearStencil(stencil);
        currentStencilClear = stencil;
      }
    },
    reset: function () {
      locked = false;
      currentStencilMask = null;
      currentStencilFunc = null;
      currentStencilRef = null;
      currentStencilFuncMask = null;
      currentStencilFail = null;
      currentStencilZFail = null;
      currentStencilZPass = null;
      currentStencilClear = null;
    }
  };
}
let locked = false;
locked = false
locked
false
let currentStencilMask = null;
currentStencilMask = null
currentStencilMask
null
let currentStencilFunc = null;
currentStencilFunc = null
currentStencilFunc
null
let currentStencilRef = null;
currentStencilRef = null
currentStencilRef
null
let currentStencilFuncMask = null;
currentStencilFuncMask = null
currentStencilFuncMask
null
let currentStencilFail = null;
currentStencilFail = null
currentStencilFail
null
let currentStencilZFail = null;
currentStencilZFail = null
currentStencilZFail
null
let currentStencilZPass = null;
currentStencilZPass = null
currentStencilZPass
null
let currentStencilClear = null;
currentStencilClear = null
currentStencilClear
null
return {
  setTest: function (stencilTest) {
    if (!locked) {
      if (stencilTest) {
        enable(gl.STENCIL_TEST);
      } else {
        disable(gl.STENCIL_TEST);
      }
    }
  },
  setMask: function (stencilMask) {
    if (currentStencilMask !== stencilMask && !locked) {
      gl.stencilMask(stencilMask);
      currentStencilMask = stencilMask;
    }
  },
  setFunc: function (stencilFunc, stencilRef, stencilMask) {
    if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
      gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
      currentStencilFunc = stencilFunc;
      currentStencilRef = stencilRef;
      currentStencilFuncMask = stencilMask;
    }
  },
  setOp: function (stencilFail, stencilZFail, stencilZPass) {
    if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
      gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
      currentStencilFail = stencilFail;
      currentStencilZFail = stencilZFail;
      currentStencilZPass = stencilZPass;
    }
  },
  setLocked: function (lock) {
    locked = lock;
  },
  setClear: function (stencil) {
    if (currentStencilClear !== stencil) {
      gl.clearStencil(stencil);
      currentStencilClear = stencil;
    }
  },
  reset: function () {
    locked = false;
    currentStencilMask = null;
    currentStencilFunc = null;
    currentStencilRef = null;
    currentStencilFuncMask = null;
    currentStencilFail = null;
    currentStencilZFail = null;
    currentStencilZPass = null;
    currentStencilClear = null;
  }
};
{
  setTest: function (stencilTest) {
    if (!locked) {
      if (stencilTest) {
        enable(gl.STENCIL_TEST);
      } else {
        disable(gl.STENCIL_TEST);
      }
    }
  },
  setMask: function (stencilMask) {
    if (currentStencilMask !== stencilMask && !locked) {
      gl.stencilMask(stencilMask);
      currentStencilMask = stencilMask;
    }
  },
  setFunc: function (stencilFunc, stencilRef, stencilMask) {
    if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
      gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
      currentStencilFunc = stencilFunc;
      currentStencilRef = stencilRef;
      currentStencilFuncMask = stencilMask;
    }
  },
  setOp: function (stencilFail, stencilZFail, stencilZPass) {
    if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
      gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
      currentStencilFail = stencilFail;
      currentStencilZFail = stencilZFail;
      currentStencilZPass = stencilZPass;
    }
  },
  setLocked: function (lock) {
    locked = lock;
  },
  setClear: function (stencil) {
    if (currentStencilClear !== stencil) {
      gl.clearStencil(stencil);
      currentStencilClear = stencil;
    }
  },
  reset: function () {
    locked = false;
    currentStencilMask = null;
    currentStencilFunc = null;
    currentStencilRef = null;
    currentStencilFuncMask = null;
    currentStencilFail = null;
    currentStencilZFail = null;
    currentStencilZPass = null;
    currentStencilClear = null;
  }
}
setTest: function (stencilTest) {
  if (!locked) {
    if (stencilTest) {
      enable(gl.STENCIL_TEST);
    } else {
      disable(gl.STENCIL_TEST);
    }
  }
}
setTest
function (stencilTest) {
  if (!locked) {
    if (stencilTest) {
      enable(gl.STENCIL_TEST);
    } else {
      disable(gl.STENCIL_TEST);
    }
  }
}
function createTexture(type, target, count, dimensions) {
  const data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
  const texture = gl.createTexture();
  gl.bindTexture(type, texture);
  gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  for (let i = 0; i < count; i++) {
    if (type === gl.TEXTURE_3D || type === gl.TEXTURE_2D_ARRAY) {
      gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
    } else {
      gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
    }
  }
  return texture;
}
createTexture
type
target
count
dimensions
{
  const data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
  const texture = gl.createTexture();
  gl.bindTexture(type, texture);
  gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  for (let i = 0; i < count; i++) {
    if (type === gl.TEXTURE_3D || type === gl.TEXTURE_2D_ARRAY) {
      gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
    } else {
      gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
    }
  }
  return texture;
}
const data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
data = new Uint8Array(4)
data
new Uint8Array(4)
Uint8Array
4
// 4 is required to match default unpack alignment of 4.
const texture = gl.createTexture();
texture = gl.createTexture()
texture
gl.createTexture()
gl.createTexture
gl
createTexture
gl.bindTexture(type, texture);
gl.bindTexture(type, texture)
gl.bindTexture
gl
bindTexture
type
texture
gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
gl.texParameteri
gl
texParameteri
type
gl.TEXTURE_MIN_FILTER
gl
TEXTURE_MIN_FILTER
gl.NEAREST
gl
NEAREST
gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
gl.texParameteri
gl
texParameteri
type
gl.TEXTURE_MAG_FILTER
gl
TEXTURE_MAG_FILTER
gl.NEAREST
gl
NEAREST
for (let i = 0; i < count; i++) {
  if (type === gl.TEXTURE_3D || type === gl.TEXTURE_2D_ARRAY) {
    gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
  } else {
    gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
  }
}
let i = 0;
i = 0
i
0
i < count
i
count
i++
i
{
  if (type === gl.TEXTURE_3D || type === gl.TEXTURE_2D_ARRAY) {
    gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
  } else {
    gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
  }
}
if (type === gl.TEXTURE_3D || type === gl.TEXTURE_2D_ARRAY) {
  gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
} else {
  gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
}
type === gl.TEXTURE_3D || type === gl.TEXTURE_2D_ARRAY
type === gl.TEXTURE_3D
type
gl.TEXTURE_3D
gl
TEXTURE_3D
type === gl.TEXTURE_2D_ARRAY
type
gl.TEXTURE_2D_ARRAY
gl
TEXTURE_2D_ARRAY
{
  gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
}
gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data)
gl.texImage3D
gl
texImage3D
target
0
gl.RGBA
gl
RGBA
1
1
dimensions
0
gl.RGBA
gl
RGBA
gl.UNSIGNED_BYTE
gl
UNSIGNED_BYTE
data
{
  gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
}
gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data)
gl.texImage2D
gl
texImage2D
target + i
target
i
0
gl.RGBA
gl
RGBA
1
1
0
gl.RGBA
gl
RGBA
gl.UNSIGNED_BYTE
gl
UNSIGNED_BYTE
data
return texture;
texture
const emptyTextures = {};
emptyTextures = {}
emptyTextures
{}
emptyTextures[gl.TEXTURE_2D] = createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
emptyTextures[gl.TEXTURE_2D] = createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1)
emptyTextures[gl.TEXTURE_2D]
emptyTextures
gl.TEXTURE_2D
gl
TEXTURE_2D
createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1)
createTexture
gl.TEXTURE_2D
gl
TEXTURE_2D
gl.TEXTURE_2D
gl
TEXTURE_2D
1
emptyTextures[gl.TEXTURE_CUBE_MAP] = createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
emptyTextures[gl.TEXTURE_CUBE_MAP] = createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6)
emptyTextures[gl.TEXTURE_CUBE_MAP]
emptyTextures
gl.TEXTURE_CUBE_MAP
gl
TEXTURE_CUBE_MAP
createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6)
createTexture
gl.TEXTURE_CUBE_MAP
gl
TEXTURE_CUBE_MAP
gl.TEXTURE_CUBE_MAP_POSITIVE_X
gl
TEXTURE_CUBE_MAP_POSITIVE_X
6
emptyTextures[gl.TEXTURE_2D_ARRAY] = createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
emptyTextures[gl.TEXTURE_2D_ARRAY] = createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1)
emptyTextures[gl.TEXTURE_2D_ARRAY]
emptyTextures
gl.TEXTURE_2D_ARRAY
gl
TEXTURE_2D_ARRAY
createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1)
createTexture
gl.TEXTURE_2D_ARRAY
gl
TEXTURE_2D_ARRAY
gl.TEXTURE_2D_ARRAY
gl
TEXTURE_2D_ARRAY
1
1
emptyTextures[gl.TEXTURE_3D] = createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

// init
emptyTextures[gl.TEXTURE_3D] = createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1)
emptyTextures[gl.TEXTURE_3D]
emptyTextures
gl.TEXTURE_3D
gl
TEXTURE_3D
createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1)
createTexture
gl.TEXTURE_3D
gl
TEXTURE_3D
gl.TEXTURE_3D
gl
TEXTURE_3D
1
1
// init

colorBuffer.setClear(0, 0, 0, 1);
colorBuffer.setClear(0, 0, 0, 1)
colorBuffer.setClear
colorBuffer
setClear
0
0
0
1
depthBuffer.setClear(1);
depthBuffer.setClear(1)
depthBuffer.setClear
depthBuffer
setClear
1
stencilBuffer.setClear(0);
stencilBuffer.setClear(0)
stencilBuffer.setClear
stencilBuffer
setClear
0
enable(gl.DEPTH_TEST);
enable(gl.DEPTH_TEST)
enable
gl.DEPTH_TEST
gl
DEPTH_TEST
depthBuffer.setFunc(LessEqualDepth);
depthBuffer.setFunc(LessEqualDepth)
depthBuffer.setFunc
depthBuffer
setFunc
LessEqualDepth
setFlipSided(false);
setFlipSided(false)
setFlipSided
false
setCullFace(CullFaceBack);
setCullFace(CullFaceBack)
setCullFace
CullFaceBack
enable(gl.CULL_FACE);
enable(gl.CULL_FACE)
enable
gl.CULL_FACE
gl
CULL_FACE
setBlending(NoBlending);

//
setBlending(NoBlending)
setBlending
NoBlending
//

function enable(id) {
  if (enabledCapabilities[id] !== true) {
    gl.enable(id);
    enabledCapabilities[id] = true;
  }
}
//

function enable(id) {
  if (enabledCapabilities[id] !== true) {
    gl.enable(id);
    enabledCapabilities[id] = true;
  }
}
enable
id
{
  if (enabledCapabilities[id] !== true) {
    gl.enable(id);
    enabledCapabilities[id] = true;
  }
}
if (enabledCapabilities[id] !== true) {
  gl.enable(id);
  enabledCapabilities[id] = true;
}
enabledCapabilities[id] !== true
enabledCapabilities[id]
enabledCapabilities
id
true
{
  gl.enable(id);
  enabledCapabilities[id] = true;
}
gl.enable(id);
gl.enable(id)
gl.enable
gl
enable
id
enabledCapabilities[id] = true;
enabledCapabilities[id] = true
enabledCapabilities[id]
enabledCapabilities
id
true
function disable(id) {
  if (enabledCapabilities[id] !== false) {
    gl.disable(id);
    enabledCapabilities[id] = false;
  }
}
function disable(id) {
  if (enabledCapabilities[id] !== false) {
    gl.disable(id);
    enabledCapabilities[id] = false;
  }
}
disable
id
{
  if (enabledCapabilities[id] !== false) {
    gl.disable(id);
    enabledCapabilities[id] = false;
  }
}
if (enabledCapabilities[id] !== false) {
  gl.disable(id);
  enabledCapabilities[id] = false;
}
enabledCapabilities[id] !== false
enabledCapabilities[id]
enabledCapabilities
id
false
{
  gl.disable(id);
  enabledCapabilities[id] = false;
}
gl.disable(id);
gl.disable(id)
gl.disable
gl
disable
id
enabledCapabilities[id] = false;
enabledCapabilities[id] = false
enabledCapabilities[id]
enabledCapabilities
id
false
function bindFramebuffer(target, framebuffer) {
  if (currentBoundFramebuffers[target] !== framebuffer) {
    gl.bindFramebuffer(target, framebuffer);
    currentBoundFramebuffers[target] = framebuffer;

    // gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

    if (target === gl.DRAW_FRAMEBUFFER) {
      currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
    }
    if (target === gl.FRAMEBUFFER) {
      currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
    }
    return true;
  }
  return false;
}
function bindFramebuffer(target, framebuffer) {
  if (currentBoundFramebuffers[target] !== framebuffer) {
    gl.bindFramebuffer(target, framebuffer);
    currentBoundFramebuffers[target] = framebuffer;

    // gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

    if (target === gl.DRAW_FRAMEBUFFER) {
      currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
    }
    if (target === gl.FRAMEBUFFER) {
      currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
    }
    return true;
  }
  return false;
}
bindFramebuffer
target
framebuffer
{
  if (currentBoundFramebuffers[target] !== framebuffer) {
    gl.bindFramebuffer(target, framebuffer);
    currentBoundFramebuffers[target] = framebuffer;

    // gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

    if (target === gl.DRAW_FRAMEBUFFER) {
      currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
    }
    if (target === gl.FRAMEBUFFER) {
      currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
    }
    return true;
  }
  return false;
}
if (currentBoundFramebuffers[target] !== framebuffer) {
  gl.bindFramebuffer(target, framebuffer);
  currentBoundFramebuffers[target] = framebuffer;

  // gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

  if (target === gl.DRAW_FRAMEBUFFER) {
    currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
  }
  if (target === gl.FRAMEBUFFER) {
    currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
  }
  return true;
}
currentBoundFramebuffers[target] !== framebuffer
currentBoundFramebuffers[target]
currentBoundFramebuffers
target
framebuffer
{
  gl.bindFramebuffer(target, framebuffer);
  currentBoundFramebuffers[target] = framebuffer;

  // gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

  if (target === gl.DRAW_FRAMEBUFFER) {
    currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
  }
  if (target === gl.FRAMEBUFFER) {
    currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
  }
  return true;
}
gl.bindFramebuffer(target, framebuffer);
gl.bindFramebuffer(target, framebuffer)
gl.bindFramebuffer
gl
bindFramebuffer
target
framebuffer
currentBoundFramebuffers[target] = framebuffer;

// gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER
currentBoundFramebuffers[target] = framebuffer
currentBoundFramebuffers[target]
currentBoundFramebuffers
target
framebuffer
// gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

if (target === gl.DRAW_FRAMEBUFFER) {
  currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
}
target === gl.DRAW_FRAMEBUFFER
target
gl.DRAW_FRAMEBUFFER
gl
DRAW_FRAMEBUFFER
{
  currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
}
currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer
currentBoundFramebuffers[gl.FRAMEBUFFER]
currentBoundFramebuffers
gl.FRAMEBUFFER
gl
FRAMEBUFFER
framebuffer
if (target === gl.FRAMEBUFFER) {
  currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
}
target === gl.FRAMEBUFFER
target
gl.FRAMEBUFFER
gl
FRAMEBUFFER
{
  currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
}
currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer
currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER]
currentBoundFramebuffers
gl.DRAW_FRAMEBUFFER
gl
DRAW_FRAMEBUFFER
framebuffer
return true;
true
return false;
false
function drawBuffers(renderTarget, framebuffer) {
  let drawBuffers = defaultDrawbuffers;
  let needsUpdate = false;
  if (renderTarget) {
    drawBuffers = currentDrawbuffers.get(framebuffer);
    if (drawBuffers === undefined) {
      drawBuffers = [];
      currentDrawbuffers.set(framebuffer, drawBuffers);
    }
    const textures = renderTarget.textures;
    if (drawBuffers.length !== textures.length || drawBuffers[0] !== gl.COLOR_ATTACHMENT0) {
      for (let i = 0, il = textures.length; i < il; i++) {
        drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
      }
      drawBuffers.length = textures.length;
      needsUpdate = true;
    }
  } else {
    if (drawBuffers[0] !== gl.BACK) {
      drawBuffers[0] = gl.BACK;
      needsUpdate = true;
    }
  }
  if (needsUpdate) {
    gl.drawBuffers(drawBuffers);
  }
}
function drawBuffers(renderTarget, framebuffer) {
  let drawBuffers = defaultDrawbuffers;
  let needsUpdate = false;
  if (renderTarget) {
    drawBuffers = currentDrawbuffers.get(framebuffer);
    if (drawBuffers === undefined) {
      drawBuffers = [];
      currentDrawbuffers.set(framebuffer, drawBuffers);
    }
    const textures = renderTarget.textures;
    if (drawBuffers.length !== textures.length || drawBuffers[0] !== gl.COLOR_ATTACHMENT0) {
      for (let i = 0, il = textures.length; i < il; i++) {
        drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
      }
      drawBuffers.length = textures.length;
      needsUpdate = true;
    }
  } else {
    if (drawBuffers[0] !== gl.BACK) {
      drawBuffers[0] = gl.BACK;
      needsUpdate = true;
    }
  }
  if (needsUpdate) {
    gl.drawBuffers(drawBuffers);
  }
}
drawBuffers
renderTarget
framebuffer
{
  let drawBuffers = defaultDrawbuffers;
  let needsUpdate = false;
  if (renderTarget) {
    drawBuffers = currentDrawbuffers.get(framebuffer);
    if (drawBuffers === undefined) {
      drawBuffers = [];
      currentDrawbuffers.set(framebuffer, drawBuffers);
    }
    const textures = renderTarget.textures;
    if (drawBuffers.length !== textures.length || drawBuffers[0] !== gl.COLOR_ATTACHMENT0) {
      for (let i = 0, il = textures.length; i < il; i++) {
        drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
      }
      drawBuffers.length = textures.length;
      needsUpdate = true;
    }
  } else {
    if (drawBuffers[0] !== gl.BACK) {
      drawBuffers[0] = gl.BACK;
      needsUpdate = true;
    }
  }
  if (needsUpdate) {
    gl.drawBuffers(drawBuffers);
  }
}
let drawBuffers = defaultDrawbuffers;
drawBuffers = defaultDrawbuffers
drawBuffers
defaultDrawbuffers
let needsUpdate = false;
needsUpdate = false
needsUpdate
false
if (renderTarget) {
  drawBuffers = currentDrawbuffers.get(framebuffer);
  if (drawBuffers === undefined) {
    drawBuffers = [];
    currentDrawbuffers.set(framebuffer, drawBuffers);
  }
  const textures = renderTarget.textures;
  if (drawBuffers.length !== textures.length || drawBuffers[0] !== gl.COLOR_ATTACHMENT0) {
    for (let i = 0, il = textures.length; i < il; i++) {
      drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
    }
    drawBuffers.length = textures.length;
    needsUpdate = true;
  }
} else {
  if (drawBuffers[0] !== gl.BACK) {
    drawBuffers[0] = gl.BACK;
    needsUpdate = true;
  }
}
renderTarget
{
  drawBuffers = currentDrawbuffers.get(framebuffer);
  if (drawBuffers === undefined) {
    drawBuffers = [];
    currentDrawbuffers.set(framebuffer, drawBuffers);
  }
  const textures = renderTarget.textures;
  if (drawBuffers.length !== textures.length || drawBuffers[0] !== gl.COLOR_ATTACHMENT0) {
    for (let i = 0, il = textures.length; i < il; i++) {
      drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
    }
    drawBuffers.length = textures.length;
    needsUpdate = true;
  }
}
drawBuffers = currentDrawbuffers.get(framebuffer);
drawBuffers = currentDrawbuffers.get(framebuffer)
drawBuffers
currentDrawbuffers.get(framebuffer)
currentDrawbuffers.get
currentDrawbuffers
get
framebuffer
if (drawBuffers === undefined) {
  drawBuffers = [];
  currentDrawbuffers.set(framebuffer, drawBuffers);
}
drawBuffers === undefined
drawBuffers
undefined
{
  drawBuffers = [];
  currentDrawbuffers.set(framebuffer, drawBuffers);
}
drawBuffers = [];
drawBuffers = []
drawBuffers
[]
currentDrawbuffers.set(framebuffer, drawBuffers);
currentDrawbuffers.set(framebuffer, drawBuffers)
currentDrawbuffers.set
currentDrawbuffers
set
framebuffer
drawBuffers
const textures = renderTarget.textures;
textures = renderTarget.textures
textures
renderTarget.textures
renderTarget
textures
if (drawBuffers.length !== textures.length || drawBuffers[0] !== gl.COLOR_ATTACHMENT0) {
  for (let i = 0, il = textures.length; i < il; i++) {
    drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
  }
  drawBuffers.length = textures.length;
  needsUpdate = true;
}
drawBuffers.length !== textures.length || drawBuffers[0] !== gl.COLOR_ATTACHMENT0
drawBuffers.length !== textures.length
drawBuffers.length
drawBuffers
length
textures.length
textures
length
drawBuffers[0] !== gl.COLOR_ATTACHMENT0
drawBuffers[0]
drawBuffers
0
gl.COLOR_ATTACHMENT0
gl
COLOR_ATTACHMENT0
{
  for (let i = 0, il = textures.length; i < il; i++) {
    drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
  }
  drawBuffers.length = textures.length;
  needsUpdate = true;
}
for (let i = 0, il = textures.length; i < il; i++) {
  drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
}
let i = 0,
  il = textures.length;
i = 0
i
0
il = textures.length
il
textures.length
textures
length
i < il
i
il
i++
i
{
  drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
}
drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i
drawBuffers[i]
drawBuffers
i
gl.COLOR_ATTACHMENT0 + i
gl.COLOR_ATTACHMENT0
gl
COLOR_ATTACHMENT0
i
drawBuffers.length = textures.length;
drawBuffers.length = textures.length
drawBuffers.length
drawBuffers
length
textures.length
textures
length
needsUpdate = true;
needsUpdate = true
needsUpdate
true
{
  if (drawBuffers[0] !== gl.BACK) {
    drawBuffers[0] = gl.BACK;
    needsUpdate = true;
  }
}
if (drawBuffers[0] !== gl.BACK) {
  drawBuffers[0] = gl.BACK;
  needsUpdate = true;
}
drawBuffers[0] !== gl.BACK
drawBuffers[0]
drawBuffers
0
gl.BACK
gl
BACK
{
  drawBuffers[0] = gl.BACK;
  needsUpdate = true;
}
drawBuffers[0] = gl.BACK;
drawBuffers[0] = gl.BACK
drawBuffers[0]
drawBuffers
0
gl.BACK
gl
BACK
needsUpdate = true;
needsUpdate = true
needsUpdate
true
if (needsUpdate) {
  gl.drawBuffers(drawBuffers);
}
needsUpdate
{
  gl.drawBuffers(drawBuffers);
}
gl.drawBuffers(drawBuffers);
gl.drawBuffers(drawBuffers)
gl.drawBuffers
gl
drawBuffers
drawBuffers
function useProgram(program) {
  if (currentProgram !== program) {
    gl.useProgram(program);
    currentProgram = program;
    return true;
  }
  return false;
}
function useProgram(program) {
  if (currentProgram !== program) {
    gl.useProgram(program);
    currentProgram = program;
    return true;
  }
  return false;
}
useProgram
program
{
  if (currentProgram !== program) {
    gl.useProgram(program);
    currentProgram = program;
    return true;
  }
  return false;
}
if (currentProgram !== program) {
  gl.useProgram(program);
  currentProgram = program;
  return true;
}
currentProgram !== program
currentProgram
program
{
  gl.useProgram(program);
  currentProgram = program;
  return true;
}
gl.useProgram(program);
gl.useProgram(program)
gl.useProgram
gl
useProgram
program
currentProgram = program;
currentProgram = program
currentProgram
program
return true;
true
return false;
false
const equationToGL = {
  [AddEquation]: gl.FUNC_ADD,
  [SubtractEquation]: gl.FUNC_SUBTRACT,
  [ReverseSubtractEquation]: gl.FUNC_REVERSE_SUBTRACT
};
equationToGL = {
  [AddEquation]: gl.FUNC_ADD,
  [SubtractEquation]: gl.FUNC_SUBTRACT,
  [ReverseSubtractEquation]: gl.FUNC_REVERSE_SUBTRACT
}
equationToGL
{
  [AddEquation]: gl.FUNC_ADD,
  [SubtractEquation]: gl.FUNC_SUBTRACT,
  [ReverseSubtractEquation]: gl.FUNC_REVERSE_SUBTRACT
}
[AddEquation]: gl.FUNC_ADD
AddEquation
gl.FUNC_ADD
gl
FUNC_ADD
[SubtractEquation]: gl.FUNC_SUBTRACT
SubtractEquation
gl.FUNC_SUBTRACT
gl
FUNC_SUBTRACT
[ReverseSubtractEquation]: gl.FUNC_REVERSE_SUBTRACT
ReverseSubtractEquation
gl.FUNC_REVERSE_SUBTRACT
gl
FUNC_REVERSE_SUBTRACT
equationToGL[MinEquation] = gl.MIN;
equationToGL[MinEquation] = gl.MIN
equationToGL[MinEquation]
equationToGL
MinEquation
gl.MIN
gl
MIN
equationToGL[MaxEquation] = gl.MAX;
equationToGL[MaxEquation] = gl.MAX
equationToGL[MaxEquation]
equationToGL
MaxEquation
gl.MAX
gl
MAX
const factorToGL = {
  [ZeroFactor]: gl.ZERO,
  [OneFactor]: gl.ONE,
  [SrcColorFactor]: gl.SRC_COLOR,
  [SrcAlphaFactor]: gl.SRC_ALPHA,
  [SrcAlphaSaturateFactor]: gl.SRC_ALPHA_SATURATE,
  [DstColorFactor]: gl.DST_COLOR,
  [DstAlphaFactor]: gl.DST_ALPHA,
  [OneMinusSrcColorFactor]: gl.ONE_MINUS_SRC_COLOR,
  [OneMinusSrcAlphaFactor]: gl.ONE_MINUS_SRC_ALPHA,
  [OneMinusDstColorFactor]: gl.ONE_MINUS_DST_COLOR,
  [OneMinusDstAlphaFactor]: gl.ONE_MINUS_DST_ALPHA,
  [ConstantColorFactor]: gl.CONSTANT_COLOR,
  [OneMinusConstantColorFactor]: gl.ONE_MINUS_CONSTANT_COLOR,
  [ConstantAlphaFactor]: gl.CONSTANT_ALPHA,
  [OneMinusConstantAlphaFactor]: gl.ONE_MINUS_CONSTANT_ALPHA
};
factorToGL = {
  [ZeroFactor]: gl.ZERO,
  [OneFactor]: gl.ONE,
  [SrcColorFactor]: gl.SRC_COLOR,
  [SrcAlphaFactor]: gl.SRC_ALPHA,
  [SrcAlphaSaturateFactor]: gl.SRC_ALPHA_SATURATE,
  [DstColorFactor]: gl.DST_COLOR,
  [DstAlphaFactor]: gl.DST_ALPHA,
  [OneMinusSrcColorFactor]: gl.ONE_MINUS_SRC_COLOR,
  [OneMinusSrcAlphaFactor]: gl.ONE_MINUS_SRC_ALPHA,
  [OneMinusDstColorFactor]: gl.ONE_MINUS_DST_COLOR,
  [OneMinusDstAlphaFactor]: gl.ONE_MINUS_DST_ALPHA,
  [ConstantColorFactor]: gl.CONSTANT_COLOR,
  [OneMinusConstantColorFactor]: gl.ONE_MINUS_CONSTANT_COLOR,
  [ConstantAlphaFactor]: gl.CONSTANT_ALPHA,
  [OneMinusConstantAlphaFactor]: gl.ONE_MINUS_CONSTANT_ALPHA
}
factorToGL
{
  [ZeroFactor]: gl.ZERO,
  [OneFactor]: gl.ONE,
  [SrcColorFactor]: gl.SRC_COLOR,
  [SrcAlphaFactor]: gl.SRC_ALPHA,
  [SrcAlphaSaturateFactor]: gl.SRC_ALPHA_SATURATE,
  [DstColorFactor]: gl.DST_COLOR,
  [DstAlphaFactor]: gl.DST_ALPHA,
  [OneMinusSrcColorFactor]: gl.ONE_MINUS_SRC_COLOR,
  [OneMinusSrcAlphaFactor]: gl.ONE_MINUS_SRC_ALPHA,
  [OneMinusDstColorFactor]: gl.ONE_MINUS_DST_COLOR,
  [OneMinusDstAlphaFactor]: gl.ONE_MINUS_DST_ALPHA,
  [ConstantColorFactor]: gl.CONSTANT_COLOR,
  [OneMinusConstantColorFactor]: gl.ONE_MINUS_CONSTANT_COLOR,
  [ConstantAlphaFactor]: gl.CONSTANT_ALPHA,
  [OneMinusConstantAlphaFactor]: gl.ONE_MINUS_CONSTANT_ALPHA
}
[ZeroFactor]: gl.ZERO
ZeroFactor
gl.ZERO
gl
ZERO
[OneFactor]: gl.ONE
OneFactor
gl.ONE
gl
ONE
[SrcColorFactor]: gl.SRC_COLOR
SrcColorFactor
gl.SRC_COLOR
gl
SRC_COLOR
[SrcAlphaFactor]: gl.SRC_ALPHA
SrcAlphaFactor
gl.SRC_ALPHA
gl
SRC_ALPHA
[SrcAlphaSaturateFactor]: gl.SRC_ALPHA_SATURATE
SrcAlphaSaturateFactor
gl.SRC_ALPHA_SATURATE
gl
SRC_ALPHA_SATURATE
[DstColorFactor]: gl.DST_COLOR
DstColorFactor
gl.DST_COLOR
gl
DST_COLOR
[DstAlphaFactor]: gl.DST_ALPHA
DstAlphaFactor
gl.DST_ALPHA
gl
DST_ALPHA
[OneMinusSrcColorFactor]: gl.ONE_MINUS_SRC_COLOR
OneMinusSrcColorFactor
gl.ONE_MINUS_SRC_COLOR
gl
ONE_MINUS_SRC_COLOR
[OneMinusSrcAlphaFactor]: gl.ONE_MINUS_SRC_ALPHA
OneMinusSrcAlphaFactor
gl.ONE_MINUS_SRC_ALPHA
gl
ONE_MINUS_SRC_ALPHA
[OneMinusDstColorFactor]: gl.ONE_MINUS_DST_COLOR
OneMinusDstColorFactor
gl.ONE_MINUS_DST_COLOR
gl
ONE_MINUS_DST_COLOR
[OneMinusDstAlphaFactor]: gl.ONE_MINUS_DST_ALPHA
OneMinusDstAlphaFactor
gl.ONE_MINUS_DST_ALPHA
gl
ONE_MINUS_DST_ALPHA
[ConstantColorFactor]: gl.CONSTANT_COLOR
ConstantColorFactor
gl.CONSTANT_COLOR
gl
CONSTANT_COLOR
[OneMinusConstantColorFactor]: gl.ONE_MINUS_CONSTANT_COLOR
OneMinusConstantColorFactor
gl.ONE_MINUS_CONSTANT_COLOR
gl
ONE_MINUS_CONSTANT_COLOR
[ConstantAlphaFactor]: gl.CONSTANT_ALPHA
ConstantAlphaFactor
gl.CONSTANT_ALPHA
gl
CONSTANT_ALPHA
[OneMinusConstantAlphaFactor]: gl.ONE_MINUS_CONSTANT_ALPHA
OneMinusConstantAlphaFactor
gl.ONE_MINUS_CONSTANT_ALPHA
gl
ONE_MINUS_CONSTANT_ALPHA
function setBlending(blending, blendEquation, blendSrc, blendDst, blendEquationAlpha, blendSrcAlpha, blendDstAlpha, blendColor, blendAlpha, premultipliedAlpha) {
  if (blending === NoBlending) {
    if (currentBlendingEnabled === true) {
      disable(gl.BLEND);
      currentBlendingEnabled = false;
    }
    return;
  }
  if (currentBlendingEnabled === false) {
    enable(gl.BLEND);
    currentBlendingEnabled = true;
  }
  if (blending !== CustomBlending) {
    if (blending !== currentBlending || premultipliedAlpha !== currentPremultipledAlpha) {
      if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {
        gl.blendEquation(gl.FUNC_ADD);
        currentBlendEquation = AddEquation;
        currentBlendEquationAlpha = AddEquation;
      }
      if (premultipliedAlpha) {
        switch (blending) {
          case NormalBlending:
            gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            break;
          case AdditiveBlending:
            gl.blendFunc(gl.ONE, gl.ONE);
            break;
          case SubtractiveBlending:
            gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            break;
          case MultiplyBlending:
            gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            break;
          default:
            console.error('THREE.WebGLState: Invalid blending: ', blending);
            break;
        }
      } else {
        switch (blending) {
          case NormalBlending:
            gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            break;
          case AdditiveBlending:
            gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            break;
          case SubtractiveBlending:
            gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            break;
          case MultiplyBlending:
            gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            break;
          default:
            console.error('THREE.WebGLState: Invalid blending: ', blending);
            break;
        }
      }
      currentBlendSrc = null;
      currentBlendDst = null;
      currentBlendSrcAlpha = null;
      currentBlendDstAlpha = null;
      currentBlendColor.set(0, 0, 0);
      currentBlendAlpha = 0;
      currentBlending = blending;
      currentPremultipledAlpha = premultipliedAlpha;
    }
    return;
  }

  // custom blending

  blendEquationAlpha = blendEquationAlpha || blendEquation;
  blendSrcAlpha = blendSrcAlpha || blendSrc;
  blendDstAlpha = blendDstAlpha || blendDst;
  if (blendEquation !== currentBlendEquation || blendEquationAlpha !== currentBlendEquationAlpha) {
    gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
    currentBlendEquation = blendEquation;
    currentBlendEquationAlpha = blendEquationAlpha;
  }
  if (blendSrc !== currentBlendSrc || blendDst !== currentBlendDst || blendSrcAlpha !== currentBlendSrcAlpha || blendDstAlpha !== currentBlendDstAlpha) {
    gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
    currentBlendSrc = blendSrc;
    currentBlendDst = blendDst;
    currentBlendSrcAlpha = blendSrcAlpha;
    currentBlendDstAlpha = blendDstAlpha;
  }
  if (blendColor.equals(currentBlendColor) === false || blendAlpha !== currentBlendAlpha) {
    gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
    currentBlendColor.copy(blendColor);
    currentBlendAlpha = blendAlpha;
  }
  currentBlending = blending;
  currentPremultipledAlpha = false;
}
function setBlending(blending, blendEquation, blendSrc, blendDst, blendEquationAlpha, blendSrcAlpha, blendDstAlpha, blendColor, blendAlpha, premultipliedAlpha) {
  if (blending === NoBlending) {
    if (currentBlendingEnabled === true) {
      disable(gl.BLEND);
      currentBlendingEnabled = false;
    }
    return;
  }
  if (currentBlendingEnabled === false) {
    enable(gl.BLEND);
    currentBlendingEnabled = true;
  }
  if (blending !== CustomBlending) {
    if (blending !== currentBlending || premultipliedAlpha !== currentPremultipledAlpha) {
      if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {
        gl.blendEquation(gl.FUNC_ADD);
        currentBlendEquation = AddEquation;
        currentBlendEquationAlpha = AddEquation;
      }
      if (premultipliedAlpha) {
        switch (blending) {
          case NormalBlending:
            gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            break;
          case AdditiveBlending:
            gl.blendFunc(gl.ONE, gl.ONE);
            break;
          case SubtractiveBlending:
            gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            break;
          case MultiplyBlending:
            gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            break;
          default:
            console.error('THREE.WebGLState: Invalid blending: ', blending);
            break;
        }
      } else {
        switch (blending) {
          case NormalBlending:
            gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            break;
          case AdditiveBlending:
            gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            break;
          case SubtractiveBlending:
            gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            break;
          case MultiplyBlending:
            gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            break;
          default:
            console.error('THREE.WebGLState: Invalid blending: ', blending);
            break;
        }
      }
      currentBlendSrc = null;
      currentBlendDst = null;
      currentBlendSrcAlpha = null;
      currentBlendDstAlpha = null;
      currentBlendColor.set(0, 0, 0);
      currentBlendAlpha = 0;
      currentBlending = blending;
      currentPremultipledAlpha = premultipliedAlpha;
    }
    return;
  }

  // custom blending

  blendEquationAlpha = blendEquationAlpha || blendEquation;
  blendSrcAlpha = blendSrcAlpha || blendSrc;
  blendDstAlpha = blendDstAlpha || blendDst;
  if (blendEquation !== currentBlendEquation || blendEquationAlpha !== currentBlendEquationAlpha) {
    gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
    currentBlendEquation = blendEquation;
    currentBlendEquationAlpha = blendEquationAlpha;
  }
  if (blendSrc !== currentBlendSrc || blendDst !== currentBlendDst || blendSrcAlpha !== currentBlendSrcAlpha || blendDstAlpha !== currentBlendDstAlpha) {
    gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
    currentBlendSrc = blendSrc;
    currentBlendDst = blendDst;
    currentBlendSrcAlpha = blendSrcAlpha;
    currentBlendDstAlpha = blendDstAlpha;
  }
  if (blendColor.equals(currentBlendColor) === false || blendAlpha !== currentBlendAlpha) {
    gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
    currentBlendColor.copy(blendColor);
    currentBlendAlpha = blendAlpha;
  }
  currentBlending = blending;
  currentPremultipledAlpha = false;
}
setBlending
blending
blendEquation
blendSrc
blendDst
blendEquationAlpha
blendSrcAlpha
blendDstAlpha
blendColor
blendAlpha
premultipliedAlpha
{
  if (blending === NoBlending) {
    if (currentBlendingEnabled === true) {
      disable(gl.BLEND);
      currentBlendingEnabled = false;
    }
    return;
  }
  if (currentBlendingEnabled === false) {
    enable(gl.BLEND);
    currentBlendingEnabled = true;
  }
  if (blending !== CustomBlending) {
    if (blending !== currentBlending || premultipliedAlpha !== currentPremultipledAlpha) {
      if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {
        gl.blendEquation(gl.FUNC_ADD);
        currentBlendEquation = AddEquation;
        currentBlendEquationAlpha = AddEquation;
      }
      if (premultipliedAlpha) {
        switch (blending) {
          case NormalBlending:
            gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            break;
          case AdditiveBlending:
            gl.blendFunc(gl.ONE, gl.ONE);
            break;
          case SubtractiveBlending:
            gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            break;
          case MultiplyBlending:
            gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
            break;
          default:
            console.error('THREE.WebGLState: Invalid blending: ', blending);
            break;
        }
      } else {
        switch (blending) {
          case NormalBlending:
            gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
            break;
          case AdditiveBlending:
            gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
            break;
          case SubtractiveBlending:
            gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
            break;
          case MultiplyBlending:
            gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
            break;
          default:
            console.error('THREE.WebGLState: Invalid blending: ', blending);
            break;
        }
      }
      currentBlendSrc = null;
      currentBlendDst = null;
      currentBlendSrcAlpha = null;
      currentBlendDstAlpha = null;
      currentBlendColor.set(0, 0, 0);
      currentBlendAlpha = 0;
      currentBlending = blending;
      currentPremultipledAlpha = premultipliedAlpha;
    }
    return;
  }

  // custom blending

  blendEquationAlpha = blendEquationAlpha || blendEquation;
  blendSrcAlpha = blendSrcAlpha || blendSrc;
  blendDstAlpha = blendDstAlpha || blendDst;
  if (blendEquation !== currentBlendEquation || blendEquationAlpha !== currentBlendEquationAlpha) {
    gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
    currentBlendEquation = blendEquation;
    currentBlendEquationAlpha = blendEquationAlpha;
  }
  if (blendSrc !== currentBlendSrc || blendDst !== currentBlendDst || blendSrcAlpha !== currentBlendSrcAlpha || blendDstAlpha !== currentBlendDstAlpha) {
    gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
    currentBlendSrc = blendSrc;
    currentBlendDst = blendDst;
    currentBlendSrcAlpha = blendSrcAlpha;
    currentBlendDstAlpha = blendDstAlpha;
  }
  if (blendColor.equals(currentBlendColor) === false || blendAlpha !== currentBlendAlpha) {
    gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
    currentBlendColor.copy(blendColor);
    currentBlendAlpha = blendAlpha;
  }
  currentBlending = blending;
  currentPremultipledAlpha = false;
}
if (blending === NoBlending) {
  if (currentBlendingEnabled === true) {
    disable(gl.BLEND);
    currentBlendingEnabled = false;
  }
  return;
}
blending === NoBlending
blending
NoBlending
{
  if (currentBlendingEnabled === true) {
    disable(gl.BLEND);
    currentBlendingEnabled = false;
  }
  return;
}
if (currentBlendingEnabled === true) {
  disable(gl.BLEND);
  currentBlendingEnabled = false;
}
currentBlendingEnabled === true
currentBlendingEnabled
true
{
  disable(gl.BLEND);
  currentBlendingEnabled = false;
}
disable(gl.BLEND);
disable(gl.BLEND)
disable
gl.BLEND
gl
BLEND
currentBlendingEnabled = false;
currentBlendingEnabled = false
currentBlendingEnabled
false
return;
if (currentBlendingEnabled === false) {
  enable(gl.BLEND);
  currentBlendingEnabled = true;
}
currentBlendingEnabled === false
currentBlendingEnabled
false
{
  enable(gl.BLEND);
  currentBlendingEnabled = true;
}
enable(gl.BLEND);
enable(gl.BLEND)
enable
gl.BLEND
gl
BLEND
currentBlendingEnabled = true;
currentBlendingEnabled = true
currentBlendingEnabled
true
if (blending !== CustomBlending) {
  if (blending !== currentBlending || premultipliedAlpha !== currentPremultipledAlpha) {
    if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {
      gl.blendEquation(gl.FUNC_ADD);
      currentBlendEquation = AddEquation;
      currentBlendEquationAlpha = AddEquation;
    }
    if (premultipliedAlpha) {
      switch (blending) {
        case NormalBlending:
          gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
          break;
        case AdditiveBlending:
          gl.blendFunc(gl.ONE, gl.ONE);
          break;
        case SubtractiveBlending:
          gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
          break;
        case MultiplyBlending:
          gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
          break;
        default:
          console.error('THREE.WebGLState: Invalid blending: ', blending);
          break;
      }
    } else {
      switch (blending) {
        case NormalBlending:
          gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
          break;
        case AdditiveBlending:
          gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
          break;
        case SubtractiveBlending:
          gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
          break;
        case MultiplyBlending:
          gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
          break;
        default:
          console.error('THREE.WebGLState: Invalid blending: ', blending);
          break;
      }
    }
    currentBlendSrc = null;
    currentBlendDst = null;
    currentBlendSrcAlpha = null;
    currentBlendDstAlpha = null;
    currentBlendColor.set(0, 0, 0);
    currentBlendAlpha = 0;
    currentBlending = blending;
    currentPremultipledAlpha = premultipliedAlpha;
  }
  return;
}

// custom blending
blending !== CustomBlending
blending
CustomBlending
{
  if (blending !== currentBlending || premultipliedAlpha !== currentPremultipledAlpha) {
    if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {
      gl.blendEquation(gl.FUNC_ADD);
      currentBlendEquation = AddEquation;
      currentBlendEquationAlpha = AddEquation;
    }
    if (premultipliedAlpha) {
      switch (blending) {
        case NormalBlending:
          gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
          break;
        case AdditiveBlending:
          gl.blendFunc(gl.ONE, gl.ONE);
          break;
        case SubtractiveBlending:
          gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
          break;
        case MultiplyBlending:
          gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
          break;
        default:
          console.error('THREE.WebGLState: Invalid blending: ', blending);
          break;
      }
    } else {
      switch (blending) {
        case NormalBlending:
          gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
          break;
        case AdditiveBlending:
          gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
          break;
        case SubtractiveBlending:
          gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
          break;
        case MultiplyBlending:
          gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
          break;
        default:
          console.error('THREE.WebGLState: Invalid blending: ', blending);
          break;
      }
    }
    currentBlendSrc = null;
    currentBlendDst = null;
    currentBlendSrcAlpha = null;
    currentBlendDstAlpha = null;
    currentBlendColor.set(0, 0, 0);
    currentBlendAlpha = 0;
    currentBlending = blending;
    currentPremultipledAlpha = premultipliedAlpha;
  }
  return;
}
if (blending !== currentBlending || premultipliedAlpha !== currentPremultipledAlpha) {
  if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {
    gl.blendEquation(gl.FUNC_ADD);
    currentBlendEquation = AddEquation;
    currentBlendEquationAlpha = AddEquation;
  }
  if (premultipliedAlpha) {
    switch (blending) {
      case NormalBlending:
        gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
        break;
      case AdditiveBlending:
        gl.blendFunc(gl.ONE, gl.ONE);
        break;
      case SubtractiveBlending:
        gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
        break;
      case MultiplyBlending:
        gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
        break;
      default:
        console.error('THREE.WebGLState: Invalid blending: ', blending);
        break;
    }
  } else {
    switch (blending) {
      case NormalBlending:
        gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
        break;
      case AdditiveBlending:
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
        break;
      case SubtractiveBlending:
        gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
        break;
      case MultiplyBlending:
        gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
        break;
      default:
        console.error('THREE.WebGLState: Invalid blending: ', blending);
        break;
    }
  }
  currentBlendSrc = null;
  currentBlendDst = null;
  currentBlendSrcAlpha = null;
  currentBlendDstAlpha = null;
  currentBlendColor.set(0, 0, 0);
  currentBlendAlpha = 0;
  currentBlending = blending;
  currentPremultipledAlpha = premultipliedAlpha;
}
blending !== currentBlending || premultipliedAlpha !== currentPremultipledAlpha
blending !== currentBlending
blending
currentBlending
premultipliedAlpha !== currentPremultipledAlpha
premultipliedAlpha
currentPremultipledAlpha
{
  if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {
    gl.blendEquation(gl.FUNC_ADD);
    currentBlendEquation = AddEquation;
    currentBlendEquationAlpha = AddEquation;
  }
  if (premultipliedAlpha) {
    switch (blending) {
      case NormalBlending:
        gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
        break;
      case AdditiveBlending:
        gl.blendFunc(gl.ONE, gl.ONE);
        break;
      case SubtractiveBlending:
        gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
        break;
      case MultiplyBlending:
        gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
        break;
      default:
        console.error('THREE.WebGLState: Invalid blending: ', blending);
        break;
    }
  } else {
    switch (blending) {
      case NormalBlending:
        gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
        break;
      case AdditiveBlending:
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
        break;
      case SubtractiveBlending:
        gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
        break;
      case MultiplyBlending:
        gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
        break;
      default:
        console.error('THREE.WebGLState: Invalid blending: ', blending);
        break;
    }
  }
  currentBlendSrc = null;
  currentBlendDst = null;
  currentBlendSrcAlpha = null;
  currentBlendDstAlpha = null;
  currentBlendColor.set(0, 0, 0);
  currentBlendAlpha = 0;
  currentBlending = blending;
  currentPremultipledAlpha = premultipliedAlpha;
}
if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {
  gl.blendEquation(gl.FUNC_ADD);
  currentBlendEquation = AddEquation;
  currentBlendEquationAlpha = AddEquation;
}
currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation
currentBlendEquation !== AddEquation
currentBlendEquation
AddEquation
currentBlendEquationAlpha !== AddEquation
currentBlendEquationAlpha
AddEquation
{
  gl.blendEquation(gl.FUNC_ADD);
  currentBlendEquation = AddEquation;
  currentBlendEquationAlpha = AddEquation;
}
gl.blendEquation(gl.FUNC_ADD);
gl.blendEquation(gl.FUNC_ADD)
gl.blendEquation
gl
blendEquation
gl.FUNC_ADD
gl
FUNC_ADD
currentBlendEquation = AddEquation;
currentBlendEquation = AddEquation
currentBlendEquation
AddEquation
currentBlendEquationAlpha = AddEquation;
currentBlendEquationAlpha = AddEquation
currentBlendEquationAlpha
AddEquation
if (premultipliedAlpha) {
  switch (blending) {
    case NormalBlending:
      gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
      break;
    case AdditiveBlending:
      gl.blendFunc(gl.ONE, gl.ONE);
      break;
    case SubtractiveBlending:
      gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
      break;
    case MultiplyBlending:
      gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
      break;
    default:
      console.error('THREE.WebGLState: Invalid blending: ', blending);
      break;
  }
} else {
  switch (blending) {
    case NormalBlending:
      gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
      break;
    case AdditiveBlending:
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
      break;
    case SubtractiveBlending:
      gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
      break;
    case MultiplyBlending:
      gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
      break;
    default:
      console.error('THREE.WebGLState: Invalid blending: ', blending);
      break;
  }
}
premultipliedAlpha
{
  switch (blending) {
    case NormalBlending:
      gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
      break;
    case AdditiveBlending:
      gl.blendFunc(gl.ONE, gl.ONE);
      break;
    case SubtractiveBlending:
      gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
      break;
    case MultiplyBlending:
      gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
      break;
    default:
      console.error('THREE.WebGLState: Invalid blending: ', blending);
      break;
  }
}
switch (blending) {
  case NormalBlending:
    gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
    break;
  case AdditiveBlending:
    gl.blendFunc(gl.ONE, gl.ONE);
    break;
  case SubtractiveBlending:
    gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
    break;
  case MultiplyBlending:
    gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
    break;
  default:
    console.error('THREE.WebGLState: Invalid blending: ', blending);
    break;
}
blending
case NormalBlending:
  gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
  break;
NormalBlending
gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA)
gl.blendFuncSeparate
gl
blendFuncSeparate
gl.ONE
gl
ONE
gl.ONE_MINUS_SRC_ALPHA
gl
ONE_MINUS_SRC_ALPHA
gl.ONE
gl
ONE
gl.ONE_MINUS_SRC_ALPHA
gl
ONE_MINUS_SRC_ALPHA
break;
case AdditiveBlending:
  gl.blendFunc(gl.ONE, gl.ONE);
  break;
AdditiveBlending
gl.blendFunc(gl.ONE, gl.ONE);
gl.blendFunc(gl.ONE, gl.ONE)
gl.blendFunc
gl
blendFunc
gl.ONE
gl
ONE
gl.ONE
gl
ONE
break;
case SubtractiveBlending:
  gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
  break;
SubtractiveBlending
gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE)
gl.blendFuncSeparate
gl
blendFuncSeparate
gl.ZERO
gl
ZERO
gl.ONE_MINUS_SRC_COLOR
gl
ONE_MINUS_SRC_COLOR
gl.ZERO
gl
ZERO
gl.ONE
gl
ONE
break;
case MultiplyBlending:
  gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
  break;
MultiplyBlending
gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA)
gl.blendFuncSeparate
gl
blendFuncSeparate
gl.ZERO
gl
ZERO
gl.SRC_COLOR
gl
SRC_COLOR
gl.ZERO
gl
ZERO
gl.SRC_ALPHA
gl
SRC_ALPHA
break;
default:
  console.error('THREE.WebGLState: Invalid blending: ', blending);
  break;
console.error('THREE.WebGLState: Invalid blending: ', blending);
console.error('THREE.WebGLState: Invalid blending: ', blending)
console.error
console
error
'THREE.WebGLState: Invalid blending: '
blending
break;
{
  switch (blending) {
    case NormalBlending:
      gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
      break;
    case AdditiveBlending:
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
      break;
    case SubtractiveBlending:
      gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
      break;
    case MultiplyBlending:
      gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
      break;
    default:
      console.error('THREE.WebGLState: Invalid blending: ', blending);
      break;
  }
}
switch (blending) {
  case NormalBlending:
    gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
    break;
  case AdditiveBlending:
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
    break;
  case SubtractiveBlending:
    gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
    break;
  case MultiplyBlending:
    gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
    break;
  default:
    console.error('THREE.WebGLState: Invalid blending: ', blending);
    break;
}
blending
case NormalBlending:
  gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
  break;
NormalBlending
gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA)
gl.blendFuncSeparate
gl
blendFuncSeparate
gl.SRC_ALPHA
gl
SRC_ALPHA
gl.ONE_MINUS_SRC_ALPHA
gl
ONE_MINUS_SRC_ALPHA
gl.ONE
gl
ONE
gl.ONE_MINUS_SRC_ALPHA
gl
ONE_MINUS_SRC_ALPHA
break;
case AdditiveBlending:
  gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
  break;
AdditiveBlending
gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
gl.blendFunc(gl.SRC_ALPHA, gl.ONE)
gl.blendFunc
gl
blendFunc
gl.SRC_ALPHA
gl
SRC_ALPHA
gl.ONE
gl
ONE
break;
case SubtractiveBlending:
  gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
  break;
SubtractiveBlending
gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE)
gl.blendFuncSeparate
gl
blendFuncSeparate
gl.ZERO
gl
ZERO
gl.ONE_MINUS_SRC_COLOR
gl
ONE_MINUS_SRC_COLOR
gl.ZERO
gl
ZERO
gl.ONE
gl
ONE
break;
case MultiplyBlending:
  gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
  break;
MultiplyBlending
gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
gl.blendFunc(gl.ZERO, gl.SRC_COLOR)
gl.blendFunc
gl
blendFunc
gl.ZERO
gl
ZERO
gl.SRC_COLOR
gl
SRC_COLOR
break;
default:
  console.error('THREE.WebGLState: Invalid blending: ', blending);
  break;
console.error('THREE.WebGLState: Invalid blending: ', blending);
console.error('THREE.WebGLState: Invalid blending: ', blending)
console.error
console
error
'THREE.WebGLState: Invalid blending: '
blending
break;
currentBlendSrc = null;
currentBlendSrc = null
currentBlendSrc
null
currentBlendDst = null;
currentBlendDst = null
currentBlendDst
null
currentBlendSrcAlpha = null;
currentBlendSrcAlpha = null
currentBlendSrcAlpha
null
currentBlendDstAlpha = null;
currentBlendDstAlpha = null
currentBlendDstAlpha
null
currentBlendColor.set(0, 0, 0);
currentBlendColor.set(0, 0, 0)
currentBlendColor.set
currentBlendColor
set
0
0
0
currentBlendAlpha = 0;
currentBlendAlpha = 0
currentBlendAlpha
0
currentBlending = blending;
currentBlending = blending
currentBlending
blending
currentPremultipledAlpha = premultipliedAlpha;
currentPremultipledAlpha = premultipliedAlpha
currentPremultipledAlpha
premultipliedAlpha
return;
// custom blending

blendEquationAlpha = blendEquationAlpha || blendEquation;
blendEquationAlpha = blendEquationAlpha || blendEquation
blendEquationAlpha
blendEquationAlpha || blendEquation
blendEquationAlpha
blendEquation
blendSrcAlpha = blendSrcAlpha || blendSrc;
blendSrcAlpha = blendSrcAlpha || blendSrc
blendSrcAlpha
blendSrcAlpha || blendSrc
blendSrcAlpha
blendSrc
blendDstAlpha = blendDstAlpha || blendDst;
blendDstAlpha = blendDstAlpha || blendDst
blendDstAlpha
blendDstAlpha || blendDst
blendDstAlpha
blendDst
if (blendEquation !== currentBlendEquation || blendEquationAlpha !== currentBlendEquationAlpha) {
  gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
  currentBlendEquation = blendEquation;
  currentBlendEquationAlpha = blendEquationAlpha;
}
blendEquation !== currentBlendEquation || blendEquationAlpha !== currentBlendEquationAlpha
blendEquation !== currentBlendEquation
blendEquation
currentBlendEquation
blendEquationAlpha !== currentBlendEquationAlpha
blendEquationAlpha
currentBlendEquationAlpha
{
  gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
  currentBlendEquation = blendEquation;
  currentBlendEquationAlpha = blendEquationAlpha;
}
gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha])
gl.blendEquationSeparate
gl
blendEquationSeparate
equationToGL[blendEquation]
equationToGL
blendEquation
equationToGL[blendEquationAlpha]
equationToGL
blendEquationAlpha
currentBlendEquation = blendEquation;
currentBlendEquation = blendEquation
currentBlendEquation
blendEquation
currentBlendEquationAlpha = blendEquationAlpha;
currentBlendEquationAlpha = blendEquationAlpha
currentBlendEquationAlpha
blendEquationAlpha
if (blendSrc !== currentBlendSrc || blendDst !== currentBlendDst || blendSrcAlpha !== currentBlendSrcAlpha || blendDstAlpha !== currentBlendDstAlpha) {
  gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
  currentBlendSrc = blendSrc;
  currentBlendDst = blendDst;
  currentBlendSrcAlpha = blendSrcAlpha;
  currentBlendDstAlpha = blendDstAlpha;
}
blendSrc !== currentBlendSrc || blendDst !== currentBlendDst || blendSrcAlpha !== currentBlendSrcAlpha || blendDstAlpha !== currentBlendDstAlpha
blendSrc !== currentBlendSrc || blendDst !== currentBlendDst || blendSrcAlpha !== currentBlendSrcAlpha
blendSrc !== currentBlendSrc || blendDst !== currentBlendDst
blendSrc !== currentBlendSrc
blendSrc
currentBlendSrc
blendDst !== currentBlendDst
blendDst
currentBlendDst
blendSrcAlpha !== currentBlendSrcAlpha
blendSrcAlpha
currentBlendSrcAlpha
blendDstAlpha !== currentBlendDstAlpha
blendDstAlpha
currentBlendDstAlpha
{
  gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
  currentBlendSrc = blendSrc;
  currentBlendDst = blendDst;
  currentBlendSrcAlpha = blendSrcAlpha;
  currentBlendDstAlpha = blendDstAlpha;
}
gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha])
gl.blendFuncSeparate
gl
blendFuncSeparate
factorToGL[blendSrc]
factorToGL
blendSrc
factorToGL[blendDst]
factorToGL
blendDst
factorToGL[blendSrcAlpha]
factorToGL
blendSrcAlpha
factorToGL[blendDstAlpha]
factorToGL
blendDstAlpha
currentBlendSrc = blendSrc;
currentBlendSrc = blendSrc
currentBlendSrc
blendSrc
currentBlendDst = blendDst;
currentBlendDst = blendDst
currentBlendDst
blendDst
currentBlendSrcAlpha = blendSrcAlpha;
currentBlendSrcAlpha = blendSrcAlpha
currentBlendSrcAlpha
blendSrcAlpha
currentBlendDstAlpha = blendDstAlpha;
currentBlendDstAlpha = blendDstAlpha
currentBlendDstAlpha
blendDstAlpha
if (blendColor.equals(currentBlendColor) === false || blendAlpha !== currentBlendAlpha) {
  gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
  currentBlendColor.copy(blendColor);
  currentBlendAlpha = blendAlpha;
}
blendColor.equals(currentBlendColor) === false || blendAlpha !== currentBlendAlpha
blendColor.equals(currentBlendColor) === false
blendColor.equals(currentBlendColor)
blendColor.equals
blendColor
equals
currentBlendColor
false
blendAlpha !== currentBlendAlpha
blendAlpha
currentBlendAlpha
{
  gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
  currentBlendColor.copy(blendColor);
  currentBlendAlpha = blendAlpha;
}
gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha)
gl.blendColor
gl
blendColor
blendColor.r
blendColor
r
blendColor.g
blendColor
g
blendColor.b
blendColor
b
blendAlpha
currentBlendColor.copy(blendColor);
currentBlendColor.copy(blendColor)
currentBlendColor.copy
currentBlendColor
copy
blendColor
currentBlendAlpha = blendAlpha;
currentBlendAlpha = blendAlpha
currentBlendAlpha
blendAlpha
currentBlending = blending;
currentBlending = blending
currentBlending
blending
currentPremultipledAlpha = false;
currentPremultipledAlpha = false
currentPremultipledAlpha
false
function setMaterial(material, frontFaceCW) {
  material.side === DoubleSide ? disable(gl.CULL_FACE) : enable(gl.CULL_FACE);
  let flipSided = material.side === BackSide;
  if (frontFaceCW) flipSided = !flipSided;
  setFlipSided(flipSided);
  material.blending === NormalBlending && material.transparent === false ? setBlending(NoBlending) : setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);
  depthBuffer.setFunc(material.depthFunc);
  depthBuffer.setTest(material.depthTest);
  depthBuffer.setMask(material.depthWrite);
  colorBuffer.setMask(material.colorWrite);
  const stencilWrite = material.stencilWrite;
  stencilBuffer.setTest(stencilWrite);
  if (stencilWrite) {
    stencilBuffer.setMask(material.stencilWriteMask);
    stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
    stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
  }
  setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
  material.alphaToCoverage === true ? enable(gl.SAMPLE_ALPHA_TO_COVERAGE) : disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
}

//
function setMaterial(material, frontFaceCW) {
  material.side === DoubleSide ? disable(gl.CULL_FACE) : enable(gl.CULL_FACE);
  let flipSided = material.side === BackSide;
  if (frontFaceCW) flipSided = !flipSided;
  setFlipSided(flipSided);
  material.blending === NormalBlending && material.transparent === false ? setBlending(NoBlending) : setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);
  depthBuffer.setFunc(material.depthFunc);
  depthBuffer.setTest(material.depthTest);
  depthBuffer.setMask(material.depthWrite);
  colorBuffer.setMask(material.colorWrite);
  const stencilWrite = material.stencilWrite;
  stencilBuffer.setTest(stencilWrite);
  if (stencilWrite) {
    stencilBuffer.setMask(material.stencilWriteMask);
    stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
    stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
  }
  setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
  material.alphaToCoverage === true ? enable(gl.SAMPLE_ALPHA_TO_COVERAGE) : disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
}

//
setMaterial
material
frontFaceCW
{
  material.side === DoubleSide ? disable(gl.CULL_FACE) : enable(gl.CULL_FACE);
  let flipSided = material.side === BackSide;
  if (frontFaceCW) flipSided = !flipSided;
  setFlipSided(flipSided);
  material.blending === NormalBlending && material.transparent === false ? setBlending(NoBlending) : setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);
  depthBuffer.setFunc(material.depthFunc);
  depthBuffer.setTest(material.depthTest);
  depthBuffer.setMask(material.depthWrite);
  colorBuffer.setMask(material.colorWrite);
  const stencilWrite = material.stencilWrite;
  stencilBuffer.setTest(stencilWrite);
  if (stencilWrite) {
    stencilBuffer.setMask(material.stencilWriteMask);
    stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
    stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
  }
  setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
  material.alphaToCoverage === true ? enable(gl.SAMPLE_ALPHA_TO_COVERAGE) : disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
}
material.side === DoubleSide ? disable(gl.CULL_FACE) : enable(gl.CULL_FACE);
material.side === DoubleSide ? disable(gl.CULL_FACE) : enable(gl.CULL_FACE)
material.side === DoubleSide
material.side
material
side
DoubleSide
disable(gl.CULL_FACE)
disable
gl.CULL_FACE
gl
CULL_FACE
enable(gl.CULL_FACE)
enable
gl.CULL_FACE
gl
CULL_FACE
let flipSided = material.side === BackSide;
flipSided = material.side === BackSide
flipSided
material.side === BackSide
material.side
material
side
BackSide
if (frontFaceCW) flipSided = !flipSided;
frontFaceCW
flipSided = !flipSided;
flipSided = !flipSided
flipSided
!flipSided
flipSided
setFlipSided(flipSided);
setFlipSided(flipSided)
setFlipSided
flipSided
material.blending === NormalBlending && material.transparent === false ? setBlending(NoBlending) : setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);
material.blending === NormalBlending && material.transparent === false ? setBlending(NoBlending) : setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha)
material.blending === NormalBlending && material.transparent === false
material.blending === NormalBlending
material.blending
material
blending
NormalBlending
material.transparent === false
material.transparent
material
transparent
false
setBlending(NoBlending)
setBlending
NoBlending
setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha)
setBlending
material.blending
material
blending
material.blendEquation
material
blendEquation
material.blendSrc
material
blendSrc
material.blendDst
material
blendDst
material.blendEquationAlpha
material
blendEquationAlpha
material.blendSrcAlpha
material
blendSrcAlpha
material.blendDstAlpha
material
blendDstAlpha
material.blendColor
material
blendColor
material.blendAlpha
material
blendAlpha
material.premultipliedAlpha
material
premultipliedAlpha
depthBuffer.setFunc(material.depthFunc);
depthBuffer.setFunc(material.depthFunc)
depthBuffer.setFunc
depthBuffer
setFunc
material.depthFunc
material
depthFunc
depthBuffer.setTest(material.depthTest);
depthBuffer.setTest(material.depthTest)
depthBuffer.setTest
depthBuffer
setTest
material.depthTest
material
depthTest
depthBuffer.setMask(material.depthWrite);
depthBuffer.setMask(material.depthWrite)
depthBuffer.setMask
depthBuffer
setMask
material.depthWrite
material
depthWrite
colorBuffer.setMask(material.colorWrite);
colorBuffer.setMask(material.colorWrite)
colorBuffer.setMask
colorBuffer
setMask
material.colorWrite
material
colorWrite
const stencilWrite = material.stencilWrite;
stencilWrite = material.stencilWrite
stencilWrite
material.stencilWrite
material
stencilWrite
stencilBuffer.setTest(stencilWrite);
stencilBuffer.setTest(stencilWrite)
stencilBuffer.setTest
stencilBuffer
setTest
stencilWrite
if (stencilWrite) {
  stencilBuffer.setMask(material.stencilWriteMask);
  stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
  stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
}
stencilWrite
{
  stencilBuffer.setMask(material.stencilWriteMask);
  stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
  stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
}
stencilBuffer.setMask(material.stencilWriteMask);
stencilBuffer.setMask(material.stencilWriteMask)
stencilBuffer.setMask
stencilBuffer
setMask
material.stencilWriteMask
material
stencilWriteMask
stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask)
stencilBuffer.setFunc
stencilBuffer
setFunc
material.stencilFunc
material
stencilFunc
material.stencilRef
material
stencilRef
material.stencilFuncMask
material
stencilFuncMask
stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass)
stencilBuffer.setOp
stencilBuffer
setOp
material.stencilFail
material
stencilFail
material.stencilZFail
material
stencilZFail
material.stencilZPass
material
stencilZPass
setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits)
setPolygonOffset
material.polygonOffset
material
polygonOffset
material.polygonOffsetFactor
material
polygonOffsetFactor
material.polygonOffsetUnits
material
polygonOffsetUnits
material.alphaToCoverage === true ? enable(gl.SAMPLE_ALPHA_TO_COVERAGE) : disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
material.alphaToCoverage === true ? enable(gl.SAMPLE_ALPHA_TO_COVERAGE) : disable(gl.SAMPLE_ALPHA_TO_COVERAGE)
material.alphaToCoverage === true
material.alphaToCoverage
material
alphaToCoverage
true
enable(gl.SAMPLE_ALPHA_TO_COVERAGE)
enable
gl.SAMPLE_ALPHA_TO_COVERAGE
gl
SAMPLE_ALPHA_TO_COVERAGE
disable(gl.SAMPLE_ALPHA_TO_COVERAGE)
disable
gl.SAMPLE_ALPHA_TO_COVERAGE
gl
SAMPLE_ALPHA_TO_COVERAGE
//

function setFlipSided(flipSided) {
  if (currentFlipSided !== flipSided) {
    if (flipSided) {
      gl.frontFace(gl.CW);
    } else {
      gl.frontFace(gl.CCW);
    }
    currentFlipSided = flipSided;
  }
}
//

function setFlipSided(flipSided) {
  if (currentFlipSided !== flipSided) {
    if (flipSided) {
      gl.frontFace(gl.CW);
    } else {
      gl.frontFace(gl.CCW);
    }
    currentFlipSided = flipSided;
  }
}
setFlipSided
flipSided
{
  if (currentFlipSided !== flipSided) {
    if (flipSided) {
      gl.frontFace(gl.CW);
    } else {
      gl.frontFace(gl.CCW);
    }
    currentFlipSided = flipSided;
  }
}
if (currentFlipSided !== flipSided) {
  if (flipSided) {
    gl.frontFace(gl.CW);
  } else {
    gl.frontFace(gl.CCW);
  }
  currentFlipSided = flipSided;
}
currentFlipSided !== flipSided
currentFlipSided
flipSided
{
  if (flipSided) {
    gl.frontFace(gl.CW);
  } else {
    gl.frontFace(gl.CCW);
  }
  currentFlipSided = flipSided;
}
if (flipSided) {
  gl.frontFace(gl.CW);
} else {
  gl.frontFace(gl.CCW);
}
flipSided
{
  gl.frontFace(gl.CW);
}
gl.frontFace(gl.CW);
gl.frontFace(gl.CW)
gl.frontFace
gl
frontFace
gl.CW
gl
CW
{
  gl.frontFace(gl.CCW);
}
gl.frontFace(gl.CCW);
gl.frontFace(gl.CCW)
gl.frontFace
gl
frontFace
gl.CCW
gl
CCW
currentFlipSided = flipSided;
currentFlipSided = flipSided
currentFlipSided
flipSided
function setCullFace(cullFace) {
  if (cullFace !== CullFaceNone) {
    enable(gl.CULL_FACE);
    if (cullFace !== currentCullFace) {
      if (cullFace === CullFaceBack) {
        gl.cullFace(gl.BACK);
      } else if (cullFace === CullFaceFront) {
        gl.cullFace(gl.FRONT);
      } else {
        gl.cullFace(gl.FRONT_AND_BACK);
      }
    }
  } else {
    disable(gl.CULL_FACE);
  }
  currentCullFace = cullFace;
}
function setCullFace(cullFace) {
  if (cullFace !== CullFaceNone) {
    enable(gl.CULL_FACE);
    if (cullFace !== currentCullFace) {
      if (cullFace === CullFaceBack) {
        gl.cullFace(gl.BACK);
      } else if (cullFace === CullFaceFront) {
        gl.cullFace(gl.FRONT);
      } else {
        gl.cullFace(gl.FRONT_AND_BACK);
      }
    }
  } else {
    disable(gl.CULL_FACE);
  }
  currentCullFace = cullFace;
}
setCullFace
cullFace
{
  if (cullFace !== CullFaceNone) {
    enable(gl.CULL_FACE);
    if (cullFace !== currentCullFace) {
      if (cullFace === CullFaceBack) {
        gl.cullFace(gl.BACK);
      } else if (cullFace === CullFaceFront) {
        gl.cullFace(gl.FRONT);
      } else {
        gl.cullFace(gl.FRONT_AND_BACK);
      }
    }
  } else {
    disable(gl.CULL_FACE);
  }
  currentCullFace = cullFace;
}
if (cullFace !== CullFaceNone) {
  enable(gl.CULL_FACE);
  if (cullFace !== currentCullFace) {
    if (cullFace === CullFaceBack) {
      gl.cullFace(gl.BACK);
    } else if (cullFace === CullFaceFront) {
      gl.cullFace(gl.FRONT);
    } else {
      gl.cullFace(gl.FRONT_AND_BACK);
    }
  }
} else {
  disable(gl.CULL_FACE);
}
cullFace !== CullFaceNone
cullFace
CullFaceNone
{
  enable(gl.CULL_FACE);
  if (cullFace !== currentCullFace) {
    if (cullFace === CullFaceBack) {
      gl.cullFace(gl.BACK);
    } else if (cullFace === CullFaceFront) {
      gl.cullFace(gl.FRONT);
    } else {
      gl.cullFace(gl.FRONT_AND_BACK);
    }
  }
}
enable(gl.CULL_FACE);
enable(gl.CULL_FACE)
enable
gl.CULL_FACE
gl
CULL_FACE
if (cullFace !== currentCullFace) {
  if (cullFace === CullFaceBack) {
    gl.cullFace(gl.BACK);
  } else if (cullFace === CullFaceFront) {
    gl.cullFace(gl.FRONT);
  } else {
    gl.cullFace(gl.FRONT_AND_BACK);
  }
}
cullFace !== currentCullFace
cullFace
currentCullFace
{
  if (cullFace === CullFaceBack) {
    gl.cullFace(gl.BACK);
  } else if (cullFace === CullFaceFront) {
    gl.cullFace(gl.FRONT);
  } else {
    gl.cullFace(gl.FRONT_AND_BACK);
  }
}
if (cullFace === CullFaceBack) {
  gl.cullFace(gl.BACK);
} else if (cullFace === CullFaceFront) {
  gl.cullFace(gl.FRONT);
} else {
  gl.cullFace(gl.FRONT_AND_BACK);
}
cullFace === CullFaceBack
cullFace
CullFaceBack
{
  gl.cullFace(gl.BACK);
}
gl.cullFace(gl.BACK);
gl.cullFace(gl.BACK)
gl.cullFace
gl
cullFace
gl.BACK
gl
BACK
if (cullFace === CullFaceFront) {
  gl.cullFace(gl.FRONT);
} else {
  gl.cullFace(gl.FRONT_AND_BACK);
}
cullFace === CullFaceFront
cullFace
CullFaceFront
{
  gl.cullFace(gl.FRONT);
}
gl.cullFace(gl.FRONT);
gl.cullFace(gl.FRONT)
gl.cullFace
gl
cullFace
gl.FRONT
gl
FRONT
{
  gl.cullFace(gl.FRONT_AND_BACK);
}
gl.cullFace(gl.FRONT_AND_BACK);
gl.cullFace(gl.FRONT_AND_BACK)
gl.cullFace
gl
cullFace
gl.FRONT_AND_BACK
gl
FRONT_AND_BACK
{
  disable(gl.CULL_FACE);
}
disable(gl.CULL_FACE);
disable(gl.CULL_FACE)
disable
gl.CULL_FACE
gl
CULL_FACE
currentCullFace = cullFace;
currentCullFace = cullFace
currentCullFace
cullFace
function setLineWidth(width) {
  if (width !== currentLineWidth) {
    if (lineWidthAvailable) gl.lineWidth(width);
    currentLineWidth = width;
  }
}
function setLineWidth(width) {
  if (width !== currentLineWidth) {
    if (lineWidthAvailable) gl.lineWidth(width);
    currentLineWidth = width;
  }
}
setLineWidth
width
{
  if (width !== currentLineWidth) {
    if (lineWidthAvailable) gl.lineWidth(width);
    currentLineWidth = width;
  }
}
if (width !== currentLineWidth) {
  if (lineWidthAvailable) gl.lineWidth(width);
  currentLineWidth = width;
}
width !== currentLineWidth
width
currentLineWidth
{
  if (lineWidthAvailable) gl.lineWidth(width);
  currentLineWidth = width;
}
if (lineWidthAvailable) gl.lineWidth(width);
lineWidthAvailable
gl.lineWidth(width);
gl.lineWidth(width)
gl.lineWidth
gl
lineWidth
width
currentLineWidth = width;
currentLineWidth = width
currentLineWidth
width
function setPolygonOffset(polygonOffset, factor, units) {
  if (polygonOffset) {
    enable(gl.POLYGON_OFFSET_FILL);
    if (currentPolygonOffsetFactor !== factor || currentPolygonOffsetUnits !== units) {
      gl.polygonOffset(factor, units);
      currentPolygonOffsetFactor = factor;
      currentPolygonOffsetUnits = units;
    }
  } else {
    disable(gl.POLYGON_OFFSET_FILL);
  }
}
function setPolygonOffset(polygonOffset, factor, units) {
  if (polygonOffset) {
    enable(gl.POLYGON_OFFSET_FILL);
    if (currentPolygonOffsetFactor !== factor || currentPolygonOffsetUnits !== units) {
      gl.polygonOffset(factor, units);
      currentPolygonOffsetFactor = factor;
      currentPolygonOffsetUnits = units;
    }
  } else {
    disable(gl.POLYGON_OFFSET_FILL);
  }
}
setPolygonOffset
polygonOffset
factor
units
{
  if (polygonOffset) {
    enable(gl.POLYGON_OFFSET_FILL);
    if (currentPolygonOffsetFactor !== factor || currentPolygonOffsetUnits !== units) {
      gl.polygonOffset(factor, units);
      currentPolygonOffsetFactor = factor;
      currentPolygonOffsetUnits = units;
    }
  } else {
    disable(gl.POLYGON_OFFSET_FILL);
  }
}
if (polygonOffset) {
  enable(gl.POLYGON_OFFSET_FILL);
  if (currentPolygonOffsetFactor !== factor || currentPolygonOffsetUnits !== units) {
    gl.polygonOffset(factor, units);
    currentPolygonOffsetFactor = factor;
    currentPolygonOffsetUnits = units;
  }
} else {
  disable(gl.POLYGON_OFFSET_FILL);
}
polygonOffset
{
  enable(gl.POLYGON_OFFSET_FILL);
  if (currentPolygonOffsetFactor !== factor || currentPolygonOffsetUnits !== units) {
    gl.polygonOffset(factor, units);
    currentPolygonOffsetFactor = factor;
    currentPolygonOffsetUnits = units;
  }
}
enable(gl.POLYGON_OFFSET_FILL);
enable(gl.POLYGON_OFFSET_FILL)
enable
gl.POLYGON_OFFSET_FILL
gl
POLYGON_OFFSET_FILL
if (currentPolygonOffsetFactor !== factor || currentPolygonOffsetUnits !== units) {
  gl.polygonOffset(factor, units);
  currentPolygonOffsetFactor = factor;
  currentPolygonOffsetUnits = units;
}
currentPolygonOffsetFactor !== factor || currentPolygonOffsetUnits !== units
currentPolygonOffsetFactor !== factor
currentPolygonOffsetFactor
factor
currentPolygonOffsetUnits !== units
currentPolygonOffsetUnits
units
{
  gl.polygonOffset(factor, units);
  currentPolygonOffsetFactor = factor;
  currentPolygonOffsetUnits = units;
}
gl.polygonOffset(factor, units);
gl.polygonOffset(factor, units)
gl.polygonOffset
gl
polygonOffset
factor
units
currentPolygonOffsetFactor = factor;
currentPolygonOffsetFactor = factor
currentPolygonOffsetFactor
factor
currentPolygonOffsetUnits = units;
currentPolygonOffsetUnits = units
currentPolygonOffsetUnits
units
{
  disable(gl.POLYGON_OFFSET_FILL);
}
disable(gl.POLYGON_OFFSET_FILL);
disable(gl.POLYGON_OFFSET_FILL)
disable
gl.POLYGON_OFFSET_FILL
gl
POLYGON_OFFSET_FILL
function setScissorTest(scissorTest) {
  if (scissorTest) {
    enable(gl.SCISSOR_TEST);
  } else {
    disable(gl.SCISSOR_TEST);
  }
}

// texture
function setScissorTest(scissorTest) {
  if (scissorTest) {
    enable(gl.SCISSOR_TEST);
  } else {
    disable(gl.SCISSOR_TEST);
  }
}

// texture
setScissorTest
scissorTest
{
  if (scissorTest) {
    enable(gl.SCISSOR_TEST);
  } else {
    disable(gl.SCISSOR_TEST);
  }
}
if (scissorTest) {
  enable(gl.SCISSOR_TEST);
} else {
  disable(gl.SCISSOR_TEST);
}
scissorTest
{
  enable(gl.SCISSOR_TEST);
}
enable(gl.SCISSOR_TEST);
enable(gl.SCISSOR_TEST)
enable
gl.SCISSOR_TEST
gl
SCISSOR_TEST
{
  disable(gl.SCISSOR_TEST);
}
disable(gl.SCISSOR_TEST);
disable(gl.SCISSOR_TEST)
disable
gl.SCISSOR_TEST
gl
SCISSOR_TEST
// texture

function activeTexture(webglSlot) {
  if (webglSlot === undefined) webglSlot = gl.TEXTURE0 + maxTextures - 1;
  if (currentTextureSlot !== webglSlot) {
    gl.activeTexture(webglSlot);
    currentTextureSlot = webglSlot;
  }
}
// texture

function activeTexture(webglSlot) {
  if (webglSlot === undefined) webglSlot = gl.TEXTURE0 + maxTextures - 1;
  if (currentTextureSlot !== webglSlot) {
    gl.activeTexture(webglSlot);
    currentTextureSlot = webglSlot;
  }
}
activeTexture
webglSlot
{
  if (webglSlot === undefined) webglSlot = gl.TEXTURE0 + maxTextures - 1;
  if (currentTextureSlot !== webglSlot) {
    gl.activeTexture(webglSlot);
    currentTextureSlot = webglSlot;
  }
}
if (webglSlot === undefined) webglSlot = gl.TEXTURE0 + maxTextures - 1;
webglSlot === undefined
webglSlot
undefined
webglSlot = gl.TEXTURE0 + maxTextures - 1;
webglSlot = gl.TEXTURE0 + maxTextures - 1
webglSlot
gl.TEXTURE0 + maxTextures - 1
gl.TEXTURE0 + maxTextures
gl.TEXTURE0
gl
TEXTURE0
maxTextures
1
if (currentTextureSlot !== webglSlot) {
  gl.activeTexture(webglSlot);
  currentTextureSlot = webglSlot;
}
currentTextureSlot !== webglSlot
currentTextureSlot
webglSlot
{
  gl.activeTexture(webglSlot);
  currentTextureSlot = webglSlot;
}
gl.activeTexture(webglSlot);
gl.activeTexture(webglSlot)
gl.activeTexture
gl
activeTexture
webglSlot
currentTextureSlot = webglSlot;
currentTextureSlot = webglSlot
currentTextureSlot
webglSlot
function bindTexture(webglType, webglTexture, webglSlot) {
  if (webglSlot === undefined) {
    if (currentTextureSlot === null) {
      webglSlot = gl.TEXTURE0 + maxTextures - 1;
    } else {
      webglSlot = currentTextureSlot;
    }
  }
  let boundTexture = currentBoundTextures[webglSlot];
  if (boundTexture === undefined) {
    boundTexture = {
      type: undefined,
      texture: undefined
    };
    currentBoundTextures[webglSlot] = boundTexture;
  }
  if (boundTexture.type !== webglType || boundTexture.texture !== webglTexture) {
    if (currentTextureSlot !== webglSlot) {
      gl.activeTexture(webglSlot);
      currentTextureSlot = webglSlot;
    }
    gl.bindTexture(webglType, webglTexture || emptyTextures[webglType]);
    boundTexture.type = webglType;
    boundTexture.texture = webglTexture;
  }
}
function bindTexture(webglType, webglTexture, webglSlot) {
  if (webglSlot === undefined) {
    if (currentTextureSlot === null) {
      webglSlot = gl.TEXTURE0 + maxTextures - 1;
    } else {
      webglSlot = currentTextureSlot;
    }
  }
  let boundTexture = currentBoundTextures[webglSlot];
  if (boundTexture === undefined) {
    boundTexture = {
      type: undefined,
      texture: undefined
    };
    currentBoundTextures[webglSlot] = boundTexture;
  }
  if (boundTexture.type !== webglType || boundTexture.texture !== webglTexture) {
    if (currentTextureSlot !== webglSlot) {
      gl.activeTexture(webglSlot);
      currentTextureSlot = webglSlot;
    }
    gl.bindTexture(webglType, webglTexture || emptyTextures[webglType]);
    boundTexture.type = webglType;
    boundTexture.texture = webglTexture;
  }
}
bindTexture
webglType
webglTexture
webglSlot
{
  if (webglSlot === undefined) {
    if (currentTextureSlot === null) {
      webglSlot = gl.TEXTURE0 + maxTextures - 1;
    } else {
      webglSlot = currentTextureSlot;
    }
  }
  let boundTexture = currentBoundTextures[webglSlot];
  if (boundTexture === undefined) {
    boundTexture = {
      type: undefined,
      texture: undefined
    };
    currentBoundTextures[webglSlot] = boundTexture;
  }
  if (boundTexture.type !== webglType || boundTexture.texture !== webglTexture) {
    if (currentTextureSlot !== webglSlot) {
      gl.activeTexture(webglSlot);
      currentTextureSlot = webglSlot;
    }
    gl.bindTexture(webglType, webglTexture || emptyTextures[webglType]);
    boundTexture.type = webglType;
    boundTexture.texture = webglTexture;
  }
}
if (webglSlot === undefined) {
  if (currentTextureSlot === null) {
    webglSlot = gl.TEXTURE0 + maxTextures - 1;
  } else {
    webglSlot = currentTextureSlot;
  }
}
webglSlot === undefined
webglSlot
undefined
{
  if (currentTextureSlot === null) {
    webglSlot = gl.TEXTURE0 + maxTextures - 1;
  } else {
    webglSlot = currentTextureSlot;
  }
}
if (currentTextureSlot === null) {
  webglSlot = gl.TEXTURE0 + maxTextures - 1;
} else {
  webglSlot = currentTextureSlot;
}
currentTextureSlot === null
currentTextureSlot
null
{
  webglSlot = gl.TEXTURE0 + maxTextures - 1;
}
webglSlot = gl.TEXTURE0 + maxTextures - 1;
webglSlot = gl.TEXTURE0 + maxTextures - 1
webglSlot
gl.TEXTURE0 + maxTextures - 1
gl.TEXTURE0 + maxTextures
gl.TEXTURE0
gl
TEXTURE0
maxTextures
1
{
  webglSlot = currentTextureSlot;
}
webglSlot = currentTextureSlot;
webglSlot = currentTextureSlot
webglSlot
currentTextureSlot
let boundTexture = currentBoundTextures[webglSlot];
boundTexture = currentBoundTextures[webglSlot]
boundTexture
currentBoundTextures[webglSlot]
currentBoundTextures
webglSlot
if (boundTexture === undefined) {
  boundTexture = {
    type: undefined,
    texture: undefined
  };
  currentBoundTextures[webglSlot] = boundTexture;
}
boundTexture === undefined
boundTexture
undefined
{
  boundTexture = {
    type: undefined,
    texture: undefined
  };
  currentBoundTextures[webglSlot] = boundTexture;
}
boundTexture = {
  type: undefined,
  texture: undefined
};
boundTexture = {
  type: undefined,
  texture: undefined
}
boundTexture
{
  type: undefined,
  texture: undefined
}
type: undefined
type
undefined
texture: undefined
texture
undefined
currentBoundTextures[webglSlot] = boundTexture;
currentBoundTextures[webglSlot] = boundTexture
currentBoundTextures[webglSlot]
currentBoundTextures
webglSlot
boundTexture
if (boundTexture.type !== webglType || boundTexture.texture !== webglTexture) {
  if (currentTextureSlot !== webglSlot) {
    gl.activeTexture(webglSlot);
    currentTextureSlot = webglSlot;
  }
  gl.bindTexture(webglType, webglTexture || emptyTextures[webglType]);
  boundTexture.type = webglType;
  boundTexture.texture = webglTexture;
}
boundTexture.type !== webglType || boundTexture.texture !== webglTexture
boundTexture.type !== webglType
boundTexture.type
boundTexture
type
webglType
boundTexture.texture !== webglTexture
boundTexture.texture
boundTexture
texture
webglTexture
{
  if (currentTextureSlot !== webglSlot) {
    gl.activeTexture(webglSlot);
    currentTextureSlot = webglSlot;
  }
  gl.bindTexture(webglType, webglTexture || emptyTextures[webglType]);
  boundTexture.type = webglType;
  boundTexture.texture = webglTexture;
}
if (currentTextureSlot !== webglSlot) {
  gl.activeTexture(webglSlot);
  currentTextureSlot = webglSlot;
}
currentTextureSlot !== webglSlot
currentTextureSlot
webglSlot
{
  gl.activeTexture(webglSlot);
  currentTextureSlot = webglSlot;
}
gl.activeTexture(webglSlot);
gl.activeTexture(webglSlot)
gl.activeTexture
gl
activeTexture
webglSlot
currentTextureSlot = webglSlot;
currentTextureSlot = webglSlot
currentTextureSlot
webglSlot
gl.bindTexture(webglType, webglTexture || emptyTextures[webglType]);
gl.bindTexture(webglType, webglTexture || emptyTextures[webglType])
gl.bindTexture
gl
bindTexture
webglType
webglTexture || emptyTextures[webglType]
webglTexture
emptyTextures[webglType]
emptyTextures
webglType
boundTexture.type = webglType;
boundTexture.type = webglType
boundTexture.type
boundTexture
type
webglType
boundTexture.texture = webglTexture;
boundTexture.texture = webglTexture
boundTexture.texture
boundTexture
texture
webglTexture
function unbindTexture() {
  const boundTexture = currentBoundTextures[currentTextureSlot];
  if (boundTexture !== undefined && boundTexture.type !== undefined) {
    gl.bindTexture(boundTexture.type, null);
    boundTexture.type = undefined;
    boundTexture.texture = undefined;
  }
}
function unbindTexture() {
  const boundTexture = currentBoundTextures[currentTextureSlot];
  if (boundTexture !== undefined && boundTexture.type !== undefined) {
    gl.bindTexture(boundTexture.type, null);
    boundTexture.type = undefined;
    boundTexture.texture = undefined;
  }
}
unbindTexture
{
  const boundTexture = currentBoundTextures[currentTextureSlot];
  if (boundTexture !== undefined && boundTexture.type !== undefined) {
    gl.bindTexture(boundTexture.type, null);
    boundTexture.type = undefined;
    boundTexture.texture = undefined;
  }
}
const boundTexture = currentBoundTextures[currentTextureSlot];
boundTexture = currentBoundTextures[currentTextureSlot]
boundTexture
currentBoundTextures[currentTextureSlot]
currentBoundTextures
currentTextureSlot
if (boundTexture !== undefined && boundTexture.type !== undefined) {
  gl.bindTexture(boundTexture.type, null);
  boundTexture.type = undefined;
  boundTexture.texture = undefined;
}
boundTexture !== undefined && boundTexture.type !== undefined
boundTexture !== undefined
boundTexture
undefined
boundTexture.type !== undefined
boundTexture.type
boundTexture
type
undefined
{
  gl.bindTexture(boundTexture.type, null);
  boundTexture.type = undefined;
  boundTexture.texture = undefined;
}
gl.bindTexture(boundTexture.type, null);
gl.bindTexture(boundTexture.type, null)
gl.bindTexture
gl
bindTexture
boundTexture.type
boundTexture
type
null
boundTexture.type = undefined;
boundTexture.type = undefined
boundTexture.type
boundTexture
type
undefined
boundTexture.texture = undefined;
boundTexture.texture = undefined
boundTexture.texture
boundTexture
texture
undefined
function compressedTexImage2D() {
  try {
    gl.compressedTexImage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
function compressedTexImage2D() {
  try {
    gl.compressedTexImage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
compressedTexImage2D
{
  try {
    gl.compressedTexImage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
try {
  gl.compressedTexImage2D.apply(gl, arguments);
} catch (error) {
  console.error('THREE.WebGLState:', error);
}
{
  gl.compressedTexImage2D.apply(gl, arguments);
}
gl.compressedTexImage2D.apply(gl, arguments);
gl.compressedTexImage2D.apply(gl, arguments)
gl.compressedTexImage2D.apply
gl.compressedTexImage2D
gl
compressedTexImage2D
apply
gl
arguments
catch (error) {
  console.error('THREE.WebGLState:', error);
}
error
{
  console.error('THREE.WebGLState:', error);
}
console.error('THREE.WebGLState:', error);
console.error('THREE.WebGLState:', error)
console.error
console
error
'THREE.WebGLState:'
error
function compressedTexImage3D() {
  try {
    gl.compressedTexImage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
function compressedTexImage3D() {
  try {
    gl.compressedTexImage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
compressedTexImage3D
{
  try {
    gl.compressedTexImage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
try {
  gl.compressedTexImage3D.apply(gl, arguments);
} catch (error) {
  console.error('THREE.WebGLState:', error);
}
{
  gl.compressedTexImage3D.apply(gl, arguments);
}
gl.compressedTexImage3D.apply(gl, arguments);
gl.compressedTexImage3D.apply(gl, arguments)
gl.compressedTexImage3D.apply
gl.compressedTexImage3D
gl
compressedTexImage3D
apply
gl
arguments
catch (error) {
  console.error('THREE.WebGLState:', error);
}
error
{
  console.error('THREE.WebGLState:', error);
}
console.error('THREE.WebGLState:', error);
console.error('THREE.WebGLState:', error)
console.error
console
error
'THREE.WebGLState:'
error
function texSubImage2D() {
  try {
    gl.texSubImage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
function texSubImage2D() {
  try {
    gl.texSubImage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
texSubImage2D
{
  try {
    gl.texSubImage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
try {
  gl.texSubImage2D.apply(gl, arguments);
} catch (error) {
  console.error('THREE.WebGLState:', error);
}
{
  gl.texSubImage2D.apply(gl, arguments);
}
gl.texSubImage2D.apply(gl, arguments);
gl.texSubImage2D.apply(gl, arguments)
gl.texSubImage2D.apply
gl.texSubImage2D
gl
texSubImage2D
apply
gl
arguments
catch (error) {
  console.error('THREE.WebGLState:', error);
}
error
{
  console.error('THREE.WebGLState:', error);
}
console.error('THREE.WebGLState:', error);
console.error('THREE.WebGLState:', error)
console.error
console
error
'THREE.WebGLState:'
error
function texSubImage3D() {
  try {
    gl.texSubImage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
function texSubImage3D() {
  try {
    gl.texSubImage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
texSubImage3D
{
  try {
    gl.texSubImage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
try {
  gl.texSubImage3D.apply(gl, arguments);
} catch (error) {
  console.error('THREE.WebGLState:', error);
}
{
  gl.texSubImage3D.apply(gl, arguments);
}
gl.texSubImage3D.apply(gl, arguments);
gl.texSubImage3D.apply(gl, arguments)
gl.texSubImage3D.apply
gl.texSubImage3D
gl
texSubImage3D
apply
gl
arguments
catch (error) {
  console.error('THREE.WebGLState:', error);
}
error
{
  console.error('THREE.WebGLState:', error);
}
console.error('THREE.WebGLState:', error);
console.error('THREE.WebGLState:', error)
console.error
console
error
'THREE.WebGLState:'
error
function compressedTexSubImage2D() {
  try {
    gl.compressedTexSubImage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
function compressedTexSubImage2D() {
  try {
    gl.compressedTexSubImage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
compressedTexSubImage2D
{
  try {
    gl.compressedTexSubImage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
try {
  gl.compressedTexSubImage2D.apply(gl, arguments);
} catch (error) {
  console.error('THREE.WebGLState:', error);
}
{
  gl.compressedTexSubImage2D.apply(gl, arguments);
}
gl.compressedTexSubImage2D.apply(gl, arguments);
gl.compressedTexSubImage2D.apply(gl, arguments)
gl.compressedTexSubImage2D.apply
gl.compressedTexSubImage2D
gl
compressedTexSubImage2D
apply
gl
arguments
catch (error) {
  console.error('THREE.WebGLState:', error);
}
error
{
  console.error('THREE.WebGLState:', error);
}
console.error('THREE.WebGLState:', error);
console.error('THREE.WebGLState:', error)
console.error
console
error
'THREE.WebGLState:'
error
function compressedTexSubImage3D() {
  try {
    gl.compressedTexSubImage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
function compressedTexSubImage3D() {
  try {
    gl.compressedTexSubImage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
compressedTexSubImage3D
{
  try {
    gl.compressedTexSubImage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
try {
  gl.compressedTexSubImage3D.apply(gl, arguments);
} catch (error) {
  console.error('THREE.WebGLState:', error);
}
{
  gl.compressedTexSubImage3D.apply(gl, arguments);
}
gl.compressedTexSubImage3D.apply(gl, arguments);
gl.compressedTexSubImage3D.apply(gl, arguments)
gl.compressedTexSubImage3D.apply
gl.compressedTexSubImage3D
gl
compressedTexSubImage3D
apply
gl
arguments
catch (error) {
  console.error('THREE.WebGLState:', error);
}
error
{
  console.error('THREE.WebGLState:', error);
}
console.error('THREE.WebGLState:', error);
console.error('THREE.WebGLState:', error)
console.error
console
error
'THREE.WebGLState:'
error
function texStorage2D() {
  try {
    gl.texStorage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
function texStorage2D() {
  try {
    gl.texStorage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
texStorage2D
{
  try {
    gl.texStorage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
try {
  gl.texStorage2D.apply(gl, arguments);
} catch (error) {
  console.error('THREE.WebGLState:', error);
}
{
  gl.texStorage2D.apply(gl, arguments);
}
gl.texStorage2D.apply(gl, arguments);
gl.texStorage2D.apply(gl, arguments)
gl.texStorage2D.apply
gl.texStorage2D
gl
texStorage2D
apply
gl
arguments
catch (error) {
  console.error('THREE.WebGLState:', error);
}
error
{
  console.error('THREE.WebGLState:', error);
}
console.error('THREE.WebGLState:', error);
console.error('THREE.WebGLState:', error)
console.error
console
error
'THREE.WebGLState:'
error
function texStorage3D() {
  try {
    gl.texStorage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
function texStorage3D() {
  try {
    gl.texStorage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
texStorage3D
{
  try {
    gl.texStorage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
try {
  gl.texStorage3D.apply(gl, arguments);
} catch (error) {
  console.error('THREE.WebGLState:', error);
}
{
  gl.texStorage3D.apply(gl, arguments);
}
gl.texStorage3D.apply(gl, arguments);
gl.texStorage3D.apply(gl, arguments)
gl.texStorage3D.apply
gl.texStorage3D
gl
texStorage3D
apply
gl
arguments
catch (error) {
  console.error('THREE.WebGLState:', error);
}
error
{
  console.error('THREE.WebGLState:', error);
}
console.error('THREE.WebGLState:', error);
console.error('THREE.WebGLState:', error)
console.error
console
error
'THREE.WebGLState:'
error
function texImage2D() {
  try {
    gl.texImage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
function texImage2D() {
  try {
    gl.texImage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
texImage2D
{
  try {
    gl.texImage2D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
try {
  gl.texImage2D.apply(gl, arguments);
} catch (error) {
  console.error('THREE.WebGLState:', error);
}
{
  gl.texImage2D.apply(gl, arguments);
}
gl.texImage2D.apply(gl, arguments);
gl.texImage2D.apply(gl, arguments)
gl.texImage2D.apply
gl.texImage2D
gl
texImage2D
apply
gl
arguments
catch (error) {
  console.error('THREE.WebGLState:', error);
}
error
{
  console.error('THREE.WebGLState:', error);
}
console.error('THREE.WebGLState:', error);
console.error('THREE.WebGLState:', error)
console.error
console
error
'THREE.WebGLState:'
error
function texImage3D() {
  try {
    gl.texImage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}

//
function texImage3D() {
  try {
    gl.texImage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}

//
texImage3D
{
  try {
    gl.texImage3D.apply(gl, arguments);
  } catch (error) {
    console.error('THREE.WebGLState:', error);
  }
}
try {
  gl.texImage3D.apply(gl, arguments);
} catch (error) {
  console.error('THREE.WebGLState:', error);
}
{
  gl.texImage3D.apply(gl, arguments);
}
gl.texImage3D.apply(gl, arguments);
gl.texImage3D.apply(gl, arguments)
gl.texImage3D.apply
gl.texImage3D
gl
texImage3D
apply
gl
arguments
catch (error) {
  console.error('THREE.WebGLState:', error);
}
error
{
  console.error('THREE.WebGLState:', error);
}
console.error('THREE.WebGLState:', error);
console.error('THREE.WebGLState:', error)
console.error
console
error
'THREE.WebGLState:'
error
//

function scissor(scissor) {
  if (currentScissor.equals(scissor) === false) {
    gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
    currentScissor.copy(scissor);
  }
}
//

function scissor(scissor) {
  if (currentScissor.equals(scissor) === false) {
    gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
    currentScissor.copy(scissor);
  }
}
scissor
scissor
{
  if (currentScissor.equals(scissor) === false) {
    gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
    currentScissor.copy(scissor);
  }
}
if (currentScissor.equals(scissor) === false) {
  gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
  currentScissor.copy(scissor);
}
currentScissor.equals(scissor) === false
currentScissor.equals(scissor)
currentScissor.equals
currentScissor
equals
scissor
false
{
  gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
  currentScissor.copy(scissor);
}
gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w)
gl.scissor
gl
scissor
scissor.x
scissor
x
scissor.y
scissor
y
scissor.z
scissor
z
scissor.w
scissor
w
currentScissor.copy(scissor);
currentScissor.copy(scissor)
currentScissor.copy
currentScissor
copy
scissor
function viewport(viewport) {
  if (currentViewport.equals(viewport) === false) {
    gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
    currentViewport.copy(viewport);
  }
}
function viewport(viewport) {
  if (currentViewport.equals(viewport) === false) {
    gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
    currentViewport.copy(viewport);
  }
}
viewport
viewport
{
  if (currentViewport.equals(viewport) === false) {
    gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
    currentViewport.copy(viewport);
  }
}
if (currentViewport.equals(viewport) === false) {
  gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
  currentViewport.copy(viewport);
}
currentViewport.equals(viewport) === false
currentViewport.equals(viewport)
currentViewport.equals
currentViewport
equals
viewport
false
{
  gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
  currentViewport.copy(viewport);
}
gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w)
gl.viewport
gl
viewport
viewport.x
viewport
x
viewport.y
viewport
y
viewport.z
viewport
z
viewport.w
viewport
w
currentViewport.copy(viewport);
currentViewport.copy(viewport)
currentViewport.copy
currentViewport
copy
viewport
function updateUBOMapping(uniformsGroup, program) {
  let mapping = uboProgramMap.get(program);
  if (mapping === undefined) {
    mapping = new WeakMap();
    uboProgramMap.set(program, mapping);
  }
  let blockIndex = mapping.get(uniformsGroup);
  if (blockIndex === undefined) {
    blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);
    mapping.set(uniformsGroup, blockIndex);
  }
}
function updateUBOMapping(uniformsGroup, program) {
  let mapping = uboProgramMap.get(program);
  if (mapping === undefined) {
    mapping = new WeakMap();
    uboProgramMap.set(program, mapping);
  }
  let blockIndex = mapping.get(uniformsGroup);
  if (blockIndex === undefined) {
    blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);
    mapping.set(uniformsGroup, blockIndex);
  }
}
updateUBOMapping
uniformsGroup
program
{
  let mapping = uboProgramMap.get(program);
  if (mapping === undefined) {
    mapping = new WeakMap();
    uboProgramMap.set(program, mapping);
  }
  let blockIndex = mapping.get(uniformsGroup);
  if (blockIndex === undefined) {
    blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);
    mapping.set(uniformsGroup, blockIndex);
  }
}
let mapping = uboProgramMap.get(program);
mapping = uboProgramMap.get(program)
mapping
uboProgramMap.get(program)
uboProgramMap.get
uboProgramMap
get
program
if (mapping === undefined) {
  mapping = new WeakMap();
  uboProgramMap.set(program, mapping);
}
mapping === undefined
mapping
undefined
{
  mapping = new WeakMap();
  uboProgramMap.set(program, mapping);
}
mapping = new WeakMap();
mapping = new WeakMap()
mapping
new WeakMap()
WeakMap
uboProgramMap.set(program, mapping);
uboProgramMap.set(program, mapping)
uboProgramMap.set
uboProgramMap
set
program
mapping
let blockIndex = mapping.get(uniformsGroup);
blockIndex = mapping.get(uniformsGroup)
blockIndex
mapping.get(uniformsGroup)
mapping.get
mapping
get
uniformsGroup
if (blockIndex === undefined) {
  blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);
  mapping.set(uniformsGroup, blockIndex);
}
blockIndex === undefined
blockIndex
undefined
{
  blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);
  mapping.set(uniformsGroup, blockIndex);
}
blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);
blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name)
blockIndex
gl.getUniformBlockIndex(program, uniformsGroup.name)
gl.getUniformBlockIndex
gl
getUniformBlockIndex
program
uniformsGroup.name
uniformsGroup
name
mapping.set(uniformsGroup, blockIndex);
mapping.set(uniformsGroup, blockIndex)
mapping.set
mapping
set
uniformsGroup
blockIndex
function uniformBlockBinding(uniformsGroup, program) {
  const mapping = uboProgramMap.get(program);
  const blockIndex = mapping.get(uniformsGroup);
  if (uboBindings.get(program) !== blockIndex) {
    // bind shader specific block index to global block point
    gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);
    uboBindings.set(program, blockIndex);
  }
}

//
function uniformBlockBinding(uniformsGroup, program) {
  const mapping = uboProgramMap.get(program);
  const blockIndex = mapping.get(uniformsGroup);
  if (uboBindings.get(program) !== blockIndex) {
    // bind shader specific block index to global block point
    gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);
    uboBindings.set(program, blockIndex);
  }
}

//
uniformBlockBinding
uniformsGroup
program
{
  const mapping = uboProgramMap.get(program);
  const blockIndex = mapping.get(uniformsGroup);
  if (uboBindings.get(program) !== blockIndex) {
    // bind shader specific block index to global block point
    gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);
    uboBindings.set(program, blockIndex);
  }
}
const mapping = uboProgramMap.get(program);
mapping = uboProgramMap.get(program)
mapping
uboProgramMap.get(program)
uboProgramMap.get
uboProgramMap
get
program
const blockIndex = mapping.get(uniformsGroup);
blockIndex = mapping.get(uniformsGroup)
blockIndex
mapping.get(uniformsGroup)
mapping.get
mapping
get
uniformsGroup
if (uboBindings.get(program) !== blockIndex) {
  // bind shader specific block index to global block point
  gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);
  uboBindings.set(program, blockIndex);
}
uboBindings.get(program) !== blockIndex
uboBindings.get(program)
uboBindings.get
uboBindings
get
program
blockIndex
{
  // bind shader specific block index to global block point
  gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);
  uboBindings.set(program, blockIndex);
}
// bind shader specific block index to global block point
gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);
gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex)
gl.uniformBlockBinding
gl
uniformBlockBinding
program
blockIndex
uniformsGroup.__bindingPointIndex
uniformsGroup
__bindingPointIndex
uboBindings.set(program, blockIndex);
uboBindings.set(program, blockIndex)
uboBindings.set
uboBindings
set
program
blockIndex
//

function reset() {
  // reset state

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

  // reset internals

  enabledCapabilities = {};
  currentTextureSlot = null;
  currentBoundTextures = {};
  currentBoundFramebuffers = {};
  currentDrawbuffers = new WeakMap();
  defaultDrawbuffers = [];
  currentProgram = null;
  currentBlendingEnabled = false;
  currentBlending = null;
  currentBlendEquation = null;
  currentBlendSrc = null;
  currentBlendDst = null;
  currentBlendEquationAlpha = null;
  currentBlendSrcAlpha = null;
  currentBlendDstAlpha = null;
  currentBlendColor = new Color(0, 0, 0);
  currentBlendAlpha = 0;
  currentPremultipledAlpha = false;
  currentFlipSided = null;
  currentCullFace = null;
  currentLineWidth = null;
  currentPolygonOffsetFactor = null;
  currentPolygonOffsetUnits = null;
  currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
  currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
  colorBuffer.reset();
  depthBuffer.reset();
  stencilBuffer.reset();
}
//

function reset() {
  // reset state

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

  // reset internals

  enabledCapabilities = {};
  currentTextureSlot = null;
  currentBoundTextures = {};
  currentBoundFramebuffers = {};
  currentDrawbuffers = new WeakMap();
  defaultDrawbuffers = [];
  currentProgram = null;
  currentBlendingEnabled = false;
  currentBlending = null;
  currentBlendEquation = null;
  currentBlendSrc = null;
  currentBlendDst = null;
  currentBlendEquationAlpha = null;
  currentBlendSrcAlpha = null;
  currentBlendDstAlpha = null;
  currentBlendColor = new Color(0, 0, 0);
  currentBlendAlpha = 0;
  currentPremultipledAlpha = false;
  currentFlipSided = null;
  currentCullFace = null;
  currentLineWidth = null;
  currentPolygonOffsetFactor = null;
  currentPolygonOffsetUnits = null;
  currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
  currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
  colorBuffer.reset();
  depthBuffer.reset();
  stencilBuffer.reset();
}
reset
{
  // reset state

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

  // reset internals

  enabledCapabilities = {};
  currentTextureSlot = null;
  currentBoundTextures = {};
  currentBoundFramebuffers = {};
  currentDrawbuffers = new WeakMap();
  defaultDrawbuffers = [];
  currentProgram = null;
  currentBlendingEnabled = false;
  currentBlending = null;
  currentBlendEquation = null;
  currentBlendSrc = null;
  currentBlendDst = null;
  currentBlendEquationAlpha = null;
  currentBlendSrcAlpha = null;
  currentBlendDstAlpha = null;
  currentBlendColor = new Color(0, 0, 0);
  currentBlendAlpha = 0;
  currentPremultipledAlpha = false;
  currentFlipSided = null;
  currentCullFace = null;
  currentLineWidth = null;
  currentPolygonOffsetFactor = null;
  currentPolygonOffsetUnits = null;
  currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
  currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
  colorBuffer.reset();
  depthBuffer.reset();
  stencilBuffer.reset();
}
// reset state

gl.disable(gl.BLEND);
gl.disable(gl.BLEND)
gl.disable
gl
disable
gl.BLEND
gl
BLEND
gl.disable(gl.CULL_FACE);
gl.disable(gl.CULL_FACE)
gl.disable
gl
disable
gl.CULL_FACE
gl
CULL_FACE
gl.disable(gl.DEPTH_TEST);
gl.disable(gl.DEPTH_TEST)
gl.disable
gl
disable
gl.DEPTH_TEST
gl
DEPTH_TEST
gl.disable(gl.POLYGON_OFFSET_FILL);
gl.disable(gl.POLYGON_OFFSET_FILL)
gl.disable
gl
disable
gl.POLYGON_OFFSET_FILL
gl
POLYGON_OFFSET_FILL
gl.disable(gl.SCISSOR_TEST);
gl.disable(gl.SCISSOR_TEST)
gl.disable
gl
disable
gl.SCISSOR_TEST
gl
SCISSOR_TEST
gl.disable(gl.STENCIL_TEST);
gl.disable(gl.STENCIL_TEST)
gl.disable
gl
disable
gl.STENCIL_TEST
gl
STENCIL_TEST
gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE)
gl.disable
gl
disable
gl.SAMPLE_ALPHA_TO_COVERAGE
gl
SAMPLE_ALPHA_TO_COVERAGE
gl.blendEquation(gl.FUNC_ADD);
gl.blendEquation(gl.FUNC_ADD)
gl.blendEquation
gl
blendEquation
gl.FUNC_ADD
gl
FUNC_ADD
gl.blendFunc(gl.ONE, gl.ZERO);
gl.blendFunc(gl.ONE, gl.ZERO)
gl.blendFunc
gl
blendFunc
gl.ONE
gl
ONE
gl.ZERO
gl
ZERO
gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO)
gl.blendFuncSeparate
gl
blendFuncSeparate
gl.ONE
gl
ONE
gl.ZERO
gl
ZERO
gl.ONE
gl
ONE
gl.ZERO
gl
ZERO
gl.blendColor(0, 0, 0, 0);
gl.blendColor(0, 0, 0, 0)
gl.blendColor
gl
blendColor
0
0
0
0
gl.colorMask(true, true, true, true);
gl.colorMask(true, true, true, true)
gl.colorMask
gl
colorMask
true
true
true
true
gl.clearColor(0, 0, 0, 0);
gl.clearColor(0, 0, 0, 0)
gl.clearColor
gl
clearColor
0
0
0
0
gl.depthMask(true);
gl.depthMask(true)
gl.depthMask
gl
depthMask
true
gl.depthFunc(gl.LESS);
gl.depthFunc(gl.LESS)
gl.depthFunc
gl
depthFunc
gl.LESS
gl
LESS
gl.clearDepth(1);
gl.clearDepth(1)
gl.clearDepth
gl
clearDepth
1
gl.stencilMask(0xffffffff);
gl.stencilMask(0xffffffff)
gl.stencilMask
gl
stencilMask
0xffffffff
gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff)
gl.stencilFunc
gl
stencilFunc
gl.ALWAYS
gl
ALWAYS
0
0xffffffff
gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP)
gl.stencilOp
gl
stencilOp
gl.KEEP
gl
KEEP
gl.KEEP
gl
KEEP
gl.KEEP
gl
KEEP
gl.clearStencil(0);
gl.clearStencil(0)
gl.clearStencil
gl
clearStencil
0
gl.cullFace(gl.BACK);
gl.cullFace(gl.BACK)
gl.cullFace
gl
cullFace
gl.BACK
gl
BACK
gl.frontFace(gl.CCW);
gl.frontFace(gl.CCW)
gl.frontFace
gl
frontFace
gl.CCW
gl
CCW
gl.polygonOffset(0, 0);
gl.polygonOffset(0, 0)
gl.polygonOffset
gl
polygonOffset
0
0
gl.activeTexture(gl.TEXTURE0);
gl.activeTexture(gl.TEXTURE0)
gl.activeTexture
gl
activeTexture
gl.TEXTURE0
gl
TEXTURE0
gl.bindFramebuffer(gl.FRAMEBUFFER, null);
gl.bindFramebuffer(gl.FRAMEBUFFER, null)
gl.bindFramebuffer
gl
bindFramebuffer
gl.FRAMEBUFFER
gl
FRAMEBUFFER
null
gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null)
gl.bindFramebuffer
gl
bindFramebuffer
gl.DRAW_FRAMEBUFFER
gl
DRAW_FRAMEBUFFER
null
gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null)
gl.bindFramebuffer
gl
bindFramebuffer
gl.READ_FRAMEBUFFER
gl
READ_FRAMEBUFFER
null
gl.useProgram(null);
gl.useProgram(null)
gl.useProgram
gl
useProgram
null
gl.lineWidth(1);
gl.lineWidth(1)
gl.lineWidth
gl
lineWidth
1
gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
gl.scissor(0, 0, gl.canvas.width, gl.canvas.height)
gl.scissor
gl
scissor
0
0
gl.canvas.width
gl.canvas
gl
canvas
width
gl.canvas.height
gl.canvas
gl
canvas
height
gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

// reset internals
gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)
gl.viewport
gl
viewport
0
0
gl.canvas.width
gl.canvas
gl
canvas
width
gl.canvas.height
gl.canvas
gl
canvas
height
// reset internals

enabledCapabilities = {};
enabledCapabilities = {}
enabledCapabilities
{}
currentTextureSlot = null;
currentTextureSlot = null
currentTextureSlot
null
currentBoundTextures = {};
currentBoundTextures = {}
currentBoundTextures
{}
currentBoundFramebuffers = {};
currentBoundFramebuffers = {}
currentBoundFramebuffers
{}
currentDrawbuffers = new WeakMap();
currentDrawbuffers = new WeakMap()
currentDrawbuffers
new WeakMap()
WeakMap
defaultDrawbuffers = [];
defaultDrawbuffers = []
defaultDrawbuffers
[]
currentProgram = null;
currentProgram = null
currentProgram
null
currentBlendingEnabled = false;
currentBlendingEnabled = false
currentBlendingEnabled
false
currentBlending = null;
currentBlending = null
currentBlending
null
currentBlendEquation = null;
currentBlendEquation = null
currentBlendEquation
null
currentBlendSrc = null;
currentBlendSrc = null
currentBlendSrc
null
currentBlendDst = null;
currentBlendDst = null
currentBlendDst
null
currentBlendEquationAlpha = null;
currentBlendEquationAlpha = null
currentBlendEquationAlpha
null
currentBlendSrcAlpha = null;
currentBlendSrcAlpha = null
currentBlendSrcAlpha
null
currentBlendDstAlpha = null;
currentBlendDstAlpha = null
currentBlendDstAlpha
null
currentBlendColor = new Color(0, 0, 0);
currentBlendColor = new Color(0, 0, 0)
currentBlendColor
new Color(0, 0, 0)
Color
0
0
0
currentBlendAlpha = 0;
currentBlendAlpha = 0
currentBlendAlpha
0
currentPremultipledAlpha = false;
currentPremultipledAlpha = false
currentPremultipledAlpha
false
currentFlipSided = null;
currentFlipSided = null
currentFlipSided
null
currentCullFace = null;
currentCullFace = null
currentCullFace
null
currentLineWidth = null;
currentLineWidth = null
currentLineWidth
null
currentPolygonOffsetFactor = null;
currentPolygonOffsetFactor = null
currentPolygonOffsetFactor
null
currentPolygonOffsetUnits = null;
currentPolygonOffsetUnits = null
currentPolygonOffsetUnits
null
currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height)
currentScissor.set
currentScissor
set
0
0
gl.canvas.width
gl.canvas
gl
canvas
width
gl.canvas.height
gl.canvas
gl
canvas
height
currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height)
currentViewport.set
currentViewport
set
0
0
gl.canvas.width
gl.canvas
gl
canvas
width
gl.canvas.height
gl.canvas
gl
canvas
height
colorBuffer.reset();
colorBuffer.reset()
colorBuffer.reset
colorBuffer
reset
depthBuffer.reset();
depthBuffer.reset()
depthBuffer.reset
depthBuffer
reset
stencilBuffer.reset();
stencilBuffer.reset()
stencilBuffer.reset
stencilBuffer
reset
return {
  buffers: {
    color: colorBuffer,
    depth: depthBuffer,
    stencil: stencilBuffer
  },
  enable: enable,
  disable: disable,
  bindFramebuffer: bindFramebuffer,
  drawBuffers: drawBuffers,
  useProgram: useProgram,
  setBlending: setBlending,
  setMaterial: setMaterial,
  setFlipSided: setFlipSided,
  setCullFace: setCullFace,
  setLineWidth: setLineWidth,
  setPolygonOffset: setPolygonOffset,
  setScissorTest: setScissorTest,
  activeTexture: activeTexture,
  bindTexture: bindTexture,
  unbindTexture: unbindTexture,
  compressedTexImage2D: compressedTexImage2D,
  compressedTexImage3D: compressedTexImage3D,
  texImage2D: texImage2D,
  texImage3D: texImage3D,
  updateUBOMapping: updateUBOMapping,
  uniformBlockBinding: uniformBlockBinding,
  texStorage2D: texStorage2D,
  texStorage3D: texStorage3D,
  texSubImage2D: texSubImage2D,
  texSubImage3D: texSubImage3D,
  compressedTexSubImage2D: compressedTexSubImage2D,
  compressedTexSubImage3D: compressedTexSubImage3D,
  scissor: scissor,
  viewport: viewport,
  reset: reset
};
{
  buffers: {
    color: colorBuffer,
    depth: depthBuffer,
    stencil: stencilBuffer
  },
  enable: enable,
  disable: disable,
  bindFramebuffer: bindFramebuffer,
  drawBuffers: drawBuffers,
  useProgram: useProgram,
  setBlending: setBlending,
  setMaterial: setMaterial,
  setFlipSided: setFlipSided,
  setCullFace: setCullFace,
  setLineWidth: setLineWidth,
  setPolygonOffset: setPolygonOffset,
  setScissorTest: setScissorTest,
  activeTexture: activeTexture,
  bindTexture: bindTexture,
  unbindTexture: unbindTexture,
  compressedTexImage2D: compressedTexImage2D,
  compressedTexImage3D: compressedTexImage3D,
  texImage2D: texImage2D,
  texImage3D: texImage3D,
  updateUBOMapping: updateUBOMapping,
  uniformBlockBinding: uniformBlockBinding,
  texStorage2D: texStorage2D,
  texStorage3D: texStorage3D,
  texSubImage2D: texSubImage2D,
  texSubImage3D: texSubImage3D,
  compressedTexSubImage2D: compressedTexSubImage2D,
  compressedTexSubImage3D: compressedTexSubImage3D,
  scissor: scissor,
  viewport: viewport,
  reset: reset
}
buffers: {
  color: colorBuffer,
  depth: depthBuffer,
  stencil: stencilBuffer
}
buffers
{
  color: colorBuffer,
  depth: depthBuffer,
  stencil: stencilBuffer
}
color: colorBuffer
color
colorBuffer
depth: depthBuffer
depth
depthBuffer
stencil: stencilBuffer
stencil
stencilBuffer
enable: enable
enable
enable
disable: disable
disable
disable
bindFramebuffer: bindFramebuffer
bindFramebuffer
bindFramebuffer
drawBuffers: drawBuffers
drawBuffers
drawBuffers
useProgram: useProgram
useProgram
useProgram
setBlending: setBlending
setBlending
setBlending
setMaterial: setMaterial
setMaterial
setMaterial
setFlipSided: setFlipSided
setFlipSided
setFlipSided
setCullFace: setCullFace
setCullFace
setCullFace
setLineWidth: setLineWidth
setLineWidth
setLineWidth
setPolygonOffset: setPolygonOffset
setPolygonOffset
setPolygonOffset
setScissorTest: setScissorTest
setScissorTest
setScissorTest
activeTexture: activeTexture
activeTexture
activeTexture
bindTexture: bindTexture
bindTexture
bindTexture
unbindTexture: unbindTexture
unbindTexture
unbindTexture
compressedTexImage2D: compressedTexImage2D
compressedTexImage2D
compressedTexImage2D
compressedTexImage3D: compressedTexImage3D
compressedTexImage3D
compressedTexImage3D
texImage2D: texImage2D
texImage2D
texImage2D
texImage3D: texImage3D
texImage3D
texImage3D
updateUBOMapping: updateUBOMapping
updateUBOMapping
updateUBOMapping
uniformBlockBinding: uniformBlockBinding
uniformBlockBinding
uniformBlockBinding
texStorage2D: texStorage2D
texStorage2D
texStorage2D
texStorage3D: texStorage3D
texStorage3D
texStorage3D
texSubImage2D: texSubImage2D
texSubImage2D
texSubImage2D
texSubImage3D: texSubImage3D
texSubImage3D
texSubImage3D
compressedTexSubImage2D: compressedTexSubImage2D
compressedTexSubImage2D
compressedTexSubImage2D
compressedTexSubImage3D: compressedTexSubImage3D
compressedTexSubImage3D
compressedTexSubImage3D
scissor: scissor
scissor
scissor
viewport: viewport
viewport
viewport
reset: reset
reset
reset
export { WebGLState };
WebGLState
WebGLState
WebGLState
WebGLState
gl
{
  function ColorBuffer() {
    let locked = false;
    const color = new Vector4();
    let currentColorMask = null;
    const currentColorClear = new Vector4(0, 0, 0, 0);
    return {
      setMask: function (colorMask) {
        if (currentColorMask !== colorMask && !locked) {
          gl.colorMask(colorMask, colorMask, colorMask, colorMask);
          currentColorMask = colorMask;
        }
      },
      setLocked: function (lock) {
        locked = lock;
      },
      setClear: function (r, g, b, a, premultipliedAlpha) {
        if (premultipliedAlpha === true) {
          r *= a;
          g *= a;
          b *= a;
        }
        color.set(r, g, b, a);
        if (currentColorClear.equals(color) === false) {
          gl.clearColor(r, g, b, a);
          currentColorClear.copy(color);
        }
      },
      reset: function () {
        locked = false;
        currentColorMask = null;
        currentColorClear.set(-1, 0, 0, 0); // set to invalid state
      }
    };
  }
  function DepthBuffer() {
    let locked = false;
    let currentDepthMask = null;
    let currentDepthFunc = null;
    let currentDepthClear = null;
    return {
      setTest: function (depthTest) {
        if (depthTest) {
          enable(gl.DEPTH_TEST);
        } else {
          disable(gl.DEPTH_TEST);
        }
      },
      setMask: function (depthMask) {
        if (currentDepthMask !== depthMask && !locked) {
          gl.depthMask(depthMask);
          currentDepthMask = depthMask;
        }
      },
      setFunc: function (depthFunc) {
        if (currentDepthFunc !== depthFunc) {
          switch (depthFunc) {
            case NeverDepth:
              gl.depthFunc(gl.NEVER);
              break;
            case AlwaysDepth:
              gl.depthFunc(gl.ALWAYS);
              break;
            case LessDepth:
              gl.depthFunc(gl.LESS);
              break;
            case LessEqualDepth:
              gl.depthFunc(gl.LEQUAL);
              break;
            case EqualDepth:
              gl.depthFunc(gl.EQUAL);
              break;
            case GreaterEqualDepth:
              gl.depthFunc(gl.GEQUAL);
              break;
            case GreaterDepth:
              gl.depthFunc(gl.GREATER);
              break;
            case NotEqualDepth:
              gl.depthFunc(gl.NOTEQUAL);
              break;
            default:
              gl.depthFunc(gl.LEQUAL);
          }
          currentDepthFunc = depthFunc;
        }
      },
      setLocked: function (lock) {
        locked = lock;
      },
      setClear: function (depth) {
        if (currentDepthClear !== depth) {
          gl.clearDepth(depth);
          currentDepthClear = depth;
        }
      },
      reset: function () {
        locked = false;
        currentDepthMask = null;
        currentDepthFunc = null;
        currentDepthClear = null;
      }
    };
  }
  function StencilBuffer() {
    let locked = false;
    let currentStencilMask = null;
    let currentStencilFunc = null;
    let currentStencilRef = null;
    let currentStencilFuncMask = null;
    let currentStencilFail = null;
    let currentStencilZFail = null;
    let currentStencilZPass = null;
    let currentStencilClear = null;
    return {
      setTest: function (stencilTest) {
        if (!locked) {
          if (stencilTest) {
            enable(gl.STENCIL_TEST);
          } else {
            disable(gl.STENCIL_TEST);
          }
        }
      },
      setMask: function (stencilMask) {
        if (currentStencilMask !== stencilMask && !locked) {
          gl.stencilMask(stencilMask);
          currentStencilMask = stencilMask;
        }
      },
      setFunc: function (stencilFunc, stencilRef, stencilMask) {
        if (currentStencilFunc !== stencilFunc || currentStencilRef !== stencilRef || currentStencilFuncMask !== stencilMask) {
          gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
          currentStencilFunc = stencilFunc;
          currentStencilRef = stencilRef;
          currentStencilFuncMask = stencilMask;
        }
      },
      setOp: function (stencilFail, stencilZFail, stencilZPass) {
        if (currentStencilFail !== stencilFail || currentStencilZFail !== stencilZFail || currentStencilZPass !== stencilZPass) {
          gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
          currentStencilFail = stencilFail;
          currentStencilZFail = stencilZFail;
          currentStencilZPass = stencilZPass;
        }
      },
      setLocked: function (lock) {
        locked = lock;
      },
      setClear: function (stencil) {
        if (currentStencilClear !== stencil) {
          gl.clearStencil(stencil);
          currentStencilClear = stencil;
        }
      },
      reset: function () {
        locked = false;
        currentStencilMask = null;
        currentStencilFunc = null;
        currentStencilRef = null;
        currentStencilFuncMask = null;
        currentStencilFail = null;
        currentStencilZFail = null;
        currentStencilZPass = null;
        currentStencilClear = null;
      }
    };
  }

  //

  const colorBuffer = new ColorBuffer();
  const depthBuffer = new DepthBuffer();
  const stencilBuffer = new StencilBuffer();
  const uboBindings = new WeakMap();
  const uboProgramMap = new WeakMap();
  let enabledCapabilities = {};
  let currentBoundFramebuffers = {};
  let currentDrawbuffers = new WeakMap();
  let defaultDrawbuffers = [];
  let currentProgram = null;
  let currentBlendingEnabled = false;
  let currentBlending = null;
  let currentBlendEquation = null;
  let currentBlendSrc = null;
  let currentBlendDst = null;
  let currentBlendEquationAlpha = null;
  let currentBlendSrcAlpha = null;
  let currentBlendDstAlpha = null;
  let currentBlendColor = new Color(0, 0, 0);
  let currentBlendAlpha = 0;
  let currentPremultipledAlpha = false;
  let currentFlipSided = null;
  let currentCullFace = null;
  let currentLineWidth = null;
  let currentPolygonOffsetFactor = null;
  let currentPolygonOffsetUnits = null;
  const maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);
  let lineWidthAvailable = false;
  let version = 0;
  const glVersion = gl.getParameter(gl.VERSION);
  if (glVersion.indexOf('WebGL') !== -1) {
    version = parseFloat(/^WebGL (\d)/.exec(glVersion)[1]);
    lineWidthAvailable = version >= 1.0;
  } else if (glVersion.indexOf('OpenGL ES') !== -1) {
    version = parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1]);
    lineWidthAvailable = version >= 2.0;
  }
  let currentTextureSlot = null;
  let currentBoundTextures = {};
  const scissorParam = gl.getParameter(gl.SCISSOR_BOX);
  const viewportParam = gl.getParameter(gl.VIEWPORT);
  const currentScissor = new Vector4().fromArray(scissorParam);
  const currentViewport = new Vector4().fromArray(viewportParam);
  function createTexture(type, target, count, dimensions) {
    const data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
    const texture = gl.createTexture();
    gl.bindTexture(type, texture);
    gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    for (let i = 0; i < count; i++) {
      if (type === gl.TEXTURE_3D || type === gl.TEXTURE_2D_ARRAY) {
        gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      } else {
        gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
      }
    }
    return texture;
  }
  const emptyTextures = {};
  emptyTextures[gl.TEXTURE_2D] = createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
  emptyTextures[gl.TEXTURE_CUBE_MAP] = createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
  emptyTextures[gl.TEXTURE_2D_ARRAY] = createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
  emptyTextures[gl.TEXTURE_3D] = createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

  // init

  colorBuffer.setClear(0, 0, 0, 1);
  depthBuffer.setClear(1);
  stencilBuffer.setClear(0);
  enable(gl.DEPTH_TEST);
  depthBuffer.setFunc(LessEqualDepth);
  setFlipSided(false);
  setCullFace(CullFaceBack);
  enable(gl.CULL_FACE);
  setBlending(NoBlending);

  //

  function enable(id) {
    if (enabledCapabilities[id] !== true) {
      gl.enable(id);
      enabledCapabilities[id] = true;
    }
  }
  function disable(id) {
    if (enabledCapabilities[id] !== false) {
      gl.disable(id);
      enabledCapabilities[id] = false;
    }
  }
  function bindFramebuffer(target, framebuffer) {
    if (currentBoundFramebuffers[target] !== framebuffer) {
      gl.bindFramebuffer(target, framebuffer);
      currentBoundFramebuffers[target] = framebuffer;

      // gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

      if (target === gl.DRAW_FRAMEBUFFER) {
        currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
      }
      if (target === gl.FRAMEBUFFER) {
        currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
      }
      return true;
    }
    return false;
  }
  function drawBuffers(renderTarget, framebuffer) {
    let drawBuffers = defaultDrawbuffers;
    let needsUpdate = false;
    if (renderTarget) {
      drawBuffers = currentDrawbuffers.get(framebuffer);
      if (drawBuffers === undefined) {
        drawBuffers = [];
        currentDrawbuffers.set(framebuffer, drawBuffers);
      }
      const textures = renderTarget.textures;
      if (drawBuffers.length !== textures.length || drawBuffers[0] !== gl.COLOR_ATTACHMENT0) {
        for (let i = 0, il = textures.length; i < il; i++) {
          drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
        }
        drawBuffers.length = textures.length;
        needsUpdate = true;
      }
    } else {
      if (drawBuffers[0] !== gl.BACK) {
        drawBuffers[0] = gl.BACK;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      gl.drawBuffers(drawBuffers);
    }
  }
  function useProgram(program) {
    if (currentProgram !== program) {
      gl.useProgram(program);
      currentProgram = program;
      return true;
    }
    return false;
  }
  const equationToGL = {
    [AddEquation]: gl.FUNC_ADD,
    [SubtractEquation]: gl.FUNC_SUBTRACT,
    [ReverseSubtractEquation]: gl.FUNC_REVERSE_SUBTRACT
  };
  equationToGL[MinEquation] = gl.MIN;
  equationToGL[MaxEquation] = gl.MAX;
  const factorToGL = {
    [ZeroFactor]: gl.ZERO,
    [OneFactor]: gl.ONE,
    [SrcColorFactor]: gl.SRC_COLOR,
    [SrcAlphaFactor]: gl.SRC_ALPHA,
    [SrcAlphaSaturateFactor]: gl.SRC_ALPHA_SATURATE,
    [DstColorFactor]: gl.DST_COLOR,
    [DstAlphaFactor]: gl.DST_ALPHA,
    [OneMinusSrcColorFactor]: gl.ONE_MINUS_SRC_COLOR,
    [OneMinusSrcAlphaFactor]: gl.ONE_MINUS_SRC_ALPHA,
    [OneMinusDstColorFactor]: gl.ONE_MINUS_DST_COLOR,
    [OneMinusDstAlphaFactor]: gl.ONE_MINUS_DST_ALPHA,
    [ConstantColorFactor]: gl.CONSTANT_COLOR,
    [OneMinusConstantColorFactor]: gl.ONE_MINUS_CONSTANT_COLOR,
    [ConstantAlphaFactor]: gl.CONSTANT_ALPHA,
    [OneMinusConstantAlphaFactor]: gl.ONE_MINUS_CONSTANT_ALPHA
  };
  function setBlending(blending, blendEquation, blendSrc, blendDst, blendEquationAlpha, blendSrcAlpha, blendDstAlpha, blendColor, blendAlpha, premultipliedAlpha) {
    if (blending === NoBlending) {
      if (currentBlendingEnabled === true) {
        disable(gl.BLEND);
        currentBlendingEnabled = false;
      }
      return;
    }
    if (currentBlendingEnabled === false) {
      enable(gl.BLEND);
      currentBlendingEnabled = true;
    }
    if (blending !== CustomBlending) {
      if (blending !== currentBlending || premultipliedAlpha !== currentPremultipledAlpha) {
        if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {
          gl.blendEquation(gl.FUNC_ADD);
          currentBlendEquation = AddEquation;
          currentBlendEquationAlpha = AddEquation;
        }
        if (premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
              break;
            case AdditiveBlending:
              gl.blendFunc(gl.ONE, gl.ONE);
              break;
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
              break;
            case MultiplyBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
              break;
            default:
              console.error('THREE.WebGLState: Invalid blending: ', blending);
              break;
          }
        } else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
              break;
            case AdditiveBlending:
              gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
              break;
            case SubtractiveBlending:
              gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
              break;
            case MultiplyBlending:
              gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
              break;
            default:
              console.error('THREE.WebGLState: Invalid blending: ', blending);
              break;
          }
        }
        currentBlendSrc = null;
        currentBlendDst = null;
        currentBlendSrcAlpha = null;
        currentBlendDstAlpha = null;
        currentBlendColor.set(0, 0, 0);
        currentBlendAlpha = 0;
        currentBlending = blending;
        currentPremultipledAlpha = premultipliedAlpha;
      }
      return;
    }

    // custom blending

    blendEquationAlpha = blendEquationAlpha || blendEquation;
    blendSrcAlpha = blendSrcAlpha || blendSrc;
    blendDstAlpha = blendDstAlpha || blendDst;
    if (blendEquation !== currentBlendEquation || blendEquationAlpha !== currentBlendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
      currentBlendEquation = blendEquation;
      currentBlendEquationAlpha = blendEquationAlpha;
    }
    if (blendSrc !== currentBlendSrc || blendDst !== currentBlendDst || blendSrcAlpha !== currentBlendSrcAlpha || blendDstAlpha !== currentBlendDstAlpha) {
      gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
      currentBlendSrc = blendSrc;
      currentBlendDst = blendDst;
      currentBlendSrcAlpha = blendSrcAlpha;
      currentBlendDstAlpha = blendDstAlpha;
    }
    if (blendColor.equals(currentBlendColor) === false || blendAlpha !== currentBlendAlpha) {
      gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);
      currentBlendColor.copy(blendColor);
      currentBlendAlpha = blendAlpha;
    }
    currentBlending = blending;
    currentPremultipledAlpha = false;
  }
  function setMaterial(material, frontFaceCW) {
    material.side === DoubleSide ? disable(gl.CULL_FACE) : enable(gl.CULL_FACE);
    let flipSided = material.side === BackSide;
    if (frontFaceCW) flipSided = !flipSided;
    setFlipSided(flipSided);
    material.blending === NormalBlending && material.transparent === false ? setBlending(NoBlending) : setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);
    depthBuffer.setFunc(material.depthFunc);
    depthBuffer.setTest(material.depthTest);
    depthBuffer.setMask(material.depthWrite);
    colorBuffer.setMask(material.colorWrite);
    const stencilWrite = material.stencilWrite;
    stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      stencilBuffer.setMask(material.stencilWriteMask);
      stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }
    setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
    material.alphaToCoverage === true ? enable(gl.SAMPLE_ALPHA_TO_COVERAGE) : disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
  }

  //

  function setFlipSided(flipSided) {
    if (currentFlipSided !== flipSided) {
      if (flipSided) {
        gl.frontFace(gl.CW);
      } else {
        gl.frontFace(gl.CCW);
      }
      currentFlipSided = flipSided;
    }
  }
  function setCullFace(cullFace) {
    if (cullFace !== CullFaceNone) {
      enable(gl.CULL_FACE);
      if (cullFace !== currentCullFace) {
        if (cullFace === CullFaceBack) {
          gl.cullFace(gl.BACK);
        } else if (cullFace === CullFaceFront) {
          gl.cullFace(gl.FRONT);
        } else {
          gl.cullFace(gl.FRONT_AND_BACK);
        }
      }
    } else {
      disable(gl.CULL_FACE);
    }
    currentCullFace = cullFace;
  }
  function setLineWidth(width) {
    if (width !== currentLineWidth) {
      if (lineWidthAvailable) gl.lineWidth(width);
      currentLineWidth = width;
    }
  }
  function setPolygonOffset(polygonOffset, factor, units) {
    if (polygonOffset) {
      enable(gl.POLYGON_OFFSET_FILL);
      if (currentPolygonOffsetFactor !== factor || currentPolygonOffsetUnits !== units) {
        gl.polygonOffset(factor, units);
        currentPolygonOffsetFactor = factor;
        currentPolygonOffsetUnits = units;
      }
    } else {
      disable(gl.POLYGON_OFFSET_FILL);
    }
  }
  function setScissorTest(scissorTest) {
    if (scissorTest) {
      enable(gl.SCISSOR_TEST);
    } else {
      disable(gl.SCISSOR_TEST);
    }
  }

  // texture

  function activeTexture(webglSlot) {
    if (webglSlot === undefined) webglSlot = gl.TEXTURE0 + maxTextures - 1;
    if (currentTextureSlot !== webglSlot) {
      gl.activeTexture(webglSlot);
      currentTextureSlot = webglSlot;
    }
  }
  function bindTexture(webglType, webglTexture, webglSlot) {
    if (webglSlot === undefined) {
      if (currentTextureSlot === null) {
        webglSlot = gl.TEXTURE0 + maxTextures - 1;
      } else {
        webglSlot = currentTextureSlot;
      }
    }
    let boundTexture = currentBoundTextures[webglSlot];
    if (boundTexture === undefined) {
      boundTexture = {
        type: undefined,
        texture: undefined
      };
      currentBoundTextures[webglSlot] = boundTexture;
    }
    if (boundTexture.type !== webglType || boundTexture.texture !== webglTexture) {
      if (currentTextureSlot !== webglSlot) {
        gl.activeTexture(webglSlot);
        currentTextureSlot = webglSlot;
      }
      gl.bindTexture(webglType, webglTexture || emptyTextures[webglType]);
      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }
  function unbindTexture() {
    const boundTexture = currentBoundTextures[currentTextureSlot];
    if (boundTexture !== undefined && boundTexture.type !== undefined) {
      gl.bindTexture(boundTexture.type, null);
      boundTexture.type = undefined;
      boundTexture.texture = undefined;
    }
  }
  function compressedTexImage2D() {
    try {
      gl.compressedTexImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function compressedTexImage3D() {
    try {
      gl.compressedTexImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texSubImage2D() {
    try {
      gl.texSubImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texSubImage3D() {
    try {
      gl.texSubImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function compressedTexSubImage2D() {
    try {
      gl.compressedTexSubImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function compressedTexSubImage3D() {
    try {
      gl.compressedTexSubImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texStorage2D() {
    try {
      gl.texStorage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texStorage3D() {
    try {
      gl.texStorage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texImage2D() {
    try {
      gl.texImage2D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }
  function texImage3D() {
    try {
      gl.texImage3D.apply(gl, arguments);
    } catch (error) {
      console.error('THREE.WebGLState:', error);
    }
  }

  //

  function scissor(scissor) {
    if (currentScissor.equals(scissor) === false) {
      gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
      currentScissor.copy(scissor);
    }
  }
  function viewport(viewport) {
    if (currentViewport.equals(viewport) === false) {
      gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
      currentViewport.copy(viewport);
    }
  }
  function updateUBOMapping(uniformsGroup, program) {
    let mapping = uboProgramMap.get(program);
    if (mapping === undefined) {
      mapping = new WeakMap();
      uboProgramMap.set(program, mapping);
    }
    let blockIndex = mapping.get(uniformsGroup);
    if (blockIndex === undefined) {
      blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);
      mapping.set(uniformsGroup, blockIndex);
    }
  }
  function uniformBlockBinding(uniformsGroup, program) {
    const mapping = uboProgramMap.get(program);
    const blockIndex = mapping.get(uniformsGroup);
    if (uboBindings.get(program) !== blockIndex) {
      // bind shader specific block index to global block point
      gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);
      uboBindings.set(program, blockIndex);
    }
  }

  //

  function reset() {
    // reset state

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

    // reset internals

    enabledCapabilities = {};
    currentTextureSlot = null;
    currentBoundTextures = {};
    currentBoundFramebuffers = {};
    currentDrawbuffers = new WeakMap();
    defaultDrawbuffers = [];
    currentProgram = null;
    currentBlendingEnabled = false;
    currentBlending = null;
    currentBlendEquation = null;
    currentBlendSrc = null;
    currentBlendDst = null;
    currentBlendEquationAlpha = null;
    currentBlendSrcAlpha = null;
    currentBlendDstAlpha = null;
    currentBlendColor = new Color(0, 0, 0);
    currentBlendAlpha = 0;
    currentPremultipledAlpha = false;
    currentFlipSided = null;
    currentCullFace = null;
    currentLineWidth = null;
    currentPolygonOffsetFactor = null;
    currentPolygonOffsetUnits = null;
    currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
    currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);
    colorBuffer.reset();
    depthBuffer.reset();
    stencilBuffer.reset();
  }
  return {
    buffers: {
      color: colorBuffer,
      depth: depthBuffer,
      stencil: stencilBuffer
    },
    enable: enable,
    disable: disable,
    bindFramebuffer: bindFramebuffer,
    drawBuffers: drawBuffers,
    useProgram: useProgram,
    setBlending: setBlending,
    setMaterial: setMaterial,
    setFlipSided: setFlipSided,
    setCullFace: setCullFace,
    setLineWidth: setLineWidth,
    setPolygonOffset: setPolygonOffset,
    setScissorTest: setScissorTest,
    activeTexture: activeTexture,
    bindTexture: bindTexture,
    unbindTexture: unbindTexture,
    compressedTexImage2D: compressedTexImage2D,
    compressedTexImage3D: compressedTexImage3D,
    texImage2D: texImage2D,
    texImage3D: texImage3D,
    updateUBOMapping: updateUBOMapping,
    uniformBlockBinding: uniformBlockBinding,
    texStorage2D: texStorage2D,
    texStorage3D: texStorage3D,
    texSubImage2D: texSubImage2D,
    texSubImage3D: texSubImage3D,
    compressedTexSubImage2D: compressedTexSubImage2D,
    compressedTexSubImage3D: compressedTexSubImage3D,
    scissor: scissor,
    viewport: viewport,
    reset: reset
  };
}
function ColorBuffer() {
  let locked = false;
  const color = new Vector4();
  let currentColorMask = null;
  const currentColorClear = new Vector4(0, 0, 0, 0);
  return {
    setMask: function (colorMask) {
      if (currentColorMask !== colorMask && !locked) {
        gl.colorMask(colorMask, colorMask, colorMask, colorMask);
        currentColorMask = colorMask;
      }
    },
    setLocked: function (lock) {
      locked = lock;
    },
    setClear: function (r, g, b, a, premultipliedAlpha) {
      if (premultipliedAlpha === true) {
        r *= a;
        g *= a;
        b *= a;
      }
      color.set(r, g, b, a);
      if (currentColorClear.equals(color) === false) {
        gl.clearColor(r, g, b, a);
        currentColorClear.copy(color);
      }
    },
    reset: function () {
      locked = false;
      currentColorMask = null;
      currentColorClear.set(-1, 0, 0, 0); // set to invalid state
    }
  };
}