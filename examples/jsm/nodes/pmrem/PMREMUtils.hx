package three.js.examples.jsm.nodes.pmrem;

import haxe.ds.Vector;
import haxe.ds.StringMap;

class PMREMUtils {
	// constants
	static var CUBE_UV_R0:Float = 1.0;
	static var CUBE_UV_M0:Float = -2.0;
	static var CUBE_UV_R1:Float = 0.8;
	static var CUBE_UV_M1:Float = -1.0;
	static var CUBE_UV_R4:Float = 0.4;
	static var CUBE_UV_M4:Float = 2.0;
	static var CUBE_UV_R5:Float = 0.305;
	static var CUBE_UV_M5:Float = 3.0;
	static var CUBE_UV_R6:Float = 0.21;
	static var CUBE_UV_M6:Float = 4.0;

	static var CUBE_UV_MIN_MIP_LEVEL:Float = 4.0;
	static var CUBE_UV_MIN_TILE_SIZE:Float = 16.0;

	// shader functions
	static var getFace:TslFn = tslFn([direction], function() {
		var absDirection:Vector<Float> = new Vector<Float>([Math.abs(direction.x), Math.abs(direction.y), Math.abs(direction.z)]);
		var face:Float = -1.0;

		if (absDirection.x > absDirection.z) {
			if (absDirection.x > absDirection.y) {
				face = direction.x > 0.0 ? 0.0 : 3.0;
			} else {
				face = direction.y > 0.0 ? 1.0 : 4.0;
			}
		} else {
			if (absDirection.z > absDirection.y) {
				face = direction.z > 0.0 ? 2.0 : 5.0;
			} else {
				face = direction.y > 0.0 ? 1.0 : 4.0;
			}
		}

		return face;
	}).setLayout({
		name: 'getFace',
		type: 'float',
		inputs: [
			{ name: 'direction', type: 'vec3' }
		]
	});

	static var getUV:TslFn = tslFn([direction, face], function() {
		var uv:Vector<Float> = new Vector<Float>([0.0, 0.0]);

		switch (face) {
			case 0.0:
				uv.x = direction.z;
				uv.y = direction.y;
				uv = uv.div(abs(direction.x));
			case 1.0:
				uv.x = direction.x;
				uv.y = direction.z;
				uv = uv.negate();
				uv.y = uv.y.negate();
				uv = uv.div(abs(direction.y));
			case 2.0:
				uv.x = direction.x;
				uv.y = direction.y;
				uv = uv.div(abs(direction.z));
			case 3.0:
				uv.x = direction.z;
				uv.y = direction.y;
				uv = uv.negate();
				uv.x = uv.x.negate();
				uv = uv.div(abs(direction.x));
			case 4.0:
				uv.x = direction.x;
				uv.y = direction.z;
				uv = uv.negate();
				uv.x = uv.x.negate();
				uv = uv.div(abs(direction.y));
			case 5.0:
				uv.x = direction.x;
				uv.y = direction.y;
				uv = uv.div(abs(direction.z));
		}

		uv = uv.mul(0.5).add(1.0);

		return uv;
	}).setLayout({
		name: 'getUV',
		type: 'vec2',
		inputs: [
			{ name: 'direction', type: 'vec3' },
			{ name: 'face', type: 'float' }
		]
	});

	static var roughnessToMip:TslFn = tslFn([roughness], function() {
		var mip:Float = 0.0;

		if (roughness >= CUBE_UV_R1) {
			mip = CUBE_UV_R0 - roughness;
			mip = mip * (CUBE_UV_M1 - CUBE_UV_M0) / (CUBE_UV_R0 - CUBE_UV_R1) + CUBE_UV_M0;
		} else if (roughness >= CUBE_UV_R4) {
			mip = CUBE_UV_R1 - roughness;
			mip = mip * (CUBE_UV_M4 - CUBE_UV_M1) / (CUBE_UV_R1 - CUBE_UV_R4) + CUBE_UV_M1;
		} else if (roughness >= CUBE_UV_R5) {
			mip = CUBE_UV_R4 - roughness;
			mip = mip * (CUBE_UV_M5 - CUBE_UV_M4) / (CUBE_UV_R4 - CUBE_UV_R5) + CUBE_UV_M4;
		} else if (roughness >= CUBE_UV_R6) {
			mip = CUBE_UV_R5 - roughness;
			mip = mip * (CUBE_UV_M6 - CUBE_UV_M5) / (CUBE_UV_R5 - CUBE_UV_R6) + CUBE_UV_M5;
		} else {
			mip = -2.0 * Math.log(1.16 * roughness) / Math.log(2.0);
		}

		return mip;
	}).setLayout({
		name: 'roughnessToMip',
		type: 'float',
		inputs: [
			{ name: 'roughness', type: 'float' }
		]
	});

	// ...
}