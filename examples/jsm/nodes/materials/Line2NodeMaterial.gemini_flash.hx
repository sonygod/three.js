import NodeMaterial from "./NodeMaterial";
import VarNode from "../core/VarNode";
import VaryingNode from "../core/VaryingNode";
import PropertyNode from "../core/PropertyNode";
import AttributeNode from "../core/AttributeNode";
import CameraNode from "../accessors/CameraNode";
import MaterialNode from "../accessors/MaterialNode";
import ModelNode from "../accessors/ModelNode";
import PositionNode from "../accessors/PositionNode";
import MathNode from "../math/MathNode";
import ShaderNode from "../shadernode/ShaderNode";
import UVNode from "../accessors/UVNode";
import ViewportNode from "../display/ViewportNode";
import {dashSize, gapSize} from "../core/PropertyNode";

import LineDashedMaterial from "three";

class Line2NodeMaterial extends NodeMaterial {

	public normals:Bool = false;
	public lights:Bool = false;
	public useAlphaToCoverage:Bool;
	public useColor:Bool;
	public useDash:Bool;
	public useWorldUnits:Bool;
	public dashOffset:Float;
	public lineWidth:Float;
	public lineColorNode:ShaderNode;
	public offsetNode:ShaderNode;
	public dashScaleNode:ShaderNode;
	public dashSizeNode:ShaderNode;
	public gapSizeNode:ShaderNode;

	public function new(?params:Dynamic = null) {
		super();

		this.setDefaultValues(cast LineDashedMaterial(new LineDashedMaterial()));

		this.useAlphaToCoverage = true;
		this.useColor = params.vertexColors;
		this.useDash = params.dashed;
		this.useWorldUnits = false;

		this.dashOffset = 0;
		this.lineWidth = 1;

		this.lineColorNode = null;

		this.offsetNode = null;
		this.dashScaleNode = null;
		this.dashSizeNode = null;
		this.gapSizeNode = null;

		this.setValues(params);
	}

	override public function setup(builder:Dynamic):Void {
		this.setupShaders();
		super.setup(builder);
	}

	public function setupShaders():Void {
		var useAlphaToCoverage = this.alphaToCoverage;
		var useColor = this.useColor;
		var useDash = this.dashed;
		var useWorldUnits = this.worldUnits;

		var trimSegment = ShaderNode.tslFn((start:ShaderNode, end:ShaderNode) -> ShaderNode {
			var a = CameraNode.cameraProjectionMatrix.element(2).element(2); // 3nd entry in 3th column
			var b = CameraNode.cameraProjectionMatrix.element(3).element(2); // 3nd entry in 4th column
			var nearEstimate = b.mul(-0.5).div(a);

			var alpha = nearEstimate.sub(start.z).div(end.z.sub(start.z));

			return ShaderNode.vec4(MathNode.mix(start.xyz, end.xyz, alpha), end.w);
		});

		this.vertexNode = ShaderNode.tslFn(() -> ShaderNode {
			VaryingNode.varyingProperty("vec2", "vUv").assign(UVNode.uv());

			var instanceStart = AttributeNode.attribute("instanceStart");
			var instanceEnd = AttributeNode.attribute("instanceEnd");

			// camera space

			var start = PropertyNode.property("vec4", "start");
			var end = PropertyNode.property("vec4", "end");

			start.assign(ModelNode.modelViewMatrix.mul(ShaderNode.vec4(instanceStart, 1.0))); // force assignment into correct place in flow
			end.assign(ModelNode.modelViewMatrix.mul(ShaderNode.vec4(instanceEnd, 1.0)));

			if (useWorldUnits) {
				VaryingNode.varyingProperty("vec3", "worldStart").assign(start.xyz);
				VaryingNode.varyingProperty("vec3", "worldEnd").assign(end.xyz);
			}

			var aspect = ViewportNode.viewport.z.div(ViewportNode.viewport.w);

			// special case for perspective projection, and segments that terminate either in, or behind, the camera plane
			// clearly the gpu firmware has a way of addressing this issue when projecting into ndc space
			// but we need to perform ndc-space calculations in the shader, so we must address this issue directly
			// perhaps there is a more elegant solution -- WestLangley

			var perspective = CameraNode.cameraProjectionMatrix.element(2).element(3).equal( - 1.0 ); // 4th entry in the 3rd column

			ShaderNode.If(perspective, () -> {
				ShaderNode.If(start.z.lessThan(0.0).and(end.z.greaterThan(0.0)), () -> {
					end.assign(trimSegment({start: start, end: end}));
				}).elseif(end.z.lessThan(0.0).and(start.z.greaterThanEqual(0.0)), () -> {
					start.assign(trimSegment({start: end, end: start}));
				});
			});

			// clip space
			var clipStart = CameraNode.cameraProjectionMatrix.mul(start);
			var clipEnd = CameraNode.cameraProjectionMatrix.mul(end);

			// ndc space
			var ndcStart = clipStart.xyz.div(clipStart.w);
			var ndcEnd = clipEnd.xyz.div(clipEnd.w);

			// direction
			var dir = ndcEnd.xy.sub(ndcStart.xy).temp();

			// account for clip-space aspect ratio
			dir.x.assign(dir.x.mul(aspect));
			dir.assign(dir.normalize());

			var clip = VarNode.temp(ShaderNode.vec4());

			if (useWorldUnits) {
				// get the offset direction as perpendicular to the view vector

				var worldDir = end.xyz.sub(start.xyz).normalize();
				var tmpFwd = MathNode.mix(start.xyz, end.xyz, 0.5).normalize();
				var worldUp = worldDir.cross(tmpFwd).normalize();
				var worldFwd = worldDir.cross(worldUp);

				var worldPos = VaryingNode.varyingProperty("vec4", "worldPos");

				worldPos.assign(PositionNode.positionGeometry.y.lessThan(0.5).cond(start, end));

				// height offset
				var hw = MaterialNode.materialLineWidth.mul(0.5);
				worldPos.addAssign(ShaderNode.vec4(PositionNode.positionGeometry.x.lessThan(0.0).cond(worldUp.mul(hw), worldUp.mul(hw).negate()), 0));

				// don't extend the line if we're rendering dashes because we
				// won't be rendering the endcaps
				if (!useDash) {
					// cap extension
					worldPos.addAssign(ShaderNode.vec4(PositionNode.positionGeometry.y.lessThan(0.5).cond(worldDir.mul(hw).negate(), worldDir.mul(hw)), 0));

					// add width to the box
					worldPos.addAssign(ShaderNode.vec4(worldFwd.mul(hw), 0));

					// endcaps
					ShaderNode.If(PositionNode.positionGeometry.y.greaterThan(1.0).or(PositionNode.positionGeometry.y.lessThan(0.0)), () -> {
						worldPos.subAssign(ShaderNode.vec4(worldFwd.mul(2.0).mul(hw), 0));
					});
				}

				// project the worldpos
				clip.assign(CameraNode.cameraProjectionMatrix.mul(worldPos));

				// shift the depth of the projected points so the line
				// segments overlap neatly
				var clipPose = VarNode.temp(ShaderNode.vec3());

				clipPose.assign(PositionNode.positionGeometry.y.lessThan(0.5).cond(ndcStart, ndcEnd));
				clip.z.assign(clipPose.z.mul(clip.w));

			} else {
				var offset = PropertyNode.property("vec2", "offset");

				offset.assign(ShaderNode.vec2(dir.y, dir.x.negate()));

				// undo aspect ratio adjustment
				dir.x.assign(dir.x.div(aspect));
				offset.x.assign(offset.x.div(aspect));

				// sign flip
				offset.assign(PositionNode.positionGeometry.x.lessThan(0.0).cond(offset.negate(), offset));

				// endcaps
				ShaderNode.If(PositionNode.positionGeometry.y.lessThan(0.0), () -> {
					offset.assign(offset.sub(dir));
				}).elseif(PositionNode.positionGeometry.y.greaterThan(1.0), () -> {
					offset.assign(offset.add(dir));
				});

				// adjust for linewidth
				offset.assign(offset.mul(MaterialNode.materialLineWidth));

				// adjust for clip-space to screen-space conversion // maybe resolution should be based on viewport ...
				offset.assign(offset.div(ViewportNode.viewport.w));

				// select end
				clip.assign(PositionNode.positionGeometry.y.lessThan(0.5).cond(clipStart, clipEnd));

				// back to clip space
				offset.assign(offset.mul(clip.w));

				clip.assign(clip.add(ShaderNode.vec4(offset, 0, 0)));
			}

			return clip;
		})();

		var closestLineToLine = ShaderNode.tslFn((p1:ShaderNode, p2:ShaderNode, p3:ShaderNode, p4:ShaderNode) -> ShaderNode {
			var p13 = p1.sub(p3);
			var p43 = p4.sub(p3);

			var p21 = p2.sub(p1);

			var d1343 = p13.dot(p43);
			var d4321 = p43.dot(p21);
			var d1321 = p13.dot(p21);
			var d4343 = p43.dot(p43);
			var d2121 = p21.dot(p21);

			var denom = d2121.mul(d4343).sub(d4321.mul(d4321));
			var numer = d1343.mul(d4321).sub(d1321.mul(d4343));

			var mua = numer.div(denom).clamp();
			var mub = d1343.add(d4321.mul(mua)).div(d4343).clamp();

			return ShaderNode.vec2(mua, mub);
		});

		this.fragmentNode = ShaderNode.tslFn(() -> ShaderNode {
			var vUv = VaryingNode.varyingProperty("vec2", "vUv");

			if (useDash) {
				var offsetNode = this.offsetNode != null ? ShaderNode.float(this.offsetNode) : MaterialNode.materialLineDashOffset;
				var dashScaleNode = this.dashScaleNode != null ? ShaderNode.float(this.dashScaleNode) : MaterialNode.materialLineScale;
				var dashSizeNode = this.dashSizeNode != null ? ShaderNode.float(this.dashSizeNode) : MaterialNode.materialLineDashSize;
				var gapSizeNode = this.dashSizeNode != null ? ShaderNode.float(this.dashGapNode) : MaterialNode.materialLineGapSize;

				dashSize.assign(dashSizeNode);
				gapSize.assign(gapSizeNode);

				var instanceDistanceStart = AttributeNode.attribute("instanceDistanceStart");
				var instanceDistanceEnd = AttributeNode.attribute("instanceDistanceEnd");

				var lineDistance = PositionNode.positionGeometry.y.lessThan(0.5).cond(dashScaleNode.mul(instanceDistanceStart), MaterialNode.materialLineScale.mul(instanceDistanceEnd));

				var vLineDistance = VaryingNode.varying(lineDistance.add(MaterialNode.materialLineDashOffset));
				var vLineDistanceOffset = offsetNode != null ? vLineDistance.add(offsetNode) : vLineDistance;

				vUv.y.lessThan(-1.0).or(vUv.y.greaterThan(1.0)).discard(); // discard endcaps
				vLineDistanceOffset.mod(dashSize.add(gapSize)).greaterThan(dashSize).discard(); // todo - FIX
			}

			// force assignment into correct place in flow
			var alpha = PropertyNode.property("float", "alpha");
			alpha.assign(1);

			if (useWorldUnits) {
				var worldStart = VaryingNode.varyingProperty("vec3", "worldStart");
				var worldEnd = VaryingNode.varyingProperty("vec3", "worldEnd");

				// Find the closest points on the view ray and the line segment
				var rayEnd = VaryingNode.varyingProperty("vec4", "worldPos").xyz.normalize().mul(1e5);
				var lineDir = worldEnd.sub(worldStart);
				var params = closestLineToLine({p1: worldStart, p2: worldEnd, p3: ShaderNode.vec3(0.0, 0.0, 0.0), p4: rayEnd});

				var p1 = worldStart.add(lineDir.mul(params.x));
				var p2 = rayEnd.mul(params.y);
				var delta = p1.sub(p2);
				var len = delta.length();
				var norm = len.div(MaterialNode.materialLineWidth);

				if (!useDash) {
					if (useAlphaToCoverage) {
						var dnorm = norm.fwidth();
						alpha.assign(MathNode.smoothstep(dnorm.negate().add(0.5), dnorm.add(0.5), norm).oneMinus());
					} else {
						norm.greaterThan(0.5).discard();
					}
				}
			} else {
				// round endcaps

				if (useAlphaToCoverage) {
					var a = vUv.x;
					var b = vUv.y.greaterThan(0.0).cond(vUv.y.sub(1.0), vUv.y.add(1.0));

					var len2 = a.mul(a).add(b.mul(b));

					// force assignment out of following 'if' statement - to avoid uniform control flow errors
					var dlen = PropertyNode.property("float", "dlen");
					dlen.assign(len2.fwidth());

					ShaderNode.If(vUv.y.abs().greaterThan(1.0), () -> {
						alpha.assign(MathNode.smoothstep(dlen.oneMinus(), dlen.add(1), len2).oneMinus());
					});
				} else {
					ShaderNode.If(vUv.y.abs().greaterThan(1.0), () -> {
						var a = vUv.x;
						var b = vUv.y.greaterThan(0.0).cond(vUv.y.sub(1.0), vUv.y.add(1.0));
						var len2 = a.mul(a).add(b.mul(b));

						len2.greaterThan(1.0).discard();
					});
				}
			}

			var lineColorNode:ShaderNode;

			if (this.lineColorNode != null) {
				lineColorNode = this.lineColorNode;
			} else {
				if (useColor) {
					var instanceColorStart = AttributeNode.attribute("instanceColorStart");
					var instanceColorEnd = AttributeNode.attribute("instanceColorEnd");

					var instanceColor = PositionNode.positionGeometry.y.lessThan(0.5).cond(instanceColorStart, instanceColorEnd);

					lineColorNode = instanceColor.mul(MaterialNode.materialColor);
				} else {
					lineColorNode = MaterialNode.materialColor;
				}
			}

			return ShaderNode.vec4(lineColorNode, alpha);
		})();
	}

	public function get worldUnits():Bool {
		return this.useWorldUnits;
	}

	public function set worldUnits(value:Bool) {
		if (this.useWorldUnits != value) {
			this.useWorldUnits = value;
			this.needsUpdate = true;
		}
	}

	public function get dashed():Bool {
		return this.useDash;
	}

	public function set dashed(value:Bool) {
		if (this.useDash != value) {
			this.useDash = value;
			this.needsUpdate = true;
		}
	}

	public function get alphaToCoverage():Bool {
		return this.useAlphaToCoverage;
	}

	public function set alphaToCoverage(value:Bool) {
		if (this.useAlphaToCoverage != value) {
			this.useAlphaToCoverage = value;
			this.needsUpdate = true;
		}
	}
}

export default Line2NodeMaterial;