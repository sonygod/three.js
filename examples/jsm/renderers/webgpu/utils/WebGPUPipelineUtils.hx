import WebGPU.{GPUBlendFactor, GPUBlendOperation, GPUCompareFunction, GPUFrontFace, GPUCullMode, GPUColorWriteFlags, GPUIndexFormat, GPUStencilOperation, WebGPUConstants};
import three.{FrontSide, BackSide, DoubleSide, NeverDepth, AlwaysDepth, LessDepth, LessEqualDepth, EqualDepth, GreaterEqualDepth, GreaterDepth, NotEqualDepth, NoBlending, NormalBlending, AdditiveBlending, SubtractiveBlending, MultiplyBlending, CustomBlending, ZeroFactor, OneFactor, SrcColorFactor, OneMinusSrcColorFactor, SrcAlphaFactor, OneMinusSrcAlphaFactor, DstColorFactor, OneMinusDstColorFactor, DstAlphaFactor, OneMinusDstAlphaFactor, SrcAlphaSaturateFactor, AddEquation, SubtractEquation, ReverseSubtractEquation, MinEquation, MaxEquation, KeepStencilOp, ZeroStencilOp, ReplaceStencilOp, InvertStencilOp, IncrementStencilOp, DecrementStencilOp, IncrementWrapStencilOp, DecrementWrapStencilOp, NeverStencilFunc, AlwaysStencilFunc, LessStencilFunc, LessEqualStencilFunc, GreaterEqualStencilFunc, GreaterStencilFunc, NotEqualStencilFunc};

class WebGPUPipelineUtils {

	public var backend:Dynamic;

	public function new(backend:Dynamic) {
		this.backend = backend;
	}

	public function createRenderPipeline(renderObject:Dynamic, promises:Array<Dynamic>) {
		var object:Dynamic = renderObject.object;
		var material:Dynamic = renderObject.material;
		var geometry:Dynamic = renderObject.geometry;
		var pipeline:Dynamic = renderObject.pipeline;
		var backend:Dynamic = this.backend;
		var device:Dynamic = backend.device;
		var utils:Dynamic = backend.utils;

		var pipelineData:Dynamic = backend.get(pipeline);
		var bindingsData:Dynamic = backend.get(renderObject.getBindings());

		// vertex buffers

		var vertexBuffers:Array<Dynamic> = backend.attributeUtils.createShaderVertexBuffers(renderObject);

		// blending

		var blending:Dynamic;

		if (material.transparent === true && material.blending !== NoBlending) {
			blending = this._getBlending(material);
		}

		// stencil

		var stencilFront:Dynamic = {};

		if (material.stencilWrite === true) {
			stencilFront = {
				compare: this._getStencilCompare(material),
				failOp: this._getStencilOperation(material.stencilFail),
				depthFailOp: this._getStencilOperation(material.stencilZFail),
				passOp: this._getStencilOperation(material.stencilZPass)
			};
		}

		var colorWriteMask = this._getColorWriteMask(material);

		var targets:Array<Dynamic> = [];

		if (renderObject.context.textures !== null) {

			var textures:Array<Dynamic> = renderObject.context.textures;

			for (var i:Int = 0; i < textures.length; i++) {

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

		var vertexModule:Dynamic = backend.get(pipeline.vertexProgram).module;
		var fragmentModule:Dynamic = backend.get(pipeline.fragmentProgram).module;

		var primitiveState:Dynamic = this._getPrimitiveState(object, geometry, material);
		var depthCompare:Dynamic =