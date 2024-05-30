
		// Animation Loop

		let onAnimationFrameCallback = null;

		function onAnimationFrame( time ) {

			if ( onAnimationFrameCallback ) onAnimationFrameCallback( time );

		}

		function onXRSessionStart() {

			animation.stop();

		}

		function onXRSessionEnd() {

			animation.start();

		}

		const animation = new WebGLAnimation();
		animation.setAnimationLoop( onAnimationFrame );

		if ( typeof self !== 'undefined' ) animation.setContext( self );

		this.setAnimationLoop = function ( callback ) {

			onAnimationFrameCallback = callback;
			xr.setAnimationLoop( callback );

			( callback === null ) ? animation.stop() : animation.start();

		};

		xr.addEventListener( 'sessionstart', onXRSessionStart );
		xr.addEventListener( 'sessionend', onXRSessionEnd );

		// Rendering

		this.render = function ( scene, camera ) {

			if ( camera !== undefined && camera.isCamera !== true ) {

				console.error( 'THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.' );
				return;

			}

			if ( _isContextLost === true ) return;

			// update scene graph

			if ( scene.matrixWorldAutoUpdate === true ) scene.updateMatrixWorld();

			// update camera matrices and frustum

			if ( camera.parent === null && camera.matrixWorldAutoUpdate === true ) camera.updateMatrixWorld();

			if ( xr.enabled === true && xr.isPresenting === true ) {

				if ( xr.cameraAutoUpdate === true ) xr.updateCamera( camera );

				camera = xr.getCamera(); // use XR camera for rendering

			}

			//
			if ( scene.isScene === true ) scene.onBeforeRender( _this, scene, camera, _currentRenderTarget );

			currentRenderState = renderStates.get( scene, renderStateStack.length );
			currentRenderState.init( camera );

			renderStateStack.push( currentRenderState );

			_projScreenMatrix.multiplyMatrices( camera.projectionMatrix, camera.matrixWorldInverse );
			_frustum.setFromProjectionMatrix( _projScreenMatrix );

			_localClippingEnabled = this.localClippingEnabled;
			_clippingEnabled = clipping.init( this.clippingPlanes, _localClippingEnabled );

			currentRenderList = renderLists.get( scene, renderListStack.length );
			currentRenderList.init();

			renderListStack.push( currentRenderList );

			projectObject( scene, camera, 0, _this.sortObjects );

			currentRenderList.finish();

			if ( _this.sortObjects === true ) {

				currentRenderList.sort( _opaqueSort, _transparentSort );

			}

			const renderBackground = xr.enabled === false || xr.isPresenting === false || xr.hasDepthSensing() === false;
			if ( renderBackground ) {

				background.addToRenderList( currentRenderList, scene );

			}

			//

			this.info.render.frame ++;

			if ( _clippingEnabled === true ) clipping.beginShadows();

			const shadowsArray = currentRenderState.state.shadowsArray;

			shadowMap.render( shadowsArray, scene, camera );

			if ( _clippingEnabled === true ) clipping.endShadows();

			//

			if ( this.info.autoReset === true ) this.info.reset();

			// render scene

			const opaqueObjects = currentRenderList.opaque;
			const transmissiveObjects = currentRenderList.transmissive;

			currentRenderState.setupLights( _this._useLegacyLights );

			if ( camera.isArrayCamera ) {

				const cameras = camera.cameras;

				if ( transmissiveObjects.length > 0 ) {

					for ( let i = 0, l = cameras.length; i < l; i ++ ) {

						const camera2 = cameras[ i ];

						renderTransmissionPass( opaqueObjects, transmissiveObjects, scene, camera2 );

					}

				}

				if ( renderBackground ) background.render( scene );

				for ( let i = 0, l = cameras.length; i < l; i ++ ) {

					const camera2 = cameras[ i ];

					renderScene( currentRenderList, scene, camera2, camera2.viewport );

				}

			} else {

				if ( transmissiveObjects.length > 0 ) renderTransmissionPass( opaqueObjects, transmissiveObjects, scene, camera );

				if ( renderBackground ) background.render( scene );

				renderScene( currentRenderList, scene, camera );

			}

			//

			if ( _currentRenderTarget !== null ) {

				// resolve multisample renderbuffers to a single-sample texture if necessary

				textures.updateMultisampleRenderTarget( _currentRenderTarget );

				// Generate mipmap if we're using any kind of mipmap filtering

				textures.updateRenderTargetMipmap( _currentRenderTarget );

			}

			//

			if ( scene.isScene === true ) scene.onAfterRender( _this, scene, camera );

			// _gl.finish();

			bindingStates.resetDefaultState();
			_currentMaterialId = - 1;
			_currentCamera = null;

			renderStateStack.pop();

			if ( renderStateStack.length > 0 ) {

				currentRenderState = renderStateStack[ renderStateStack.length - 1 ];

				if ( _clippingEnabled === true ) clipping.setGlobalState( _this.clippingPlanes, currentRenderState.state.camera );

			} else {

				currentRenderState = null;

			}

			renderListStack.pop();

			if ( renderListStack.length > 0 ) {

				currentRenderList = renderListStack[ renderListStack.length - 1 ];

			} else {

				currentRenderList = null;

			}

		};

		function projectObject( object, camera, groupOrder, sortObjects ) {

			if ( object.visible === false ) return;

			const visible = object.layers.test( camera.layers );

			if ( visible ) {

				if ( object.isGroup ) {

					groupOrder = object.renderOrder;

				} else if ( object.isLOD ) {

					if ( object.autoUpdate === true ) object.update( camera );

				} else if ( object.isLight ) {

					currentRenderState.pushLight( object );

					if ( object.castShadow ) {

						currentRenderState.pushShadow( object );

					}

				} else if ( object.isSprite ) {

					if ( ! object.frustumCulled || _frustum.intersectsSprite( object ) ) {

						if ( sortObjects ) {

							_vector3.setFromMatrixPosition( object.matrixWorld )
								.applyMatrix4( _projScreenMatrix );

						}

						const geometry = objects.update( object );
						const material = object.material;

						if ( material.visible ) {

							currentRenderList.push( object, geometry, material, groupOrder, _vector3.z, null );

						}

					}

				} else if ( object.isMesh || object.isLine || object.isPoints ) {

					if ( ! object.frustumCulled || _frustum.intersectsObject( object ) ) {

						const geometry = objects.update( object );
						const material = object.material;

						if ( sortObjects ) {

							if ( object.boundingSphere !== undefined ) {

								if ( object.boundingSphere === null ) object.computeBoundingSphere();
								_vector3.copy( object.boundingSphere.center );

							} else {

								if ( geometry.boundingSphere === null ) geometry.computeBoundingSphere();
								_vector3.copy( geometry.boundingSphere.center );

							}

							_vector3
								.applyMatrix4( object.matrixWorld )
								.applyMatrix4( _projScreenMatrix );

						}

						if ( Array.isArray( material ) ) {

							const groups = geometry.groups;

							for ( let i = 0, l = groups.length; i < l; i ++ ) {

								const group = groups[ i ];
								const groupMaterial = material[ group.materialIndex ];

								if ( groupMaterial && groupMaterial.visible ) {

									currentRenderList.push( object, geometry, groupMaterial, groupOrder, _vector3.z, group );

								}

							}

						} else if ( material.visible ) {

							currentRenderList.push( object, geometry, material, groupOrder, _vector3.z, null );

						}

					}

				}

			}

			const children = object.children;

			for ( let i = 0, l = children.length; i < l; i ++ ) {

				projectObject( children[ i ], camera, groupOrder, sortObjects );

			}

		}

		function renderScene( currentRenderList, scene, camera, viewport ) {

			const opaqueObjects = currentRenderList.opaque;
			const transmissiveObjects = currentRenderList.transmissive;
			const transparentObjects = currentRenderList.transparent;

			currentRenderState.setupLightsView( camera );

			if ( _clippingEnabled === true ) clipping.setGlobalState( _this.clippingPlanes, camera );

			if ( viewport ) state.viewport( _currentViewport.copy( viewport ) );

			if ( opaqueObjects.length > 0 ) renderObjects( opaqueObjects, scene, camera );
			if ( transmissiveObjects.length > 0 ) renderObjects( transmissiveObjects, scene, camera );
			if ( transparentObjects.length > 0 ) renderObjects( transparentObjects, scene, camera );

			// Ensure depth buffer writing is enabled so it can be cleared on next render

			state.buffers.depth.setTest( true );
			state.buffers.depth.setMask( true );
			state.buffers.color.setMask( true );

			state.setPolygonOffset( false );

		}

		function renderTransmissionPass( opaqueObjects, transmissiveObjects, scene, camera ) {

			const overrideMaterial = scene.isScene === true ? scene.overrideMaterial : null;

			if ( overrideMaterial !== null ) {

				return;

			}

			if ( currentRenderState.state.transmissionRenderTarget[ camera.id ] === undefined ) {

				currentRenderState.state.transmissionRenderTarget[ camera.id ] = new WebGLRenderTarget( 1, 1, {
					generateMipmaps: true,
					type: ( extensions.has( 'EXT_color_buffer_half_float' ) || extensions.has( 'EXT_color_buffer_float' ) ) ? HalfFloatType : UnsignedByteType,
					minFilter: LinearMipmapLinearFilter,
					samples: 4,
					stencilBuffer: stencil,
					resolveDepthBuffer: false,
					resolveStencilBuffer: false
				} );

				// debug

				/*
				const geometry = new PlaneGeometry();
				const material = new MeshBasicMaterial( { map: _transmissionRenderTarget.texture } );

				const mesh = new Mesh( geometry, material );
				scene.add( mesh );
				*/

			}

			const transmissionRenderTarget = currentRenderState.state.transmissionRenderTarget[ camera.id ];

			const activeViewport = camera.viewport || _currentViewport;
			transmissionRenderTarget.setSize( activeViewport.z, activeViewport.w );

			//

			const currentRenderTarget = _this.getRenderTarget();
			_this.setRenderTarget( transmissionRenderTarget );

			_this.getClearColor( _currentClearColor );
			_currentClearAlpha = _this.getClearAlpha();
			if ( _currentClearAlpha < 1 ) _this.setClearColor( 0xffffff, 0.5 );

			_this.clear();

			// Turn off the features which can affect the frag color for opaque objects pass.
			// Otherwise they are applied twice in opaque objects pass and transmission objects pass.
			const currentToneMapping = _this.toneMapping;
			_this.toneMapping = NoToneMapping;

			// Remove viewport from camera to avoid nested render calls resetting viewport to it (e.g Reflector).
			// Transmission render pass requires viewport to match the transmissionRenderTarget.
			const currentCameraViewport = camera.viewport;
			if ( camera.viewport !== undefined ) camera.viewport = undefined;

			currentRenderState.setupLightsView( camera );

			if ( _clippingEnabled === true ) clipping.setGlobalState( _this.clippingPlanes, camera );

			renderObjects( opaqueObjects, scene, camera );

			textures.updateMultisampleRenderTarget( transmissionRenderTarget );
			textures.updateRenderTargetMipmap( transmissionRenderTarget );

			if ( extensions.has( 'WEBGL_multisampled_render_to_texture' ) === false ) { // see #28131

				let renderTargetNeedsUpdate = false;

				for ( let i = 0, l = transmissiveObjects.length; i < l; i ++ ) {

					const renderItem = transmissiveObjects[ i ];

					const object = renderItem.object;
					const geometry = renderItem.geometry;
					const material = renderItem.material;
					const group = renderItem.group;

					if ( material.side === DoubleSide && object.layers.test( camera.layers ) ) {

						const currentSide = material.side;

						material.side = BackSide;
						material.needsUpdate = true;

						renderObject( object, scene, camera, geometry, material, group );

						material.side = currentSide;
						material.needsUpdate = true;

						renderTargetNeedsUpdate = true;

					}

				}

				if ( renderTargetNeedsUpdate === true ) {

					textures.updateMultisampleRenderTarget( transmissionRenderTarget );
					textures.updateRenderTargetMipmap( transmissionRenderTarget );

				}

			}

			_this.setRenderTarget( currentRenderTarget );

			_this.setClearColor( _currentClearColor, _currentClearAlpha );

			if ( currentCameraViewport !== undefined ) camera.viewport = currentCameraViewport;

			_this.toneMapping = currentToneMapping;

		}

		function renderObjects( renderList, scene, camera ) {

			const overrideMaterial = scene.isScene === true ? scene.overrideMaterial : null;

			for ( let i = 0, l = renderList.length; i < l; i ++ ) {

				const renderItem = renderList[ i ];

				const object = renderItem.object;
				const geometry = renderItem.geometry;
				const material = overrideMaterial === null ? renderItem.material : overrideMaterial;
				const group = renderItem.group;

				if ( object.layers.test( camera.layers ) ) {

					renderObject( object, scene, camera, geometry, material, group );

				}

			}

		}

