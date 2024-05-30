package;

import js.webgpu.GPU;
import js.webgpu.GPUAdapter;
import js.webgpu.GPUBufferUsage;
import js.webgpu.GPUColorWriteFlags;
import js.webgpu.GPUCompareFunction;
import js.webgpu.GPUCullMode;
import js.webgpu.GPUDevice;
import js.webgpu.GPUFrontFace;
import js.webgpu.GPULoadOp;
import js.webgpu.GPUPipelineStatisticName;
import js.webgpu.GPUPrimitiveTopology;
import js.webgpu.GPUQueryType;
import js.webgpu.GPUQueryUsage;
import js.webgpu.GPUStoreOp;
import js.webgpu.GPUStencilOperation;
import js.webgpu.GPUStencilFaceState;
import js.webgpu.GPUTexture;
import js.webgpu.GPUTextureAspect;
import js.webgpu.GPUTextureFormat;
import js.webgpu.GPUTextureUsage;
import js.webgpu.GPUVertexFormat;
import js.webgpu.GPUIndexFormat;
import js.webgpu.GPUCommandBuffer;
import js.webgpu.GPUCommandBufferDescriptor;
import js.webgpu.GPUCommandEncoder;
import js.webgpu.GPUComputePassEncoder;
import js.webgpu.GPUComputePassEncoderDescriptor;
import js.webgpu.GPUComputePipeline;
import js.webgpu.GPUProgrammableStageDescriptor;
import js.webgpu.GPURenderPassColorAttachment;
import js.webgpu.GPURenderPassColorAttachmentDescriptor;
import js.webgpu.GPURenderPassDepthStencilAttachment;
import js.webgpu.GPURenderPassDepthStencilAttachmentDescriptor;
import js.webgpu.GPURenderPassDescriptor;
import js.webgpu.GPURenderPassEncoder;
import js.webgpu.GPURenderPipeline;
import js.webgpu.GPUSamplerDescriptor;
import js.webgpu.GPUTextureDescriptor;
import js.webgpu.GPUTextureView;
import js.webgpu.GPUTextureViewDimension;
import js.webgpu.GPUBindGroup;
import js.webgpu.GPUBindGroupDescriptor;
import js.webgpu.GPUBindGroupLayout;
import js.webgpu.GPUBindGroupLayoutDescriptor;
import js.webgpu.GPUBindingType;
import js.webgpu.GPUBufferBindingLayout;
import js.webgpu.GPUInputStepMode;
import js.webgpu.GPUSamplerBindingLayout;
import js.webgpu.GPUTextureBindingLayout;
import js.webgpu.GPUShaderStage;
import js.webgpu.GPUShaderModule;
import js.webgpu.GPUShaderModuleDescriptor;
import js.webgpu.GPUShaderModuleSource;
import js.webgpu.GPUShaderStageFlags;
import js.webgpu.GPUPipelineLayout;
import js.webgpu.GPUPipelineLayoutDescriptor;
import js.webgpu.GPUPipelineStatisticName;
import js.webgpu.GPUPipelineStatisticsQuery;
import js.webgpu.GPUQuerySet;
import js.webgpu.GPUQuerySetDescriptor;
import js.webgpu.GPUQuery;

import js.html.CanvasElement;
import js.html.HTMLCanvasElement;

import js.html.HTMLElement;
import js.html.Window;

import js.Browser;

class WebGPUBackend {

	public var isWebGPUBackend:Bool;

	public var device:GPUDevice;
	public var context:GPU;
	public var colorBuffer:GPUTexture;
	public var defaultRenderPassdescriptor:GPURenderPassDescriptor;

	public var utils:WebGPUUtils;
	public var attributeUtils:WebGPUAttributeUtils;
	public var bindingUtils:WebGPUBindingUtils;
	public var pipelineUtils:WebGPUPipelineUtils;
	public var textureUtils:WebGPUTextureUtils;
	public var occludedResolveCache:Map<Int, GPUBuffer>;

	public function new(parameters:Dynamic) {
		super(parameters);

		isWebGPUBackend = true;

		// some parameters require default values other than "undefined"
		if (parameters.alpha == null) {
			parameters.alpha = true;
		}

		if (parameters.antialias == null) {
			parameters.antialias = true;
		}

		if (parameters.sampleCount == null) {
			if (parameters.antialias) {
				parameters.sampleCount = 4;
			} else {
				parameters.sampleCount = 1;
			}
		}

		if (parameters.requiredLimits == null) {
			parameters.requiredLimits = { };
		}

		trackTimestamp = parameters.trackTimestamp;

		device = null;
		context = null;
		colorBuffer = null;
		defaultRenderPassdescriptor = null;

		utils = new WebGPUUtils(this);
		attributeUtils = new WebGPUAttributeUtils(this);
		bindingUtils = new WebGPUBindingUtils(this);
		pipelineUtils = new WebGPUPipelineUtils(this);
		textureUtils = new WebGPUTextureUtils(this);
		occludedResolveCache = new Map();
	}

	public async function init(renderer:Dynamic) {
		await super.init(renderer);

		const parameters = this.parameters;

		// create the device if it is not passed with parameters

		var device:GPUDevice;

		if (parameters.device == null) {
			var adapterOptions = {
				powerPreference: parameters.powerPreference
			};

			var adapter = await navigator.gpu.requestAdapter(adapterOptions);

			if (adapter == null) {
				throw new Error('WebGPUBackend: Unable to create WebGPU adapter.');
			}

			// feature support

			var features = GPUFeatureName.values();

			var supportedFeatures = [];

			for (name in features) {
				if (adapter.features.has(name)) {
					supportedFeatures.push(name);
				}
			}

			var deviceDescriptor = {
				requiredFeatures: supportedFeatures,
				requiredLimits: parameters.requiredLimits
			};

			device = await adapter.requestDevice(deviceDescriptor);

		} else {
			device = parameters.device;
		}

		var context = (parameters.context != null) ? parameters.context : (renderer.domElement as HTMLCanvasElement).getContext('webgpu');

		this.device = device;
		this.context = context;

		var alphaMode = parameters.alpha ? 'premultiplied' : 'opaque';

		context.configure({
			device: device,
			format: GPUTextureFormat.BGRA8Unorm,
			usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.COPY_SRC,
			alphaMode: alphaMode
		});

		updateSize();
	}

	public inline function get coordinateSystem():WebGPUCoordinateSystem {
		return WebGPUCoordinateSystem.X_RIGHT_Y_DOWN;
	}

	public async function getArrayBufferAsync(attribute:Dynamic):Null<ArrayBuffer> {
		return await attributeUtils.getArrayBufferAsync(attribute);
	}

	public function getContext():GPU {
		return context;
	}

	public function _getDefaultRenderPassDescriptor():GPURenderPassDescriptor {
		var descriptor = defaultRenderPassdescriptor;

		var antialias = parameters.antialias;

		if (descriptor == null) {
			var renderer = this.renderer;

			descriptor = {
				colorAttachments: [ {
					view: null
				} ],
				depthStencilAttachment: {
					view: textureUtils.getDepthBuffer(renderer.depth, renderer.stencil).createView()
				}
			};

			var colorAttachment = descriptor.colorAttachments[0];

			if (antialias) {
				colorAttachment.view = colorBuffer.createView();
			} else {
				colorAttachment.resolveTarget = null;
			}

			defaultRenderPassdescriptor = descriptor;
		}

		var colorAttachment = descriptor.colorAttachments[0];

		if (antialias) {
			colorAttachment.resolveTarget = context.getCurrentTexture().createView();
		} else {
			colorAttachment.view = context.getCurrentTexture().createView();
		}

		return descriptor;
	}

	public function _getRenderPassDescriptor(renderContext:Dynamic):GPURenderPassDescriptor {
		var renderTarget = renderContext.renderTarget;
		var renderTargetData = get(renderTarget);

		var descriptors = renderTargetData.descriptors;

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

		var descriptor = descriptors[renderContext.activeCubeFace];

		if (descriptor == null) {
			var textures = renderContext.textures;
			var colorAttachments = [];

			for (i in 0...textures.length) {
				var textureData = get(textures[i]);

				var textureView = textureData.texture.createView({
					baseMipLevel: renderContext.activeMipmapLevel,
					mipLevelCount: 1,
					baseArrayLayer: renderContext.activeCubeFace,
					dimension: GPUTextureViewDimension.TwoD
				});

				var view:GPUTextureView, resolveTarget:GPUTextureView;

				if (textureData.msaaTexture != null) {
					view = textureData.msaaTexture.createView();
					resolveTarget = textureView;
				} else {
					view = textureView;
					resolveTarget = null;
				}

				colorAttachments.push({
					view: view,
					resolveTarget: resolveTarget,
					loadOp: GPULoadOp.Load,
					storeOp: GPUStoreOp.Store
				});
			}

			var depthTextureData = get(renderContext.depthTexture);

			var depthStencilAttachment = {
				view: depthTextureData.texture.createView(),
			};

			descriptor = {
				colorAttachments: colorAttachments,
				depthStencilAttachment: depthStencilAttachment
			};

			descriptors[renderContext.activeCubeFace] = descriptor;

			renderTargetData.width = renderTarget.width;
			renderTargetData.height = renderTarget.height;
			renderTargetData.samples = renderTarget.samples;
			renderTargetData.activeMipmapLevel = renderTarget.activeMipmapLevel;
		}

		return descriptor;
	}

	public function beginRender(renderContext:Dynamic) {
		var renderContextData = get(renderContext);

		var device = this.device;
		var occlusionQueryCount = renderContext.occlusionQueryCount;

		var occlusionQuerySet:Null<GPUQuerySet>;

		if (occlusionQueryCount > 0) {
			if (renderContextData.currentOcclusionQuerySet != null) renderContextData.currentOcclusionQuerySet.destroy();
			if (renderContextData.currentOcclusionQueryBuffer != null) renderContextData.currentOcclusionQueryBuffer.destroy();

			// Get a reference to the array of objects with queries. The renderContextData property
			// can be changed by another render pass before the buffer.mapAsyc() completes.
			renderContextData.currentOcclusionQuerySet = renderContextData.occlusionQuerySet;
			renderContextData.currentOcclusionQueryBuffer = renderContextData.occlusionQueryBuffer;
			renderContextData.currentOcclusionQueryObjects = renderContextData.occlusionQueryObjects;

			//

			occlusionQuerySet = device.createQuerySet({ type: 'occlusion', count: occlusionQueryCount });

			renderContextData.occlusionQuerySet = occlusionQuerySet;
			renderContextData.occlusionQueryIndex = 0;
			renderContextData.occlusionQueryObjects = new Array<Dynamic>(occlusionQueryCount);

			renderContextData.lastOcclusionObject = null;
		}

		var descriptor:GPURenderPassDescriptor;

		if (renderContext.textures == null) {
			descriptor = _getDefaultRenderPassDescriptor();
		} else {
			descriptor = _getRenderPassDescriptor(renderContext);
		}

		initTimestampQuery(renderContext, descriptor);

		descriptor.occlusionQuerySet = occlusionQuerySet;

		var depthStencilAttachment = descriptor.depthStencilAttachment;

		if (renderContext.textures != null) {
			var colorAttachments = descriptor.colorAttachments;

			for (i in 0...colorAttachments.length) {
				var colorAttachment = colorAttachments[i];

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
			var colorAttachment = descriptor.colorAttachments[0];

			if (renderContext.clearColor) {
				colorAttachment.clearValue = renderContext.clearColorValue;
				colorAttachment.loadOp = GPULoadOp.Clear;
				colorAttachment.storeOp = GPUStoreOp.Store;
			} else {
				colorAttachment.loadOp = GPULoadOp.Load;
				colorAttachment.storeOp = GPUStoreOp.Store;
			}
		}

		//

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

		//

		var encoder = device.createCommandEncoder({ label: 'renderContext_' + renderContext.id });
		var currentPass = encoder.beginRenderPass(descriptor);

		//

		renderContextData.descriptor = descriptor;
		renderContextData.encoder = encoder;
		renderContextData.currentPass = currentPass;
		renderContextData.currentSets = { attributes: { } };

		//

		if (renderContext.viewport) {
			updateViewport(renderContext);
		}

		if (renderContext.scissor) {
			var x = renderContext.scissorValue.x;
			var y = renderContext.scissorValue.y;
			var width = renderContext.scissorValue.width;
			var height = renderContext.scissorValue.height;

			currentPass.setScissorRect(x, renderContext.height - height - y, width, height);
		}
	}

	public function finishRender(renderContext:Dynamic) {
		var renderContextData = get(renderContext);
		var occlusionQueryCount = renderContext.occlusionQueryCount;

		if (occlusionQueryCount > renderContextData.occlusionQueryIndex) {
			renderContextData.currentPass.endOcclusionQuery();
		}

		renderContextData.currentPass.end();

		if (occlusionQueryCount > 0) {
			var bufferSize = occlusionQueryCount * 8; // 8 byte entries for query results

			//

			var queryResolveBuffer = occludedResolveCache.get(bufferSize);

			if (queryResolveBuffer == null) {
				queryResolveBuffer = device.createBuffer({
					size: bufferSize,
					usage: GPUBufferUsage.QUERY_RESOLVE | GPUBufferUsage.COPY_SRC
				});

				occludedResolveCache.set(bufferSize, queryResolveBuffer);
			}

			//

			var readBuffer = device.createBuffer({
				size: bufferSize,
				usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
			});

			// two buffers required here - WebGPU doesn't allow usage of QUERY_RESOLVE & MAP_READ to be combined
			renderContextData.encoder.resolveQuerySet(renderContextData.occlusionQuerySet, 0, occlusionQueryCount, queryResolveBuffer, 0);
			renderContextData.encoder.copyBufferToBuffer(queryResolveBuffer, 0, readBuffer, 0, bufferSize);

			renderContextData.occlusionQueryBuffer = readBuffer;

			//

			resolveOccludedAsync(renderContext);
		}

		prepareTimestampBuffer(renderContext, renderContextData.encoder);

		device.queue.