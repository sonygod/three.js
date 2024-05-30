package three.js.examples.jsm.renderers.webgpu.utils;

import webgpu.*;

class WebGPUTexturePassUtils {
    private var device:WebGPUDevice;

    public function new(device:WebGPUDevice) {
        this.device = device;

        var mipmapVertexSource = '
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
';

        var mipmapFragmentSource = '
@group( 0 ) @binding( 0 )
var imgSampler : sampler;

@group( 0 ) @binding( 1 )
var img : texture_2d<f32>;

@fragment
fn main( @location( 0 ) vTex : vec2<f32> ) -> @location( 0 ) vec4<f32> {

    return textureSample( img, imgSampler, vTex );

}
';

        var flipYFragmentSource = '
@group( 0 ) @binding( 0 )
var imgSampler : sampler;

@group( 0 ) @binding( 1 )
var img : texture_2d<f32>;

@fragment
fn main( @location( 0 ) vTex : vec2<f32> ) -> @location( 0 ) vec4<f32> {

    return textureSample( img, imgSampler, vec2( vTex.x, 1.0 - vTex.y ) );

}
';

        this.mipmapSampler = device.createSampler( { minFilter: webgpu.GPUFilterMode.Linear } );
        this.flipYSampler = device.createSampler( { minFilter: webgpu.GPUFilterMode.Nearest } );

        this.transferPipelines = {};
        this.flipYPipelines = {};

        this.mipmapVertexShaderModule = device.createShaderModule( {
            label: 'mipmapVertex',
            code: mipmapVertexSource
        } );

        this.mipmapFragmentShaderModule = device.createShaderModule( {
            label: 'mipmapFragment',
            code: mipmapFragmentSource
        } );

        this.flipYFragmentShaderModule = device.createShaderModule( {
            label: 'flipYFragment',
            code: flipYFragmentSource
        } );
    }

    public function getTransferPipeline(format:webgpu.GPUTextureFormat):webgpu.GPURenderPipeline {
        var pipeline = this.transferPipelines[format];

        if (pipeline == null) {
            pipeline = this.device.createRenderPipeline( {
                vertex: {
                    module: this.mipmapVertexShaderModule,
                    entryPoint: 'main'
                },
                fragment: {
                    module: this.mipmapFragmentShaderModule,
                    entryPoint: 'main',
                    targets: [ { format: format } ]
                },
                primitive: {
                    topology: webgpu.GPUPrimitiveTopology.TriangleStrip,
                    stripIndexFormat: webgpu.GPUIndexFormat.Uint32
                },
                layout: 'auto'
            } );

            this.transferPipelines[format] = pipeline;
        }

        return pipeline;
    }

    public function getFlipYPipeline(format:webgpu.GPUTextureFormat):webgpu.GPURenderPipeline {
        var pipeline = this.flipYPipelines[format];

        if (pipeline == null) {
            pipeline = this.device.createRenderPipeline( {
                vertex: {
                    module: this.mipmapVertexShaderModule,
                    entryPoint: 'main'
                },
                fragment: {
                    module: this.flipYFragmentShaderModule,
                    entryPoint: 'main',
                    targets: [ { format: format } ]
                },
                primitive: {
                    topology: webgpu.GPUPrimitiveTopology.TriangleStrip,
                    stripIndexFormat: webgpu.GPUIndexFormat.Uint32
                },
                layout: 'auto'
            } );

            this.flipYPipelines[format] = pipeline;
        }

        return pipeline;
    }

    public function flipY(textureGPU:webgpu.GPUTexture, textureGPUDescriptor:webgpu.GPUTextureDescriptor, baseArrayLayer:Int = 0) {
        var format = textureGPUDescriptor.format;
        var size = textureGPUDescriptor.size;
        var width = size.width;
        var height = size.height;

        var transferPipeline = this.getTransferPipeline(format);
        var flipYPipeline = this.getFlipYPipeline(format);

        var tempTexture = this.device.createTexture( {
            size: { width: width, height: height, depthOrArrayLayers: 1 },
            format: format,
            usage: webgpu.GPUTextureUsage.RENDER_ATTACHMENT | webgpu.GPUTextureUsage.TEXTURE_BINDING
        } );

        var srcView = textureGPU.createView( {
            baseMipLevel: 0,
            mipLevelCount: 1,
            dimension: webgpu.GPUTextureViewDimension.TwoD,
            baseArrayLayer: baseArrayLayer
        } );

        var dstView = tempTexture.createView( {
            baseMipLevel: 0,
            mipLevelCount: 1,
            dimension: webgpu.GPUTextureViewDimension.TwoD,
            baseArrayLayer: 0
        } );

        var commandEncoder = this.device.createCommandEncoder( {} );

        var pass = (pipeline:webgpu.GPURenderPipeline, sourceView:webgpu.GPUTextureView, destinationView:webgpu.GPUTextureView) -> {
            var bindGroupLayout = pipeline.getBindGroupLayout(0); // @TODO: Consider making this static.

            var bindGroup = this.device.createBindGroup( {
                layout: bindGroupLayout,
                entries: [ {
                    binding: 0,
                    resource: this.flipYSampler
                }, {
                    binding: 1,
                    resource: sourceView
                } ]
            } );

            var passEncoder = commandEncoder.beginRenderPass( {
                colorAttachments: [ {
                    view: destinationView,
                    loadOp: webgpu.GPULoadOp.Clear,
                    storeOp: webgpu.GPUStoreOp.Store,
                    clearValue: [ 0, 0, 0, 0 ]
                } ]
            } );

            passEncoder.setPipeline( pipeline );
            passEncoder.setBindGroup( 0, bindGroup );
            passEncoder.draw( 4, 1, 0, 0 );
            passEncoder.end();
        };

        pass(transferPipeline, srcView, dstView);
        pass(flipYPipeline, dstView, srcView);

        this.device.queue.submit( [ commandEncoder.finish() ] );

        tempTexture.destroy();
    }

    public function generateMipmaps(textureGPU:webgpu.GPUTexture, textureGPUDescriptor:webgpu.GPUTextureDescriptor, baseArrayLayer:Int = 0) {
        var pipeline = this.getTransferPipeline(textureGPUDescriptor.format);

        var commandEncoder = this.device.createCommandEncoder( {} );
        var bindGroupLayout = pipeline.getBindGroupLayout(0); // @TODO: Consider making this static.

        var srcView = textureGPU.createView( {
            baseMipLevel: 0,
            mipLevelCount: 1,
            dimension: webgpu.GPUTextureViewDimension.TwoD,
            baseArrayLayer: baseArrayLayer
        } );

        for (i in 1...textureGPUDescriptor.mipLevelCount) {
            var bindGroup = this.device.createBindGroup( {
                layout: bindGroupLayout,
                entries: [ {
                    binding: 0,
                    resource: this.mipmapSampler
                }, {
                    binding: 1,
                    resource: srcView
                } ]
            } );

            var dstView = textureGPU.createView( {
                baseMipLevel: i,
                mipLevelCount: 1,
                dimension: webgpu.GPUTextureViewDimension.TwoD,
                baseArrayLayer: baseArrayLayer
            } );

            var passEncoder = commandEncoder.beginRenderPass( {
                colorAttachments: [ {
                    view: dstView,
                    loadOp: webgpu.GPULoadOp.Clear,
                    storeOp: webgpu.GPUStoreOp.Store,
                    clearValue: [ 0, 0, 0, 0 ]
                } ]
            } );

            passEncoder.setPipeline( pipeline );
            passEncoder.setBindGroup( 0, bindGroup );
            passEncoder.draw( 4, 1, 0, 0 );
            passEncoder.end();

            srcView = dstView;
        }

        this.device.queue.submit( [ commandEncoder.finish() ] );
    }
}