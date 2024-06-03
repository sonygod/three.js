import three.core.Object3D;
import three.core.Scene;
import three.core.Camera;
import three.geometries.Geometry;
import three.materials.Material;
import three.scenes.Fog;
import three.materials.MeshStandardMaterial;
import three.math.Matrix4;
import three.math.Matrix3;
import three.math.Vector3;
import three.constants.RendererCapabilities;
import three.constants.Side;
import three.constants.DoubleSide;
import three.constants.BackSide;
import three.constants.FrontSide;
import three.constants.NoToneMapping;
import three.constants.LinearSRGBColorSpace;
import three.constants.WebGLUniforms;

class Renderer {
  var _this:Renderer;
  var _gl:WebGLRenderingContext;
  var _emptyScene:Scene;
  var _currentCamera:Camera;
  var _currentMaterialId:Int;
  var _clippingEnabled:Bool;
  var _localClippingEnabled:Bool;
  var _currentRenderTarget:Dynamic;
  var _vector3:Vector3;
  var _toneMappingExposure:Float;
  var _outputColorSpace:Int;
  var _toneMapping:Int;
  var state:Dynamic;
  var capabilities:RendererCapabilities;
  var clipping:Dynamic;
  var morphtargets:Dynamic;
  var textures:Dynamic;
  var properties:Dynamic;
  var programCache:Dynamic;
  var currentRenderState:Dynamic;
  var cubemaps:Dynamic;
  var cubeuvmaps:Dynamic;

  public function new() {
    _this = this;
  }

  public function renderObject( object:Object3D, scene:Scene, camera:Camera, geometry:Geometry, material:Material, group:Dynamic ) {
    object.onBeforeRender(_this, scene, camera, geometry, material, group);

    object.modelViewMatrix.multiplyMatrices(camera.matrixWorldInverse, object.matrixWorld);
    object.normalMatrix.getNormalMatrix(object.modelViewMatrix);

    material.onBeforeRender(_this, scene, camera, geometry, object, group);

    if (material.transparent && material.side == DoubleSide && !material.forceSinglePass) {
      material.side = BackSide;
      material.needsUpdate = true;
      _this.renderBufferDirect(camera, scene, geometry, material, object, group);

      material.side = FrontSide;
      material.needsUpdate = true;
      _this.renderBufferDirect(camera, scene, geometry, material, object, group);

      material.side = DoubleSide;
    } else {
      _this.renderBufferDirect(camera, scene, geometry, material, object, group);
    }

    object.onAfterRender(_this, scene, camera, geometry, material, object, group);
  }

  public function getProgram( material:Material, scene:Scene, object:Object3D ) {
    if (!scene.isScene) scene = _emptyScene;

    var materialProperties = properties.get(material);

    var lights = currentRenderState.state.lights;
    var shadowsArray = currentRenderState.state.shadowsArray;

    var lightsStateVersion = lights.state.version;

    var parameters = programCache.getParameters(material, lights.state, shadowsArray, scene, object);
    var programCacheKey = programCache.getProgramCacheKey(parameters);

    var programs = materialProperties.programs;

    // always update environment and fog - changing these trigger an getProgram call, but it's possible that the program doesn't change

    materialProperties.environment = cast material.isMeshStandardMaterial ? scene.environment : null;
    materialProperties.fog = scene.fog;
    materialProperties.envMap = cast material.isMeshStandardMaterial ? cubeuvmaps.get(material.envMap || materialProperties.environment) : cubemaps.get(material.envMap || materialProperties.environment);
    materialProperties.envMapRotation = (materialProperties.environment != null && material.envMap == null) ? scene.environmentRotation : material.envMapRotation;

    if (programs == null) {
      // new material

      material.addEventListener('dispose', onMaterialDispose);

      programs = new Map();
      materialProperties.programs = programs;
    }

    var program = programs.get(programCacheKey);

    if (program != null) {
      // early out if program and light state is identical

      if (materialProperties.currentProgram == program && materialProperties.lightsStateVersion == lightsStateVersion) {
        updateCommonMaterialProperties(material, parameters);

        return program;
      }
    } else {
      parameters.uniforms = programCache.getUniforms(material);

      material.onBuild(object, parameters, _this);

      material.onBeforeCompile(parameters, _this);

      program = programCache.acquireProgram(parameters, programCacheKey);
      programs.set(programCacheKey, program);

      materialProperties.uniforms = parameters.uniforms;
    }

    var uniforms = materialProperties.uniforms;

    if ((material.isShaderMaterial || material.isRawShaderMaterial) || material.clipping) {
      uniforms.clippingPlanes = clipping.uniform;
    }

    updateCommonMaterialProperties(material, parameters);

    // store the light setup it was created for

    materialProperties.needsLights = materialNeedsLights(material);
    materialProperties.lightsStateVersion = lightsStateVersion;

    if (materialProperties.needsLights) {
      // wire up the material to this renderer's lighting state

      uniforms.ambientLightColor.value = lights.state.ambient;
      uniforms.lightProbe.value = lights.state.probe;
      uniforms.directionalLights.value = lights.state.directional;
      uniforms.directionalLightShadows.value = lights.state.directionalShadow;
      uniforms.spotLights.value = lights.state.spot;
      uniforms.spotLightShadows.value = lights.state.spotShadow;
      uniforms.rectAreaLights.value = lights.state.rectArea;
      uniforms.ltc_1.value = lights.state.rectAreaLTC1;
      uniforms.ltc_2.value = lights.state.rectAreaLTC2;
      uniforms.pointLights.value = lights.state.point;
      uniforms.pointLightShadows.value = lights.state.pointShadow;
      uniforms.hemisphereLights.value = lights.state.hemi;

      uniforms.directionalShadowMap.value = lights.state.directionalShadowMap;
      uniforms.directionalShadowMatrix.value = lights.state.directionalShadowMatrix;
      uniforms.spotShadowMap.value = lights.state.spotShadowMap;
      uniforms.spotLightMatrix.value = lights.state.spotLightMatrix;
      uniforms.spotLightMap.value = lights.state.spotLightMap;
      uniforms.pointShadowMap.value = lights.state.pointShadowMap;
      uniforms.pointShadowMatrix.value = lights.state.pointShadowMatrix;
      // TODO (abelnation): add area lights shadow info to uniforms
    }

    materialProperties.currentProgram = program;
    materialProperties.uniformsList = null;

    return program;
  }

  public function getUniformList( materialProperties:Dynamic ) {
    if (materialProperties.uniformsList == null) {
      var progUniforms = materialProperties.currentProgram.getUniforms();
      materialProperties.uniformsList = WebGLUniforms.seqWithValue(progUniforms.seq, materialProperties.uniforms);
    }

    return materialProperties.uniformsList;
  }

  public function updateCommonMaterialProperties( material:Material, parameters:Dynamic ) {
    var materialProperties = properties.get(material);

    materialProperties.outputColorSpace = parameters.outputColorSpace;
    materialProperties.batching = parameters.batching;
    materialProperties.batchingColor = parameters.batchingColor;
    materialProperties.instancing = parameters.instancing;
    materialProperties.instancingColor = parameters.instancingColor;
    materialProperties.instancingMorph = parameters.instancingMorph;
    materialProperties.skinning = parameters.skinning;
    materialProperties.morphTargets = parameters.morphTargets;
    materialProperties.morphNormals = parameters.morphNormals;
    materialProperties.morphColors = parameters.morphColors;
    materialProperties.morphTargetsCount = parameters.morphTargetsCount;
    materialProperties.numClippingPlanes = parameters.numClippingPlanes;
    materialProperties.numIntersection = parameters.numClipIntersection;
    materialProperties.vertexAlphas = parameters.vertexAlphas;
    materialProperties.vertexTangents = parameters.vertexTangents;
    materialProperties.toneMapping = parameters.toneMapping;
  }

  public function setProgram( camera:Camera, scene:Scene, geometry:Geometry, material:Material, object:Object3D ) {
    if (!scene.isScene) scene = _emptyScene;

    textures.resetTextureUnits();

    var fog = scene.fog;
    var environment = cast material.isMeshStandardMaterial ? scene.environment : null;
    var colorSpace = (_currentRenderTarget == null) ? _this.outputColorSpace : (cast _currentRenderTarget.isXRRenderTarget ? _currentRenderTarget.texture.colorSpace : LinearSRGBColorSpace);
    var envMap = cast material.isMeshStandardMaterial ? cubeuvmaps.get(material.envMap || environment) : cubemaps.get(material.envMap || environment);
    var vertexAlphas = material.vertexColors && geometry.attributes.color != null && geometry.attributes.color.itemSize == 4;
    var vertexTangents = geometry.attributes.tangent != null && (material.normalMap || material.anisotropy > 0);
    var morphTargets = geometry.morphAttributes.position != null;
    var morphNormals = geometry.morphAttributes.normal != null;
    var morphColors = geometry.morphAttributes.color != null;

    var toneMapping = NoToneMapping;

    if (material.toneMapped) {
      if (_currentRenderTarget == null || _currentRenderTarget.isXRRenderTarget) {
        toneMapping = _this.toneMapping;
      }
    }

    var morphAttribute = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
    var morphTargetsCount = (morphAttribute != null) ? morphAttribute.length : 0;

    var materialProperties = properties.get(material);
    var lights = currentRenderState.state.lights;

    if (_clippingEnabled) {
      if (_localClippingEnabled || camera != _currentCamera) {
        var useCache = camera == _currentCamera && material.id == _currentMaterialId;

        // we might want to call this function with some ClippingGroup
        // object instead of the material, once it becomes feasible
        // (#8465, #8379)
        clipping.setState(material, camera, useCache);
      }
    }

    //

    var needsProgramChange = false;

    if (material.version == materialProperties.__version) {
      if (materialProperties.needsLights && (materialProperties.lightsStateVersion != lights.state.version)) {
        needsProgramChange = true;
      } else if (materialProperties.outputColorSpace != colorSpace) {
        needsProgramChange = true;
      } else if (object.isBatchedMesh && !materialProperties.batching) {
        needsProgramChange = true;
      } else if (!object.isBatchedMesh && materialProperties.batching) {
        needsProgramChange = true;
      } else if (object.isBatchedMesh && materialProperties.batchingColor && object.colorTexture == null) {
        needsProgramChange = true;
      } else if (object.isBatchedMesh && !materialProperties.batchingColor && object.colorTexture != null) {
        needsProgramChange = true;
      } else if (object.isInstancedMesh && !materialProperties.instancing) {
        needsProgramChange = true;
      } else if (!object.isInstancedMesh && materialProperties.instancing) {
        needsProgramChange = true;
      } else if (object.isSkinnedMesh && !materialProperties.skinning) {
        needsProgramChange = true;
      } else if (!object.isSkinnedMesh && materialProperties.skinning) {
        needsProgramChange = true;
      } else if (object.isInstancedMesh && materialProperties.instancingColor && object.instanceColor == null) {
        needsProgramChange = true;
      } else if (object.isInstancedMesh && !materialProperties.instancingColor && object.instanceColor != null) {
        needsProgramChange = true;
      } else if (object.isInstancedMesh && materialProperties.instancingMorph && object.morphTexture == null) {
        needsProgramChange = true;
      } else if (object.isInstancedMesh && !materialProperties.instancingMorph && object.morphTexture != null) {
        needsProgramChange = true;
      } else if (materialProperties.envMap != envMap) {
        needsProgramChange = true;
      } else if (material.fog && materialProperties.fog != fog) {
        needsProgramChange = true;
      } else if (materialProperties.numClippingPlanes != null && (materialProperties.numClippingPlanes != clipping.numPlanes || materialProperties.numIntersection != clipping.numIntersection)) {
        needsProgramChange = true;
      } else if (materialProperties.vertexAlphas != vertexAlphas) {
        needsProgramChange = true;
      } else if (materialProperties.vertexTangents != vertexTangents) {
        needsProgramChange = true;
      } else if (materialProperties.morphTargets != morphTargets) {
        needsProgramChange = true;
      } else if (materialProperties.morphNormals != morphNormals) {
        needsProgramChange = true;
      } else if (materialProperties.morphColors != morphColors) {
        needsProgramChange = true;
      } else if (materialProperties.toneMapping != toneMapping) {
        needsProgramChange = true;
      } else if (materialProperties.morphTargetsCount != morphTargetsCount) {
        needsProgramChange = true;
      }
    } else {
      needsProgramChange = true;
      materialProperties.__version = material.version;
    }

    //

    var program = materialProperties.currentProgram;

    if (needsProgramChange) {
      program = getProgram(material, scene, object);
    }

    var refreshProgram = false;
    var refreshMaterial = false;
    var refreshLights = false;

    var p_uniforms = program.getUniforms();
    var m_uniforms = materialProperties.uniforms;

    if (state.useProgram(program.program)) {
      refreshProgram = true;
      refreshMaterial = true;
      refreshLights = true;
    }

    if (material.id != _currentMaterialId) {
      _currentMaterialId = material.id;
      refreshMaterial = true;
    }

    if (refreshProgram || _currentCamera != camera) {
      // common camera uniforms

      p_uniforms.setValue(_gl, 'projectionMatrix', camera.projectionMatrix);
      p_uniforms.setValue(_gl, 'viewMatrix', camera.matrixWorldInverse);

      var uCamPos = p_uniforms.map.cameraPosition;

      if (uCamPos != null) {
        uCamPos.setValue(_gl, _vector3.setFromMatrixPosition(camera.matrixWorld));
      }

      if (capabilities.logarithmicDepthBuffer) {
        p_uniforms.setValue(_gl, 'logDepthBufFC', 2.0 / (Math.log(camera.far + 1.0) / Math.LN2));
      }

      // consider moving isOrthographic to UniformLib and WebGLMaterials, see https://github.com/mrdoob/three.js/pull/26467#issuecomment-1645185067

      if (material.isMeshPhongMaterial || material.isMeshToonMaterial || material.isMeshLambertMaterial || material.isMeshBasicMaterial || material.isMeshStandardMaterial || material.isShaderMaterial) {
        p_uniforms.setValue(_gl, 'isOrthographic', camera.isOrthographicCamera);
      }

      if (_currentCamera != camera) {
        _currentCamera = camera;

        // lighting uniforms depend on the camera so enforce an update
        // now, in case this material supports lights - or later, when
        // the next material that does gets activated:

        refreshMaterial = true;		// set to true on material change
        refreshLights = true;		// remains set until update done
      }
    }

    // skinning and morph target uniforms must be set even if material didn't change
    // auto-setting of texture unit for bone and morph texture must go before other textures
    // otherwise textures used for skinning and morphing can take over texture units reserved for other material textures

    if (object.isSkinnedMesh) {
      p_uniforms.setOptional(_gl, object, 'bindMatrix');
      p_uniforms.setOptional(_gl, object, 'bindMatrixInverse');

      var skeleton = object.skeleton;

      if (skeleton != null) {
        if (skeleton.boneTexture == null) skeleton.computeBoneTexture();

        p_uniforms.setValue(_gl, 'boneTexture', skeleton.boneTexture, textures);
      }
    }

    if (object.isBatchedMesh) {
      p_uniforms.setOptional(_gl, object, 'batchingTexture');
      p_uniforms.setValue(_gl, 'batchingTexture', object._matricesTexture, textures);

      p_uniforms.setOptional(_gl, object, 'batchingColorTexture');
      if (object._colorsTexture != null) {
        p_uniforms.setValue(_gl, 'batchingColorTexture', object._colorsTexture, textures);
      }
    }

    var morphAttributes = geometry.morphAttributes;

    if (morphAttributes.position != null || morphAttributes.normal != null || (morphAttributes.color != null)) {
      morphtargets.update(object, geometry, program);
    }

    if (refreshMaterial || materialProperties.receiveShadow != object.receiveShadow) {
      materialProperties.receiveShadow = object.receiveShadow;
      p_uniforms.setValue(_gl, 'receiveShadow', object.receiveShadow);
    }

    // https://github.com/mrdoob/three.js/pull/24467#issuecomment-1209031512

    if (material.isMeshGouraudMaterial && material.envMap != null) {
      m_uniforms.envMap.value = envMap;

      m_uniforms.flipEnvMap.value = (envMap.isCubeTexture && !envMap.isRenderTargetTexture) ? -1 : 1;
    }

    if (material.isMeshStandardMaterial && material.envMap == null && scene.environment != null) {
      m_uniforms.envMapIntensity.value = scene.environmentIntensity;
    }

    if (refreshMaterial) {
      p_uniforms.setValue(_gl, 'toneMappingExposure', _this.toneMappingExposure);

      if (materialProperties.needsLights) {
        // lights uniforms depend on the program, so enforce an update
        // now, in case this material supports lights - or later, when
        // the next material that does gets activated:

        refreshMaterial = true;		// set to true on material change
        refreshLights = true;		// remains set until update done
      }
    }

    if (refreshLights) {
      uniforms.ambientLightColor.value = lights.state.ambient;
      uniforms.lightProbe.value = lights.state.probe;
      uniforms.directionalLights.value = lights.state.directional;
      uniforms.directionalLightShadows.value = lights.state.directionalShadow;
      uniforms.spotLights.value = lights.state.spot;
      uniforms.spotLightShadows.value = lights.state.spotShadow;
      uniforms.rectAreaLights.value = lights.state.rectArea;
      uniforms.ltc_1.value = lights.state.rectAreaLTC1;
      uniforms.ltc_2.value = lights.state.rectAreaLTC2;
      uniforms.pointLights.value = lights.state.point;
      uniforms.pointLightShadows.value = lights.state.pointShadow;
      uniforms.hemisphereLights.value = lights.state.hemi;

      uniforms.directionalShadowMap.value = lights.state.directionalShadowMap;
      uniforms.directionalShadowMatrix.value = lights.state.directionalShadowMatrix;
      uniforms.spotShadowMap.value = lights.state.spotShadowMap;
      uniforms.spotLightMatrix.value = lights.state.spotLightMatrix;
      uniforms.spotLightMap.value = lights.state.spotLightMap;
      uniforms.pointShadowMap.value = lights.state.pointShadowMap;
      uniforms.pointShadowMatrix.value = lights.state.pointShadowMatrix;
    }

    if (refreshMaterial) {
      if (material.isShaderMaterial || material.isRawShaderMaterial) {
        // TODO: There's a bug in the program cache that causes the program
        //       to get recreated if the material's `defines` are changed,
        //       but the `defines` are not actually used by the shader.
        //       This is a workaround.

        program.setDefine( 'USE_SHADOWMAP', material.shadowMap === true ? '1' : '0' );

        program.setDefine( 'USE_ENVMAP', material.envMap === null ? '0' : '1' );

        program.setDefine( 'USE_SKINNING', object.isSkinnedMesh === true ? '1' : '0' );

        program.setDefine( 'USE_MORPHTARGETS', material.morphTargets === true ? '1' : '0' );

        program.setDefine( 'USE_MORPHNORMALS', material.morphNormals === true ? '1' : '0' );

        program.setDefine( 'USE_COLOR_ALPHA', material.vertexColors === true ? '1' : '0' );

        program.setDefine( 'USE_VERTEX_TEXTURE', object.isBatchedMesh === true ? '1' : '0' );

        program.setDefine( 'USE_INSTANCING', object.isInstancedMesh === true ? '1' : '0' );

        program.setDefine( 'USE_INSTANCING_COLOR', object.instanceColor === null ? '0' : '1' );

        program.setDefine( 'USE_INSTANCING_MORPH', object.morphTexture === null ? '0' : '1' );

        program.setDefine( 'USE_TANGENT', material.normalMap === true || material.anisotropy > 0 ? '1' : '0' );

        program.setDefine( 'USE_UV', material.map === null && material.envMap === null && material.lightMap === null && material.aoMap === null && material.displacementMap === null && material.emissiveMap === null && material.gradientMap === null && material.normalMap === null && material.bumpMap === null && material.roughnessMap === null && material.metalnessMap === null && material.alphaMap === null && material.specularMap === null ? '0' : '1' );

        program.setDefine( 'USE_UV2', material.lightMap === null && material.aoMap === null && material.displacementMap === null && material.emissiveMap === null && material.gradientMap === null && material.normalMap === null && material.bumpMap === null && material.roughnessMap === null && material.metalnessMap === null && material.alphaMap === null && material.specularMap === null ? '0' : '1' );

        program.setDefine( 'USE_COLOR', material.vertexColors === true || material.color.isColor === true ? '1' : '0' );

        program.setDefine( 'USE_FOG', material.fog === true ? '1' : '0' );

        program.setDefine( 'USE_LOGDEPTHBUF', capabilities.logarithmicDepthBuffer === true ? '1' : '0' );

        program.setDefine( 'USE_MAP', material.map === null ? '0' : '1' );

        program.setDefine( 'USE_ALPHAMAP', material.alphaMap === null ? '0' : '1' );

        program.setDefine( 'USE_LIGHTMAP', material.lightMap === null ? '0' : '1' );

        program.setDefine( 'USE_AOMAP', material.aoMap === null ? '0' : '1' );

        program.setDefine( 'USE_EMISSIVEMAP', material.emissiveMap === null ? '0' : '1' );

        program.setDefine( 'USE_BUMPMAP', material.bumpMap === null ? '0' : '1' );

        program.setDefine( 'USE_NORMALMAP', material.normalMap === null ? '0' : '1' );

        program.setDefine( 'USE_DISPLACEMENTMAP', material.displacementMap === null ? '0' : '1' );

        program.setDefine( 'USE_ROUGHNESSMAP', material.roughnessMap === null ? '0' : '1' );

        program.setDefine( 'USE_METALNESSMAP', material.metalnessMap === null ? '0' : '1' );

        program.setDefine( 'USE_SPECULARMAP', material.specularMap === null ? '0' : '1' );

        program.setDefine( 'USE_GRADIENTMAP', material.gradientMap === null ? '0' : '1' );

        program.setDefine( 'USE_CUBEMAP', material.envMap === null ? '0' : '1' );

        program.setDefine( 'USE_CUBEMAP_TEX', material.envMap === null ? '0' : '1' );

        program.setDefine( 'USE_CUBEMAP_REFLECTION', material.envMap !== null && material.envMap.mapping === CubeReflectionMapping ? '1' : '0' );

        program.setDefine( 'USE_CUBEMAP_REFRACTION', material.envMap !== null && material.envMap.mapping === CubeRefractionMapping ? '1' : '0' );

        program.setDefine( 'USE_CUBEMAP_PROJECTION', material.envMap !== null && material.envMap.mapping === CubeProjectionMapping ? '1' : '0' );

        program.setDefine( 'USE_SHADOWS', material.shadowMap === true && object.receiveShadow === true ? '1' : '0' );

        program.setDefine( 'USE_BLENDING', material.blending > 0 ? '1' : '0' );

        program.setDefine( 'USE_PREMULTIPLIED_ALPHA', material.premultipliedAlpha === true ? '1' : '0' );

        program.setDefine( 'USE_CLIP', material.clipping === true ? '1' : '0' );

        program.setDefine( 'USE_VERTEX_COLOR', material.vertexColors === true ? '1' : '0' );

        program.setDefine( 'USE_FACE_VARYING', ( material.isMeshPhongMaterial || material.isMeshToonMaterial || material.isMeshLambertMaterial || material.isMeshBasicMaterial || material.isMeshStandardMaterial || material.isMeshLambertMaterial || material.isMeshGouraudMaterial ) && ( material.envMap !== null ) ? '1' : '0' );

        program.setDefine( 'USE_UV_VARYING', material.map !== null || material.bumpMap !== null || material.normalMap !== null || material.displacementMap !== null || material.roughnessMap !== null || material.metalnessMap !== null || material.alphaMap !== null || material.emissiveMap !== null || material.specularMap !== null || material.gradientMap !== null ? '1' : '0' );

        program.setDefine( 'USE_LIGHTMAP_VARYING', material.lightMap !== null ? '1' : '0' );

        program.setDefine( 'USE_AOMAP_VARYING', material.aoMap !== null ? '1' : '0' );

        program.setDefine( 'USE_COLOR_VARYING', material.vertexColors === true ? '1' : '0' );

        program.setDefine( 'USE_FOG_VARYING', material.fog === true ? '1' : '0' );

        program.setDefine( 'USE_SKINNING_VARYING', object.isSkinnedMesh === true ? '1' : '0' );

        program.setDefine( 'USE_MORPHTARGETS_VARYING', material.morphTargets === true ? '1' : '0' );

        program.setDefine( 'USE_MORPHNORMALS_VARYING', material.morphNormals === true ? '1' : '0' );

        program.setDefine( 'USE_INSTANCING_VARYING', object.isInstancedMesh === true ? '1' : '0' );

        program.setDefine( 'USE_INSTANCING_COLOR_VARYING', object.instanceColor === null ? '0' : '1' );

        program.setDefine( 'USE_INSTANCING_MORPH_VARYING', object.morphTexture === null ? '0' : '1' );

        program.setDefine( 'NUM_CLIPPING_PLANES', clipping.numPlanes.toString() );

        program.setDefine( 'NUM_DIR_LIGHTS', lights.state.directional.length.toString() );

        program.setDefine( 'NUM_SPOT_LIGHTS', lights.state.spot.length.toString() );

        program.setDefine( 'NUM_POINT_LIGHTS', lights.state.point.length.toString() );

        program.setDefine( 'NUM_HEMI_LIGHTS', lights.state.hemi.length.toString() );

        program.setDefine( 'NUM_RECT_AREA_LIGHTS', lights.state.rectArea.length.toString() );

        program.setDefine( 'NUM_DIR_LIGHT_SHADOWS', lights.state.directionalShadow.length.toString() );

        program.setDefine( 'NUM_SPOT_LIGHT_SHADOWS', lights.state.spotShadow.length.toString() );

        program.setDefine( 'NUM_POINT_LIGHT_SHADOWS', lights.state.pointShadow.length.toString() );

        program.setDefine( 'NUM_MORPH_TARGETS', geometry.morphAttributes.position !== undefined ? geometry.morphAttributes.position.length.toString() : '0' );

        program.setDefine( 'NUM_BONE_JOINTS', object.isSkinnedMesh === true && object.skeleton !== null ? object.skeleton.bones.length.toString() : '0' );

        program.setDefine( 'NUM_BONE_INFLUENCES', object.isSkinnedMesh === true && object.skeleton !== null ? object.skeleton.boneInverses.length.toString() : '0' );

        program.setDefine( 'MAX_BONES', Math.min( 256, object.isSkinnedMesh === true && object.skeleton !== null ? object.skeleton.bones.length : 0 ).toString() );

        program.setDefine( 'MAX_MORPH_TARGETS', Math.min( 48, geometry.morphAttributes.position !== undefined ? geometry.morphAttributes.position.length : 0 ).toString() );

      }

      if ( material.isMeshStandardMaterial ) {

        program.setDefine( 'STANDARD', '1' );

      }

      if ( material.isMeshPhongMaterial ) {

        program.setDefine( 'PHONG', '1' );

      }

      if ( material.isMeshLambertMaterial ) {

        program.setDefine( 'LAMBERT', '1' );

      }

      if ( material.isMeshBasicMaterial ) {

        program.setDefine( 'BASIC', '1' );

      }

      if ( material.isMeshToonMaterial ) {

        program.setDefine( 'TOON', '1' );

      }

      if ( material.isMeshGouraudMaterial ) {

        program.setDefine( 'GOURAUD', '1' );

      }

      program.setDefine( 'VERTEX_COLOR_B', material.vertexColors === true && ( geometry.attributes.color !== undefined && geometry.attributes.color.itemSize === 4 ) ? '1' : '0' );

      program.setDefine( 'VERTEX_COLOR_C', material.vertexColors === true && ( geometry.attributes.color !== undefined && geometry.attributes.color.itemSize === 3 ) ? '1' : '0' );

      program.setDefine( 'VERTEX_ALPHA', material.vertexColors === true && ( geometry.attributes.color !== undefined && geometry.attributes.color.itemSize === 4 ) ? '1' : '0' );

      program.setDefine( 'COLOR_SPACE', colorSpace === LinearSRGBColorSpace ? '1' : '0' );

      program.setDefine( 'TONE_MAPPING', toneMapping.toString() );

      program.setDefine( 'PHYSICAL', material.isMeshStandardMaterial ? '1' : '0' );

      program.setDefine( 'UV_TEXTURE', material.map !== null ? '1' : '0' );

      program.setDefine( 'LIGHTMAP_TEXTURE', material.lightMap !== null ? '1' : '0' );

      program.setDefine( 'AOMAP_TEXTURE', material.aoMap !== null ? '1' : '0' );

      program.setDefine( 'EMISSIVE_TEXTURE', material.emissiveMap !== null ? '1' : '0' );

      program.setDefine( 'BUMP_TEXTURE', material.bumpMap !== null ? '1' : '0' );

      program.setDefine( 'NORMAL_TEXTURE', material.normalMap !== null ? '1' : '0' );

      program.setDefine( 'DISPLACEMENT_TEXTURE', material.displacementMap !== null ? '1' : '0' );

      program.setDefine( 'ROUGHNESS_TEXTURE', material.roughnessMap !== null ? '1' : '0' );

      program.setDefine( 'METALNESS_TEXTURE', material.metalnessMap !== null ? '1' : '0' );

      program.setDefine( 'SPECULAR_TEXTURE', material.specularMap !== null ? '1' : '0' );

      program.setDefine( 'GRADIENT_TEXTURE', material.gradientMap !== null ? '1' : '0' );

      program.setDefine( 'ENV_TEXTURE', material.envMap !== null ? '1' : '0' );

      program.setDefine( 'SKINNING_TEXTURE', object.isSkinnedMesh === true && object.skeleton !== null ? '1' : '0' );

      program.setDefine( 'MORPH_TEXTURE', object.isInstancedMesh === true && object.morphTexture !== null ? '1' : '0' );

      program.setDefine( 'VERTEX_TEXTURE_COLOR', object.isBatchedMesh === true && object.colorTexture !== null ? '1' : '0' );

      program.setDefine( 'VERTEX_TEXTURE_MORPH', object.isInstancedMesh === true && object.morphTexture !== null ? '1' : '0' );

      program.setDefine( 'USE_COLOR_ALPHA', material.vertexColors === true && ( geometry.attributes.color !== undefined && geometry.attributes.color.itemSize === 4 ) ? '1' : '0' );

      
      program.setDefine( 'SKINNING_TEXTURE', object.isSkinnedMesh === true && object.skeleton !== null ? '1' : '0' );

      program.setDefine( 'MORPH_TEXTURE', object.isInstancedMesh === true && object.morphTexture !== null ? '1' : '0' );

      program.setDefine( 'VERTEX_TEXTURE_COLOR', object.isBatchedMesh === true && object.colorTexture !== null ? '1' : '0' );

      program.setDefine( 'VERTEX_TEXTURE_MORPH', object.isInstancedMesh === true && object.morphTexture !== null ? '1' : '0' );

      program.setDefine( 'USE_COLOR_ALPHA', material.vertexColors === true && ( geometry.attributes.color !== undefined && geometry.attributes.color.itemSize === 4 ) ? '1' : '0' );

      program.needsUpdate = true;

      // custom defines

      material.onDefine( program, object );

      // custom uniforms

      material.onBeforeCompile( program, _this );

      //

      if ( refreshProgram === true ) {

        refreshProgram = false;

        // reset the attributes/uniforms once the program has been set

        p_uniforms.setValue( _gl, 'diffuse', material.color );
        p_uniforms.setValue( _gl, 'opacity', material.opacity );
        p_uniforms.setValue( _gl, 'map', material.map, textures );

        // set the default value for the 'morphTargetInfluences' uniform,
        // which is needed if the material uses morphTargets but the
        // geometry doesn't (e.g. a LOD with a simplified geometry).

        if ( material.morphTargets === true ) {

          p_uniforms.setValue( _gl, 'morphTargetInfluences', new Array<Float>( 8 ), 0 );

        }

        // set the default value for the 'morphTargetBaseInfluences' uniform,
        // which is needed if the material uses morphTargets but the
        // geometry doesn't (e.g. a LOD with a simplified geometry).

        if ( material.morphTargets === true ) {

          p_uniforms.setValue( _gl, 'morphTargetBaseInfluences', new Array<Float>( 8 ), 0 );

        }

      }

      if ( refreshMaterial === true ) {

        refreshMaterial = false;

        if ( material.isMeshStandardMaterial ) {

          m_uniforms.roughness.value = material.roughness;
          m_uniforms.metalness.value = material.metalness;
          m_uniforms.envMap.value = envMap;

          m_uniforms.envMapIntensity.value = material.envMapIntensity;

          m_uniforms.flipEnvMap.value = ( envMap.isCubeTexture && envMap.isRenderTargetTexture === false ) ? - 1 : 1;

        }

        if ( material.isMeshPhongMaterial ) {

          m_uniforms.specular.value = material.specular;
          m_uniforms.shininess.value = material.shininess;

        }

        if ( material.isMeshLambertMaterial || material.isMeshBasicMaterial || material.isMeshGouraudMaterial ) {

          m_uniforms.emissive.value = material.emissive;

        }

        if ( material.isMeshBasicMaterial || material.isMeshGouraudMaterial ) {

          m_uniforms.combine.value = material.combine;

        }

        if ( material.isMeshGouraudMaterial ) {

          m_uniforms.reflectivity.value = material.reflectivity;

        }

        if ( material.isMeshBasicMaterial || material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshToonMaterial || material.isMeshStandardMaterial ) {

          m_uniforms.map.value = material.map;
          m_uniforms.alphaMap.value = material.alphaMap;
          m_uniforms.lightMap.value = material.lightMap;
          m_uniforms.aoMap.value = material.aoMap;
          m_uniforms.emissiveMap.value = material.emissiveMap;
          m_uniforms.bumpMap.value = material.bumpMap;
          m_uniforms.normalMap.value = material.normalMap;
          m_uniforms.displacementMap.value = material.displacementMap;
          m_uniforms.roughnessMap.value = material.roughnessMap;
          m_uniforms.metalnessMap.value = material.metalnessMap;
          m_uniforms.specularMap.value = material.specularMap;
          m_uniforms.gradientMap.value = material.gradientMap;

          if ( material.map !== null ) {

            m_uniforms.map.needsUpdate = true;

          }

          if ( material.alphaMap !== null ) {

            m_uniforms.alphaMap.needsUpdate = true;

          }

          if ( material.lightMap !== null ) {

            m_uniforms.lightMap.needsUpdate = true;

          }

          if ( material.aoMap !== null ) {

            m_uniforms.aoMap.needsUpdate = true;

          }

          if ( material.emissiveMap !== null ) {

            m_uniforms.emissiveMap.needsUpdate = true;

          }

          if ( material.bumpMap !== null ) {

            m_uniforms.bumpMap.needsUpdate = true;

          }

          if ( material.normalMap !== null ) {

            m_uniforms.normalMap.needsUpdate = true;

          }

          if ( material.displacementMap !== null ) {

            m_uniforms.displacementMap.needsUpdate = true;

          }

          if ( material.roughnessMap !== null ) {

            m_uniforms.roughnessMap.needsUpdate = true;

          }

          if ( material.metalnessMap !== null ) {

            m_uniforms.metalnessMap.needsUpdate = true;

          }

          if ( material.specularMap !== null ) {

            m_uniforms.specularMap.needsUpdate = true;

          }

          if ( material.gradientMap !== null ) {

            m_uniforms.gradientMap.needsUpdate = true;

          }

        }

        if ( material.isMeshPhongMaterial ||
          material.isMeshToonMaterial ||
          material.isMeshLambertMaterial ||
          material.isMeshBasicMaterial ||
          material.isMeshStandardMaterial ||
          material.isShaderMaterial ) {

          m_uniforms.envMap.value = envMap;
          m_uniforms.flipEnvMap.value = ( envMap.isCubeTexture && envMap.isRenderTargetTexture === false ) ? - 1 : 1;

        }

        if ( material.isMeshPhongMaterial ||
          material.isMeshToonMaterial ||
          material.isMeshLambertMaterial ||
          material.isMeshBasicMaterial ) {

          m_uniforms.specular.value = material.specular;

        }

        if ( material.isMeshPhongMaterial ) {

          m_uniforms.shininess.value = material.shininess;

        }

        if ( material.isMeshLambertMaterial ||
          material.isMeshBasicMaterial ||
          material.isMeshPhongMaterial ||
          material.isMeshToonMaterial ||
          material.isMeshStandardMaterial ||
          material.isShaderMaterial ) {

          m_uniforms.emissive.value = material.emissive;

        }

        if ( material.isMeshBasicMaterial || material.isMeshLambertMaterial || material.isMeshPhongMaterial ) {

          m_uniforms.combine.value = material.combine;

        }

        if ( material.isMeshBasicMaterial || material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshToonMaterial || material.isMeshStandardMaterial ) {

          if ( material.aoMap !== null ) {

            m_uniforms.aoMapIntensity.value = material.aoMapIntensity;

          }

          if ( material.bumpMap !== null ) {

            m_uniforms.bumpScale.value = material.bumpScale;

          }

          if ( material.normalMap !== null ) {

            m_uniforms.normalScale.value = material.normalScale;

          }

          if ( material.displacementMap !== null ) {

            m_uniforms.displacementScale.value = material.displacementScale;
            m_uniforms.displacementBias.value = material.displacementBias;

          }

        }

        if ( material.isMeshBasicMaterial || material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshToonMaterial ) {

          m_uniforms.specular.value = material.specular;
          m_uniforms.shininess.value = material.shininess;

        }

        if ( material.isMeshBasicMaterial || material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshToonMaterial ) {

          m_uniforms.combine.value = material.combine;

        }

        if ( material.isMeshPhongMaterial || material.isMeshToonMaterial || material.isMeshStandardMaterial ) {

          m_uniforms.reflectivity.value = material.reflectivity;

        }

        if ( material.isMeshStandardMaterial ) {

          m_uniforms.roughness.value = material.roughness;
          m_uniforms.metalness.value = material.metalness;
          m_uniforms.envMapIntensity.value = material.envMapIntensity;

        }

        if ( material.isMeshToonMaterial ) {

          m_uniforms.gradientMap.value = material.gradientMap;

        }

        if ( material.isShaderMaterial ) {

          const uniforms = material.uniforms;

          for ( const u in uniforms ) {

            const uniform = uniforms[ u ];

            if ( uniform.value !== null && uniform.value.needsUpdate ) {

              p_uniforms.setValue( _gl, u, uniform.value );

            }

          }

        }

      }

      if ( refreshLights === true ) {

        refreshLights = false;

        uniforms.ambientLightColor.value = lights.state.ambient;
        uniforms.lightProbe.value = lights.state.probe;
        uniforms.directionalLights.value = lights.state.directional;
        uniforms.directionalLightShadows.value = lights.state.directionalShadow;
        uniforms.spotLights.value = lights.state.spot;
        uniforms.spotLightShadows.value = lights.state.spotShadow;
        uniforms.rectAreaLights.value = lights.state.rectArea;
        uniforms.ltc_1.value = lights.state.rectAreaLTC1;
        uniforms.ltc_2.value = lights.state.rectAreaLTC2;
        uniforms.pointLights.value = lights.state.point;
        uniforms.pointLightShadows.value = lights.state.pointShadow;
        uniforms.hemisphereLights.value = lights.state.hemi;

        uniforms.directionalShadowMap.value = lights.state.directionalShadowMap;
        uniforms.directionalShadowMatrix.value = lights.state.directionalShadowMatrix;
        uniforms.spotShadowMap.value = lights.state.spotShadowMap;
        uniforms.spotLightMatrix.value = lights.state.spotLightMatrix;
        uniforms.spotLightMap.value = lights.state.spotLightMap;
        uniforms.pointShadowMap.value = lights.state.pointShadowMap;
        uniforms.pointShadowMatrix.value = lights.state.pointShadowMatrix;

      }

      if ( material.isMeshPhongMaterial ||
        material.isMeshToonMaterial ||
        material.isMeshLambertMaterial ||
        material.isMeshBasicMaterial ||
        material.isMeshStandardMaterial ||
        material.isShaderMaterial ) {

        p_uniforms.setValue( _gl, 'isOrthographic', camera.isOrthographicCamera === true );

      }

      //

      materialProperties.currentProgram = program;

      return program;

    }

  }

  public function onMaterialDispose( event:Dynamic ) {

    const material = event.target;

    const materialProperties = properties.get( material );

    materialProperties.programs.forEach( function ( program, programCacheKey ) {

      programCache.releaseProgram( program );

    } );

    properties.delete( material );

  }

  public function materialNeedsLights( material:Material ) {

    if ( material.isMeshStandardMaterial === true ) {

      return true;

    }

    if ( material.isMeshPhongMaterial === true ) {

      return true;

    }

    if ( material.isMeshLambertMaterial === true ) {

      return true;

    }

    if ( material.isMeshToonMaterial === true ) {

      return true;

    }

    if ( material.isMeshBasicMaterial === true ) {

      return false;

    }

    if ( material.isShaderMaterial === true ) {

      return ( material.lights === true );

    }

    if ( material.isRawShaderMaterial === true ) {

      return false;

    }

    return false;

  }

}