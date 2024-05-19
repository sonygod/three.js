	function setupRenderTarget( renderTarget ) {

		const texture = renderTarget.texture;

		const renderTargetProperties = properties.get( renderTarget );
		const textureProperties = properties.get( texture );

		renderTarget.addEventListener( 'dispose', onRenderTargetDispose );

		const textures = renderTarget.textures;

		const isCube = ( renderTarget.isWebGLCubeRenderTarget === true );
		const isMultipleRenderTargets = ( textures.length > 1 );

		if ( ! isMultipleRenderTargets ) {

			if ( textureProperties.__webglTexture === undefined ) {

				textureProperties.__webglTexture = _gl.createTexture();

			}

			textureProperties.__version = texture.version;
			info.memory.textures ++;

		}

		// Setup framebuffer

		if ( isCube ) {

			renderTargetProperties.__webglFramebuffer = [];

			for ( let i = 0; i < 6; i ++ ) {

				if ( texture.mipmaps && texture.mipmaps.length > 0 ) {

					renderTargetProperties.__webglFramebuffer[ i ] = [];

					for ( let level = 0; level < texture.mipmaps.length; level ++ ) {

						renderTargetProperties.__webglFramebuffer[ i ][ level ] = _gl.createFramebuffer();

					}

				} else {

					renderTargetProperties.__webglFramebuffer[ i ] = _gl.createFramebuffer();

				}

			}

		} else {

			if ( texture.mipmaps && texture.mipmaps.length > 0 ) {

				renderTargetProperties.__webglFramebuffer = [];

				for ( let level = 0; level < texture.mipmaps.length; level ++ ) {

					renderTargetProperties.__webglFramebuffer[ level ] = _gl.createFramebuffer();

				}

			} else {

				renderTargetProperties.__webglFramebuffer = _gl.createFramebuffer();

			}

			if ( isMultipleRenderTargets ) {

				for ( let i = 0, il = textures.length; i < il; i ++ ) {

					const attachmentProperties = properties.get( textures[ i ] );

					if ( attachmentProperties.__webglTexture === undefined ) {

						attachmentProperties.__webglTexture = _gl.createTexture();

						info.memory.textures ++;

					}

				}

			}

			if ( ( renderTarget.samples > 0 ) && useMultisampledRTT( renderTarget ) === false ) {

				renderTargetProperties.__webglMultisampledFramebuffer = _gl.createFramebuffer();
				renderTargetProperties.__webglColorRenderbuffer = [];

				state.bindFramebuffer( _gl.FRAMEBUFFER, renderTargetProperties.__webglMultisampledFramebuffer );

				for ( let i = 0; i < textures.length; i ++ ) {

					const texture = textures[ i ];
					renderTargetProperties.__webglColorRenderbuffer[ i ] = _gl.createRenderbuffer();

					_gl.bindRenderbuffer( _gl.RENDERBUFFER, renderTargetProperties.__webglColorRenderbuffer[ i ] );

					const glFormat = utils.convert( texture.format, texture.colorSpace );
					const glType = utils.convert( texture.type );
					const glInternalFormat = getInternalFormat( texture.internalFormat, glFormat, glType, texture.colorSpace, renderTarget.isXRRenderTarget === true );
					const samples = getRenderTargetSamples( renderTarget );
					_gl.renderbufferStorageMultisample( _gl.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height );

					_gl.framebufferRenderbuffer( _gl.FRAMEBUFFER, _gl.COLOR_ATTACHMENT0 + i, _gl.RENDERBUFFER, renderTargetProperties.__webglColorRenderbuffer[ i ] );

				}

				_gl.bindRenderbuffer( _gl.RENDERBUFFER, null );

				if ( renderTarget.depthBuffer ) {

					renderTargetProperties.__webglDepthRenderbuffer = _gl.createRenderbuffer();
					setupRenderBufferStorage( renderTargetProperties.__webglDepthRenderbuffer, renderTarget, true );

				}

				state.bindFramebuffer( _gl.FRAMEBUFFER, null );

			}

		}

		// Setup color buffer

		if ( isCube ) {

			state.bindTexture( _gl.TEXTURE_CUBE_MAP, textureProperties.__webglTexture );
			setTextureParameters( _gl.TEXTURE_CUBE_MAP, texture );

			for ( let i = 0; i < 6; i ++ ) {

				if ( texture.mipmaps && texture.mipmaps.length > 0 ) {

					for ( let level = 0; level < texture.mipmaps.length; level ++ ) {

						setupFrameBufferTexture( renderTargetProperties.__webglFramebuffer[ i ][ level ], renderTarget, texture, _gl.COLOR_ATTACHMENT0, _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, level );

					}

				} else {

					setupFrameBufferTexture( renderTargetProperties.__webglFramebuffer[ i ], renderTarget, texture, _gl.COLOR_ATTACHMENT0, _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0 );

				}

			}

			if ( textureNeedsGenerateMipmaps( texture ) ) {

				generateMipmap( _gl.TEXTURE_CUBE_MAP );

			}

			state.unbindTexture();

		} else if ( isMultipleRenderTargets ) {

			for ( let i = 0, il = textures.length; i < il; i ++ ) {

				const attachment = textures[ i ];
				const attachmentProperties = properties.get( attachment );

				state.bindTexture( _gl.TEXTURE_2D, attachmentProperties.__webglTexture );
				setTextureParameters( _gl.TEXTURE_2D, attachment );
				setupFrameBufferTexture( renderTargetProperties.__webglFramebuffer, renderTarget, attachment, _gl.COLOR_ATTACHMENT0 + i, _gl.TEXTURE_2D, 0 );

				if ( textureNeedsGenerateMipmaps( attachment ) ) {

					generateMipmap( _gl.TEXTURE_2D );

				}

			}

			state.unbindTexture();

		} else {

			let glTextureType = _gl.TEXTURE_2D;

			if ( renderTarget.isWebGL3DRenderTarget || renderTarget.isWebGLArrayRenderTarget ) {

				glTextureType = renderTarget.isWebGL3DRenderTarget ? _gl.TEXTURE_3D : _gl.TEXTURE_2D_ARRAY;

			}

			state.bindTexture( glTextureType, textureProperties.__webglTexture );
			setTextureParameters( glTextureType, texture );

			if ( texture.mipmaps && texture.mipmaps.length > 0 ) {

				for ( let level = 0; level < texture.mipmaps.length; level ++ ) {

					setupFrameBufferTexture( renderTargetProperties.__webglFramebuffer[ level ], renderTarget, texture, _gl.COLOR_ATTACHMENT0, glTextureType, level );

				}

			} else {

				setupFrameBufferTexture( renderTargetProperties.__webglFramebuffer, renderTarget, texture, _gl.COLOR_ATTACHMENT0, glTextureType, 0 );

			}

			if ( textureNeedsGenerateMipmaps( texture ) ) {

				generateMipmap( glTextureType );

			}

			state.unbindTexture();

		}

		// Setup depth and stencil buffers

		if ( renderTarget.depthBuffer ) {

			setupDepthRenderbuffer( renderTarget );

		}

	}

	function updateRenderTargetMipmap( renderTarget ) {

		const textures = renderTarget.textures;

		for ( let i = 0, il = textures.length; i < il; i ++ ) {

			const texture = textures[ i ];

			if ( textureNeedsGenerateMipmaps( texture ) ) {

				const target = renderTarget.isWebGLCubeRenderTarget ? _gl.TEXTURE_CUBE_MAP : _gl.TEXTURE_2D;
				const webglTexture = properties.get( texture ).__webglTexture;

				state.bindTexture( target, webglTexture );
				generateMipmap( target );
				state.unbindTexture();

			}

		}

	}

	const invalidationArrayRead = [];
	const invalidationArrayDraw = [];

	function updateMultisampleRenderTarget( renderTarget ) {

		if ( renderTarget.samples > 0 ) {

			if ( useMultisampledRTT( renderTarget ) === false ) {

				const textures = renderTarget.textures;
				const width = renderTarget.width;
				const height = renderTarget.height;
				let mask = _gl.COLOR_BUFFER_BIT;
				const depthStyle = renderTarget.stencilBuffer ? _gl.DEPTH_STENCIL_ATTACHMENT : _gl.DEPTH_ATTACHMENT;
				const renderTargetProperties = properties.get( renderTarget );
				const isMultipleRenderTargets = ( textures.length > 1 );

				// If MRT we need to remove FBO attachments
				if ( isMultipleRenderTargets ) {

					for ( let i = 0; i < textures.length; i ++ ) {

						state.bindFramebuffer( _gl.FRAMEBUFFER, renderTargetProperties.__webglMultisampledFramebuffer );
						_gl.framebufferRenderbuffer( _gl.FRAMEBUFFER, _gl.COLOR_ATTACHMENT0 + i, _gl.RENDERBUFFER, null );

						state.bindFramebuffer( _gl.FRAMEBUFFER, renderTargetProperties.__webglFramebuffer );
						_gl.framebufferTexture2D( _gl.DRAW_FRAMEBUFFER, _gl.COLOR_ATTACHMENT0 + i, _gl.TEXTURE_2D, null, 0 );

					}

				}

				state.bindFramebuffer( _gl.READ_FRAMEBUFFER, renderTargetProperties.__webglMultisampledFramebuffer );
				state.bindFramebuffer( _gl.DRAW_FRAMEBUFFER, renderTargetProperties.__webglFramebuffer );

				for ( let i = 0; i < textures.length; i ++ ) {

					if ( renderTarget.resolveDepthBuffer ) {

						if ( renderTarget.depthBuffer ) mask |= _gl.DEPTH_BUFFER_BIT;

						// resolving stencil is slow with a D3D backend. disable it for all transmission render targets (see #27799)

						if ( renderTarget.stencilBuffer && renderTarget.resolveStencilBuffer ) mask |= _gl.STENCIL_BUFFER_BIT;

					}

					if ( isMultipleRenderTargets ) {

						_gl.framebufferRenderbuffer( _gl.READ_FRAMEBUFFER, _gl.COLOR_ATTACHMENT0, _gl.RENDERBUFFER, renderTargetProperties.__webglColorRenderbuffer[ i ] );

						const webglTexture = properties.get( textures[ i ] ).__webglTexture;
						_gl.framebufferTexture2D( _gl.DRAW_FRAMEBUFFER, _gl.COLOR_ATTACHMENT0, _gl.TEXTURE_2D, webglTexture, 0 );

					}

					_gl.blitFramebuffer( 0, 0, width, height, 0, 0, width, height, mask, _gl.NEAREST );

					if ( supportsInvalidateFramebuffer === true ) {

						invalidationArrayRead.length = 0;
						invalidationArrayDraw.length = 0;

						invalidationArrayRead.push( _gl.COLOR_ATTACHMENT0 + i );

						if ( renderTarget.depthBuffer && renderTarget.resolveDepthBuffer === false ) {

							invalidationArrayRead.push( depthStyle );
							invalidationArrayDraw.push( depthStyle );

							_gl.invalidateFramebuffer( _gl.DRAW_FRAMEBUFFER, invalidationArrayDraw );

						}

						_gl.invalidateFramebuffer( _gl.READ_FRAMEBUFFER, invalidationArrayRead );

					}

				}

				state.bindFramebuffer( _gl.READ_FRAMEBUFFER, null );
				state.bindFramebuffer( _gl.DRAW_FRAMEBUFFER, null );

				// If MRT since pre-blit we removed the FBO we need to reconstruct the attachments
				if ( isMultipleRenderTargets ) {

					for ( let i = 0; i < textures.length; i ++ ) {

						state.bindFramebuffer( _gl.FRAMEBUFFER, renderTargetProperties.__webglMultisampledFramebuffer );
						_gl.framebufferRenderbuffer( _gl.FRAMEBUFFER, _gl.COLOR_ATTACHMENT0 + i, _gl.RENDERBUFFER, renderTargetProperties.__webglColorRenderbuffer[ i ] );

						const webglTexture = properties.get( textures[ i ] ).__webglTexture;

						state.bindFramebuffer( _gl.FRAMEBUFFER, renderTargetProperties.__webglFramebuffer );
						_gl.framebufferTexture2D( _gl.DRAW_FRAMEBUFFER, _gl.COLOR_ATTACHMENT0 + i, _gl.TEXTURE_2D, webglTexture, 0 );

					}

				}

				state.bindFramebuffer( _gl.DRAW_FRAMEBUFFER, renderTargetProperties.__webglMultisampledFramebuffer );

			} else {

				if ( renderTarget.depthBuffer && renderTarget.resolveDepthBuffer === false && supportsInvalidateFramebuffer ) {

					const depthStyle = renderTarget.stencilBuffer ? _gl.DEPTH_STENCIL_ATTACHMENT : _gl.DEPTH_ATTACHMENT;

					_gl.invalidateFramebuffer( _gl.DRAW_FRAMEBUFFER, [ depthStyle ] );

				}

			}

		}

	}

	function getRenderTargetSamples( renderTarget ) {

		return Math.min( capabilities.maxSamples, renderTarget.samples );

	}

	function useMultisampledRTT( renderTarget ) {

		const renderTargetProperties = properties.get( renderTarget );

		return renderTarget.samples > 0 && extensions.has( 'WEBGL_multisampled_render_to_texture' ) === true && renderTargetProperties.__useRenderToTexture !== false;

	}

	function updateVideoTexture( texture ) {

		const frame = info.render.frame;

		// Check the last frame we updated the VideoTexture

		if ( _videoTextures.get( texture ) !== frame ) {

			_videoTextures.set( texture, frame );
			texture.update();

		}

	}

	function verifyColorSpace( texture, image ) {

		const colorSpace = texture.colorSpace;
		const format = texture.format;
		const type = texture.type;

		if ( texture.isCompressedTexture === true || texture.isVideoTexture === true ) return image;

		if ( colorSpace !== LinearSRGBColorSpace && colorSpace !== NoColorSpace ) {

			// sRGB

			if ( ColorManagement.getTransfer( colorSpace ) === SRGBTransfer ) {

				// in WebGL 2 uncompressed textures can only be sRGB encoded if they have the RGBA8 format

				if ( format !== RGBAFormat || type !== UnsignedByteType ) {

					console.warn( 'THREE.WebGLTextures: sRGB encoded textures have to use RGBAFormat and UnsignedByteType.' );

				}

			} else {

				console.error( 'THREE.WebGLTextures: Unsupported texture color space:', colorSpace );

			}

		}

		return image;

	}

	function getDimensions( image ) {

		if ( typeof HTMLImageElement !== 'undefined' && image instanceof HTMLImageElement ) {

			// if intrinsic data are not available, fallback to width/height

			_imageDimensions.width = image.naturalWidth || image.width;
			_imageDimensions.height = image.naturalHeight || image.height;

		} else if ( typeof VideoFrame !== 'undefined' && image instanceof VideoFrame ) {

			_imageDimensions.width = image.displayWidth;
			_imageDimensions.height = image.displayHeight;

		} else {

			_imageDimensions.width = image.width;
			_imageDimensions.height = image.height;

		}

		return _imageDimensions;

	}