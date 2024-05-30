import three.renderers.WebGLRenderer;
import three.textures.Texture;
import three.utils.Utils;
import three.core.BufferGeometry;
import three.materials.Material;

class WebGLRendererFuncPart5 {
  
  public function new() {}

  // the current material requires lighting info

  // note: all lighting uniforms are always set correctly
  // they simply reference the renderer's state for their
  // values
  //
  // use the current material's .needsUpdate flags to set
  // the GL state when required

  markUniformsLightsNeedsUpdate(m_uniforms, refreshLights);

  // refresh uniforms common to several materials

  if (fog != null && material.fog == true) {
    materials.refreshFogUniforms(m_uniforms, fog);
  }

  materials.refreshMaterialUniforms(m_uniforms, material, _pixelRatio, _height, currentRenderState.state.transmissionRenderTarget[camera.id]);

  WebGLUniforms.upload(_gl, getUniformList(materialProperties), m_uniforms, textures);

  if (material.isShaderMaterial && material.uniformsNeedUpdate == true) {
    WebGLUniforms.upload(_gl, getUniformList(materialProperties), m_uniforms, textures);
    material.uniformsNeedUpdate = false;
  }

  if (material.isSpriteMaterial) {
    p_uniforms.setValue(_gl, 'center', object.center);
  }

  // common matrices
  p_uniforms.setValue(_gl, 'modelViewMatrix', object.modelViewMatrix);
  p_uniforms.setValue(_gl, 'normalMatrix', object.normalMatrix);
  p_uniforms.setValue(_gl, 'modelMatrix', object.matrixWorld);

  // UBOs
  if (material.isShaderMaterial || material.isRawShaderMaterial) {
    var groups = material.uniformsGroups;

    for (i in 0...groups.length) {
      var group = groups[i];
      uniformsGroups.update(group, program);
      uniformsGroups.bind(group, program);
    }
  }

  return program;

  // If uniforms are marked as clean, they don't need to be loaded to the GPU.
  function markUniformsLightsNeedsUpdate(uniforms, value) {
    uniforms.ambientLightColor.needsUpdate = value;
    uniforms.lightProbe.needsUpdate = value;
    uniforms.directionalLights.needsUpdate = value;
    uniforms.directionalLightShadows.needsUpdate = value;
    uniforms.pointLights.needsUpdate = value;
    uniforms.pointLightShadows.needsUpdate = value;
    uniforms.spotLights.needsUpdate = value;
    uniforms.spotLightShadows.needsUpdate = value;
    uniforms.rectAreaLights.needsUpdate = value;
    uniforms.hemisphereLights.needsUpdate = value;
  }

  function materialNeedsLights(material) {
    return material.isMeshLambertMaterial || material.isMeshToonMaterial || material.isMeshPhongMaterial || material.isMeshStandardMaterial || material.isShadowMaterial || (material.isShaderMaterial && material.lights == true);
  }

  public function getActiveCubeFace(): Int {
    return _currentActiveCubeFace;
  }

  public function getActiveMipmapLevel(): Int {
    return _currentActiveMipmapLevel;
  }

  public function getRenderTarget(): RenderTarget {
    return _currentRenderTarget;
  }

  public function setRenderTargetTextures(renderTarget: RenderTarget, colorTexture: Texture, depthTexture: Texture): Void {
    properties.get(renderTarget.texture).__webglTexture = colorTexture;
    properties.get(renderTarget.depthTexture).__webglTexture = depthTexture;
    var renderTargetProperties = properties.get(renderTarget);
    renderTargetProperties.__hasExternalTextures = true;
    renderTargetProperties.__autoAllocateDepthBuffer = depthTexture == null;

    if (!renderTargetProperties.__autoAllocateDepthBuffer) {
      // The multisample_render_to_texture extension doesn't work properly if there
      // are midframe flushes and an external depth buffer. Disable use of the extension.
      if (extensions.has('WEBGL_multisampled_render_to_texture') == true) {
        trace('THREE.WebGLRenderer: Render-to-texture extension was disabled because an external texture was provided');
        renderTargetProperties.__useRenderToTexture = false;
      }
    }
  }

  public function setRenderTargetFramebuffer(renderTarget: RenderTarget, defaultFramebuffer: Framebuffer): Void {
    var renderTargetProperties = properties.get(renderTarget);
    renderTargetProperties.__webglFramebuffer = defaultFramebuffer;
    renderTargetProperties.__useDefaultFramebuffer = defaultFramebuffer == null;
  }

  public function setRenderTarget(renderTarget: RenderTarget, activeCubeFace: Int = 0, activeMipmapLevel: Int = 0): Void {
    _currentRenderTarget = renderTarget;
    _currentActiveCubeFace = activeCubeFace;
    _currentActiveMipmapLevel = activeMipmapLevel;
    var useDefaultFramebuffer = true;
    var framebuffer: Framebuffer = null;
    var isCube = false;
    var isRenderTarget3D = false;

    if (renderTarget != null) {
      var renderTargetProperties = properties.get(renderTarget);

      if (renderTargetProperties.__useDefaultFramebuffer != null) {
        // We need to make sure to rebind the framebuffer.
        state.bindFramebuffer(_gl.FRAMEBUFFER, null);
        useDefaultFramebuffer = false;
      } else if (renderTargetProperties.__webglFramebuffer == null) {
        textures.setupRenderTarget(renderTarget);
      } else if (renderTargetProperties.__hasExternalTextures) {
        // Color and depth texture must be rebound in order for the swapchain to update.
        textures.rebindTextures(renderTarget, properties.get(renderTarget.texture).__webglTexture, properties.get(renderTarget.depthTexture).__webglTexture);
      }

      var texture = renderTarget.texture;

      if (texture.isData3DTexture || texture.isDataArrayTexture || texture.isCompressedArrayTexture) {
        isRenderTarget3D = true;
      }

      var __webglFramebuffer = properties.get(renderTarget).__webglFramebuffer;

      if (renderTarget.isWebGLCubeRenderTarget) {
        if (__webglFramebuffer[activeCubeFace] is Array) {
          framebuffer = __webglFramebuffer[activeCubeFace][activeMipmapLevel];
        } else {
          framebuffer = __webglFramebuffer[activeCubeFace];
        }
        isCube = true;
      } else if ((renderTarget.samples > 0) && textures.useMultisampledRTT(renderTarget) == false) {
        framebuffer = properties.get(renderTarget).__webglMultisampledFramebuffer;
      } else {
        if (__webglFramebuffer is Array) {
          framebuffer = __webglFramebuffer[activeMipmapLevel];
        } else {
          framebuffer = __webglFramebuffer;
        }
      }

      _currentViewport.copy(renderTarget.viewport);
      _currentScissor.copy(renderTarget.scissor);
      _currentScissorTest = renderTarget.scissorTest;
    } else {
      _currentViewport.copy(_viewport).multiplyScalar(_pixelRatio).floor();
      _currentScissor.copy(_scissor).multiplyScalar(_pixelRatio).floor();
      _currentScissorTest = _scissorTest;
    }

    var framebufferBound = state.bindFramebuffer(_gl.FRAMEBUFFER, framebuffer);

    if (framebufferBound && useDefaultFramebuffer) {
      state.drawBuffers(renderTarget, framebuffer);
    }

    state.viewport(_currentViewport);
    state.scissor(_currentScissor);
    state.setScissorTest(_currentScissorTest);

    if (isCube) {
      var textureProperties = properties.get(renderTarget.texture);
      _gl.framebufferTexture2D(_gl.FRAMEBUFFER, _gl.COLOR_ATTACHMENT0, _gl.TEXTURE_CUBE_MAP_POSITIVE_X + activeCubeFace, textureProperties.__webglTexture, activeMipmapLevel);
    } else if (isRenderTarget3D) {
      var textureProperties = properties.get(renderTarget.texture);
      var layer = activeCubeFace != null ? activeCubeFace : 0;
      _gl.framebufferTextureLayer(_gl.FRAMEBUFFER, _gl.COLOR_ATTACHMENT0, textureProperties.__webglTexture, activeMipmapLevel != null ? activeMipmapLevel : 0, layer);
    }

    _currentMaterialId = -1; // reset current material to ensure correct uniform bindings
  }

  public function readRenderTargetPixels(renderTarget: RenderTarget, x: Int, y: Int, width: Int, height: Int, buffer: ArrayBufferView, activeCubeFaceIndex: Int): Void {
    if (!(renderTarget != null && renderTarget.isWebGLRenderTarget)) {
      trace('THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.');
      return;
    }

    var framebuffer = properties.get(renderTarget).__webglFramebuffer;

    if (renderTarget.isWebGLCubeRenderTarget && activeCubeFaceIndex != null) {
      framebuffer = framebuffer[activeCubeFaceIndex];
    }

    if (framebuffer != null) {
      state.bindFramebuffer(_gl.FRAMEBUFFER, framebuffer);

      try {
        var texture = renderTarget.texture;
        var textureFormat = texture.format;
        var textureType = texture.type;

        if (!capabilities.textureFormatReadable(textureFormat)) {
          trace('THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in RGBA or implementation defined format.');
          return;
        }

        if (!capabilities.textureTypeReadable(textureType)) {
          trace('THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in UnsignedByteType or implementation defined type.');
          return;
        }

        // the following if statement ensures valid read requests (no out-of-bounds pixels, negative width or height)
        if (x >= 0 && x < renderTarget.width && y >= 0 && y < renderTarget.height && (x + width) <= renderTarget.width && (y + height) <= renderTarget.height) {
          _gl.readPixels(x, y, width, height, capabilities.convert(textureFormat), capabilities.convert(textureType), buffer);
        }
      } finally {
        var _currentFramebuffer = properties.get(_currentRenderTarget).__webglFramebuffer;
        state.bindFramebuffer(_gl.FRAMEBUFFER, _currentFramebuffer != null ? _currentFramebuffer : null);
      }
    }
  }
}