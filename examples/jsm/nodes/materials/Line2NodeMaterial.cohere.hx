import NodeMaterial, { addNodeMaterial } from './NodeMaterial.hx';
import { temp, varyingProperty, property, attribute, cameraProjectionMatrix, materialColor, materialLineScale, materialLineDashSize, materialLineGapSize, materialLineDashOffset, materialLineWidth } from '../core/Nodes.hx';
import { modelViewMatrix, positionGeometry, uv, viewport } from '../accessors/Nodes.hx';
import { mix, smoothstep } from '../math/MathNode.hx';
import { tslFn, float, vec2, vec3, vec4, If } from '../shadernode/ShaderNode.hx';
import { dashSize, gapSize } from '../core/PropertyNode.hx';

import { LineDashedMaterial } from 'three';

const defaultValues = new LineDashedMaterial();

class Line2NodeMaterial extends NodeMaterial {
    public normals: Bool;
    public lights: Bool;
    public useAlphaToCoverage: Bool;
    public useColor: Bool;
    public useDash: Bool;
    public useWorldUnits: Bool;
    public dashOffset: Float;
    public lineWidth: Float;
    public lineColorNode: Float;
    public offsetNode: Float;
    public dashScaleNode: Float;
    public dashSizeNode: Float;
    public gapSizeNode: Float;

    public function new(params: { ?vertexColors: Bool, ?dashed: Bool } = { null, null }) {
        super();

        normals = false;
        lights = false;

        setDefaultValues(defaultValues);

        useAlphaToCoverage = true;
        useColor = params.vertexColors ?? false;
        useDash = params.dashed ?? false;
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

    public function setup(builder: Builder) {
        setupShaders();
        super.setup(builder);
    }

    public function setupShaders() {
        const useAlphaToCoverage = this.alphaToCoverage;
        const useColor = this.useColor;
        const useDash = this.dashed;
        const useWorldUnits = this.worldUnits;

        const trimSegment = tslFn({ start, end }: { start: Vec4, end: Vec4 }) -> Vec4 {
            const a = cameraProjectionMatrix.element(2).element(2); // 3nd entry in 3th column
            const b = cameraProjectionMatrix.element(3).element(2); // 3nd entry in 4th column
            const nearEstimate = b * -0.5 / a;

            const alpha = (nearEstimate - start.z) / (end.z - start.z);

            return vec4(mix(start.xyz, end.xyz, alpha), end.w);
        };

        vertexNode = tslFn() -> {
            varyingProperty('vec2', 'vUv').assign(uv());

            const instanceStart = attribute('instanceStart');
            const instanceEnd = attribute('instanceEnd');

            // camera space
            const start = property('vec4', 'start');
            const end = property('vec4', 'end');

            start.assign(modelViewMatrix * vec4(instanceStart, 1.0)); // force assignment into correct place in flow
            end.assign(modelViewMatrix * vec4(instanceEnd, 1.0));

            if (useWorldUnits) {
                varyingProperty('vec3', 'worldStart').assign(start.xyz);
                varyingProperty('vec3', 'worldEnd').assign(end.xyz);
            }

            const aspect = viewport.z / viewport.w;

            // special case for perspective projection, and segments that terminate either in, or behind, the camera plane
            // clearly the gpu firmware has a way of addressing this issue when projecting into ndc space
            // but we need to perform ndc-space calculations in the shader, so we must address this issue directly
            // perhaps there is a more elegant solution -- WestLangley
            const perspective = cameraProjectionMatrix.element(2).element(3) == -1.0; // 4th entry in the 3rd column

            If(perspective, () -> {
                If(start.z < 0.0 && end.z > 0.0, () -> {
                    end.assign(trimSegment({ start: start, end: end }));
                }).elseif(end.z < 0.0 && start.z >= 0.0, () -> {
                    start.assign(trimSegment({ start: end, end: start }));
                });
            });

            // clip space
            const clipStart = cameraProjectionMatrix * start;
            const clipEnd = cameraProjectionMatrix * end;

            // ndc space
            const ndcStart = clipStart.xyz / clipStart.w;
            const ndcEnd = clipEnd.xyz / clipEnd.w;

            // direction
            const dir = ndcEnd.xy - ndcStart.xy;

            // account for clip-space aspect ratio
            dir.x = dir.x * aspect;
            dir = dir.normalize();

            const clip = temp(vec4());

            if (useWorldUnits) {
                // get the offset direction as perpendicular to the view vector
                const worldDir = end.xyz - start.xyz;
                const tmpFwd = mix(start.xyz, end.xyz, 0.5);
                const worldUp = worldDir.cross(tmpFwd);
                const worldFwd = worldDir.cross(worldUp);

                const worldPos = varyingProperty('vec4', 'worldPos');

                worldPos.assign(positionGeometry.y < 0.5 ? start : end);

                // height offset
                const hw = materialLineWidth * 0.5;
                worldPos += vec4(positionGeometry.x < 0.0 ? worldUp * hw : worldUp * -hw, 0);

                // don't extend the line if we're rendering dashes because we
                // won't be rendering the endcaps
                if (!useDash) {
                    // cap extension
                    worldPos += vec4(positionGeometry.y < 0.5 ? worldDir * -hw : worldDir * hw, 0);

                    // add width to the box
                    worldPos += vec4(worldFwd * hw, 0);

                    // endcaps
                    If(positionGeometry.y > 1.0 || positionGeometry.y < 0.0, () -> {
                        worldPos -= vec4(worldFwd * 2.0 * hw, 0);
                    });
                }

                // project the worldpos
                clip.assign(cameraProjectionMatrix * worldPos);

                // shift the depth of the projected points so the line
                // segments overlap neatly
                const clipPose = temp(vec3());

                clipPose.assign(positionGeometry.y < 0.5 ? ndcStart : ndcEnd);
                clip.z = clipPose.z * clip.w;
            } else {
                const offset = property('vec2', 'offset');

                offset.assign(vec2(dir.y, -dir.x));

                // undo aspect ratio adjustment
                dir.x = dir.x / aspect;
                offset.x = offset.x / aspect;

                // sign flip
                offset = positionGeometry.x < 0.0 ? -offset : offset;

                // endcaps
                If(positionGeometry.y < 0.0, () -> {
                    offset.assign(offset - dir);
                }).elseif(positionGeometry.y > 1.0, () -> {
                    offset.assign(offset + dir);
                });

                // adjust for linewidth
                offset.assign(offset * materialLineWidth);

                // adjust for clip-space to screen-space conversion // maybe resolution should be based on viewport ...
                offset.assign(offset / viewport.w);

                // select end
                clip.assign(positionGeometry.y < 0.5 ? clipStart : clipEnd);

                // back to clip space
                offset.assign(offset * clip.w);

                clip.assign(clip + vec4(offset, 0, 0));
            }

            return clip;
        }();

        const closestLineToLine = tslFn({ p1, p2, p3, p4 }: { p1: Vec3, p2: Vec3, p3: Vec3, p4: Vec3 }) -> Vec2 {
            const p13 = p1 - p3;
            const p43 = p4 - p3;

            const p21 = p2 - p1;

            const d1343 = p13.dot(p43);
            const d4321 = p43.dot(p21);
            const d1321 = p13.dot(p21);
            const d4343 = p43.dot(p43);
            const d2121 = p21.dot(p21);

            const denom = d2121 * d4343 - d4321 * d4321;
            const numer = d1343 * d4321 - d1321 * d4343;

            const mua = numer / denom;
            const mub = (d1343 + d4321 * mua) / d4343;

            return vec2(mua, mub);
        };

        fragmentNode = tslFn() -> {
            const vUv = varyingProperty('vec2', 'vUv');

            if (useDash) {
                const offsetNode = this.offsetNode ?? materialLineDashOffset;
                const dashScaleNode = this.dashScaleNode ?? materialLineScale;
                const dashSizeNode = this.dashSizeNode ?? materialLineDashSize;
                const gapSizeNode = this.dashSizeNode ?? materialLineGapSize;

                dashSize.assign(dashSizeNode);
                gapSize.assign(gapSizeNode);

                const instanceDistanceStart = attribute('instanceDistanceStart');
                const instanceDistanceEnd = attribute('instanceDistanceEnd');

                const lineDistance = positionGeometry.y < 0.5 ? dashScaleNode * instanceDistanceStart : materialLineScale * instanceDistanceEnd;

                const vLineDistance = varying(lineDistance + materialLineDashOffset);
                const vLineDistanceOffset = offsetNode != null ? vLineDistance + offsetNode : vLineDistance;

                if (vUv.y < -1.0 || vUv.y > 1.0) discard(); // discard endcaps
                if (vLineDistanceOffset % (dashSize + gapSize) > dashSize) discard(); // todo - FIX

            }

            // force assignment into correct place in flow
            const alpha = property('float', 'alpha');
            alpha.assign(1);

            if (useWorldUnits) {
                const worldStart = varyingProperty('vec3', 'worldStart');
                const worldEnd = varyingProperty('vec3', 'worldEnd');

                // Find the closest points on the view ray and the line segment
                const rayEnd = varyingProperty('vec4', 'worldPos').xyz;
                const lineDir = worldEnd - worldStart;
                const params = closestLineToLine({ p1: worldStart, p2: worldEnd, p3: vec3(0.0, 0.0, 0.0), p4: rayEnd });

                const p1 = worldStart + lineDir * params.x;
                const p2 = rayEnd * params.y;
                const delta = p1 - p2;
                const len = delta.length();
                const norm = len / materialLineWidth;

                if (!useDash) {
                    if (useAlphaToCoverage) {
                        const dnorm = norm.fwidth();
                        alpha.assign(smoothstep(-0.5 + dnorm, 0.5 + dnorm, norm).oneMinus());
                    } else {
                        if (norm > 0.5) discard();
                    }
                }

            } else {
                // round endcaps
                if (useAlphaToCoverage) {
                    const a = vUv.x;
                    const b = vUv.y > 0.0 ? vUv.y - 1.0 : vUv.y + 1.0;

                    const len2 = a * a + b * b;

                    // force assignment out of following 'if' statement - to avoid uniform control flow errors
                    const dlen = property('float', 'dlen');
                    dlen.assign(len2.fwidth());

                    If(abs(vUv.y) > 1.0, () -> {
                        alpha.assign(smoothstep(1 - dlen, 1 + dlen, len2).oneMinus());
                    });
                } else {
                    If(abs(vUv.y) > 1.0, () -> {
                        const a = vUv.x;
                        const b = vUv.y > 0.0 ? vUv.y - 1.0 : vUv.y + 1.0;
                        const len2 = a * a + b * b;

                        if (len2 > 1.0) discard();
                    });
                }
            }

            var lineColorNode: Float;

            if (this.lineColorNode != null) {
                lineColorNode = this.lineColorNode;
            } else {
                if (useColor) {
                    const instanceColorStart = attribute('instanceColorStart');
                    const instanceColorEnd = attribute('instanceColorEnd');

                    const instanceColor = positionGeometry.y < 0.5 ? instanceColorStart : instanceColorEnd;

                    lineColorNode = instanceColor * materialColor;
                } else {
                    lineColorNode = materialColor;
                }
            }

            return vec4(lineColorNode, alpha);
        }();
    }

    public function get worldUnits(): Bool {
        return useWorldUnits;
    }

    public function set worldUnits(value: Bool) {
        if (useWorldUnits != value) {
            useWorldUnits = value;
            needsUpdate = true;
        }
    }

    public function get dashed(): Bool {
        return useDash;
    }

    public function set dashed(value: Bool) {
        if (useDash != value) {
            useDash = value;
            needsUpdate = true;
        }
    }

    public function get alphaToCoverage(): Bool {
        return useAlphaToCoverage;
    }

    public function set alphaToCoverage(value: Bool) {
        if (useAlphaToCoverage != value) {
            useAlphaToCoverage = value;
            needsUpdate = true;
        }
    }
}

export default Line2NodeMaterial;

addNodeMaterial('Line2NodeMaterial', Line2NodeMaterial);