import haxe.io.Bytes;
import three.constants.Blending;
import three.constants.CullFace;
import three.constants.DepthFunc;
import three.constants.Equation;
import three.constants.Factor;
import three.math.Color;
import three.math.Vector4;

class WebGLState {

	public var gl: WebGLRenderingContext;

	public var colorBuffer: ColorBuffer;
	public var depthBuffer: DepthBuffer;
	public var stencilBuffer: StencilBuffer;

	public var uboBindings: WeakMap<WebGLProgram, Int>;
	public var uboProgramMap: WeakMap<WebGLProgram, WeakMap<Dynamic, Int>>;

	public var enabledCapabilities: Map<Int, Bool>;

	public var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
	public var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
	public var defaultDrawbuffers: Array<Int>;

	public var currentProgram: WebGLProgram;

	public var currentBlendingEnabled: Bool;
	public var currentBlending: Blending;
	public var currentBlendEquation: Equation;
	public var currentBlendSrc: Factor;
	public var currentBlendDst: Factor;
	public var currentBlendEquationAlpha: Equation;
	public var currentBlendSrcAlpha: Factor;
	public var currentBlendDstAlpha: Factor;
	public var currentBlendColor: Color;
	public var currentBlendAlpha: Float;
	public var currentPremultipledAlpha: Bool;

	public var currentFlipSided: Bool;
	public var currentCullFace: CullFace;

	public var currentLineWidth: Float;

	public var currentPolygonOffsetFactor: Float;
	public var currentPolygonOffsetUnits: Float;

	public var maxTextures: Int;

	public var lineWidthAvailable: Bool;
	public var version: Float;

	public var currentTextureSlot: Int;
	public var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;

	public var currentScissor: Vector4;
	public var currentViewport: Vector4;

	public var emptyTextures: Map<Int, WebGLTexture>;

	public function new(gl: WebGLRenderingContext) {

		this.gl = gl;

		this.colorBuffer = new ColorBuffer();
		this.depthBuffer = new DepthBuffer();
		this.stencilBuffer = new StencilBuffer();

		this.uboBindings = new WeakMap();
		this.uboProgramMap = new WeakMap();

		this.enabledCapabilities = new Map();

		this.currentBoundFramebuffers = new Map();
		this.currentDrawbuffers = new WeakMap();
		this.defaultDrawbuffers = [];

		this.currentProgram = null;

		this.currentBlendingEnabled = false;
		this.currentBlending = null;
		this.currentBlendEquation = null;
		this.currentBlendSrc = null;
		this.currentBlendDst = null;
		this.currentBlendEquationAlpha = null;
		this.currentBlendSrcAlpha = null;
		this.currentBlendDstAlpha = null;
		this.currentBlendColor = new Color(0, 0, 0);
		this.currentBlendAlpha = 0;
		this.currentPremultipledAlpha = false;

		this.currentFlipSided = null;
		this.currentCullFace = null;

		this.currentLineWidth = null;

		this.currentPolygonOffsetFactor = null;
		this.currentPolygonOffsetUnits = null;

		this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

		this.lineWidthAvailable = false;
		this.version = 0;
		var glVersion = gl.getParameter(gl.VERSION);

		if (glVersion.indexOf("WebGL") != - 1) {

			this.version = Std.parseFloat(glVersion.split(" ")[1]);
			this.lineWidthAvailable = (this.version >= 1.0);

		} else if (glVersion.indexOf("OpenGL ES") != - 1) {

			this.version = Std.parseFloat(glVersion.split(" ")[2]);
			this.lineWidthAvailable = (this.version >= 2.0);

		}

		this.currentTextureSlot = null;
		this.currentBoundTextures = new Map();

		var scissorParam = gl.getParameter(gl.SCISSOR_BOX);
		var viewportParam = gl.getParameter(gl.VIEWPORT);

		this.currentScissor = new Vector4().fromArray(scissorParam);
		this.currentViewport = new Vector4().fromArray(viewportParam);

		this.emptyTextures = new Map();
		this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
		this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
		this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
		this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

		// init

		this.colorBuffer.setClear(0, 0, 0, 1);
		this.depthBuffer.setClear(1);
		this.stencilBuffer.setClear(0);

		this.enable(gl.DEPTH_TEST);
		this.depthBuffer.setFunc(DepthFunc.LessEqualDepth);

		this.setFlipSided(false);
		this.setCullFace(CullFace.CullFaceBack);
		this.enable(gl.CULL_FACE);

		this.setBlending(Blending.NoBlending);

	}

	public function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {

		var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
		var texture = gl.createTexture();

		gl.bindTexture(type, texture);
		gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
		gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

		for (var i in 0...count) {

			if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {

				gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

			} else {

				gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

			}

		}

		return texture;

	}

	public function enable(id: Int): Void {

		if (this.enabledCapabilities.exists(id) == false || this.enabledCapabilities.get(id) == false) {

			gl.enable(id);
			this.enabledCapabilities.set(id, true);

		}

	}

	public function disable(id: Int): Void {

		if (this.enabledCapabilities.exists(id) == false || this.enabledCapabilities.get(id) == true) {

			gl.disable(id);
			this.enabledCapabilities.set(id, false);

		}

	}

	public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {

		if (this.currentBoundFramebuffers.exists(target) == false || this.currentBoundFramebuffers.get(target) != framebuffer) {

			gl.bindFramebuffer(target, framebuffer);

			this.currentBoundFramebuffers.set(target, framebuffer);

			// gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

			if (target == gl.DRAW_FRAMEBUFFER) {

				this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);

			}

			if (target == gl.FRAMEBUFFER) {

				this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);

			}

			return true;

		}

		return false;

	}

	public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {

		var drawBuffers = this.defaultDrawbuffers;

		var needsUpdate = false;

		if (renderTarget != null) {

			drawBuffers = this.currentDrawbuffers.get(framebuffer);

			if (drawBuffers == null) {

				drawBuffers = [];
				this.currentDrawbuffers.set(framebuffer, drawBuffers);

			}

			var textures = renderTarget.textures;

			if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {

				for (var i in 0...textures.length) {

					drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;

				}

				drawBuffers.length = textures.length;

				needsUpdate = true;

			}

		} else {

			if (drawBuffers[0] != gl.BACK) {

				drawBuffers[0] = gl.BACK;

				needsUpdate = true;

			}

		}

		if (needsUpdate) {

			gl.drawBuffers(drawBuffers);

		}

	}

	public function useProgram(program: WebGLProgram): Bool {

		if (this.currentProgram != program) {

			gl.useProgram(program);

			this.currentProgram = program;

			return true;

		}

		return false;

	}

	public var equationToGL: Map<Equation, Int> = new Map([
		[Equation.AddEquation, gl.FUNC_ADD],
		[Equation.SubtractEquation, gl.FUNC_SUBTRACT],
		[Equation.ReverseSubtractEquation, gl.FUNC_REVERSE_SUBTRACT]
	]);

	equationToGL.set(Equation.MinEquation, gl.MIN);
	equationToGL.set(Equation.MaxEquation, gl.MAX);

	public var factorToGL: Map<Factor, Int> = new Map([
		[Factor.ZeroFactor, gl.ZERO],
		[Factor.OneFactor, gl.ONE],
		[Factor.SrcColorFactor, gl.SRC_COLOR],
		[Factor.SrcAlphaFactor, gl.SRC_ALPHA],
		[Factor.SrcAlphaSaturateFactor, gl.SRC_ALPHA_SATURATE],
		[Factor.DstColorFactor, gl.DST_COLOR],
		[Factor.DstAlphaFactor, gl.DST_ALPHA],
		[Factor.OneMinusSrcColorFactor, gl.ONE_MINUS_SRC_COLOR],
		[Factor.OneMinusSrcAlphaFactor, gl.ONE_MINUS_SRC_ALPHA],
		[Factor.OneMinusDstColorFactor, gl.ONE_MINUS_DST_COLOR],
		[Factor.OneMinusDstAlphaFactor, gl.ONE_MINUS_DST_ALPHA],
		[Factor.ConstantColorFactor, gl.CONSTANT_COLOR],
		[Factor.OneMinusConstantColorFactor, gl.ONE_MINUS_CONSTANT_COLOR],
		[Factor.ConstantAlphaFactor, gl.CONSTANT_ALPHA],
		[Factor.OneMinusConstantAlphaFactor, gl.ONE_MINUS_CONSTANT_ALPHA]
	]);

	public function setBlending(blending: Blending, blendEquation: Equation = Equation.AddEquation, blendSrc: Factor = Factor.SrcAlphaFactor, blendDst: Factor = Factor.OneMinusSrcAlphaFactor, blendEquationAlpha: Equation = Equation.AddEquation, blendSrcAlpha: Factor = Factor.SrcAlphaFactor, blendDstAlpha: Factor = Factor.OneMinusSrcAlphaFactor, blendColor: Color = null, blendAlpha: Float = 1, premultipliedAlpha: Bool = false): Void {

		if (blending == Blending.NoBlending) {

			if (this.currentBlendingEnabled) {

				this.disable(gl.BLEND);
				this.currentBlendingEnabled = false;

			}

			return;

		}

		if (this.currentBlendingEnabled == false) {

			this.enable(gl.BLEND);
			this.currentBlendingEnabled = true;

		}

		if (blending != Blending.CustomBlending) {

			if (blending != this.currentBlending || premultipliedAlpha != this.currentPremultipledAlpha) {

				if (this.currentBlendEquation != Equation.AddEquation || this.currentBlendEquationAlpha != Equation.AddEquation) {

					gl.blendEquation(gl.FUNC_ADD);

					this.currentBlendEquation = Equation.AddEquation;
					this.currentBlendEquationAlpha = Equation.AddEquation;

				}

				if (premultipliedAlpha) {

					switch (blending) {

						case Blending.NormalBlending:
							gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
							break;

						case Blending.AdditiveBlending:
							gl.blendFunc(gl.ONE, gl.ONE);
							break;

						case Blending.SubtractiveBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
							break;

						case Blending.MultiplyBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
							break;

						default:
							console.error("THREE.WebGLState: Invalid blending: ", blending);
							break;

					}

				} else {

					switch (blending) {

						case Blending.NormalBlending:
							gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
							break;

						case Blending.AdditiveBlending:
							gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
							break;

						case Blending.SubtractiveBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
							break;

						case Blending.MultiplyBlending:
							gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
							break;

						default:
							console.error("THREE.WebGLState: Invalid blending: ", blending);
							break;

					}

				}

				this.currentBlendSrc = null;
				this.currentBlendDst = null;
				this.currentBlendSrcAlpha = null;
				this.currentBlendDstAlpha = null;
				this.currentBlendColor.set(0, 0, 0);
				this.currentBlendAlpha = 0;

				this.currentBlending = blending;
				this.currentPremultipledAlpha = premultipliedAlpha;

			}

			return;

		}

		// custom blending

		blendEquationAlpha = blendEquationAlpha != null ? blendEquationAlpha : blendEquation;
		blendSrcAlpha = blendSrcAlpha != null ? blendSrcAlpha : blendSrc;
		blendDstAlpha = blendDstAlpha != null ? blendDstAlpha : blendDst;

		if (blendEquation != this.currentBlendEquation || blendEquationAlpha != this.currentBlendEquationAlpha) {

			gl.blendEquationSeparate(this.equationToGL.get(blendEquation), this.equationToGL.get(blendEquationAlpha));

			this.currentBlendEquation = blendEquation;
			this.currentBlendEquationAlpha = blendEquationAlpha;

		}

		if (blendSrc != this.currentBlendSrc || blendDst != this.currentBlendDst || blendSrcAlpha != this.currentBlendSrcAlpha || blendDstAlpha != this.currentBlendDstAlpha) {

			gl.blendFuncSeparate(this.factorToGL.get(blendSrc), this.factorToGL.get(blendDst), this.factorToGL.get(blendSrcAlpha), this.factorToGL.get(blendDstAlpha));

			this.currentBlendSrc = blendSrc;
			this.currentBlendDst = blendDst;
			this.currentBlendSrcAlpha = blendSrcAlpha;
			this.currentBlendDstAlpha = blendDstAlpha;

		}

		if (blendColor != null && blendColor.equals(this.currentBlendColor) == false || blendAlpha != this.currentBlendAlpha) {

			gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);

			this.currentBlendColor.copy(blendColor);
			this.currentBlendAlpha = blendAlpha;

		}

		this.currentBlending = blending;
		this.currentPremultipledAlpha = false;

	}

	public function setMaterial(material: Dynamic, frontFaceCW: Bool): Void {

		if (material.side == CullFace.DoubleSide) {

			this.disable(gl.CULL_FACE);

		} else {

			this.enable(gl.CULL_FACE);

		}

		var flipSided = (material.side == CullFace.BackSide);
		if (frontFaceCW) flipSided = !flipSided;

		this.setFlipSided(flipSided);

		if (material.blending == Blending.NormalBlending && material.transparent == false) {

			this.setBlending(Blending.NoBlending);

		} else {

			this.setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);

		}

		this.depthBuffer.setFunc(material.depthFunc);
		this.depthBuffer.setTest(material.depthTest);
		this.depthBuffer.setMask(material.depthWrite);
		this.colorBuffer.setMask(material.colorWrite);

		var stencilWrite = material.stencilWrite;
		this.stencilBuffer.setTest(stencilWrite);
		if (stencilWrite) {

			this.stencilBuffer.setMask(material.stencilWriteMask);
			this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
			this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);

		}

		this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);

		if (material.alphaToCoverage) {

			this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		} else {

			this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		}

	}

	public function setFlipSided(flipSided: Bool): Void {

		if (this.currentFlipSided != flipSided) {

			if (flipSided) {

				gl.frontFace(gl.CW);

			} else {

				gl.frontFace(gl.CCW);

			}

			this.currentFlipSided = flipSided;

		}

	}

	public function setCullFace(cullFace: CullFace): Void {

		if (cullFace != CullFace.CullFaceNone) {

			this.enable(gl.CULL_FACE);

			if (cullFace != this.currentCullFace) {

				if (cullFace == CullFace.CullFaceBack) {

					gl.cullFace(gl.BACK);

				} else if (cullFace == CullFace.CullFaceFront) {

					gl.cullFace(gl.FRONT);

				} else {

					gl.cullFace(gl.FRONT_AND_BACK);

				}

			}

		} else {

			this.disable(gl.CULL_FACE);

		}

		this.currentCullFace = cullFace;

	}

	public function setLineWidth(width: Float): Void {

		if (width != this.currentLineWidth) {

			if (this.lineWidthAvailable) gl.lineWidth(width);

			this.currentLineWidth = width;

		}

	}

	public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {

		if (polygonOffset) {

			this.enable(gl.POLYGON_OFFSET_FILL);

			if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {

				gl.polygonOffset(factor, units);

				this.currentPolygonOffsetFactor = factor;
				this.currentPolygonOffsetUnits = units;

			}

		} else {

			this.disable(gl.POLYGON_OFFSET_FILL);

		}

	}

	public function setScissorTest(scissorTest: Bool): Void {

		if (scissorTest) {

			this.enable(gl.SCISSOR_TEST);

		} else {

			this.disable(gl.SCISSOR_TEST);

		}

	}

	public function activeTexture(webglSlot: Int = gl.TEXTURE0 + maxTextures - 1): Void {

		if (this.currentTextureSlot != webglSlot) {

			gl.activeTexture(webglSlot);
			this.currentTextureSlot = webglSlot;

		}

	}

	public function bindTexture(webglType: Int, webglTexture: WebGLTexture, webglSlot: Int = null): Void {

		if (webglSlot == null) {

			if (this.currentTextureSlot == null) {

				webglSlot = gl.TEXTURE0 + maxTextures - 1;

			} else {

				webglSlot = this.currentTextureSlot;

			}

		}

		var boundTexture = this.currentBoundTextures.get(webglSlot);

		if (boundTexture == null) {

			boundTexture = { type: null, texture: null };
			this.currentBoundTextures.set(webglSlot, boundTexture);

		}

		if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {

			if (this.currentTextureSlot != webglSlot) {

				gl.activeTexture(webglSlot);
				this.currentTextureSlot = webglSlot;

			}

			gl.bindTexture(webglType, webglTexture != null ? webglTexture : this.emptyTextures.get(webglType));

			boundTexture.type = webglType;
			boundTexture.texture = webglTexture;

		}

	}

	public function unbindTexture(): Void {

		var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);

		if (boundTexture != null && boundTexture.type != null) {

			gl.bindTexture(boundTexture.type, null);

			boundTexture.type = null;
			boundTexture.texture = null;

		}

	}

	public function compressedTexImage2D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, border: Int, data: Bytes): Void {

		try {

			gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexImage3D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, depth: Int, border: Int, data: Bytes): Void {

		try {

			gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texSubImage2D(target: Int, level: Int, xoffset: Int, yoffset: Int, width: Int, height: Int, format: Int, type: Int, pixels: Dynamic, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texSubImage3D(target: Int, level: Int, xoffset: Int, yoffset: Int, zoffset: Int, width: Int, height: Int, depth: Int, format: Int, type: Int, pixels: Dynamic, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexSubImage2D(target: Int, level: Int, xoffset: Int, yoffset: Int, width: Int, height: Int, format: Int, data: Bytes, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexSubImage3D(target: Int, level: Int, xoffset: Int, yoffset: Int, zoffset: Int, width: Int, height: Int, depth: Int, format: Int, data: Bytes, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texStorage2D(target: Int, levels: Int, internalformat: Int, width: Int, height: Int): Void {

		try {

			gl.texStorage2D(target, levels, internalformat, width, height);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texStorage3D(target: Int, levels: Int, internalformat: Int, width: Int, height: Int, depth: Int): Void {

		try {

			gl.texStorage3D(target, levels, internalformat, width, height, depth);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texImage2D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, border: Int, format: Int = null, type: Int = null, pixels: Dynamic = null, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texImage3D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, depth: Int, border: Int, format: Int = null, type: Int = null, pixels: Dynamic = null, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function scissor(scissor: Vector4): Void {

		if (this.currentScissor.equals(scissor) == false) {

			gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
			this.currentScissor.copy(scissor);

		}

	}

	public function viewport(viewport: Vector4): Void {

		if (this.currentViewport.equals(viewport) == false) {

			gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
			this.currentViewport.copy(viewport);

		}

	}

	public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {

		var mapping = this.uboProgramMap.get(program);

		if (mapping == null) {

			mapping = new WeakMap();

			this.uboProgramMap.set(program, mapping);

		}

		var blockIndex = mapping.get(uniformsGroup);

		if (blockIndex == null) {

			blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);

			mapping.set(uniformsGroup, blockIndex);

		}

	}

	public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {

		var mapping = this.uboProgramMap.get(program);
		var blockIndex = mapping.get(uniformsGroup);

		if (this.uboBindings.get(program) != blockIndex) {

			// bind shader specific block index to global block point
			gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);

			this.uboBindings.set(program, blockIndex);

		}

	}

	public function reset(): Void {

		// reset state

		gl.disable(gl.BLEND);
		gl.disable(gl.CULL_FACE);
		gl.disable(gl.DEPTH_TEST);
		gl.disable(gl.POLYGON_OFFSET_FILL);
		gl.disable(gl.SCISSOR_TEST);
		gl.disable(gl.STENCIL_TEST);
		gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		gl.blendEquation(gl.FUNC_ADD);
		gl.blendFunc(gl.ONE, gl.ZERO);
		gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
		gl.blendColor(0, 0, 0, 0);

		gl.colorMask(true, true, true, true);
		gl.clearColor(0, 0, 0, 0);

		gl.depthMask(true);
		gl.depthFunc(gl.LESS);
		gl.clearDepth(1);

		gl.stencilMask(0xffffffff);
		gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
		gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
		gl.clearStencil(0);

		gl.cullFace(gl.BACK);
		gl.frontFace(gl.CCW);

		gl.polygonOffset(0, 0);

		gl.activeTexture(gl.TEXTURE0);

		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
		gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
		gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);

		gl.useProgram(null);

		gl.lineWidth(1);

		gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
		gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

		// reset internals

		this.enabledCapabilities = new Map();

		this.currentTextureSlot = null;
		this.currentBoundTextures = new Map();

		this.currentBoundFramebuffers = new Map();
		this.currentDrawbuffers = new WeakMap();
		this.defaultDrawbuffers = [];

		this.currentProgram = null;

		this.currentBlendingEnabled = false;
		this.currentBlending = null;
		this.currentBlendEquation = null;
		this.currentBlendSrc = null;
		this.currentBlendDst = null;
		this.currentBlendEquationAlpha = null;
		this.currentBlendSrcAlpha = null;
		this.currentBlendDstAlpha = null;
		this.currentBlendColor = new Color(0, 0, 0);
		this.currentBlendAlpha = 0;
		this.currentPremultipledAlpha = false;

		this.currentFlipSided = null;
		this.currentCullFace = null;

		this.currentLineWidth = null;

		this.currentPolygonOffsetFactor = null;
		this.currentPolygonOffsetUnits = null;

		this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
		this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);

		this.colorBuffer.reset();
		this.depthBuffer.reset();
		this.stencilBuffer.reset();

	}

}

class ColorBuffer {

	public var locked: Bool;

	public var color: Vector4;
	public var currentColorMask: Bool;
	public var currentColorClear: Vector4;

	public function new() {

		this.locked = false;

		this.color = new Vector4();
		this.currentColorMask = null;
		this.currentColorClear = new Vector4(0, 0, 0, 0);

	}

	public function setMask(colorMask: Bool): Void {

		if (this.currentColorMask != colorMask && !this.locked) {

			gl.colorMask(colorMask, colorMask, colorMask, colorMask);
			this.currentColorMask = colorMask;

		}

	}

	public function setLocked(lock: Bool): Void {

		this.locked = lock;

	}

	public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {

		if (premultipliedAlpha) {

			r *= a;
			g *= a;
			b *= a;

		}

		this.color.set(r, g, b, a);

		if (this.currentColorClear.equals(this.color) == false) {

			gl.clearColor(r, g, b, a);
			this.currentColorClear.copy(this.color);

		}

	}

	public function reset(): Void {

		this.locked = false;

		this.currentColorMask = null;
		this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state

	}

}

class DepthBuffer {

	public var locked: Bool;

	public var currentDepthMask: Bool;
	public var currentDepthFunc: DepthFunc;
	public var currentDepthClear: Float;

	public function new() {

		this.locked = false;

		this.currentDepthMask = null;
		this.currentDepthFunc = null;
		this.currentDepthClear = null;

	}

	public function setTest(depthTest: Bool): Void {

		if (depthTest) {

			gl.
import haxe.io.Bytes;
import three.constants.Blending;
import three.constants.CullFace;
import three.constants.DepthFunc;
import three.constants.Equation;
import three.constants.Factor;
import three.math.Color;
import three.math.Vector4;

class WebGLState {

	public var gl: WebGLRenderingContext;

	public var colorBuffer: ColorBuffer;
	public var depthBuffer: DepthBuffer;
	public var stencilBuffer: StencilBuffer;

	public var uboBindings: WeakMap<WebGLProgram, Int>;
	public var uboProgramMap: WeakMap<WebGLProgram, WeakMap<Dynamic, Int>>;

	public var enabledCapabilities: Map<Int, Bool>;

	public var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
	public var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
	public var defaultDrawbuffers: Array<Int>;

	public var currentProgram: WebGLProgram;

	public var currentBlendingEnabled: Bool;
	public var currentBlending: Blending;
	public var currentBlendEquation: Equation;
	public var currentBlendSrc: Factor;
	public var currentBlendDst: Factor;
	public var currentBlendEquationAlpha: Equation;
	public var currentBlendSrcAlpha: Factor;
	public var currentBlendDstAlpha: Factor;
	public var currentBlendColor: Color;
	public var currentBlendAlpha: Float;
	public var currentPremultipledAlpha: Bool;

	public var currentFlipSided: Bool;
	public var currentCullFace: CullFace;

	public var currentLineWidth: Float;

	public var currentPolygonOffsetFactor: Float;
	public var currentPolygonOffsetUnits: Float;

	public var maxTextures: Int;

	public var lineWidthAvailable: Bool;
	public var version: Float;

	public var currentTextureSlot: Int;
	public var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;

	public var currentScissor: Vector4;
	public var currentViewport: Vector4;

	public var emptyTextures: Map<Int, WebGLTexture>;

	public function new(gl: WebGLRenderingContext) {

		this.gl = gl;

		this.colorBuffer = new ColorBuffer();
		this.depthBuffer = new DepthBuffer();
		this.stencilBuffer = new StencilBuffer();

		this.uboBindings = new WeakMap();
		this.uboProgramMap = new WeakMap();

		this.enabledCapabilities = new Map();

		this.currentBoundFramebuffers = new Map();
		this.currentDrawbuffers = new WeakMap();
		this.defaultDrawbuffers = [];

		this.currentProgram = null;

		this.currentBlendingEnabled = false;
		this.currentBlending = null;
		this.currentBlendEquation = null;
		this.currentBlendSrc = null;
		this.currentBlendDst = null;
		this.currentBlendEquationAlpha = null;
		this.currentBlendSrcAlpha = null;
		this.currentBlendDstAlpha = null;
		this.currentBlendColor = new Color(0, 0, 0);
		this.currentBlendAlpha = 0;
		this.currentPremultipledAlpha = false;

		this.currentFlipSided = null;
		this.currentCullFace = null;

		this.currentLineWidth = null;

		this.currentPolygonOffsetFactor = null;
		this.currentPolygonOffsetUnits = null;

		this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

		this.lineWidthAvailable = false;
		this.version = 0;
		var glVersion = gl.getParameter(gl.VERSION);

		if (glVersion.indexOf("WebGL") != - 1) {

			this.version = Std.parseFloat(glVersion.split(" ")[1]);
			this.lineWidthAvailable = (this.version >= 1.0);

		} else if (glVersion.indexOf("OpenGL ES") != - 1) {

			this.version = Std.parseFloat(glVersion.split(" ")[2]);
			this.lineWidthAvailable = (this.version >= 2.0);

		}

		this.currentTextureSlot = null;
		this.currentBoundTextures = new Map();

		var scissorParam = gl.getParameter(gl.SCISSOR_BOX);
		var viewportParam = gl.getParameter(gl.VIEWPORT);

		this.currentScissor = new Vector4().fromArray(scissorParam);
		this.currentViewport = new Vector4().fromArray(viewportParam);

		this.emptyTextures = new Map();
		this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
		this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
		this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
		this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

		// init

		this.colorBuffer.setClear(0, 0, 0, 1);
		this.depthBuffer.setClear(1);
		this.stencilBuffer.setClear(0);

		this.enable(gl.DEPTH_TEST);
		this.depthBuffer.setFunc(DepthFunc.LessEqualDepth);

		this.setFlipSided(false);
		this.setCullFace(CullFace.CullFaceBack);
		this.enable(gl.CULL_FACE);

		this.setBlending(Blending.NoBlending);

	}

	public function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {

		var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
		var texture = gl.createTexture();

		gl.bindTexture(type, texture);
		gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
		gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

		for (var i in 0...count) {

			if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {

				gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

			} else {

				gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

			}

		}

		return texture;

	}

	public function enable(id: Int): Void {

		if (this.enabledCapabilities.exists(id) == false || this.enabledCapabilities.get(id) == false) {

			gl.enable(id);
			this.enabledCapabilities.set(id, true);

		}

	}

	public function disable(id: Int): Void {

		if (this.enabledCapabilities.exists(id) == false || this.enabledCapabilities.get(id) == true) {

			gl.disable(id);
			this.enabledCapabilities.set(id, false);

		}

	}

	public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {

		if (this.currentBoundFramebuffers.exists(target) == false || this.currentBoundFramebuffers.get(target) != framebuffer) {

			gl.bindFramebuffer(target, framebuffer);

			this.currentBoundFramebuffers.set(target, framebuffer);

			// gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

			if (target == gl.DRAW_FRAMEBUFFER) {

				this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);

			}

			if (target == gl.FRAMEBUFFER) {

				this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);

			}

			return true;

		}

		return false;

	}

	public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {

		var drawBuffers = this.defaultDrawbuffers;

		var needsUpdate = false;

		if (renderTarget != null) {

			drawBuffers = this.currentDrawbuffers.get(framebuffer);

			if (drawBuffers == null) {

				drawBuffers = [];
				this.currentDrawbuffers.set(framebuffer, drawBuffers);

			}

			var textures = renderTarget.textures;

			if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {

				for (var i in 0...textures.length) {

					drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;

				}

				drawBuffers.length = textures.length;

				needsUpdate = true;

			}

		} else {

			if (drawBuffers[0] != gl.BACK) {

				drawBuffers[0] = gl.BACK;

				needsUpdate = true;

			}

		}

		if (needsUpdate) {

			gl.drawBuffers(drawBuffers);

		}

	}

	public function useProgram(program: WebGLProgram): Bool {

		if (this.currentProgram != program) {

			gl.useProgram(program);

			this.currentProgram = program;

			return true;

		}

		return false;

	}

	public var equationToGL: Map<Equation, Int> = new Map([
		[Equation.AddEquation, gl.FUNC_ADD],
		[Equation.SubtractEquation, gl.FUNC_SUBTRACT],
		[Equation.ReverseSubtractEquation, gl.FUNC_REVERSE_SUBTRACT]
	]);

	equationToGL.set(Equation.MinEquation, gl.MIN);
	equationToGL.set(Equation.MaxEquation, gl.MAX);

	public var factorToGL: Map<Factor, Int> = new Map([
		[Factor.ZeroFactor, gl.ZERO],
		[Factor.OneFactor, gl.ONE],
		[Factor.SrcColorFactor, gl.SRC_COLOR],
		[Factor.SrcAlphaFactor, gl.SRC_ALPHA],
		[Factor.SrcAlphaSaturateFactor, gl.SRC_ALPHA_SATURATE],
		[Factor.DstColorFactor, gl.DST_COLOR],
		[Factor.DstAlphaFactor, gl.DST_ALPHA],
		[Factor.OneMinusSrcColorFactor, gl.ONE_MINUS_SRC_COLOR],
		[Factor.OneMinusSrcAlphaFactor, gl.ONE_MINUS_SRC_ALPHA],
		[Factor.OneMinusDstColorFactor, gl.ONE_MINUS_DST_COLOR],
		[Factor.OneMinusDstAlphaFactor, gl.ONE_MINUS_DST_ALPHA],
		[Factor.ConstantColorFactor, gl.CONSTANT_COLOR],
		[Factor.OneMinusConstantColorFactor, gl.ONE_MINUS_CONSTANT_COLOR],
		[Factor.ConstantAlphaFactor, gl.CONSTANT_ALPHA],
		[Factor.OneMinusConstantAlphaFactor, gl.ONE_MINUS_CONSTANT_ALPHA]
	]);

	public function setBlending(blending: Blending, blendEquation: Equation = Equation.AddEquation, blendSrc: Factor = Factor.SrcAlphaFactor, blendDst: Factor = Factor.OneMinusSrcAlphaFactor, blendEquationAlpha: Equation = Equation.AddEquation, blendSrcAlpha: Factor = Factor.SrcAlphaFactor, blendDstAlpha: Factor = Factor.OneMinusSrcAlphaFactor, blendColor: Color = null, blendAlpha: Float = 1, premultipliedAlpha: Bool = false): Void {

		if (blending == Blending.NoBlending) {

			if (this.currentBlendingEnabled) {

				this.disable(gl.BLEND);
				this.currentBlendingEnabled = false;

			}

			return;

		}

		if (this.currentBlendingEnabled == false) {

			this.enable(gl.BLEND);
			this.currentBlendingEnabled = true;

		}

		if (blending != Blending.CustomBlending) {

			if (blending != this.currentBlending || premultipliedAlpha != this.currentPremultipledAlpha) {

				if (this.currentBlendEquation != Equation.AddEquation || this.currentBlendEquationAlpha != Equation.AddEquation) {

					gl.blendEquation(gl.FUNC_ADD);

					this.currentBlendEquation = Equation.AddEquation;
					this.currentBlendEquationAlpha = Equation.AddEquation;

				}

				if (premultipliedAlpha) {

					switch (blending) {

						case Blending.NormalBlending:
							gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
							break;

						case Blending.AdditiveBlending:
							gl.blendFunc(gl.ONE, gl.ONE);
							break;

						case Blending.SubtractiveBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
							break;

						case Blending.MultiplyBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
							break;

						default:
							console.error("THREE.WebGLState: Invalid blending: ", blending);
							break;

					}

				} else {

					switch (blending) {

						case Blending.NormalBlending:
							gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
							break;

						case Blending.AdditiveBlending:
							gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
							break;

						case Blending.SubtractiveBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
							break;

						case Blending.MultiplyBlending:
							gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
							break;

						default:
							console.error("THREE.WebGLState: Invalid blending: ", blending);
							break;

					}

				}

				this.currentBlendSrc = null;
				this.currentBlendDst = null;
				this.currentBlendSrcAlpha = null;
				this.currentBlendDstAlpha = null;
				this.currentBlendColor.set(0, 0, 0);
				this.currentBlendAlpha = 0;

				this.currentBlending = blending;
				this.currentPremultipledAlpha = premultipliedAlpha;

			}

			return;

		}

		// custom blending

		blendEquationAlpha = blendEquationAlpha != null ? blendEquationAlpha : blendEquation;
		blendSrcAlpha = blendSrcAlpha != null ? blendSrcAlpha : blendSrc;
		blendDstAlpha = blendDstAlpha != null ? blendDstAlpha : blendDst;

		if (blendEquation != this.currentBlendEquation || blendEquationAlpha != this.currentBlendEquationAlpha) {

			gl.blendEquationSeparate(this.equationToGL.get(blendEquation), this.equationToGL.get(blendEquationAlpha));

			this.currentBlendEquation = blendEquation;
			this.currentBlendEquationAlpha = blendEquationAlpha;

		}

		if (blendSrc != this.currentBlendSrc || blendDst != this.currentBlendDst || blendSrcAlpha != this.currentBlendSrcAlpha || blendDstAlpha != this.currentBlendDstAlpha) {

			gl.blendFuncSeparate(this.factorToGL.get(blendSrc), this.factorToGL.get(blendDst), this.factorToGL.get(blendSrcAlpha), this.factorToGL.get(blendDstAlpha));

			this.currentBlendSrc = blendSrc;
			this.currentBlendDst = blendDst;
			this.currentBlendSrcAlpha = blendSrcAlpha;
			this.currentBlendDstAlpha = blendDstAlpha;

		}

		if (blendColor != null && blendColor.equals(this.currentBlendColor) == false || blendAlpha != this.currentBlendAlpha) {

			gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);

			this.currentBlendColor.copy(blendColor);
			this.currentBlendAlpha = blendAlpha;

		}

		this.currentBlending = blending;
		this.currentPremultipledAlpha = false;

	}

	public function setMaterial(material: Dynamic, frontFaceCW: Bool): Void {

		if (material.side == CullFace.DoubleSide) {

			this.disable(gl.CULL_FACE);

		} else {

			this.enable(gl.CULL_FACE);

		}

		var flipSided = (material.side == CullFace.BackSide);
		if (frontFaceCW) flipSided = !flipSided;

		this.setFlipSided(flipSided);

		if (material.blending == Blending.NormalBlending && material.transparent == false) {

			this.setBlending(Blending.NoBlending);

		} else {

			this.setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);

		}

		this.depthBuffer.setFunc(material.depthFunc);
		this.depthBuffer.setTest(material.depthTest);
		this.depthBuffer.setMask(material.depthWrite);
		this.colorBuffer.setMask(material.colorWrite);

		var stencilWrite = material.stencilWrite;
		this.stencilBuffer.setTest(stencilWrite);
		if (stencilWrite) {

			this.stencilBuffer.setMask(material.stencilWriteMask);
			this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
			this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);

		}

		this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);

		if (material.alphaToCoverage) {

			this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		} else {

			this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		}

	}

	public function setFlipSided(flipSided: Bool): Void {

		if (this.currentFlipSided != flipSided) {

			if (flipSided) {

				gl.frontFace(gl.CW);

			} else {

				gl.frontFace(gl.CCW);

			}

			this.currentFlipSided = flipSided;

		}

	}

	public function setCullFace(cullFace: CullFace): Void {

		if (cullFace != CullFace.CullFaceNone) {

			this.enable(gl.CULL_FACE);

			if (cullFace != this.currentCullFace) {

				if (cullFace == CullFace.CullFaceBack) {

					gl.cullFace(gl.BACK);

				} else if (cullFace == CullFace.CullFaceFront) {

					gl.cullFace(gl.FRONT);

				} else {

					gl.cullFace(gl.FRONT_AND_BACK);

				}

			}

		} else {

			this.disable(gl.CULL_FACE);

		}

		this.currentCullFace = cullFace;

	}

	public function setLineWidth(width: Float): Void {

		if (width != this.currentLineWidth) {

			if (this.lineWidthAvailable) gl.lineWidth(width);

			this.currentLineWidth = width;

		}

	}

	public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {

		if (polygonOffset) {

			this.enable(gl.POLYGON_OFFSET_FILL);

			if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {

				gl.polygonOffset(factor, units);

				this.currentPolygonOffsetFactor = factor;
				this.currentPolygonOffsetUnits = units;

			}

		} else {

			this.disable(gl.POLYGON_OFFSET_FILL);

		}

	}

	public function setScissorTest(scissorTest: Bool): Void {

		if (scissorTest) {

			this.enable(gl.SCISSOR_TEST);

		} else {

			this.disable(gl.SCISSOR_TEST);

		}

	}

	public function activeTexture(webglSlot: Int = gl.TEXTURE0 + maxTextures - 1): Void {

		if (this.currentTextureSlot != webglSlot) {

			gl.activeTexture(webglSlot);
			this.currentTextureSlot = webglSlot;

		}

	}

	public function bindTexture(webglType: Int, webglTexture: WebGLTexture, webglSlot: Int = null): Void {

		if (webglSlot == null) {

			if (this.currentTextureSlot == null) {

				webglSlot = gl.TEXTURE0 + maxTextures - 1;

			} else {

				webglSlot = this.currentTextureSlot;

			}

		}

		var boundTexture = this.currentBoundTextures.get(webglSlot);

		if (boundTexture == null) {

			boundTexture = { type: null, texture: null };
			this.currentBoundTextures.set(webglSlot, boundTexture);

		}

		if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {

			if (this.currentTextureSlot != webglSlot) {

				gl.activeTexture(webglSlot);
				this.currentTextureSlot = webglSlot;

			}

			gl.bindTexture(webglType, webglTexture != null ? webglTexture : this.emptyTextures.get(webglType));

			boundTexture.type = webglType;
			boundTexture.texture = webglTexture;

		}

	}

	public function unbindTexture(): Void {

		var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);

		if (boundTexture != null && boundTexture.type != null) {

			gl.bindTexture(boundTexture.type, null);

			boundTexture.type = null;
			boundTexture.texture = null;

		}

	}

	public function compressedTexImage2D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, border: Int, data: Bytes): Void {

		try {

			gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexImage3D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, depth: Int, border: Int, data: Bytes): Void {

		try {

			gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texSubImage2D(target: Int, level: Int, xoffset: Int, yoffset: Int, width: Int, height: Int, format: Int, type: Int, pixels: Dynamic, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texSubImage3D(target: Int, level: Int, xoffset: Int, yoffset: Int, zoffset: Int, width: Int, height: Int, depth: Int, format: Int, type: Int, pixels: Dynamic, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexSubImage2D(target: Int, level: Int, xoffset: Int, yoffset: Int, width: Int, height: Int, format: Int, data: Bytes, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexSubImage3D(target: Int, level: Int, xoffset: Int, yoffset: Int, zoffset: Int, width: Int, height: Int, depth: Int, format: Int, data: Bytes, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texStorage2D(target: Int, levels: Int, internalformat: Int, width: Int, height: Int): Void {

		try {

			gl.texStorage2D(target, levels, internalformat, width, height);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texStorage3D(target: Int, levels: Int, internalformat: Int, width: Int, height: Int, depth: Int): Void {

		try {

			gl.texStorage3D(target, levels, internalformat, width, height, depth);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texImage2D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, border: Int, format: Int = null, type: Int = null, pixels: Dynamic = null, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texImage3D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, depth: Int, border: Int, format: Int = null, type: Int = null, pixels: Dynamic = null, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function scissor(scissor: Vector4): Void {

		if (this.currentScissor.equals(scissor) == false) {

			gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
			this.currentScissor.copy(scissor);

		}

	}

	public function viewport(viewport: Vector4): Void {

		if (this.currentViewport.equals(viewport) == false) {

			gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
			this.currentViewport.copy(viewport);

		}

	}

	public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {

		var mapping = this.uboProgramMap.get(program);

		if (mapping == null) {

			mapping = new WeakMap();

			this.uboProgramMap.set(program, mapping);

		}

		var blockIndex = mapping.get(uniformsGroup);

		if (blockIndex == null) {

			blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);

			mapping.set(uniformsGroup, blockIndex);

		}

	}

	public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {

		var mapping = this.uboProgramMap.get(program);
		var blockIndex = mapping.get(uniformsGroup);

		if (this.uboBindings.get(program) != blockIndex) {

			// bind shader specific block index to global block point
			gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);

			this.uboBindings.set(program, blockIndex);

		}

	}

	public function reset(): Void {

		// reset state

		gl.disable(gl.BLEND);
		gl.disable(gl.CULL_FACE);
		gl.disable(gl.DEPTH_TEST);
		gl.disable(gl.POLYGON_OFFSET_FILL);
		gl.disable(gl.SCISSOR_TEST);
		gl.disable(gl.STENCIL_TEST);
		gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		gl.blendEquation(gl.FUNC_ADD);
		gl.blendFunc(gl.ONE, gl.ZERO);
		gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
		gl.blendColor(0, 0, 0, 0);

		gl.colorMask(true, true, true, true);
		gl.clearColor(0, 0, 0, 0);

		gl.depthMask(true);
		gl.depthFunc(gl.LESS);
		gl.clearDepth(1);

		gl.stencilMask(0xffffffff);
		gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
		gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
		gl.clearStencil(0);

		gl.cullFace(gl.BACK);
		gl.frontFace(gl.CCW);

		gl.polygonOffset(0, 0);

		gl.activeTexture(gl.TEXTURE0);

		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
		gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
		gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);

		gl.useProgram(null);

		gl.lineWidth(1);

		gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
		gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

		// reset internals

		this.enabledCapabilities = new Map();

		this.currentTextureSlot = null;
		this.currentBoundTextures = new Map();

		this.currentBoundFramebuffers = new Map();
		this.currentDrawbuffers = new WeakMap();
		this.defaultDrawbuffers = [];

		this.currentProgram = null;

		this.currentBlendingEnabled = false;
		this.currentBlending = null;
		this.currentBlendEquation = null;
		this.currentBlendSrc = null;
		this.currentBlendDst = null;
		this.currentBlendEquationAlpha = null;
		this.currentBlendSrcAlpha = null;
		this.currentBlendDstAlpha = null;
		this.currentBlendColor = new Color(0, 0, 0);
		this.currentBlendAlpha = 0;
		this.currentPremultipledAlpha = false;

		this.currentFlipSided = null;
		this.currentCullFace = null;

		this.currentLineWidth = null;

		this.currentPolygonOffsetFactor = null;
		this.currentPolygonOffsetUnits = null;

		this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
		this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);

		this.colorBuffer.reset();
		this.depthBuffer.reset();
		this.stencilBuffer.reset();

	}

}

class ColorBuffer {

	public var locked: Bool;

	public var color: Vector4;
	public var currentColorMask: Bool;
	public var currentColorClear: Vector4;

	public function new() {

		this.locked = false;

		this.color = new Vector4();
		this.currentColorMask = null;
		this.currentColorClear = new Vector4(0, 0, 0, 0);

	}

	public function setMask(colorMask: Bool): Void {

		if (this.currentColorMask != colorMask && !this.locked) {

			gl.colorMask(colorMask, colorMask, colorMask, colorMask);
			this.currentColorMask = colorMask;

		}

	}

	public function setLocked(lock: Bool): Void {

		this.locked = lock;

	}

	public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {

		if (premultipliedAlpha) {

			r *= a;
			g *= a;
			b *= a;

		}

		this.color.set(r, g, b, a);

		if (this.currentColorClear.equals(this.color) == false) {

			gl.clearColor(r, g, b, a);
			this.currentColorClear.copy(this.color);

		}

	}

	public function reset(): Void {

		this.locked = false;

		this.currentColorMask = null;
		this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state

	}

}

class DepthBuffer {

	public var locked: Bool;

	public var currentDepthMask: Bool;
	public var currentDepthFunc: DepthFunc;
	public var currentDepthClear: Float;

	public function new() {

		this.locked = false;

		this.currentDepthMask = null;
		this.currentDepthFunc = null;
		this.currentDepthClear = null;

	}

	public function setTest(depthTest: Bool): Void {

		if (depthTest) {

			gl.
import haxe.io.Bytes;
import three.constants.Blending;
import three.constants.CullFace;
import three.constants.DepthFunc;
import three.constants.Equation;
import three.constants.Factor;
import three.math.Color;
import three.math.Vector4;

class WebGLState {

	public var gl: WebGLRenderingContext;

	public var colorBuffer: ColorBuffer;
	public var depthBuffer: DepthBuffer;
	public var stencilBuffer: StencilBuffer;

	public var uboBindings: WeakMap<WebGLProgram, Int>;
	public var uboProgramMap: WeakMap<WebGLProgram, WeakMap<Dynamic, Int>>;

	public var enabledCapabilities: Map<Int, Bool>;

	public var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
	public var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
	public var defaultDrawbuffers: Array<Int>;

	public var currentProgram: WebGLProgram;

	public var currentBlendingEnabled: Bool;
	public var currentBlending: Blending;
	public var currentBlendEquation: Equation;
	public var currentBlendSrc: Factor;
	public var currentBlendDst: Factor;
	public var currentBlendEquationAlpha: Equation;
	public var currentBlendSrcAlpha: Factor;
	public var currentBlendDstAlpha: Factor;
	public var currentBlendColor: Color;
	public var currentBlendAlpha: Float;
	public var currentPremultipledAlpha: Bool;

	public var currentFlipSided: Bool;
	public var currentCullFace: CullFace;

	public var currentLineWidth: Float;

	public var currentPolygonOffsetFactor: Float;
	public var currentPolygonOffsetUnits: Float;

	public var maxTextures: Int;

	public var lineWidthAvailable: Bool;
	public var version: Float;

	public var currentTextureSlot: Int;
	public var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;

	public var currentScissor: Vector4;
	public var currentViewport: Vector4;

	public var emptyTextures: Map<Int, WebGLTexture>;

	public function new(gl: WebGLRenderingContext) {

		this.gl = gl;

		this.colorBuffer = new ColorBuffer();
		this.depthBuffer = new DepthBuffer();
		this.stencilBuffer = new StencilBuffer();

		this.uboBindings = new WeakMap();
		this.uboProgramMap = new WeakMap();

		this.enabledCapabilities = new Map();

		this.currentBoundFramebuffers = new Map();
		this.currentDrawbuffers = new WeakMap();
		this.defaultDrawbuffers = [];

		this.currentProgram = null;

		this.currentBlendingEnabled = false;
		this.currentBlending = null;
		this.currentBlendEquation = null;
		this.currentBlendSrc = null;
		this.currentBlendDst = null;
		this.currentBlendEquationAlpha = null;
		this.currentBlendSrcAlpha = null;
		this.currentBlendDstAlpha = null;
		this.currentBlendColor = new Color(0, 0, 0);
		this.currentBlendAlpha = 0;
		this.currentPremultipledAlpha = false;

		this.currentFlipSided = null;
		this.currentCullFace = null;

		this.currentLineWidth = null;

		this.currentPolygonOffsetFactor = null;
		this.currentPolygonOffsetUnits = null;

		this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

		this.lineWidthAvailable = false;
		this.version = 0;
		var glVersion = gl.getParameter(gl.VERSION);

		if (glVersion.indexOf("WebGL") != - 1) {

			this.version = Std.parseFloat(glVersion.split(" ")[1]);
			this.lineWidthAvailable = (this.version >= 1.0);

		} else if (glVersion.indexOf("OpenGL ES") != - 1) {

			this.version = Std.parseFloat(glVersion.split(" ")[2]);
			this.lineWidthAvailable = (this.version >= 2.0);

		}

		this.currentTextureSlot = null;
		this.currentBoundTextures = new Map();

		var scissorParam = gl.getParameter(gl.SCISSOR_BOX);
		var viewportParam = gl.getParameter(gl.VIEWPORT);

		this.currentScissor = new Vector4().fromArray(scissorParam);
		this.currentViewport = new Vector4().fromArray(viewportParam);

		this.emptyTextures = new Map();
		this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
		this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
		this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
		this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

		// init

		this.colorBuffer.setClear(0, 0, 0, 1);
		this.depthBuffer.setClear(1);
		this.stencilBuffer.setClear(0);

		this.enable(gl.DEPTH_TEST);
		this.depthBuffer.setFunc(DepthFunc.LessEqualDepth);

		this.setFlipSided(false);
		this.setCullFace(CullFace.CullFaceBack);
		this.enable(gl.CULL_FACE);

		this.setBlending(Blending.NoBlending);

	}

	public function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {

		var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
		var texture = gl.createTexture();

		gl.bindTexture(type, texture);
		gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
		gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

		for (var i in 0...count) {

			if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {

				gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

			} else {

				gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

			}

		}

		return texture;

	}

	public function enable(id: Int): Void {

		if (this.enabledCapabilities.exists(id) == false || this.enabledCapabilities.get(id) == false) {

			gl.enable(id);
			this.enabledCapabilities.set(id, true);

		}

	}

	public function disable(id: Int): Void {

		if (this.enabledCapabilities.exists(id) == false || this.enabledCapabilities.get(id) == true) {

			gl.disable(id);
			this.enabledCapabilities.set(id, false);

		}

	}

	public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {

		if (this.currentBoundFramebuffers.exists(target) == false || this.currentBoundFramebuffers.get(target) != framebuffer) {

			gl.bindFramebuffer(target, framebuffer);

			this.currentBoundFramebuffers.set(target, framebuffer);

			// gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

			if (target == gl.DRAW_FRAMEBUFFER) {

				this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);

			}

			if (target == gl.FRAMEBUFFER) {

				this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);

			}

			return true;

		}

		return false;

	}

	public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {

		var drawBuffers = this.defaultDrawbuffers;

		var needsUpdate = false;

		if (renderTarget != null) {

			drawBuffers = this.currentDrawbuffers.get(framebuffer);

			if (drawBuffers == null) {

				drawBuffers = [];
				this.currentDrawbuffers.set(framebuffer, drawBuffers);

			}

			var textures = renderTarget.textures;

			if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {

				for (var i in 0...textures.length) {

					drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;

				}

				drawBuffers.length = textures.length;

				needsUpdate = true;

			}

		} else {

			if (drawBuffers[0] != gl.BACK) {

				drawBuffers[0] = gl.BACK;

				needsUpdate = true;

			}

		}

		if (needsUpdate) {

			gl.drawBuffers(drawBuffers);

		}

	}

	public function useProgram(program: WebGLProgram): Bool {

		if (this.currentProgram != program) {

			gl.useProgram(program);

			this.currentProgram = program;

			return true;

		}

		return false;

	}

	public var equationToGL: Map<Equation, Int> = new Map([
		[Equation.AddEquation, gl.FUNC_ADD],
		[Equation.SubtractEquation, gl.FUNC_SUBTRACT],
		[Equation.ReverseSubtractEquation, gl.FUNC_REVERSE_SUBTRACT]
	]);

	equationToGL.set(Equation.MinEquation, gl.MIN);
	equationToGL.set(Equation.MaxEquation, gl.MAX);

	public var factorToGL: Map<Factor, Int> = new Map([
		[Factor.ZeroFactor, gl.ZERO],
		[Factor.OneFactor, gl.ONE],
		[Factor.SrcColorFactor, gl.SRC_COLOR],
		[Factor.SrcAlphaFactor, gl.SRC_ALPHA],
		[Factor.SrcAlphaSaturateFactor, gl.SRC_ALPHA_SATURATE],
		[Factor.DstColorFactor, gl.DST_COLOR],
		[Factor.DstAlphaFactor, gl.DST_ALPHA],
		[Factor.OneMinusSrcColorFactor, gl.ONE_MINUS_SRC_COLOR],
		[Factor.OneMinusSrcAlphaFactor, gl.ONE_MINUS_SRC_ALPHA],
		[Factor.OneMinusDstColorFactor, gl.ONE_MINUS_DST_COLOR],
		[Factor.OneMinusDstAlphaFactor, gl.ONE_MINUS_DST_ALPHA],
		[Factor.ConstantColorFactor, gl.CONSTANT_COLOR],
		[Factor.OneMinusConstantColorFactor, gl.ONE_MINUS_CONSTANT_COLOR],
		[Factor.ConstantAlphaFactor, gl.CONSTANT_ALPHA],
		[Factor.OneMinusConstantAlphaFactor, gl.ONE_MINUS_CONSTANT_ALPHA]
	]);

	public function setBlending(blending: Blending, blendEquation: Equation = Equation.AddEquation, blendSrc: Factor = Factor.SrcAlphaFactor, blendDst: Factor = Factor.OneMinusSrcAlphaFactor, blendEquationAlpha: Equation = Equation.AddEquation, blendSrcAlpha: Factor = Factor.SrcAlphaFactor, blendDstAlpha: Factor = Factor.OneMinusSrcAlphaFactor, blendColor: Color = null, blendAlpha: Float = 1, premultipliedAlpha: Bool = false): Void {

		if (blending == Blending.NoBlending) {

			if (this.currentBlendingEnabled) {

				this.disable(gl.BLEND);
				this.currentBlendingEnabled = false;

			}

			return;

		}

		if (this.currentBlendingEnabled == false) {

			this.enable(gl.BLEND);
			this.currentBlendingEnabled = true;

		}

		if (blending != Blending.CustomBlending) {

			if (blending != this.currentBlending || premultipliedAlpha != this.currentPremultipledAlpha) {

				if (this.currentBlendEquation != Equation.AddEquation || this.currentBlendEquationAlpha != Equation.AddEquation) {

					gl.blendEquation(gl.FUNC_ADD);

					this.currentBlendEquation = Equation.AddEquation;
					this.currentBlendEquationAlpha = Equation.AddEquation;

				}

				if (premultipliedAlpha) {

					switch (blending) {

						case Blending.NormalBlending:
							gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
							break;

						case Blending.AdditiveBlending:
							gl.blendFunc(gl.ONE, gl.ONE);
							break;

						case Blending.SubtractiveBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
							break;

						case Blending.MultiplyBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
							break;

						default:
							console.error("THREE.WebGLState: Invalid blending: ", blending);
							break;

					}

				} else {

					switch (blending) {

						case Blending.NormalBlending:
							gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
							break;

						case Blending.AdditiveBlending:
							gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
							break;

						case Blending.SubtractiveBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
							break;

						case Blending.MultiplyBlending:
							gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
							break;

						default:
							console.error("THREE.WebGLState: Invalid blending: ", blending);
							break;

					}

				}

				this.currentBlendSrc = null;
				this.currentBlendDst = null;
				this.currentBlendSrcAlpha = null;
				this.currentBlendDstAlpha = null;
				this.currentBlendColor.set(0, 0, 0);
				this.currentBlendAlpha = 0;

				this.currentBlending = blending;
				this.currentPremultipledAlpha = premultipliedAlpha;

			}

			return;

		}

		// custom blending

		blendEquationAlpha = blendEquationAlpha != null ? blendEquationAlpha : blendEquation;
		blendSrcAlpha = blendSrcAlpha != null ? blendSrcAlpha : blendSrc;
		blendDstAlpha = blendDstAlpha != null ? blendDstAlpha : blendDst;

		if (blendEquation != this.currentBlendEquation || blendEquationAlpha != this.currentBlendEquationAlpha) {

			gl.blendEquationSeparate(this.equationToGL.get(blendEquation), this.equationToGL.get(blendEquationAlpha));

			this.currentBlendEquation = blendEquation;
			this.currentBlendEquationAlpha = blendEquationAlpha;

		}

		if (blendSrc != this.currentBlendSrc || blendDst != this.currentBlendDst || blendSrcAlpha != this.currentBlendSrcAlpha || blendDstAlpha != this.currentBlendDstAlpha) {

			gl.blendFuncSeparate(this.factorToGL.get(blendSrc), this.factorToGL.get(blendDst), this.factorToGL.get(blendSrcAlpha), this.factorToGL.get(blendDstAlpha));

			this.currentBlendSrc = blendSrc;
			this.currentBlendDst = blendDst;
			this.currentBlendSrcAlpha = blendSrcAlpha;
			this.currentBlendDstAlpha = blendDstAlpha;

		}

		if (blendColor != null && blendColor.equals(this.currentBlendColor) == false || blendAlpha != this.currentBlendAlpha) {

			gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);

			this.currentBlendColor.copy(blendColor);
			this.currentBlendAlpha = blendAlpha;

		}

		this.currentBlending = blending;
		this.currentPremultipledAlpha = false;

	}

	public function setMaterial(material: Dynamic, frontFaceCW: Bool): Void {

		if (material.side == CullFace.DoubleSide) {

			this.disable(gl.CULL_FACE);

		} else {

			this.enable(gl.CULL_FACE);

		}

		var flipSided = (material.side == CullFace.BackSide);
		if (frontFaceCW) flipSided = !flipSided;

		this.setFlipSided(flipSided);

		if (material.blending == Blending.NormalBlending && material.transparent == false) {

			this.setBlending(Blending.NoBlending);

		} else {

			this.setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);

		}

		this.depthBuffer.setFunc(material.depthFunc);
		this.depthBuffer.setTest(material.depthTest);
		this.depthBuffer.setMask(material.depthWrite);
		this.colorBuffer.setMask(material.colorWrite);

		var stencilWrite = material.stencilWrite;
		this.stencilBuffer.setTest(stencilWrite);
		if (stencilWrite) {

			this.stencilBuffer.setMask(material.stencilWriteMask);
			this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
			this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);

		}

		this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);

		if (material.alphaToCoverage) {

			this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		} else {

			this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		}

	}

	public function setFlipSided(flipSided: Bool): Void {

		if (this.currentFlipSided != flipSided) {

			if (flipSided) {

				gl.frontFace(gl.CW);

			} else {

				gl.frontFace(gl.CCW);

			}

			this.currentFlipSided = flipSided;

		}

	}

	public function setCullFace(cullFace: CullFace): Void {

		if (cullFace != CullFace.CullFaceNone) {

			this.enable(gl.CULL_FACE);

			if (cullFace != this.currentCullFace) {

				if (cullFace == CullFace.CullFaceBack) {

					gl.cullFace(gl.BACK);

				} else if (cullFace == CullFace.CullFaceFront) {

					gl.cullFace(gl.FRONT);

				} else {

					gl.cullFace(gl.FRONT_AND_BACK);

				}

			}

		} else {

			this.disable(gl.CULL_FACE);

		}

		this.currentCullFace = cullFace;

	}

	public function setLineWidth(width: Float): Void {

		if (width != this.currentLineWidth) {

			if (this.lineWidthAvailable) gl.lineWidth(width);

			this.currentLineWidth = width;

		}

	}

	public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {

		if (polygonOffset) {

			this.enable(gl.POLYGON_OFFSET_FILL);

			if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {

				gl.polygonOffset(factor, units);

				this.currentPolygonOffsetFactor = factor;
				this.currentPolygonOffsetUnits = units;

			}

		} else {

			this.disable(gl.POLYGON_OFFSET_FILL);

		}

	}

	public function setScissorTest(scissorTest: Bool): Void {

		if (scissorTest) {

			this.enable(gl.SCISSOR_TEST);

		} else {

			this.disable(gl.SCISSOR_TEST);

		}

	}

	public function activeTexture(webglSlot: Int = gl.TEXTURE0 + maxTextures - 1): Void {

		if (this.currentTextureSlot != webglSlot) {

			gl.activeTexture(webglSlot);
			this.currentTextureSlot = webglSlot;

		}

	}

	public function bindTexture(webglType: Int, webglTexture: WebGLTexture, webglSlot: Int = null): Void {

		if (webglSlot == null) {

			if (this.currentTextureSlot == null) {

				webglSlot = gl.TEXTURE0 + maxTextures - 1;

			} else {

				webglSlot = this.currentTextureSlot;

			}

		}

		var boundTexture = this.currentBoundTextures.get(webglSlot);

		if (boundTexture == null) {

			boundTexture = { type: null, texture: null };
			this.currentBoundTextures.set(webglSlot, boundTexture);

		}

		if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {

			if (this.currentTextureSlot != webglSlot) {

				gl.activeTexture(webglSlot);
				this.currentTextureSlot = webglSlot;

			}

			gl.bindTexture(webglType, webglTexture != null ? webglTexture : this.emptyTextures.get(webglType));

			boundTexture.type = webglType;
			boundTexture.texture = webglTexture;

		}

	}

	public function unbindTexture(): Void {

		var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);

		if (boundTexture != null && boundTexture.type != null) {

			gl.bindTexture(boundTexture.type, null);

			boundTexture.type = null;
			boundTexture.texture = null;

		}

	}

	public function compressedTexImage2D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, border: Int, data: Bytes): Void {

		try {

			gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexImage3D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, depth: Int, border: Int, data: Bytes): Void {

		try {

			gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texSubImage2D(target: Int, level: Int, xoffset: Int, yoffset: Int, width: Int, height: Int, format: Int, type: Int, pixels: Dynamic, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texSubImage3D(target: Int, level: Int, xoffset: Int, yoffset: Int, zoffset: Int, width: Int, height: Int, depth: Int, format: Int, type: Int, pixels: Dynamic, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexSubImage2D(target: Int, level: Int, xoffset: Int, yoffset: Int, width: Int, height: Int, format: Int, data: Bytes, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexSubImage3D(target: Int, level: Int, xoffset: Int, yoffset: Int, zoffset: Int, width: Int, height: Int, depth: Int, format: Int, data: Bytes, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texStorage2D(target: Int, levels: Int, internalformat: Int, width: Int, height: Int): Void {

		try {

			gl.texStorage2D(target, levels, internalformat, width, height);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texStorage3D(target: Int, levels: Int, internalformat: Int, width: Int, height: Int, depth: Int): Void {

		try {

			gl.texStorage3D(target, levels, internalformat, width, height, depth);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texImage2D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, border: Int, format: Int = null, type: Int = null, pixels: Dynamic = null, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texImage3D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, depth: Int, border: Int, format: Int = null, type: Int = null, pixels: Dynamic = null, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function scissor(scissor: Vector4): Void {

		if (this.currentScissor.equals(scissor) == false) {

			gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
			this.currentScissor.copy(scissor);

		}

	}

	public function viewport(viewport: Vector4): Void {

		if (this.currentViewport.equals(viewport) == false) {

			gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
			this.currentViewport.copy(viewport);

		}

	}

	public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {

		var mapping = this.uboProgramMap.get(program);

		if (mapping == null) {

			mapping = new WeakMap();

			this.uboProgramMap.set(program, mapping);

		}

		var blockIndex = mapping.get(uniformsGroup);

		if (blockIndex == null) {

			blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);

			mapping.set(uniformsGroup, blockIndex);

		}

	}

	public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {

		var mapping = this.uboProgramMap.get(program);
		var blockIndex = mapping.get(uniformsGroup);

		if (this.uboBindings.get(program) != blockIndex) {

			// bind shader specific block index to global block point
			gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);

			this.uboBindings.set(program, blockIndex);

		}

	}

	public function reset(): Void {

		// reset state

		gl.disable(gl.BLEND);
		gl.disable(gl.CULL_FACE);
		gl.disable(gl.DEPTH_TEST);
		gl.disable(gl.POLYGON_OFFSET_FILL);
		gl.disable(gl.SCISSOR_TEST);
		gl.disable(gl.STENCIL_TEST);
		gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		gl.blendEquation(gl.FUNC_ADD);
		gl.blendFunc(gl.ONE, gl.ZERO);
		gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
		gl.blendColor(0, 0, 0, 0);

		gl.colorMask(true, true, true, true);
		gl.clearColor(0, 0, 0, 0);

		gl.depthMask(true);
		gl.depthFunc(gl.LESS);
		gl.clearDepth(1);

		gl.stencilMask(0xffffffff);
		gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
		gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
		gl.clearStencil(0);

		gl.cullFace(gl.BACK);
		gl.frontFace(gl.CCW);

		gl.polygonOffset(0, 0);

		gl.activeTexture(gl.TEXTURE0);

		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
		gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
		gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);

		gl.useProgram(null);

		gl.lineWidth(1);

		gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
		gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

		// reset internals

		this.enabledCapabilities = new Map();

		this.currentTextureSlot = null;
		this.currentBoundTextures = new Map();

		this.currentBoundFramebuffers = new Map();
		this.currentDrawbuffers = new WeakMap();
		this.defaultDrawbuffers = [];

		this.currentProgram = null;

		this.currentBlendingEnabled = false;
		this.currentBlending = null;
		this.currentBlendEquation = null;
		this.currentBlendSrc = null;
		this.currentBlendDst = null;
		this.currentBlendEquationAlpha = null;
		this.currentBlendSrcAlpha = null;
		this.currentBlendDstAlpha = null;
		this.currentBlendColor = new Color(0, 0, 0);
		this.currentBlendAlpha = 0;
		this.currentPremultipledAlpha = false;

		this.currentFlipSided = null;
		this.currentCullFace = null;

		this.currentLineWidth = null;

		this.currentPolygonOffsetFactor = null;
		this.currentPolygonOffsetUnits = null;

		this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
		this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);

		this.colorBuffer.reset();
		this.depthBuffer.reset();
		this.stencilBuffer.reset();

	}

}

class ColorBuffer {

	public var locked: Bool;

	public var color: Vector4;
	public var currentColorMask: Bool;
	public var currentColorClear: Vector4;

	public function new() {

		this.locked = false;

		this.color = new Vector4();
		this.currentColorMask = null;
		this.currentColorClear = new Vector4(0, 0, 0, 0);

	}

	public function setMask(colorMask: Bool): Void {

		if (this.currentColorMask != colorMask && !this.locked) {

			gl.colorMask(colorMask, colorMask, colorMask, colorMask);
			this.currentColorMask = colorMask;

		}

	}

	public function setLocked(lock: Bool): Void {

		this.locked = lock;

	}

	public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {

		if (premultipliedAlpha) {

			r *= a;
			g *= a;
			b *= a;

		}

		this.color.set(r, g, b, a);

		if (this.currentColorClear.equals(this.color) == false) {

			gl.clearColor(r, g, b, a);
			this.currentColorClear.copy(this.color);

		}

	}

	public function reset(): Void {

		this.locked = false;

		this.currentColorMask = null;
		this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state

	}

}

class DepthBuffer {

	public var locked: Bool;

	public var currentDepthMask: Bool;
	public var currentDepthFunc: DepthFunc;
	public var currentDepthClear: Float;

	public function new() {

		this.locked = false;

		this.currentDepthMask = null;
		this.currentDepthFunc = null;
		this.currentDepthClear = null;

	}

	public function setTest(depthTest: Bool): Void {

		if (depthTest) {

			gl.
import haxe.io.Bytes;
import three.constants.Blending;
import three.constants.CullFace;
import three.constants.DepthFunc;
import three.constants.Equation;
import three.constants.Factor;
import three.math.Color;
import three.math.Vector4;

class WebGLState {

	public var gl: WebGLRenderingContext;

	public var colorBuffer: ColorBuffer;
	public var depthBuffer: DepthBuffer;
	public var stencilBuffer: StencilBuffer;

	public var uboBindings: WeakMap<WebGLProgram, Int>;
	public var uboProgramMap: WeakMap<WebGLProgram, WeakMap<Dynamic, Int>>;

	public var enabledCapabilities: Map<Int, Bool>;

	public var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
	public var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
	public var defaultDrawbuffers: Array<Int>;

	public var currentProgram: WebGLProgram;

	public var currentBlendingEnabled: Bool;
	public var currentBlending: Blending;
	public var currentBlendEquation: Equation;
	public var currentBlendSrc: Factor;
	public var currentBlendDst: Factor;
	public var currentBlendEquationAlpha: Equation;
	public var currentBlendSrcAlpha: Factor;
	public var currentBlendDstAlpha: Factor;
	public var currentBlendColor: Color;
	public var currentBlendAlpha: Float;
	public var currentPremultipledAlpha: Bool;

	public var currentFlipSided: Bool;
	public var currentCullFace: CullFace;

	public var currentLineWidth: Float;

	public var currentPolygonOffsetFactor: Float;
	public var currentPolygonOffsetUnits: Float;

	public var maxTextures: Int;

	public var lineWidthAvailable: Bool;
	public var version: Float;

	public var currentTextureSlot: Int;
	public var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;

	public var currentScissor: Vector4;
	public var currentViewport: Vector4;

	public var emptyTextures: Map<Int, WebGLTexture>;

	public function new(gl: WebGLRenderingContext) {

		this.gl = gl;

		this.colorBuffer = new ColorBuffer();
		this.depthBuffer = new DepthBuffer();
		this.stencilBuffer = new StencilBuffer();

		this.uboBindings = new WeakMap();
		this.uboProgramMap = new WeakMap();

		this.enabledCapabilities = new Map();

		this.currentBoundFramebuffers = new Map();
		this.currentDrawbuffers = new WeakMap();
		this.defaultDrawbuffers = [];

		this.currentProgram = null;

		this.currentBlendingEnabled = false;
		this.currentBlending = null;
		this.currentBlendEquation = null;
		this.currentBlendSrc = null;
		this.currentBlendDst = null;
		this.currentBlendEquationAlpha = null;
		this.currentBlendSrcAlpha = null;
		this.currentBlendDstAlpha = null;
		this.currentBlendColor = new Color(0, 0, 0);
		this.currentBlendAlpha = 0;
		this.currentPremultipledAlpha = false;

		this.currentFlipSided = null;
		this.currentCullFace = null;

		this.currentLineWidth = null;

		this.currentPolygonOffsetFactor = null;
		this.currentPolygonOffsetUnits = null;

		this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

		this.lineWidthAvailable = false;
		this.version = 0;
		var glVersion = gl.getParameter(gl.VERSION);

		if (glVersion.indexOf("WebGL") != - 1) {

			this.version = Std.parseFloat(glVersion.split(" ")[1]);
			this.lineWidthAvailable = (this.version >= 1.0);

		} else if (glVersion.indexOf("OpenGL ES") != - 1) {

			this.version = Std.parseFloat(glVersion.split(" ")[2]);
			this.lineWidthAvailable = (this.version >= 2.0);

		}

		this.currentTextureSlot = null;
		this.currentBoundTextures = new Map();

		var scissorParam = gl.getParameter(gl.SCISSOR_BOX);
		var viewportParam = gl.getParameter(gl.VIEWPORT);

		this.currentScissor = new Vector4().fromArray(scissorParam);
		this.currentViewport = new Vector4().fromArray(viewportParam);

		this.emptyTextures = new Map();
		this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
		this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
		this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
		this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

		// init

		this.colorBuffer.setClear(0, 0, 0, 1);
		this.depthBuffer.setClear(1);
		this.stencilBuffer.setClear(0);

		this.enable(gl.DEPTH_TEST);
		this.depthBuffer.setFunc(DepthFunc.LessEqualDepth);

		this.setFlipSided(false);
		this.setCullFace(CullFace.CullFaceBack);
		this.enable(gl.CULL_FACE);

		this.setBlending(Blending.NoBlending);

	}

	public function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {

		var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
		var texture = gl.createTexture();

		gl.bindTexture(type, texture);
		gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
		gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

		for (var i in 0...count) {

			if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {

				gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

			} else {

				gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

			}

		}

		return texture;

	}

	public function enable(id: Int): Void {

		if (this.enabledCapabilities.exists(id) == false || this.enabledCapabilities.get(id) == false) {

			gl.enable(id);
			this.enabledCapabilities.set(id, true);

		}

	}

	public function disable(id: Int): Void {

		if (this.enabledCapabilities.exists(id) == false || this.enabledCapabilities.get(id) == true) {

			gl.disable(id);
			this.enabledCapabilities.set(id, false);

		}

	}

	public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {

		if (this.currentBoundFramebuffers.exists(target) == false || this.currentBoundFramebuffers.get(target) != framebuffer) {

			gl.bindFramebuffer(target, framebuffer);

			this.currentBoundFramebuffers.set(target, framebuffer);

			// gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

			if (target == gl.DRAW_FRAMEBUFFER) {

				this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);

			}

			if (target == gl.FRAMEBUFFER) {

				this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);

			}

			return true;

		}

		return false;

	}

	public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {

		var drawBuffers = this.defaultDrawbuffers;

		var needsUpdate = false;

		if (renderTarget != null) {

			drawBuffers = this.currentDrawbuffers.get(framebuffer);

			if (drawBuffers == null) {

				drawBuffers = [];
				this.currentDrawbuffers.set(framebuffer, drawBuffers);

			}

			var textures = renderTarget.textures;

			if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {

				for (var i in 0...textures.length) {

					drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;

				}

				drawBuffers.length = textures.length;

				needsUpdate = true;

			}

		} else {

			if (drawBuffers[0] != gl.BACK) {

				drawBuffers[0] = gl.BACK;

				needsUpdate = true;

			}

		}

		if (needsUpdate) {

			gl.drawBuffers(drawBuffers);

		}

	}

	public function useProgram(program: WebGLProgram): Bool {

		if (this.currentProgram != program) {

			gl.useProgram(program);

			this.currentProgram = program;

			return true;

		}

		return false;

	}

	public var equationToGL: Map<Equation, Int> = new Map([
		[Equation.AddEquation, gl.FUNC_ADD],
		[Equation.SubtractEquation, gl.FUNC_SUBTRACT],
		[Equation.ReverseSubtractEquation, gl.FUNC_REVERSE_SUBTRACT]
	]);

	equationToGL.set(Equation.MinEquation, gl.MIN);
	equationToGL.set(Equation.MaxEquation, gl.MAX);

	public var factorToGL: Map<Factor, Int> = new Map([
		[Factor.ZeroFactor, gl.ZERO],
		[Factor.OneFactor, gl.ONE],
		[Factor.SrcColorFactor, gl.SRC_COLOR],
		[Factor.SrcAlphaFactor, gl.SRC_ALPHA],
		[Factor.SrcAlphaSaturateFactor, gl.SRC_ALPHA_SATURATE],
		[Factor.DstColorFactor, gl.DST_COLOR],
		[Factor.DstAlphaFactor, gl.DST_ALPHA],
		[Factor.OneMinusSrcColorFactor, gl.ONE_MINUS_SRC_COLOR],
		[Factor.OneMinusSrcAlphaFactor, gl.ONE_MINUS_SRC_ALPHA],
		[Factor.OneMinusDstColorFactor, gl.ONE_MINUS_DST_COLOR],
		[Factor.OneMinusDstAlphaFactor, gl.ONE_MINUS_DST_ALPHA],
		[Factor.ConstantColorFactor, gl.CONSTANT_COLOR],
		[Factor.OneMinusConstantColorFactor, gl.ONE_MINUS_CONSTANT_COLOR],
		[Factor.ConstantAlphaFactor, gl.CONSTANT_ALPHA],
		[Factor.OneMinusConstantAlphaFactor, gl.ONE_MINUS_CONSTANT_ALPHA]
	]);

	public function setBlending(blending: Blending, blendEquation: Equation = Equation.AddEquation, blendSrc: Factor = Factor.SrcAlphaFactor, blendDst: Factor = Factor.OneMinusSrcAlphaFactor, blendEquationAlpha: Equation = Equation.AddEquation, blendSrcAlpha: Factor = Factor.SrcAlphaFactor, blendDstAlpha: Factor = Factor.OneMinusSrcAlphaFactor, blendColor: Color = null, blendAlpha: Float = 1, premultipliedAlpha: Bool = false): Void {

		if (blending == Blending.NoBlending) {

			if (this.currentBlendingEnabled) {

				this.disable(gl.BLEND);
				this.currentBlendingEnabled = false;

			}

			return;

		}

		if (this.currentBlendingEnabled == false) {

			this.enable(gl.BLEND);
			this.currentBlendingEnabled = true;

		}

		if (blending != Blending.CustomBlending) {

			if (blending != this.currentBlending || premultipliedAlpha != this.currentPremultipledAlpha) {

				if (this.currentBlendEquation != Equation.AddEquation || this.currentBlendEquationAlpha != Equation.AddEquation) {

					gl.blendEquation(gl.FUNC_ADD);

					this.currentBlendEquation = Equation.AddEquation;
					this.currentBlendEquationAlpha = Equation.AddEquation;

				}

				if (premultipliedAlpha) {

					switch (blending) {

						case Blending.NormalBlending:
							gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
							break;

						case Blending.AdditiveBlending:
							gl.blendFunc(gl.ONE, gl.ONE);
							break;

						case Blending.SubtractiveBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
							break;

						case Blending.MultiplyBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
							break;

						default:
							console.error("THREE.WebGLState: Invalid blending: ", blending);
							break;

					}

				} else {

					switch (blending) {

						case Blending.NormalBlending:
							gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
							break;

						case Blending.AdditiveBlending:
							gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
							break;

						case Blending.SubtractiveBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
							break;

						case Blending.MultiplyBlending:
							gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
							break;

						default:
							console.error("THREE.WebGLState: Invalid blending: ", blending);
							break;

					}

				}

				this.currentBlendSrc = null;
				this.currentBlendDst = null;
				this.currentBlendSrcAlpha = null;
				this.currentBlendDstAlpha = null;
				this.currentBlendColor.set(0, 0, 0);
				this.currentBlendAlpha = 0;

				this.currentBlending = blending;
				this.currentPremultipledAlpha = premultipliedAlpha;

			}

			return;

		}

		// custom blending

		blendEquationAlpha = blendEquationAlpha != null ? blendEquationAlpha : blendEquation;
		blendSrcAlpha = blendSrcAlpha != null ? blendSrcAlpha : blendSrc;
		blendDstAlpha = blendDstAlpha != null ? blendDstAlpha : blendDst;

		if (blendEquation != this.currentBlendEquation || blendEquationAlpha != this.currentBlendEquationAlpha) {

			gl.blendEquationSeparate(this.equationToGL.get(blendEquation), this.equationToGL.get(blendEquationAlpha));

			this.currentBlendEquation = blendEquation;
			this.currentBlendEquationAlpha = blendEquationAlpha;

		}

		if (blendSrc != this.currentBlendSrc || blendDst != this.currentBlendDst || blendSrcAlpha != this.currentBlendSrcAlpha || blendDstAlpha != this.currentBlendDstAlpha) {

			gl.blendFuncSeparate(this.factorToGL.get(blendSrc), this.factorToGL.get(blendDst), this.factorToGL.get(blendSrcAlpha), this.factorToGL.get(blendDstAlpha));

			this.currentBlendSrc = blendSrc;
			this.currentBlendDst = blendDst;
			this.currentBlendSrcAlpha = blendSrcAlpha;
			this.currentBlendDstAlpha = blendDstAlpha;

		}

		if (blendColor != null && blendColor.equals(this.currentBlendColor) == false || blendAlpha != this.currentBlendAlpha) {

			gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);

			this.currentBlendColor.copy(blendColor);
			this.currentBlendAlpha = blendAlpha;

		}

		this.currentBlending = blending;
		this.currentPremultipledAlpha = false;

	}

	public function setMaterial(material: Dynamic, frontFaceCW: Bool): Void {

		if (material.side == CullFace.DoubleSide) {

			this.disable(gl.CULL_FACE);

		} else {

			this.enable(gl.CULL_FACE);

		}

		var flipSided = (material.side == CullFace.BackSide);
		if (frontFaceCW) flipSided = !flipSided;

		this.setFlipSided(flipSided);

		if (material.blending == Blending.NormalBlending && material.transparent == false) {

			this.setBlending(Blending.NoBlending);

		} else {

			this.setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);

		}

		this.depthBuffer.setFunc(material.depthFunc);
		this.depthBuffer.setTest(material.depthTest);
		this.depthBuffer.setMask(material.depthWrite);
		this.colorBuffer.setMask(material.colorWrite);

		var stencilWrite = material.stencilWrite;
		this.stencilBuffer.setTest(stencilWrite);
		if (stencilWrite) {

			this.stencilBuffer.setMask(material.stencilWriteMask);
			this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
			this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);

		}

		this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);

		if (material.alphaToCoverage) {

			this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		} else {

			this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		}

	}

	public function setFlipSided(flipSided: Bool): Void {

		if (this.currentFlipSided != flipSided) {

			if (flipSided) {

				gl.frontFace(gl.CW);

			} else {

				gl.frontFace(gl.CCW);

			}

			this.currentFlipSided = flipSided;

		}

	}

	public function setCullFace(cullFace: CullFace): Void {

		if (cullFace != CullFace.CullFaceNone) {

			this.enable(gl.CULL_FACE);

			if (cullFace != this.currentCullFace) {

				if (cullFace == CullFace.CullFaceBack) {

					gl.cullFace(gl.BACK);

				} else if (cullFace == CullFace.CullFaceFront) {

					gl.cullFace(gl.FRONT);

				} else {

					gl.cullFace(gl.FRONT_AND_BACK);

				}

			}

		} else {

			this.disable(gl.CULL_FACE);

		}

		this.currentCullFace = cullFace;

	}

	public function setLineWidth(width: Float): Void {

		if (width != this.currentLineWidth) {

			if (this.lineWidthAvailable) gl.lineWidth(width);

			this.currentLineWidth = width;

		}

	}

	public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {

		if (polygonOffset) {

			this.enable(gl.POLYGON_OFFSET_FILL);

			if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {

				gl.polygonOffset(factor, units);

				this.currentPolygonOffsetFactor = factor;
				this.currentPolygonOffsetUnits = units;

			}

		} else {

			this.disable(gl.POLYGON_OFFSET_FILL);

		}

	}

	public function setScissorTest(scissorTest: Bool): Void {

		if (scissorTest) {

			this.enable(gl.SCISSOR_TEST);

		} else {

			this.disable(gl.SCISSOR_TEST);

		}

	}

	public function activeTexture(webglSlot: Int = gl.TEXTURE0 + maxTextures - 1): Void {

		if (this.currentTextureSlot != webglSlot) {

			gl.activeTexture(webglSlot);
			this.currentTextureSlot = webglSlot;

		}

	}

	public function bindTexture(webglType: Int, webglTexture: WebGLTexture, webglSlot: Int = null): Void {

		if (webglSlot == null) {

			if (this.currentTextureSlot == null) {

				webglSlot = gl.TEXTURE0 + maxTextures - 1;

			} else {

				webglSlot = this.currentTextureSlot;

			}

		}

		var boundTexture = this.currentBoundTextures.get(webglSlot);

		if (boundTexture == null) {

			boundTexture = { type: null, texture: null };
			this.currentBoundTextures.set(webglSlot, boundTexture);

		}

		if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {

			if (this.currentTextureSlot != webglSlot) {

				gl.activeTexture(webglSlot);
				this.currentTextureSlot = webglSlot;

			}

			gl.bindTexture(webglType, webglTexture != null ? webglTexture : this.emptyTextures.get(webglType));

			boundTexture.type = webglType;
			boundTexture.texture = webglTexture;

		}

	}

	public function unbindTexture(): Void {

		var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);

		if (boundTexture != null && boundTexture.type != null) {

			gl.bindTexture(boundTexture.type, null);

			boundTexture.type = null;
			boundTexture.texture = null;

		}

	}

	public function compressedTexImage2D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, border: Int, data: Bytes): Void {

		try {

			gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexImage3D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, depth: Int, border: Int, data: Bytes): Void {

		try {

			gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texSubImage2D(target: Int, level: Int, xoffset: Int, yoffset: Int, width: Int, height: Int, format: Int, type: Int, pixels: Dynamic, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texSubImage3D(target: Int, level: Int, xoffset: Int, yoffset: Int, zoffset: Int, width: Int, height: Int, depth: Int, format: Int, type: Int, pixels: Dynamic, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexSubImage2D(target: Int, level: Int, xoffset: Int, yoffset: Int, width: Int, height: Int, format: Int, data: Bytes, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexSubImage3D(target: Int, level: Int, xoffset: Int, yoffset: Int, zoffset: Int, width: Int, height: Int, depth: Int, format: Int, data: Bytes, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texStorage2D(target: Int, levels: Int, internalformat: Int, width: Int, height: Int): Void {

		try {

			gl.texStorage2D(target, levels, internalformat, width, height);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texStorage3D(target: Int, levels: Int, internalformat: Int, width: Int, height: Int, depth: Int): Void {

		try {

			gl.texStorage3D(target, levels, internalformat, width, height, depth);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texImage2D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, border: Int, format: Int = null, type: Int = null, pixels: Dynamic = null, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texImage3D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, depth: Int, border: Int, format: Int = null, type: Int = null, pixels: Dynamic = null, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function scissor(scissor: Vector4): Void {

		if (this.currentScissor.equals(scissor) == false) {

			gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
			this.currentScissor.copy(scissor);

		}

	}

	public function viewport(viewport: Vector4): Void {

		if (this.currentViewport.equals(viewport) == false) {

			gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
			this.currentViewport.copy(viewport);

		}

	}

	public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {

		var mapping = this.uboProgramMap.get(program);

		if (mapping == null) {

			mapping = new WeakMap();

			this.uboProgramMap.set(program, mapping);

		}

		var blockIndex = mapping.get(uniformsGroup);

		if (blockIndex == null) {

			blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);

			mapping.set(uniformsGroup, blockIndex);

		}

	}

	public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {

		var mapping = this.uboProgramMap.get(program);
		var blockIndex = mapping.get(uniformsGroup);

		if (this.uboBindings.get(program) != blockIndex) {

			// bind shader specific block index to global block point
			gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);

			this.uboBindings.set(program, blockIndex);

		}

	}

	public function reset(): Void {

		// reset state

		gl.disable(gl.BLEND);
		gl.disable(gl.CULL_FACE);
		gl.disable(gl.DEPTH_TEST);
		gl.disable(gl.POLYGON_OFFSET_FILL);
		gl.disable(gl.SCISSOR_TEST);
		gl.disable(gl.STENCIL_TEST);
		gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		gl.blendEquation(gl.FUNC_ADD);
		gl.blendFunc(gl.ONE, gl.ZERO);
		gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
		gl.blendColor(0, 0, 0, 0);

		gl.colorMask(true, true, true, true);
		gl.clearColor(0, 0, 0, 0);

		gl.depthMask(true);
		gl.depthFunc(gl.LESS);
		gl.clearDepth(1);

		gl.stencilMask(0xffffffff);
		gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
		gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
		gl.clearStencil(0);

		gl.cullFace(gl.BACK);
		gl.frontFace(gl.CCW);

		gl.polygonOffset(0, 0);

		gl.activeTexture(gl.TEXTURE0);

		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
		gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
		gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);

		gl.useProgram(null);

		gl.lineWidth(1);

		gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
		gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

		// reset internals

		this.enabledCapabilities = new Map();

		this.currentTextureSlot = null;
		this.currentBoundTextures = new Map();

		this.currentBoundFramebuffers = new Map();
		this.currentDrawbuffers = new WeakMap();
		this.defaultDrawbuffers = [];

		this.currentProgram = null;

		this.currentBlendingEnabled = false;
		this.currentBlending = null;
		this.currentBlendEquation = null;
		this.currentBlendSrc = null;
		this.currentBlendDst = null;
		this.currentBlendEquationAlpha = null;
		this.currentBlendSrcAlpha = null;
		this.currentBlendDstAlpha = null;
		this.currentBlendColor = new Color(0, 0, 0);
		this.currentBlendAlpha = 0;
		this.currentPremultipledAlpha = false;

		this.currentFlipSided = null;
		this.currentCullFace = null;

		this.currentLineWidth = null;

		this.currentPolygonOffsetFactor = null;
		this.currentPolygonOffsetUnits = null;

		this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
		this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);

		this.colorBuffer.reset();
		this.depthBuffer.reset();
		this.stencilBuffer.reset();

	}

}

class ColorBuffer {

	public var locked: Bool;

	public var color: Vector4;
	public var currentColorMask: Bool;
	public var currentColorClear: Vector4;

	public function new() {

		this.locked = false;

		this.color = new Vector4();
		this.currentColorMask = null;
		this.currentColorClear = new Vector4(0, 0, 0, 0);

	}

	public function setMask(colorMask: Bool): Void {

		if (this.currentColorMask != colorMask && !this.locked) {

			gl.colorMask(colorMask, colorMask, colorMask, colorMask);
			this.currentColorMask = colorMask;

		}

	}

	public function setLocked(lock: Bool): Void {

		this.locked = lock;

	}

	public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {

		if (premultipliedAlpha) {

			r *= a;
			g *= a;
			b *= a;

		}

		this.color.set(r, g, b, a);

		if (this.currentColorClear.equals(this.color) == false) {

			gl.clearColor(r, g, b, a);
			this.currentColorClear.copy(this.color);

		}

	}

	public function reset(): Void {

		this.locked = false;

		this.currentColorMask = null;
		this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state

	}

}

class DepthBuffer {

	public var locked: Bool;

	public var currentDepthMask: Bool;
	public var currentDepthFunc: DepthFunc;
	public var currentDepthClear: Float;

	public function new() {

		this.locked = false;

		this.currentDepthMask = null;
		this.currentDepthFunc = null;
		this.currentDepthClear = null;

	}

	public function setTest(depthTest: Bool): Void {

		if (depthTest) {

			gl.
import haxe.io.Bytes;
import three.constants.Blending;
import three.constants.CullFace;
import three.constants.DepthFunc;
import three.constants.Equation;
import three.constants.Factor;
import three.math.Color;
import three.math.Vector4;

class WebGLState {

	public var gl: WebGLRenderingContext;

	public var colorBuffer: ColorBuffer;
	public var depthBuffer: DepthBuffer;
	public var stencilBuffer: StencilBuffer;

	public var uboBindings: WeakMap<WebGLProgram, Int>;
	public var uboProgramMap: WeakMap<WebGLProgram, WeakMap<Dynamic, Int>>;

	public var enabledCapabilities: Map<Int, Bool>;

	public var currentBoundFramebuffers: Map<Int, WebGLFramebuffer>;
	public var currentDrawbuffers: WeakMap<WebGLFramebuffer, Array<Int>>;
	public var defaultDrawbuffers: Array<Int>;

	public var currentProgram: WebGLProgram;

	public var currentBlendingEnabled: Bool;
	public var currentBlending: Blending;
	public var currentBlendEquation: Equation;
	public var currentBlendSrc: Factor;
	public var currentBlendDst: Factor;
	public var currentBlendEquationAlpha: Equation;
	public var currentBlendSrcAlpha: Factor;
	public var currentBlendDstAlpha: Factor;
	public var currentBlendColor: Color;
	public var currentBlendAlpha: Float;
	public var currentPremultipledAlpha: Bool;

	public var currentFlipSided: Bool;
	public var currentCullFace: CullFace;

	public var currentLineWidth: Float;

	public var currentPolygonOffsetFactor: Float;
	public var currentPolygonOffsetUnits: Float;

	public var maxTextures: Int;

	public var lineWidthAvailable: Bool;
	public var version: Float;

	public var currentTextureSlot: Int;
	public var currentBoundTextures: Map<Int, { type: Int, texture: WebGLTexture }>;

	public var currentScissor: Vector4;
	public var currentViewport: Vector4;

	public var emptyTextures: Map<Int, WebGLTexture>;

	public function new(gl: WebGLRenderingContext) {

		this.gl = gl;

		this.colorBuffer = new ColorBuffer();
		this.depthBuffer = new DepthBuffer();
		this.stencilBuffer = new StencilBuffer();

		this.uboBindings = new WeakMap();
		this.uboProgramMap = new WeakMap();

		this.enabledCapabilities = new Map();

		this.currentBoundFramebuffers = new Map();
		this.currentDrawbuffers = new WeakMap();
		this.defaultDrawbuffers = [];

		this.currentProgram = null;

		this.currentBlendingEnabled = false;
		this.currentBlending = null;
		this.currentBlendEquation = null;
		this.currentBlendSrc = null;
		this.currentBlendDst = null;
		this.currentBlendEquationAlpha = null;
		this.currentBlendSrcAlpha = null;
		this.currentBlendDstAlpha = null;
		this.currentBlendColor = new Color(0, 0, 0);
		this.currentBlendAlpha = 0;
		this.currentPremultipledAlpha = false;

		this.currentFlipSided = null;
		this.currentCullFace = null;

		this.currentLineWidth = null;

		this.currentPolygonOffsetFactor = null;
		this.currentPolygonOffsetUnits = null;

		this.maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

		this.lineWidthAvailable = false;
		this.version = 0;
		var glVersion = gl.getParameter(gl.VERSION);

		if (glVersion.indexOf("WebGL") != - 1) {

			this.version = Std.parseFloat(glVersion.split(" ")[1]);
			this.lineWidthAvailable = (this.version >= 1.0);

		} else if (glVersion.indexOf("OpenGL ES") != - 1) {

			this.version = Std.parseFloat(glVersion.split(" ")[2]);
			this.lineWidthAvailable = (this.version >= 2.0);

		}

		this.currentTextureSlot = null;
		this.currentBoundTextures = new Map();

		var scissorParam = gl.getParameter(gl.SCISSOR_BOX);
		var viewportParam = gl.getParameter(gl.VIEWPORT);

		this.currentScissor = new Vector4().fromArray(scissorParam);
		this.currentViewport = new Vector4().fromArray(viewportParam);

		this.emptyTextures = new Map();
		this.emptyTextures[gl.TEXTURE_2D] = this.createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
		this.emptyTextures[gl.TEXTURE_CUBE_MAP] = this.createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
		this.emptyTextures[gl.TEXTURE_2D_ARRAY] = this.createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
		this.emptyTextures[gl.TEXTURE_3D] = this.createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

		// init

		this.colorBuffer.setClear(0, 0, 0, 1);
		this.depthBuffer.setClear(1);
		this.stencilBuffer.setClear(0);

		this.enable(gl.DEPTH_TEST);
		this.depthBuffer.setFunc(DepthFunc.LessEqualDepth);

		this.setFlipSided(false);
		this.setCullFace(CullFace.CullFaceBack);
		this.enable(gl.CULL_FACE);

		this.setBlending(Blending.NoBlending);

	}

	public function createTexture(type: Int, target: Int, count: Int, dimensions: Int = 1): WebGLTexture {

		var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
		var texture = gl.createTexture();

		gl.bindTexture(type, texture);
		gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
		gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

		for (var i in 0...count) {

			if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {

				gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

			} else {

				gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

			}

		}

		return texture;

	}

	public function enable(id: Int): Void {

		if (this.enabledCapabilities.exists(id) == false || this.enabledCapabilities.get(id) == false) {

			gl.enable(id);
			this.enabledCapabilities.set(id, true);

		}

	}

	public function disable(id: Int): Void {

		if (this.enabledCapabilities.exists(id) == false || this.enabledCapabilities.get(id) == true) {

			gl.disable(id);
			this.enabledCapabilities.set(id, false);

		}

	}

	public function bindFramebuffer(target: Int, framebuffer: WebGLFramebuffer): Bool {

		if (this.currentBoundFramebuffers.exists(target) == false || this.currentBoundFramebuffers.get(target) != framebuffer) {

			gl.bindFramebuffer(target, framebuffer);

			this.currentBoundFramebuffers.set(target, framebuffer);

			// gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

			if (target == gl.DRAW_FRAMEBUFFER) {

				this.currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);

			}

			if (target == gl.FRAMEBUFFER) {

				this.currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);

			}

			return true;

		}

		return false;

	}

	public function drawBuffers(renderTarget: Dynamic, framebuffer: WebGLFramebuffer): Void {

		var drawBuffers = this.defaultDrawbuffers;

		var needsUpdate = false;

		if (renderTarget != null) {

			drawBuffers = this.currentDrawbuffers.get(framebuffer);

			if (drawBuffers == null) {

				drawBuffers = [];
				this.currentDrawbuffers.set(framebuffer, drawBuffers);

			}

			var textures = renderTarget.textures;

			if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {

				for (var i in 0...textures.length) {

					drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;

				}

				drawBuffers.length = textures.length;

				needsUpdate = true;

			}

		} else {

			if (drawBuffers[0] != gl.BACK) {

				drawBuffers[0] = gl.BACK;

				needsUpdate = true;

			}

		}

		if (needsUpdate) {

			gl.drawBuffers(drawBuffers);

		}

	}

	public function useProgram(program: WebGLProgram): Bool {

		if (this.currentProgram != program) {

			gl.useProgram(program);

			this.currentProgram = program;

			return true;

		}

		return false;

	}

	public var equationToGL: Map<Equation, Int> = new Map([
		[Equation.AddEquation, gl.FUNC_ADD],
		[Equation.SubtractEquation, gl.FUNC_SUBTRACT],
		[Equation.ReverseSubtractEquation, gl.FUNC_REVERSE_SUBTRACT]
	]);

	equationToGL.set(Equation.MinEquation, gl.MIN);
	equationToGL.set(Equation.MaxEquation, gl.MAX);

	public var factorToGL: Map<Factor, Int> = new Map([
		[Factor.ZeroFactor, gl.ZERO],
		[Factor.OneFactor, gl.ONE],
		[Factor.SrcColorFactor, gl.SRC_COLOR],
		[Factor.SrcAlphaFactor, gl.SRC_ALPHA],
		[Factor.SrcAlphaSaturateFactor, gl.SRC_ALPHA_SATURATE],
		[Factor.DstColorFactor, gl.DST_COLOR],
		[Factor.DstAlphaFactor, gl.DST_ALPHA],
		[Factor.OneMinusSrcColorFactor, gl.ONE_MINUS_SRC_COLOR],
		[Factor.OneMinusSrcAlphaFactor, gl.ONE_MINUS_SRC_ALPHA],
		[Factor.OneMinusDstColorFactor, gl.ONE_MINUS_DST_COLOR],
		[Factor.OneMinusDstAlphaFactor, gl.ONE_MINUS_DST_ALPHA],
		[Factor.ConstantColorFactor, gl.CONSTANT_COLOR],
		[Factor.OneMinusConstantColorFactor, gl.ONE_MINUS_CONSTANT_COLOR],
		[Factor.ConstantAlphaFactor, gl.CONSTANT_ALPHA],
		[Factor.OneMinusConstantAlphaFactor, gl.ONE_MINUS_CONSTANT_ALPHA]
	]);

	public function setBlending(blending: Blending, blendEquation: Equation = Equation.AddEquation, blendSrc: Factor = Factor.SrcAlphaFactor, blendDst: Factor = Factor.OneMinusSrcAlphaFactor, blendEquationAlpha: Equation = Equation.AddEquation, blendSrcAlpha: Factor = Factor.SrcAlphaFactor, blendDstAlpha: Factor = Factor.OneMinusSrcAlphaFactor, blendColor: Color = null, blendAlpha: Float = 1, premultipliedAlpha: Bool = false): Void {

		if (blending == Blending.NoBlending) {

			if (this.currentBlendingEnabled) {

				this.disable(gl.BLEND);
				this.currentBlendingEnabled = false;

			}

			return;

		}

		if (this.currentBlendingEnabled == false) {

			this.enable(gl.BLEND);
			this.currentBlendingEnabled = true;

		}

		if (blending != Blending.CustomBlending) {

			if (blending != this.currentBlending || premultipliedAlpha != this.currentPremultipledAlpha) {

				if (this.currentBlendEquation != Equation.AddEquation || this.currentBlendEquationAlpha != Equation.AddEquation) {

					gl.blendEquation(gl.FUNC_ADD);

					this.currentBlendEquation = Equation.AddEquation;
					this.currentBlendEquationAlpha = Equation.AddEquation;

				}

				if (premultipliedAlpha) {

					switch (blending) {

						case Blending.NormalBlending:
							gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
							break;

						case Blending.AdditiveBlending:
							gl.blendFunc(gl.ONE, gl.ONE);
							break;

						case Blending.SubtractiveBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
							break;

						case Blending.MultiplyBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
							break;

						default:
							console.error("THREE.WebGLState: Invalid blending: ", blending);
							break;

					}

				} else {

					switch (blending) {

						case Blending.NormalBlending:
							gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
							break;

						case Blending.AdditiveBlending:
							gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
							break;

						case Blending.SubtractiveBlending:
							gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
							break;

						case Blending.MultiplyBlending:
							gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
							break;

						default:
							console.error("THREE.WebGLState: Invalid blending: ", blending);
							break;

					}

				}

				this.currentBlendSrc = null;
				this.currentBlendDst = null;
				this.currentBlendSrcAlpha = null;
				this.currentBlendDstAlpha = null;
				this.currentBlendColor.set(0, 0, 0);
				this.currentBlendAlpha = 0;

				this.currentBlending = blending;
				this.currentPremultipledAlpha = premultipliedAlpha;

			}

			return;

		}

		// custom blending

		blendEquationAlpha = blendEquationAlpha != null ? blendEquationAlpha : blendEquation;
		blendSrcAlpha = blendSrcAlpha != null ? blendSrcAlpha : blendSrc;
		blendDstAlpha = blendDstAlpha != null ? blendDstAlpha : blendDst;

		if (blendEquation != this.currentBlendEquation || blendEquationAlpha != this.currentBlendEquationAlpha) {

			gl.blendEquationSeparate(this.equationToGL.get(blendEquation), this.equationToGL.get(blendEquationAlpha));

			this.currentBlendEquation = blendEquation;
			this.currentBlendEquationAlpha = blendEquationAlpha;

		}

		if (blendSrc != this.currentBlendSrc || blendDst != this.currentBlendDst || blendSrcAlpha != this.currentBlendSrcAlpha || blendDstAlpha != this.currentBlendDstAlpha) {

			gl.blendFuncSeparate(this.factorToGL.get(blendSrc), this.factorToGL.get(blendDst), this.factorToGL.get(blendSrcAlpha), this.factorToGL.get(blendDstAlpha));

			this.currentBlendSrc = blendSrc;
			this.currentBlendDst = blendDst;
			this.currentBlendSrcAlpha = blendSrcAlpha;
			this.currentBlendDstAlpha = blendDstAlpha;

		}

		if (blendColor != null && blendColor.equals(this.currentBlendColor) == false || blendAlpha != this.currentBlendAlpha) {

			gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);

			this.currentBlendColor.copy(blendColor);
			this.currentBlendAlpha = blendAlpha;

		}

		this.currentBlending = blending;
		this.currentPremultipledAlpha = false;

	}

	public function setMaterial(material: Dynamic, frontFaceCW: Bool): Void {

		if (material.side == CullFace.DoubleSide) {

			this.disable(gl.CULL_FACE);

		} else {

			this.enable(gl.CULL_FACE);

		}

		var flipSided = (material.side == CullFace.BackSide);
		if (frontFaceCW) flipSided = !flipSided;

		this.setFlipSided(flipSided);

		if (material.blending == Blending.NormalBlending && material.transparent == false) {

			this.setBlending(Blending.NoBlending);

		} else {

			this.setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);

		}

		this.depthBuffer.setFunc(material.depthFunc);
		this.depthBuffer.setTest(material.depthTest);
		this.depthBuffer.setMask(material.depthWrite);
		this.colorBuffer.setMask(material.colorWrite);

		var stencilWrite = material.stencilWrite;
		this.stencilBuffer.setTest(stencilWrite);
		if (stencilWrite) {

			this.stencilBuffer.setMask(material.stencilWriteMask);
			this.stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
			this.stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);

		}

		this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);

		if (material.alphaToCoverage) {

			this.enable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		} else {

			this.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		}

	}

	public function setFlipSided(flipSided: Bool): Void {

		if (this.currentFlipSided != flipSided) {

			if (flipSided) {

				gl.frontFace(gl.CW);

			} else {

				gl.frontFace(gl.CCW);

			}

			this.currentFlipSided = flipSided;

		}

	}

	public function setCullFace(cullFace: CullFace): Void {

		if (cullFace != CullFace.CullFaceNone) {

			this.enable(gl.CULL_FACE);

			if (cullFace != this.currentCullFace) {

				if (cullFace == CullFace.CullFaceBack) {

					gl.cullFace(gl.BACK);

				} else if (cullFace == CullFace.CullFaceFront) {

					gl.cullFace(gl.FRONT);

				} else {

					gl.cullFace(gl.FRONT_AND_BACK);

				}

			}

		} else {

			this.disable(gl.CULL_FACE);

		}

		this.currentCullFace = cullFace;

	}

	public function setLineWidth(width: Float): Void {

		if (width != this.currentLineWidth) {

			if (this.lineWidthAvailable) gl.lineWidth(width);

			this.currentLineWidth = width;

		}

	}

	public function setPolygonOffset(polygonOffset: Bool, factor: Float, units: Float): Void {

		if (polygonOffset) {

			this.enable(gl.POLYGON_OFFSET_FILL);

			if (this.currentPolygonOffsetFactor != factor || this.currentPolygonOffsetUnits != units) {

				gl.polygonOffset(factor, units);

				this.currentPolygonOffsetFactor = factor;
				this.currentPolygonOffsetUnits = units;

			}

		} else {

			this.disable(gl.POLYGON_OFFSET_FILL);

		}

	}

	public function setScissorTest(scissorTest: Bool): Void {

		if (scissorTest) {

			this.enable(gl.SCISSOR_TEST);

		} else {

			this.disable(gl.SCISSOR_TEST);

		}

	}

	public function activeTexture(webglSlot: Int = gl.TEXTURE0 + maxTextures - 1): Void {

		if (this.currentTextureSlot != webglSlot) {

			gl.activeTexture(webglSlot);
			this.currentTextureSlot = webglSlot;

		}

	}

	public function bindTexture(webglType: Int, webglTexture: WebGLTexture, webglSlot: Int = null): Void {

		if (webglSlot == null) {

			if (this.currentTextureSlot == null) {

				webglSlot = gl.TEXTURE0 + maxTextures - 1;

			} else {

				webglSlot = this.currentTextureSlot;

			}

		}

		var boundTexture = this.currentBoundTextures.get(webglSlot);

		if (boundTexture == null) {

			boundTexture = { type: null, texture: null };
			this.currentBoundTextures.set(webglSlot, boundTexture);

		}

		if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {

			if (this.currentTextureSlot != webglSlot) {

				gl.activeTexture(webglSlot);
				this.currentTextureSlot = webglSlot;

			}

			gl.bindTexture(webglType, webglTexture != null ? webglTexture : this.emptyTextures.get(webglType));

			boundTexture.type = webglType;
			boundTexture.texture = webglTexture;

		}

	}

	public function unbindTexture(): Void {

		var boundTexture = this.currentBoundTextures.get(this.currentTextureSlot);

		if (boundTexture != null && boundTexture.type != null) {

			gl.bindTexture(boundTexture.type, null);

			boundTexture.type = null;
			boundTexture.texture = null;

		}

	}

	public function compressedTexImage2D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, border: Int, data: Bytes): Void {

		try {

			gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexImage3D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, depth: Int, border: Int, data: Bytes): Void {

		try {

			gl.compressedTexImage3D(target, level, internalformat, width, height, depth, border, data);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texSubImage2D(target: Int, level: Int, xoffset: Int, yoffset: Int, width: Int, height: Int, format: Int, type: Int, pixels: Dynamic, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texSubImage3D(target: Int, level: Int, xoffset: Int, yoffset: Int, zoffset: Int, width: Int, height: Int, depth: Int, format: Int, type: Int, pixels: Dynamic, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexSubImage2D(target: Int, level: Int, xoffset: Int, yoffset: Int, width: Int, height: Int, format: Int, data: Bytes, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function compressedTexSubImage3D(target: Int, level: Int, xoffset: Int, yoffset: Int, zoffset: Int, width: Int, height: Int, depth: Int, format: Int, data: Bytes, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, data, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texStorage2D(target: Int, levels: Int, internalformat: Int, width: Int, height: Int): Void {

		try {

			gl.texStorage2D(target, levels, internalformat, width, height);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texStorage3D(target: Int, levels: Int, internalformat: Int, width: Int, height: Int, depth: Int): Void {

		try {

			gl.texStorage3D(target, levels, internalformat, width, height, depth);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texImage2D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, border: Int, format: Int = null, type: Int = null, pixels: Dynamic = null, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function texImage3D(target: Int, level: Int, internalformat: Int, width: Int, height: Int, depth: Int, border: Int, format: Int = null, type: Int = null, pixels: Dynamic = null, offset: Int = 0, length: Int = -1): Void {

		try {

			gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels, offset, length);

		} catch (error: Dynamic) {

			console.error("THREE.WebGLState:", error);

		}

	}

	public function scissor(scissor: Vector4): Void {

		if (this.currentScissor.equals(scissor) == false) {

			gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
			this.currentScissor.copy(scissor);

		}

	}

	public function viewport(viewport: Vector4): Void {

		if (this.currentViewport.equals(viewport) == false) {

			gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
			this.currentViewport.copy(viewport);

		}

	}

	public function updateUBOMapping(uniformsGroup: Dynamic, program: WebGLProgram): Void {

		var mapping = this.uboProgramMap.get(program);

		if (mapping == null) {

			mapping = new WeakMap();

			this.uboProgramMap.set(program, mapping);

		}

		var blockIndex = mapping.get(uniformsGroup);

		if (blockIndex == null) {

			blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);

			mapping.set(uniformsGroup, blockIndex);

		}

	}

	public function uniformBlockBinding(uniformsGroup: Dynamic, program: WebGLProgram): Void {

		var mapping = this.uboProgramMap.get(program);
		var blockIndex = mapping.get(uniformsGroup);

		if (this.uboBindings.get(program) != blockIndex) {

			// bind shader specific block index to global block point
			gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);

			this.uboBindings.set(program, blockIndex);

		}

	}

	public function reset(): Void {

		// reset state

		gl.disable(gl.BLEND);
		gl.disable(gl.CULL_FACE);
		gl.disable(gl.DEPTH_TEST);
		gl.disable(gl.POLYGON_OFFSET_FILL);
		gl.disable(gl.SCISSOR_TEST);
		gl.disable(gl.STENCIL_TEST);
		gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		gl.blendEquation(gl.FUNC_ADD);
		gl.blendFunc(gl.ONE, gl.ZERO);
		gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
		gl.blendColor(0, 0, 0, 0);

		gl.colorMask(true, true, true, true);
		gl.clearColor(0, 0, 0, 0);

		gl.depthMask(true);
		gl.depthFunc(gl.LESS);
		gl.clearDepth(1);

		gl.stencilMask(0xffffffff);
		gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
		gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
		gl.clearStencil(0);

		gl.cullFace(gl.BACK);
		gl.frontFace(gl.CCW);

		gl.polygonOffset(0, 0);

		gl.activeTexture(gl.TEXTURE0);

		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
		gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
		gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);

		gl.useProgram(null);

		gl.lineWidth(1);

		gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
		gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

		// reset internals

		this.enabledCapabilities = new Map();

		this.currentTextureSlot = null;
		this.currentBoundTextures = new Map();

		this.currentBoundFramebuffers = new Map();
		this.currentDrawbuffers = new WeakMap();
		this.defaultDrawbuffers = [];

		this.currentProgram = null;

		this.currentBlendingEnabled = false;
		this.currentBlending = null;
		this.currentBlendEquation = null;
		this.currentBlendSrc = null;
		this.currentBlendDst = null;
		this.currentBlendEquationAlpha = null;
		this.currentBlendSrcAlpha = null;
		this.currentBlendDstAlpha = null;
		this.currentBlendColor = new Color(0, 0, 0);
		this.currentBlendAlpha = 0;
		this.currentPremultipledAlpha = false;

		this.currentFlipSided = null;
		this.currentCullFace = null;

		this.currentLineWidth = null;

		this.currentPolygonOffsetFactor = null;
		this.currentPolygonOffsetUnits = null;

		this.currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
		this.currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);

		this.colorBuffer.reset();
		this.depthBuffer.reset();
		this.stencilBuffer.reset();

	}

}

class ColorBuffer {

	public var locked: Bool;

	public var color: Vector4;
	public var currentColorMask: Bool;
	public var currentColorClear: Vector4;

	public function new() {

		this.locked = false;

		this.color = new Vector4();
		this.currentColorMask = null;
		this.currentColorClear = new Vector4(0, 0, 0, 0);

	}

	public function setMask(colorMask: Bool): Void {

		if (this.currentColorMask != colorMask && !this.locked) {

			gl.colorMask(colorMask, colorMask, colorMask, colorMask);
			this.currentColorMask = colorMask;

		}

	}

	public function setLocked(lock: Bool): Void {

		this.locked = lock;

	}

	public function setClear(r: Float, g: Float, b: Float, a: Float, premultipliedAlpha: Bool = false): Void {

		if (premultipliedAlpha) {

			r *= a;
			g *= a;
			b *= a;

		}

		this.color.set(r, g, b, a);

		if (this.currentColorClear.equals(this.color) == false) {

			gl.clearColor(r, g, b, a);
			this.currentColorClear.copy(this.color);

		}

	}

	public function reset(): Void {

		this.locked = false;

		this.currentColorMask = null;
		this.currentColorClear.set(-1, 0, 0, 0); // set to invalid state

	}

}

class DepthBuffer {

	public var locked: Bool;

	public var currentDepthMask: Bool;
	public var currentDepthFunc: DepthFunc;
	public var currentDepthClear: Float;

	public function new() {

		this.locked = false;

		this.currentDepthMask = null;
		this.currentDepthFunc = null;
		this.currentDepthClear = null;

	}

	public function setTest(depthTest: Bool): Void {

		if (depthTest) {

			gl.