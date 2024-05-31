import three.js.examples.jsm.common.Constants.BlendColorFactor;
import three.js.examples.jsm.renderers.webgpu.utils.WebGPUConstants.*;
import three.js.examples.jsm.renderers.webgpu.utils.WebGPUPipelineUtils.*;

class WebGPUPipelineUtils {

	var backend:WebGPUBackend;

	public function new(backend:WebGPUBackend) {
		this.backend = backend;
	}

	public function createRenderPipeline(renderObject:RenderObject, promises:Null<Array<Dynamic>>):Void {
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

		// vertex buffers
		var vertexBuffers = backend.attributeUtils.createShaderVertexBuffers(renderObject);

		// blending
		var blending:Null<Blending> = null;

		if (material.transparent === true && material.blending !== NoBlending) {
			blending = this._getBlending(material);
		}

		// stencil
		var stencilFront:Null<StencilFront> = null;

		if (material.stencilWrite === true) {
			stencilFront = {
				compare: this._getStencilCompare(material),
				failOp: this._getStencilOperation(material.stencilFail),
				depthFailOp: this._getStencilOperation(material.stencilZFail),
				passOp: this._getStencilOperation(material.stencilZPass)
			};
		}

		var colorWriteMask = this._getColorWriteMask(material);

		var targets:Array<Target> = [];

		if (renderObject.context.textures !== null) {
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

		var primitiveState = this._getPrimitiveState(object, geometry, material);
		var depthCompare = this._getDepthCompare(material);
		var depthStencilFormat = utils.getCurrentDepthStencilFormat(renderObject.context);
		var sampleCount = utils.getSampleCount(renderObject.context);

		if (sampleCount > 1) {
			// WebGPU only supports power-of-two sample counts and 2 is not a valid value
			sampleCount = Math.pow(2, Math.floor(Math.log2(sampleCount)));

			if (sampleCount === 2) {
				sampleCount = 4;
			}
		}

		var pipelineDescriptor = {
			vertex: Type.clone(vertexModule) as Dynamic,
			fragment: Type.clone(fragmentModule) as Dynamic,
			primitive: primitiveState,
			depthStencil: {
				format: depthStencilFormat,
				depthWriteEnabled: material.depthWrite,
				depthCompare: depthCompare,
				stencilFront: stencilFront,
				stencilBack: {}, // three.js does not provide an API to configure the back function (gl.stencilFuncSeparate() was never used)
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

		if (promises === null) {
			pipelineData.pipeline = device.createRenderPipeline(pipelineDescriptor);
		} else {
			var p = new Promise(function(resolve /*, reject*/) {
				device.createRenderPipelineAsync(pipelineDescriptor).then(function(pipeline) {
					pipelineData.pipeline = pipeline;
					resolve();
				});
			});

			promises.push(p);
		}
	}

	public function createComputePipeline(pipeline:Pipeline, bindings:Bindings):Void {
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

	private function _getBlending(material:Material):Blending {
		var color:Null<Color> = null;
		var alpha:Null<Alpha> = null;

		var blending = material.blending;

		if (blending === CustomBlending) {
			var blendSrcAlpha = material.blendSrcAlpha !== null ? material.blendSrcAlpha : GPUBlendFactor.One;
			var blendDstAlpha = material.blendDstAlpha !== null ? material.blendDstAlpha : GPUBlendFactor.Zero;
			var blendEquationAlpha = material.blendEquationAlpha !== null ? material.blendEquationAlpha : GPUBlendFactor.Add;

			color = {
				srcFactor: this._getBlendFactor(material.blendSrc),
				dstFactor: this._getBlendFactor(material.blendDst),
				operation: this._getBlendOperation(material.blendEquation)
			};

			alpha = {
				srcFactor: this._getBlendFactor(blendSrcAlpha),
				dstFactor: this._getBlendFactor(blendDstAlpha),
				operation: this._getBlendOperation(blendEquationAlpha)
			};
		} else {
			var premultipliedAlpha = material.premultipliedAlpha;

			var setBlend = function(srcRGB:GPUBlendFactor, dstRGB:GPUBlendFactor, srcAlpha:GPUBlendFactor, dstAlpha:GPUBlendFactor):Void {
				color = {
					srcFactor: srcRGB,
					dstFactor: dstRGB,
					operation: GPUBlendOperation.Add
				};

				alpha = {
					srcFactor: srcAlpha,
					dstFactor: dstAlpha,
					operation: GPUBlendOperation.Add
				};
			};

			if (premultipliedAlpha) {
				switch (blending) {
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
				switch (blending) {
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

		if (color !== null && alpha !== null) {
			return {color, alpha};
		} else {
			throw "Invalid blending: " + blending;
		}
	}

	private function _getBlendFactor(blend:GPUBlendFactor):GPUBlendFactor {
		var blendFactor:GPUBlendFactor;

		switch (blend) {
			case ZeroFactor:
				blendFactor = GPUBlendFactor.Zero;
				break;

			case OneFactor:
				blendFactor = GPUBlendFactor.One;
				break;

			case SrcColorFactor:
				blendFactor = GPUBlendFactor.Src;
				break;

			case OneMinusSrcColorFactor:
				blendFactor = GPUBlendFactor.OneMinusSrc;
				break;

			case SrcAlphaFactor:
				blendFactor = GPUBlendFactor.SrcAlpha;
				break;

			case OneMinusSrcAlphaFactor:
				blendFactor = GPUBlendFactor.OneMinusSrcAlpha;
				break;

			case DstColorFactor:
				blendFactor = GPUBlendFactor.Dst;
				break;

			case OneMinusDstColorFactor:
				blendFactor = GPUBlendFactor.OneMinusDstColor;
				break;

			case DstAlphaFactor:
				blendFactor = GPUBlendFactor.DstAlpha;
				break;

			case OneMinusDstAlphaFactor:
				blendFactor = GPUBlendFactor.OneMinusDstAlpha;
				break;

			case SrcAlphaSaturateFactor:
				blendFactor = GPUBlendFactor.SrcAlphaSaturated;
				break;

			case BlendColorFactor:
				blendFactor = GPUBlendFactor.Constant;
				break;

			case OneMinusBlendColorFactor:
				blendFactor = GPUBlendFactor.OneMinusConstant;
				break;

			default:
				throw "Blend factor not supported: " + blend;
		}

		return blendFactor;
	}

	private function _getStencilCompare(material:Material):GPUCompareFunction {
		var stencilCompare:GPUCompareFunction;

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

			default:
				throw "Invalid stencil function: " + stencilFunc;
		}

		return stencilCompare;
	}

	private function _getStencilOperation(op:GPUStencilOperation):GPUStencilOperation {
		var stencilOperation:GPUStencilOperation;

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

			default:
				throw "Invalid stencil operation: " + stencilOperation;
		}

		return stencilOperation;
	}

	private function _getBlendOperation(blendEquation:GPUBlendOperation):GPUBlendOperation {
		var blendOperation:GPUBlendOperation;

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

			default:
				throw "Blend equation not supported: " + blendEquation;
		}

		return blendOperation;
	}

	private function _getPrimitiveState(object:Object3D, geometry:Geometry, material:Material):PrimitiveState {
		var descriptor:PrimitiveState = {};
		var utils = this.backend.utils;

		descriptor.topology = utils.getPrimitiveTopology(object, material);

		if (geometry.index !== null && object.isLine === true && object.isLineSegments !== true) {
			descriptor.stripIndexFormat = (geometry.index.array instanceof Uint16Array) ? GPUIndexFormat.Uint16 : GPUIndexFormat.Uint32;
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

			default:
				throw "Unknown material.side value: " + material.side;
		}

		return descriptor;
	}

	private function _getColorWriteMask(material:Material):GPUColorWriteFlags {
		return (material.colorWrite === true) ? GPUColorWriteFlags.All : GPUColorWriteFlags.None;
	}

	private function _getDepthCompare(material:Material):GPUCompareFunction {
		var depthCompare:GPUCompareFunction;

		if (material.depthTest === false) {
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

				default:
					throw "Invalid depth function: " + depthFunc;
			}
		}

		return depthCompare;
	}

}