import NodeMaterial;
import VaryingNode;
import PropertyNode;
import AttributeNode;
import CameraNode;
import MaterialNode;
import ModelNode;
import PositionNode;
import MathNode;
import ShaderNode;
import UVNode;
import ViewportNode;

import three.materials.PointsMaterial;

class InstancedPointsNodeMaterial extends NodeMaterial {

    public function new(params:Dynamic = null) {

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

    public function setupShaders() {

        var useAlphaToCoverage = this.alphaToCoverage;
        var useColor = this.useColor;

        this.vertexNode = ShaderNode.tslFn(() -> {

            var vUv = VaryingNode.varying(ShaderNode.vec2(), 'vUv');
            vUv.assign(UVNode.uv());

            var instancePosition = AttributeNode.attribute('instancePosition');

            var mvPos = PropertyNode.property('vec4', 'mvPos');
            mvPos.assign(ModelNode.modelViewMatrix.mul(ShaderNode.vec4(instancePosition, 1.0)));

            var aspect = ViewportNode.viewport.z.div(ViewportNode.viewport.w);

            var clipPos = CameraNode.cameraProjectionMatrix.mul(mvPos);

            var offset = PropertyNode.property('vec2', 'offset');
            offset.assign(PositionNode.positionGeometry.xy);
            offset.assign(offset.mul(MaterialNode.materialPointWidth));
            offset.assign(offset.div(ViewportNode.viewport.z));
            offset.y.assign(offset.y.mul(aspect));

            offset.assign(offset.mul(clipPos.w));

            clipPos.assign(clipPos.add(ShaderNode.vec4(offset, 0, 0)));

            return clipPos;

        })();

        this.fragmentNode = ShaderNode.tslFn(() -> {

            var vUv = VaryingNode.varying(ShaderNode.vec2(), 'vUv');

            var alpha = PropertyNode.property('float', 'alpha');
            alpha.assign(1);

            var a = vUv.x;
            var b = vUv.y;

            var len2 = a.mul(a).add(b.mul(b));

            if (useAlphaToCoverage) {

                var dlen = PropertyNode.property('float', 'dlen');
                dlen.assign(len2.fwidth());

                alpha.assign(MathNode.smoothstep(dlen.oneMinus(), dlen.add(1), len2).oneMinus());

            } else {

                len2.greaterThan(1.0).discard();

            }

            var pointColorNode;

            if (this.pointColorNode) {

                pointColorNode = this.pointColorNode;

            } else {

                if (useColor) {

                    var instanceColor = AttributeNode.attribute('instanceColor');

                    pointColorNode = instanceColor.mul(MaterialNode.materialColor);

                } else {

                    pointColorNode = MaterialNode.materialColor;

                }

            }

            return ShaderNode.vec4(pointColorNode, alpha);

        })();

        this.needsUpdate = true;

    }

    public function get alphaToCoverage():Bool {

        return this.useAlphaToCoverage;

    }

    public function set alphaToCoverage(value:Bool) {

        if (this.useAlphaToCoverage != value) {

            this.useAlphaToCoverage = value;
            this.setupShaders();

        }

    }

}

NodeMaterial.addNodeMaterial('InstancedPointsNodeMaterial', InstancedPointsNodeMaterial);