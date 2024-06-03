import DataMap from './DataMap';

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
	var renderer:Renderer;
	var backend:Backend;
	var info:Info;

	public function new(renderer:Renderer, backend:Backend, info:Info) {
		super();
		this.renderer = renderer;
		this.backend = backend;
		this.info = info;
	}

	public function updateRenderTarget(renderTarget:RenderTarget, activeMipmapLevel:Int = 0) {
		var renderTargetData:Dynamic = this.get(renderTarget);

		var sampleCount:Int = renderTarget.samples === 0 ? 1 : renderTarget.samples;
		var depthTextureMips:haxe.ds.StringMap<DepthTexture> = renderTargetData.depthTextureMips || (renderTargetData.depthTextureMips = new haxe.ds.StringMap<DepthTexture>());

		var texture:Texture = renderTarget.texture;
		var textures:Array<Texture> = renderTarget.textures;

		var size:Vector3 = this.getSize(texture);

		var mipWidth:Int = size.x >> activeMipmapLevel;
		var mipHeight:Int = size.y >> activeMipmapLevel;

		var depthTexture:DepthTexture = renderTarget.depthTexture || depthTextureMips.get(Std.string(activeMipmapLevel));
		var textureNeedsUpdate:Bool = false;

		if (depthTexture == null) {
			depthTexture = new DepthTexture();
			depthTexture.format = renderTarget.stencilBuffer ? DepthStencilFormat : DepthFormat;
			depthTexture.type = renderTarget.stencilBuffer ? UnsignedInt248Type : UnsignedIntType; // FloatType
			depthTexture.image.width = mipWidth;
			depthTexture.image.height = mipHeight;

			depthTextureMips.set(Std.string(activeMipmapLevel), depthTexture);
		}

		if (renderTargetData.width != size.x || size.y != renderTargetData.height) {
			textureNeedsUpdate = true;
			depthTexture.needsUpdate = true;

			depthTexture.image.width = mipWidth;
			depthTexture.image.height = mipHeight;
		}

		renderTargetData.width = size.x;
		renderTargetData.height = size.y;
		renderTargetData.textures = textures;
		renderTargetData.depthTexture = depthTexture;
		renderTargetData.depth = renderTarget.depthBuffer;
		renderTargetData.stencil = renderTarget.stencilBuffer;
		renderTargetData.renderTarget = renderTarget;

		if (renderTargetData.sampleCount != sampleCount) {
			textureNeedsUpdate = true;
			depthTexture.needsUpdate = true;

			renderTargetData.sampleCount = sampleCount;
		}

		var options:Dynamic = { sampleCount: sampleCount };

		for (i in 0...textures.length) {
			var texture:Texture = textures[i];

			if (textureNeedsUpdate) texture.needsUpdate = true;

			this.updateTexture(texture, options);
		}

		this.updateTexture(depthTexture, options);

		if (renderTargetData.initialized != true) {
			renderTargetData.initialized = true;

			renderTarget.addEventListener('dispose', function() {
				if (textures != null) {
					for (i in 0...textures.length) {
						this._destroyTexture(textures[i]);
					}
				} else {
					this._destroyTexture(texture);
				}

				this._destroyTexture(depthTexture);
			});
		}
	}

	public function updateTexture(texture:Texture, options:Dynamic = null) {
		if (options == null) options = {};
		var textureData:Dynamic = this.get(texture);
		if (textureData.initialized == true && textureData.version == texture.version) return;

		var isRenderTarget:Bool = texture.isRenderTargetTexture || texture.isDepthTexture || texture.isFramebufferTexture;

		if (isRenderTarget && textureData.initialized == true) {
			this.backend.destroySampler(texture);
			this.backend.destroyTexture(texture);
		}

		if (texture.isFramebufferTexture) {
			var renderTarget:RenderTarget = this.renderer.getRenderTarget();

			if (renderTarget != null) {
				texture.type = renderTarget.texture.type;
			} else {
				texture.type = UnsignedByteType;
			}
		}

		var image:Dynamic = texture.images != null ? texture.images[0] : texture.image;

		if (image != null) {
			if (image.image != null) image = image.image;
			options.width = image.width;
			options.height = image.height;
			options.depth = texture.isCubeTexture ? 6 : (image.depth || 1);
		} else {
			options.width = options.height = options.depth = 1;
		}

		options.needsMipmaps = this.needsMipmaps(texture);
		options.levels = options.needsMipmaps ? this.getMipLevels(texture, options.width, options.height) : 1;

		if (isRenderTarget || texture.isStorageTexture == true) {
			this.backend.createSampler(texture);
			this.backend.createTexture(texture, options);
		} else {
			var needsCreate:Bool = textureData.initialized != true;

			if (needsCreate) this.backend.createSampler(texture);

			if (texture.version > 0) {
				var image:Dynamic = texture.image;

				if (image == null) {
					trace('THREE.Renderer: Texture marked for update but image is undefined.');
				} else if (image.complete == false) {
					trace('THREE.Renderer: Texture marked for update but image is incomplete.');
				} else {
					if (texture.images != null) {
						var images:Array<Dynamic> = [];

						for (image in texture.images) {
							images.push(image);
						}

						options.images = images;
					} else {
						options.image = image;
					}

					if (textureData.isDefaultTexture == null || textureData.isDefaultTexture == true) {
						this.backend.createTexture(texture, options);

						textureData.isDefaultTexture = false;
					}

					if (texture.source.dataReady == true) this.backend.updateTexture(texture, options);

					if (options.needsMipmaps && texture.mipmaps.length == 0) this.backend.generateMipmaps(texture);
				}
			} else {
				this.backend.createDefaultTexture(texture);

				textureData.isDefaultTexture = true;
			}
		}

		if (textureData.initialized != true) {
			textureData.initialized = true;

			this.info.memory.textures++;

			texture.addEventListener('dispose', function() {
				this._destroyTexture(texture);

				this.info.memory.textures--;
			});
		}

		textureData.version = texture.version;
	}

	public function getSize(texture:Texture, target:Vector3 = null):Vector3 {
		if (target == null) target = _size;
		var image:Dynamic = texture.images != null ? texture.images[0] : texture.image;

		if (image != null) {
			if (image.image != null) image = image.image;

			target.x = image.width;
			target.y = image.height;
			target.z = texture.isCubeTexture ? 6 : (image.depth || 1);
		} else {
			target.x = target.y = target.z = 1;
		}

		return target;
	}

	public function getMipLevels(texture:Texture, width:Int, height:Int):Int {
		var mipLevelCount:Int;

		if (texture.isCompressedTexture) {
			mipLevelCount = texture.mipmaps.length;
		} else {
			mipLevelCount = Math.floor(Math.log2(Math.max(width, height))) + 1;
		}

		return mipLevelCount;
	}

	public function needsMipmaps(texture:Texture):Bool {
		if (this.isEnvironmentTexture(texture)) return true;

		return (texture.isCompressedTexture == true) || ( (texture.minFilter != NearestFilter) && (texture.minFilter != LinearFilter) );
	}

	public function isEnvironmentTexture(texture:Texture):Bool {
		var mapping:Int = texture.mapping;

		return (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping) || (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);
	}

	public function _destroyTexture(texture:Texture) {
		this.backend.destroySampler(texture);
		this.backend.destroyTexture(texture);

		this.delete(texture);
	}
}