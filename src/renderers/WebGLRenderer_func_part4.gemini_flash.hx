package;

import three.WebGLRenderer;
import three.Camera;
import three.Scene;
import three.Object3D;
import three.Material;
import three.BufferGeometry;
import three.WebGLProgram;
import three.WebGLUniforms;
import three.Properties;

@:access(three.WebGLRenderer)
@:access(three.WebGLProgram)
@:access(three.WebGLUniforms)
class WebGLRenderer_ExtractProgramHandling {

	// ... (other methods)

	function renderObject( object : Object3D, scene : Scene, camera : Camera, geometry : BufferGeometry, material : Material, group : Dynamic ) : Void {

		object.onBeforeRender( _this, scene, camera, geometry, material, group );

		object.modelViewMatrix.multiplyMatrices( camera.matrixWorldInverse, object.matrixWorld );
		object.normalMatrix.getNormalMatrix( object.modelViewMatrix );

		material.onBeforeRender( _this, scene, camera, geometry, object, group );

		if ( material.transparent == true && material.side == DoubleSide && material.forceSinglePass == false ) {

			material.side = BackSide;
			material.needsUpdate = true;
			_this.renderBufferDirect( camera, scene, geometry, material, object, group );

			material.side = FrontSide;
			material.needsUpdate = true;
			_this.renderBufferDirect( camera, scene, geometry, material, object, group );

			material.side = DoubleSide;

		} else {

			_this.renderBufferDirect( camera, scene, geometry, material, object, group );

		}

		object.onAfterRender( _this, scene, camera, geometry, material, group );

	}

	function getProgram( material : Material, scene : Scene, object : Object3D ) : WebGLProgram {

		if ( ! scene.isScene ) scene = _emptyScene; // scene could be a Mesh, Line, Points, ...

		var materialProperties = properties.get( material );

		var lights = currentRenderState.state.lights;
		var shadowsArray = currentRenderState.state.shadowsArray;

		var lightsStateVersion = lights.state.version;

		var parameters = programCache.getParameters( material, lights.state, shadowsArray, scene, object );
		var programCacheKey = programCache.getProgramCacheKey( parameters );

		var programs : Map<String, WebGLProgram> = materialProperties.programs;

		// always update environment and fog - changing these trigger an getProgram call, but it's possible that the program doesn't change

		materialProperties.environment = ( material.isMeshStandardMaterial ? scene.environment : null );
		materialProperties.fog = scene.fog;
		materialProperties.envMap = ( material.isMeshStandardMaterial ? cubeuvmaps : cubemaps ).get( material.envMap != null ? material.envMap : materialProperties.environment );
		materialProperties.envMapRotation = ( materialProperties.environment != null && material.envMap == null ) ? scene.environmentRotation : material.envMapRotation;

		if ( programs == null ) {

			// new material

			material.addEventListener( 'dispose', onMaterialDispose );

			programs = new Map();
			materialProperties.programs = programs;

		}

		var program = programs.get( programCacheKey );

		if ( program != null ) {

			// early out if program and light state is identical

			if ( materialProperties.currentProgram == program && materialProperties.lightsStateVersion == lightsStateVersion ) {

				updateCommonMaterialProperties( material, parameters );

				return program;

			}

		} else {

			parameters.uniforms = programCache.getUniforms( material );

			material.onBuild( object, parameters, _this );

			material.onBeforeCompile( parameters, _this );

			program = programCache.acquireProgram( parameters, programCacheKey );
			programs.set( programCacheKey, program );

			materialProperties.uniforms = parameters.uniforms;

		}

		var uniforms = materialProperties.uniforms;

		if ( ( ! material.isShaderMaterial && ! material.isRawShaderMaterial ) || material.clipping == true ) {

			uniforms.clippingPlanes = clipping.uniform;

		}

		updateCommonMaterialProperties( material, parameters );

		// store the light setup it was created for

		materialProperties.needsLights = materialNeedsLights( material );
		materialProperties.lightsStateVersion = lightsStateVersion;

		if ( materialProperties.needsLights ) {

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

	function getUniformList( materialProperties : { currentProgram : WebGLProgram, uniforms : Dynamic, uniformsList : WebGLUniforms } ) : WebGLUniforms {

		if ( materialProperties.uniformsList == null ) {

			var progUniforms = materialProperties.currentProgram.getUniforms();
			materialProperties.uniformsList = WebGLUniforms.seqWithValue( progUniforms.seq, materialProperties.uniforms );

		}

		return materialProperties.uniformsList;

	}

	function updateCommonMaterialProperties( material : Material, parameters : { outputColorSpace : Int, batching : Bool, batchingColor : Bool, instancing : Bool, instancingColor : Bool, instancingMorph : Bool, skinning : Bool, morphTargets : Bool, morphNormals : Bool, morphColors : Bool, morphTargetsCount : Int, numClippingPlanes : Int, numClipIntersection : Int, vertexAlphas : Bool, vertexTangents : Bool, toneMapping : Int } ) : Void {

		var materialProperties = properties.get( material );

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

	function setProgram( camera : Camera, scene : Scene, geometry : BufferGeometry, material : Material, object : Object3D ) : Void {

		if ( ! scene.isScene ) scene = _emptyScene; // scene could be a Mesh, Line, Points, ...

		textures.resetTextureUnits();

		var fog = scene.fog;
		var environment = ( material.isMeshStandardMaterial ? scene.environment : null );
		var colorSpace = ( _currentRenderTarget == null ) ? _this.outputColorSpace : ( _currentRenderTarget.isXRRenderTarget ? _currentRenderTarget.texture.colorSpace : LinearSRGBColorSpace );
		var envMap = ( material.isMeshStandardMaterial ? cubeuvmaps : cubemaps ).get( material.envMap != null ? material.envMap : environment );
		var vertexAlphas = material.vertexColors && geometry.attributes.color != null && geometry.attributes.color.itemSize == 4;
		var vertexTangents = geometry.attributes.tangent != null && ( material.normalMap != null || material.anisotropy > 0 );
		var morphTargets = geometry.morphAttributes.position != null;
		var morphNormals = geometry.morphAttributes.normal != null;
		var morphColors = geometry.morphAttributes.color != null;

		var toneMapping = NoToneMapping;

		if ( material.toneMapped ) {

			if ( _currentRenderTarget == null || _currentRenderTarget.isXRRenderTarget ) {

				toneMapping = _this.toneMapping;

			}

		}

		var morphAttribute = geometry.morphAttributes.position != null ? geometry.morphAttributes.position : ( geometry.morphAttributes.normal != null ? geometry.morphAttributes.normal : geometry.morphAttributes.color );
		var morphTargetsCount = ( morphAttribute != null ) ? morphAttribute.length : 0;

		var materialProperties = properties.get( material );
		var lights = currentRenderState.state.lights;

		if ( _clippingEnabled == true ) {

			if ( _localClippingEnabled == true || camera != _currentCamera ) {

				var useCache =
					camera == _currentCamera &&
					material.id == _currentMaterialId;

				// we might want to call this function with some ClippingGroup
				// object instead of the material, once it becomes feasible
				// (#8465, #8379)
				clipping.setState( material, camera, useCache );

			}

		}

		//

		var needsProgramChange = false;

		if ( material.version == materialProperties.__version ) {

			if ( materialProperties.needsLights && ( materialProperties.lightsStateVersion != lights.state.version ) ) {

				needsProgramChange = true;

			} else if ( materialProperties.outputColorSpace != colorSpace ) {

				needsProgramChange = true;

			} else if ( object.isBatchedMesh && ! materialProperties.batching ) {

				needsProgramChange = true;

			} else if ( ! object.isBatchedMesh && materialProperties.batching ) {

				needsProgramChange = true;

			} else if ( object.isBatchedMesh && materialProperties.batchingColor && object.colorTexture == null ) {

				needsProgramChange = true;

			} else if ( object.isBatchedMesh && ! materialProperties.batchingColor && object.colorTexture != null ) {

				needsProgramChange = true;

			} else if ( object.isInstancedMesh && ! materialProperties.instancing ) {

				needsProgramChange = true;

			} else if ( ! object.isInstancedMesh && materialProperties.instancing ) {

				needsProgramChange = true;

			} else if ( object.isSkinnedMesh && ! materialProperties.skinning ) {

				needsProgramChange = true;

			} else if ( ! object.isSkinnedMesh && materialProperties.skinning ) {

				needsProgramChange = true;

			} else if ( object.isInstancedMesh && materialProperties.instancingColor && object.instanceColor == null ) {

				needsProgramChange = true;

			} else if ( object.isInstancedMesh && ! materialProperties.instancingColor && object.instanceColor != null ) {

				needsProgramChange = true;

			} else if ( object.isInstancedMesh && materialProperties.instancingMorph && object.morphTexture == null ) {

				needsProgramChange = true;

			} else if ( object.isInstancedMesh && ! materialProperties.instancingMorph && object.morphTexture != null ) {

				needsProgramChange = true;

			} else if ( materialProperties.envMap != envMap ) {

				needsProgramChange = true;

			} else if ( material.fog && materialProperties.fog != fog ) {

				needsProgramChange = true;

			} else if ( materialProperties.numClippingPlanes != null &&
				( materialProperties.numClippingPlanes != clipping.numPlanes ||
				materialProperties.numIntersection != clipping.numIntersection ) ) {

				needsProgramChange = true;

			} else if ( materialProperties.vertexAlphas != vertexAlphas ) {

				needsProgramChange = true;

			} else if ( materialProperties.vertexTangents != vertexTangents ) {

				needsProgramChange = true;

			} else if ( materialProperties.morphTargets != morphTargets ) {

				needsProgramChange = true;

			} else if ( materialProperties.morphNormals != morphNormals ) {

				needsProgramChange = true;

			} else if ( materialProperties.morphColors != morphColors ) {

				needsProgramChange = true;

			} else if ( materialProperties.toneMapping != toneMapping ) {

				needsProgramChange = true;

			} else if ( materialProperties.morphTargetsCount != morphTargetsCount ) {

				needsProgramChange = true;

			}

		} else {

			needsProgramChange = true;
			materialProperties.__version = material.version;

		}

		//

		var program = materialProperties.currentProgram;

		if ( needsProgramChange ) {

			program = getProgram( material, scene, object );

		}

		var refreshProgram = false;
		var refreshMaterial = false;
		var refreshLights = false;

		var p_uniforms = program.getUniforms(),
			m_uniforms = materialProperties.uniforms;

		if ( state.useProgram( program.program ) ) {

			refreshProgram = true;
			refreshMaterial = true;
			refreshLights = true;

		}

		if ( material.id != _currentMaterialId ) {

			_currentMaterialId = material.id;

			refreshMaterial = true;

		}

		if ( refreshProgram || _currentCamera != camera ) {

			// common camera uniforms

			p_uniforms.setValue( _gl, 'projectionMatrix', camera.projectionMatrix );
			p_uniforms.setValue( _gl, 'viewMatrix', camera.matrixWorldInverse );

			var uCamPos = p_uniforms.map.cameraPosition;

			if ( uCamPos != null ) {

				uCamPos.setValue( _gl, _vector3.setFromMatrixPosition( camera.matrixWorld ) );

			}

			if ( capabilities.logarithmicDepthBuffer ) {

				p_uniforms.setValue( _gl, 'logDepthBufFC',
					2.0 / ( Math.log( camera.far + 1.0 ) / Math.LN2 ) );

			}

			// consider moving isOrthographic to UniformLib and WebGLMaterials, see https://github.com/mrdoob/three.js/pull/26467#issuecomment-1645185067

			if ( material.isMeshPhongMaterial ||
				material.isMeshToonMaterial ||
				material.isMeshLambertMaterial ||
				material.isMeshBasicMaterial ||
				material.isMeshStandardMaterial ||
				material.isShaderMaterial ) {

				p_uniforms.setValue( _gl, 'isOrthographic', camera.isOrthographicCamera );

			}

			if ( _currentCamera != camera ) {

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

		if ( object.isSkinnedMesh ) {

			p_uniforms.setOptional( _gl, object, 'bindMatrix' );
			p_uniforms.setOptional( _gl, object, 'bindMatrixInverse' );

			var skeleton = object.skeleton;

			if ( skeleton != null ) {

				if ( skeleton.boneTexture == null ) skeleton.computeBoneTexture();

				p_uniforms.setValue( _gl, 'boneTexture', skeleton.boneTexture, textures );

			}

		}

		if ( object.isBatchedMesh ) {

			p_uniforms.setOptional( _gl, object, 'batchingTexture' );
			p_uniforms.setValue( _gl, 'batchingTexture', object._matricesTexture, textures );

			p_uniforms.setOptional( _gl, object, 'batchingColorTexture' );
			if ( object._colorsTexture != null ) {

				p_uniforms.setValue( _gl, 'batchingColorTexture', object._colorsTexture, textures );

			}

		}

		var morphAttributes = geometry.morphAttributes;

		if ( morphAttributes.position != null || morphAttributes.normal != null || ( morphAttributes.color != null ) ) {

			morphtargets.update( object, geometry, program );

		}

		if ( refreshMaterial || materialProperties.receiveShadow != object.receiveShadow ) {

			materialProperties.receiveShadow = object.receiveShadow;
			p_uniforms.setValue( _gl, 'receiveShadow', object.receiveShadow );

		}

		// https://github.com/mrdoob/three.js/pull/24467#issuecomment-1209031512

		if ( material.isMeshGouraudMaterial && material.envMap != null ) {

			m_uniforms.envMap.value = envMap;

			m_uniforms.flipEnvMap.value = ( envMap.isCubeTexture && ! envMap.isRenderTargetTexture ) ? - 1 : 1;

		}

		if ( material.isMeshStandardMaterial && material.envMap == null && scene.environment != null ) {

			m_uniforms.envMapIntensity.value = scene.environmentIntensity;

		}

		if ( refreshMaterial ) {

			p_uniforms.setValue( _gl, 'toneMappingExposure', _this.toneMappingExposure );

			if ( materialProperties.needsLights ) {

				// TODO: Add the rest of the function

			}

		}

	}

	// ... (rest of the class)

}