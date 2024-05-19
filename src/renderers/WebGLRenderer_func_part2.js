
					const clearColor = background.getClearColor();
					const a = background.getClearAlpha();
					const r = clearColor.r;
					const g = clearColor.g;
					const b = clearColor.b;

					if ( isUnsignedType ) {

						uintClearColor[ 0 ] = r;
						uintClearColor[ 1 ] = g;
						uintClearColor[ 2 ] = b;
						uintClearColor[ 3 ] = a;
						_gl.clearBufferuiv( _gl.COLOR, 0, uintClearColor );

					} else {

						intClearColor[ 0 ] = r;
						intClearColor[ 1 ] = g;
						intClearColor[ 2 ] = b;
						intClearColor[ 3 ] = a;
						_gl.clearBufferiv( _gl.COLOR, 0, intClearColor );

					}

				} else {

					bits |= _gl.COLOR_BUFFER_BIT;

				}

			}

			if ( depth ) bits |= _gl.DEPTH_BUFFER_BIT;
			if ( stencil ) {

				bits |= _gl.STENCIL_BUFFER_BIT;
				this.state.buffers.stencil.setMask( 0xffffffff );

			}

			_gl.clear( bits );

		};

		this.clearColor = function () {

			this.clear( true, false, false );

		};

		this.clearDepth = function () {

			this.clear( false, true, false );

		};

		this.clearStencil = function () {

			this.clear( false, false, true );

		};

		//

		this.dispose = function () {

			canvas.removeEventListener( 'webglcontextlost', onContextLost, false );
			canvas.removeEventListener( 'webglcontextrestored', onContextRestore, false );
			canvas.removeEventListener( 'webglcontextcreationerror', onContextCreationError, false );

			renderLists.dispose();
			renderStates.dispose();
			properties.dispose();
			cubemaps.dispose();
			cubeuvmaps.dispose();
			objects.dispose();
			bindingStates.dispose();
			uniformsGroups.dispose();
			programCache.dispose();

			xr.dispose();

			xr.removeEventListener( 'sessionstart', onXRSessionStart );
			xr.removeEventListener( 'sessionend', onXRSessionEnd );

			animation.stop();

		};

		// Events

		function onContextLost( event ) {

			event.preventDefault();

			console.log( 'THREE.WebGLRenderer: Context Lost.' );

			_isContextLost = true;

		}

		function onContextRestore( /* event */ ) {

			console.log( 'THREE.WebGLRenderer: Context Restored.' );

			_isContextLost = false;

			const infoAutoReset = info.autoReset;
			const shadowMapEnabled = shadowMap.enabled;
			const shadowMapAutoUpdate = shadowMap.autoUpdate;
			const shadowMapNeedsUpdate = shadowMap.needsUpdate;
			const shadowMapType = shadowMap.type;

			initGLContext();

			info.autoReset = infoAutoReset;
			shadowMap.enabled = shadowMapEnabled;
			shadowMap.autoUpdate = shadowMapAutoUpdate;
			shadowMap.needsUpdate = shadowMapNeedsUpdate;
			shadowMap.type = shadowMapType;

		}

		function onContextCreationError( event ) {

			console.error( 'THREE.WebGLRenderer: A WebGL context could not be created. Reason: ', event.statusMessage );

		}

		function onMaterialDispose( event ) {

			const material = event.target;

			material.removeEventListener( 'dispose', onMaterialDispose );

			deallocateMaterial( material );

		}

		// Buffer deallocation

		function deallocateMaterial( material ) {

			releaseMaterialProgramReferences( material );

			properties.remove( material );

		}


		function releaseMaterialProgramReferences( material ) {

			const programs = properties.get( material ).programs;

			if ( programs !== undefined ) {

				programs.forEach( function ( program ) {

					programCache.releaseProgram( program );

				} );

				if ( material.isShaderMaterial ) {

					programCache.releaseShaderCache( material );

				}

			}

		}

		// Buffer rendering

		this.renderBufferDirect = function ( camera, scene, geometry, material, object, group ) {

			if ( scene === null ) scene = _emptyScene; // renderBufferDirect second parameter used to be fog (could be null)

			const frontFaceCW = ( object.isMesh && object.matrixWorld.determinant() < 0 );

			const program = setProgram( camera, scene, geometry, material, object );

			state.setMaterial( material, frontFaceCW );

			//

			let index = geometry.index;
			let rangeFactor = 1;

			if ( material.wireframe === true ) {

				index = geometries.getWireframeAttribute( geometry );

				if ( index === undefined ) return;

				rangeFactor = 2;

			}

			//

			const drawRange = geometry.drawRange;
			const position = geometry.attributes.position;

			let drawStart = drawRange.start * rangeFactor;
			let drawEnd = ( drawRange.start + drawRange.count ) * rangeFactor;

			if ( group !== null ) {

				drawStart = Math.max( drawStart, group.start * rangeFactor );
				drawEnd = Math.min( drawEnd, ( group.start + group.count ) * rangeFactor );

			}

			if ( index !== null ) {

				drawStart = Math.max( drawStart, 0 );
				drawEnd = Math.min( drawEnd, index.count );

			} else if ( position !== undefined && position !== null ) {

				drawStart = Math.max( drawStart, 0 );
				drawEnd = Math.min( drawEnd, position.count );

			}

			const drawCount = drawEnd - drawStart;

			if ( drawCount < 0 || drawCount === Infinity ) return;

			//

			bindingStates.setup( object, material, program, geometry, index );

			let attribute;
			let renderer = bufferRenderer;

			if ( index !== null ) {

				attribute = attributes.get( index );

				renderer = indexedBufferRenderer;
				renderer.setIndex( attribute );

			}

			//

			if ( object.isMesh ) {

				if ( material.wireframe === true ) {

					state.setLineWidth( material.wireframeLinewidth * getTargetPixelRatio() );
					renderer.setMode( _gl.LINES );

				} else {

					renderer.setMode( _gl.TRIANGLES );

				}

			} else if ( object.isLine ) {

				let lineWidth = material.linewidth;

				if ( lineWidth === undefined ) lineWidth = 1; // Not using Line*Material

				state.setLineWidth( lineWidth * getTargetPixelRatio() );

				if ( object.isLineSegments ) {

					renderer.setMode( _gl.LINES );

				} else if ( object.isLineLoop ) {

					renderer.setMode( _gl.LINE_LOOP );

				} else {

					renderer.setMode( _gl.LINE_STRIP );

				}

			} else if ( object.isPoints ) {

				renderer.setMode( _gl.POINTS );

			} else if ( object.isSprite ) {

				renderer.setMode( _gl.TRIANGLES );

			}

			if ( object.isBatchedMesh ) {

				if ( object._multiDrawInstances !== null ) {

					renderer.renderMultiDrawInstances( object._multiDrawStarts, object._multiDrawCounts, object._multiDrawCount, object._multiDrawInstances );

				} else {

					renderer.renderMultiDraw( object._multiDrawStarts, object._multiDrawCounts, object._multiDrawCount );

				}

			} else if ( object.isInstancedMesh ) {

				renderer.renderInstances( drawStart, drawCount, object.count );

			} else if ( geometry.isInstancedBufferGeometry ) {

				const maxInstanceCount = geometry._maxInstanceCount !== undefined ? geometry._maxInstanceCount : Infinity;
				const instanceCount = Math.min( geometry.instanceCount, maxInstanceCount );

				renderer.renderInstances( drawStart, drawCount, instanceCount );

			} else {

				renderer.render( drawStart, drawCount );

			}

		};

		// Compile

		function prepareMaterial( material, scene, object ) {

			if ( material.transparent === true && material.side === DoubleSide && material.forceSinglePass === false ) {

				material.side = BackSide;
				material.needsUpdate = true;
				getProgram( material, scene, object );

				material.side = FrontSide;
				material.needsUpdate = true;
				getProgram( material, scene, object );

				material.side = DoubleSide;

			} else {

				getProgram( material, scene, object );

			}

		}

		this.compile = function ( scene, camera, targetScene = null ) {

			if ( targetScene === null ) targetScene = scene;

			currentRenderState = renderStates.get( targetScene );
			currentRenderState.init( camera );

			renderStateStack.push( currentRenderState );

			// gather lights from both the target scene and the new object that will be added to the scene.

			targetScene.traverseVisible( function ( object ) {

				if ( object.isLight && object.layers.test( camera.layers ) ) {

					currentRenderState.pushLight( object );

					if ( object.castShadow ) {

						currentRenderState.pushShadow( object );

					}

				}

			} );

			if ( scene !== targetScene ) {

				scene.traverseVisible( function ( object ) {

					if ( object.isLight && object.layers.test( camera.layers ) ) {

						currentRenderState.pushLight( object );

						if ( object.castShadow ) {

							currentRenderState.pushShadow( object );

						}

					}

				} );

			}

			currentRenderState.setupLights( _this._useLegacyLights );

			// Only initialize materials in the new scene, not the targetScene.

			const materials = new Set();

			scene.traverse( function ( object ) {

				const material = object.material;

				if ( material ) {

					if ( Array.isArray( material ) ) {

						for ( let i = 0; i < material.length; i ++ ) {

							const material2 = material[ i ];

							prepareMaterial( material2, targetScene, object );
							materials.add( material2 );

						}

					} else {

						prepareMaterial( material, targetScene, object );
						materials.add( material );

					}

				}

			} );

			renderStateStack.pop();
			currentRenderState = null;

			return materials;

		};

		// compileAsync

		this.compileAsync = function ( scene, camera, targetScene = null ) {

			const materials = this.compile( scene, camera, targetScene );

			// Wait for all the materials in the new object to indicate that they're
			// ready to be used before resolving the promise.

			return new Promise( ( resolve ) => {

				function checkMaterialsReady() {

					materials.forEach( function ( material ) {

						const materialProperties = properties.get( material );
						const program = materialProperties.currentProgram;

						if ( program.isReady() ) {

							// remove any programs that report they're ready to use from the list
							materials.delete( material );

						}

					} );

					// once the list of compiling materials is empty, call the callback

					if ( materials.size === 0 ) {

						resolve( scene );
						return;

					}

					// if some materials are still not ready, wait a bit and check again

					setTimeout( checkMaterialsReady, 10 );

				}

				if ( extensions.get( 'KHR_parallel_shader_compile' ) !== null ) {

					// If we can check the compilation status of the materials without
					// blocking then do so right away.

					checkMaterialsReady();

				} else {

					// Otherwise start by waiting a bit to give the materials we just
					// initialized a chance to finish.

					setTimeout( checkMaterialsReady, 10 );

				}

			} );

		};
