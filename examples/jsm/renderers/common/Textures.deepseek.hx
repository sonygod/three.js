import DataMap from './DataMap.hx';

import three.Vector3;
import three.DepthTexture;
import three.DepthStencilFormat;
import three.DepthFormat;
import three.UnsignedIntType;
import three.UnsignedInt248Type;
import three.LinearFilter;
import three.NearestFilter;
import three.EquirectangularReflectionMapping;
import three.EquirectangularRefractionMapping;
import three.CubeReflectionMapping;
import three.CubeRefractionMapping;
import three.UnsignedByteType;

class Textures extends DataMap {

	var _size:Vector3 = new Vector3();

	public function new(renderer:Dynamic, backend:Dynamic, info:Dynamic) {
		super();
		this.renderer = renderer;
		this.backend = backend;
		this.info = info;
	}

	public function updateRenderTarget(renderTarget:Dynamic, activeMipmapLevel:Int = 0) {
		var renderTargetData = this.get(renderTarget);
		var sampleCount = renderTarget.samples === 0 ? 1 : renderTarget.samples;
		var depthTextureMips = renderTargetData.depthTextureMips || (renderTargetData.depthTextureMips = {});
		var texture = renderTarget.texture;
		var textures = renderTarget.textures;
		var size = this.getSize(texture);
		var mipWidth = size.width >> activeMipmapLevel;
		var mipHeight = size.height >> activeMipmapLevel;
		var depthTexture = renderTarget.depthTexture || depthTextureMips[activeMipmapLevel];
		var textureNeedsUpdate = false;
		if (depthTexture === undefined) {
			depthTexture = new DepthTexture();
			depthTexture.format = renderTarget.stencilBuffer ? DepthStencilFormat : DepthFormat;
			depthTexture.type = renderTarget.stencilBuffer ? UnsignedInt248Type : UnsignedIntType;
			depthTexture.image.width = mipWidth;
			depthTexture.image.height = mipHeight;
			depthTextureMips[activeMipmapLevel] = depthTexture;
		}
		if (renderTargetData.width !== size.width || size.height !== renderTargetData.height) {
			textureNeedsUpdate = true;
			depthTexture.needsUpdate = true;
			depthTexture.image.width = mipWidth;
			depthTexture.image.height = mipHeight;
		}
		renderTargetData.width = size.width;
		renderTargetData.height = size.height;
		renderTargetData.textures = textures;
		renderTargetData.depthTexture = depthTexture;
		renderTargetData.depth = renderTarget.depthBuffer;
		renderTargetData.stencil = renderTarget.stencilBuffer;
		renderTargetData.renderTarget = renderTarget;
		if (renderTargetData.sampleCount !== sampleCount) {
			textureNeedsUpdate = true;
			depthTexture.needsUpdate = true;
			renderTargetData.sampleCount = sampleCount;
		}
		var options = {sampleCount: sampleCount};
		for (i in 0...textures.length) {
			var texture = textures[i];
			if (textureNeedsUpdate) texture.needsUpdate = true;
			this.updateTexture(texture, options);
		}
		this.updateTexture(depthTexture, options);
		if (renderTargetData.initialized !== true) {
			renderTargetData.initialized = true;
			var onDispose = function() {
				renderTarget.removeEventListener('dispose', onDispose);
				if (textures !== undefined) {
					for (i in 0...textures.length) {
						this._destroyTexture(textures[i]);
					}
				} else {
					this._destroyTexture(texture);
				}
				this._destroyTexture(depthTexture);
			};
			renderTarget.addEventListener('dispose', onDispose);
		}
	}

	public function updateTexture(texture:Dynamic, options:Dynamic = {}) {
		var textureData = this.get(texture);
		if (textureData.initialized === true && textureData.version === texture.version) return;
		var isRenderTarget = texture.isRenderTargetTexture || texture.isDepthTexture || texture.isFramebufferTexture;
		var backend = this.backend;
		if (isRenderTarget && textureData.initialized === true) {
			backend.destroySampler(texture);
			backend.destroyTexture(texture);
		}
		if (texture.isFramebufferTexture) {
			var renderer = this.renderer;
			var renderTarget = renderer.getRenderTarget();
			if (renderTarget) {
				texture.type = renderTarget.texture.type;
			} else {
				texture.type = UnsignedByteType;
			}
		}
		var {width, height, depth} = this.getSize(texture);
		options.width = width;
		options.height = height;
		options.depth = depth;
		options.needsMipmaps = this.needsMipmaps(texture);
		options.levels = options.needsMipmaps ? this.getMipLevels(texture, width, height) : 1;
		if (isRenderTarget || texture.isStorageTexture === true) {
			backend.createSampler(texture);
			backend.createTexture(texture, options);
		} else {
			var needsCreate = textureData.initialized !== true;
			if (needsCreate) backend.createSampler(texture);
			if (texture.version > 0) {
				var image = texture.images ? texture.images[0] : texture.image;
				if (image === undefined) {
					trace('THREE.Renderer: Texture marked for update but image is undefined.');
				} else if (image.complete === false) {
					trace('THREE.Renderer: Texture marked for update but image is incomplete.');
				} else {
					if (texture.images) {
						var images = [];
						for (image in texture.images) {
							images.push(image);
						}
						options.images = images;
					} else {
						options.image = image;
					}
					if (textureData.isDefaultTexture === undefined || textureData.isDefaultTexture === true) {
						backend.createTexture(texture, options);
						textureData.isDefaultTexture = false;
					}
					if (texture.source.dataReady === true) backend.updateTexture(texture, options);
					if (options.needsMipmaps && texture.mipmaps.length === 0) backend.generateMipmaps(texture);
				}
			} else {
				backend.createDefaultTexture(texture);
				textureData.isDefaultTexture = true;
			}
		}
		if (textureData.initialized !== true) {
			textureData.initialized = true;
			this.info.memory.textures++;
			var onDispose = function() {
				texture.removeEventListener('dispose', onDispose);
				this._destroyTexture(texture);
				this.info.memory.textures--;
			};
			texture.addEventListener('dispose', onDispose);
		}
		textureData.version = texture.version;
	}

	public function getSize(texture:Dynamic, target:Vector3 = _size):Vector3 {
		var image = texture.images ? texture.images[0] : texture.image;
		if (image) {
			if (image.image !== undefined) image = image.image;
			target.width = image.width;
			target.height = image.height;
			target.depth = texture.isCubeTexture ? 6 : (image.depth || 1);
		} else {
			target.width = target.height = target.depth = 1;
		}
		return target;
	}

	public function getMipLevels(texture:Dynamic, width:Int, height:Int):Int {
		var mipLevelCount:Int;
		if (texture.isCompressedTexture) {
			mipLevelCount = texture.mipmaps.length;
		} else {
			mipLevelCount = Math.floor(Math.log2(Math.max(width, height))) + 1;
		}
		return mipLevelCount;
	}

	public function needsMipmaps(texture:Dynamic):Bool {
		if (this.isEnvironmentTexture(texture)) return true;
		return (texture.isCompressedTexture === true) || ((texture.minFilter !== NearestFilter) && (texture.minFilter !== LinearFilter));
	}

	public function isEnvironmentTexture(texture:Dynamic):Bool {
		var mapping = texture.mapping;
		return (mapping === EquirectangularReflectionMapping || mapping === EquirectangularRefractionMapping) || (mapping === CubeReflectionMapping || mapping === CubeRefractionMapping);
	}

	public function _destroyTexture(texture:Dynamic) {
		this.backend.destroySampler(texture);
		this.backend.destroyTexture(texture);
		this.delete(texture);
	}

}