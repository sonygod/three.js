import three.js.renderers.webgpu.utils.WebGPUConstants;
import three.js.constants.Constants;
import three.js.core.Object3D;
import three.js.materials.Material;
import three.js.objects.Mesh;
import three.js.core.BufferGeometry;
import three.js.renderers.webgpu.WebGPUBindings;
import three.js.renderers.webgpu.WebGPUPipeline;
import three.js.renderers.webgpu.WebGPURendererBackend;
import three.js.materials.Materials;
import three.js.textures.Texture;

class WebGPUPipelineUtils {
    var backend: WebGPURendererBackend;

    public function new(backend: WebGPURendererBackend) {
        this.backend = backend;
    }

    public function createRenderPipeline(renderObject: WebGPURenderObject, promises: Array<Promise<Void>>) {
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

        var vertexBuffers = backend.attributeUtils.createShaderVertexBuffers(renderObject);

        var blending: Dynamic;

        if (material.transparent == true && material.blending != Materials.NoBlending) {
            blending = _getBlending(material);
        }

        var stencilFront: Dynamic = {};

        if (material.stencilWrite == true) {
            stencilFront = {
                compare: _getStencilCompare(material),
                failOp: _getStencilOperation(material.stencilFail),
                depthFailOp: _getStencilOperation(material.stencilZFail),
                passOp: _getStencilOperation(material.stencilZPass)
            };
        }

        var colorWriteMask = _getColorWriteMask(material);

        var targets: Array<Dynamic> = [];

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
        var depthCompare = _getDepthCompare(material);
        var depthStencilFormat = utils.getCurrentDepthStencilFormat(renderObject.context);
        var sampleCount = utils.getSampleCount(renderObject.context);

        if (sampleCount > 1) {
            sampleCount = Math.pow(2, Math.floor(Math.log2(sampleCount)));

            if (sampleCount == 2) {
                sampleCount = 4;
            }
        }

        var pipelineDescriptor = {
            vertex: {...vertexModule, buffers: vertexBuffers},
            fragment: {...fragmentModule, targets: targets},
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
            var p = new Promise<Void>((resolve, reject) => {
                device.createRenderPipelineAsync(pipelineDescriptor).then(pipeline => {
                    pipelineData.pipeline = pipeline;
                    resolve();
                });
            });

            promises.push(p);
        }
    }

    public function createComputePipeline(pipeline: WebGPUPipeline, bindings: WebGPUBindings) {
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

    private function _getBlending(material: Material): Dynamic {
        var color: Dynamic;
        var alpha: Dynamic;

        var blending = material.blending;

        if (blending == Materials.CustomBlending) {
            var blendSrcAlpha = material.blendSrcAlpha != null ? material.blendSrcAlpha : WebGPUConstants.GPUBlendFactor.One;
            var blendDstAlpha = material.blendDstAlpha != null ? material.blendDstAlpha : WebGPUConstants.GPUBlendFactor.Zero;
            var blendEquationAlpha = material.blendEquationAlpha != null ? material.blendEquationAlpha : WebGPUConstants.GPUBlendFactor.Add;

            color = {
                srcFactor: _getBlendFactor(material.blendSrc),
                dstFactor: _getBlendFactor(material.blendDst),
                operation: _getBlendOperation(material.blendEquation)
            };

            alpha = {
                srcFactor: _getBlendFactor(blendSrcAlpha),
                dstFactor: _getBlendFactor(blendDstAlpha),
                operation: _getBlendOperation(blendEquationAlpha)
            };
        } else {
            var premultipliedAlpha = material.premultipliedAlpha;

            var setBlend = (srcRGB: Int, dstRGB: Int, srcAlpha: Int, dstAlpha: Int) => {
                color = {
                    srcFactor: srcRGB,
                    dstFactor: dstRGB,
                    operation: WebGPUConstants.GPUBlendOperation.Add
                };

                alpha = {
                    srcFactor: srcAlpha,
                    dstFactor: dstAlpha,
                    operation: WebGPUConstants.GPUBlendOperation.Add
                };
            };

            if (premultipliedAlpha) {
                switch (blending) {
                    case Materials.NormalBlending:
                        setBlend(WebGPUConstants.GPUBlendFactor.SrcAlpha, WebGPUConstants.GPUBlendFactor.OneMinusSrcAlpha, WebGPUConstants.GPUBlendFactor.One, WebGPUConstants.GPUBlendFactor.OneMinusSrcAlpha);
                        break;

                    case Materials.AdditiveBlending:
                        setBlend(WebGPUConstants.GPUBlendFactor.SrcAlpha, WebGPUConstants.GPUBlendFactor.One, WebGPUConstants.GPUBlendFactor.One, WebGPUConstants.GPUBlendFactor.One);
                        break;

                    case Materials.SubtractiveBlending:
                        setBlend(WebGPUConstants.GPUBlendFactor.Zero, WebGPUConstants.GPUBlendFactor.OneMinusSrc, WebGPUConstants.GPUBlendFactor.Zero, WebGPUConstants.GPUBlendFactor.One);
                        break;

                    case Materials.MultiplyBlending:
                        setBlend(WebGPUConstants.GPUBlendFactor.Zero, WebGPUConstants.GPUBlendFactor.Src, WebGPUConstants.GPUBlendFactor.Zero, WebGPUConstants.GPUBlendFactor.SrcAlpha);
                        break;
                }
            } else {
                switch (blending) {
                    case Materials.NormalBlending:
                        setBlend(WebGPUConstants.GPUBlendFactor.SrcAlpha, WebGPUConstants.GPUBlendFactor.OneMinusSrcAlpha, WebGPUConstants.GPUBlendFactor.One, WebGPUConstants.GPUBlendFactor.OneMinusSrcAlpha);
                        break;

                    case Materials.AdditiveBlending:
                        setBlend(WebGPUConstants.GPUBlendFactor.SrcAlpha, WebGPUConstants.GPUBlendFactor.One, WebGPUConstants.GPUBlendFactor.SrcAlpha, WebGPUConstants.GPUBlendFactor.One);
                        break;

                    case Materials.SubtractiveBlending:
                        setBlend(WebGPUConstants.GPUBlendFactor.Zero, WebGPUConstants.GPUBlendFactor.OneMinusSrc, WebGPUConstants.GPUBlendFactor.Zero, WebGPUConstants.GPUBlendFactor.One);
                        break;

                    case Materials.MultiplyBlending:
                        setBlend(WebGPUConstants.GPUBlendFactor.Zero, WebGPUConstants.GPUBlendFactor.Src, WebGPUConstants.GPUBlendFactor.Zero, WebGPUConstants.GPUBlendFactor.Src);
                        break;
                }
            }
        }

        if (color != null && alpha != null) {
            return {color, alpha};
        } else {
            trace("THREE.WebGPURenderer: Invalid blending: " + blending);
        }
    }

    private function _getBlendFactor(blend: Int): Int {
        var blendFactor: Int;

        switch (blend) {
            case Materials.ZeroFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.Zero;
                break;

            case Materials.OneFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.One;
                break;

            case Materials.SrcColorFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.Src;
                break;

            case Materials.OneMinusSrcColorFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.OneMinusSrc;
                break;

            case Materials.SrcAlphaFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.SrcAlpha;
                break;

            case Materials.OneMinusSrcAlphaFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.OneMinusSrcAlpha;
                break;

            case Materials.DstColorFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.Dst;
                break;

            case Materials.OneMinusDstColorFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.OneMinusDstColor;
                break;

            case Materials.DstAlphaFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.DstAlpha;
                break;

            case Materials.OneMinusDstAlphaFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.OneMinusDstAlpha;
                break;

            case Materials.SrcAlphaSaturateFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.SrcAlphaSaturated;
                break;

            case Constants.BlendColorFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.Constant;
                break;

            case Constants.OneMinusBlendColorFactor:
                blendFactor = WebGPUConstants.GPUBlendFactor.OneMinusConstant;
                break;

            default:
                trace("THREE.WebGPURenderer: Blend factor not supported. " + blend);
        }

        return blendFactor;
    }

    private function _getStencilCompare(material: Material): Int {
        var stencilCompare: Int;

        var stencilFunc = material.stencilFunc;

        switch (stencilFunc) {
            case Materials.NeverStencilFunc:
                stencilCompare = WebGPUConstants.GPUCompareFunction.Never;
                break;

            case Materials.AlwaysStencilFunc:
                stencilCompare = WebGPUConstants.GPUCompareFunction.Always;
                break;

            case Materials.LessStencilFunc:
                stencilCompare = WebGPUConstants.GPUCompareFunction.Less;
                break;

            case Materials.LessEqualStencilFunc:
                stencilCompare = WebGPUConstants.GPUCompareFunction.LessEqual;
                break;

            case Materials.EqualStencilFunc:
                stencilCompare = WebGPUConstants.GPUCompareFunction.Equal;
                break;

            case Materials.GreaterEqualStencilFunc:
                stencilCompare = WebGPUConstants.GPUCompareFunction.GreaterEqual;
                break;

            case Materials.GreaterStencilFunc:
                stencilCompare = WebGPUConstants.GPUCompareFunction.Greater;
                break;

            case Materials.NotEqualStencilFunc:
                stencilCompare = WebGPUConstants.GPUCompareFunction.NotEqual;
                break;

            default:
                trace("THREE.WebGPURenderer: Invalid stencil function. " + stencilFunc);
        }

        return stencilCompare;
    }

    private function _getStencilOperation(op: Int): Int {
        var stencilOperation: Int;

        switch (op) {
            case Materials.KeepStencilOp:
                stencilOperation = WebGPUConstants.GPUStencilOperation.Keep;
                break;

            case Materials.ZeroStencilOp:
                stencilOperation = WebGPUConstants.GPUStencilOperation.Zero;
                break;

            case Materials.ReplaceStencilOp:
                stencilOperation = WebGPUConstants.GPUStencilOperation.Replace;
                break;

            case Materials.InvertStencilOp:
                stencilOperation = WebGPUConstants.GPUStencilOperation.Invert;
                break;

            case Materials.IncrementStencilOp:
                stencilOperation = WebGPUConstants.GPUStencilOperation.IncrementClamp;
                break;

            case Materials.DecrementStencilOp:
                stencilOperation = WebGPUConstants.GPUStencilOperation.DecrementClamp;
                break;

            case Materials.IncrementWrapStencilOp:
                stencilOperation = WebGPUConstants.GPUStencilOperation.IncrementWrap;
                break;

            case Materials.DecrementWrapStencilOp:
                stencilOperation = WebGPUConstants.GPUStencilOperation.DecrementWrap;
                break;

            default:
                trace("THREE.WebGPURenderer: Invalid stencil operation. " + stencilOperation);
        }

        return stencilOperation;
    }

    private function _getBlendOperation(blendEquation: Int): Int {
        var blendOperation: Int;

        switch (blendEquation) {
            case Materials.AddEquation:
                blendOperation = WebGPUConstants.GPUBlendOperation.Add;
                break;

            case Materials.SubtractEquation:
                blendOperation = WebGPUConstants.GPUBlendOperation.Subtract;
                break;

            case Materials.ReverseSubtractEquation:
                blendOperation = WebGPUConstants.GPUBlendOperation.ReverseSubtract;
                break;

            case Materials.MinEquation:
                blendOperation = WebGPUConstants.GPUBlendOperation.Min;
                break;

            case Materials.MaxEquation:
                blendOperation = WebGPUConstants.GPUBlendOperation.Max;
                break;

            default:
                trace("THREE.WebGPUPipelineUtils: Blend equation not supported. " + blendEquation);
        }

        return blendOperation;
    }

    private function _getPrimitiveState(object: Object3D, geometry: BufferGeometry, material: Material): Dynamic {
        var descriptor = {};
        var utils = backend.utils;

        descriptor.topology = utils.getPrimitiveTopology(object, material);

        if (geometry.index != null && object.isLine == true && object.isLineSegments != true) {
            descriptor.stripIndexFormat = (Std.is(geometry.index.array, Uint16Array)) ? WebGPUConstants.GPUIndexFormat.Uint16 : WebGPUConstants.GPUIndexFormat.Uint32;
        }

        switch (material.side) {
            case Materials.FrontSide:
                descriptor.frontFace = WebGPUConstants.GPUFrontFace.CCW;
                descriptor.cullMode = WebGPUConstants.GPUCullMode.Back;
                break;

            case Materials.BackSide:
                descriptor.frontFace = WebGPUConstants.GPUFrontFace.CCW;
                descriptor.cullMode = WebGPUConstants.GPUCullMode.Front;
                break;

            case Materials.DoubleSide:
                descriptor.frontFace = WebGPUConstants.GPUFrontFace.CCW;
                descriptor.cullMode = WebGPUConstants.GPUCullMode.None;
                break;

            default:
                trace("THREE.WebGPUPipelineUtils: Unknown material.side value. " + material.side);
                break;
        }

        return descriptor;
    }

    private function _getColorWriteMask(material: Material): Int {
        return (material.colorWrite == true) ? WebGPUConstants.GPUColorWriteFlags.All : WebGPUConstants.GPUColorWriteFlags.None;
    }

    private function _getDepthCompare(material: Material): Int {
        var depthCompare: Int;

        if (material.depthTest == false) {
            depthCompare = WebGPUConstants.GPUCompareFunction.Always;
        } else {
            var depthFunc = material.depthFunc;

            switch (depthFunc) {
                case Materials.NeverDepth:
                    depthCompare = WebGPUConstants.GPUCompareFunction.Never;
                    break;

                case Materials.AlwaysDepth:
                    depthCompare = WebGPUConstants.GPUCompareFunction.Always;
                    break;

                case Materials.LessDepth:
                    depthCompare = WebGPUConstants.GPUCompareFunction.Less;
                    break;

                case Materials.LessEqualDepth:
                    depthCompare = WebGPUConstants.GPUCompareFunction.LessEqual;
                    break;

                case Materials.EqualDepth:
                    depthCompare = WebGPUConstants.GPUCompareFunction.Equal;
                    break;

                case Materials.GreaterEqualDepth:
                    depthCompare = WebGPUConstants.GPUCompareFunction.GreaterEqual;
                    break;

                case Materials.GreaterDepth:
                    depthCompare = WebGPUConstants.GPUCompareFunction.Greater;
                    break;

                case Materials.NotEqualDepth:
                    depthCompare = WebGPUConstants.GPUCompareFunction.NotEqual;
                    break;

                default:
                    trace("THREE.WebGPUPipelineUtils: Invalid depth function. " + depthFunc);
            }
        }

        return depthCompare;
    }
}

export default WebGPUPipelineUtils;