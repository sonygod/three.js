import DataMap from './DataMap.hx';

import Vector3 from 'three/src/math/Vector3';
import DepthTexture from 'three/src/textures/DepthTexture';
import DepthStencilFormat from 'three/src/constants/DepthStencilFormat';
import DepthFormat from 'three/src/constants/DepthFormat';
import UnsignedIntType from 'three/src/constants/UnsignedIntType';
import UnsignedInt248Type from 'three/src/constants/UnsignedInt248Type';
import LinearFilter from 'three/src/constants/LinearFilter';
import NearestFilter from 'three/src/constants/NearestFilter';
import EquirectangularReflectionMapping from 'three/src/constants/EquirectangularReflectionMapping';
import EquirectangularRefractionMapping from 'three/src/constants/EquirectangularRefractionMapping';
import CubeReflectionMapping from 'three/src/constants/CubeReflectionMapping';
import CubeRefractionMapping from 'three/src/constants/CubeRefractionMapping';
import UnsignedByteType from 'three/src/constants/UnsignedByteType';

class Textures extends DataMap {
    public renderer: any;
    public backend: any;
    public info: any;

    public constructor(renderer: any, backend: any, info: any) {
        super();
        this.renderer = renderer;
        this.backend = backend;
        this.info = info;
    }

    public updateRenderTarget(renderTarget: any, activeMipmapLevel: number = 0): void {
        const renderTargetData = this.get(renderTarget);
        const sampleCount = renderTarget.samples === 0 ? 1 : renderTarget.samples;
        const depthTextureMips = renderTargetData.depthTextureMips ?? (renderTargetData.depthTextureMips = {});
        const texture = renderTarget.texture;
        const textures = renderTarget.textures;
        const size = this.getSize(texture);
        const mipWidth = size.width >> activeMipmapLevel;
        const mipHeight = size.height >> activeMipmapLevel;
        let depthTexture = renderTarget.depthTexture ?? depthTextureMips[activeMipmapLevel];
        let textureNeedsUpdate = false;

        if (depthTexture === null) {
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

        const options = { sampleCount };

        for (let i = 0; i < textures.length; i++) {
            const texture = textures[i];
            if (textureNeedsUpdate) texture.needsUpdate = true;
            this.updateTexture(texture, options);
        }

        this.updateTexture(depthTexture, options);

        if (renderTargetData.initialized !== true) {
            renderTargetData.initialized = true;
            const onDispose = function () {
                renderTarget.removeEventListener('dispose', onDispose);
                if (textures !== null) {
                    for (let i = 0; i < textures.length; i++) {
                        this._destroyTexture(textures[i]);
                    }
                } else {
                    this._destroyTexture(texture);
                }
                this._destroyTexture(depthTexture);
            }.bind(this);
            renderTarget.addEventListener('dispose', onDispose);
        }
    }

    public updateTexture(texture: any, options: any = {}): void {
        const textureData = this.get(texture);
        if (textureData.initialized === true && textureData.version === texture.version) return;
        const isRenderTarget = texture.isRenderTargetTexture || texture.isDepthTexture || texture.isFramebufferTexture;
        const backend = this.backend;

        if (isRenderTarget && textureData.initialized === true) {
            backend.destroySampler(texture);
            backend.destroyTexture(texture);
        }

        if (texture.isFramebufferTexture) {
            const renderer = this.renderer;
            const renderTarget = renderer.getRenderTarget();
            if (renderTarget) {
                texture.type = renderTarget.texture.type;
            } else {
                texture.type = UnsignedByteType;
            }
        }

        const { width, height, depth } = this.getSize(texture);
        options.width = width;
        options.height = height;
        options.depth = depth;
        options.needsMipmaps = this.needsMipmaps(texture);
        options.levels = options.needsMipmaps ? this.getMipLevels(texture, width, height) : 1;

        if (isRenderTarget || texture.isStorageTexture === true) {
            backend.createSampler(texture);
            backend.createTexture(texture, options);
        } else {
            const needsCreate = textureData.initialized !== true;
            if (needsCreate) backend.createSampler(texture);

            if (texture.version > 0) {
                const image = texture.image;
                if (image === null) {
                    trace('THREE.Renderer: Texture marked for update but image is null.');
                } else if (image.complete === false) {
                    trace('THREE.Renderer: Texture marked for update but image is incomplete.');
                } else {
                    if (texture.images) {
                        const images = [];
                        for (const image of texture.images) {
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
            const onDispose = function () {
                texture.removeEventListener('dispose', onDispose);
                this._destroyTexture(texture);
                this.info.memory.textures--;
            }.bind(this);
            texture.addEventListener('dispose', onDispose);
        }

        textureData.version = texture.version;
    }

    public getSize(texture: any, target = new Vector3()): Vector3 {
        let image = texture.images ? texture.images[0] : texture.image;
        if (image) {
            if (image.image !== null) image = image.image;
            target.width = image.width;
            target.height = image.height;
            target.depth = texture.isCubeTexture ? 6 : (image.depth ?? 1);
        } else {
            target.width = target.height = target.depth = 1;
        }
        return target;
    }

    public getMipLevels(texture: any, width: number, height: number): number {
        let mipLevelCount;
        if (texture.isCompressedTexture) {
            mipLevelCount = texture.mipmaps.length;
        } else {
            mipLevelCount = Math.floor(Math.log2(Math.max(width, height))) + 1;
        }
        return mipLevelCount;
    }

    public needsMipmaps(texture: any): boolean {
        if (this.isEnvironmentTexture(texture)) return true;
        return texture.isCompressedTexture === true || texture.minFilter !== NearestFilter && texture.minFilter !== LinearFilter;
    }

    public isEnvironmentTexture(texture: any): boolean {
        const mapping = texture.mapping;
        return mapping === EquirectangularReflectionMapping || mapping === EquirectangularRefractionMapping || mapping === CubeReflectionMapping || mapping === CubeRefractionMapping;
    }

    public _destroyTexture(texture: any): void {
        this.backend.destroySampler(texture);
        this.backend.destroyTexture(texture);
        this.delete(texture);
    }
}

export default Textures;