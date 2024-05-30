package three.js.examples.jsm.nodes.pmrem;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.accessors.TextureNode;
import three.js.utils.PMREMUtils;
import three.js.core.UniformNode;
import three.js.core.constants.NodeUpdateType;
import three.js.shadernode.ShaderNode;
import three.js.WebGLCoordinateSystem;

class PMREMNode extends TempNode
{
    public var _value:Dynamic;
    public var _pmrem:Dynamic;
    public var uvNode:Dynamic;
    public var levelNode:Dynamic;
    public var _generator:Dynamic;
    public var _texture:TextureNode;
    public var _width:UniformNode;
    public var _height:UniformNode;
    public var _maxMip:UniformNode;

    public function new(value:Dynamic, uvNode:Dynamic = null, levelNode:Dynamic = null)
    {
        super('vec3');
        _value = value;
        _pmrem = null;
        this.uvNode = uvNode;
        this.levelNode = levelNode;
        _generator = null;
        _texture = new TextureNode(null);
        _width = new UniformNode(0);
        _height = new UniformNode(0);
        _maxMip = new UniformNode(0);
        updateBeforeType = NodeUpdateType.RENDER;
    }

    public function set_value(value:Dynamic)
    {
        _value = value;
        _pmrem = null;
    }

    public function get_value():Dynamic
    {
        return _value;
    }

    public function updateFromTexture(texture:Dynamic)
    {
        var cubeUVSize = _generateCubeUVSize(texture.image.height);
        _texture.value = texture;
        _width.value = cubeUVSize.texelWidth;
        _height.value = cubeUVSize.texelHeight;
        _maxMip.value = cubeUVSize.maxMip;
    }

    public function updateBefore()
    {
        var pmrem = _pmrem;
        var pmremVersion = pmrem != null ? pmrem.pmremVersion : -1;
        var texture = _value;

        if (pmremVersion != texture.pmremVersion)
        {
            if (texture.isPMREMTexture == true)
            {
                pmrem = texture;
            }
            else
            {
                pmrem = _getPMREMFromTexture(texture);
            }

            _pmrem = pmrem;
            updateFromTexture(pmrem);
        }
    }

    public function setup(builder:Dynamic)
    {
        if (_generator == null)
        {
            _generator = builder.createPMREMGenerator();
        }

        updateBefore(builder);

        var uvNode = this.uvNode;

        if (uvNode == null && builder.context.getUV != null)
        {
            uvNode = builder.context.getUV(this);
        }

        var texture = _value;

        if (builder.renderer.coordinateSystem == WebGLCoordinateSystem && texture.isPMREMTexture != true && texture.isRenderTargetTexture == true)
        {
            uvNode = vec3(uvNode.x.negate(), uvNode.yz);
        }

        var levelNode = this.levelNode;

        if (levelNode == null && builder.context.getTextureLevel != null)
        {
            levelNode = builder.context.getTextureLevel(this);
        }

        return textureCubeUV(_texture, uvNode, levelNode, _width, _height, _maxMip);
    }

    static function _generateCubeUVSize(imageHeight:Int):{ texelWidth:Float, texelHeight:Float, maxMip:Float }
    {
        var maxMip = Math.log2(imageHeight) - 2;
        var texelHeight = 1.0 / imageHeight;
        var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));
        return { texelWidth: texelWidth, texelHeight: texelHeight, maxMip: maxMip };
    }

    static function _getPMREMFromTexture(texture:Dynamic):Dynamic
    {
        var cacheTexture = _cache.get(texture);

        var pmremVersion = cacheTexture != null ? cacheTexture.pmremVersion : -1;

        if (pmremVersion != texture.pmremVersion)
        {
            if (texture.isCubeTexture)
            {
                if (texture.source.data.some(function(t) return t == null))
                {
                    throw new Error('PMREMNode: Undefined texture in CubeTexture. Use onLoad callback or async loader');
                }

                cacheTexture = _generator.fromCubemap(texture, cacheTexture);
            }
            else
            {
                if (texture.image == null)
                {
                    throw new Error('PMREMNode: Undefined image in Texture. Use onLoad callback or async loader');
                }

                cacheTexture = _generator.fromEquirectangular(texture, cacheTexture);
            }

            cacheTexture.pmremVersion = texture.pmremVersion;

            _cache.set(texture, cacheTexture);
        }

        return cacheTexture.texture;
    }

    static var _cache:WeakMap<Dynamic, Dynamic> = new WeakMap();
    static var _generator:Dynamic = null;
}

var pmremTexture = nodeProxy(PMREMNode);

addNodeClass('PMREMNode', PMREMNode);

export default PMREMNode;