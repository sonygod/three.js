package three.js.nodes.display;

import haxe.ds.ObjectMap;
import three.js.core.TempNode;
import three.js.nodes.ShaderNode;

class ToneMappingNode extends TempNode {
  public var toneMapping:Dynamic;
  public var exposureNode:ShaderNode;
  public var colorNode:ShaderNode;

  public function new(toneMapping:Dynamic = NoToneMapping, exposureNode:ShaderNode = null, colorNode:ShaderNode = null) {
    super('vec3');
    this.toneMapping = toneMapping;
    this.exposureNode = exposureNode;
    this.colorNode = colorNode;
  }

  override public function getCacheKey():String {
    var cacheKey = super.getCacheKey();
    cacheKey += '{toneMapping:' + this.toneMapping + ',nodes:' + cacheKey + '}';
    return cacheKey;
  }

  public function setup(builder:ShaderNode):ShaderNode {
    var colorNode = this.colorNode != null ? this.colorNode : builder.context.color;
    var toneMappingParams = {
      exposure: this.exposureNode,
      color: colorNode
    };
    var toneMappingNode = toneMappingLib.get(this.toneMapping);

    if (toneMappingNode != null) {
      return toneMappingNode(toneMappingParams);
    } else {
      trace('ToneMappingNode: Unsupported Tone Mapping configuration.', this.toneMapping);
      return colorNode;
    }
  }
}

class ToneMapping {
  public static var toneMappingLib:ObjectMap<ShaderNode> = [
    LinearToneMapping => new LinearToneMappingNode(),
    ReinhardToneMapping => new ReinhardToneMappingNode(),
    CineonToneMapping => new OptimizedCineonToneMappingNode(),
    ACESFilmicToneMapping => new ACESFilmicToneMappingNode(),
    AgXToneMapping => new AGXToneMappingNode()
  ];

  public static function toneMapping(mapping:Dynamic, exposure:ShaderNode, color:ShaderNode):ShaderNode {
    return new ToneMappingNode(mapping, exposure, color);
  }

  public static var toneMappingExposure:Int = 0;
}

class LinearToneMappingNode extends ShaderNode {
  public function new() {
    super('vec3');
  }

  override public function evaluate(params:Dynamic):ShaderNode {
    var color = params.color;
    var exposure = params.exposure;
    return color.mul(exposure).clamp();
  }
}

class ReinhardToneMappingNode extends ShaderNode {
  public function new() {
    super('vec3');
  }

  override public function evaluate(params:Dynamic):ShaderNode {
    var color = params.color;
    var exposure = params.exposure;
    color = color.mul(exposure);
    return color.div(color.add(1.0)).clamp();
  }
}

class OptimizedCineonToneMappingNode extends ShaderNode {
  public function new() {
    super('vec3');
  }

  override public function evaluate(params:Dynamic):ShaderNode {
    var color = params.color;
    var exposure = params.exposure;
    color = color.mul(exposure);
    color = color.sub(0.004).max(0.0);
    var a = color.mul(color.mul(6.2).add(0.5));
    var b = color.mul(color.mul(6.2).add(1.7)).add(0.06);
    return a.div(b).pow(2.2);
  }
}

class ACESFilmicToneMappingNode extends ShaderNode {
  public function new() {
    super('vec3');
  }

  override public function evaluate(params:Dynamic):ShaderNode {
    var color = params.color;
    var exposure = params.exposure;
    var ACESInputMat = [
      0.59719, 0.35458, 0.04823,
      0.07600, 0.90834, 0.01566,
      0.02840, 0.13383, 0.83777
    ];
    var ACESOutputMat = [
      1.60475, -0.53108, -0.07367,
      -0.10208, 1.10813, -0.00605,
      -0.00327, -0.07276, 1.07602
    ];
    color = color.mul(exposure).div(0.6);
    color = ACESInputMat.mul(color);
    color = RRTAndODTFit(color);
    color = ACESOutputMat.mul(color);
    return color.clamp();
  }
}

class AGXToneMappingNode extends ShaderNode {
  public function new() {
    super('vec3');
  }

  override public function evaluate(params:Dynamic):ShaderNode {
    var color = params.color;
    var exposure = params.exposure;
    var AgXInsetMatrix = [
      0.856627153315983, 0.137318972929847, 0.11189821299995,
      0.0951212405381588, 0.761241990602591, 0.0767994186031903,
      0.0482516061458583, 0.101439036467562, 0.811302368396859
    ];
    var AgXOutsetMatrix = [
      1.1271005818144368, -0.1413297634984383, -0.14132976349843826,
      -0.11060664309660323, 1.157823702216272, -0.11060664309660294,
      -0.016493938717834573, -0.016493938717834257, 1.2519364065950405
    ];
    var AgxMinEv = -12.47393;
    var AgxMaxEv = 4.026069;
    color = color.mul(exposure);
    color = AgXInsetMatrix.mul(color);
    color = max(color, 1e-10);
    color = log2(color);
    color = (color - AgxMinEv) / (AgxMaxEv - AgxMinEv);
    color = clamp(color, 0.0, 1.0);
    color = agxDefaultContrastApprox(color);
    color = AgXOutsetMatrix.mul(color);
    color = pow(max(vec3(0.0), color), vec3(2.2));
    return clamp(color, 0.0, 1.0);
  }
}

class RRTAndODTFitNode extends ShaderNode {
  public function new() {
    super('vec3');
  }

  override public function evaluate(params:Dynamic):ShaderNode {
    var color = params.color;
    var a = color.mul(color.add(0.0245786)).sub(0.000090537);
    var b = color.mul(color.add(0.4329510).mul(0.983729)).add(0.238081);
    return a.div(b);
  }
}

class AgXContrastApproxNode extends ShaderNode {
  public function new() {
    super('float');
  }

  override public function evaluate(params:Dynamic):ShaderNode {
    var x = params.x;
    var x2 = x.mul(x);
    var x4 = x2.mul(x2);
    return float(15.5).mul(x4.mul(x2)).sub(mul(40.14, x4.mul(x))).add(mul(31.96, x4).sub(mul(6.868, x2.mul(x))).add(mul(0.4298, x2).add(mul(0.1191, x).sub(0.00232))));
  }
}