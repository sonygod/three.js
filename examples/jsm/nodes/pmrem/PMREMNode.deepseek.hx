import three.examples.jsm.nodes.core.TempNode;
import three.examples.jsm.nodes.core.Node;
import three.examples.jsm.nodes.accessors.TextureNode;
import three.examples.jsm.nodes.pmrem.PMREMUtils;
import three.examples.jsm.nodes.core.UniformNode;
import three.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.examples.jsm.nodes.shadernode.ShaderNode;
import three.WebGLCoordinateSystem;

private static var _generator:Null<PMREMGenerator> = null;

private static var _cache:WeakMap<Texture, PMREMTexture> = new WeakMap();

private static function _generateCubeUVSize(imageHeight:Int):{texelWidth:Float, texelHeight:Float, maxMip:Float} {
    var maxMip = Math.log2(imageHeight) - 2;
    var texelHeight = 1.0 / imageHeight;
    var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));
    return {texelWidth:texelWidth, texelHeight:texelHeight, maxMip:maxMip};
}

private static function _getPMREMFromTexture(texture:Texture):Texture {
    var cacheTexture = _cache.get(texture);
    var pmremVersion = cacheTexture != null ? cacheTexture.pmremVersion : -1;
    if (pmremVersion != texture.pmremVersion) {
        if (texture.isCubeTexture) {
            if (texture.source.data.some((texture) => texture == null)) {
                throw 'PMREMNode: Undefined texture in CubeTexture. Use onLoad callback or async loader';
            }
            cacheTexture = _generator.fromCubemap(texture, cacheTexture);
        } else {
            if (texture.image == null) {
                throw 'PMREMNode: Undefined image in Texture. Use onLoad callback or async loader';
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
    public var uvNode:ShaderNode;
    public var levelNode:ShaderNode;
    public var _texture:TextureNode;
    public var _width:UniformNode;
    public var _height:UniformNode;
    public var _maxMip:UniformNode;

    public function new(value:Texture, uvNode:ShaderNode = null, levelNode:ShaderNode = null) {
        super('vec3');
        this._value = value;
        this._pmrem = null;
        this.uvNode = uvNode;
        this.levelNode = levelNode;
        this._texture = new TextureNode(null);
        this._width = new UniformNode(0);
        this._height = new UniformNode(0);
        this._maxMip = new UniformNode(0);
        this.updateBeforeType = NodeUpdateType.RENDER;
    }

    public function set value(value:Texture) {
        this._value = value;
        this._pmrem = null;
    }

    public function get value():Texture {
        return this._value;
    }

    public function updateFromTexture(texture:Texture) {
        var cubeUVSize = _generateCubeUVSize(texture.image.height);
        this._texture.value = texture;
        this._width.value = cubeUVSize.texelWidth;
        this._height.value = cubeUVSize.texelHeight;
        this._maxMip.value = cubeUVSize.maxMip;
    }

    public function updateBefore() {
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

    public function setup(builder:ShaderNodeBuilder) {
        if (_generator == null) {
            _generator = builder.createPMREMGenerator();
        }
        this.updateBefore();
        var uvNode = this.uvNode;
        if (uvNode == null && builder.context.getUV != null) {
            uvNode = builder.context.getUV(this);
        }
        var texture = this.value;
        if (builder.renderer.coordinateSystem == WebGLCoordinateSystem && texture.isPMREMTexture != true && texture.isRenderTargetTexture) {
            uvNode = ShaderNode.vec3(uvNode.x.negate(), uvNode.yz);
        }
        var levelNode = this.levelNode;
        if (levelNode == null && builder.context.getTextureLevel != null) {
            levelNode = builder.context.getTextureLevel(this);
        }
        return PMREMUtils.textureCubeUV(this._texture, uvNode, levelNode, this._width, this._height, this._maxMip);
    }
}

public static function pmremTexture(node:PMREMNode):ShaderNode {
    return ShaderNode.nodeProxy(node);
}

Node.addNodeClass('PMREMNode', PMREMNode);