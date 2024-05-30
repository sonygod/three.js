import NodeMaterial from './NodeMaterial';
import { VaryingNode, varying } from '../core/VaryingNode';
import { PropertyNode, property } from '../core/PropertyNode';
import { AttributeNode, attribute } from '../core/AttributeNode';
import { CameraNode, cameraProjectionMatrix } from '../accessors/CameraNode';
import { MaterialNode, materialColor, materialPointWidth } from '../accessors/MaterialNode';
import { ModelNode, modelViewMatrix } from '../accessors/ModelNode';
import { PositionNode, positionGeometry } from '../accessors/PositionNode';
import { MathNode, smoothstep } from '../math/MathNode';
import { ShaderNode, tslFn, vec2, vec4 } from '../shadernode/ShaderNode';
import { UVNode, uv } from '../accessors/UVNode';
import { ViewportNode, viewport } from '../display/ViewportNode';

import { PointsMaterial } from 'three';

class InstancedPointsNodeMaterial extends NodeMaterial {
    public normals: Bool;
    public lights: Bool;
    public useAlphaToCoverage: Bool;
    public useColor: Bool;
    public pointWidth: Float;
    public pointColorNode: Node;

    public function new(params: { vertexColors: Bool } = { vertexColors: false }) {
        super();
        this.normals = false;
        this.lights = false;
        this.useAlphaToCoverage = true;
        this.useColor = params.vertexColors;
        this.pointWidth = 1.0;
        this.pointColorNode = null;
        this.setDefaultValues(cast PointsMaterial.defaultValues);
        this.setupShaders();
        this.setValues(params);
    }

    public function setupShaders() {
        var useAlphaToCoverage = this.useAlphaToCoverage;
        var useColor = this.useColor;

        this.vertexNode = tslFn(function() {
            var vUv = varying(cast vec2(), 'vUv');
            vUv.assign(uv());

            var instancePosition = attribute('instancePosition');
            var mvPos = property(cast vec4(), 'mvPos');
            mvPos.assign(modelViewMatrix.mul(vec4(instancePosition, 1.0)));

            var aspect = viewport.z.div(viewport.w);
            var clipPos = cameraProjectionMatrix.mul(mvPos);
            var offset = property(cast vec2(), 'offset');
            offset.assign(positionGeometry.xy);
            offset.assign(offset.mul(materialPointWidth));
            offset.assign(offset.div(viewport.z));
            offset.y.assign(offset.y.mul(aspect));
            offset.assign(offset.mul(clipPos.w));
            clipPos.assign(clipPos.add(vec4(offset, 0.0, 0.0)));

            return clipPos;
        });

        this.fragmentNode = tslFn(function() {
            var vUv = varying(cast vec2(), 'vUv');
            var alpha = property(Float, 'alpha');
            alpha.assign(1.0);

            var a = vUv.x;
            var b = vUv.y;
            var len2 = a.mul(a).add(b.mul(b));

            if (useAlphaToCoverage) {
                var dlen = property(Float, 'dlen');
                dlen.assign(len2.fwidth());
                alpha.assign(smoothstep(dlen.oneMinus(), dlen.add(1.0), len2).oneMinus());
            } else {
                len2.greaterThan(1.0).discard();
            }

            var pointColorNode: Node;
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
        });

        this.needsUpdate = true;
    }

    public function get_alphaToCoverage(): Bool {
        return this.useAlphaToCoverage;
    }

    public function set_alphaToCoverage(value: Bool) {
        if (this.useAlphaToCoverage != value) {
            this.useAlphaToCoverage = value;
            this.setupShaders();
        }
    }
}

class Point {
    public x: Float;
    public y: Float;

    public function new(x: Float, y: Float) {
        this.x = x;
        this.y = y;
    }
}