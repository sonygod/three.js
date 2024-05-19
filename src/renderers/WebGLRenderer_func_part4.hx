package three.js.src.renderers;

import three.js.src.core.Camera;
import three.js.src.core.Geometry;
import three.js.src.core.Material;
import three.js.src.core.Object3D;
import three.js.src.core.Scene;
import three.js.src.math.Matrix4;
import three.js.src.math.Vector3;
import three.js.src.renderers.WebGLRenderer;

class WebGLRendererFuncPart4 {

    public function renderObject(object:Object3D, scene:Scene, camera:Camera, geometry:Geometry, material:Material, group:Array<Object3D>) {
        object.onBeforeRender(this, scene, camera, geometry, material, group);

        object.modelViewMatrix.multiplyMatrices(camera.matrixWorldInverse, object.matrixWorld);
        object.normalMatrix.getNormalMatrix(object.modelViewMatrix);

        material.onBeforeRender(this, scene, camera, geometry, object, group);

        if (material.transparent && material.side == DoubleSide && !material.forceSinglePass) {
            material.side = BackSide;
            material.needsUpdate = true;
            renderBufferDirect(camera, scene, geometry, material, object, group);

            material.side = FrontSide;
            material.needsUpdate = true;
            renderBufferDirect(camera, scene, geometry, material, object, group);

            material.side = DoubleSide;
        } else {
            renderBufferDirect(camera, scene, geometry, material, object, group);
        }

        object.onAfterRender(this, scene, camera, geometry, material, group);
    }

    public function getProgram(material:Material, scene:Scene, object:Object3D):WebGLProgram {
        if (!Std.isOfType(scene, Scene)) scene = _emptyScene;

        var materialProperties:Dynamic = properties.get(material);

        var lights:Array<Light> = currentRenderState.state.lights;
        var shadowsArray:Array<Shadow> = currentRenderState.state.shadowsArray;

        var lightsStateVersion:Int = lights.state.version;

        var parameters:Dynamic = programCache.getParameters(material, lights.state, shadowsArray, scene, object);
        var programCacheKey:String = programCache.getProgramCacheKey(parameters);

        var programs:Map<String, WebGLProgram> = materialProperties.programs;

        materialProperties.environment = material.isMeshStandardMaterial ? scene.environment : null;
        materialProperties.fog = scene.fog;
        materialProperties.envMap = (material.isMeshStandardMaterial ? cubeuvmaps : cubemaps).get(material.envMap || materialProperties.environment);
        materialProperties.envMapRotation = (materialProperties.environment != null && material.envMap == null) ? scene.environmentRotation : material.envMapRotation;

        if (programs == null) {
            material.addEventListener('dispose', onMaterialDispose);

            programs = new Map<String, WebGLProgram>();
            materialProperties.programs = programs;
        }

        var program:WebGLProgram = programs.get(programCacheKey);

        if (program != null) {
            if (materialProperties.currentProgram == program && materialProperties.lightsStateVersion == lightsStateVersion) {
                updateCommonMaterialProperties(material, parameters);
                return program;
            }
        } else {
            parameters.uniforms = programCache.getUniforms(material);

            material.onBuild(object, parameters, this);

            material.onBeforeCompile(parameters, this);

            program = programCache.acquireProgram(parameters, programCacheKey);
            programs.set(programCacheKey, program);

            materialProperties.uniforms = parameters.uniforms;
        }

        var uniforms:Dynamic = materialProperties.uniforms;

        if (!material.isShaderMaterial && !material.isRawShaderMaterial || material.clipping) {
            uniforms.clippingPlanes = clipping.uniform;
        }

        updateCommonMaterialProperties(material, parameters);

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

    public function getUniformList(materialProperties:Dynamic):WebGLUniforms {
        if (materialProperties.uniformsList == null) {
            var progUniforms:WebGLUniforms = materialProperties.currentProgram.getUniforms();
            materialProperties.uniformsList = WebGLUniforms.seqWithValue(progUniforms.seq, materialProperties.uniforms);
        }

        return materialProperties.uniformsList;
    }

    public function updateCommonMaterialProperties(material:Material, parameters:Dynamic):Void {
        var materialProperties:Dynamic = properties.get(material);

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

    public function setProgram(camera:Camera, scene:Scene, geometry:Geometry, material:Material, object:Object3D):Void {
        if (!Std.isOfType(scene, Scene)) scene = _emptyScene;

        textures.resetTextureUnits();

        var fog:Fog = scene.fog;
        var environment:Environment = material.isMeshStandardMaterial ? scene.environment : null;
        var colorSpace:ColorSpace = ( _currentRenderTarget == null ) ? _this.outputColorSpace : ( _currentRenderTarget.isXRRenderTarget ) ? _currentRenderTarget.texture.colorSpace : LinearSRGBColorSpace;
        var envMap:Texture = ( material.isMeshStandardMaterial ? cubeuvmaps : cubemaps ).get( material.envMap || environment );
        var vertexAlphas:Bool = material.vertexColors && geometry.attributes.color != null && geometry.attributes.color.itemSize == 4;
        var vertexTangents:Bool = geometry.attributes.tangent != null && ( material.normalMap || material.anisotropy > 0 );
        var morphTargets:Bool = geometry.morphAttributes.position != null || geometry.morphAttributes.normal != null || geometry.morphAttributes.color != null;
        var morphNormals:Bool = geometry.morphAttributes.normal != null;
        var morphColors:Bool = geometry.morphAttributes.color != null;

        var toneMapping:Int = NoToneMapping;

        if (material.toneMapped) {
            if (_currentRenderTarget == null || _currentRenderTarget.isXRRenderTarget) {
                toneMapping = _this.toneMapping;
            }
        }

        var morphAttribute:Array<Dynamic> = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
        var morphTargetsCount:Int = morphAttribute != null ? morphAttribute.length : 0;

        var materialProperties:Dynamic = properties.get(material);
        var lights:Array<Light> = currentRenderState.state.lights;

        if (_clippingEnabled) {
            if (_localClippingEnabled || camera != _currentCamera) {
                clipping.setState(material, camera, _localClippingEnabled || camera != _currentCamera);
            }
        }

        var needsProgramChange:Bool = false;

        if (material.version == materialProperties.__version) {
            if (materialProperties.needsLights && materialProperties.lightsStateVersion != lights.state.version) {
                needsProgramChange = true;
            } else if (materialProperties.outputColorSpace != colorSpace) {
                needsProgramChange = true;
            } else if (object.isBatchedMesh && materialProperties.batching == false) {
                needsProgramChange = true;
            } else if (!object.isBatchedMesh && materialProperties.batching == true) {
                needsProgramChange = true;
            } else if (object.isBatchedMesh && materialProperties.batchingColor == true && object.colorTexture == null) {
                needsProgramChange = true;
            } else if (object.isBatchedMesh && materialProperties.batchingColor == false && object.colorTexture != null) {
                needsProgramChange = true;
            } else if (object.isInstancedMesh && materialProperties.instancing == false) {
                needsProgramChange = true;
            } else if (!object.isInstancedMesh && materialProperties.instancing == true) {
                needsProgramChange = true;
            } else if (object.isSkinnedMesh && materialProperties.skinning == false) {
                needsProgramChange = true;
            } else if (!object.isSkinnedMesh && materialProperties.skinning == true) {
                needsProgramChange = true;
            } else if (object.isInstancedMesh && materialProperties.instancingColor == true && object.instanceColor == null) {
                needsProgramChange = true;
            } else if (object.isInstancedMesh && materialProperties.instancingColor == false && object.instanceColor != null) {
                needsProgramChange = true;
            } else if (object.isInstancedMesh && materialProperties.instancingMorph == true && object.morphTexture == null) {
                needsProgramChange = true;
            } else if (object.isInstancedMesh && materialProperties.instancingMorph == false && object.morphTexture != null) {
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

        var program:WebGLProgram = materialProperties.currentProgram;

        if (needsProgramChange) {
            program = getProgram(material, scene, object);
        }

        var refreshProgram:Bool = false;
        var refreshMaterial:Bool = false;
        var refreshLights:Bool = false;

        var p_uniforms:WebGLUniforms = program.getUniforms();
        var m_uniforms:Dynamic = materialProperties.uniforms;

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
            p_uniforms.setValue(_gl, 'projectionMatrix', camera.projectionMatrix);
            p_uniforms.setValue(_gl, 'viewMatrix', camera.matrixWorldInverse);

            var uCamPos:WebGLUniform = p_uniforms.map.cameraPosition;

            if (uCamPos != null) {
                uCamPos.setValue(_gl, _vector3.setFromMatrixPosition(camera.matrixWorld));
            }

            if (capabilities.logarithmicDepthBuffer) {
                p_uniforms.setValue(_gl, 'logDepthBufFC', 2.0 / (Math.log(camera.far + 1.0) / Math.LN2));
            }

            if (material.isMeshPhongMaterial || material.isMeshToonMaterial || material.isMeshLambertMaterial || material.isMeshBasicMaterial || material.isMeshStandardMaterial || material.isShaderMaterial) {
                p_uniforms.setValue(_gl, 'isOrthographic', camera.isOrthographicCamera);
            }

            if (_currentCamera != camera) {
                _currentCamera = camera;
                refreshMaterial = true;
                refreshLights = true;
            }
        }

        // ...
    }
}