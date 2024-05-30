package three.examples.jsm.geometries;

import three.BufferAttribute;
import three.BufferGeometry;
import three.FloatType;
import three.Mesh;
import three.OrthographicCamera;
import three.PlaneGeometry;
import three.Scene;
import three.ShaderMaterial;
import three.Vector2;
import three.WebGLRenderTarget;
import three.examples.jsm.libs.surfaceNet;

class SDFGeometryGenerator {

	var renderer:Dynamic;

	public function new(renderer:Dynamic) {
		this.renderer = renderer;
	}

	public function generate(res:Int = 64, distFunc:String = 'float dist( vec3 p ){ return length(p) - 0.5; }', bounds:Float = 1.0):BufferGeometry {

		var w:Float;
		var h:Float;
		if (res == 8) [w, h] = [32, 16];
		else if (res == 16) [w, h] = [64, 64];
		else if (res == 32) [w, h] = [256, 128];
		else if (res == 64) [w, h] = [512, 512];
		else if (res == 128) [w, h] = [2048, 1024];
		else if (res == 256) [w, h] = [4096, 4096];
		else if (res == 512) [w, h] = [16384, 8096];
		else if (res == 1024) [w, h] = [32768, 32768];
		else throw 'THREE.SDFGeometryGenerator: Resolution must be in range 8 < res < 1024 and must be ^2';

		var maxTexSize = this.renderer.capabilities.maxTextureSize;

		if (w > maxTexSize || h > maxTexSize) throw 'THREE.SDFGeometryGenerator: Your device does not support this resolution (' + res + '), decrease [res] param.';

		var tilesX = w / res;
		var tilesY = h / res;

		var sdfCompute = '
			varying vec2 vUv;
			uniform float tileNum;
			uniform float bounds;
			[#dist#]
			void main()	{ gl_FragColor=vec4( ( dist( vec3( vUv, tileNum ) * 2.0 * bounds - vec3( bounds ) ) < 0.00001 ) ? 1.0 : 0.0 ); }
		';

		var sdfRT = this.computeSDF(w, h, tilesX, tilesY, bounds, sdfCompute.replace('[#dist#]', distFunc));

		var read = new Float32Array(w * h * 4);
		this.renderer.readRenderTargetPixels(sdfRT, 0, 0, w, h, read);
		sdfRT.dispose();

		var mesh = surfaceNet.call([res, res, res], (x:Float, y:Float, z:Float) -> {

			x = (x + bounds) * (res / (bounds * 2));
			y = (y + bounds) * (res / (bounds * 2));
			z = (z + bounds) * (res / (bounds * 2));
			var p = (x + (z % tilesX) * res) + y * w + (Math.floor(z / tilesX) * res * w);
			p *= 4;
			return (read[p + 3] > 0) ? -0.000000001 : 1;

		}, [[ - bounds, - bounds, - bounds ], [ bounds, bounds, bounds ]]);

		var ps = [], ids = [];
		var geometry = new BufferGeometry();
		mesh.positions.forEach(p -> {

			ps.push(p[0], p[1], p[2]);

		});
		mesh.cells.forEach(p -> ids.push(p[0], p[1], p[2]));
		geometry.setAttribute('position', new BufferAttribute(new Float32Array(ps), 3));
		geometry.setIndex(ids);

		return geometry;

	}

	public function computeSDF(width:Float, height:Float, tilesX:Float, tilesY:Float, bounds:Float, shader:String):WebGLRenderTarget {

		var rt = new WebGLRenderTarget(width, height, { type: FloatType });
		var scn = new Scene();
		var cam = new OrthographicCamera();
		var tiles = tilesX * tilesY;
		var currentTile = 0;

		Object.assign(cam, { left: width / -2, right: width / 2, top: height / 2, bottom: height / -2 }).updateProjectionMatrix();
		cam.position.z = 2;

		var tileSize = width / tilesX;
		var geometry = new PlaneGeometry(tileSize, tileSize);

		while (currentTile++ < tiles) {

			var c = currentTile - 1;
			var [px, py] = [(tileSize) / 2 + (c % tilesX) * (tileSize) - width / 2, (tileSize) / 2 + Math.floor(c / tilesX) * (tileSize) - height / 2];
			var compPlane = new Mesh(geometry, new ShaderMaterial({
				uniforms: {
					res: { value: new Vector2(width, height) },
					tileNum: { value: c / (tilesX * tilesY - 1) },
					bounds: { value: bounds }
				},
				vertexShader: 'varying vec2 vUv;void main(){vUv=uv;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0);}',
				fragmentShader: shader
			}));
			compPlane.position.set(px, py, 0);
			scn.add(compPlane);

		}

		this.renderer.setRenderTarget(rt);
		this.renderer.render(scn, cam);
		this.renderer.setRenderTarget(null);

		geometry.dispose();

		scn.traverse(function(object) {

			if (object.material !== undefined) object.material.dispose();

		});

		return rt;

	}

}