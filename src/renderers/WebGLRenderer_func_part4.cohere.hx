function renderObject(object:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, material:Dynamic, group:Dynamic):Void {
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

    object.onAfterRender(_this, scene, camera, geometry, material, group);
}

function getProgram(material:Dynamic, scene:Dynamic, object:Dynamic):Dynamic {
    if (!scene.isScene) scene = _emptyScene; // scene could be a Mesh, Line, Points, ...

    var materialProperties = properties.get(material);

    var lights = currentRenderState.state.lights;
    var shadowsArray = currentRenderState.state.shadowsArray;

    var lightsStateVersion = lights.state.version;

    var parameters = programCache.getParameters(material, lights.state, shadowsArray, scene, object);
    var programCacheKey = programCache.getProgramCacheKey(parameters);

    var programs = materialProperties.programs;

    // always update environment and fog - changing these trigger an getProgram call, but it's possible that the program doesn't change
    materialProperties.environment = if (material.isMeshStandardMaterial) scene.environment else null;
    materialProperties.fog = scene.fog;
    materialProperties.envMap = if (material.isMeshStandardMaterial) cubeuvmaps else cubemaps).get(material.envMap or materialProperties.environment);
    materialProperties.envMapRotation = if (materialProperties.environment != null && material.envMap == null) scene.environmentRotation else material.envMapRotation;

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

    if (!material.isShaderMaterial && !material.isRawShaderMaterial) || material.clipping) {
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

function getUniformList(materialProperties:Dynamic):Dynamic {
    if (materialProperties.uniformsList == null) {
        var progUniforms = materialProperties.currentProgram.getUniforms();
        materialProperties.uniformsList = WebGLUniforms.seqWithValue(progUniforms.seq, materialProperties.uniforms);
    }

    return materialProperties.uniformsList;
}

function updateCommonMaterialProperties(material:Dynamic, parameters:Dynamic):Void {
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

function setProgram(camera:Dynamic, scene:Dynamic, geometry:Dynamic, material:Dynamic, object:Dynamic):Void {
    if (!scene.isScene) scene = _emptyScene; // scene could be a Mesh, Line, Points, ...

    textures.resetTextureUnits();

    var fog = scene.fog;
    var environment = if (material.isMeshStandardMaterial) scene.environment else null;
    var colorSpace = if (_currentRenderTarget == null) _this.outputColorSpace else if (_currentRenderTarget.isXRRenderTarget) _currentRenderTarget.texture.colorSpace else LinearSRGBColorSpace;
    var envMap = if (material.isMeshStandardMaterial) cubeuvmaps else cubemaps).get(material.envMap or environment);
    var vertexAlphas = material.vertexColors && geometry.attributes.color && geometry.attributes.color.itemSize == 4;
    var vertexTangents = geometry.attributes.tangent && (material.normalMap || material.anisotropy > 0);
    var morphTargets = geometry.morphAttributes.position;
    var morphNormals = geometry.morphAttributes.normal;
    var morphColors = geometry.morphAttributes.color;

    var toneMapping = NoToneMapping;

    if (material.toneMapped) {
        if (_currentRenderTarget == null || _currentRenderTarget.isXRRenderTarget) {
            toneMapping = _this.toneMapping;
        }
    }

    var morphAttribute = geometry.morphAttributes.position or geometry.morphAttributes.normal or geometry.morphAttributes.color;
    var morphTargetsCount = if (morphAttribute != null) morphAttribute.length else 0;

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
        if (materialProperties.needsLights && materialProperties.lightsStateVersion != lights.state.version) {
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

            refreshMaterial = true; // set to true on material change
            refreshLights = true; // remains set until update done
        }
    }

    // skinning and morph target uniforms must be set even if material didn't change
    // auto-setting of texture unit for bone and morph texture must go before other textures
    // otherwise textures used for skinning and morphing can take over texture units reserved for other material textures

    if (object.isSkinnedMesh) {
        p_uniforms.setOptional(_gl, object, 'bindMatrix');
        p_uniforms.setOptional(_gl, object, 'bindMatrixInverse');

        var skeleton = object.skeleton;

        if (skeleton) {
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

    if (morphAttributes.position != null || morphAttributes.normal != null || morphAttributes.color != null) {
        morphtargets.update(object, geometry, program);
    }

    if (refreshMaterial || materialProperties.receiveShadow != object.receiveShadow) {
        materialProperties.receiveShadow = object.receiveShadow;
        p_uniforms.setValue(_gl, 'receiveShadow', object.receiveShadow);
    }

    // https://github.com/mrdoob/three.js/pull/24467#issuecomment-1209031512

    if (material.isMeshGouraudMaterial && material.envMap != null) {
        m_uniforms.envMap.value = envMap;

        m_uniforms.flipEnvMap.value = if (envMap.isCubeTexture && !envMap.isRenderTargetTexture) -1 else 1;
    }

    if (material.isMeshStandardMaterial && material.envMap == null && scene.environment != null) {
        m_uniforms.envMapIntensity.value = scene.environmentIntensity;
    }

    if (refreshMaterial) {
        p_uniforms.setValue(_gl, 'toneMappingExposure', _this.toneMappingExposure);

        if (materialProperties.needsLights) {