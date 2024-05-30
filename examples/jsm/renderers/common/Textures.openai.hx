package three.js.renderers.common;

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
    private var renderer:Dynamic;
    private var backend:Dynamic;
    private var info:Dynamic;

    public function new(renderer:Dynamic, backend:Dynamic, info:Dynamic) {
        super();
        this.renderer = renderer;
        this.backend = backend;
        this.info = info;
    }

    public function updateRenderTarget(renderTarget:Dynamic, activeMipmapLevel:Int = 0) {
        var renderTargetData:Dynamic = this.get(renderTarget);

        var sampleCount:Int = renderTarget.samples == 0 ? 1 : renderTarget.samples;
        var depthTextureMips:Dynamic = renderTargetData.depthTextureMips || (renderTargetData.depthTextureMips = {});

        var texture:Dynamic = renderTarget.texture;
        var textures:Array<Dynamic> = renderTarget.textures;

        var size:Vector3 = getSize(texture);

        var mipWidth:Int = size.width >> activeMipmapLevel;
        var mipHeight:Int = size.height >> activeMipmapLevel;

        var depthTexture:Dynamic = renderTarget.depthTexture || depthTextureMips[activeMipmapLevel];
        var textureNeedsUpdate:Bool = false;

        if (depthTexture == null) {
            depthTexture = new DepthTexture();
            depthTexture.format = renderTarget.stencilBuffer ? DepthStencilFormat : DepthFormat;
            depthTexture.type = renderTarget.stencilBuffer ? UnsignedInt248Type : UnsignedIntType;
            depthTexture.image.width = mipWidth;
            depthTexture.image.height = mipHeight;

            depthTextureMips[activeMipmapLevel] = depthTexture;
        }

        if (renderTargetData.width != size.width || renderTargetData.height != size.height) {
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

        var options:Dynamic = { sampleCount: sampleCount };

        for (i in 0...textures.length) {
            var texture:Dynamic = textures[i];

            if (textureNeedsUpdate) texture.needsUpdate = true;

            updateTexture(texture, options);
        }

        updateTexture(depthTexture, options);

        if (!renderTargetData.initialized) {
            renderTargetData.initialized = true;

            var onDispose:Void->Void = function() {
                renderTarget.removeEventListener("dispose", onDispose);

                if (textures != null) {
                    for (i in 0...textures.length) {
                        _destroyTexture(textures[i]);
                    }
                } else {
                    _destroyTexture(texture);
                }

                _destroyTexture(depthTexture);
            };

            renderTarget.addEventListener("dispose", onDispose);
        }
    }

    public function updateTexture(texture:Dynamic, ?options:Dynamic) {
        var textureData:Dynamic = this.get(texture);
        if (textureData.initialized && textureData.version == texture.version) return;

        var isRenderTarget:Bool = texture.isRenderTargetTexture || texture.isDepthTexture || texture.isFramebufferTexture;
        var backend:Dynamic = this.backend;

        if (isRenderTarget && textureData.initialized) {
            backend.destroySampler(texture);
            backend.destroyTexture(texture);
        }

        if (texture.isFramebufferTexture) {
            var renderer:Dynamic = this.renderer;
            var renderTarget:Dynamic = renderer.getRenderTarget();

            if (renderTarget) {
                texture.type = renderTarget.texture.type;

            } else {
                texture.type = UnsignedByteType;
            }
        }

        var size:Vector3 = getSize(texture);
        var width:Int = size.width;
        var height:Int = size.height;
        var depth:Int = size.depth;

        options.width = width;
        options.height = height;
        options.depth = depth;
        options.needsMipmaps = needsMipmaps(texture);
        options.levels = needsMipmaps(texture) ? getMipLevels(texture, width, height) : 1;

        if (isRenderTarget || texture.isStorageTexture) {
            backend.createSampler(texture);
            backend.createTexture(texture, options);

        } else {
            var needsCreate:Bool = !textureData.initialized;

            if (needsCreate) backend.createSampler(texture);

            if (texture.version > 0) {
                var image:Dynamic = texture.image;

                if (image == null) {
                    console.warn("THREE.Renderer: Texture marked for update but image is undefined.");

                } else if (!image.complete) {
                    console.warn("THREE.Renderer: Texture marked for update but image is incomplete.");

                } else {
                    if (texture.images) {
                        var images:Array<Dynamic> = [];

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

                    if (options.needsMipmaps && texture.mipmaps.length == 0) backend.generateMipmaps(texture);
                }
            } else {
                backend.createDefaultTexture(texture);

                textureData.isDefaultTexture = true;
            }
        }

        if (!textureData.initialized) {
            textureData.initialized = true;

            this.info.memory.textures++;

            var onDispose:Void->Void = function() {
                texture.removeEventListener("dispose", onDispose);

                _destroyTexture(texture);

                this.info.memory.textures--;
            };

            texture.addEventListener("dispose", onDispose);
        }

        textureData.version = texture.version;
    }

    private function getSize(texture:Dynamic, ?target:Vector3):Vector3 {
        var image:Dynamic = texture.images ? texture.images[0] : texture.image;

        if (image) {
            if (image.image != null) image = image.image;

            target.width = image.width;
            target.height = image.height;
            target.depth = texture.isCubeTexture ? 6 : (image.depth || 1);

        } else {
            target.width = target.height = target.depth = 1;
        }

        return target;
    }

    private function getMipLevels(texture:Dynamic, width:Int, height:Int):Int {
        var mipLevelCount:Int;

        if (texture.isCompressedTexture) {
            mipLevelCount = texture.mipmaps.length;

        } else {
            mipLevelCount = Math.floor(Math.log2(Math.max(width, height))) + 1;
        }

        return mipLevelCount;
    }

    private function needsMipmaps(texture:Dynamic):Bool {
        if (isEnvironmentTexture(texture)) return true;

        return texture.isCompressedTexture || (texture.minFilter != NearestFilter && texture.minFilter != LinearFilter);
    }

    private function isEnvironmentTexture(texture:Dynamic):Bool {
        var mapping:Int = texture.mapping;

        return (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping) || (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);
    }

    private function _destroyTexture(texture:Dynamic) {
        backend.destroySampler(texture);
        backend.destroyTexture(texture);

        this.delete(texture);
    }
}