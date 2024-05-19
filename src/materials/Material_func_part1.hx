package three.materials;

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
    public var id:Int;
    public var uuid:String;
    public var name:String;
    public var type:String;
    public var blending:Int;
    public var side:Int;
    public var vertexColors:Bool;
    public var opacity:Float;
    public var transparent:Bool;
    public var alphaHash:Bool;
    public var blendSrc:Int;
    public var blendDst:Int;
    public var blendEquation:Int;
    public var blendSrcAlpha:Null<Int>;
    public var blendDstAlpha:Null<Int>;
    public var blendEquationAlpha:Null<Int>;
    public var blendColor:Color;
    public var blendAlpha:Float;
    public var depthFunc:Int;
    public var depthTest:Bool;
    public var depthWrite:Bool;
    public var stencilWriteMask:Int;
    public var stencilFunc:Int;
    public var stencilRef:Int;
    public var stencilFuncMask:Int;
    public var stencilFail:Int;
    public var stencilZFail:Int;
    public var stencilZPass:Int;
    public var stencilWrite:Bool;
    public var clippingPlanes:Array<Plane>;
    public var clipIntersection:Bool;
    public var clipShadows:Bool;
    public var shadowSide:Null<Int>;
    public var colorWrite:Bool;
    public var precision:Null<String>;
    public var polygonOffset:Bool;
    public var polygonOffsetFactor:Float;
    public var polygonOffsetUnits:Float;
    public var dithering:Bool;
    public var alphaToCoverage:Bool;
    public var premultipliedAlpha:Bool;
    public var forceSinglePass:Bool;
    public var visible:Bool;
    public var toneMapped:Bool;
    public var userData:Dynamic;

    private var _alphaTest:Int;

    public function new() {
        super();
        _materialId++;
        id = _materialId;
        uuid = MathUtils.generateUUID();
        name = '';
        type = 'Material';
        blending = NormalBlending;
        side = FrontSide;
        vertexColors = false;
        opacity = 1;
        transparent = false;
        alphaHash = false;
        blendSrc = SrcAlphaFactor;
        blendDst = OneMinusSrcAlphaFactor;
        blendEquation = AddEquation;
        blendSrcAlpha = null;
        blendDstAlpha = null;
        blendEquationAlpha = null;
        blendColor = new Color(0, 0, 0);
        blendAlpha = 0;
        depthFunc = LessEqualDepth;
        depthTest = true;
        depthWrite = true;
        stencilWriteMask = 0xff;
        stencilFunc = AlwaysStencilFunc;
        stencilRef = 0;
        stencilFuncMask = 0xff;
        stencilFail = KeepStencilOp;
        stencilZFail = KeepStencilOp;
        stencilZPass = KeepStencilOp;
        stencilWrite = false;
        clippingPlanes = null;
        clipIntersection = false;
        clipShadows = false;
        shadowSide = null;
        colorWrite = true;
        precision = null;
        polygonOffset = false;
        polygonOffsetFactor = 0;
        polygonOffsetUnits = 0;
        dithering = false;
        alphaToCoverage = false;
        premultipliedAlpha = false;
        forceSinglePass = false;
        visible = true;
        toneMapped = true;
        userData = {};
    }

    public function get_alphaTest():Int {
        return _alphaTest;
    }

    public function set_alphaTest(value:Int):Void {
        if (_alphaTest > 0 != value > 0) {
            version++;
        }
        _alphaTest = value;
    }

    public function onBuild(shaderObject:Dynamic, renderer:Dynamic):Void {}

    public function onBeforeRender(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, object:Dynamic, group:Dynamic):Void {}

    public function onBeforeCompile(shaderObject:Dynamic, renderer:Dynamic):Void {}

    public function customProgramCacheKey():String {
        return onBeforeCompile.toString();
    }

    public function setValues(values:Dynamic):Void {
        if (values === null) return;
        for (key in values) {
            var newValue = values[key];
            if (newValue === null) {
                trace('THREE.Material: parameter \'' + key + '\' has value of null.');
                continue;
            }
            var currentValue = this[key];
            if (currentValue === null) {
                trace('THREE.Material: \'' + key + '\' is not a property of THREE.' + type + '.');
                continue;
            }
            if (currentValue.isColor) {
                currentValue.set(newValue);
            } else if (currentValue.isVector3 && newValue.isVector3) {
                currentValue.copy(newValue);
            } else {
                this[key] = newValue;
            }
        }
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var isRootObject:Bool = (meta === null || Std.is(meta, String));
        if (isRootObject) {
            meta = {
                textures: {},
                images: {}
            };
        }
        var data:Dynamic = {
            metadata: {
                version: 4.6,
                type: 'Material',
                generator: 'Material.toJSON'
            }
        };
        // standard Material serialization
        data.uuid = uuid;
        data.type = type;
        if (name != '') data.name = name;
        if (color != null && color.isColor) data.color = color.getHex();
        // ...
        // (omitted for brevity)
        // ...
        return data;
    }

    public function clone():Material {
        return new Material().copy(this);
    }

    public function copy(source:Material):Material {
        name = source.name;
        blending = source.blending;
        side = source.side;
        vertexColors = source.vertexColors;
        // ...
        // (omitted for brevity)
        // ...
        return this;
    }

    public function dispose():Void {
        dispatchEvent({ type: 'dispose' });
    }

    public function set_needsUpdate(value:Bool):Void {
        if (value) version++;
    }
}