package three.js.examples.jsm.nodes.pmrem;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.accessors.TextureNode;
import three.js.utils.PMREMUtils;
import three.js.core.UniformNode;
import three.js.constants.NodeUpdateType;
import three.js.shadernode.ShaderNode;
import three.js/WebGLCoordinateSystem;

class PMREMNode extends TempNode {
    private var _value:Dynamic;
    private var _pmrem:Dynamic;
    private var uvNode:Node;
    private var levelNode:Node;
    private var _generator:Dynamic;
    private var _texture:TextureNode;
    private var _width:UniformNode;
    private var _height:UniformNode;
    private var _maxMip:UniformNode;

    public function new(value:Dynamic, uvNode:Node = null, levelNode:Node = null) {
        super('vec3');

        this._value = value;
        this._pmrem = null;
        this.uvNode = uvNode;
        this.levelNode = levelNode;
        this._generator = null;
        this._texture = new TextureNode(null);
        this._width = new UniformNode(0);
        this._height = new UniformNode(0);
        this._maxMip = new UniformNode(0);

        this.updateBeforeType = NodeUpdateType.RENDER;
    }

    public function setValue(value:Dynamic) {
        this._value = value;
        this._pmrem = null;
    }

    public function getValue():Dynamic {
        return this._value;
    }

    public function updateFromTexture(texture:TextureNode) {
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

    public function setup(builder:Dynamic) {
        if (_generator == null) {
            _generator = builder.createPMREMGenerator();
        }

        this.updateBefore(builder);

        var uvNode = this.uvNode;
        if (uvNode == null && builder.context.getUV != null) {
            uvNode = builder.context.getUV(this);
        }

        var texture = this._value;
        if (builder.renderer.coordinateSystem == WebGLCoordinateSystem && texture.isPMREMTexture != true && texture.isRenderTargetTexture) {
            uvNode = new Vec3(-uvNode.x, uvNode.y, uvNode.z);
        }

        var levelNode = this.levelNode;
        if (levelNode == null && builder.context.getTextureLevel != null) {
            levelNode = builder.context.getTextureLevel(this);
        }

        return textureCubeUV(this._texture, uvNode, levelNode, this._width, this._height, this._maxMip);
    }
}

private function _generateCubeUVSize(imageHeight:Int):{texelWidth:Float, texelHeight:Float, maxMip:Float} {
    var maxMip = Math.log2(imageHeight) - 2;
    var texelHeight:Float = 1.0 / imageHeight;
    var texelWidth:Float = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));
    return {texelWidth: texelWidth, texelHeight: texelHeight, maxMip: maxMip};
}

private function _getPMREMFromTexture(texture:TextureNode):TextureNode {
    var cacheTexture:Dynamic = _cache.get(texture);
    var pmremVersion = cacheTexture != null ? cacheTexture.pmremVersion : -1;

    if (pmremVersion != texture.pmremVersion) {
        if (texture.isCubeTexture) {
            if (texture.source.data.some(function(tex) return tex == null)) {
                throw new Error('PMREMNode: Undefined texture in CubeTexture. Use onLoad callback or async loader');
            }

            cacheTexture = _generator.fromCubemap(texture, cacheTexture);
        } else {
            if (texture.image == null) {
                throw new Error('PMREMNode: Undefined image in Texture. Use onLoad callback or async loader');
            }

            cacheTexture = _generator.fromEquirectangular(texture, cacheTexture);
        }

        cacheTexture.pmremVersion = texture.pmremVersion;
        _cache.set(texture, cacheTexture);
    }

    return cacheTexture.texture;
}

private var _generator:Dynamic = null;
private var _cache:WeakMap<Dynamic, Dynamic> = new WeakMap();

var pmremTexture:Node = nodeProxy(PMREMNode);

addNodeClass('PMREMNode', PMREMNode);

export default PMREMNode;