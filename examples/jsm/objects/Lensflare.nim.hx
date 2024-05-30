import three.js.examples.jsm.objects.Lensflare;
import three.js.examples.jsm.objects.LensflareElement;
import three.js.examples.jsm.shaders.LensflareElementShader;
import three.js.examples.jsm.shaders.RawShaderMaterial;
import three.js.examples.jsm.shaders.ShaderMaterial;
import three.js.examples.jsm.shaders.UniformsUtils;
import three.js.examples.jsm.utils.FramebufferTexture;
import three.js.examples.jsm.utils.InterleavedBuffer;
import three.js.examples.jsm.utils.InterleavedBufferAttribute;
import three.js.examples.jsm.utils.Mesh;
import three.js.examples.jsm.utils.MeshBasicMaterial;
import three.js.examples.jsm.utils.RawShaderMaterial;
import three.js.examples.jsm.utils.UnsignedByteType;
import three.js.examples.jsm.utils.Vector2;
import three.js.examples.jsm.utils.Vector3;
import three.js.examples.jsm.utils.Vector4;

class Lensflare extends Mesh {

	public function new() {

		super(Lensflare.Geometry, new MeshBasicMaterial({ opacity: 0, transparent: true }));

		this.isLensflare = true;

		this.type = 'Lensflare';
		this.frustumCulled = false;
		this.renderOrder = Infinity;

		//

		var positionScreen = new Vector3();
		var positionView = new Vector3();

		// textures

		var tempMap = new FramebufferTexture(16, 16);
		var occlusionMap = new FramebufferTexture(16, 16);

		var currentType = UnsignedByteType;

		// material

		var geometry = Lensflare.Geometry;

		var material1a = new RawShaderMaterial({
			uniforms: UniformsUtils.merge([
				RawShaderMaterial.uniforms,
				{
					'scale': { value: null },
					'screenPosition': { value: null }
				}
			]),
			vertexShader: /* glsl */`

				precision highp float;

				uniform vec3 screenPosition;
				uniform vec2 scale;

				attribute vec3 position;

				void main() {

					gl_Position = vec4(position.xy * scale + screenPosition.xy, screenPosition.z, 1.0);

				}`,

			fragmentShader: /* glsl */`

				precision highp float;

				void main() {

					gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);

				}`,
			depthTest: true,
			depthWrite: false,
			transparent: false
		});

		var material1b = new RawShaderMaterial({
			uniforms: UniformsUtils.merge([
				RawShaderMaterial.uniforms,
				{
					'map': { value: tempMap },
					'scale': { value: null },
					'screenPosition': { value: null }
				}
			]),
			vertexShader: /* glsl */`

				precision highp float;

				uniform vec3 screenPosition;
				uniform vec2 scale;

				attribute vec3 position;
				attribute vec2 uv;

				varying vec2 vUV;

				void main() {

					vUV = uv;

					gl_Position = vec4(position.xy * scale + screenPosition.xy, screenPosition.z, 1.0);

				}`,

			fragmentShader: /* glsl */`

				precision highp float;

				uniform sampler2D map;

				varying vec2 vUV;

				void main() {

					gl_FragColor = texture2D(map, vUV);

				}`,
			depthTest: false,
			depthWrite: false,
			transparent: false
		});

		// the following object is used for occlusionMap generation

		var mesh1 = new Mesh(geometry, material1a);

		//

		var elements = [];

		var shader = LensflareElementShader;

		var material2 = new ShaderMaterial({
			name: shader.name,
			uniforms: UniformsUtils.merge([
				ShaderMaterial.uniforms,
				{
					'map': { value: null },
					'occlusionMap': { value: occlusionMap },
					'color': { value: new Color(0xffffff) },
					'scale': { value: new Vector2() },
					'screenPosition': { value: new Vector3() }
				}
			]),
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader,
			blending: AdditiveBlending,
			transparent: true,
			depthWrite: false
		});

		var mesh2 = new Mesh(geometry, material2);

		this.addElement = function(element) {

			elements.push(element);

		};

		//

		var scale = new Vector2();
		var screenPositionPixels = new Vector2();
		var validArea = new Box2();
		var viewport = new Vector4();

		this.onBeforeRender = function(renderer, scene, camera) {

			renderer.getCurrentViewport(viewport);

			var renderTarget = renderer.getRenderTarget();
			var type = (renderTarget !== null) ? renderTarget.texture.type : UnsignedByteType;

			if (currentType !== type) {

				tempMap.dispose();
				occlusionMap.dispose();

				tempMap.type = occlusionMap.type = type;

				currentType = type;

			}

			var invAspect = viewport.w / viewport.z;
			var halfViewportWidth = viewport.z / 2.0;
			var halfViewportHeight = viewport.w / 2.0;

			var size = 16 / viewport.w;
			scale.set(size * invAspect, size);

			validArea.min.set(viewport.x, viewport.y);
			validArea.max.set(viewport.x + (viewport.z - 16), viewport.y + (viewport.w - 16));

			// calculate position in screen space

			positionView.setFromMatrixPosition(this.matrixWorld);
			positionView.applyMatrix4(camera.matrixWorldInverse);

			if (positionView.z > 0) return; // lensflare is behind the camera

			positionScreen.copy(positionView).applyMatrix4(camera.projectionMatrix);

			// horizontal and vertical coordinate of the lower left corner of the pixels to copy

			screenPositionPixels.x = viewport.x + (positionScreen.x * halfViewportWidth) + halfViewportWidth - 8;
			screenPositionPixels.y = viewport.y + (positionScreen.y * halfViewportHeight) + halfViewportHeight - 8;

			// screen cull

			if (validArea.containsPoint(screenPositionPixels)) {

				// save current RGB to temp texture

				renderer.copyFramebufferToTexture(tempMap, screenPositionPixels);

				// render pink quad

				var uniforms = material1a.uniforms;
				uniforms['scale'].value = scale;
				uniforms['screenPosition'].value = positionScreen;

				renderer.renderBufferDirect(camera, null, geometry, material1a, mesh1, null);

				// copy result to occlusionMap

				renderer.copyFramebufferToTexture(occlusionMap, screenPositionPixels);

				// restore graphics

				uniforms = material1b.uniforms;
				uniforms['scale'].value = scale;
				uniforms['screenPosition'].value = positionScreen;

				renderer.renderBufferDirect(camera, null, geometry, material1b, mesh1, null);

				// render elements

				var vecX = -positionScreen.x * 2;
				var vecY = -positionScreen.y * 2;

				for (var i = 0, l = elements.length; i < l; i++) {

					var element = elements[i];

					var uniforms = material2.uniforms;

					uniforms['color'].value.copy(element.color);
					uniforms['map'].value = element.texture;
					uniforms['screenPosition'].value.x = positionScreen.x + vecX * element.distance;
					uniforms['screenPosition'].value.y = positionScreen.y + vecY * element.distance;

					size = element.size / viewport.w;
					var invAspect = viewport.w / viewport.z;

					uniforms['scale'].value.set(size * invAspect, size);

					material2.uniformsNeedUpdate = true;

					renderer.renderBufferDirect(camera, null, geometry, material2, mesh2, null);

				}

			}

		};

		this.dispose = function() {

			material1a.dispose();
			material1b.dispose();
			material2.dispose();

			tempMap.dispose();
			occlusionMap.dispose();

			for (var i = 0, l = elements.length; i < l; i++) {

				elements[i].texture.dispose();

			}

		};

	}

}

//

class LensflareElement {

	public function new(texture, size = 1, distance = 0, color = new Color(0xffffff)) {

		this.texture = texture;
		this.size = size;
		this.distance = distance;
		this.color = color;

	}

}

LensflareElement.Shader = LensflareElementShader;

Lensflare.Geometry = (function() {

	var geometry = new BufferGeometry();

	var float32Array = new Float32Array([
		-1, -1, 0, 0, 0,
		1, -1, 0, 1, 0,
		1, 1, 0, 1, 1,
		-1, 1, 0, 0, 1
	]);

	var interleavedBuffer = new InterleavedBuffer(float32Array, 5);

	geometry.setIndex([0, 1, 2, 0, 2, 3]);
	geometry.setAttribute('position', new InterleavedBufferAttribute(interleavedBuffer, 3, 0, false));
	geometry.setAttribute('uv', new InterleavedBufferAttribute(interleavedBuffer, 2, 3, false));

	return geometry;

})();

export { Lensflare, LensflareElement };