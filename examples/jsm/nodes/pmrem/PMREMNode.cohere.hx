import TempNode from '../core/TempNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { texture } from '../accessors/TextureNode.hx';
import { textureCubeUV } from './PMREMUtils.hx';
import { uniform } from '../core/UniformNode.hx';
import { NodeUpdateType } from '../core/constants.hx';
import { nodeProxy, vec3 } from '../shadernode/ShaderNode.hx';
import { WebGLCoordinateSystem } from 'three';

var _generator = null;

var _cache = new WeakMap();

function _generateCubeUVSize(imageHeight) {
    var maxMip = Std.int(Math.log2(imageHeight) - 2);
    var texelHeight = 1.0 / imageHeight;
    var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));
    return {texelWidth, texelHeight, maxMip};
}

function _getPMREMFromTexture(texture) {
    var cacheTexture = _cache.get(texture);
    var pmremVersion = cacheTexture != null ? cacheTexture.pmremVersion : -1;
    if (pmremVersion != texture.pmremVersion) {
        if (texture.isCubeTexture) {
            if (texture.source.data.exists((texture) => texture == null)) {
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

class PMREMNode extends TempNode {
    constructor(value, uvNode = null, levelNode = null) {
        super('vec3');
        this._value = value;
        this._pmrem = null;
        this.uvNode = uvNode;
        this.levelNode = levelNode;
        this._generator = null;
        this._texture = texture(null);
        this._width = uniform(0);
        this._height = uniform(0);
        this._maxMip = uniform(0);
        this.updateBeforeType = NodeUpdateType.RENDER;
    }

    set value(value) {
        this._value = value;
        this._pmrem = null;
    }

    get value() {
        return this._value;
    }

    updateFromTexture(texture) {
        var cubeUVSize = _generateCubeUVSize(texture.image.height);
        this._texture.value = texture;
        this._width.value = cubeUVSize.texelWidth;
        this._height.value = cubeUVSize.texelHeight;
        this._maxMip.value = cubeUVSize.maxMip;
    }

    updateBefore() {
        var pmrem = this._pmrem;
        var pmremVersion = pmrem != null ? pmrem.pmremVersion : -1;
        var texture = this._value;
        if (pmremVersion != texture.pmremVersion) {
            if (texture.isPMREMTexture == true) {
                pmrem = texture;
            } else {
                pmrem = _getPMREMFromTexture(texture);
            }
            this._pmrem = pmrem;
            this.updateFromTexture(pmrem);
        }
    }

    setup(builder) {
        if (_generator == null) {
            _generator = builder.createPMREMGenerator();
        }
        this.updateBefore(builder);
        var uvNode = this.uvNode;
        if (uvNode == null && builder.context.getUV != null) {
            uvNode = builder.context.getUV(this);
        }
        var texture = this.value;
        if (builder.renderer.coordinateSystem == WebGLCoordinateSystem && !texture.isPMREMTexture && texture.isRenderTargetTexture) {
            uvNode = vec3(uvNode.x.negate(), uvNode.yz);
        }
        var levelNode = this.levelNode;
        if (levelNode == null && builder.context.getTextureLevel != null) {
            levelNode = builder.context.getTextureLevel(this);
        }
        return textureCubeUV(this._texture, uvNode, levelNode, this._width, this._height, this._maxMip);
    }
}

export var pmremTexture = nodeProxy(PMREMNode);

addNodeClass('PMREMNode', PMREMNode);

export default PMREMNode;