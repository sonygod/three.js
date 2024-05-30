package three.jsm.objects;

import three.AdditiveBlending;
import three.Box2;
import three.BufferGeometry;
import three.Color;
import three.FramebufferTexture;
import three.InterleavedBuffer;
import three.InterleavedBufferAttribute;
import three.Mesh;
import three.MeshBasicMaterial;
import three.RawShaderMaterial;
import three.UnsignedByteType;
import three.Vector2;
import three.Vector3;
import three.Vector4;
import three.Renderer;
import three.Camera;

class Lensflare extends Mesh {

	public function new() {

		super(Lensflare.Geometry, new MeshBasicMaterial({ opacity: 0, transparent: true }));

		this.isLensflare = true;

		this.type = 'Lensflare';
		this.frustumCulled = false;
		this.renderOrder = Infinity;

		var positionScreen = new Vector3();
		var positionView = new Vector3();

		var tempMap = new FramebufferTexture(16, 16);
		var occlusionMap = new FramebufferTexture(16, 16);

		var currentType = UnsignedByteType;

		var material1a = new RawShaderMaterial({
			uniforms: {
				'scale': { value: null },
				'screenPosition': { value: null }
			},
			vertexShader: /* glsl */`

				precision highp float;

				uniform vec3 screenPosition;
				uniform vec2 scale;

				attribute vec3 position;

				void main() {

					gl_Position = vec4( position.xy * scale + screenPosition.xy, screenPosition.z, 1.0 );

				}`,

			fragmentShader: /* glsl */`

				precision highp float;

				void main() {

					gl_FragColor = vec4( 1.0, 0.0, 1.0, 1.0 );

				}`,
			depthTest: true,
			depthWrite: false,
			transparent: false
		});

		var material1b = new RawShaderMaterial({
			uniforms: {
				'map': { value: tempMap },
				'scale': { value: null },
				'screenPosition': { value: null }
			},
			vertexShader: /* glsl */`

				precision highp float;

				uniform vec3 screenPosition;
				uniform vec2 scale;

				attribute vec3 position;
				attribute vec2 uv;

				varying vec2 vUV;

				void main() {

					vUV = uv;

					gl_Position = vec4( position.xy * scale + screenPosition.xy, screenPosition.z, 1.0 );

				}`,

			fragmentShader: /* glsl */`

				precision highp float;

				uniform sampler2D map;

				varying vec2 vUV;

				void main() {

					gl_FragColor = texture2D( map, vUV );

				}`,
			depthTest: false,
			depthWrite: false,
			transparent: false
		});

		var mesh1 = new Mesh(Lensflare.Geometry, material1a);

		var elements = [];

		var shader = LensflareElement.Shader;

		var material2 = new RawShaderMaterial({
			name: shader.name,
			uniforms: {
				'map': { value: null },
				'occlusionMap': { value: occlusionMap },
				'color': { value: new Color(0xffffff) },
				'scale': { value: new Vector2() },
				'screenPosition': { value: new Vector3() }
			},
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader,
			blending: AdditiveBlending,
			transparent: true,
			depthWrite: false
		});

		var mesh2 = new Mesh(Lensflare.Geometry, material2);

		this.addElement = function(element) {

			elements.push(element);

		};

		var scale = new Vector2();
		var screenPositionPixels = new Vector2();
		var validArea = new Box2();
		var viewport = new Vector4();

		this.onBeforeRender = function(renderer:Renderer, scene, camera:Camera) {

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

			positionView.setFromMatrixPosition(this.matrixWorld);
			positionView.applyMatrix4(camera.matrixWorldInverse);

			if (positionView.z > 0) return;

			positionScreen.copy(positionView).applyMatrix4(camera.projectionMatrix);

			screenPositionPixels.x = viewport.x + (positionScreen.x * halfViewportWidth) + halfViewportWidth - 8;
			screenPositionPixels.y = viewport.y + (positionScreen.y * halfViewportHeight) + halfViewportHeight - 8;

			if (validArea.containsPoint(screenPositionPixels)) {

				renderer.copyFramebufferToTexture(tempMap, screenPositionPixels);

				var uniforms = material1a.uniforms;
				uniforms['scale'].value = scale;
				uniforms['screenPosition'].value = positionScreen;

				renderer.renderBufferDirect(camera, null, Lensflare.Geometry, material1a, mesh1, null);

				renderer.copyFramebufferToTexture(occlusionMap, screenPositionPixels);

				uniforms = material1b.uniforms;
				uniforms['scale'].value = scale;
				uniforms['screenPosition'].value = positionScreen;

				renderer.renderBufferDirect(camera, null, Lensflare.Geometry, material1b, mesh1, null);

				var vecX = -positionScreen.x * 2;
				var vecY = -positionScreen.y * 2;

				for (i in 0...elements.length) {

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

					renderer.renderBufferDirect(camera, null, Lensflare.Geometry, material2, mesh2, null);

				}

			}

		};

		this.dispose = function() {

			material1a.dispose();
			material1b.dispose();
			material2.dispose();

			tempMap.dispose();
			occlusionMap.dispose();

			for (i in 0...elements.length) {

				elements[i].texture.dispose();

			}

		};

	}

}

class LensflareElement {

	public function new(texture, size:Float = 1, distance:Float = 0, color:Color = new Color(0xffffff)) {

		this.texture = texture;
		this.size = size;
		this.distance = distance;
		this.color = color;

	}

}

class LensflareElementShader {

	public static var Shader = {

		name: 'LensflareElementShader',

		uniforms: {

			'map': { value: null },
			'occlusionMap': { value: null },
			'color': { value: null },
			'scale': { value: null },
			'screenPosition': { value: null }

		},

		vertexShader: /* glsl */`

			precision highp float;

			uniform vec3 screenPosition;
			uniform vec2 scale;

			uniform sampler2D occlusionMap;

			attribute vec3 position;
			attribute vec2 uv;

			varying vec2 vUV;
			varying float vVisibility;

			void main() {

				vUV = uv;

				vec2 pos = position.xy;

				vec4 visibility = texture2D( occlusionMap, vec2( 0.1, 0.1 ) );
				visibility += texture2D( occlusionMap, vec2( 0.5, 0.1 ) );
				visibility += texture2D( occlusionMap, vec2( 0.9, 0.1 ) );
				visibility += texture2D( occlusionMap, vec2( 0.9, 0.5 ) );
				visibility += texture2D( occlusionMap, vec2( 0.9, 0.9 ) );
				visibility += texture2D( occlusionMap, vec2( 0.5, 0.9 ) );
				visibility += texture2D( occlusionMap, vec2( 0.1, 0.9 ) );
				visibility += texture2D( occlusionMap, vec2( 0.1, 0.5 ) );
				visibility += texture2D( occlusionMap, vec2( 0.5, 0.5 ) );

				vVisibility =        visibility.r / 9.0;
				vVisibility *= 1.0 - visibility.g / 9.0;
				vVisibility *=       visibility.b / 9.0;

				gl_Position = vec4( ( pos * scale + screenPosition.xy ).xy, screenPosition.z, 1.0 );

			}`,

		fragmentShader: /* glsl */`

			precision highp float;

			uniform sampler2D map;
			uniform vec3 color;

			varying vec2 vUV;
			varying float vVisibility;

			void main() {

				vec4 texture = texture2D( map, vUV );
				texture.a *= vVisibility;
				gl_FragColor = texture;
				gl_FragColor.rgb *= color;

			}`

	};

}

class LensflareGeometry {

	public static function get() {

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

	}

}