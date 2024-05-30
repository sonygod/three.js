package three.js.examples.jsm.nodes.materials;

import three.js.examples.jsm.nodes.materials.NodeMaterial;
import three.js.examples.jsm.core.VaryingNode;
import three.js.examples.jsm.core.PropertyNode;
import three.js.examples.jsm.core.AttributeNode;
import three.js.examples.jsm.accessors.CameraNode;
import three.js.examples.jsm.accessors.MaterialNode;
import three.js.examples.jsm.accessors.ModelNode;
import three.js.examples.jsm.accessors.PositionNode;
import three.js.examples.jsm.math.MathNode;
import three.js.examples.jsm.shadernode.ShaderNode;
import three.js.examples.jsm.accessors.UVNode;
import three.js.examples.jsm.display.ViewportNode;
import three.PointsMaterial;

class InstancedPointsNodeMaterial extends NodeMaterial
{
    public function new(?params: {}) {
        super();
        this.normals = false;
        this.lights = false;
        this.useAlphaToCoverage = true;
        this.useColor = params != null && params.vertexColors;
        this.pointWidth = 1;
        this.pointColorNode = null;
        this.setDefaultValues(new PointsMaterial());
        this.setupShaders();
        this.setValues(params);
    }

    public function setupShaders():Void {
        var useAlphaToCoverage:Bool = this.alphaToCoverage;
        var useColor:Bool = this.useColor;

        this.vertexNode = tslFn(function() {
            var vUv:Vec2 = varying('vUv', uv());
            var instancePosition:Attribute = attribute('instancePosition');
            var mvPos:Property<Vec4> = property('mvPos', modelViewMatrix.mul(vec4(instancePosition, 1.0)));
            var aspect:Float = viewport.z / viewport.w;
            var offset:Property<Vec2> = property('offset', positionGeometry.xy.mul(materialPointWidth).div(viewport.z));
            offset.y = offset.y * aspect;
            var clipPos:Vec4 = cameraProjectionMatrix.mul(mvPos);
            clipPos.xy += offset.mul(clipPos.w);
            return clipPos;
        });

        this.fragmentNode = tslFn(function() {
            var vUv:Vec2 = varying('vUv');
            var alpha:Property<Float> = property('alpha', 1.0);
            var a:Float = vUv.x;
            var b:Float = vUv.y;
            var len2:Float = a * a + b * b;
            if (useAlphaToCoverage) {
                var dlen:Property<Float> = property('dlen', len2.fwidth());
                alpha.assign(smoothstep(dlen.oneMinus(), dlen.add(1.0), len2).oneMinus());
            } else {
                len2.greaterThan(1.0).discard();
            }
            var pointColorNode:Vec4;
            if (this.pointColorNode != null) {
                pointColorNode = this.pointColorNode;
            } else {
                if (useColor) {
                    var instanceColor:Attribute = attribute('instanceColor');
                    pointColorNode = instanceColor.mul(materialColor);
                } else {
                    pointColorNode = materialColor;
                }
            }
            return vec4(pointColorNode, alpha);
        });
        this.needsUpdate = true;
    }

    public var alphaToCoverage(get, set):Bool;

    private function get_alphaToCoverage():Bool {
        return this.useAlphaToCoverage;
    }

    private function set_alphaToCoverage(value:Bool):Void {
        if (this.useAlphaToCoverage != value) {
            this.useAlphaToCoverage = value;
            this.setupShaders();
        }
    }
}

NodeMaterial.addNodeMaterial('InstancedPointsNodeMaterial', InstancedPointsNodeMaterial);