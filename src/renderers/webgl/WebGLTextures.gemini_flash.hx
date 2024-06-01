import three.constants.*;
import three.utils.Utils;
import three.math.ColorManagement;
import three.math.Vector2;

class WebGLTextures {
	var _gl: WebGLRenderingContext;
	var _extensions: Map<String,Dynamic>;
	var _state: WebGLState;
	var _properties: Map<Dynamic,Dynamic>;
	var _capabilities: WebGLCapabilities;
	var _utils: Utils;
	var _info: WebGLInfo;
	var multisampledRTTExt: Dynamic;
	var supportsInvalidateFramebuffer: Bool;
	var _imageDimensions: Vector2;
	var _videoTextures: WeakMap<Dynamic,Int>;
	var _canvas: Dynamic;
	var _sources: WeakMap<Dynamic,Dynamic>;
	var useOffscreenCanvas: Bool;
	var textureUnits: Int;

	public function new(gl: WebGLRenderingContext, extensions: Map<String,Dynamic>, state: WebGLState, properties: Map<Dynamic,Dynamic>, capabilities: WebGLCapabilities, utils: Utils, info: WebGLInfo) {
		this._gl = gl;
		this._extensions = extensions;
		this._state = state;
		this._properties = properties;
		this._capabilities = capabilities;
		this._utils = utils;
		this._info = info;

		multisampledRTTExt = extensions.exists("WEBGL_multisampled_render_to_texture") ? extensions.get("WEBGL_multisampled_render_to_texture") : null;
		supportsInvalidateFramebuffer = typeof navigator != 'undefined' ? /OculusBrowser/g.test(navigator.userAgent) : false;

		_imageDimensions = new Vector2();
		_videoTextures = new WeakMap();
		_canvas = null;
		_sources = new WeakMap();

		useOffscreenCanvas = typeof OffscreenCanvas != 'undefined' && (new OffscreenCanvas(1, 1)).getContext('2d') != null;

		textureUnits = 0;
	}

	function createCanvas(width: Int, height: Int): Dynamic {
		return useOffscreenCanvas ? new OffscreenCanvas(width, height) : Utils.createElementNS("canvas");
	}

	function resizeImage(image: Dynamic, needsNewCanvas: Bool, maxSize: Int): Dynamic {
		var scale = 1;
		var dimensions = getDimensions(image);

		if (dimensions.width > maxSize || dimensions.height > maxSize) {
			scale = maxSize / Math.max(dimensions.width, dimensions.height);
		}

		if (scale < 1) {
			if ((typeof HTMLImageElement != 'undefined' && Std.is(image, HTMLImageElement)) ||
				(typeof HTMLCanvasElement != 'undefined' && Std.is(image, HTMLCanvasElement)) ||
				(typeof ImageBitmap != 'undefined' && Std.is(image, ImageBitmap)) ||
				(typeof VideoFrame != 'undefined' && Std.is(image, VideoFrame))) {

				var width = Math.floor(scale * dimensions.width);
				var height = Math.floor(scale * dimensions.height);

				if (_canvas == null) _canvas = createCanvas(width, height);
				var canvas = needsNewCanvas ? createCanvas(width, height) : _canvas;
				canvas.width = width;
				canvas.height = height;
				var context = canvas.getContext('2d');
				context.drawImage(image, 0, 0, width, height);

				console.warn('THREE.WebGLRenderer: Texture has been resized from (' + dimensions.width + 'x' + dimensions.height + ') to (' + width + 'x' + height + ').');

				return canvas;
			} else if ('data' in image) {
				console.warn('THREE.WebGLRenderer: Image in DataTexture is too big (' + dimensions.width + 'x' + dimensions.height + ').');
			}
			return image;
		}
		return image;
	}

	function textureNeedsGenerateMipmaps(texture: Dynamic): Bool {
		return texture.generateMipmaps && texture.minFilter != NearestFilter && texture.minFilter != LinearFilter;
	}

	function generateMipmap(target: Int) {
		_gl.generateMipmap(target);
	}

	function getInternalFormat(internalFormatName: String, glFormat: Int, glType: Int, colorSpace: String, forceLinearTransfer: Bool = false): Int {
		if (internalFormatName != null && _gl[internalFormatName] != null) {
			return cast _gl[internalFormatName];
		} else if (internalFormatName != null) {
			console.warn('THREE.WebGLRenderer: Attempt to use non-existing WebGL internal format \'' + internalFormatName + '\'');
		}
		var internalFormat = glFormat;
		if (glFormat == _gl.RED) {
			if (glType == _gl.FLOAT) internalFormat = _gl.R32F;
			else if (glType == _gl.HALF_FLOAT) internalFormat = _gl.R16F;
			else if (glType == _gl.UNSIGNED_BYTE) internalFormat = _gl.R8;
		} else if (glFormat == _gl.RED_INTEGER) {
			if (glType == _gl.UNSIGNED_BYTE) internalFormat = _gl.R8UI;
			else if (glType == _gl.UNSIGNED_SHORT) internalFormat = _gl.R16UI;
			else if (glType == _gl.UNSIGNED_INT) internalFormat = _gl.R32UI;
			else if (glType == _gl.BYTE) internalFormat = _gl.R8I;
			else if (glType == _gl.SHORT) internalFormat = _gl.R16I;
			else if (glType == _gl.INT) internalFormat = _gl.R32I;
		} else if (glFormat == _gl.RG) {
			if (glType == _gl.FLOAT) internalFormat = _gl.RG32F;
			else if (glType == _gl.HALF_FLOAT) internalFormat = _gl.RG16F;
			else if (glType == _gl.UNSIGNED_BYTE) internalFormat = _gl.RG8;
		} else if (glFormat == _gl.RG_INTEGER) {
			if (glType == _gl.UNSIGNED_BYTE) internalFormat = _gl.RG8UI;
			else if (glType == _gl.UNSIGNED_SHORT) internalFormat = _gl.RG16UI;
			else if (glType == _gl.UNSIGNED_INT) internalFormat = _gl.RG32UI;
			else if (glType == _gl.BYTE) internalFormat = _gl.RG8I;
			else if (glType == _gl.SHORT) internalFormat = _gl.RG16I;
			else if (glType == _gl.INT) internalFormat = _gl.RG32I;
		} else if (glFormat == _gl.RGB) {
			if (glType == _gl.UNSIGNED_INT_5_9_9_9_REV) internalFormat = _gl.RGB9_E5;
		} else if (glFormat == _gl.RGBA) {
			var transfer = forceLinearTransfer ? LinearTransfer : ColorManagement.getTransfer(colorSpace);
			if (glType == _gl.FLOAT) internalFormat = _gl.RGBA32F;
			else if (glType == _gl.HALF_FLOAT) internalFormat = _gl.RGBA16F;
			else if (glType == _gl.UNSIGNED_BYTE) internalFormat = (transfer == SRGBTransfer) ? _gl.SRGB8_ALPHA8 : _gl.RGBA8;
			else if (glType == _gl.UNSIGNED_SHORT_4_4_4_4) internalFormat = _gl.RGBA4;
			else if (glType == _gl.UNSIGNED_SHORT_5_5_5_1) internalFormat = _gl.RGB5_A1;
		}
		if (internalFormat == _gl.R16F || internalFormat == _gl.R32F ||
			internalFormat == _gl.RG16F || internalFormat == _gl.RG32F ||
			internalFormat == _gl.RGBA16F || internalFormat == _gl.RGBA32F) {
			_extensions.get("EXT_color_buffer_float");
		}
		return internalFormat;
	}

	function getMipLevels(texture: Dynamic, image: Dynamic): Int {
		if (textureNeedsGenerateMipmaps(texture) || (texture.isFramebufferTexture && texture.minFilter != NearestFilter && texture.minFilter != LinearFilter)) {
			return Math.log2(Math.max(image.width, image.height)) + 1;
		} else if (texture.mipmaps != null && texture.mipmaps.length > 0) {
			return texture.mipmaps.length;
		} else if (texture.isCompressedTexture && Std.is(texture.image, Array)) {
			return image.mipmaps.length;
		} else {
			return 1;
		}
	}

	function onTextureDispose(event: Dynamic) {
		var texture = event.target;
		texture.removeEventListener('dispose', onTextureDispose);
		deallocateTexture(texture);
		if (texture.isVideoTexture) {
			_videoTextures.delete(texture);
		}
	}

	function onRenderTargetDispose(event: Dynamic) {
		var renderTarget = event.target;
		renderTarget.removeEventListener('dispose', onRenderTargetDispose);
		deallocateRenderTarget(renderTarget);
	}

	function deallocateTexture(texture: Dynamic) {
		var textureProperties = _properties.get(texture);
		if (textureProperties.__webglInit == null) return;
		var source = texture.source;
		var webglTextures = _sources.get(source);
		if (webglTextures != null) {
			var webglTexture = webglTextures[textureProperties.__cacheKey];
			webglTexture.usedTimes--;
			if (webglTexture.usedTimes == 0) {
				deleteTexture(texture);
			}
			if (Reflect.field(webglTextures, "length") == 0) {
				_sources.delete(source);
			}
		}
		_properties.remove(texture);
	}

	function deleteTexture(texture: Dynamic) {
		var textureProperties = _properties.get(texture);
		_gl.deleteTexture(textureProperties.__webglTexture);
		var source = texture.source;
		var webglTextures = _sources.get(source);
		Reflect.deleteField(webglTextures, textureProperties.__cacheKey);
		_info.memory.textures--;
	}

	function deallocateRenderTarget(renderTarget: Dynamic) {
		var renderTargetProperties = _properties.get(renderTarget);
		if (renderTarget.depthTexture != null) {
			renderTarget.depthTexture.dispose();
		}
		if (renderTarget.isWebGLCubeRenderTarget) {
			for (var i = 0; i < 6; i++) {
				if (Std.is(renderTargetProperties.__webglFramebuffer[i], Array)) {
					for (var level = 0; level < renderTargetProperties.__webglFramebuffer[i].length; level++) _gl.deleteFramebuffer(renderTargetProperties.__webglFramebuffer[i][level]);
				} else {
					_gl.deleteFramebuffer(renderTargetProperties.__webglFramebuffer[i]);
				}
				if (renderTargetProperties.__webglDepthbuffer != null) _gl.deleteRenderbuffer(renderTargetProperties.__webglDepthbuffer[i]);
			}
		} else {
			if (Std.is(renderTargetProperties.__webglFramebuffer, Array)) {
				for (var level = 0; level < renderTargetProperties.__webglFramebuffer.length; level++) _gl.deleteFramebuffer(renderTargetProperties.__webglFramebuffer[level]);
			} else {
				_gl.deleteFramebuffer(renderTargetProperties.__webglFramebuffer);
			}
			if (renderTargetProperties.__webglDepthbuffer != null) _gl.deleteRenderbuffer(renderTargetProperties.__webglDepthbuffer);
			if (renderTargetProperties.__webglMultisampledFramebuffer != null) _gl.deleteFramebuffer(renderTargetProperties.__webglMultisampledFramebuffer);
			if (renderTargetProperties.__webglColorRenderbuffer != null) {
				for (var i = 0; i < renderTargetProperties.__webglColorRenderbuffer.length; i++) {
					if (renderTargetProperties.__webglColorRenderbuffer[i] != null) _gl.deleteRenderbuffer(renderTargetProperties.__webglColorRenderbuffer[i]);
				}
			}
			if (renderTargetProperties.__webglDepthRenderbuffer != null) _gl.deleteRenderbuffer(renderTargetProperties.__webglDepthRenderbuffer);
		}
		var textures = renderTarget.textures;
		for (var i = 0, il = textures.length; i < il; i++) {
			var attachmentProperties = _properties.get(textures[i]);
			if (attachmentProperties.__webglTexture != null) {
				_gl.deleteTexture(attachmentProperties.__webglTexture);
				_info.memory.textures--;
			}
			_properties.remove(textures[i]);
		}
		_properties.remove(renderTarget);
	}

	function resetTextureUnits() {
		textureUnits = 0;
	}

	function allocateTextureUnit(): Int {
		var textureUnit = textureUnits;
		if (textureUnit >= _capabilities.maxTextures) {
			console.warn('THREE.WebGLTextures: Trying to use ' + textureUnit + ' texture units while this GPU supports only ' + _capabilities.maxTextures);
		}
		textureUnits++;
		return textureUnit;
	}

	function getTextureCacheKey(texture: Dynamic): String {
		var array = [];
		array.push(texture.wrapS);
		array.push(texture.wrapT);
		array.push(texture.wrapR == null ? 0 : texture.wrapR);
		array.push(texture.magFilter);
		array.push(texture.minFilter);
		array.push(texture.anisotropy);
		array.push(texture.internalFormat);
		array.push(texture.format);
		array.push(texture.type);
		array.push(texture.generateMipmaps);
		array.push(texture.premultiplyAlpha);
		array.push(texture.flipY);
		array.push(texture.unpackAlignment);
		array.push(texture.colorSpace);
		return array.join();
	}

	function setTexture2D(texture: Dynamic, slot: Int) {
		var textureProperties = _properties.get(texture);
		if (texture.isVideoTexture) updateVideoTexture(texture);
		if (!texture.isRenderTargetTexture && texture.version > 0 && textureProperties.__version != texture.version) {
			var image = texture.image;
			if (image == null) {
				console.warn('THREE.WebGLRenderer: Texture marked for update but no image data found.');
			} else if (!image.complete) {
				console.warn('THREE.WebGLRenderer: Texture marked for update but image is incomplete');
			} else {
				uploadTexture(textureProperties, texture, slot);
				return;
			}
		}
		_state.bindTexture(_gl.TEXTURE_2D, textureProperties.__webglTexture, _gl.TEXTURE0 + slot);
	}

	function setTexture2DArray(texture: Dynamic, slot: Int) {
		var textureProperties = _properties.get(texture);
		if (texture.version > 0 && textureProperties.__version != texture.version) {
			uploadTexture(textureProperties, texture, slot);
			return;
		}
		_state.bindTexture(_gl.TEXTURE_2D_ARRAY, textureProperties.__webglTexture, _gl.TEXTURE0 + slot);
	}

	function setTexture3D(texture: Dynamic, slot: Int) {
		var textureProperties = _properties.get(texture);
		if (texture.version > 0 && textureProperties.__version != texture.version) {
			uploadTexture(textureProperties, texture, slot);
			return;
		}
		_state.bindTexture(_gl.TEXTURE_3D, textureProperties.__webglTexture, _gl.TEXTURE0 + slot);
	}

	function setTextureCube(texture: Dynamic, slot: Int) {
		var textureProperties = _properties.get(texture);
		if (texture.version > 0 && textureProperties.__version != texture.version) {
			uploadCubeTexture(textureProperties, texture, slot);
			return;
		}
		_state.bindTexture(_gl.TEXTURE_CUBE_MAP, textureProperties.__webglTexture, _gl.TEXTURE0 + slot);
	}

	var wrappingToGL = {
		RepeatWrapping: _gl.REPEAT,
		ClampToEdgeWrapping: _gl.CLAMP_TO_EDGE,
		MirroredRepeatWrapping: _gl.MIRRORED_REPEAT
	};
	var filterToGL = {
		NearestFilter: _gl.NEAREST,
		NearestMipmapNearestFilter: _gl.NEAREST_MIPMAP_NEAREST,
		NearestMipmapLinearFilter: _gl.NEAREST_MIPMAP_LINEAR,
		LinearFilter: _gl.LINEAR,
		LinearMipmapNearestFilter: _gl.LINEAR_MIPMAP_NEAREST,
		LinearMipmapLinearFilter: _gl.LINEAR_MIPMAP_LINEAR
	};
	var compareToGL = {
		NeverCompare: _gl.NEVER,
		AlwaysCompare: _gl.ALWAYS,
		LessCompare: _gl.LESS,
		LessEqualCompare: _gl.LEQUAL,
		EqualCompare: _gl.EQUAL,
		GreaterEqualCompare: _gl.GEQUAL,
		GreaterCompare: _gl.GREATER,
		NotEqualCompare: _gl.NOTEQUAL
	};

	function setTextureParameters(textureType: Int, texture: Dynamic) {
		if (texture.type == FloatType && !_extensions.exists("OES_texture_float_linear") &&
			(texture.magFilter == LinearFilter || texture.magFilter == LinearMipmapNearestFilter || texture.magFilter == NearestMipmapLinearFilter || texture.magFilter == LinearMipmapLinearFilter ||
				texture.minFilter == LinearFilter || texture.minFilter == LinearMipmapNearestFilter || texture.minFilter == NearestMipmapLinearFilter || texture.minFilter == LinearMipmapLinearFilter)) {
			console.warn('THREE.WebGLRenderer: Unable to use linear filtering with floating point textures. OES_texture_float_linear not supported on this device.');
		}
		_gl.texParameteri(textureType, _gl.TEXTURE_WRAP_S, wrappingToGL[texture.wrapS]);
		_gl.texParameteri(textureType, _gl.TEXTURE_WRAP_T, wrappingToGL[texture.wrapT]);
		if (textureType == _gl.TEXTURE_3D || textureType == _gl.TEXTURE_2D_ARRAY) {
			_gl.texParameteri(textureType, _gl.TEXTURE_WRAP_R, wrappingToGL[texture.wrapR]);
		}
		_gl.texParameteri(textureType, _gl.TEXTURE_MAG_FILTER, filterToGL[texture.magFilter]);
		_gl.texParameteri(textureType, _gl.TEXTURE_MIN_FILTER, filterToGL[texture.minFilter]);
		if (texture.compareFunction != null) {
			_gl.texParameteri(textureType, _gl.TEXTURE_COMPARE_MODE, _gl.COMPARE_REF_TO_TEXTURE);
			_gl.texParameteri(textureType, _gl.TEXTURE_COMPARE_FUNC, compareToGL[texture.compareFunction]);
		}
		if (_extensions.exists("EXT_texture_filter_anisotropic")) {
			if (texture.magFilter == NearestFilter) return;
			if (texture.minFilter != NearestMipmapLinearFilter && texture.minFilter != LinearMipmapLinearFilter) return;
			if (texture.type == FloatType && !_extensions.exists("OES_texture_float_linear")) return;
			if (texture.anisotropy > 1 || _properties.get(texture).__currentAnisotropy != null) {
				var extension = _extensions.get("EXT_texture_filter_anisotropic");
				_gl.texParameterf(textureType, extension.TEXTURE_MAX_ANISOTROPY_EXT, Math.min(texture.anisotropy, _capabilities.getMaxAnisotropy()));
				_properties.get(texture).__currentAnisotropy = texture.anisotropy;
			}
		}
	}

	function initTexture(textureProperties: Dynamic, texture: Dynamic): Bool {
		var forceUpload = false;
		if (textureProperties.__webglInit == null) {
			textureProperties.__webglInit = true;
			texture.addEventListener('dispose', onTextureDispose);
		}
		var source = texture.source;
		var webglTextures = _sources.get(source);
		if (webglTextures == null) {
			webglTextures = {};
			_sources.set(source, webglTextures);
		}
		var textureCacheKey = getTextureCacheKey(texture);
		if (textureCacheKey != textureProperties.__cacheKey) {
			if (webglTextures[textureCacheKey] == null) {
				webglTextures[textureCacheKey] = {
					texture: _gl.createTexture(),
					usedTimes: 0
				};
				_info.memory.textures++;
				forceUpload = true;
			}
			webglTextures[textureCacheKey].usedTimes++;
			var webglTexture = webglTextures[textureProperties.__cacheKey];
			if (webglTexture != null) {
				webglTextures[textureProperties.__cacheKey].usedTimes--;
				if (webglTexture.usedTimes == 0) {
					deleteTexture(texture);
				}
			}
			textureProperties.__cacheKey = textureCacheKey;
			textureProperties.__webglTexture = webglTextures[textureCacheKey].texture;
		}
		return forceUpload;
	}

	function uploadTexture(textureProperties: Dynamic, texture: Dynamic, slot: Int) {
		var textureType = _gl.TEXTURE_2D;
		if (texture.isDataArrayTexture || texture.isCompressedArrayTexture) textureType = _gl.TEXTURE_2D_ARRAY;
		else if (texture.isData3DTexture) textureType = _gl.TEXTURE_3D;
		var forceUpload = initTexture(textureProperties, texture);
		var source = texture.source;
		_state.bindTexture(textureType, textureProperties.__webglTexture, _gl.TEXTURE0 + slot);
		var sourceProperties = _properties.get(source);
		if (source.version != sourceProperties.__version || forceUpload) {
			_state.activeTexture(_gl.TEXTURE0 + slot);
			var workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
			var texturePrimaries = texture.colorSpace == NoColorSpace ? null : ColorManagement.getPrimaries(texture.colorSpace);
			var unpackConversion = texture.colorSpace == NoColorSpace || workingPrimaries == texturePrimaries ? _gl.NONE : _gl.BROWSER_DEFAULT_WEBGL;
			_gl.pixelStorei(_gl.UNPACK_FLIP_Y_WEBGL, texture.flipY);
			_gl.pixelStorei(_gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha);
			_gl.pixelStorei(_gl.UNPACK_ALIGNMENT, texture.unpackAlignment);
			_gl.pixelStorei(_gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, unpackConversion);
			var image = resizeImage(texture.image, false, _capabilities.maxTextureSize);
			image = verifyColorSpace(texture, image);
			var glFormat = _utils.convert(texture.format, texture.colorSpace);
			var glType = _utils.convert(texture.type);
			var glInternalFormat = getInternalFormat(texture.internalFormat, glFormat, glType, texture.colorSpace, texture.isVideoTexture);
			setTextureParameters(textureType, texture);
			var mipmap;
			var mipmaps = texture.mipmaps;
			var useTexStorage = (texture.isVideoTexture != true);
			var allocateMemory = (sourceProperties.__version == null) || (forceUpload);
			var dataReady = source.dataReady;
			var levels = getMipLevels(texture, image);
			if (texture.isDepthTexture) {
				glInternalFormat = _gl.DEPTH_COMPONENT16;
				if (texture.type == FloatType) {
					glInternalFormat = _gl.DEPTH_COMPONENT32F;
				} else if (texture.type == UnsignedIntType) {
					glInternalFormat = _gl.DEPTH_COMPONENT24;
				} else if (texture.type == UnsignedInt248Type) {
					glInternalFormat = _gl.DEPTH24_STENCIL8;
				}
				if (allocateMemory) {
					if (useTexStorage) {
						_state.texStorage2D(_gl.TEXTURE_2D, 1, glInternalFormat, image.width, image.height);
					} else {
						_state.texImage2D(_gl.TEXTURE_2D, 0, glInternalFormat, image.width, image.height, 0, glFormat, glType, null);
					}
				}
			} else if (texture.isDataTexture) {
				if (mipmaps.length > 0) {
					if (useTexStorage && allocateMemory) {
						_state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, mipmaps[0].width, mipmaps[0].height);
					}
					for (var i = 0, il = mipmaps.length; i < il; i++) {
						mipmap = mipmaps[i];
						if (useTexStorage) {
							if (dataReady) {
								_state.texSubImage2D(_gl.TEXTURE_2D, i, 0, 0, mipmap.width, mipmap.height, glFormat, glType, mipmap.data);
							}
						} else {
							_state.texImage2D(_gl.TEXTURE_2D, i, glInternalFormat, mipmap.width, mipmap.height, 0, glFormat, glType, mipmap.data);
						}
					}
					texture.generateMipmaps = false;
				} else {
					if (useTexStorage) {
						if (allocateMemory) {
							_state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, image.width, image.height);
						}
						if (dataReady) {
							_state.texSubImage2D(_gl.TEXTURE_2D, 0, 0, 0, image.width, image.height, glFormat, glType, image.data);
						}
					} else {
						_state.texImage2D(_gl.TEXTURE_2D, 0, glInternalFormat, image.width, image.height, 0, glFormat, glType, image.data);
					}
				}
			} else if (texture.isCompressedTexture) {
				if (texture.isCompressedArrayTexture) {
					if (useTexStorage && allocateMemory) {
						_state.texStorage3D(_gl.TEXTURE_2D_ARRAY, levels, glInternalFormat, mipmaps[0].width, mipmaps[0].height, image.depth);
					}
					for (var i = 0, il = mipmaps.length; i < il; i++) {
						mipmap = mipmaps[i];
						if (texture.format != RGBAFormat) {
							if (glFormat != null) {
								if (useTexStorage) {
									if (dataReady) {
										if (texture.layerUpdates.size > 0) {
											for (var layerIndex in texture.layerUpdates) {
												var layerSize = mipmap.width * mipmap.height;
												_state.compressedTexSubImage3D(_gl.TEXTURE_2D_ARRAY, i, 0, 0, layerIndex, mipmap.width, mipmap.height, 1, glFormat, mipmap.data.slice(layerSize * layerIndex, layerSize * (layerIndex + 1)), 0, 0);
											}
											texture.clearLayerUpdates();
										} else {
											_state.compressedTexSubImage3D(_gl.TEXTURE_2D_ARRAY, i, 0, 0, 0, mipmap.width, mipmap.height, image.depth, glFormat, mipmap.data, 0, 0);
										}
									}
								} else {
									_state.compressedTexImage3D(_gl.TEXTURE_2D_ARRAY, i, glInternalFormat, mipmap.width, mipmap.height, image.depth, 0, mipmap.data, 0, 0);
								}
							} else {
								console.warn('THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()');
							}
						} else {
							if (useTexStorage) {
								if (dataReady) {
									_state.texSubImage3D(_gl.TEXTURE_2D_ARRAY, i, 0, 0, 0, mipmap.width, mipmap.height, image.depth, glFormat, glType, mipmap.data);
								}
							} else {
								_state.texImage3D(_gl.TEXTURE_2D_ARRAY, i, glInternalFormat, mipmap.width, mipmap.height, image.depth, 0, glFormat, glType, mipmap.data);
							}
						}
					}
				} else {
					if (useTexStorage && allocateMemory) {
						_state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, mipmaps[0].width, mipmaps[0].height);
					}
					for (var i = 0, il = mipmaps.length; i < il; i++) {
						mipmap = mipmaps[i];
						if (texture.format != RGBAFormat) {
							if (glFormat != null) {
								if (useTexStorage) {
									if (dataReady) {
										_state.compressedTexSubImage2D(_gl.TEXTURE_2D, i, 0, 0, mipmap.width, mipmap.height, glFormat, mipmap.data);
									}
								} else {
									_state.compressedTexImage2D(_gl.TEXTURE_2D, i, glInternalFormat, mipmap.width, mipmap.height, 0, mipmap.data);
								}
							} else {
								console.warn('THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()');
							}
						} else {
							if (useTexStorage) {
								if (dataReady) {
									_state.texSubImage2D(_gl.TEXTURE_2D, i, 0, 0, mipmap.width, mipmap.height, glFormat, glType, mipmap.data);
								}
							} else {
								_state.texImage2D(_gl.TEXTURE_2D, i, glInternalFormat, mipmap.width, mipmap.height, 0, glFormat, glType, mipmap.data);
							}
						}
					}
				}
			} else if (texture.isDataArrayTexture) {
				if (useTexStorage) {
					if (allocateMemory) {
						_state.texStorage3D(_gl.TEXTURE_2D_ARRAY, levels, glInternalFormat, image.width, image.height, image.depth);
					}
					if (dataReady) {
						if (texture.layerUpdates.size > 0) {
							var texelSize: Int;
							switch (glType) {
								case _gl.UNSIGNED_BYTE:
									switch (glFormat) {
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
											throw new Error('Unknown texel size for format ' + glFormat + '.');
									}
									break;
								case _gl.UNSIGNED_SHORT_4_4_4_4:
								case _gl.UNSIGNED_SHORT_5_5_5_1:
								case _gl.UNSIGNED_SHORT_5_6_5:
									texelSize = 1;
									break;
								default:
									throw new Error('Unknown texel size for type ' + glType + '.');
							}
							var layerSize = image.width * image.height * texelSize;
							for (var layerIndex in texture.layerUpdates) {
								_state.texSubImage3D(_gl.TEXTURE_2D_ARRAY, 0, 0, 0, layerIndex, image.width, image.height, 1, glFormat, glType, image.data.slice(layerSize * layerIndex, layerSize * (layerIndex + 1)));
							}
							texture.clearLayerUpdates();
						} else {
							_state.texSubImage3D(_gl.TEXTURE_2D_ARRAY, 0, 0, 0, 0, image.width, image.height, image.depth, glFormat, glType, image.data);
						}
					}
				} else {
					_state.texImage3D(_gl.TEXTURE_2D_ARRAY, 0, glInternalFormat, image.width, image.height, image.depth, 0, glFormat, glType, image.data);
				}
			} else if (texture.isData3DTexture) {
				if (useTexStorage) {
					if (allocateMemory) {
						_state.texStorage3D(_gl.TEXTURE_3D, levels, glInternalFormat, image.width, image.height, image.depth);
					}
					if (dataReady) {
						_state.texSubImage3D(_gl.TEXTURE_3D, 0, 0, 0, 0, image.width, image.height, image.depth, glFormat, glType, image.data);
					}
				} else {
					_state.texImage3D(_gl.TEXTURE_3D, 0, glInternalFormat, image.width, image.height, image.depth, 0, glFormat, glType, image.data);
				}
			} else if (texture.isFramebufferTexture) {
				if (allocateMemory) {
					if (useTexStorage) {
						_state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, image.width, image.height);
					} else {
						var width = image.width;
						var height = image.height;
						for (var i = 0; i < levels; i++) {
							_state.texImage2D(_gl.TEXTURE_2D, i, glInternalFormat, width
				}
			} else if (texture.isFramebufferTexture) {

				if (allocateMemory) {

					if (useTexStorage) {

						_state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, image.width, image.height);

					} else {

						var width = image.width;
						var height = image.height;
						for (var i = 0; i < levels; i++) {
							_state.texImage2D(_gl.TEXTURE_2D, i, glInternalFormat, width, height, 0, glFormat, glType, null);
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

				if (mipmaps.length > 0) {

					if (useTexStorage && allocateMemory) {

						const dimensions = getDimensions(mipmaps[0]);

						_state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, dimensions.width, dimensions.height);

					}

					for (var i = 0, il = mipmaps.length; i < il; i++) {

						mipmap = mipmaps[i];

						if (useTexStorage) {

							if (dataReady) {

								_state.texSubImage2D(_gl.TEXTURE_2D, i, 0, 0, glFormat, glType, mipmap);

							}

						} else {

							_state.texImage2D(_gl.TEXTURE_2D, i, glInternalFormat, glFormat, glType, mipmap);

						}

					}

					texture.generateMipmaps = false;

				} else {

					if (useTexStorage) {

						if (allocateMemory) {

							const dimensions = getDimensions(image);

							_state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, dimensions.width, dimensions.height);

						}

						if (dataReady) {

							_state.texSubImage2D(_gl.TEXTURE_2D, 0, 0, 0, glFormat, glType, image);

						}

					} else {

						_state.texImage2D(_gl.TEXTURE_2D, 0, glInternalFormat, glFormat, glType, image);

					}

				}

			}

			if (textureNeedsGenerateMipmaps(texture)) {

				generateMipmap(textureType);

			}

			sourceProperties.__version = source.version;

			if (texture.onUpdate != null) texture.onUpdate(texture);

		}

		textureProperties.__version = texture.version;

	}

	function uploadCubeTexture(textureProperties: Dynamic, texture: Dynamic, slot: Int) {

		if (texture.image.length != 6) return;

		const forceUpload = initTexture(textureProperties, texture);
		const source = texture.source;

		_state.bindTexture(_gl.TEXTURE_CUBE_MAP, textureProperties.__webglTexture, _gl.TEXTURE0 + slot);

		const sourceProperties = _properties.get(source);

		if (source.version != sourceProperties.__version || forceUpload) {

			_state.activeTexture(_gl.TEXTURE0 + slot);

			const workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
			const texturePrimaries = texture.colorSpace == NoColorSpace ? null : ColorManagement.getPrimaries(texture.colorSpace);
			const unpackConversion = texture.colorSpace == NoColorSpace || workingPrimaries == texturePrimaries ? _gl.NONE : _gl.BROWSER_DEFAULT_WEBGL;

			_gl.pixelStorei(_gl.UNPACK_FLIP_Y_WEBGL, texture.flipY);
			_gl.pixelStorei(_gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha);
			_gl.pixelStorei(_gl.UNPACK_ALIGNMENT, texture.unpackAlignment);
			_gl.pixelStorei(_gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, unpackConversion);

			const isCompressed = (texture.isCompressedTexture || texture.image[0].isCompressedTexture);
			const isDataTexture = (texture.image[0] != null && texture.image[0].isDataTexture);

			const cubeImage = [];

			for (var i = 0; i < 6; i++) {

				if (!isCompressed && !isDataTexture) {

					cubeImage[i] = resizeImage(texture.image[i], true, _capabilities.maxCubemapSize);

				} else {

					cubeImage[i] = isDataTexture ? texture.image[i].image : texture.image[i];

				}

				cubeImage[i] = verifyColorSpace(texture, cubeImage[i]);

			}

			const image = cubeImage[0],
				glFormat = _utils.convert(texture.format, texture.colorSpace),
				glType = _utils.convert(texture.type),
				glInternalFormat = getInternalFormat(texture.internalFormat, glFormat, glType, texture.colorSpace);

			const useTexStorage = (texture.isVideoTexture != true);
			const allocateMemory = (sourceProperties.__version == null) || (forceUpload);
			const dataReady = source.dataReady;
			var levels = getMipLevels(texture, image);

			setTextureParameters(_gl.TEXTURE_CUBE_MAP, texture);

			var mipmaps;

			if (isCompressed) {

				if (useTexStorage && allocateMemory) {

					_state.texStorage2D(_gl.TEXTURE_CUBE_MAP, levels, glInternalFormat, image.width, image.height);

				}

				for (var i = 0; i < 6; i++) {

					mipmaps = cubeImage[i].mipmaps;

					for (var j = 0; j < mipmaps.length; j++) {

						const mipmap = mipmaps[j];

						if (texture.format != RGBAFormat) {

							if (glFormat != null) {

								if (useTexStorage) {

									if (dataReady) {

										_state.compressedTexSubImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, 0, 0, mipmap.width, mipmap.height, glFormat, mipmap.data);

									}

								} else {

									_state.compressedTexImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, glInternalFormat, mipmap.width, mipmap.height, 0, mipmap.data);

								}

							} else {

								console.warn('THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .setTextureCube()');

							}

						} else {

							if (useTexStorage) {

								if (dataReady) {

									_state.texSubImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, 0, 0, mipmap.width, mipmap.height, glFormat, glType, mipmap.data);

								}

							} else {

								_state.texImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, glInternalFormat, mipmap.width, mipmap.height, 0, glFormat, glType, mipmap.data);

							}

						}

					}

				}

			} else {

				mipmaps = texture.mipmaps;

				if (useTexStorage && allocateMemory) {

					// TODO: Uniformly handle mipmap definitions
					// Normal textures and compressed cube textures define base level + mips with their mipmap array
					// Uncompressed cube textures use their mipmap array only for mips (no base level)

					if (mipmaps.length > 0) levels++;

					const dimensions = getDimensions(cubeImage[0]);

					_state.texStorage2D(_gl.TEXTURE_CUBE_MAP, levels, glInternalFormat, dimensions.width, dimensions.height);

				}

				for (var i = 0; i < 6; i++) {

					if (isDataTexture) {

						if (useTexStorage) {

							if (dataReady) {

								_state.texSubImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, 0, 0, cubeImage[i].width, cubeImage[i].height, glFormat, glType, cubeImage[i].data);

							}

						} else {

							_state.texImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, glInternalFormat, cubeImage[i].width, cubeImage[i].height, 0, glFormat, glType, cubeImage[i].data);

						}

						for (var j = 0; j < mipmaps.length; j++) {

							const mipmap = mipmaps[j];
							const mipmapImage = mipmap.image[i].image;

							if (useTexStorage) {

								if (dataReady) {

									_state.texSubImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j + 1, 0, 0, mipmapImage.width, mipmapImage.height, glFormat, glType, mipmapImage.data);

								}

							} else {

								_state.texImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j + 1, glInternalFormat, mipmapImage.width, mipmapImage.height, 0, glFormat, glType, mipmapImage.data);

							}

						}

					} else {

						if (useTexStorage) {

							if (dataReady) {

								_state.texSubImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, 0, 0, glFormat, glType, cubeImage[i]);

							}

						} else {

							_state.texImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, glInternalFormat, glFormat, glType, cubeImage[i]);

						}

						for (var j = 0; j < mipmaps.length; j++) {

							const mipmap = mipmaps[j];

							if (useTexStorage) {

								if (dataReady) {

									_state.texSubImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j + 1, 0, 0, glFormat, glType, mipmap.image[i]);

								}

							} else {

								_state.texImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j + 1, glInternalFormat, glFormat, glType, mipmap.image[i]);

							}

						}

					}

				}

			}

			if (textureNeedsGenerateMipmaps(texture)) {

				// We assume images for cube map have the same size.
				generateMipmap(_gl.TEXTURE_CUBE_MAP);

			}

			sourceProperties.__version = source.version;

			if (texture.onUpdate != null) texture.onUpdate(texture);

		}

		textureProperties.__version = texture.version;

	}

	// Render targets

	// Setup storage for target texture and bind it to correct framebuffer
	function setupFrameBufferTexture(framebuffer: Dynamic, renderTarget: Dynamic, texture: Dynamic, attachment: Int, textureTarget: Int, level: Int) {

		const glFormat = _utils.convert(texture.format, texture.colorSpace);
		const glType = _utils.convert(texture.type);
		const glInternalFormat = getInternalFormat(texture.internalFormat, glFormat, glType, texture.colorSpace);
		const renderTargetProperties = _properties.get(renderTarget);

		if (!renderTargetProperties.__hasExternalTextures) {

			const width = Math.max(1, renderTarget.width >> level);
			const height = Math.max(1, renderTarget.height >> level);

			if (textureTarget == _gl.TEXTURE_3D || textureTarget == _gl.TEXTURE_2D_ARRAY) {

				_state.texImage3D(textureTarget, level, glInternalFormat, width, height, renderTarget.depth, 0, glFormat, glType, null);

			} else {

				_state.texImage2D(textureTarget, level, glInternalFormat, width, height, 0, glFormat, glType, null);

			}

		}

		_state.bindFramebuffer(_gl.FRAMEBUFFER, framebuffer);

		if (useMultisampledRTT(renderTarget)) {

			multisampledRTTExt.framebufferTexture2DMultisampleEXT(_gl.FRAMEBUFFER, attachment, textureTarget, _properties.get(texture).__webglTexture, 0, getRenderTargetSamples(renderTarget));

		} else if (textureTarget == _gl.TEXTURE_2D || (textureTarget >= _gl.TEXTURE_CUBE_MAP_POSITIVE_X && textureTarget <= _gl.TEXTURE_CUBE_MAP_NEGATIVE_Z)) { // see #24753

			_gl.framebufferTexture2D(_gl.FRAMEBUFFER, attachment, textureTarget, _properties.get(texture).__webglTexture, level);

		}

		_state.bindFramebuffer(_gl.FRAMEBUFFER, null);

	}


	// Setup storage for internal depth/stencil buffers and bind to correct framebuffer
	function setupRenderBufferStorage(renderbuffer: Dynamic, renderTarget: Dynamic, isMultisample: Bool) {

		_gl.bindRenderbuffer(_gl.RENDERBUFFER, renderbuffer);

		if (renderTarget.depthBuffer && !renderTarget.stencilBuffer) {

			var glInternalFormat = _gl.DEPTH_COMPONENT24;

			if (isMultisample || useMultisampledRTT(renderTarget)) {

				const depthTexture = renderTarget.depthTexture;

				if (depthTexture != null && depthTexture.isDepthTexture) {

					if (depthTexture.type == FloatType) {

						glInternalFormat = _gl.DEPTH_COMPONENT32F;

					} else if (depthTexture.type == UnsignedIntType) {

						glInternalFormat = _gl.DEPTH_COMPONENT24;

					}

				}

				const samples = getRenderTargetSamples(renderTarget);

				if (useMultisampledRTT(renderTarget)) {

					multisampledRTTExt.renderbufferStorageMultisampleEXT(_gl.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height);

				} else {

					_gl.renderbufferStorageMultisample(_gl.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height);

				}

			} else {

				_gl.renderbufferStorage(_gl.RENDERBUFFER, glInternalFormat, renderTarget.width, renderTarget.height);

			}

			_gl.framebufferRenderbuffer(_gl.FRAMEBUFFER, _gl.DEPTH_ATTACHMENT, _gl.RENDERBUFFER, renderbuffer);

		} else if (renderTarget.depthBuffer && renderTarget.stencilBuffer) {

			const samples = getRenderTargetSamples(renderTarget);

			if (isMultisample && useMultisampledRTT(renderTarget) == false) {

				_gl.renderbufferStorageMultisample(_gl.RENDERBUFFER, samples, _gl.DEPTH24_STENCIL8, renderTarget.width, renderTarget.height);

			} else if (useMultisampledRTT(renderTarget)) {

				multisampledRTTExt.renderbufferStorageMultisampleEXT(_gl.RENDERBUFFER, samples, _gl.DEPTH24_STENCIL8, renderTarget.width, renderTarget.height);

			} else {

				_gl.renderbufferStorage(_gl.RENDERBUFFER, _gl.DEPTH_STENCIL, renderTarget.width, renderTarget.height);

			}


			_gl.framebufferRenderbuffer(_gl.FRAMEBUFFER, _gl.DEPTH_STENCIL_ATTACHMENT, _gl.RENDERBUFFER, renderbuffer);

		} else {

			const textures = renderTarget.textures;

			for (var i = 0; i < textures.length; i++) {

				const texture = textures[i];

				const glFormat = _utils.convert(texture.format, texture.colorSpace);
				const glType = _utils.convert(texture.type);
				const glInternalFormat = getInternalFormat(texture.internalFormat, glFormat, glType, texture.colorSpace);
				const samples = getRenderTargetSamples(renderTarget);

				if (isMultisample && useMultisampledRTT(renderTarget) == false) {

					_gl.renderbufferStorageMultisample(_gl.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height);

				} else if (useMultisampledRTT(renderTarget)) {

					multisampledRTTExt.renderbufferStorageMultisampleEXT(_gl.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height);

				} else {

					_gl.renderbufferStorage(_gl.RENDERBUFFER, glInternalFormat, renderTarget.width, renderTarget.height);

				}

			}

		}

		_gl.bindRenderbuffer(_gl.RENDERBUFFER, null);

	}

	// Setup resources for a Depth Texture for a FBO (needs an extension)
	function setupDepthTexture(framebuffer: Dynamic, renderTarget: Dynamic) {

		const isCube = (renderTarget != null && renderTarget.isWebGLCubeRenderTarget);
		if (isCube) throw new Error('Depth Texture with cube render targets is not supported');

		_state.bindFramebuffer(_gl.FRAMEBUFFER, framebuffer);

		if (!(renderTarget.depthTexture != null && renderTarget.depthTexture.isDepthTexture)) {

			throw new Error('renderTarget.depthTexture must be an instance of THREE.DepthTexture');

		}

		// upload an empty depth texture with framebuffer size
		if (!_properties.get(renderTarget.depthTexture).__webglTexture ||
			renderTarget.depthTexture.image.width != renderTarget.width ||
			renderTarget.depthTexture.image.height != renderTarget.height) {

			renderTarget.depthTexture.image.width = renderTarget.width;
			renderTarget.depthTexture.image.height = renderTarget.height;
			renderTarget.depthTexture.needsUpdate = true;

		}

		setTexture2D(renderTarget.depthTexture, 0);

		const webglDepthTexture = _properties.get(renderTarget.depthTexture).__webglTexture;
		const samples = getRenderTargetSamples(renderTarget);

		if (renderTarget.depthTexture.format == DepthFormat) {

			if (useMultisampledRTT(renderTarget)) {

				multisampledRTTExt.framebufferTexture2DMultisampleEXT(_gl.FRAMEBUFFER, _gl.DEPTH_ATTACHMENT, _gl.TEXTURE_2D, webglDepthTexture, 0, samples);

			} else {

				_gl.framebufferTexture2D(_gl.FRAMEBUFFER, _gl.DEPTH_ATTACHMENT, _gl.TEXTURE_2D, webglDepthTexture, 0);

			}

		} else if (renderTarget.depthTexture.format == DepthStencilFormat) {

			if (useMultisampledRTT(renderTarget)) {

				multisampledRTTExt.framebufferTexture2DMultisampleEXT(_gl.FRAMEBUFFER, _gl.DEPTH_STENCIL_ATTACHMENT, _gl.TEXTURE_2D, webglDepthTexture, 0, samples);

			} else {

				_gl.framebufferTexture2D(_gl.FRAMEBUFFER, _gl.DEPTH_STENCIL_ATTACHMENT, _gl.TEXTURE_2D, webglDepthTexture, 0);

			}

		} else {

			throw new Error('Unknown depthTexture format');

		}

	}

	// Setup GL resources for a non-texture depth buffer
	function setupDepthRenderbuffer(renderTarget: Dynamic) {

		const renderTargetProperties = _properties.get(renderTarget);
		const isCube = (renderTarget.isWebGLCubeRenderTarget == true);

		if (renderTarget.depthTexture != null && !renderTargetProperties.__autoAllocateDepthBuffer) {

			if (isCube) throw new Error('target.depthTexture not supported in Cube render targets');

			setupDepthTexture(renderTargetProperties.__webglFramebuffer, renderTarget);

		} else {

			if (isCube) {

				renderTargetProperties.__webglDepthbuffer = [];

				for (var i = 0; i < 6; i++) {

					_state.bindFramebuffer(_gl.FRAMEBUFFER, renderTargetProperties.__webglFramebuffer[i]);
					renderTargetProperties.__webglDepthbuffer[i] = _gl.createRenderbuffer();
					setupRenderBufferStorage(renderTargetProperties.__webglDepthbuffer[i], renderTarget, false);

				}

			} else {

				_state.bindFramebuffer(_gl.FRAMEBUFFER, renderTargetProperties.__webglFramebuffer);
				renderTargetProperties.__webglDepthbuffer = _gl.createRenderbuffer();
				setupRenderBufferStorage(renderTargetProperties.__webglDepthbuffer, renderTarget, false);

			}

		}

		_state.bindFramebuffer(_gl.FRAMEBUFFER, null);

	}

	// rebind framebuffer with external textures
	function rebindTextures(renderTarget: Dynamic, colorTexture: Dynamic, depthTexture: Dynamic) {

		const renderTargetProperties = _properties.get(renderTarget);

		if (colorTexture != null) {

			setupFrameBufferTexture(renderTargetProperties.__webglFramebuffer, renderTarget, renderTarget.texture, _gl.COLOR_ATTACHMENT0, _gl.TEXTURE_2D, 0);

		}

		if (depthTexture != null) {

			setupDepthRenderbuffer(renderTarget);

		}

	}

	// Set up GL resources for the render target
	function setupRenderTarget(renderTarget: Dynamic) {

		const texture = renderTarget.texture;

		const renderTargetProperties = _properties.get(renderTarget);
		const textureProperties = _properties.get(texture);

		renderTarget.addEventListener('dispose', onRenderTargetDispose);

		const textures = renderTarget.textures;

		const isCube = (renderTarget.isWebGLCubeRenderTarget == true);
		const isMultipleRenderTargets = (textures.length > 1);

		if (!isMultipleRenderTargets) {

			if (textureProperties.__webglTexture == null) {

				textureProperties.__webglTexture = _gl.createTexture();

			}

			textureProperties.__version = texture.version;
			_info.memory.textures++;

		}

		// Setup framebuffer

		if (isCube) {

			renderTargetProperties.__webglFramebuffer = [];

			for (var i = 0; i < 6; i++) {

				if (texture.mipmaps != null && texture.mipmaps.length > 0) {

					renderTargetProperties.__webglFramebuffer[i] = [];

					for (var level = 0; level < texture.mipmaps.length; level++) {

						renderTargetProperties.__webglFramebuffer[i][level] = _gl.createFramebuffer();

					}

				} else {

					renderTargetProperties.__webglFramebuffer[i] = _gl.createFramebuffer();

				}

			}

		} else {

			if (texture.mipmaps != null && texture.mipmaps.length > 0) {

				renderTargetProperties.__webglFramebuffer = [];

				for (var level = 0; level < texture.mipmaps.length; level++) {

					renderTargetProperties.__webglFramebuffer[level] = _gl.createFramebuffer();

				}

			} else {

				renderTargetProperties.__webglFramebuffer = _gl.createFramebuffer();

			}

			if (isMultipleRenderTargets) {

				for (var i = 0, il = textures.length; i < il; i++) {

					const attachmentProperties = _properties.get(textures[i]);

					if (attachmentProperties.__webglTexture == null) {

						attachmentProperties.__webglTexture = _gl.createTexture();

						_info.memory.textures++;

					}

				}

			}

			if ((renderTarget.samples > 0) && useMultisampledRTT(renderTarget) == false) {

				renderTargetProperties.__webglMultisampledFramebuffer = _gl.createFramebuffer();
				renderTargetProperties.__webglColorRenderbuffer = [];

				_state.bindFramebuffer(_gl.FRAMEBUFFER, renderTargetProperties.__webglMultisampledFramebuffer);

				for (var i = 0; i < textures.length; i++) {

					const texture = textures[i];
					renderTargetProperties.__webglColorRenderbuffer[i] = _gl.createRenderbuffer();

					_gl.bindRenderbuffer(_gl.RENDERBUFFER, renderTargetProperties.__webglColorRenderbuffer[i]);

					const glFormat = _utils.convert(texture.format, texture.colorSpace);
					const glType = _utils.convert(texture.type);
					const glInternalFormat = getInternalFormat(texture.internalFormat, glFormat, glType, texture.colorSpace, renderTarget.isXRRenderTarget == true);
					const samples = getRenderTargetSamples(renderTarget);
					_gl.renderbufferStorageMultisample(_gl.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height);

					_gl.framebufferRenderbuffer(_gl.FRAMEBUFFER, _gl.COLOR_ATTACHMENT0 + i, _gl.RENDERBUFFER, renderTargetProperties.__webglColorRenderbuffer[i]);

				}

				_gl.bindRenderbuffer(_gl.RENDERBUFFER, null);

				if (renderTarget.depthBuffer) {

					renderTargetProperties.__webglDepthRenderbuffer = _gl.createRenderbuffer();
					setupRenderBufferStorage(renderTargetProperties.__webglDepthRenderbuffer, renderTarget, true);

				}

				_state.bindFramebuffer(_gl.FRAMEBUFFER, null);

			}

		}

		// Setup color buffer

		if (isCube) {

			_state.bindTexture(_gl.TEXTURE_CUBE_MAP, textureProperties.__webglTexture);
			setTextureParameters(_gl.TEXTURE_CUBE_MAP, texture);

			for (var i = 0; i < 6; i++) {

				if (texture.mipmaps != null && texture.mipmaps.length > 0) {

					for (var level = 0; level < texture.mipmaps.length; level++) {

						setupFrameBufferTexture(renderTargetProperties.__webglFramebuffer[i][level], renderTarget, texture, _gl.COLOR_ATTACHMENT0, _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, level);

					}

				} else {

					setupFrameBufferTexture(renderTargetProperties.__webglFramebuffer[i], renderTarget, texture, _gl.COLOR_ATTACHMENT0, _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0);

				}

			}

			if (textureNeedsGenerateMipmaps(texture)) {

				generateMipmap(_gl.TEXTURE_CUBE_MAP);

			}

			_state.unbindTexture();

		} else if (isMultipleRenderTargets) {

			for (var i = 0, il = textures.length; i < il; i++) {

				const attachment = textures[i];
				const attachmentProperties = _properties.get(attachment);

				_state.bindTexture(_gl.TEXTURE_2D, attachmentProperties.__webglTexture);
				setTextureParameters(_gl.TEXTURE_2D, attachment);
				setupFrameBufferTexture(renderTargetProperties.__webglFramebuffer, renderTarget, attachment, _gl.COLOR_ATTACHMENT0 + i, _gl.TEXTURE_2D, 0);

				if (textureNeedsGenerateMipmaps(attachment)) {

					generateMipmap(_gl.TEXTURE_2D);

				}

			}

			_state.unbindTexture();

		} else {

			var glTextureType = _gl.TEXTURE_2D;

			if (renderTarget.isWebGL3DRenderTarget || renderTarget.isWebGLArrayRenderTarget) {

				glTextureType = renderTarget.isWebGL3DRenderTarget ? _gl.TEXTURE_3D : _gl.TEXTURE_2D_ARRAY;

			}

			_state.bindTexture(glTextureType, textureProperties.__webglTexture);
			setTextureParameters(glTextureType, texture);

			if (texture.mipmaps != null && texture.mipmaps.length > 0) {

				for (var level = 0; level < texture.mipmaps.length; level++) {

					setupFrameBufferTexture(renderTargetProperties.__webglFramebuffer[level], renderTarget, texture, _gl.COLOR_ATTACHMENT0, glTextureType, level);

				}

			} else {

				setupFrameBufferTexture(renderTargetProperties.__webglFramebuffer, renderTarget, texture, _gl.COLOR_ATTACHMENT0, glTextureType, 0);

			}

			if (textureNeedsGenerateMipmaps(texture)) {

				generateMipmap(glTextureType);

			}

			_state.unbindTexture();

		}

		// Setup depth and stencil buffers

		if (renderTarget.depthBuffer) {

			setupDepthRenderbuffer(renderTarget);

		}

	}

	function updateRenderTargetMipmap(renderTarget: Dynamic) {

		const textures = renderTarget.textures;

		for (var i = 0, il = textures.length; i < il; i++) {

			const texture = textures[i];

			if (textureNeedsGenerateMipmaps(texture)) {

				const target = renderTarget.isWebGLCubeRenderTarget ? _gl.TEXTURE_CUBE_MAP : _gl.TEXTURE_2D;
				const webglTexture = _properties.get(texture).__webglTexture;

				_state.bindTexture(target, webglTexture);
				generateMipmap(target);
				_state.unbindTexture();

			}

		}

	}

	var invalidationArrayRead: Array<Int> = [];
	var invalidationArrayDraw: Array<Int> = [];

	function updateMultisampleRenderTarget(renderTarget: Dynamic) {

		if (renderTarget.samples > 0) {

			if (useMultisampledRTT(renderTarget) == false) {

				const textures = renderTarget.textures;
				const width = renderTarget.width;
				const height = renderTarget.height;
				var mask = _gl.COLOR_BUFFER_BIT;
				const depthStyle = renderTarget.stencilBuffer ? _gl.DEPTH_STENCIL_ATTACHMENT : _gl.DEPTH_ATTACHMENT;
				const renderTargetProperties = _properties.get(renderTarget);
				const isMultipleRenderTargets = (textures.length > 1);

				// If MRT we need to remove FBO attachments
				if (isMultipleRenderTargets) {

					for (var i = 0; i < textures.length; i++) {

						_state.bindFramebuffer(_gl.FRAMEBUFFER, renderTargetProperties.__webglMultisampledFramebuffer);
						_gl.framebufferRenderbuffer(_gl.FRAMEBUFFER, _gl.COLOR_ATTACHMENT0 + i, _gl.RENDERBUFFER, null);

						_state.bindFramebuffer(_gl.FRAMEBUFFER, renderTargetProperties.__webglFramebuffer);
						_gl.framebufferTexture2D(_gl.DRAW_FRAMEBUFFER, _gl.COLOR_ATTACHMENT0 + i, _gl.TEXTURE_2D, null, 0);

					}

				}

				_state.bindFramebuffer(_gl.READ_FRAMEBUFFER, renderTargetProperties.__webglMultisampledFramebuffer);
				_state.bindFramebuffer(_gl.DRAW_FRAMEBUFFER, renderTargetProperties.__webglFramebuffer);

				for (var i = 0; i < textures.length; i++) {

					if (renderTarget.resolveDepthBuffer) {

						if (renderTarget.depthBuffer) mask |= _gl.DEPTH_BUFFER_BIT;

						// resolving stencil is slow with a D3D backend. disable it for all transmission render targets (see #27799)

						if (renderTarget.stencilBuffer && renderTarget.resolveStencilBuffer) mask |= _gl.STENCIL_BUFFER_BIT;

					}

					if (isMultipleRenderTargets) {

						_gl.framebufferRenderbuffer(_gl.READ_FRAMEBUFFER, _gl.COLOR_ATTACHMENT0, _gl.RENDERBUFFER, renderTargetProperties.__webglColorRenderbuffer[i]);

						const webglTexture = _properties.get(textures[i]).__webglTexture;
						_gl.framebufferTexture2D(_gl.DRAW_FRAMEBUFFER, _gl.COLOR_ATTACHMENT0, _gl.TEXTURE_2D, webglTexture, 0);

					}

					_gl.blitFramebuffer(0, 0, width, height, 0, 0, width, height, mask, _gl.NEAREST);

					if (supportsInvalidateFramebuffer) {

						invalidationArrayRead.length = 0;
						invalidationArrayDraw.length = 0;

						invalidationArrayRead.push(_gl.COLOR_ATTACHMENT0 + i);

						if (renderTarget.depthBuffer && renderTarget.resolveDepthBuffer == false) {

							invalidationArrayRead.push(depthStyle);
							invalidationArrayDraw.push(depthStyle);

							_gl.invalidateFramebuffer(_gl.DRAW_FRAMEBUFFER, invalidationArrayDraw);

						}

						_gl.invalidateFramebuffer(_gl.READ_FRAMEBUFFER, invalidationArrayRead);

					}

				}

				_state.bindFramebuffer(_gl.READ_FRAMEBUFFER, null);
				_state.bindFramebuffer(_gl.DRAW_FRAMEBUFFER, null);

				// If MRT since pre-blit we removed the FBO we need to reconstruct the attachments
				if (isMultipleRenderTargets) {

					for (var i = 0; i < textures.length; i++) {

						_state.bindFramebuffer(_gl.FRAMEBUFFER, renderTargetProperties.__webglMultisampledFramebuffer);
						_gl.framebufferRenderbuffer(_gl.FRAMEBUFFER, _gl.COLOR_ATTACHMENT0 + i, _gl.RENDERBUFFER, renderTargetProperties.__webglColorRenderbuffer[i]);

						const webglTexture = _properties.get(textures[i]).__webglTexture;

						_state.bindFramebuffer(_gl.FRAMEBUFFER, renderTargetProperties.__webglFramebuffer);
						_gl.framebufferTexture2D(_gl.DRAW_FRAMEBUFFER, _gl.COLOR_ATTACHMENT0 + i, _gl.TEXTURE_2D, webglTexture, 0);

					}

				}

				_state.bindFramebuffer(_gl.DRAW_FRAMEBUFFER, renderTargetProperties.__webglMultisampledFramebuffer);

			} else {

				if (renderTarget.depthBuffer && renderTarget.resolveDepthBuffer == false && supportsInvalidateFramebuffer) {

					const depthStyle = renderTarget.stencilBuffer ? _gl.DEPTH_STENCIL_ATTACHMENT : _gl.DEPTH_ATTACHMENT;

					_gl.invalidateFramebuffer(_gl.DRAW_FRAMEBUFFER, [depthStyle]);

				}

			}

		}

	}

	function getRenderTargetSamples(renderTarget: Dynamic): Int {

		return Math.min(_capabilities.maxSamples, renderTarget.samples);

	}

	function useMultisampledRTT(renderTarget: Dynamic): Bool {

		const renderTargetProperties = _properties.get(renderTarget);

		return renderTarget.samples > 0 && _extensions.exists("WEBGL_multisampled_render_to_texture") && renderTargetProperties.__useRenderToTexture != false;

	}

	function updateVideoTexture(texture: Dynamic) {

		const frame = _info.render.frame;

		// Check the last frame we updated the VideoTexture

		if (_videoTextures.get(texture) != frame) {

			_videoTextures.set(texture, frame);
			texture.update();

		}

	}

	function
		if (_videoTextures.get(texture) != frame) {

			_videoTextures.set(texture, frame);
			texture.update();

		}

	}

	function verifyColorSpace(texture: Dynamic, image: Dynamic): Dynamic {

		const colorSpace = texture.colorSpace;
		const format = texture.format;
		const type = texture.type;

		if (texture.isCompressedTexture || texture.isVideoTexture) return image;

		if (colorSpace != LinearSRGBColorSpace && colorSpace != NoColorSpace) {

			// sRGB

			if (ColorManagement.getTransfer(colorSpace) == SRGBTransfer) {

				// in WebGL 2 uncompressed textures can only be sRGB encoded if they have the RGBA8 format

				if (format != RGBAFormat || type != UnsignedByteType) {

					console.warn('THREE.WebGLTextures: sRGB encoded textures have to use RGBAFormat and UnsignedByteType.');

				}

			} else {

				console.error('THREE.WebGLTextures: Unsupported texture color space:', colorSpace);

			}

		}

		return image;

	}

	function getDimensions(image: Dynamic): Vector2 {

		if (typeof HTMLImageElement != 'undefined' && Std.is(image, HTMLImageElement)) {

			// if intrinsic data are not available, fallback to width/height

			_imageDimensions.width = image.naturalWidth != null ? image.naturalWidth : image.width;
			_imageDimensions.height = image.naturalHeight != null ? image.naturalHeight : image.height;

		} else if (typeof VideoFrame != 'undefined' && Std.is(image, VideoFrame)) {

			_imageDimensions.width = image.displayWidth;
			_imageDimensions.height = image.displayHeight;

		} else {

			_imageDimensions.width = image.width;
			_imageDimensions.height = image.height;

		}

		return _imageDimensions;

	}

	//

	public function allocateTextureUnit(): Int {
		return allocateTextureUnit();
	}

	public function resetTextureUnits() {
		resetTextureUnits();
	}

	public function setTexture2D(texture: Dynamic, slot: Int) {
		setTexture2D(texture, slot);
	}

	public function setTexture2DArray(texture: Dynamic, slot: Int) {
		setTexture2DArray(texture, slot);
	}

	public function setTexture3D(texture: Dynamic, slot: Int) {
		setTexture3D(texture, slot);
	}

	public function setTextureCube(texture: Dynamic, slot: Int) {
		setTextureCube(texture, slot);
	}

	public function rebindTextures(renderTarget: Dynamic, colorTexture: Dynamic, depthTexture: Dynamic) {
		rebindTextures(renderTarget, colorTexture, depthTexture);
	}

	public function setupRenderTarget(renderTarget: Dynamic) {
		setupRenderTarget(renderTarget);
	}

	public function updateRenderTargetMipmap(renderTarget: Dynamic) {
		updateRenderTargetMipmap(renderTarget);
	}

	public function updateMultisampleRenderTarget(renderTarget: Dynamic) {
		updateMultisampleRenderTarget(renderTarget);
	}

	public function setupDepthRenderbuffer(renderTarget: Dynamic) {
		setupDepthRenderbuffer(renderTarget);
	}

	public function setupFrameBufferTexture(framebuffer: Dynamic, renderTarget: Dynamic, texture: Dynamic, attachment: Int, textureTarget: Int, level: Int) {
		setupFrameBufferTexture(framebuffer, renderTarget, texture, attachment, textureTarget, level);
	}

	public function useMultisampledRTT(renderTarget: Dynamic): Bool {
		return useMultisampledRTT(renderTarget);
	}

}

export { WebGLTextures };