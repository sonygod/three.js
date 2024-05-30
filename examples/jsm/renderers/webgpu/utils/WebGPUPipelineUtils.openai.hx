package three.js.examples.jsm.renderers.webgpu.utils;

import three.js.Constants;

class WebGPUPipelineUtils {
    public var backend:Backend;

    public function new(backend:Backend) {
        this.backend = backend;
    }

    public function createRenderPipeline(renderObject:RenderObject, promises:Array<Promise<Dynamic>>):Void {
        var object = renderObject.object;
        var material = renderObject.material;
        var geometry = renderObject.geometry;
        var pipeline = renderObject.pipeline;

        var vertexProgram = pipeline.vertexProgram;
        var fragmentProgram = pipeline.fragmentProgram;

        var device = backend.device;
        var utils = backend.utils;

        var pipelineData = backend.get(pipeline);
        var bindingsData = backend.get(renderObject.getBindings());

        // vertex buffers
        var vertexBuffers = backend.attributeUtils.createShaderVertexBuffers(renderObject);

        // blending
        var blending:Blending = null;
        if (material.transparent && material.blending != NoBlending) {
            blending = _getBlending(material);
        }

        // stencil
        var stencilFront:StencilState = null;
        if (material.stencilWrite) {
            stencilFront = {
                compare: _getStencilCompare(material),
                failOp: _getStencilOperation(material.stencilFail),
                depthFailOp: _getStencilOperation(material.stencilZFail),
                passOp: _getStencilOperation(material.stencilZPass)
            };
        }

        var colorWriteMask:GPUColorWriteFlags = _getColorWriteMask(material);

        var targets:Array<Target> = [];
        if (renderObject.context.textures != null) {
            var textures = renderObject.context.textures;
            for (i in 0...textures.length) {
                var colorFormat = utils.getTextureFormatGPU(textures[i]);
                targets.push({
                    format: colorFormat,
                    blend: blending,
                    writeMask: colorWriteMask
                });
            }
        } else {
            var colorFormat = utils.getCurrentColorFormat(renderObject.context);
            targets.push({
                format: colorFormat,
                blend: blending,
                writeMask: colorWriteMask
            });
        }

        var vertexModule = backend.get(vertexProgram).module;
        var fragmentModule = backend.get(fragmentProgram).module;

        var primitiveState = _getPrimitiveState(object, geometry, material);
        var depthCompare:GPUCompareFunction = _getDepthCompare(material);
        var depthStencilFormat = utils.getCurrentDepthStencilFormat(renderObject.context);
        var sampleCount = utils.getSampleCount(renderObject.context);
        if (sampleCount > 1) {
            sampleCount = Math.pow(2, Math.floor(Math.log(sampleCount) / Math.log(2)));
            if (sampleCount == 2) {
                sampleCount = 4;
            }
        }

        var pipelineDescriptor:PipelineDescriptor = {
            vertex: vertexModule,
            fragment: fragmentModule,
            primitive: primitiveState,
            depthStencil: {
                format: depthStencilFormat,
                depthWriteEnabled: material.depthWrite,
                depthCompare: depthCompare,
                stencilFront: stencilFront,
                stencilBack: {},
                stencilReadMask: material.stencilFuncMask,
                stencilWriteMask: material.stencilWriteMask
            },
            multisample: {
                count: sampleCount,
                alphaToCoverageEnabled: material.alphaToCoverage
            },
            layout: device.createPipelineLayout({
                bindGroupLayouts: [bindingsData.layout]
            })
        };

        if (promises == null) {
            pipelineData.pipeline = device.createRenderPipeline(pipelineDescriptor);
        } else {
            var promise = new Promise((resolve) -> {
                device.createRenderPipelineAsync(pipelineDescriptor).then((pipeline) -> {
                    pipelineData.pipeline = pipeline;
                    resolve();
                });
            });
            promises.push(promise);
        }
    }

    function createComputePipeline(pipeline:Pipeline, bindings:Bindings):Void {
        var backend = this.backend;
        var device = backend.device;

        var computeProgram = backend.get(pipeline.computeProgram).module;

        var pipelineGPU = backend.get(pipeline);
        var bindingsData = backend.get(bindings);

        pipelineGPU.pipeline = device.createComputePipeline({
            compute: computeProgram,
            layout: device.createPipelineLayout({
                bindGroupLayouts: [bindingsData.layout]
            })
        });
    }

    function _getBlending(material:Material):Blending {
        // ...
    }

    function _getBlendFactor(blend:Int):GPUBlendFactor {
        // ...
    }

    function _getStencilCompare(material:Material):GPUCompareFunction {
        // ...
    }

    function _getStencilOperation(op:Int):GPUStencilOperation {
        // ...
    }

    function _getPrimitiveState(object:Object3D, geometry:Geometry, material:Material):PrimitiveState {
        // ...
    }

    function _getColorWriteMask(material:Material):GPUColorWriteFlags {
        // ...
    }

    function _getDepthCompare(material:Material):GPUCompareFunction {
        // ...
    }
}