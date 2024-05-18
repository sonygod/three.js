package three.js.examples.jvm.renderers.common;

import three.js.DataMap;

import three.js.Vector3;
import three.js.DepthTexture;
import three.js.DepthStencilFormat;
import three.js.DepthFormat;
import three.js.UnsignedIntType;
import three.js.UnsignedInt248Type;
import three.js.LinearFilter;
import three.js.NearestFilter;
import three.js.EquirectangularReflectionMapping;
import three.js.EquirectangularRefractionMapping;
import three.js.CubeReflectionMapping;
import three.js.CubeRefractionMapping;
import three.js.UnsignedByteType;

class Textures extends DataMap {
    private var _size:Vector3;

    public function new(renderer: Renderer, backend: Backend, info: Info) {
        super();
        this.renderer = renderer;
        this.backend = backend;
        this.info = info;
        _size = new Vector3();
    }

    public function updateRenderTarget(renderTarget: RenderTarget, activeMipmapLevel: Int = 0) {
        var renderTargetData: Dynamic = get(renderTarget);
        var sampleCount: Int = renderTarget.samples == 0 ? 1 : renderTarget.samples;
        var depthTextureMips: Dynamic = renderTargetData.depthTextureMips || (renderTargetData.depthTextureMips = {});
        var texture: Texture = renderTarget.texture;
        var textures: Array<Texture> = renderTarget.textures;
        var size: Vector3 = getSize(texture);
        var mipWidth: Int = size.width >> activeMipmapLevel;
        var mipHeight: Int = size.height >> activeMipmapLevel;
        var depthTexture: DepthTexture = renderTarget.depthTexture || depthTextureMips[activeMipmapLevel];
        var textureNeedsUpdate: Bool = false;

        if (depthTexture == null) {
            depthTexture = new DepthTexture();
            depthTexture.format = renderTarget.stencilBuffer ? DepthStencilFormat : DepthFormat;
            depthTexture.type = renderTarget.stencilBuffer ? UnsignedInt248Type : UnsignedIntType; // FloatType
            depthTexture.image.width = mipWidth;
            depthTexture.image.height = mipHeight;
            depthTextureMips[activeMipmapLevel] = depthTexture;
        }

        if (renderTargetData.width != size.width || size.height != renderTargetData.height) {
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

        if (renderTargetData.sampleCount != sampleCount) {
            textureNeedsUpdate = true;
            depthTexture.needsUpdate = true;
            renderTargetData.sampleCount = sampleCount;
        }

        var options: Dynamic = { sampleCount: sampleCount };

        for (i in 0...textures.length) {
            var texture: Texture = textures[i];
            if (textureNeedsUpdate) texture.needsUpdate = true;
            updateTexture(texture, options);
        }

        updateTexture(depthTexture, options);

        // dispose handler
        if (!renderTargetData.initialized) {
            renderTargetData.initialized = true;

            // dispose
            var onDispose: Void -> Void = () -> {
                renderTarget.removeEventListener('dispose', onDispose);
                if (textures != null) {
                    for (i in 0...textures.length) {
                        _destroyTexture(textures[i]);
                    }
                } else {
                    _destroyTexture(texture);
                }
                _destroyTexture(depthTexture);
            };
            renderTarget.addEventListener('dispose', onDispose);
        }
    }

    public function updateTexture(texture: Texture, options: Dynamic = {}): Void {
        var textureData: Dynamic = get(texture);
        if (textureData.initialized && textureData.version == texture.version) return;

        var isRenderTarget: Bool = texture.isRenderTargetTexture || texture.isDepthTexture || texture.isFramebufferTexture;
        var backend: Backend = this.backend;

        if (isRenderTarget && textureData.initialized) {
            // it's an update
            backend.destroySampler(texture);
            backend.destroyTexture(texture);
        }

        // ...

        var width: Int = 0;
        var height: Int = 0;
        var depth: Int = 0;
        if (texture.isFramebufferTexture) {
            var renderer: Renderer = this.renderer;
            var renderTarget: RenderTarget = renderer.getRenderTarget();
            if (renderTarget) {
                texture.type = renderTarget.texture.type;
            } else {
                texture.type = UnsignedByteType;
            }
        }

        var needsMipmaps: Bool = needsMipmaps(texture);
        var levels: Int = needsMipmaps ? getMipLevels(texture, width, height) : 1;

        options.width = width;
        options.height = height;
        options.depth = depth;
        options.needsMipmaps = needsMipmaps;
        options.levels = levels;

        if (isRenderTarget || texture.isStorageTexture) {
            backend.createSampler(texture);
            backend.createTexture(texture, options);
        } else {
            var needsCreate: Bool = !textureData.initialized;
            if (needsCreate) backend.createSampler(texture);

            if (texture.version > 0) {
                var image: Dynamic = texture.image;
                if (image == null) {
                    Console.warn('THREE.Renderer: Texture marked for update but image is undefined.');
                } else if (!image.complete) {
                    Console.warn('THREE.Renderer: Texture marked for update but image is incomplete.');
                } else {
                    if (texture.images != null) {
                        var images: Array<Dynamic> = [];
                        for (image in texture.images) {
                            images.push(image);
                        }
                        options.images = images;
                    } else {
                        options.image = image;
                    }

                    if (textureData.isDefaultTexture == null || textureData.isDefaultTexture) {
                        backend.createTexture(texture, options);
                        textureData.isDefaultTexture = false;
                    }

                    if (texture.source.dataReady) backend.updateTexture(texture, options);

                    if (needsMipmaps && texture.mipmaps.length == 0) backend.generateMipmaps(texture);
                }
            } else {
                // async update
                backend.createDefaultTexture(texture);
                textureData.isDefaultTexture = true;
            }
        }

        // dispose handler
        if (!textureData.initialized) {
            textureData.initialized = true;
            // dispose
            var onDispose: Void -> Void = () -> {
                texture.removeEventListener('dispose', onDispose);
                _destroyTexture(texture);
                this.info.memory.textures--;
            };
            texture.addEventListener('dispose', onDispose);
        }

        textureData.version = texture.version;
    }

    private function getSize(texture: Texture, target: Vector3 = _size): Vector3 {
        var image: Dynamic = texture.images ? texture.images[0] : texture.image;
        if (image != null) {
            if (image.image != null) image = image.image;
            target.width = image.width;
            target.height = image.height;
            target.depth = texture.isCubeTexture ? 6 : (image.depth || 1);
        } else {
            target.width = target.height = target.depth = 1;
        }
        return target;
    }

    private function getMipLevels(texture: Texture, width: Int, height: Int): Int {
        var mipLevelCount: Int;
        if (texture.isCompressedTexture) {
            mipLevelCount = texture.mipmaps.length;
        } else {
            mipLevelCount = Math.floor(Math.log2(Math.max(width, height))) + 1;
        }
        return mipLevelCount;
    }

    private function needsMipmaps(texture: Texture): Bool {
        if (isEnvironmentTexture(texture)) return true;

        return (texture.isCompressedTexture) || ((texture.minFilter != NearestFilter) && (texture.minFilter != LinearFilter));
    }

    private function isEnvironmentTexture(texture: Texture): Bool {
        var mapping: Dynamic = texture.mapping;
        return (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping) || (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);
    }

    private function _destroyTexture(texture: Texture): Void {
        this.backend.destroySampler(texture);
        this.backend.destroyTexture(texture);
        delete(texture);
    }
}