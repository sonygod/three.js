package three.js.examples.jsm.nodes.materials;

import three.js.core.NodeMaterial;
import three.js.core.VarNode;
import three.js.core.VaryingNode;
import three.js.core.PropertyNode;
import three.js.core.AttributeNode;
import three.js.accessors.CameraNode;
import three.js.accessors.MaterialNode;
import three.js.accessors.ModelNode;
import three.js.accessors.PositionNode;
import three.js.math.MathNode;
import three.js.shader.ShaderNode;
import three.js.display.ViewportNode;
import three.js.core.PropertyNode;

class Line2NodeMaterial extends NodeMaterial {

    public var normals:Bool = false;
    public var lights:Bool = false;

    public var useAlphaToCoverage:Bool = true;
    public var useColor:Bool = false;
    public var useDash:Bool = false;
    public var useWorldUnits:Bool = false;

    public var dashOffset:Float = 0;
    public var lineWidth:Float = 1;

    public var lineColorNode:ShaderNode = null;
    public var offsetNode:ShaderNode = null;
    public var dashScaleNode:ShaderNode = null;
    public var dashSizeNode:ShaderNode = null;
    public var gapSizeNode:ShaderNode = null;

    public function new(params:Dynamic = {}) {
        super();

        setDefaultValues(new LineDashedMaterial());

        useAlphaToCoverage = true;
        useColor = params.vertexColors;
        useDash = params.dashed;
        useWorldUnits = false;

        dashOffset = 0;
        lineWidth = 1;

        lineColorNode = null;

        offsetNode = null;
        dashScaleNode = null;
        dashSizeNode = null;
        gapSizeNode = null;

        setValues(params);
    }

    override public function setup(builder:NodeMaterialBuilder) {
        setupShaders();

        super.setup(builder);
    }

    private function setupShaders() {
        var useAlphaToCoverage:Bool = this.useAlphaToCoverage;
        var useColor:Bool = this.useColor;
        var useDash:Bool = this.useDash;
        var useWorldUnits:Bool = this.useWorldUnits;

        var trimSegment:ShaderNode = tslFn((start:Vec4, end:Vec4) -> {
            var a:Float = cameraProjectionMatrix.getElement(2, 2);
            var b:Float = cameraProjectionMatrix.getElement(3, 2);
            var nearEstimate:Float = b * -0.5 / a;

            var alpha:Float = (nearEstimate - start.z) / (end.z - start.z);

            return vec4(mix(start.xyz, end.xyz, alpha), end.w);
        });

        vertexNode = tslFn(() -> {
            varyingProperty("vec2", "vUv").assign(uv());

            var instanceStart:AttributeNode = attribute("instanceStart");
            var instanceEnd:AttributeNode = attribute("instanceEnd");

            var start:PropertyNode = property("vec4", "start");
            var end:PropertyNode = property("vec4", "end");

            start.assign(modelViewMatrix.mul(vec4(instanceStart, 1.0)));
            end.assign(modelViewMatrix.mul(vec4(instanceEnd, 1.0)));

            if (useWorldUnits) {
                varyingProperty("vec3", "worldStart").assign(start.xyz);
                varyingProperty("vec3", "worldEnd").assign(end.xyz);
            }

            var aspect:Float = viewport.z / viewport.w;

            // ... (rest of the shader code)

            return clip;
        });

        fragmentNode = tslFn(() -> {
            var vUv:VaryingNode = varying("vec2", "vUv");

            if (useDash) {
                var offsetNode:ShaderNode = this.offsetNode ? float(this.offsetNode) : materialLineDashOffset;
                var dashScaleNode:ShaderNode = this.dashScaleNode ? float(this.dashScaleNode) : materialLineScale;
                var dashSizeNode:ShaderNode = this.dashSizeNode ? float(this.dashSizeNode) : materialLineDashSize;
                var gapSizeNode:ShaderNode = this.gapSizeNode ? float(this.gapSizeNode) : materialLineGapSize;

                dashSize.assign(dashSizeNode);
                gapSize.assign(gapSizeNode);

                // ... (rest of the shader code)
            }

            // ... (rest of the shader code)

            return vec4(lineColorNode, alpha);
        });
    }

    public var worldUnits(get, set):Bool;

    private function get_worldUnits():Bool {
        return useWorldUnits;
    }

    private function set_worldUnits(value:Bool):Void {
        if (useWorldUnits != value) {
            useWorldUnits = value;
            needsUpdate = true;
        }
    }

    public var dashed(get, set):Bool;

    private function get_dashed():Bool {
        return useDash;
    }

    private function set_dashed(value:Bool):Void {
        if (useDash != value) {
            useDash = value;
            needsUpdate = true;
        }
    }

    public var alphaToCoverage(get, set):Bool;

    private function get_alphaToCoverage():Bool {
        return useAlphaToCoverage;
    }

    private function set_alphaToCoverage(value:Bool):Void {
        if (useAlphaToCoverage != value) {
            useAlphaToCoverage = value;
            needsUpdate = true;
        }
    }
}

addNodeMaterial("Line2NodeMaterial", Line2NodeMaterial);