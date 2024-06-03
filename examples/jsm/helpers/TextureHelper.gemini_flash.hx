import three.extras.geometries.BoxGeometry;
import three.extras.geometries.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.math.Vector3;
import three.objects.Mesh;
import three.textures.CubeTexture;
import three.textures.Data3DTexture;
import three.textures.DataArrayTexture;
import three.textures.Texture;
import three.utils.BufferGeometryUtils;

class TextureHelper extends Mesh {

	public var texture:Texture;

	public function new(texture:Texture, width:Float = 1, height:Float = 1, depth:Float = 1) {
		var material = new ShaderMaterial({
			type: "TextureHelperMaterial",
			side: ShaderMaterial.DoubleSide,
			transparent: true,
			uniforms: {
				map: {value: texture},
				alpha: {value: getAlpha(texture)}
			},
			vertexShader: [
				"attribute vec3 uvw;",
				"varying vec3 vUvw;",
				"void main() {",
				"	vUvw = uvw;",
				"	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );",
				"}"
			].join("\n"),
			fragmentShader: [
				"precision highp float;",
				"precision highp sampler2DArray;",
				"precision highp sampler3D;",
				"uniform {samplerType} map;",
				"uniform float alpha;",
				"varying vec3 vUvw;",
				"vec4 textureHelper( in sampler2D map ) { return texture( map, vUvw.xy ); }",
				"vec4 textureHelper( in sampler2DArray map ) { return texture( map, vUvw ); }",
				"vec4 textureHelper( in sampler3D map ) { return texture( map, vUvw ); }",
				"vec4 textureHelper( in samplerCube map ) { return texture( map, vUvw ); }",
				"void main() {",
				"	gl_FragColor = linearToOutputTexel( vec4( textureHelper( map ).xyz, alpha ) );",
				"}"
			].join("\n").replace("{samplerType}", getSamplerType(texture))
		});

		var geometry = texture.isCubeTexture
			? createCubeGeometry(width, height, depth)
			: createSliceGeometry(texture, width, height, depth);

		super(geometry, material);

		this.texture = texture;
		this.type = "TextureHelper";
	}

	public function dispose() {
		this.geometry.dispose();
		this.material.dispose();
	}

}

function getSamplerType(texture:Texture):String {
	if (texture.isCubeTexture) {
		return "samplerCube";
	} else if (texture.isDataArrayTexture || texture.isCompressedArrayTexture) {
		return "sampler2DArray";
	} else if (texture.isData3DTexture || texture.isCompressed3DTexture) {
		return "sampler3D";
	} else {
		return "sampler2D";
	}
}

function getImageCount(texture:Texture):Int {
	if (texture.isCubeTexture) {
		return 6;
	} else if (texture.isDataArrayTexture || texture.isCompressedArrayTexture) {
		return cast texture.image.depth;
	} else if (texture.isData3DTexture || texture.isCompressed3DTexture) {
		return cast texture.image.depth;
	} else {
		return 1;
	}
}

function getAlpha(texture:Texture):Float {
	if (texture.isCubeTexture) {
		return 1;
	} else if (texture.isDataArrayTexture || texture.isCompressedArrayTexture) {
		return Math.max(1 / cast texture.image.depth, 0.25);
	} else if (texture.isData3DTexture || texture.isCompressed3DTexture) {
		return Math.max(1 / cast texture.image.depth, 0.25);
	} else {
		return 1;
	}
}

function createCubeGeometry(width:Float, height:Float, depth:Float):BoxGeometry {
	var geometry = new BoxGeometry(width, height, depth);
	var position = geometry.attributes.position;
	var uv = geometry.attributes.uv;
	var uvw = new BufferAttribute(new Float32Array(uv.count * 3), 3);

	var direction = new Vector3();

	for (j in 0...uv.count) {
		direction.fromBufferAttribute(position, j).normalize();

		var u = direction.x;
		var v = direction.y;
		var w = direction.z;

		uvw.setXYZ(j, u, v, w);
	}

	geometry.deleteAttribute("uv");
	geometry.setAttribute("uvw", uvw);

	return geometry;
}

function createSliceGeometry(texture:Texture, width:Float, height:Float, depth:Float):BoxGeometry {
	var sliceCount = getImageCount(texture);
	var geometries = new Array<PlaneGeometry>();

	for (i in 0...sliceCount) {
		var geometry = new PlaneGeometry(width, height);

		if (sliceCount > 1) {
			geometry.translate(0, 0, depth * (i / (sliceCount - 1) - 0.5));
		}

		var uv = geometry.attributes.uv;
		var uvw = new BufferAttribute(new Float32Array(uv.count * 3), 3);

		for (j in 0...uv.count) {
			var u = uv.getX(j);
			var v = texture.flipY ? uv.getY(j) : 1 - uv.getY(j);
			var w = sliceCount == 1
				? 1
				: texture.isDataArrayTexture || texture.isCompressedArrayTexture
					? i
					: i / (sliceCount - 1);

			uvw.setXYZ(j, u, v, w);
		}

		geometry.deleteAttribute("uv");
		geometry.setAttribute("uvw", uvw);

		geometries.push(geometry);
	}

	return cast BufferGeometryUtils.mergeGeometries(geometries);
}

class TextureHelperMaterial extends ShaderMaterial {
	public function new() {
		super();
	}
}

class TextureHelper extends Mesh {
	public var texture:Texture;

	public function new(texture:Texture, width:Float = 1, height:Float = 1, depth:Float = 1) {
		var material = new TextureHelperMaterial({
			type: "TextureHelperMaterial",
			side: ShaderMaterial.DoubleSide,
			transparent: true,
			uniforms: {
				map: {value: texture},
				alpha: {value: getAlpha(texture)}
			},
			vertexShader: [
				"attribute vec3 uvw;",
				"varying vec3 vUvw;",
				"void main() {",
				"	vUvw = uvw;",
				"	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );",
				"}"
			].join("\n"),
			fragmentShader: [
				"precision highp float;",
				"precision highp sampler2DArray;",
				"precision highp sampler3D;",
				"uniform {samplerType} map;",
				"uniform float alpha;",
				"varying vec3 vUvw;",
				"vec4 textureHelper( in sampler2D map ) { return texture( map, vUvw.xy ); }",
				"vec4 textureHelper( in sampler2DArray map ) { return texture( map, vUvw ); }",
				"vec4 textureHelper( in sampler3D map ) { return texture( map, vUvw ); }",
				"vec4 textureHelper( in samplerCube map ) { return texture( map, vUvw ); }",
				"void main() {",
				"	gl_FragColor = linearToOutputTexel( vec4( textureHelper( map ).xyz, alpha ) );",
				"}"
			].join("\n").replace("{samplerType}", getSamplerType(texture))
		});

		var geometry = texture.isCubeTexture
			? createCubeGeometry(width, height, depth)
			: createSliceGeometry(texture, width, height, depth);

		super(geometry, material);

		this.texture = texture;
		this.type = "TextureHelper";
	}

	public function dispose() {
		this.geometry.dispose();
		this.material.dispose();
	}

}

class TextureHelperMaterial extends ShaderMaterial {
	public function new() {
		super();
	}
}