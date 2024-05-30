import js.webgpu.GPUBlendFactor;
import js.webgpu.GPUBlendOperation;
import js.webgpu.GPUColorWriteFlags;
import js.webgpu.GPUCompareFunction;
import js.webgpu.GPUCullMode;
import js.webgpu.GPUFrontFace;
import js.webgpu.GPUIndexFormat;
import js.webgpu.GPUPipelineDescriptor;
import js.webgpu.GPUPrimitiveTopology;
import js.webgpu.GPUStencilOperation;

class WebGPUPipelineUtils {
    public var backend:Dynamic;

    public function new(backend:Dynamic) {
        this.backend = backend;
    }

    public function createRenderPipeline(renderObject:Dynamic, promises:Array<Dynamic>) {
        var object = renderObject.object;
        var material = renderObject.material;
        var geometry = renderObject.geometry;
        var pipeline = renderObject.pipeline;
        var vertexProgram = pipeline.vertexProgram;
        var fragmentProgram = pipeline.fragmentProgram;
        var backend = this.backend;
        var device = backend.device;
        var utils = backend.utils;
        var pipelineData = backend.get(pipeline);
        var bindingsData = backend.get(renderObject.getBindings());
        var vertexBuffers = backend.attributeUtils.createShaderVertexBuffers(renderObject);
        var blending:Dynamic;
        if (material.transparent && material.blending != NoBlending) {
            blending = this._getBlending(material);
        }
        var stencilFront:Dynamic;
        if (material.stencilWrite) {
            stencilFront = {
                compare: this._getStencilCompare(material),
                failOp: this._getStencilOperation(material.stencilFail),
                depthFailOp: this._getStencilOperation(material.stencilZFail),
                passOp: this._getStencilOperation(material.stencilZPass)
            };
        }
        var colorWriteMask = this._getColorWriteMask(material);
        var targets = [];
        if (renderObject.context.textures != null) {
            var textures = renderObject.context.textures;
            var _g = 0;
            while (_g < textures.length) {
                var texture = textures[_g];
                ++_g;
                var colorFormat = utils.getTextureFormatGPU(texture);
                targets.push({ format : colorFormat, blend : blending, writeMask : colorWriteMask });
            }
        } else {
            var colorFormat1 = utils.getCurrentColorFormat(renderObject.context);
            targets.push({ format : colorFormat1, blend : blending, writeMask : colorWriteMask });
        }
        var vertexModule = backend.get(vertexProgram).module;
        var fragmentModule = backend.get(fragmentProgram).module;
        var primitiveState = this._getPrimitiveState(object, geometry, material);
        var depthCompare = this._getDepthCompare(material);
        var depthStencilFormat = utils.getCurrentDepthStencilFormat(renderObject.context);
        var sampleCount = utils.getSampleCount(renderObject.context);
        if (sampleCount > 1) {
            sampleCount = Math.pow(2, Std.int(Math.log2(sampleCount)));
            if (sampleCount == 2) {
                sampleCount = 4;
            }
        }
        var pipelineDescriptor = { };
        pipelineDescriptor.vertex = haxe.ds.StringMap_Impl_.fromData({ }, vertexModule);
        pipelineDescriptor.vertex.buffers = vertexBuffers;
        pipelineDescriptor.fragment = haxe.ds.StringMap_Impl_.fromData({ }, fragmentModule);
        pipelineDescriptor.fragment.targets = targets;
        pipelineDescriptor.primitive = primitiveState;
        pipelineDescriptor.depthStencil = {
            format : depthStencilFormat,
            depthWriteEnabled : material.depthWrite,
            depthCompare : depthCompare,
            stencilFront : stencilFront,
            stencilBack : { },
            stencilReadMask : material.stencilFuncMask,
            stencilWriteMask : material.stencilWriteMask
        };
        pipelineDescriptor.multisample = {
            count : sampleCount,
            alphaToCoverageEnabled : material.alphaToCoverage
        };
        pipelineDescriptor.layout = device.createPipelineLayout({ bindGroupLayouts : [bindingsData.layout] });
        if (promises == null) {
            pipelineData.pipeline = device.createRenderPipeline(pipelineDescriptor);
        } else {
            var p = new Promise(function(resolve, _) {
                device.createRenderPipelineAsync(pipelineDescriptor).then(function(pipeline) {
                    pipelineData.pipeline = pipeline;
                    resolve();
                });
            });
            promises.push(p);
        }
    }

    public function createComputePipeline(pipeline:Dynamic, bindings:Dynamic) {
        var backend = this.backend;
        var device = backend.device;
        var computeProgram = backend.get(pipeline.computeProgram).module;
        var pipelineGPU = backend.get(pipeline);
        var bindingsData1 = backend.get(bindings);
        pipelineGPU.pipeline = device.createComputePipeline({
            compute : computeProgram,
            layout : device.createPipelineLayout({ bindGroupLayouts : [bindingsData1.layout] })
        });
    }

    public function _getBlending(material:Dynamic) {
        var color:Dynamic;
        var alpha:Dynamic;
        var blending1 = material.blending;
        if (blending1 == CustomBlending) {
            var blendSrcAlpha = material.blendSrcAlpha != null ? material.blendSrcAlpha : GPUBlendFactor.One;
            var blendDstAlpha = material.blendDstAlpha != null ? material.blendDstAlpha : GPUBlendFactor.Zero;
            var blendEquationAlpha = material.blendEquationAlpha != null ? material.blendEquationAlpha : GPUBlendFactor.Add;
            color = {
                srcFactor : this._getBlendFactor(material.blendSrc),
                dstFactor : this._getBlendFactor(material.blendDst),
                operation : this._getBlendOperation(material.blendEquation)
            };
            alpha = {
                srcFactor : this._getBlendFactor(blendSrcAlpha),
                dstFactor : this._getBlendFactor(blendDstAlpha),
                operation : this._getBlendOperation(blendEquationAlpha)
            };
        } else {
            var premultipliedAlpha = material.premultipliedAlpha;
            var setBlend = function(srcRGB, dstRGB, srcAlpha, dstAlpha) {
                color = {
                    srcFactor : srcRGB,
                    dstFactor : dstRGB,
                    operation : GPUBlendOperation.Add
                };
                alpha = {
                    srcFactor : srcAlpha,
                    dstFactor : dstAlpha,
                    operation : GPUBlendOperation.Add
                };
            };
            if (premultipliedAlpha) {
                switch (blending1) {
                    case NormalBlending:
                        setBlend(GPUBlendFactor.SrcAlpha, GPUBlendFactor.OneMinusSrcAlpha, GPUBlendFactor.One, GPUBlendFactor.OneMinusSrcAlpha);
                        break;
                    case AdditiveBlending:
                        setBlend(GPUBlendFactor.SrcAlpha, GPUBlendFactor.One, GPUBlendFactor.One, GPUBlendFactor.One);
                        break;
                    case SubtractiveBlending:
                        setBlend(GPUBlendFactor.Zero, GPUBlendFactor.OneMinusSrc, GPUBlendFactor.Zero, GPUBlendFactor.One);
                        break;
                    case MultiplyBlending:
                        setBlend(GPUBlendFactor.Zero, GPUBlendFactor.Src, GPUBlendFactor.Zero, GPUBlendFactor.SrcAlpha);
                        break;
                }
            } else {
                switch (blending1) {
                    case NormalBlending:
                        setBlend(GPUBlendFactor.SrcAlpha, GPUBlendFactor.OneMinusSrcAlpha, GPUBlendFactor.One, GPUBlendFactor.OneMinusSrcAlpha);
                        break;
                    case AdditiveBlending:
                        setBlend(GPUBlendFactor.SrcAlpha, GPUBlendFactor.One, GPUBlendFactor.SrcAlpha, GPUBlendFactor.One);
                        break;
                    case SubtractiveBlending:
                        setBlend(GPUBlendFactor.Zero, GPUBlendFactor.OneMinusSrc, GPUBlendFactor.Zero, GPUBlendFactor.One);
                        break;
                    case MultiplyBlending:
                        setBlend(GPUBlendFactor.Zero, GPUBlendFactor.Src, GPUBlendFactor.Zero, GPUBlendFactor.Src);
                        break;
                }
            }
        }
        if (color != null && alpha != null) {
            return { color : color, alpha : alpha };
        } else {
            trace("THREE.WebGPURenderer: Invalid blending: ", blending1);
        }
    }

    public function _getBlendFactor(blend:Dynamic) {
        switch (blend) {
            case ZeroFactor:
                return GPUBlendFactor.Zero;
            case OneFactor:
                return GPUBlendFactor.One;
            case SrcColorFactor:
                return GPUBlendFactor.Src;
            case OneMinusSrcColorFactor:
                return GPUBlendFactor.OneMinusSrc;
            case SrcAlphaFactor:
                return GPUBlendFactor.SrcAlpha;
            case OneMinusSrcAlphaFactor:
                return GPUBlendFactor.OneMinusSrcAlpha;
            case DstColorFactor:
                return GPUBlendFactor.Dst;
            case OneMinusDstColorFactor:
                return GPUBlendFactor.OneMinusDstColor;
            case DstAlphaFactor:
                return GPUBlendFactor.DstAlpha;
            case OneMinusDstAlphaFactor:
                return GPUBlendFactor.OneMinusDstAlpha;
            case SrcAlphaSaturateFactor:
                return GPUBlendFactor.SrcAlphaSaturated;
            case BlendColorFactor:
                return GPUBlendFactor.Constant;
            case OneMinusBlendColorFactor:
                return GPUBlendFactor.OneMinusConstant;
        }
    }

    public function _getStencilCompare(material:Dynamic) {
        var stencilCompare:Dynamic;
        var stencilFunc = material.stencilFunc;
        switch (stencilFunc) {
            case NeverStencilFunc:
                stencilCompare = GPUCompareFunction.Never;
                break;
            case AlwaysStencilFunc:
                stencilCompare = GPUCompareFunction.Always;
                break;
            case LessStencilFunc:
                stencilCompare = GPUCompareFunction.Less;
                break;
            case LessEqualStencilFunc:
                stencilCompare = GPUCompareFunction.LessEqual;
                break;
            case EqualStencilFunc:
                stencilCompare = GPUCompareFunction.Equal;
                break;
            case GreaterEqualStencilFunc:
                stencilCompare = GPUCompareFunction.GreaterEqual;
                break;
            case GreaterStencilFunc:
                stencilCompare = GPUCompareFunction.Greater;
                break;
            case NotEqualStencilFunc:
                stencilCompare = GPUCompareFunction.NotEqual;
                break;
        }
        return stencilCompare;
    }

    public function _getStencilOperation(op:Dynamic) {
        var stencilOperation:Dynamic;
        switch (op) {
            case KeepStencilOp:
                stencilOperation = GPUStencilOperation.Keep;
                break;
            case ZeroStencilOp:
                stencilOperation = GPUStencilOperation.Zero;
                break;
            case ReplaceStencilOp:
                stencilOperation = GPUStencilOperation.Replace;
                break;
            case InvertStencilOp:
                stencilOperation = GPUStencilOperation.Invert;
                break;
            case IncrementStencilOp:
                stencilOperation = GPUStencilOperation.IncrementClamp;
                break;
            case DecrementStencilOp:
                stencilOperation = GPUStencilOperation.DecrementClamp;
                break;
            case IncrementWrapStencilOp:
                stencilOperation = GPUStencilOperation.IncrementWrap;
                break;
            case DecrementWrapStencilOp:
                stencilOperation = GPUStencilOperation.DecrementWrap;
                break;
        }
        return stencilOperation;
    }

    public function _getBlendOperation(blendEquation:Dynamic) {
        var blendOperation:Dynamic;
        switch (blendEquation) {
            case AddEquation:
                blendOperation = GPUBlendOperation.Add;
                break;
            case SubtractEquation:
                blendOperation = GPUBlendOperation.Subtract;
                break;
            case ReverseSubtractEquation:
                blendOperation = GPUBlendOperation.ReverseSubtract;
                break;
            case MinEquation:
                blendOperation = GPUBlendOperation.Min;
                break;
            case MaxEquation:
                blendOperation = GPUBlendOperation.Max;
                break;
        }
        return blendOperation;
    }

    public function _getPrimitiveState(object:Dynamic, geometry:Dynamic, material:Dynamic) {
        var descriptor = { };
        var utils = this.backend.utils;
        descriptor.topology = utils.getPrimitiveTopology(object, material);
        if (geometry.index != null && object.isLine && !object.isLineSegments) {
            descriptor.stripIndexFormat = Type.enumIndex(GPUIndexFormat, Std.string(geometry.index.array));
        }
        switch (material.side) {
            case FrontSide:
                descriptor.frontFace = GPUFrontFace.CCW;
                descriptor.cullMode = GPUCullMode.Back;
                break;
            case BackSide:
                descriptor.frontFace = GPUFrontFace.CCW;
                descriptor.cullMode = GPUCullMode.Front;
                break;
            case DoubleSide:
                descriptor.frontFace = GPUFrontFace.CCW;
                descriptor.cullMode = GPUCullMode.None;
                break;
        }
        return descriptor;
    }

    public function _getColorWriteMask(material:Dynamic) {
        if (material.colorWrite) {
            return GPUColorWriteFlags.All;
        } else {
            return GPUColorWriteFlags.None;
        }
    }

    public function _getDepthCompare(material:Dynamic) {
        var depthCompare:Dynamic;
        if (!material.depthTest) {
            depthCompare = GPUCompareFunction.Always;
        } else {
            var depthFunc = material.depthFunc;
            switch (depthFunc) {
                case NeverDepth:
                    depthCompare = GPUCompareFunction.Never;
                    break;
                case AlwaysDepth:
                    depthCompare = GPUCompareFunction.Always;
                    break;
                case LessDepth:
                    depthCompare = GPUCompareFunction.Less;
                    break;
                case LessEqualDepth:
                    depthCompare = GPUCompareFunction.LessEqual;
                    break;
                case EqualDepth:
                    depthCompare = GPUCompareFunction.Equal;
                    break;
                case GreaterEqualDepth:
                    depthCompare = GPUCompareFunction.GreaterEqual;
                    break;
                case GreaterDepth:
                    depthCompare = GPUCompareFunction.Greater;
                    break;
                case NotEqualDepth:
                    depthCompare = GPUCompareFunction.NotEqual;
                    break;
            }
        }
        return depthCompare;
    }
}

class Constants {
    static var NoBlending:Int = 0;
    static var CustomBlending:Int = 3;
    static var NeverStencilFunc:Int = 0;
    static var AlwaysStencilFunc:Int = 7;
    static var LessStencilFunc:Int = 2;
    static var LessEqualStencilFunc:Int = 3;
    static var EqualStencilFunc:Int = 4;
    static var GreaterEqualStencilFunc:Int = 5;
    static var GreaterStencilFunc:Int = 6;
    static var NotEqualStencilFunc:Int = 1;
    static var KeepStencilOp:Int = 0;
    var ZeroStencilOp:Int = 1;
    var ReplaceStencilOp:Int = 2;
    var InvertStencilOp:Int = 3;
    var IncrementStencilOp:Int = 4;
    var DecrementStencilOp:Int = 5;
    var IncrementWrapStencilOp:Int = 6;
    var DecrementWrapStencilOp:Int = 7;
    static var NeverDepth:Int = 0;
    static var AlwaysDepth:Int = 7;
    static var LessDepth:Int = 2;
    static var LessEqualDepth:Int = 3;
    static var EqualDepth:Int = 4;
    static var GreaterEqualDepth:Int = 5;
    static var GreaterDepth:Int = 6;
    static var NotEqualDepth:Int = 1;
    static var ZeroFactor:Int = 0;
    static var OneFactor:Int = 1;
    static var SrcColorFactor:Int = 4;
    static var OneMinusSrcColorFactor:Int = 5;
    static var SrcAlphaFactor:Int = 6;
    static var OneMinusSrcAlphaFactor:Int = 7;
    static var DstColorFactor:Int = 8;
    static var OneMinusDstColorFactor:Int = 9;
    static var DstAlphaFactor:Int = 10;
    static var OneMinusDstAlphaFactor:Int = 11;
    static var SrcAlphaSaturateFactor:Int = 14;
    static var BlendColorFactor:Int = 15;
    static var OneMinusBlendColorFactor:Int = 16;
    static var FrontSide:Int = 0;
    static var BackSide:Int = 1;
    static var DoubleSide:Int = 2;
    static var NormalBlending:Int = 1;
    static var AdditiveBlending:Int = 2;
    static var SubtractiveBlending:Int = 3;
    static var MultiplyBlending:Int = 4;
}