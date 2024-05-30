import three.core.Object3D;
import three.core.Scene;
import three.cameras.Camera;
import three.core.Geometry;
import three.materials.Material;
import three.core.Group;
import three.renderers.WebGLRenderer;
import three.renderers.WebGLProperties;
import three.renderers.WebGLTextures;
import three.renderers.WebGLClipping;
import three.renderers.WebGLMorphtargets;
import three.renderers.WebGLPrograms;
import three.renderers.WebGLUniforms;
import three.renderers.WebGLState;
import three.renderers.WebGLRenderStates;
import three.renderers.WebGLProgram;
import three.scenes.Fog;
import three.textures.Texture;
import three.math.Matrix4;
import three.math.Vector3;
import three.constants.*;


然后，实现函数 `renderObject`:


function renderObject(object:Object3D, scene:Scene, camera:Camera, geometry:Geometry, material:Material, group:Group):Void {
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


然后，实现函数 `getProgram`:


function getProgram(material:Material, scene:Scene, object:Object3D):WebGLProgram {
    if (!scene.isScene) scene = _emptyScene; // scene could be a Mesh, Line, Points, ...

    var materialProperties = properties.get(material);
    var lights = currentRenderState.state.lights;
    var shadowsArray = currentRenderState.state.shadowsArray;
    var lightsStateVersion = lights.state.version;

    var parameters = programCache.getParameters(material, lights.state, shadowsArray, scene, object);
    var programCacheKey = programCache.getProgramCacheKey(parameters);

    var programs = materialProperties.programs;

    materialProperties.environment = material.isMeshStandardMaterial ? scene.environment : null;
    materialProperties.fog = scene.fog;
    materialProperties.envMap = (material.isMeshStandardMaterial ? cubeuvmaps : cubemaps).get(material.envMap != null ? material.envMap : materialProperties.environment);
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
    if (!material.isShaderMaterial && !material.isRawShaderMaterial || material.clipping) {
        uniforms.clippingPlanes = clipping.uniform;
    }

    updateCommonMaterialProperties(material, parameters);

    // store the light setup it was created for
    materialProperties.needsLights = materialNeedsLights(material);
    materialProperties.lightsStateVersion = lightsStateVersion;

    if (materialProperties.needsLights) {
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

    materialProperties.currentProgram = program;
    materialProperties.uniformsList = null;

    return program;
}


接下来，实现函数 `getUniformList`:


function getUniformList(materialProperties:Dynamic):Array<Dynamic> {
    if (materialProperties.uniformsList == null) {
        var progUniforms = materialProperties.currentProgram.getUniforms();
        materialProperties.uniformsList = WebGLUniforms.seqWithValue(progUniforms.seq, materialProperties.uniforms);
    }
    return materialProperties.uniformsList;
}


再实现函数 `updateCommonMaterialProperties`:


function updateCommonMaterialProperties(material:Material, parameters:Dynamic):Void {
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


最后，实现函数 `setProgram`:


function setProgram(camera:Camera, scene:Scene, geometry:Geometry, material:Material, object:Object3D):Void {
    if (!scene.isScene) scene = _emptyScene; // scene could be a Mesh, Line, Points, ...

    textures.resetTextureUnits();

    var fog = scene.fog;
    var environment = material.isMeshStandardMaterial ? scene.environment : null;
    var colorSpace = (_currentRenderTarget == null) ? _this.outputColorSpace : (_currentRenderTarget.isXRRenderTarget ? _currentRenderTarget.texture.colorSpace : LinearSRGBColorSpace);
    var envMap = (material.isMeshStandardMaterial ? cubeuvmaps : cubemaps).get(material.envMap != null ? material.envMap : environment);
    var vertexAlphas = material.vertexColors && geometry.attributes.color != null && geometry.attributes.color.itemSize == 4;
    var vertexTangents = geometry.attributes.tangent != null && (material.normalMap != null || material.anisotropy > 0);
    var morphTargets = geometry.morphAttributes.position != null;
    var morphNormals = geometry.morphAttributes.normal != null;
    var morphColors = geometry.morphAttributes.color != null;

    var toneMapping = NoToneMapping;

    if (material.toneMapped) {
        if (_currentRenderTarget == null || _currentRenderTarget.isXRRenderTarget) {
            toneMapping = _this.toneMapping;
        }
    }

    var morphAttribute = geometry.morphAttributes.position != null ? geometry.morphAttributes.position : (geometry.morphAttributes.normal != null ? geometry.morphAttributes.normal : geometry.morphAttributes.color);
    var morphTargetsCount = (morphAttribute != null) ? morphAttribute.length : 0;

    var materialProperties = properties.get(material);
    var lights = currentRenderState.state.lights;

    if (_clippingEnabled) {
        if (_localClippingEnabled || camera != _currentCamera) {
            var useCache = camera == _currentCamera && material.id == _currentMaterialId;
            clipping.setState(material, camera, useCache);
        }
    }

    var needsProgramChange = false;

    if (material.version == materialProperties.__version) {
        if (materialProperties.needsLights && materialProperties.lightsStateVersion != lights.state.version) {
            needsProgramChange = true;
        } else if (materialProperties.outputColorSpace != colorSpace) {
            needsProgramChange = true;
        } else if (materialProperties.environment != environment) {
            needsProgramChange = true;
        } else if (materialProperties.fog != fog) {
            needsProgramChange = true;
        } else if (materialProperties.envMap != envMap) {
            needsProgramChange = true;
        } else if (materialProperties.envMapRotation != (materialProperties.environment != null && material.envMap == null ? scene.environmentRotation : material.envMapRotation)) {
            needsProgramChange = true;
        } else if (materialProperties.batching != (object.isMesh && object.geometry.attributes["position"].data == null)) {
            needsProgramChange = true;
        } else if (materialProperties.batchingColor != (object.isMesh && object.geometry.attributes["color"] != null)) {
            needsProgramChange = true;
        } else if (materialProperties.instancing != (object.isMesh && object.isInstancedMesh)) {
            needsProgramChange = true;
        } else if (materialProperties.instancingColor != (object.isMesh && object.isInstancedMesh && object.geometry.attributes["instanceColor"] != null)) {
            needsProgramChange = true;
        } else if (materialProperties.instancingMorph != (object.isMesh && object.isInstancedMesh && object.geometry.morphAttributes.position != null)) {
            needsProgramChange = true;
        } else if (materialProperties.skinning != (object.isSkinnedMesh && material.skinning)) {
            needsProgramChange = true;
        } else if (materialProperties.morphTargets != morphTargets) {
            needsProgramChange = true;
        } else if (materialProperties.morphNormals != morphNormals) {
            needsProgramChange = true;
        } else if (materialProperties.morphColors != morphColors) {
            needsProgramChange = true;
        } else if (materialProperties.morphTargetsCount != morphTargetsCount) {
            needsProgramChange = true;
        } else if (materialProperties.numClippingPlanes != clipping.numPlanes) {
            needsProgramChange = true;
        } else if (materialProperties.numIntersection != clipping.numIntersection) {
            needsProgramChange = true;
        } else if (materialProperties.vertexAlphas != vertexAlphas) {
            needsProgramChange = true;
        } else if (materialProperties.vertexTangents != vertexTangents) {
            needsProgramChange = true;
        } else if (materialProperties.toneMapping != toneMapping) {
            needsProgramChange = true;
        }
    } else {
        needsProgramChange = true;
        materialProperties.__version = material.version;
    }

    if (needsProgramChange) {
        materialProperties.needsLights = materialNeedsLights(material);
        materialProperties.lightsStateVersion = lights.state.version;

        var shaders:WebGLProgram = getProgram(material, scene, object);

        materialProperties.currentProgram = shaders;
        materialProperties.uniformsList = null;
    }

    var progUniforms = materialProperties.currentProgram.getUniforms();

    if (!material.isShaderMaterial && !material.isRawShaderMaterial || material.clipping) {
        materialProperties.uniforms.clippingPlanes = clipping.uniform;
    }

    if (!materialProperties.programs.has(progUniforms)) {
        materialProperties.programs.set(progUniforms, materialProperties.currentProgram);
    }

    material.onBeforeRender(_this, scene, camera, geometry, object, group);

    updateCommonMaterialProperties(material, materialProperties.currentProgram.parameters);

    var uniformsList = getUniformList(materialProperties);

    textures.update(materialProperties);

    updateObject(material, uniformsList, materialProperties);

    material.onBeforeCompile(materialProperties.currentProgram.parameters, _this);
    material.onBeforeRender(_this, scene, camera, geometry, material, object, group);

    material.needsUpdate = false;

    materialProperties.currentProgram.bind();
    materialProperties.programs.set(materialProperties.currentProgram.getUniforms(), materialProperties.currentProgram);

    object.onBeforeRender(_this, scene, camera, geometry, material, group);
}