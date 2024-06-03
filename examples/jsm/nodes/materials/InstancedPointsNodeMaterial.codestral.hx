import NodeMaterial;
import NodeMaterial.addNodeMaterial;
import VaryingNode.varying;
import PropertyNode.property;
import AttributeNode.attribute;
import CameraNode.cameraProjectionMatrix;
import MaterialNode.materialColor;
import MaterialNode.materialPointWidth;
import ModelNode.modelViewMatrix;
import PositionNode.positionGeometry;
import MathNode.smoothstep;
import ShaderNode.tslFn;
import ShaderNode.vec2;
import ShaderNode.vec4;
import UVNode.uv;
import ViewportNode.viewport;
import three.PointsMaterial;

class InstancedPointsNodeMaterial extends NodeMaterial {

    public var normals:Bool;
    public var lights:Bool;
    public var useAlphaToCoverage:Bool;
    public var useColor:Bool;
    public var pointWidth:Float;
    public var pointColorNode:Dynamic;

    public function new(params:Object = null) {
        super();

        this.normals = false;
        this.lights = false;
        this.useAlphaToCoverage = true;
        this.useColor = params != null ? params.vertexColors : false;
        this.pointWidth = 1;
        this.pointColorNode = null;

        this.setDefaultValues(new PointsMaterial());
        this.setupShaders();
        if (params != null) this.setValues(params);
    }

    public function setupShaders() {

        var useAlphaToCoverage = this.alphaToCoverage;
        var useColor = this.useColor;

        this.vertexNode = tslFn(() => {

            varying(vec2(), 'vUv').assign(uv());

            var instancePosition = attribute('instancePosition');
            var mvPos = property('vec4', 'mvPos');
            mvPos.assign(modelViewMatrix.mul(vec4(instancePosition, 1.0)));

            var aspect = viewport.z.div(viewport.w);
            var clipPos = cameraProjectionMatrix.mul(mvPos);

            var offset = property('vec2', 'offset');
            offset.assign(positionGeometry.xy);
            offset.assign(offset.mul(materialPointWidth));
            offset.assign(offset.div(viewport.z));
            offset.y.assign(offset.y.mul(aspect));

            offset.assign(offset.mul(clipPos.w));
            clipPos.assign(clipPos.add(vec4(offset, 0, 0)));

            return clipPos;
        })();

        this.fragmentNode = tslFn(() => {

            var vUv = varying(vec2(), 'vUv');

            var alpha = property('float', 'alpha');
            alpha.assign(1);

            var a = vUv.x;
            var b = vUv.y;

            var len2 = a.mul(a).add(b.mul(b));

            if (useAlphaToCoverage) {

                var dlen = property('float', 'dlen');
                dlen.assign(len2.fwidth());

                alpha.assign(smoothstep(dlen.oneMinus(), dlen.add(1), len2).oneMinus());

            } else {

                len2.greaterThan(1.0).discard();

            }

            var pointColorNode:Dynamic;

            if (this.pointColorNode != null) {

                pointColorNode = this.pointColorNode;

            } else {

                if (useColor) {

                    var instanceColor = attribute('instanceColor');
                    pointColorNode = instanceColor.mul(materialColor);

                } else {

                    pointColorNode = materialColor;

                }

            }

            return vec4(pointColorNode, alpha);
        })();

        this.needsUpdate = true;

    }

    public function get_alphaToCoverage():Bool {
        return this.useAlphaToCoverage;
    }

    public function set_alphaToCoverage(value:Bool) {
        if (this.useAlphaToCoverage != value) {
            this.useAlphaToCoverage = value;
            this.setupShaders();
        }
    }
}

addNodeMaterial('InstancedPointsNodeMaterial', InstancedPointsNodeMaterial);