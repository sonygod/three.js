import webgpu.WebGPUConstants;
import webgpu.WebGPUSamplerDescriptor;
import webgpu.WebGPUShaderModuleDescriptor;
import webgpu.WebGPURenderPipelineDescriptor;
import webgpu.WebGPUVertexState;
import webgpu.WebGPUFragmentState;
import webgpu.WebGPUPrimitiveState;
import webgpu.WebGPUColorTargetState;
import webgpu.WebGPUBindGroupLayoutDescriptor;
import webgpu.WebGPUBindGroupDescriptor;
import webgpu.WebGPUBindGroupEntry;
import webgpu.WebGPUCommandEncoderDescriptor;
import webgpu.WebGPURenderPassDescriptor;
import webgpu.WebGPUColorAttachment;
import webgpu.WebGPUTextureDescriptor;
import webgpu.WebGPUTextureViewDescriptor;

class WebGPUTexturePassUtils {

	public var device: webgpu.GPUDevice;
	public var mipmapSampler: webgpu.GPUSampler;
	public var flipYSampler: webgpu.GPUSampler;

	public var transferPipelines: Map<String, webgpu.GPURenderPipeline>;
	public var flipYPipelines: Map<String, webgpu.GPURenderPipeline>;

	public var mipmapVertexShaderModule: webgpu.GPUShaderModule;
	public var mipmapFragmentShaderModule: webgpu.GPUShaderModule;
	public var flipYFragmentShaderModule: webgpu.GPUShaderModule;

	public function new(device: webgpu.GPUDevice) {
		this.device = device;

		this.mipmapSampler = device.createSampler({
			minFilter: WebGPUConstants.GPUFilterMode.Linear
		});
		this.flipYSampler = device.createSampler({
			minFilter: WebGPUConstants.GPUFilterMode.Nearest
		});

		this.transferPipelines = new Map();
		this.flipYPipelines = new Map();

		this.mipmapVertexShaderModule = device.createShaderModule({
			label: "mipmapVertex",
			code: `
struct VarysStruct {
	@builtin( position ) Position: vec4<f32>,
	@location( 0 ) vTex : vec2<f32>
};

@vertex
fn main( @builtin( vertex_index ) vertexIndex : u32 ) -> VarysStruct {

	var Varys : VarysStruct;

	var pos = array< vec2<f32>, 4 >(
		vec2<f32>( -1.0,  1.0 ),
		vec2<f32>(  1.0,  1.0 ),
		vec2<f32>( -1.0, -1.0 ),
		vec2<f32>(  1.0, -1.0 )
	);

	var tex = array< vec2<f32>, 4 >(
		vec2<f32>( 0.0, 0.0 ),
		vec2<f32>( 1.0, 0.0 ),
		vec2<f32>( 0.0, 1.0 ),
		vec2<f32>( 1.0, 1.0 )
	);

	Varys.vTex = tex[ vertexIndex ];
	Varys.Position = vec4<f32>( pos[ vertexIndex ], 0.0, 1.0 );

	return Varys;

}
`
		});

		this.mipmapFragmentShaderModule = device.createShaderModule({
			label: "mipmapFragment",
			code: `
@group( 0 ) @binding( 0 )
var imgSampler : sampler;

@group( 0 ) @binding( 1 )
var img : texture_2d<f32>;

@fragment
fn main( @location( 0 ) vTex : vec2<f32> ) -> @location( 0 ) vec4<f32> {

	return textureSample( img, imgSampler, vTex );

}
`
		});

		this.flipYFragmentShaderModule = device.createShaderModule({
			label: "flipYFragment",
			code: `
@group( 0 ) @binding( 0 )
var imgSampler : sampler;

@group( 0 ) @binding( 1 )
var img : texture_2d<f32>;

@fragment
fn main( @location( 0 ) vTex : vec2<f32> ) -> @location( 0 ) vec4<f32> {

	return textureSample( img, imgSampler, vec2( vTex.x, 1.0 - vTex.y ) );

}
`
		});
	}

	public function getTransferPipeline(format: String): webgpu.GPURenderPipeline {
		var pipeline = this.transferPipelines.get(format);

		if (pipeline == null) {
			pipeline = device.createRenderPipeline({
				vertex: {
					module: this.mipmapVertexShaderModule,
					entryPoint: "main"
				},
				fragment: {
					module: this.mipmapFragmentShaderModule,
					entryPoint: "main",
					targets: [
						{
							format: format
						}
					]
				},
				primitive: {
					topology: WebGPUConstants.GPUPrimitiveTopology.TriangleStrip,
					stripIndexFormat: WebGPUConstants.GPUIndexFormat.Uint32
				},
				layout: "auto"
			});

			this.transferPipelines.set(format, pipeline);
		}

		return pipeline;
	}

	public function getFlipYPipeline(format: String): webgpu.GPURenderPipeline {
		var pipeline = this.flipYPipelines.get(format);

		if (pipeline == null) {
			pipeline = device.createRenderPipeline({
				vertex: {
					module: this.mipmapVertexShaderModule,
					entryPoint: "main"
				},
				fragment: {
					module: this.flipYFragmentShaderModule,
					entryPoint: "main",
					targets: [
						{
							format: format
						}
					]
				},
				primitive: {
					topology: WebGPUConstants.GPUPrimitiveTopology.TriangleStrip,
					stripIndexFormat: WebGPUConstants.GPUIndexFormat.Uint32
				},
				layout: "auto"
			});

			this.flipYPipelines.set(format, pipeline);
		}

		return pipeline;
	}

	public function flipY(textureGPU: webgpu.GPUTexture, textureGPUDescriptor: webgpu.WebGPUTextureDescriptor, baseArrayLayer: Int = 0) {
		var format = textureGPUDescriptor.format;
		var width = textureGPUDescriptor.size.width;
		var height = textureGPUDescriptor.size.height;

		var transferPipeline = this.getTransferPipeline(format);
		var flipYPipeline = this.getFlipYPipeline(format);

		var tempTexture = device.createTexture({
			size: {
				width: width,
				height: height,
				depthOrArrayLayers: 1
			},
			format: format,
			usage: WebGPUConstants.GPUTextureUsage.RENDER_ATTACHMENT | WebGPUConstants.GPUTextureUsage.TEXTURE_BINDING
		});

		var srcView = textureGPU.createView({
			baseMipLevel: 0,
			mipLevelCount: 1,
			dimension: WebGPUConstants.GPUTextureViewDimension.TwoD,
			baseArrayLayer: baseArrayLayer
		});

		var dstView = tempTexture.createView({
			baseMipLevel: 0,
			mipLevelCount: 1,
			dimension: WebGPUConstants.GPUTextureViewDimension.TwoD,
			baseArrayLayer: 0
		});

		var commandEncoder = device.createCommandEncoder({ });

		var pass = function(pipeline: webgpu.GPURenderPipeline, sourceView: webgpu.GPUTextureView, destinationView: webgpu.GPUTextureView) {
			var bindGroupLayout = pipeline.getBindGroupLayout(0);
			var bindGroup = device.createBindGroup({
				layout: bindGroupLayout,
				entries: [
					{
						binding: 0,
						resource: this.flipYSampler
					},
					{
						binding: 1,
						resource: sourceView
					}
				]
			});

			var passEncoder = commandEncoder.beginRenderPass({
				colorAttachments: [
					{
						view: destinationView,
						loadOp: WebGPUConstants.GPULoadOp.Clear,
						storeOp: WebGPUConstants.GPUStoreOp.Store,
						clearValue: [0, 0, 0, 0]
					}
				]
			});

			passEncoder.setPipeline(pipeline);
			passEncoder.setBindGroup(0, bindGroup);
			passEncoder.draw(4, 1, 0, 0);
			passEncoder.end();
		};

		pass(transferPipeline, srcView, dstView);
		pass(flipYPipeline, dstView, srcView);

		device.queue.submit([commandEncoder.finish()]);

		tempTexture.destroy();
	}

	public function generateMipmaps(textureGPU: webgpu.GPUTexture, textureGPUDescriptor: webgpu.WebGPUTextureDescriptor, baseArrayLayer: Int = 0) {
		var pipeline = this.getTransferPipeline(textureGPUDescriptor.format);
		var commandEncoder = device.createCommandEncoder({});
		var bindGroupLayout = pipeline.getBindGroupLayout(0);
		var srcView = textureGPU.createView({
			baseMipLevel: 0,
			mipLevelCount: 1,
			dimension: WebGPUConstants.GPUTextureViewDimension.TwoD,
			baseArrayLayer: baseArrayLayer
		});

		for (i in 1...textureGPUDescriptor.mipLevelCount) {
			var bindGroup = device.createBindGroup({
				layout: bindGroupLayout,
				entries: [
					{
						binding: 0,
						resource: this.mipmapSampler
					},
					{
						binding: 1,
						resource: srcView
					}
				]
			});

			var dstView = textureGPU.createView({
				baseMipLevel: i,
				mipLevelCount: 1,
				dimension: WebGPUConstants.GPUTextureViewDimension.TwoD,
				baseArrayLayer: baseArrayLayer
			});

			var passEncoder = commandEncoder.beginRenderPass({
				colorAttachments: [
					{
						view: dstView,
						loadOp: WebGPUConstants.GPULoadOp.Clear,
						storeOp: WebGPUConstants.GPUStoreOp.Store,
						clearValue: [0, 0, 0, 0]
					}
				]
			});

			passEncoder.setPipeline(pipeline);
			passEncoder.setBindGroup(0, bindGroup);
			passEncoder.draw(4, 1, 0, 0);
			passEncoder.end();

			srcView = dstView;
		}

		device.queue.submit([commandEncoder.finish()]);
	}
}