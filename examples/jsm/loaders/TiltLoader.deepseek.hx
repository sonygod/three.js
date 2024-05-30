import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.DoubleSide;
import three.FileLoader;
import three.Group;
import three.Loader;
import three.Mesh;
import three.MeshBasicMaterial;
import three.RawShaderMaterial;
import three.TextureLoader;
import three.Quaternion;
import three.Vector3;
import fflate.unzipSync;
import fflate.strFromU8;

class TiltLoader extends Loader {

	public function new() {
		super();
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {

		var scope = this;

		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setResponseType('arraybuffer');
		loader.setWithCredentials(this.withCredentials);

		loader.load(url, function(buffer:ArrayBuffer) {

			try {

				onLoad(scope.parse(buffer));

			} catch (e:Dynamic) {

				if (onError != null) {

					onError(e);

				} else {

					trace(e);

				}

				scope.manager.itemError(url);

			}

		}, onProgress, onError);

	}

	public function parse(buffer:ArrayBuffer):Group {

		var group = new Group();

		var zip = unzipSync(new Uint8Array(buffer.slice(16)));

		var metadata = JSON.parse(strFromU8(zip['metadata.json']));

		var data = new DataView(zip['data.sketch'].buffer);

		var num_strokes = data.getInt32(16, true);

		var brushes = {};

		var offset = 20;

		for (var i = 0; i < num_strokes; i++) {

			var brush_index = data.getInt32(offset, true);

			var brush_color = [
				data.getFloat32(offset + 4, true),
				data.getFloat32(offset + 8, true),
				data.getFloat32(offset + 12, true),
				data.getFloat32(offset + 16, true)
			];
			var brush_size = data.getFloat32(offset + 20, true);
			var stroke_mask = data.getUint32(offset + 24, true);
			var controlpoint_mask = data.getUint32(offset + 28, true);

			var offset_stroke_mask = 0;
			var offset_controlpoint_mask = 0;

			for (var j = 0; j < 4; j++) {

				var byte = 1 << j;
				if ((stroke_mask & byte) > 0) offset_stroke_mask += 4;
				if ((controlpoint_mask & byte) > 0) offset_controlpoint_mask += 4;

			}

			offset = offset + 28 + offset_stroke_mask + 4;

			var num_control_points = data.getInt32(offset, true);

			var positions = new Float32Array(num_control_points * 3);
			var quaternions = new Float32Array(num_control_points * 4);

			offset = offset + 4;

			for (var j = 0, k = 0; j < positions.length; j += 3, k += 4) {

				positions[j + 0] = data.getFloat32(offset + 0, true);
				positions[j + 1] = data.getFloat32(offset + 4, true);
				positions[j + 2] = data.getFloat32(offset + 8, true);

				quaternions[k + 0] = data.getFloat32(offset + 12, true);
				quaternions[k + 1] = data.getFloat32(offset + 16, true);
				quaternions[k + 2] = data.getFloat32(offset + 20, true);
				quaternions[k + 3] = data.getFloat32(offset + 24, true);

				offset = offset + 28 + offset_controlpoint_mask;

			}

			if (brush_index in brushes === false) {

				brushes[brush_index] = [];

			}

			brushes[brush_index].push([positions, quaternions, brush_size, brush_color]);

		}

		for (var brush_index in brushes) {

			var geometry = new StrokeGeometry(brushes[brush_index]);
			var material = getMaterial(metadata.BrushIndex[brush_index]);

			group.add(new Mesh(geometry, material));

		}

		return group;

	}

}

class StrokeGeometry extends BufferGeometry {

	public function new(strokes:Array<Array<Dynamic>>) {

		super();

		var vertices = [];
		var colors = [];
		var uvs = [];

		var position = new Vector3();
		var prevPosition = new Vector3();

		var quaternion = new Quaternion();
		var prevQuaternion = new Quaternion();

		var vector1 = new Vector3();
		var vector2 = new Vector3();
		var vector3 = new Vector3();
		var vector4 = new Vector3();

		var color = new Color();

		for (var k in strokes) {

			var stroke = strokes[k];
			var positions = stroke[0];
			var quaternions = stroke[1];
			var size = stroke[2];
			var rgba = stroke[3];
			var alpha = stroke[3][3];

			color.fromArray(rgba).convertSRGBToLinear();

			prevPosition.fromArray(positions, 0);
			prevQuaternion.fromArray(quaternions, 0);

			for (var i = 3, j = 4, l = positions.length; i < l; i += 3, j += 4) {

				position.fromArray(positions, i);
				quaternion.fromArray(quaternions, j);

				vector1.set(-size, 0, 0);
				vector1.applyQuaternion(quaternion);
				vector1.add(position);

				vector2.set(size, 0, 0);
				vector2.applyQuaternion(quaternion);
				vector2.add(position);

				vector3.set(size, 0, 0);
				vector3.applyQuaternion(prevQuaternion);
				vector3.add(prevPosition);

				vector4.set(-size, 0, 0);
				vector4.applyQuaternion(prevQuaternion);
				vector4.add(prevPosition);

				vertices.push(vector1.x, vector1.y, -vector1.z);
				vertices.push(vector2.x, vector2.y, -vector2.z);
				vertices.push(vector4.x, vector4.y, -vector4.z);

				vertices.push(vector2.x, vector2.y, -vector2.z);
				vertices.push(vector3.x, vector3.y, -vector3.z);
				vertices.push(vector4.x, vector4.y, -vector4.z);

				prevPosition.copy(position);
				prevQuaternion.copy(quaternion);

				colors.push(color.r, color.g, color.b, alpha);
				colors.push(color.r, color.g, color.b, alpha);
				colors.push(color.r, color.g, color.b, alpha);

				colors.push(color.r, color.g, color.b, alpha);
				colors.push(color.r, color.g, color.b, alpha);
				colors.push(color.r, color.g, color.b, alpha);

				var p1 = i / l;
				var p2 = (i - 3) / l;

				uvs.push(p1, 0);
				uvs.push(p1, 1);
				uvs.push(p2, 0);

				uvs.push(p1, 1);
				uvs.push(p2, 1);
				uvs.push(p2, 0);

			}

		}

		this.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));
		this.setAttribute('color', new BufferAttribute(new Float32Array(colors), 4));
		this.setAttribute('uv', new BufferAttribute(new Float32Array(uvs), 2));

	}

}

var BRUSH_LIST_ARRAY = {
	'89d104cd-d012-426b-b5b3-bbaee63ac43c': 'Bubbles',
	// ...
};

var common = {

	'colors': {

		'BloomColor': `
			vec3 BloomColor(vec3 color, float gain) {
				// Guarantee that there's at least a little bit of all 3 channels.
				// This makes fully-saturated strokes (which only have 2 non-zero
				// color channels) eventually clip to white rather than to a secondary.
				float cmin = length(color.rgb) * .05;
				color.rgb = max(color.rgb, vec3(cmin, cmin, cmin));
				// If we try to remove this pow() from .a, it brightens up
				// pressure-sensitive strokes; looks better as-is.
				color = pow(color, vec3(2.2));
				color.rgb *= 2. * exp(gain * 10.);
				return color;
			}
		`,

		// ...

	}

};

var shaders = null;

function getShaders():Dynamic {

	if (shaders === null) {

		var loader = new TextureLoader().setPath('./textures/tiltbrush/');

		shaders = {
			'Light': {
				uniforms: {
					mainTex: { value: loader.load('Light.webp') },
					alphaTest: { value: 0.067 },
					emission_gain: { value: 0.45 },
					alpha: { value: 1 },
				},
				vertexShader: `
					precision highp float;
					precision highp int;

					attribute vec2 uv;
					attribute vec4 color;
					attribute vec3 position;

					uniform mat4 modelMatrix;
					uniform mat4 modelViewMatrix;
					uniform mat4 projectionMatrix;
					uniform mat4 viewMatrix;
					uniform mat3 normalMatrix;
					uniform vec3 cameraPosition;

					varying vec2 vUv;
					varying vec3 vColor;

					${common.colors.LinearToSrgb}
					${common.colors.hsv}

					void main() {

						vUv = uv;

						vColor = lookup(color.rgb);

						vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);

						gl_Position = projectionMatrix * mvPosition;

					}
				`,
				fragmentShader: `
					precision highp float;
					precision highp int;

					uniform float emission_gain;

					uniform sampler2D mainTex;
					uniform float alphaTest;

					varying vec2 vUv;
					varying vec3 vColor;

					${common.colors.BloomColor}
					${common.colors.SrgbToLinear}

					void main(){
						vec4 col = texture2D(mainTex, vUv);
						vec3 color = vColor;
						color = BloomColor(color, emission_gain);
						color = color * col.rgb;
						color = color * col.a;
						color = SrgbToLinear(color);
						gl_FragColor = vec4(color, 1.0);
					}
				`,
				side: 2,
				transparent: true,
				depthFunc: 2,
				depthWrite: true,
				depthTest: false,
				blending: 5,
				blendDst: 201,
				blendDstAlpha: 201,
				blendEquation: 100,
				blendEquationAlpha: 100,
				blendSrc: 201,
				blendSrcAlpha: 201,
			}

		};

	}

	return shaders;

}

function getMaterial(GUID:String):Dynamic {

	var name = BRUSH_LIST_ARRAY[GUID];

	switch (name) {

		case 'Light':
			return new RawShaderMaterial(getShaders().Light);

		default:
			return new MeshBasicMaterial({ vertexColors: true, side: DoubleSide });

	}

}

typedef TiltLoaderLoader = {

	function new():Void,
	function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void,
	function parse(buffer:ArrayBuffer):Group

}

extern class TiltLoader extends Loader {

	public function new():Void;
	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void;
	public function parse(buffer:ArrayBuffer):Group;

}