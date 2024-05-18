package three.js.examples.jsm.nodes.materials;

import three.js.core.NodeMaterial;
import three.js.core.VaryingNode;
import three.js.core.PropertyNode;
import three.js.core.AttributeNode;
import three.js.accessors.CameraNode;
import three.js.accessors.MaterialNode;
import three.js.accessors.ModelNode;
import three.js.accessors.PositionNode;
import three.js.math.MathNode;
import three.js.shader.ShaderNode;
import three.js.accessors.UVNode;
import three.js.display.ViewportNode;
import three.js.materials.PointsMaterial;

class InstancedPointsNodeMaterial extends NodeMaterial {
    public var normals:Bool;
    public var lights:Bool;
    public var useAlphaToCoverage:Bool;
    public var useColor:Bool;
    public var pointWidth:Float;
    public var pointColorNode:ShaderNode;

    public function new(params:Dynamic = {}) {
        super();
        this.normals = false;
        this.lights = false;
        this.useAlphaToCoverage = true;
        this.useColor = params.vertexColors;
        this.pointWidth = 1;
        this.pointColorNode = null;
        this.setDefaultValues(new PointsMaterial());
        this.setupShaders();
        this.setValues(params);
    }

    private function setupShaders():Void {
        var useAlphaToCoverage:Bool = this.useAlphaToCoverage;
        var useColor:Bool = this.useColor;

        this.vertexNode = tslFn(function():ShaderNode {
            var vUv:ShaderNode = varying(vec2(), 'vUv');
            vUv.assign(uv());

            var instancePosition:ShaderNode = attribute('instancePosition');

            // camera space
            var mvPos:ShaderNode = property('vec4', 'mvPos');
            mvPos.assign(modelViewMatrix.mul(vec4(instancePosition, 1.0)));

            var aspect:ShaderNode = viewport.z.div(viewport.w);

            // clip space
            var clipPos:ShaderNode = cameraProjectionMatrix.mul(mvPos);

            // offset in ndc space
            var offset:ShaderNode = property('vec2', 'offset');
            offset.assign(positionGeometry.xy);
            offset.assign(offset.mul(materialPointWidth));
            offset.assign(offset.div(viewport.z));
            offset.y.assign(offset.y.mul(aspect));

            // back to clip space
            offset.assign(offset.mul(clipPos.w));

            clipPos.assign(clipPos.add(vec4(offset, 0, 0)));

            return clipPos;
        });

        this.fragmentNode = tslFn(function():ShaderNode {
            var vUv:ShaderNode = varying(vec2(), 'vUv');

            var alpha:ShaderNode = property('float', 'alpha');
            alpha.assign(1);

            var a:ShaderNode = vUv.x;
            var b:ShaderNode = vUv.y;

            var len2:ShaderNode = a.mul(a).add(b.mul(b));

            if (useAlphaToCoverage) {
                var dlen:ShaderNode = property('float', 'dlen');
                dlen.assign(len2.fwidth());
                alpha.assign(smoothstep(dlen.oneMinus(), dlen.add(1), len2).oneMinus());
            } else {
                len2.greaterThan(1.0).discard();
            }

            var pointColorNode:ShaderNode;

            if (this.pointColorNode != null) {
                pointColorNode = this.pointColorNode;
            } else {
                if (useColor) {
                    var instanceColor:ShaderNode = attribute('instanceColor');
                    pointColorNode = instanceColor.mul(materialColor);
                } else {
                    pointColorNode = materialColor;
                }
            }

            return vec4(pointColorNode, alpha);
        });

        this.needsUpdate = true;
    }

    public function get_alphaToCoverage():Bool {
        return this.useAlphaToCoverage;
    }

    public function set_alphaToCoverage(value:Bool):Void {
        if (this.useAlphaToCoverage != value) {
            this.useAlphaToCoverage = value;
            this.setupShaders();
        }
    }
}

NodeMaterial.addNodeMaterial('InstancedPointsNodeMaterial', InstancedPointsNodeMaterial);