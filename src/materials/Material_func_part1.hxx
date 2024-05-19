import three.math.Color;
import three.core.EventDispatcher;
import three.constants.*;
import three.math.MathUtils;

static var _materialId = 0;

class Material extends EventDispatcher {

	public function new() {

		super();

		this.isMaterial = true;

		this.id = _materialId ++;

		this.uuid = MathUtils.generateUUID();

		this.name = '';
		this.type = 'Material';

		this.blending = NormalBlending;
		this.side = FrontSide;
		this.vertexColors = false;

		this.opacity = 1;
		this.transparent = false;
		this.alphaHash = false;

		this.blendSrc = SrcAlphaFactor;
		this.blendDst = OneMinusSrcAlphaFactor;
		this.blendEquation = AddEquation;
		this.blendSrcAlpha = null;
		this.blendDstAlpha = null;
		this.blendEquationAlpha = null;
		this.blendColor = new Color( 0, 0, 0 );
		this.blendAlpha = 0;

		this.depthFunc = LessEqualDepth;
		this.depthTest = true;
		this.depthWrite = true;

		this.stencilWriteMask = 0xff;
		this.stencilFunc = AlwaysStencilFunc;
		this.stencilRef = 0;
		this.stencilFuncMask = 0xff;
		this.stencilFail = KeepStencilOp;
		this.stencilZFail = KeepStencilOp;
		this.stencilZPass = KeepStencilOp;
		this.stencilWrite = false;

		this.clippingPlanes = null;
		this.clipIntersection = false;
		this.clipShadows = false;

		this.shadowSide = null;

		this.colorWrite = true;

		this.precision = null; // override the renderer's default precision for this material

		this.polygonOffset = false;
		this.polygonOffsetFactor = 0;
		this.polygonOffsetUnits = 0;

		this.dithering = false;

		this.alphaToCoverage = false;
		this.premultipliedAlpha = false;
		this.forceSinglePass = false;

		this.visible = true;

		this.toneMapped = true;

		this.userData = {};

		this.version = 0;

		this._alphaTest = 0;

	}

	public function get alphaTest():Float {

		return this._alphaTest;

	}

	public function set alphaTest(value:Float):Void {

		if (this._alphaTest > 0 !== value > 0) {

			this.version ++;

		}

		this._alphaTest = value;

	}

	public function onBuild(/* shaderobject, renderer */):Void {}

	public function onBeforeRender(/* renderer, scene, camera, geometry, object, group */):Void {}

	public function onBeforeCompile(/* shaderobject, renderer */):Void {}

	public function customProgramCacheKey():String {

		return this.onBeforeCompile.toString();

	}

	public function setValues(values:Dynamic):Void {

		if (values === undefined) return;

		for (key in values) {

			var newValue = values[key];

			if (newValue === undefined) {

				trace(`THREE.Material: parameter '${key}' has value of undefined.`);
				continue;

			}

			var currentValue = this[key];

			if (currentValue === undefined) {

				trace(`THREE.Material: '${key}' is not a property of THREE.${this.type}.`);
				continue;

			}

			if (currentValue && currentValue.isColor) {

				currentValue.set(newValue);

			} else if ((currentValue && currentValue.isVector3) && (newValue && newValue.isVector3)) {

				currentValue.copy(newValue);

			} else {

				this[key] = newValue;

			}

		}

	}

	public function toJSON(meta:Dynamic):Dynamic {

		var isRootObject = (meta === undefined || typeof meta === 'string');

		if (isRootObject) {

			meta = {
				textures: {},
				images: {}
			};

		}

		var data = {
			metadata: {
				version: 4.6,
				type: 'Material',
				generator: 'Material.toJSON'
			}
		};

		// standard Material serialization
		data.uuid = this.uuid;
		data.type = this.type;

		if (this.name !== '') data.name = this.name;

		if (this.color && this.color.isColor) data.color = this.color.getHex();

		// ... 省略其他属性的序列化代码 ...

		// TODO: Copied from Object3D.toJSON

		function extractFromCache(cache:Dynamic):Array<Dynamic> {

			var values = [];

			for (key in cache) {

				var data = cache[key];
				delete data.metadata;
				values.push(data);

			}

			return values;

		}

		if (isRootObject) {

			var textures = extractFromCache(meta.textures);
			var images = extractFromCache(meta.images);

			if (textures.length > 0) data.textures = textures;
			if (images.length > 0) data.images = images;

		}

		return data;

	}

	public function clone():Material {

		return cast(new this.constructor().copy(this), Material);

	}

	public function copy(source:Material):Material {

		this.name = source.name;

		this.blending = source.blending;
		this.side = source.side;
		this.vertexColors = source.vertexColors;

		this.opacity = source.opacity;
		this.transparent = source.transparent;

		this.blendSrc = source.blendSrc;
		this.blendDst = source.blendDst;
		this.blendEquation = source.blendEquation;
		this.blendSrcAlpha = source.blendSrcAlpha;
		this.blendDstAlpha = source.blendDstAlpha;
		this.blendEquationAlpha = source.blendEquationAlpha;
		this.blendColor.copy(source.blendColor);
		this.blendAlpha = source.blendAlpha;

		this.depthFunc = source.depthFunc;
		this.depthTest = source.depthTest;
		this.depthWrite = source.depthWrite;

		this.stencilWriteMask = source.stencilWriteMask;
		this.stencilFunc = source.stencilFunc;
		this.stencilRef = source.stencilRef;
		this.stencilFuncMask = source.stencilFuncMask;
		this.stencilFail = source.stencilFail;
		this.stencilZFail = source.stencilZFail;
		this.stencilZPass = source.stencilZPass;
		this.stencilWrite = source.stencilWrite;

		// ... 省略其他属性的复制代码 ...

		return this;

	}

	public function dispose():Void {

		this.dispatchEvent({type: 'dispose'});

	}

	public function set needsUpdate(value:Bool):Void {

		if (value) this.version ++;

	}

}