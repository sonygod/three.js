import three.CullFace;
import three.Blending;
import three.BlendEquation;
import three.BlendFactor;
import three.DepthFunc;

class WebGLState {

	public var backend:Backend;
	public var gl:WebGLRenderingContext;

	public var enabled:Map<Int,Bool> = new Map();
	public var currentFlipSided:Null<Bool> = null;
	public var currentCullFace:Null<CullFace> = null;
	public var currentProgram:Null<WebGLProgram> = null;
	public var currentBlendingEnabled:Bool = false;
	public var currentBlending:Null<Blending> = null;
	public var currentBlendSrc:Null<BlendFactor> = null;
	public var currentBlendDst:Null<BlendFactor> = null;
	public var currentBlendSrcAlpha:Null<BlendFactor> = null;
	public var currentBlendDstAlpha:Null<BlendFactor> = null;
	public var currentPremultipledAlpha:Null<Bool> = null;
	public var currentPolygonOffsetFactor:Null<Float> = null;
	public var currentPolygonOffsetUnits:Null<Float> = null;
	public var currentColorMask:Null<Bool> = null;
	public var currentDepthFunc:Null<DepthFunc> = null;
	public var currentDepthMask:Null<Bool> = null;
	public var currentStencilFunc:Null<Int> = null;
	public var currentStencilRef:Null<Int> = null;
	public var currentStencilFuncMask:Null<Int> = null;
	public var currentStencilFail:Null<Int> = null;
	public var currentStencilZFail:Null<Int> = null;
	public var currentStencilZPass:Null<Int> = null;
	public var currentStencilMask:Null<Int> = null;
	public var currentLineWidth:Null<Float> = null;

	public var currentBoundFramebuffers:Map<Int,Null<WebGLFramebuffer>> = new Map();
	public var currentDrawbuffers:WeakMap<WebGLFramebuffer,Array<Int>> = new WeakMap();

	public var maxTextures:Int;
	public var currentTextureSlot:Null<Int> = null;
	public var currentBoundTextures:Map<Int, { type:Null<Int>, texture:Null<WebGLTexture> }> = new Map();

	public function new(backend:Backend) {
		this.backend = backend;
		this.gl = backend.gl;

		this.maxTextures = this.gl.getParameter(this.gl.MAX_TEXTURE_IMAGE_UNITS);

		_init(gl);
	}

	private function _init(gl:WebGLRenderingContext) {
		// Store only WebGL constants here.

		equationToGL = new Map<BlendEquation,Int>();
		equationToGL.set(BlendEquation.Add, gl.FUNC_ADD);
		equationToGL.set(BlendEquation.Subtract, gl.FUNC_SUBTRACT);
		equationToGL.set(BlendEquation.ReverseSubtract, gl.FUNC_REVERSE_SUBTRACT);

		factorToGL = new Map<BlendFactor,Int>();
		factorToGL.set(BlendFactor.Zero, gl.ZERO);
		factorToGL.set(BlendFactor.One, gl.ONE);
		factorToGL.set(BlendFactor.SrcColor, gl.SRC_COLOR);
		factorToGL.set(BlendFactor.SrcAlpha, gl.SRC_ALPHA);
		factorToGL.set(BlendFactor.SrcAlphaSaturate, gl.SRC_ALPHA_SATURATE);
		factorToGL.set(BlendFactor.DstColor, gl.DST_COLOR);
		factorToGL.set(BlendFactor.DstAlpha, gl.DST_ALPHA);
		factorToGL.set(BlendFactor.OneMinusSrcColor, gl.ONE_MINUS_SRC_COLOR);
		factorToGL.set(BlendFactor.OneMinusSrcAlpha, gl.ONE_MINUS_SRC_ALPHA);
		factorToGL.set(BlendFactor.OneMinusDstColor, gl.ONE_MINUS_DST_COLOR);
		factorToGL.set(BlendFactor.OneMinusDstAlpha, gl.ONE_MINUS_DST_ALPHA);
	}

	public function enable(id:Int) {
		if (!enabled.exists(id) || enabled.get(id) != true) {
			gl.enable(id);
			enabled.set(id, true);
		}
	}

	public function disable(id:Int) {
		if (!enabled.exists(id) || enabled.get(id) != false) {
			gl.disable(id);
			enabled.set(id, false);
		}
	}

	public function setFlipSided(flipSided:Bool) {
		if (currentFlipSided != flipSided) {
			if (flipSided) {
				gl.frontFace(gl.CW);
			} else {
				gl.frontFace(gl.CCW);
			}
			currentFlipSided = flipSided;
		}
	}

	public function setCullFace(cullFace:CullFace) {
		if (cullFace != CullFace.None) {
			enable(gl.CULL_FACE);

			if (cullFace != currentCullFace) {
				switch (cullFace) {
					case CullFace.Back:
						gl.cullFace(gl.BACK);
					case CullFace.Front:
						gl.cullFace(gl.FRONT);
					case CullFace.Both:
						gl.cullFace(gl.FRONT_AND_BACK);
				}
			}
		} else {
			disable(gl.CULL_FACE);
		}
		currentCullFace = cullFace;
	}

	public function setLineWidth(width:Float) {
		if (currentLineWidth != width) {
			gl.lineWidth(width);
			currentLineWidth = width;
		}
	}

	public function setBlending(blending:Blending, blendEquation:BlendEquation, blendSrc:BlendFactor, blendDst:BlendFactor, blendEquationAlpha:BlendEquation = null, blendSrcAlpha:BlendFactor = null, blendDstAlpha:BlendFactor = null, premultipliedAlpha:Bool = false) {
		if (blending == Blending.NoBlending) {
			if (currentBlendingEnabled) {
				disable(gl.BLEND);
				currentBlendingEnabled = false;
			}
			return;
		}

		if (!currentBlendingEnabled) {
			enable(gl.BLEND);
			currentBlendingEnabled = true;
		}

		if (blending != Blending.Custom) {
			if (blending != currentBlending || premultipliedAlpha != currentPremultipledAlpha) {
				if (currentBlendEquation != BlendEquation.Add || currentBlendEquationAlpha != BlendEquation.Add) {
					gl.blendEquation(gl.FUNC_ADD);
					currentBlendEquation = BlendEquation.Add;
					currentBlendEquationAlpha = BlendEquation.Add;
				}

				if (premultipliedAlpha) {
					switch (blending) {
						case Blending.Normal:
							gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
						case Blending.Additive:
							gl.blendFunc(gl.ONE, gl.ONE);
						case Blending.Subtractive:
							gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
						case Blending.Multiply:
							gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
						default:
							console.error("THREE.WebGLState: Invalid blending: ", blending);
					}
				} else {
					switch (blending) {
						case Blending.Normal:
							gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
						case Blending.Additive:
							gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
						case Blending.Subtractive:
							gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
						case Blending.Multiply:
							gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
						default:
							console.error("THREE.WebGLState: Invalid blending: ", blending);
					}
				}
				currentBlendSrc = null;
				currentBlendDst = null;
				currentBlendSrcAlpha = null;
				currentBlendDstAlpha = null;
				currentBlending = blending;
				currentPremultipledAlpha = premultipliedAlpha;
			}
			return;
		}

		// custom blending

		blendEquationAlpha = blendEquationAlpha != null ? blendEquationAlpha : blendEquation;
		blendSrcAlpha = blendSrcAlpha != null ? blendSrcAlpha : blendSrc;
		blendDstAlpha = blendDstAlpha != null ? blendDstAlpha : blendDst;

		if (blendEquation != currentBlendEquation || blendEquationAlpha != currentBlendEquationAlpha) {
			gl.blendEquationSeparate(equationToGL.get(blendEquation), equationToGL.get(blendEquationAlpha));
			currentBlendEquation = blendEquation;
			currentBlendEquationAlpha = blendEquationAlpha;
		}

		if (blendSrc != currentBlendSrc || blendDst != currentBlendDst || blendSrcAlpha != currentBlendSrcAlpha || blendDstAlpha != currentBlendDstAlpha) {
			gl.blendFuncSeparate(factorToGL.get(blendSrc), factorToGL.get(blendDst), factorToGL.get(blendSrcAlpha), factorToGL.get(blendDstAlpha));
			currentBlendSrc = blendSrc;
			currentBlendDst = blendDst;
			currentBlendSrcAlpha = blendSrcAlpha;
			currentBlendDstAlpha = blendDstAlpha;
		}

		currentBlending = blending;
		currentPremultipledAlpha = false;
	}

	public function setColorMask(colorMask:Bool) {
		if (currentColorMask != colorMask) {
			gl.colorMask(colorMask, colorMask, colorMask, colorMask);
			currentColorMask = colorMask;
		}
	}

	public function setDepthTest(depthTest:Bool) {
		if (depthTest) {
			enable(gl.DEPTH_TEST);
		} else {
			disable(gl.DEPTH_TEST);
		}
	}

	public function setDepthMask(depthMask:Bool) {
		if (currentDepthMask != depthMask) {
			gl.depthMask(depthMask);
			currentDepthMask = depthMask;
		}
	}

	public function setDepthFunc(depthFunc:DepthFunc) {
		if (currentDepthFunc != depthFunc) {
			switch (depthFunc) {
				case DepthFunc.Never:
					gl.depthFunc(gl.NEVER);
				case DepthFunc.Always:
					gl.depthFunc(gl.ALWAYS);
				case DepthFunc.Less:
					gl.depthFunc(gl.LESS);
				case DepthFunc.LessEqual:
					gl.depthFunc(gl.LEQUAL);
				case DepthFunc.Equal:
					gl.depthFunc(gl.EQUAL);
				case DepthFunc.GreaterEqual:
					gl.depthFunc(gl.GEQUAL);
				case DepthFunc.Greater:
					gl.depthFunc(gl.GREATER);
				case DepthFunc.NotEqual:
					gl.depthFunc(gl.NOTEQUAL);
				default:
					gl.depthFunc(gl.LEQUAL);
			}
			currentDepthFunc = depthFunc;
		}
	}

	public function setStencilTest(stencilTest:Bool) {
		if (stencilTest) {
			enable(gl.STENCIL_TEST);
		} else {
			disable(gl.STENCIL_TEST);
		}
	}

	public function setStencilMask(stencilMask:Int) {
		if (currentStencilMask != stencilMask) {
			gl.stencilMask(stencilMask);
			currentStencilMask = stencilMask;
		}
	}

	public function setStencilFunc(stencilFunc:Int, stencilRef:Int, stencilMask:Int) {
		if (currentStencilFunc != stencilFunc || currentStencilRef != stencilRef || currentStencilFuncMask != stencilMask) {
			gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
			currentStencilFunc = stencilFunc;
			currentStencilRef = stencilRef;
			currentStencilFuncMask = stencilMask;
		}
	}

	public function setStencilOp(stencilFail:Int, stencilZFail:Int, stencilZPass:Int) {
		if (currentStencilFail != stencilFail || currentStencilZFail != stencilZFail || currentStencilZPass != stencilZPass) {
			gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
			currentStencilFail = stencilFail;
			currentStencilZFail = stencilZFail;
			currentStencilZPass = stencilZPass;
		}
	}

	public function setMaterial(material:Material, frontFaceCW:Bool) {
		if (material.side == three.Side.Double) {
			disable(gl.CULL_FACE);
		} else {
			enable(gl.CULL_FACE);
		}

		var flipSided = material.side == three.Side.Back;
		if (frontFaceCW) flipSided = !flipSided;

		setFlipSided(flipSided);

		if (material.blending == Blending.Normal && !material.transparent) {
			setBlending(Blending.NoBlending);
		} else {
			setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.premultipliedAlpha);
		}

		setDepthFunc(material.depthFunc);
		setDepthTest(material.depthTest);
		setDepthMask(material.depthWrite);
		setColorMask(material.colorWrite);

		var stencilWrite = material.stencilWrite;
		setStencilTest(stencilWrite);
		if (stencilWrite) {
			setStencilMask(material.stencilWriteMask);
			setStencilFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
			setStencilOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
		}

		setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);

		if (material.alphaToCoverage) {
			enable(gl.SAMPLE_ALPHA_TO_COVERAGE);
		} else {
			disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
		}
	}

	public function setPolygonOffset(polygonOffset:Bool, factor:Float, units:Float) {
		if (polygonOffset) {
			enable(gl.POLYGON_OFFSET_FILL);

			if (currentPolygonOffsetFactor != factor || currentPolygonOffsetUnits != units) {
				gl.polygonOffset(factor, units);
				currentPolygonOffsetFactor = factor;
				currentPolygonOffsetUnits = units;
			}
		} else {
			disable(gl.POLYGON_OFFSET_FILL);
		}
	}

	public function useProgram(program:WebGLProgram):Bool {
		if (currentProgram != program) {
			gl.useProgram(program);
			currentProgram = program;
			return true;
		}
		return false;
	}

	// framebuffer

	public function bindFramebuffer(target:Int, framebuffer:WebGLFramebuffer):Bool {
		if (currentBoundFramebuffers.exists(target) && currentBoundFramebuffers.get(target) == framebuffer) {
			return false;
		}

		gl.bindFramebuffer(target, framebuffer);
		currentBoundFramebuffers.set(target, framebuffer);

		// gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER
		if (target == gl.DRAW_FRAMEBUFFER) {
			currentBoundFramebuffers.set(gl.FRAMEBUFFER, framebuffer);
		}

		if (target == gl.FRAMEBUFFER) {
			currentBoundFramebuffers.set(gl.DRAW_FRAMEBUFFER, framebuffer);
		}

		return true;
	}

	public function drawBuffers(renderContext:RenderContext, framebuffer:WebGLFramebuffer) {
		var drawBuffers:Array<Int> = [];
		var needsUpdate:Bool = false;

		if (renderContext.textures != null) {
			drawBuffers = currentDrawbuffers.get(framebuffer);

			if (drawBuffers == null) {
				drawBuffers = [];
				currentDrawbuffers.set(framebuffer, drawBuffers);
			}

			var textures = renderContext.textures;

			if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
				for (i in 0...textures.length) {
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

	// texture

	public function activeTexture(webglSlot:Int = null) {
		if (webglSlot == null) webglSlot = gl.TEXTURE0 + maxTextures - 1;

		if (currentTextureSlot != webglSlot) {
			gl.activeTexture(webglSlot);
			currentTextureSlot = webglSlot;
		}
	}

	public function bindTexture(webglType:Int, webglTexture:WebGLTexture, webglSlot:Int = null) {
		if (webglSlot == null) {
			if (currentTextureSlot == null) {
				webglSlot = gl.TEXTURE0 + maxTextures - 1;
			} else {
				webglSlot = currentTextureSlot;
			}
		}

		var boundTexture = currentBoundTextures.get(webglSlot);

		if (boundTexture == null) {
			boundTexture = { type: null, texture: null };
			currentBoundTextures.set(webglSlot, boundTexture);
		}

		if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
			if (currentTextureSlot != webglSlot) {
				gl.activeTexture(webglSlot);
				currentTextureSlot = webglSlot;
			}

			gl.bindTexture(webglType, webglTexture);

			boundTexture.type = webglType;
			boundTexture.texture = webglTexture;
		}
	}

	public function unbindTexture() {
		var boundTexture = currentBoundTextures.get(currentTextureSlot);

		if (boundTexture != null && boundTexture.type != null) {
			gl.bindTexture(boundTexture.type, null);
			boundTexture.type = null;
			boundTexture.texture = null;
		}
	}

	private static var equationToGL:Map<BlendEquation,Int>;
	private static var factorToGL:Map<BlendFactor,Int>;
}