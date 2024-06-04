import TempNode from "../core/TempNode";
import Node from "../core/Node";
import TextureNode from "../accessors/TextureNode";
import PMREMUtils from "./PMREMUtils";
import UniformNode from "../core/UniformNode";
import { NodeUpdateType } from "../core/constants";
import ShaderNode from "../shadernode/ShaderNode";
import WebGLCoordinateSystem from "three";

class PMREMNode extends TempNode {
  private _value: dynamic;
  private _pmrem: dynamic;
  public uvNode: dynamic;
  public levelNode: dynamic;
  private _generator: dynamic;
  private _texture: dynamic;
  private _width: dynamic;
  private _height: dynamic;
  private _maxMip: dynamic;

  public constructor(value: dynamic, uvNode: dynamic = null, levelNode: dynamic = null) {
    super("vec3");
    this._value = value;
    this._pmrem = null;
    this.uvNode = uvNode;
    this.levelNode = levelNode;
    this._generator = null;
    this._texture = TextureNode.texture(null);
    this._width = UniformNode.uniform(0);
    this._height = UniformNode.uniform(0);
    this._maxMip = UniformNode.uniform(0);
    this.updateBeforeType = NodeUpdateType.RENDER;
  }

  public set value(value: dynamic) {
    this._value = value;
    this._pmrem = null;
  }

  public get value(): dynamic {
    return this._value;
  }

  public updateFromTexture(texture: dynamic) {
    var cubeUVSize = this._generateCubeUVSize(texture.image.height);
    this._texture.value = texture;
    this._width.value = cubeUVSize.texelWidth;
    this._height.value = cubeUVSize.texelHeight;
    this._maxMip.value = cubeUVSize.maxMip;
  }

  public updateBefore(builder: dynamic) {
    var pmrem = this._pmrem;
    var pmremVersion = pmrem != null ? pmrem.pmremVersion : -1;
    var texture = this._value;
    if (pmremVersion != texture.pmremVersion) {
      if (texture.isPMREMTexture == true) {
        pmrem = texture;
      } else {
        pmrem = this._getPMREMFromTexture(texture);
      }
      this._pmrem = pmrem;
      this.updateFromTexture(pmrem);
    }
  }

  public setup(builder: dynamic): dynamic {
    if (this._generator == null) {
      this._generator = builder.createPMREMGenerator();
    }
    this.updateBefore(builder);
    var uvNode = this.uvNode;
    if (uvNode == null && builder.context.getUV != null) {
      uvNode = builder.context.getUV(this);
    }
    var texture = this.value;
    if (
      builder.renderer.coordinateSystem == WebGLCoordinateSystem &&
      texture.isPMREMTexture != true &&
      texture.isRenderTargetTexture == true
    ) {
      uvNode = ShaderNode.vec3(ShaderNode.negate(uvNode.x), uvNode.yz);
    }
    var levelNode = this.levelNode;
    if (levelNode == null && builder.context.getTextureLevel != null) {
      levelNode = builder.context.getTextureLevel(this);
    }
    return PMREMUtils.textureCubeUV(
      this._texture,
      uvNode,
      levelNode,
      this._width,
      this._height,
      this._maxMip
    );
  }

  private _generateCubeUVSize(imageHeight: Float): dynamic {
    var maxMip = Math.log2(imageHeight) - 2;
    var texelHeight = 1.0 / imageHeight;
    var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));
    return {
      texelWidth: texelWidth,
      texelHeight: texelHeight,
      maxMip: maxMip
    };
  }

  private _getPMREMFromTexture(texture: dynamic): dynamic {
    var cacheTexture = this._cache.get(texture);
    var pmremVersion = cacheTexture != null ? cacheTexture.pmremVersion : -1;
    if (pmremVersion != texture.pmremVersion) {
      if (texture.isCubeTexture) {
        if (
          texture.source.data.some(function(texture: dynamic) {
            return texture == null;
          })
        ) {
          throw new Error(
            "PMREMNode: Undefined texture in CubeTexture. Use onLoad callback or async loader"
          );
        }
        cacheTexture = this._generator.fromCubemap(texture, cacheTexture);
      } else {
        if (texture.image == null) {
          throw new Error(
            "PMREMNode: Undefined image in Texture. Use onLoad callback or async loader"
          );
        }
        cacheTexture = this._generator.fromEquirectangular(
          texture,
          cacheTexture
        );
      }
      cacheTexture.pmremVersion = texture.pmremVersion;
      this._cache.set(texture, cacheTexture);
    }
    return cacheTexture.texture;
  }

  private _cache: WeakMap<dynamic, dynamic> = new WeakMap();
}

export var pmremTexture: dynamic = ShaderNode.nodeProxy(PMREMNode);
Node.addNodeClass("PMREMNode", PMREMNode);

export default PMREMNode;