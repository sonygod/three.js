package three.js.examples.jsm.renderers.webgpu;

import greggman.github.io.webgpu_avoid_redundant_state_setting.WebGPUCheckRedundantStateSetting;

import three.WebGPUCoordinateSystem;

import WebGPUConstants.*;

import nodes.WGSLNodeBuilder;
import common.Backend;

import utils.WebGPUUtils;
import utils.WebGPUAttributeUtils;
import utils.WebGPUBindingUtils;
import utils.WebGPUPipelineUtils;
import utils.WebGPUTextureUtils;

class WebGPUBackend extends Backend {
    public var isWebGPUBackend:Bool = true;

    public function new(parameters:Dynamic = {}) {
        super(parameters);

        // some parameters require default values other than "undefined"
        this.parameters.alpha = (parameters.alpha == null) ? true : parameters.alpha;

        this.parameters.antialias = (parameters.antialias == true);

        if (this.parameters.antialias == true) {
            this.parameters.sampleCount = (parameters.sampleCount == null) ? 4 : parameters.sampleCount;
        } else {
            this.parameters.sampleCount = 1;
        }

        this.parameters.requiredLimits = (parameters.requiredLimits == null) ? {} : parameters.requiredLimits;

        this.trackTimestamp = (parameters.trackTimestamp == true);

        this.device = null;
        this.context = null;
        this.colorBuffer = null;
        this.defaultRenderPassdescriptor = null;

        this.utils = new WebGPUUtils(this);
        this.attributeUtils = new WebGPUAttributeUtils(this);
        this.bindingUtils = new WebGPUBindingUtils(this);
        this.pipelineUtils = new WebGPUPipelineUtils(this);
        this.textureUtils = new WebGPUTextureUtils(this);
        this.occludedResolveCache = new Map<String, Dynamic>();
    }

    async function init(renderer:Dynamic) {
        await super.init(renderer);

        // create the device if it is not passed with parameters
        let device;

        if (this.parameters.device == null) {
            const adapterOptions = {
                powerPreference: this.parameters.powerPreference
            };

            const adapter = await navigator.gpu.requestAdapter(adapterOptions);

            if (adapter == null) {
                throw new Error('WebGPUBackend: Unable to create WebGPU adapter.');
            }

            // feature support
            const features = [GPUFeatureName.values()];

            const supportedFeatures = [];

            for (feature in features) {
                if (adapter.features.has(feature)) {
                    supportedFeatures.push(feature);
                }
            }

            const deviceDescriptor = {
                requiredFeatures: supportedFeatures,
                requiredLimits: this.parameters.requiredLimits
            };

            device = await adapter.requestDevice(deviceDescriptor);
        } else {
            device = this.parameters.device;
        }

        const context = (this.parameters.context == null) ? renderer.domElement.getContext('webgpu') : this.parameters.context;

        this.device = device;
        this.context = context;

        const alphaMode = this.parameters.alpha ? 'premultiplied' : 'opaque';

        this.context.configure({
            device: this.device,
            format: GPUTextureFormat.BGRA8Unorm,
            usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.COPY_SRC,
            alphaMode: alphaMode
        });

        this.updateSize();
    }

    public function get_coordinateSystem():WebGPUCoordinateSystem {
        return WebGPUCoordinateSystem;
    }

    async function getArrayBufferAsync(attribute:Dynamic) {
        return await this.attributeUtils.getArrayBufferAsync(attribute);
    }

    public function getContext():Dynamic {
        return this.context;
    }

    function _getDefaultRenderPassDescriptor():Dynamic {
        let descriptor = this.defaultRenderPassdescriptor;

        const antialias = this.parameters.antialias;

        if (descriptor == null) {
            const renderer = this.renderer;

            descriptor = {
                colorAttachments: [{
                    view: null
                }],
                depthStencilAttachment: {
                    view: this.textureUtils.getDepthBuffer(renderer.depth, renderer.stencil).createView()
                }
            };

            const colorAttachment = descriptor.colorAttachments[0];

            if (antialias == true) {
                colorAttachment.view = this.colorBuffer.createView();
            } else {
                colorAttachment.resolveTarget = undefined;
            }

            this.defaultRenderPassdescriptor = descriptor;
        }

        const colorAttachment = descriptor.colorAttachments[0];

        if (antialias == true) {
            colorAttachment.resolveTarget = this.context.getCurrentTexture().createView();
        } else {
            colorAttachment.view = this.context.getCurrentTexture().createView();
        }

        return descriptor;
    }

    function _getRenderPassDescriptor(renderContext:Dynamic) {
        const renderTarget = renderContext.renderTarget;
        const renderTargetData = this.get(renderTarget);

        let descriptors = renderTargetData.descriptors;

        if (descriptors == null) {
            descriptors = [];

            renderTargetData.descriptors = descriptors;
        }

        if (renderTargetData.width != renderTarget.width ||
            renderTargetData.height != renderTarget.height ||
            renderTargetData.activeMipmapLevel != renderTarget.activeMipmapLevel ||
            renderTargetData.samples != renderTarget.samples
        ) {
            descriptors.length = 0;
        }

        let descriptor = descriptors[renderContext.activeCubeFace];

        if (descriptor == null) {
            const textures = renderContext.textures;
            const colorAttachments = [];

            for (i in 0...textures.length) {
                const textureData = this.get(textures[i]);

                const textureView = textureData.texture.createView({
                    baseMipLevel: renderContext.activeMipmapLevel,
                    mipLevelCount: 1,
                    baseArrayLayer: renderContext.activeCubeFace,
                    dimension: GPUTextureViewDimension.TwoD
                });

                let view, resolveTarget;

                if (textureData.msaaTexture != null) {
                    view = textureData.msaaTexture.createView();
                    resolveTarget = textureView;
                } else {
                    view = textureView;
                    resolveTarget = undefined;
                }

                colorAttachments.push({
                    view,
                    resolveTarget,
                    loadOp: GPULoadOp.Load,
                    storeOp: GPUStoreOp.Store
                });
            }

            const depthTextureData = this.get(renderContext.depthTexture);

            const depthStencilAttachment = {
                view: depthTextureData.texture.createView(),
            };

            descriptor = {
                colorAttachments,
                depthStencilAttachment
            };

            descriptors[renderContext.activeCubeFace] = descriptor;

            renderTargetData.width = renderTarget.width;
            renderTargetData.height = renderTarget.height;
            renderTargetData.samples = renderTarget.samples;
            renderTargetData.activeMipmapLevel = renderTarget.activeMipmapLevel;
        }

        return descriptor;
    }

    function beginRender(renderContext:Dynamic) {
        const renderContextData = this.get(renderContext);

        const device = this.device;
        const occlusionQueryCount = renderContext.occlusionQueryCount;

        let occlusionQuerySet;

        if (occlusionQueryCount > 0) {
            if (renderContextData.currentOcclusionQuerySet != null) renderContextData.currentOcclusionQuerySet.destroy();
            if (renderContextData.currentOcclusionQueryBuffer != null) renderContextData.currentOcclusionQueryBuffer.destroy();

            renderContextData.currentOcclusionQuerySet = device.createQuerySet({ type: 'occlusion', count: occlusionQueryCount });

            renderContextData.occlusionQuerySet = renderContextData.currentOcclusionQuerySet;
            renderContextData.occlusionQueryIndex = 0;
            renderContextData.occlusionQueryObjects = new Array(occlusionQueryCount);

            renderContextData.lastOcclusionObject = null;
        }

        let descriptor;

        if (renderContext.textures == null) {
            descriptor = this._getDefaultRenderPassDescriptor();
        } else {
            descriptor = this._getRenderPassDescriptor(renderContext);
        }

        this.initTimestampQuery(renderContext, descriptor);

        descriptor.occlusionQuerySet = occlusionQuerySet;

        const depthStencilAttachment = descriptor.depthStencilAttachment;

        if (renderContext.textures != null) {
            const colorAttachments = descriptor.colorAttachments;

            for (i in 0...colorAttachments.length) {
                const colorAttachment = colorAttachments[i];

                if (renderContext.clearColor) {
                    colorAttachment.clearValue = renderContext.clearColorValue;
                    colorAttachment.loadOp = GPULoadOp.Clear;
                    colorAttachment.storeOp = GPUStoreOp.Store;
                } else {
                    colorAttachment.loadOp = GPULoadOp.Load;
                    colorAttachment.storeOp = GPUStoreOp.Store;
                }
            }
        } else {
            const colorAttachment = descriptor.colorAttachments[0];

            if (renderContext.clearColor) {
                colorAttachment.clearValue = renderContext.clearColorValue;
                colorAttachment.loadOp = GPULoadOp.Clear;
                colorAttachment.storeOp = GPUStoreOp.Store;
            } else {
                colorAttachment.loadOp = GPULoadOp.Load;
                colorAttachment.storeOp = GPUStoreOp.Store;
            }
        }

        if (renderContext.depth) {
            if (renderContext.clearDepth) {
                depthStencilAttachment.depthClearValue = renderContext.clearDepthValue;
                depthStencilAttachment.depthLoadOp = GPULoadOp.Clear;
                depthStencilAttachment.depthStoreOp = GPUStoreOp.Store;
            } else {
                depthStencilAttachment.depthLoadOp = GPULoadOp.Load;
                depthStencilAttachment.depthStoreOp = GPUStoreOp.Store;
            }
        }

        if (renderContext.stencil) {
            if (renderContext.clearStencil) {
                depthStencilAttachment.stencilClearValue = renderContext.clearStencilValue;
                depthStencilAttachment.stencilLoadOp = GPULoadOp.Clear;
                depthStencilAttachment.stencilStoreOp = GPUStoreOp.Store;
            } else {
                depthStencilAttachment.stencilLoadOp = GPULoadOp.Load;
                depthStencilAttachment.stencilStoreOp = GPUStoreOp.Store;
            }
        }

        const encoder = device.createCommandEncoder({ label: 'renderContext_' + renderContext.id });
        const currentPass = encoder.beginRenderPass(descriptor);

        renderContextData.descriptor = descriptor;
        renderContextData.encoder = encoder;
        renderContextData.currentPass = currentPass;
        renderContextData.currentSets = { attributes: {} };

        if (renderContext.viewport) {
            this.updateViewport(renderContext);
        }

        if (renderContext.scissor) {
            const { x, y, width, height } = renderContext.scissorValue;

            currentPass.setScissorRect(x, renderContext.height - height - y, width, height);
        }
    }
}