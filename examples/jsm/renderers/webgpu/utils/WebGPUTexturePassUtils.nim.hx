import WebGPUConstants.GPUTextureViewDimension;
import WebGPUConstants.GPUIndexFormat;
import WebGPUConstants.GPUFilterMode;
import WebGPUConstants.GPUPrimitiveTopology;
import WebGPUConstants.GPULoadOp;
import WebGPUConstants.GPUStoreOp;

class WebGPUTexturePassUtils {

	public var device:WebGPUDevice;

	public var mipmapSampler:WebGPUSampler;
	public var flipYSampler:WebGPUSampler;

	public var mipmapVertexShaderModule:WebGPUShaderModule;
	public var mipmapFragmentShaderModule:WebGPUShaderModule;
	public var flipYFragmentShaderModule:WebGPUShaderModule;

	public var transferPipelines:Map<String, WebGPURenderPipeline>;
	public var flipYPipelines:Map<String, WebGPURenderPipeline>;

	public function new(device:WebGPUDevice) {

		this.device = device;

		this.mipmapSampler = device.createSampler({ minFilter: GPUFilterMode.Linear });
		this.flipYSampler = device.createSampler({ minFilter: GPUFilterMode.Nearest });

		this.transferPipelines = new Map<String, WebGPURenderPipeline>();
		this.flipYPipelines = new Map<String, WebGPURenderPipeline>();

		var mipmapVertexSource = "..."; // WGSL code
		var mipmapFragmentSource = "..."; // WGSL code
		var flipYFragmentSource = "..."; // WGSL code

		this.mipmapVertexShaderModule = device.createShaderModule({
			label: 'mipmapVertex',
			code: mipmapVertexSource
		});

		this.mipmapFragmentShaderModule = device.createShaderModule({
			label: 'mipmapFragment',
			code: mipmapFragmentSource
		});

		this.flipYFragmentShaderModule = device.createShaderModule({
			label: 'flipYFragment',
			code: flipYFragmentSource
		});

	}

	public function getTransferPipeline(format:String):WebGPURenderPipeline {

		var pipeline = this.transferPipelines.get(format);

		if (pipeline == null) {

			pipeline = this.device.createRenderPipeline({
				vertex: {
					module: this.mipmapVertexShaderModule,
					entryPoint: 'main'
				},
				fragment: {
					module: this.mipmapFragmentShaderModule,
					entryPoint: 'main',
					targets: [{ format: format }]
				},
				primitive: {
					topology: GPUPrimitiveTopology.TriangleStrip,
					stripIndexFormat: GPUIndexFormat.Uint32
				},
				layout: 'auto'
			});

			this.transferPipelines.set(format, pipeline);

		}

		return pipeline;

	}

	public function getFlipYPipeline(format:String):WebGPURenderPipeline {

		var pipeline = this.flipYPipelines.get(format);

		if (pipeline == null) {

			pipeline = this.device.createRenderPipeline({
				vertex: {
					module: this.mipmapVertexShaderModule,
					entryPoint: 'main'
				},
				fragment: {
					module: this.flipYFragmentShaderModule,
					entryPoint: 'main',
					targets: [{ format: format }]
				},
				primitive: {
					topology: GPUPrimitiveTopology.TriangleStrip,
					stripIndexFormat: GPUIndexFormat.Uint32
				},
				layout: 'auto'
			});

			this.flipYPipelines.set(format, pipeline);

		}

		return pipeline;

	}

	public function flipY(textureGPU:WebGPUTexture, textureGPUDescriptor:WebGPUTextureDescriptor, baseArrayLayer:Int = 0):Void {

		var format = textureGPUDescriptor.format;
		var width = textureGPUDescriptor.size.width;
		var height = textureGPUDescriptor.size.height;

		var transferPipeline = this.getTransferPipeline(format);
		var flipYPipeline = this.getFlipYPipeline(format);

		var tempTexture = this.device.createTexture({
			size: { width: width, height: height, depthOrArrayLayers: 1 },
			format: format,
			usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.TEXTURE_BINDING
		});

		var srcView = textureGPU.createView({
			baseMipLevel: 0,
			mipLevelCount: 1,
			dimension: GPUTextureViewDimension.TwoD,
			baseArrayLayer: baseArrayLayer
		});

		var dstView = tempTexture.createView({
			baseMipLevel: 0,
			mipLevelCount: 1,
			dimension: GPUTextureViewDimension.TwoD,
			baseArrayLayer: 0
		});

		var commandEncoder = this.device.createCommandEncoder({});

		var pass = function(pipeline:WebGPURenderPipeline, sourceView:WebGPUTextureView, destinationView:WebGPUTextureView):Void {

			var bindGroupLayout = pipeline.getBindGroupLayout(0);

			var bindGroup = this.device.createBindGroup({
				layout: bindGroupLayout,
				entries: [{
					binding: 0,
					resource: this.flipYSampler
				}, {
					binding: 1,
					resource: sourceView
				}]
			});

			var passEncoder = commandEncoder.beginRenderPass({
				colorAttachments: [{
					view: destinationView,
					loadOp: GPULoadOp.Clear,
					storeOp: GPUStoreOp.Store,
					clearValue: [0, 0, 0, 0]
				}]
			});

			passEncoder.setPipeline(pipeline);
			passEncoder.setBindGroup(0, bindGroup);
			passEncoder.draw(4, 1, 0, 0);
			passEncoder.end();

		};

		pass(transferPipeline, srcView, dstView);
		pass(flipYPipeline, dstView, srcView);

		this.device.queue.submit([commandEncoder.finish()]);

		tempTexture.destroy();

	}

	public function generateMipmaps(textureGPU:WebGPUTexture, textureGPUDescriptor:WebGPUTextureDescriptor, baseArrayLayer:Int = 0):Void {

		var pipeline = this.getTransferPipeline(textureGPUDescriptor.format);

		var commandEncoder = this.device.createCommandEncoder({});
		var bindGroupLayout = pipeline.getBindGroupLayout(0);

		var srcView = textureGPU.createView({
			baseMipLevel: 0,
			mipLevelCount: 1,
			dimension: GPUTextureViewDimension.TwoD,
			baseArrayLayer: baseArrayLayer
		});

		for (i in 1...textureGPUDescriptor.mipLevelCount) {

			var bindGroup = this.device.createBindGroup({
				layout: bindGroupLayout,
				entries: [{
					binding: 0,
					resource: this.mipmapSampler
				}, {
					binding: 1,
					resource: srcView
				}]
			});

			var dstView = textureGPU.createView({
				baseMipLevel: i,
				mipLevelCount: 1,
				dimension: GPUTextureViewDimension.TwoD,
				baseArrayLayer: baseArrayLayer
			});

			var passEncoder = commandEncoder.beginRenderPass({
				colorAttachments: [{
					view: dstView,
					loadOp: GPULoadOp.Clear,
					storeOp: GPUStoreOp.Store,
					clearValue: [0, 0, 0, 0]
				}]
			});

			passEncoder.setPipeline(pipeline);
			passEncoder.setBindGroup(0, bindGroup);
			passEncoder.draw(4, 1, 0, 0);
			passEncoder.end();

			srcView = dstView;

		}

		this.device.queue.submit([commandEncoder.finish()]);

	}

}