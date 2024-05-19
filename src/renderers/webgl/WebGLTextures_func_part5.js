	function uploadTexture( textureProperties, texture, slot ) {

		let textureType = _gl.TEXTURE_2D;

		if ( texture.isDataArrayTexture || texture.isCompressedArrayTexture ) textureType = _gl.TEXTURE_2D_ARRAY;
		if ( texture.isData3DTexture ) textureType = _gl.TEXTURE_3D;

		const forceUpload = initTexture( textureProperties, texture );
		const source = texture.source;

		state.bindTexture( textureType, textureProperties.__webglTexture, _gl.TEXTURE0 + slot );

		const sourceProperties = properties.get( source );

		if ( source.version !== sourceProperties.__version || forceUpload === true ) {

			state.activeTexture( _gl.TEXTURE0 + slot );

			const workingPrimaries = ColorManagement.getPrimaries( ColorManagement.workingColorSpace );
			const texturePrimaries = texture.colorSpace === NoColorSpace ? null : ColorManagement.getPrimaries( texture.colorSpace );
			const unpackConversion = texture.colorSpace === NoColorSpace || workingPrimaries === texturePrimaries ? _gl.NONE : _gl.BROWSER_DEFAULT_WEBGL;

			_gl.pixelStorei( _gl.UNPACK_FLIP_Y_WEBGL, texture.flipY );
			_gl.pixelStorei( _gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha );
			_gl.pixelStorei( _gl.UNPACK_ALIGNMENT, texture.unpackAlignment );
			_gl.pixelStorei( _gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, unpackConversion );

			let image = resizeImage( texture.image, false, capabilities.maxTextureSize );
			image = verifyColorSpace( texture, image );

			const glFormat = utils.convert( texture.format, texture.colorSpace );

			const glType = utils.convert( texture.type );
			let glInternalFormat = getInternalFormat( texture.internalFormat, glFormat, glType, texture.colorSpace, texture.isVideoTexture );

			setTextureParameters( textureType, texture );

			let mipmap;
			const mipmaps = texture.mipmaps;

			const useTexStorage = ( texture.isVideoTexture !== true );
			const allocateMemory = ( sourceProperties.__version === undefined ) || ( forceUpload === true );
			const dataReady = source.dataReady;
			const levels = getMipLevels( texture, image );

			if ( texture.isDepthTexture ) {

				// populate depth texture with dummy data

				glInternalFormat = _gl.DEPTH_COMPONENT16;

				if ( texture.type === FloatType ) {

					glInternalFormat = _gl.DEPTH_COMPONENT32F;

				} else if ( texture.type === UnsignedIntType ) {

					glInternalFormat = _gl.DEPTH_COMPONENT24;

				} else if ( texture.type === UnsignedInt248Type ) {

					glInternalFormat = _gl.DEPTH24_STENCIL8;

				}

				//

				if ( allocateMemory ) {

					if ( useTexStorage ) {

						state.texStorage2D( _gl.TEXTURE_2D, 1, glInternalFormat, image.width, image.height );

					} else {

						state.texImage2D( _gl.TEXTURE_2D, 0, glInternalFormat, image.width, image.height, 0, glFormat, glType, null );

					}

				}

			} else if ( texture.isDataTexture ) {

				// use manually created mipmaps if available
				// if there are no manual mipmaps
				// set 0 level mipmap and then use GL to generate other mipmap levels

				if ( mipmaps.length > 0 ) {

					if ( useTexStorage && allocateMemory ) {

						state.texStorage2D( _gl.TEXTURE_2D, levels, glInternalFormat, mipmaps[ 0 ].width, mipmaps[ 0 ].height );

					}

					for ( let i = 0, il = mipmaps.length; i < il; i ++ ) {

						mipmap = mipmaps[ i ];

						if ( useTexStorage ) {

							if ( dataReady ) {

								state.texSubImage2D( _gl.TEXTURE_2D, i, 0, 0, mipmap.width, mipmap.height, glFormat, glType, mipmap.data );

							}

						} else {

							state.texImage2D( _gl.TEXTURE_2D, i, glInternalFormat, mipmap.width, mipmap.height, 0, glFormat, glType, mipmap.data );

						}

					}

					texture.generateMipmaps = false;

				} else {

					if ( useTexStorage ) {

						if ( allocateMemory ) {

							state.texStorage2D( _gl.TEXTURE_2D, levels, glInternalFormat, image.width, image.height );

						}

						if ( dataReady ) {

							state.texSubImage2D( _gl.TEXTURE_2D, 0, 0, 0, image.width, image.height, glFormat, glType, image.data );

						}

					} else {

						state.texImage2D( _gl.TEXTURE_2D, 0, glInternalFormat, image.width, image.height, 0, glFormat, glType, image.data );

					}

				}

			} else if ( texture.isCompressedTexture ) {

				if ( texture.isCompressedArrayTexture ) {

					if ( useTexStorage && allocateMemory ) {

						state.texStorage3D( _gl.TEXTURE_2D_ARRAY, levels, glInternalFormat, mipmaps[ 0 ].width, mipmaps[ 0 ].height, image.depth );

					}

					for ( let i = 0, il = mipmaps.length; i < il; i ++ ) {

						mipmap = mipmaps[ i ];

						if ( texture.format !== RGBAFormat ) {

							if ( glFormat !== null ) {

								if ( useTexStorage ) {

									if ( dataReady ) {

										if ( texture.layerUpdates.size > 0 ) {

											for ( const layerIndex of texture.layerUpdates ) {

												const layerSize = mipmap.width * mipmap.height;
												state.compressedTexSubImage3D( _gl.TEXTURE_2D_ARRAY, i, 0, 0, layerIndex, mipmap.width, mipmap.height, 1, glFormat, mipmap.data.slice( layerSize * layerIndex, layerSize * ( layerIndex + 1 ) ), 0, 0 );

											}

											texture.clearLayerUpdates();

										} else {

											state.compressedTexSubImage3D( _gl.TEXTURE_2D_ARRAY, i, 0, 0, 0, mipmap.width, mipmap.height, image.depth, glFormat, mipmap.data, 0, 0 );

										}

									}

								} else {

									state.compressedTexImage3D( _gl.TEXTURE_2D_ARRAY, i, glInternalFormat, mipmap.width, mipmap.height, image.depth, 0, mipmap.data, 0, 0 );

								}

							} else {

								console.warn( 'THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()' );

							}

						} else {

							if ( useTexStorage ) {

								if ( dataReady ) {

									state.texSubImage3D( _gl.TEXTURE_2D_ARRAY, i, 0, 0, 0, mipmap.width, mipmap.height, image.depth, glFormat, glType, mipmap.data );

								}

							} else {

								state.texImage3D( _gl.TEXTURE_2D_ARRAY, i, glInternalFormat, mipmap.width, mipmap.height, image.depth, 0, glFormat, glType, mipmap.data );

							}

						}

					}

				} else {

					if ( useTexStorage && allocateMemory ) {

						state.texStorage2D( _gl.TEXTURE_2D, levels, glInternalFormat, mipmaps[ 0 ].width, mipmaps[ 0 ].height );

					}

					for ( let i = 0, il = mipmaps.length; i < il; i ++ ) {

						mipmap = mipmaps[ i ];

						if ( texture.format !== RGBAFormat ) {

							if ( glFormat !== null ) {

								if ( useTexStorage ) {

									if ( dataReady ) {

										state.compressedTexSubImage2D( _gl.TEXTURE_2D, i, 0, 0, mipmap.width, mipmap.height, glFormat, mipmap.data );

									}

								} else {

									state.compressedTexImage2D( _gl.TEXTURE_2D, i, glInternalFormat, mipmap.width, mipmap.height, 0, mipmap.data );

								}

							} else {

								console.warn( 'THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()' );

							}

						} else {

							if ( useTexStorage ) {

								if ( dataReady ) {

									state.texSubImage2D( _gl.TEXTURE_2D, i, 0, 0, mipmap.width, mipmap.height, glFormat, glType, mipmap.data );

								}

							} else {

								state.texImage2D( _gl.TEXTURE_2D, i, glInternalFormat, mipmap.width, mipmap.height, 0, glFormat, glType, mipmap.data );

							}

						}

					}

				}

			} else if ( texture.isDataArrayTexture ) {

				if ( useTexStorage ) {

					if ( allocateMemory ) {

						state.texStorage3D( _gl.TEXTURE_2D_ARRAY, levels, glInternalFormat, image.width, image.height, image.depth );

					}

					if ( dataReady ) {

						if ( texture.layerUpdates.size > 0 ) {

							// When type is GL_UNSIGNED_BYTE, each of these bytes is
							// interpreted as one color component, depending on format. When
							// type is one of GL_UNSIGNED_SHORT_5_6_5,
							// GL_UNSIGNED_SHORT_4_4_4_4, GL_UNSIGNED_SHORT_5_5_5_1, each
							// unsigned value is interpreted as containing all the components
							// for a single pixel, with the color components arranged
							// according to format.
							//
							// See https://registry.khronos.org/OpenGL-Refpages/es1.1/xhtml/glTexImage2D.xml
							let texelSize;
							switch ( glType ) {

								case _gl.UNSIGNED_BYTE:
									switch ( glFormat ) {

										case _gl.ALPHA:
											texelSize = 1;
											break;
										case _gl.LUMINANCE:
											texelSize = 1;
											break;
										case _gl.LUMINANCE_ALPHA:
											texelSize = 2;
											break;
										case _gl.RGB:
											texelSize = 3;
											break;
										case _gl.RGBA:
											texelSize = 4;
											break;

										default:
											throw new Error( `Unknown texel size for format ${glFormat}.` );

									}

									break;

								case _gl.UNSIGNED_SHORT_4_4_4_4:
								case _gl.UNSIGNED_SHORT_5_5_5_1:
								case _gl.UNSIGNED_SHORT_5_6_5:
									texelSize = 1;
									break;

								default:
									throw new Error( `Unknown texel size for type ${glType}.` );

							}

							const layerSize = image.width * image.height * texelSize;

							for ( const layerIndex of texture.layerUpdates ) {

								state.texSubImage3D( _gl.TEXTURE_2D_ARRAY, 0, 0, 0, layerIndex, image.width, image.height, 1, glFormat, glType, image.data.slice( layerSize * layerIndex, layerSize * ( layerIndex + 1 ) ) );

							}

							texture.clearLayerUpdates();

						} else {

							state.texSubImage3D( _gl.TEXTURE_2D_ARRAY, 0, 0, 0, 0, image.width, image.height, image.depth, glFormat, glType, image.data );

						}

					}

				} else {

					state.texImage3D( _gl.TEXTURE_2D_ARRAY, 0, glInternalFormat, image.width, image.height, image.depth, 0, glFormat, glType, image.data );

				}

			} else if ( texture.isData3DTexture ) {

				if ( useTexStorage ) {

					if ( allocateMemory ) {

						state.texStorage3D( _gl.TEXTURE_3D, levels, glInternalFormat, image.width, image.height, image.depth );

					}

					if ( dataReady ) {

						state.texSubImage3D( _gl.TEXTURE_3D, 0, 0, 0, 0, image.width, image.height, image.depth, glFormat, glType, image.data );

					}

				} else {

					state.texImage3D( _gl.TEXTURE_3D, 0, glInternalFormat, image.width, image.height, image.depth, 0, glFormat, glType, image.data );

				}

			} else if ( texture.isFramebufferTexture ) {

				if ( allocateMemory ) {

					if ( useTexStorage ) {

						state.texStorage2D( _gl.TEXTURE_2D, levels, glInternalFormat, image.width, image.height );

					} else {

						let width = image.width, height = image.height;

						for ( let i = 0; i < levels; i ++ ) {

							state.texImage2D( _gl.TEXTURE_2D, i, glInternalFormat, width, height, 0, glFormat, glType, null );

							width >>= 1;
							height >>= 1;

						}

					}

				}

			} else {

				// regular Texture (image, video, canvas)

				// use manually created mipmaps if available
				// if there are no manual mipmaps
				// set 0 level mipmap and then use GL to generate other mipmap levels

				if ( mipmaps.length > 0 ) {

					if ( useTexStorage && allocateMemory ) {

						const dimensions = getDimensions( mipmaps[ 0 ] );

						state.texStorage2D( _gl.TEXTURE_2D, levels, glInternalFormat, dimensions.width, dimensions.height );

					}

					for ( let i = 0, il = mipmaps.length; i < il; i ++ ) {

						mipmap = mipmaps[ i ];

						if ( useTexStorage ) {

							if ( dataReady ) {

								state.texSubImage2D( _gl.TEXTURE_2D, i, 0, 0, glFormat, glType, mipmap );

							}

						} else {

							state.texImage2D( _gl.TEXTURE_2D, i, glInternalFormat, glFormat, glType, mipmap );

						}

					}

					texture.generateMipmaps = false;

				} else {

					if ( useTexStorage ) {

						if ( allocateMemory ) {

							const dimensions = getDimensions( image );

							state.texStorage2D( _gl.TEXTURE_2D, levels, glInternalFormat, dimensions.width, dimensions.height );

						}

						if ( dataReady ) {

							state.texSubImage2D( _gl.TEXTURE_2D, 0, 0, 0, glFormat, glType, image );

						}

					} else {

						state.texImage2D( _gl.TEXTURE_2D, 0, glInternalFormat, glFormat, glType, image );

					}

				}

			}

			if ( textureNeedsGenerateMipmaps( texture ) ) {

				generateMipmap( textureType );

			}

			sourceProperties.__version = source.version;

			if ( texture.onUpdate ) texture.onUpdate( texture );

		}

		textureProperties.__version = texture.version;

	}