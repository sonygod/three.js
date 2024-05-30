package three.js.examples.jsm.nodes.materials;

import thx.node.NodeMaterial;
import thx.node.NodeMaterialBuilder;

class Line2NodeMaterial extends NodeMaterial {
  public var normals: Bool = false;
  public var lights: Bool = false;
  public var useAlphaToCoverage: Bool = true;
  public var useColor: Bool = false;
  public var useDash: Bool = false;
  public var useWorldUnits: Bool = false;
  public var dashOffset: Float = 0;
  public var lineWidth: Float = 1;
  public var lineColorNode: Node;
  public var offsetNode: Node;
  public var dashScaleNode: Node;
  public var dashSizeNode: Node;
  public var gapSizeNode: Node;

  public function new(?params: {}) {
    super();
    setDefaultValues(new LineDashedMaterial());
    setupShaders();
    setValues(params);
  }

  override public function setup(builder: NodeMaterialBuilder) {
    setupShaders();
    super.setup(builder);
  }

  private function setupShaders() {
    var useAlphaToCoverage = this.useAlphaToCoverage;
    var useColor = this.useColor;
    var useDash = this.useDash;
    var useWorldUnits = this.useWorldUnits;

    var trimSegment = thx.fn((start: Vec4, end: Vec4) -> {
      var a = cameraProjectionMatrix.element(2, 2);
      var b = cameraProjectionMatrix.element(3, 2);
      var nearEstimate = b * -0.5 / a;
      var alpha = nearEstimate - start.z / (end.z - start.z);
      return Vec4.mix(start.xyz, end.xyz, alpha).add(end.w);
    });

    vertexNode = thx.fn(() -> {
      varying("vUv", Vec2);

      var instanceStart = attribute("instanceStart");
      var instanceEnd = attribute("instanceEnd");

      var start = property("vec4", "start");
      var end = property("vec4", "end");

      start.assign(modelViewMatrix * Vec4(instanceStart, 1.0));
      end.assign(modelViewMatrix * Vec4(instanceEnd, 1.0));

      if (useWorldUnits) {
        varying("worldStart", Vec3).assign(start.xyz);
        varying("worldEnd", Vec3).assign(end.xyz);
      }

      var aspect = viewport.z / viewport.w;

      // ... (rest of the vertex shader code)

      return clip;
    })();

    fragmentNode = thx.fn(() -> {
      var vUv = varying("vUv", Vec2);

      if (useDash) {
        // ... (dash handling code)
      }

      // ... (rest of the fragment shader code)

      return Vec4(lineColorNode, alpha);
    })();
  }

  public function get_worldUnits(): Bool {
    return useWorldUnits;
  }

  public function set_worldUnits(value: Bool) {
    if (useWorldUnits != value) {
      useWorldUnits = value;
      needsUpdate = true;
    }
  }

  public function get_dashed(): Bool {
    return useDash;
  }

  public function set_dashed(value: Bool) {
    if (useDash != value) {
      useDash = value;
      needsUpdate = true;
    }
  }

  public function get_alphaToCoverage(): Bool {
    return useAlphaToCoverage;
  }

  public function set_alphaToCoverage(value: Bool) {
    if (useAlphaToCoverage != value) {
      useAlphaToCoverage = value;
      needsUpdate = true;
    }
  }
}

thx.addNodeMaterial("Line2NodeMaterial", Line2NodeMaterial);