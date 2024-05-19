		function renderObject( object, scene, camera, geometry, material, group ) {

			object.onBeforeRender( _this, scene, camera, geometry, material, group );

			object.modelViewMatrix.multiplyMatrices( camera.matrixWorldInverse, object.matrixWorld );
			object.normalMatrix.getNormalMatrix( object.modelViewMatrix );

			material.onBeforeRender( _this, scene, camera, geometry, object, group );

			if ( material.transparent === true && material.side === DoubleSide && material.forceSinglePass === false ) {

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

		function getProgram( material, scene, object ) {

			if ( scene.isScene !== true ) scene = _emptyScene; // scene could be a Mesh, Line, Points, ...

			const materialProperties = properties.get( material );

			const lights = currentRenderState.state.lights;
			const shadowsArray = currentRenderState.state.shadowsArray;

			const lightsStateVersion = lights.state.version;

			const parameters = programCache.getParameters( material, lights.state, shadowsArray, scene, object );
			const programCacheKey = programCache.getProgramCacheKey( parameters );

			let programs = materialProperties.programs;

			// always update environment and fog - changing these trigger an getProgram call, but it's possible that the program doesn't change

			materialProperties.environment = material.isMeshStandardMaterial ? scene.environment : null;
			materialProperties.fog = scene.fog;
			materialProperties.envMap = ( material.isMeshStandardMaterial ? cubeuvmaps : cubemaps ).get( material.envMap || materialProperties.environment );
			materialProperties.envMapRotation = ( materialProperties.environment !== null && material.envMap === null ) ? scene.environmentRotation : material.envMapRotation;

			if ( programs === undefined ) {

				// new material

				material.addEventListener( 'dispose', onMaterialDispose );

				programs = new Map();
				materialProperties.programs = programs;

			}

			let program = programs.get( programCacheKey );

			if ( program !== undefined ) {

				// early out if program and light state is identical

				if ( materialProperties.currentProgram === program && materialProperties.lightsStateVersion === lightsStateVersion ) {

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

			const uniforms = materialProperties.uniforms;

			if ( ( ! material.isShaderMaterial && ! material.isRawShaderMaterial ) || material.clipping === true ) {

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

		function getUniformList( materialProperties ) {

			if ( materialProperties.uniformsList === null ) {

				const progUniforms = materialProperties.currentProgram.getUniforms();
				materialProperties.uniformsList = WebGLUniforms.seqWithValue( progUniforms.seq, materialProperties.uniforms );

			}

			return materialProperties.uniformsList;

		}

		function updateCommonMaterialProperties( material, parameters ) {

			const materialProperties = properties.get( material );

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

		function setProgram( camera, scene, geometry, material, object ) {

			if ( scene.isScene !== true ) scene = _emptyScene; // scene could be a Mesh, Line, Points, ...

			textures.resetTextureUnits();

			const fog = scene.fog;
			const environment = material.isMeshStandardMaterial ? scene.environment : null;
			const colorSpace = ( _currentRenderTarget === null ) ? _this.outputColorSpace : ( _currentRenderTarget.isXRRenderTarget === true ? _currentRenderTarget.texture.colorSpace : LinearSRGBColorSpace );
			const envMap = ( material.isMeshStandardMaterial ? cubeuvmaps : cubemaps ).get( material.envMap || environment );
			const vertexAlphas = material.vertexColors === true && !! geometry.attributes.color && geometry.attributes.color.itemSize === 4;
			const vertexTangents = !! geometry.attributes.tangent && ( !! material.normalMap || material.anisotropy > 0 );
			const morphTargets = !! geometry.morphAttributes.position;
			const morphNormals = !! geometry.morphAttributes.normal;
			const morphColors = !! geometry.morphAttributes.color;

			let toneMapping = NoToneMapping;

			if ( material.toneMapped ) {

				if ( _currentRenderTarget === null || _currentRenderTarget.isXRRenderTarget === true ) {

					toneMapping = _this.toneMapping;

				}

			}

			const morphAttribute = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
			const morphTargetsCount = ( morphAttribute !== undefined ) ? morphAttribute.length : 0;

			const materialProperties = properties.get( material );
			const lights = currentRenderState.state.lights;

			if ( _clippingEnabled === true ) {

				if ( _localClippingEnabled === true || camera !== _currentCamera ) {

					const useCache =
						camera === _currentCamera &&
						material.id === _currentMaterialId;

					// we might want to call this function with some ClippingGroup
					// object instead of the material, once it becomes feasible
					// (#8465, #8379)
					clipping.setState( material, camera, useCache );

				}

			}

			//

			let needsProgramChange = false;

			if ( material.version === materialProperties.__version ) {

				if ( materialProperties.needsLights && ( materialProperties.lightsStateVersion !== lights.state.version ) ) {

					needsProgramChange = true;

				} else if ( materialProperties.outputColorSpace !== colorSpace ) {

					needsProgramChange = true;

				} else if ( object.isBatchedMesh && materialProperties.batching === false ) {

					needsProgramChange = true;

				} else if ( ! object.isBatchedMesh && materialProperties.batching === true ) {

					needsProgramChange = true;

				} else if ( object.isBatchedMesh && materialProperties.batchingColor === true && object.colorTexture === null ) {

					needsProgramChange = true;

				} else if ( object.isBatchedMesh && materialProperties.batchingColor === false && object.colorTexture !== null ) {

					needsProgramChange = true;

				} else if ( object.isInstancedMesh && materialProperties.instancing === false ) {

					needsProgramChange = true;

				} else if ( ! object.isInstancedMesh && materialProperties.instancing === true ) {

					needsProgramChange = true;

				} else if ( object.isSkinnedMesh && materialProperties.skinning === false ) {

					needsProgramChange = true;

				} else if ( ! object.isSkinnedMesh && materialProperties.skinning === true ) {

					needsProgramChange = true;

				} else if ( object.isInstancedMesh && materialProperties.instancingColor === true && object.instanceColor === null ) {

					needsProgramChange = true;

				} else if ( object.isInstancedMesh && materialProperties.instancingColor === false && object.instanceColor !== null ) {

					needsProgramChange = true;

				} else if ( object.isInstancedMesh && materialProperties.instancingMorph === true && object.morphTexture === null ) {

					needsProgramChange = true;

				} else if ( object.isInstancedMesh && materialProperties.instancingMorph === false && object.morphTexture !== null ) {

					needsProgramChange = true;

				} else if ( materialProperties.envMap !== envMap ) {

					needsProgramChange = true;

				} else if ( material.fog === true && materialProperties.fog !== fog ) {

					needsProgramChange = true;

				} else if ( materialProperties.numClippingPlanes !== undefined &&
					( materialProperties.numClippingPlanes !== clipping.numPlanes ||
					materialProperties.numIntersection !== clipping.numIntersection ) ) {

					needsProgramChange = true;

				} else if ( materialProperties.vertexAlphas !== vertexAlphas ) {

					needsProgramChange = true;

				} else if ( materialProperties.vertexTangents !== vertexTangents ) {

					needsProgramChange = true;

				} else if ( materialProperties.morphTargets !== morphTargets ) {

					needsProgramChange = true;

				} else if ( materialProperties.morphNormals !== morphNormals ) {

					needsProgramChange = true;

				} else if ( materialProperties.morphColors !== morphColors ) {

					needsProgramChange = true;

				} else if ( materialProperties.toneMapping !== toneMapping ) {

					needsProgramChange = true;

				} else if ( materialProperties.morphTargetsCount !== morphTargetsCount ) {

					needsProgramChange = true;

				}

			} else {

				needsProgramChange = true;
				materialProperties.__version = material.version;

			}

			//

			let program = materialProperties.currentProgram;

			if ( needsProgramChange === true ) {

				program = getProgram( material, scene, object );

			}

			let refreshProgram = false;
			let refreshMaterial = false;
			let refreshLights = false;

			const p_uniforms = program.getUniforms(),
				m_uniforms = materialProperties.uniforms;

			if ( state.useProgram( program.program ) ) {

				refreshProgram = true;
				refreshMaterial = true;
				refreshLights = true;

			}

			if ( material.id !== _currentMaterialId ) {

				_currentMaterialId = material.id;

				refreshMaterial = true;

			}

			if ( refreshProgram || _currentCamera !== camera ) {

				// common camera uniforms

				p_uniforms.setValue( _gl, 'projectionMatrix', camera.projectionMatrix );
				p_uniforms.setValue( _gl, 'viewMatrix', camera.matrixWorldInverse );

				const uCamPos = p_uniforms.map.cameraPosition;

				if ( uCamPos !== undefined ) {

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

					p_uniforms.setValue( _gl, 'isOrthographic', camera.isOrthographicCamera === true );

				}

				if ( _currentCamera !== camera ) {

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

				const skeleton = object.skeleton;

				if ( skeleton ) {

					if ( skeleton.boneTexture === null ) skeleton.computeBoneTexture();

					p_uniforms.setValue( _gl, 'boneTexture', skeleton.boneTexture, textures );

				}

			}

			if ( object.isBatchedMesh ) {

				p_uniforms.setOptional( _gl, object, 'batchingTexture' );
				p_uniforms.setValue( _gl, 'batchingTexture', object._matricesTexture, textures );

				p_uniforms.setOptional( _gl, object, 'batchingColorTexture' );
				if ( object._colorsTexture !== null ) {

					p_uniforms.setValue( _gl, 'batchingColorTexture', object._colorsTexture, textures );

				}

			}

			const morphAttributes = geometry.morphAttributes;

			if ( morphAttributes.position !== undefined || morphAttributes.normal !== undefined || ( morphAttributes.color !== undefined ) ) {

				morphtargets.update( object, geometry, program );

			}

			if ( refreshMaterial || materialProperties.receiveShadow !== object.receiveShadow ) {

				materialProperties.receiveShadow = object.receiveShadow;
				p_uniforms.setValue( _gl, 'receiveShadow', object.receiveShadow );

			}

			// https://github.com/mrdoob/three.js/pull/24467#issuecomment-1209031512

			if ( material.isMeshGouraudMaterial && material.envMap !== null ) {

				m_uniforms.envMap.value = envMap;

				m_uniforms.flipEnvMap.value = ( envMap.isCubeTexture && envMap.isRenderTargetTexture === false ) ? - 1 : 1;

			}

			if ( material.isMeshStandardMaterial && material.envMap === null && scene.environment !== null ) {

				m_uniforms.envMapIntensity.value = scene.environmentIntensity;

			}

			if ( refreshMaterial ) {

				p_uniforms.setValue( _gl, 'toneMappingExposure', _this.toneMappingExposure );

				if ( materialProperties.needsLights ) {
