import TempNode from '../core/TempNode.hx';
import Node from '../core/Node.hx';
import TextureNode from '../accessors/TextureNode.hx';
import PMREMUtils from './PMREMUtils.hx';
import UniformNode from '../core/UniformNode.hx';
import Constants from '../core/constants.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';
import WebGLCoordinateSystem from 'three.WebGLCoordinateSystem';

var _generator:PMREMGenerator = null;
var _cache:Map<Texture, PMREMTexture> = new WeakMap<Texture, PMREMTexture>();

function _generateCubeUVSize(imageHeight:Int):CubeUVSize {
    var maxMip:Int = Math.log2(imageHeight) - 2;
    var texelHeight:Float = 1.0 / imageHeight;
    var texelWidth:Float = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));
    return { texelWidth, texelHeight, maxMip };
}

function _getPMREMFromTexture(texture:Texture):Texture {
    var cacheTexture = _cache.get(texture);
    var pmremVersion = cacheTexture != null ? cacheTexture.pmremVersion : -1;

    if (pmremVersion != texture.pmremVersion) {
        if (texture.isCubeTexture) {
            if (texture.source.data.some((texture) => texture == null)) {
                throw new Error("PMREMNode: Undefined texture in CubeTexture. Use onLoad callback or async loader");
            }
            cacheTexture = _generator.fromCubemap(texture, cacheTexture);
        } else {
            if (texture.image == null) {
                throw new Error("PMREMNode: Undefined image in Texture. Use onLoad callback or async loader");
            }
            cacheTexture = _generator.fromEquirectangular(texture, cacheTexture);
        }
        cacheTexture.pmremVersion = texture.pmremVersion;
        _cache.set(texture, cacheTexture);
    }
    return cacheTexture.texture;
}

class PMREMNode extends TempNode {
    public var _value:Texture;
    public var _pmrem:PMREMTexture;
    public var uvNode:Vec3Node;
    public var levelNode:IntNode;
    public var _generator:PMREMGenerator;
    public var _texture:TextureNode;
    public var _width:UniformNode;
    public var _height:UniformNode;
    public var _maxMip:UniformNode;

    public function new(value:Texture, uvNode:Vec3Node = null, levelNode:IntNode = null) {
        super("vec3");
        this._value = value;
        this._pmrem = null;
        this.uvNode = uvNode;
        this.levelNode = levelNode;
        this._generator = null;
        this._texture = new TextureNode(null);
        this._width = new UniformNode(0);
        this._height = new UniformNode(0);
        this._maxMip = new UniformNode(0);
        this.updateBeforeType = Constants.NodeUpdateType.RENDER;
    }

    public function set value(value:Texture):Void {
        this._value = value;
        this._pmrem = null;
    }

    public function get value():Texture {
        return this._value;
    }

    public function updateFromTexture(texture:Texture):Void {
        var cubeUVSize = _generateCubeUVSize(texture.image.height);
        this._texture.value = texture;
        this._width.value = cubeUVSize.texelWidth;
        this._height.value = cubeUVSize.texelHeight;
        this._maxMip.value = cubeUVSize.maxMip;
    }

    public function updateBefore():Void {
        var pmrem = this._pmrem;
        var pmremVersion = pmrem != null ? pmrem.pmremVersion : -1;
        var texture = this._value;

        if (pmremVersion != texture.pmremVersion) {
            if (texture.isPMREMTexture) {
                pmrem = texture;
            } else {
                pmrem = _getPMREMFromTexture(texture);
            }
            this._pmrem = pmrem;
            this.updateFromTexture(pmrem);
        }
    }

    public function setup(builder:Builder):Vec3Node {
        if (_generator == null) {
            _generator = builder.createPMREMGenerator();
        }

        this.updateBefore();

        var uvNode = this.uvNode;
        if (uvNode == null && builder.context.getUV != null) {
            uvNode = builder.context.getUV(this);
        }

        var texture = this.value;
        if (builder.renderer.coordinateSystem == WebGLCoordinateSystem && !texture.isPMREMTexture && texture.isRenderTargetTexture) {
            uvNode = new Vec3Node(uvNode.x.negate(), uvNode.yz);
        }

        var levelNode = this.levelNode;
        if (levelNode == null && builder.context.getTextureLevel != null) {
            levelNode = builder.context.getTextureLevel(this);
        }

        return PMREMUtils.textureCubeUV(this._texture, uvNode, levelNode, this._width, this._height, this._maxMip);
    }
}

export function pmremTexture(value:Texture, uvNode:Vec3Node = null, levelNode:IntNode = null):PMREMNode {
    return ShaderNode.nodeProxy(new PMREMNode(value, uvNode, levelNode));
}

Node.addNodeClass("PMREMNode", PMREMNode);

export default PMREMNode;