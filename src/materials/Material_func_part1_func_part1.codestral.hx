import three.math.Color;
import three.core.EventDispatcher;
import three.constants.FrontSide;
import three.constants.NormalBlending;
import three.constants.LessEqualDepth;
import three.constants.AddEquation;
import three.constants.OneMinusSrcAlphaFactor;
import three.constants.SrcAlphaFactor;
import three.constants.AlwaysStencilFunc;
import three.constants.KeepStencilOp;
import three.math.MathUtils;

class Material extends EventDispatcher {
    public var isMaterial:Bool = true;
    private static var _materialId:Int = 0;
    public var id:Int;
    public var uuid:String;
    public var name:String = "";
    public var type:String = "Material";
    public var blending:Int = NormalBlending;
    public var side:Int = FrontSide;
    public var vertexColors:Bool = false;
    public var opacity:Float = 1;
    public var transparent:Bool = false;
    public var alphaHash:Bool = false;
    public var blendSrc:Int = SrcAlphaFactor;
    public var blendDst:Int = OneMinusSrcAlphaFactor;
    public var blendEquation:Int = AddEquation;
    public var blendSrcAlpha:Int;
    public var blendDstAlpha:Int;
    public var blendEquationAlpha:Int;
    public var blendColor:Color = new Color(0, 0, 0);
    public var blendAlpha:Float = 0;
    public var depthFunc:Int = LessEqualDepth;
    public var depthTest:Bool = true;
    public var depthWrite:Bool = true;
    public var stencilWriteMask:Int = 0xff;
    public var stencilFunc:Int = AlwaysStencilFunc;
    public var stencilRef:Int = 0;
    public var stencilFuncMask:Int = 0xff;
    public var stencilFail:Int = KeepStencilOp;
    public var stencilZFail:Int = KeepStencilOp;
    public var stencilZPass:Int = KeepStencilOp;
    public var stencilWrite:Bool = false;
    public var clippingPlanes:Dynamic;
    public var clipIntersection:Bool = false;
    public var clipShadows:Bool = false;
    public var shadowSide:Dynamic;
    public var colorWrite:Bool = true;
    public var precision:Dynamic;
    public var polygonOffset:Bool = false;
    public var polygonOffsetFactor:Float = 0;
    public var polygonOffsetUnits:Float = 0;
    public var dithering:Bool = false;
    public var alphaToCoverage:Bool = false;
    public var premultipliedAlpha:Bool = false;
    public var forceSinglePass:Bool = false;
    public var visible:Bool = true;
    public var toneMapped:Bool = true;
    public var userData:Dynamic = {};
    public var version:Int = 0;
    private var _alphaTest:Float = 0;

    public function new() {
        super();
        id = _materialId++;
        uuid = MathUtils.generateUUID();
    }

    public function get_alphaTest():Float {
        return _alphaTest;
    }

    public function set_alphaTest(value:Float):Void {
        if((_alphaTest > 0) != (value > 0)) {
            version++;
        }
        _alphaTest = value;
    }

    public function onBuild(/* shaderobject, renderer */):Void {}
    public function onBeforeRender(/* renderer, scene, camera, geometry, object, group */):Void {}
    public function onBeforeCompile(/* shaderobject, renderer */):Void {}

    public function customProgramCacheKey():String {
        return this.onBeforeCompile.toString();
    }

    public function setValues(values:Dynamic):Void {
        if(values === undefined) return;
        for(key in Reflect.fields(values)) {
            var newValue = Reflect.field(values, key);
            if(newValue === undefined) {
                trace("THREE.Material: parameter '${key}' has value of undefined.");
                continue;
            }
            var currentValue = Reflect.field(this, key);
            if(currentValue === undefined) {
                trace("THREE.Material: '${key}' is not a property of THREE.${this.type}.");
                continue;
            }
            if(Std.is(currentValue, Color)) {
                currentValue.set(newValue);
            } else {
                Reflect.setField(this, key, newValue);
            }
        }
    }

    public function toJSON(meta:Dynamic = null):Dynamic {
        var isRootObject = (meta === undefined || Std.is(meta, String));
        if(isRootObject) {
            meta = {
                textures: {},
                images: {}
            };
        }
        // Implementation is not fully provided as it requires more context about Texture, MathUtils, etc.
    }

    public function clone():Material {
        return new Material().copy(this);
    }

    public function copy(source:Material):Material {
        name = source.name;
        blending = source.blending;
        side = source.side;
        vertexColors = source.vertexColors;
        opacity = source.opacity;
        transparent = source.transparent;
        blendSrc = source.blendSrc;
        blendDst = source.blendDst;
        blendEquation = source.blendEquation;
        blendSrcAlpha = source.blendSrcAlpha;
        blendDstAlpha = source.blendDstAlpha;
        blendEquationAlpha = source.blendEquationAlpha;
        blendColor.copy(source.blendColor);
        blendAlpha = source.blendAlpha;
        depthFunc = source.depthFunc;
        depthTest = source.depthTest;
        depthWrite = source.depthWrite;
        stencilWriteMask = source.stencilWriteMask;
        stencilFunc = source.stencilFunc;
        stencilRef = source.stencilRef;
        stencilFuncMask = source.stencilFuncMask;
        stencilFail = source.stencilFail;
        stencilZFail = source.stencilZFail;
        stencilZPass = source.stencilZPass;
        stencilWrite = source.stencilWrite;
        clipIntersection = source.clipIntersection;
        clipShadows = source.clipShadows;
        shadowSide = source.shadowSide;
        colorWrite = source.colorWrite;
        precision = source.precision;
        polygonOffset = source.polygonOffset;
        polygonOffsetFactor = source.polygonOffsetFactor;
        polygonOffsetUnits = source.polygonOffsetUnits;
        dithering = source.dithering;
        alphaTest = source.alphaTest;
        alphaHash = source.alphaHash;
        alphaToCoverage = source.alphaToCoverage;
        premultipliedAlpha = source.premultipliedAlpha;
        forceSinglePass = source.forceSinglePass;
        visible = source.visible;
        toneMapped = source.toneMapped;
        userData = JSON.parse(JSON.stringify(source.userData));
        return this;
    }

    public function dispose():Void {
        this.dispatchEvent({ type: 'dispose' });
    }

    public function set needsUpdate(value:Bool):Void {
        if(value === true) version++;
    }
}