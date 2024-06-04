import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.objects.Camera;
import three.objects.Mesh;
import three.objects.Object3D;
import three.scenes.Scene;
import three.materials.MeshStandardMaterial;
import three.geometries.BufferGeometry;
import three.textures.Texture;
import three.textures.CompressedTexture;

import fflate.FFlate;

import utils.TextureUtils;

class USDZExporter {

	public function new() {}

	public function parse(scene:Scene, onDone:Dynamic->Void, onError:Dynamic->Void, options:Dynamic = {}) {
		parseAsync(scene, options).then(onDone).catch(onError);
	}

	public function parseAsync(scene:Scene, options:Dynamic = {}):Dynamic {
		options = {
			ar: {
				anchoring: { type: 'plane' },
				planeAnchoring: { alignment: 'horizontal' }
			},
			includeAnchoringProperties: true,
			quickLookCompatible: false,
			maxTextureSize: 1024
		}.merge(options);

		var files = new Map<String, Dynamic>();
		var modelFileName = 'model.usda';
		files.set(modelFileName, null);

		var output = buildHeader();
		output += buildSceneStart(options);

		var materials = new Map<String, MeshStandardMaterial>();
		var textures = new Map<String, Texture>();

		scene.traverseVisible((object:Object3D) -> {
			if (cast object.isMesh) {
				var geometry = cast object.geometry;
				var material = cast object.material;

				if (material.isMeshStandardMaterial) {
					var geometryFileName = 'geometries/Geometry_' + geometry.id + '.usda';

					if (!files.exists(geometryFileName)) {
						var meshObject = buildMeshObject(geometry);
						files.set(geometryFileName, buildUSDFileAsString(meshObject));
					}

					if (!materials.exists(material.uuid)) {
						materials.set(material.uuid, material);
					}

					output += buildXform(object, geometry, material);

				} else {
					console.warn('THREE.USDZExporter: Unsupported material type (USDZ only supports MeshStandardMaterial)', object);
				}
			} else if (cast object.isCamera) {
				output += buildCamera(object);
			}
		});

		output += buildSceneEnd();
		output += buildMaterials(materials, textures, options.quickLookCompatible);

		files.set(modelFileName, strToU8(output));
		output = null;

		for (texture in textures.iterator()) {
			if (cast texture.isCompressedTexture) {
				texture = TextureUtils.decompress(texture);
			}

			var canvas = imageToCanvas(texture.image, texture.flipY, options.maxTextureSize);
			var blob = new Promise((resolve:Dynamic->Void) -> canvas.toBlob(resolve, 'image/png', 1));
			files.set('textures/Texture_' + texture.id + '.png', new Uint8Array(blob.arrayBuffer()));
		}

		// 64 byte alignment
		// https://github.com/101arrowz/fflate/issues/39#issuecomment-777263109

		var offset = 0;

		for (filename in files.iterator()) {
			var file = files.get(filename);
			var headerSize = 34 + filename.length;

			offset += headerSize;
			var offsetMod64 = offset & 63;

			if (offsetMod64 != 4) {
				var padLength = 64 - offsetMod64;
				var padding = new Uint8Array(padLength);

				files.set(filename, [file, { extra: { 12345: padding } }]);
			}

			offset += file.length;
		}

		return FFlate.zipSync(files, { level: 0 });
	}

	function imageToCanvas(image:Dynamic, flipY:Bool, maxTextureSize:Int):Dynamic {
		if ((typeof(HTMLImageElement) != 'undefined' && cast image.isHTMLImageElement) ||
			(typeof(HTMLCanvasElement) != 'undefined' && cast image.isHTMLCanvasElement) ||
			(typeof(OffscreenCanvas) != 'undefined' && cast image.isOffscreenCanvas) ||
			(typeof(ImageBitmap) != 'undefined' && cast image.isImageBitmap)) {

			var scale = maxTextureSize / Math.max(image.width, image.height);

			var canvas = document.createElement('canvas');
			canvas.width = image.width * Math.min(1, scale);
			canvas.height = image.height * Math.min(1, scale);

			var context = canvas.getContext('2d');

			// TODO: We should be able to do this in the UsdTransform2d?

			if (flipY) {
				context.translate(0, canvas.height);
				context.scale(1, -1);
			}

			context.drawImage(image, 0, 0, canvas.width, canvas.height);

			return canvas;

		} else {
			throw new Error('THREE.USDZExporter: No valid image data found. Unable to process texture.');
		}
	}

	//

	static public var PRECISION:Int = 7;

	static function buildHeader():String {
		return `#usda 1.0
(
	customLayerData = {
		string creator = "Three.js USDZExporter"
	}
	defaultPrim = "Root"
	metersPerUnit = 1
	upAxis = "Y"
)

`;
	}

	static function buildSceneStart(options:Dynamic):String {
		var alignment = options.includeAnchoringProperties ? `
		token preliminary:anchoring:type = "${options.ar.anchoring.type}"
		token preliminary:planeAnchoring:alignment = "${options.ar.planeAnchoring.alignment}"
	` : '';
		return `def Xform "Root"
{
	def Scope "Scenes" (
		kind = "sceneLibrary"
	)
	{
		def Xform "Scene" (
			customData = {
				bool preliminary_collidesWithEnvironment = 0
				string sceneName = "Scene"
			}
			sceneName = "Scene"
		)
		{${alignment}
`;
	}

	static function buildSceneEnd():String {
		return `
		}
	}
}

`;
	}

	static function buildUSDFileAsString(dataToInsert:String):Uint8Array {
		var output = buildHeader();
		output += dataToInsert;
		return strToU8(output);
	}

	// Xform

	static function buildXform(object:Object3D, geometry:BufferGeometry, material:MeshStandardMaterial):String {
		var name = 'Object_' + object.id;
		var transform = buildMatrix(object.matrixWorld);

		if (object.matrixWorld.determinant() < 0) {
			console.warn('THREE.USDZExporter: USDZ does not support negative scales', object);
		}

		return `def Xform "${name}" (
	prepend references = @./geometries/Geometry_${geometry.id}.usda@</Geometry>
	prepend apiSchemas = ["MaterialBindingAPI"]
)
{
	matrix4d xformOp:transform = ${transform}
	uniform token[] xformOpOrder = ["xformOp:transform"]

	rel material:binding = </Materials/Material_${material.id}>
}

`;
	}

	static function buildMatrix(matrix:Matrix4):String {
		var array = matrix.elements;

		return `( ${buildMatrixRow(array, 0)}, ${buildMatrixRow(array, 4)}, ${buildMatrixRow(array, 8)}, ${buildMatrixRow(array, 12)} )`;
	}

	static function buildMatrixRow(array:Array<Float>, offset:Int):String {
		return `(${array[offset + 0]}, ${array[offset + 1]}, ${array[offset + 2]}, ${array[offset + 3]})`;
	}

	// Mesh

	static function buildMeshObject(geometry:BufferGeometry):String {
		var mesh = buildMesh(geometry);
		return `
def "Geometry"
{
${mesh}
}
`;
	}

	static function buildMesh(geometry:BufferGeometry):String {
		var name = 'Geometry';
		var attributes = geometry.attributes;
		var count = attributes.position.count;

		return `
	def Mesh "${name}"
	{
		int[] faceVertexCounts = [${buildMeshVertexCount(geometry)}]
		int[] faceVertexIndices = [${buildMeshVertexIndices(geometry)}]
		normal3f[] normals = [${buildVector3Array(attributes.normal, count)}] (
			interpolation = "vertex"
		)
		point3f[] points = [${buildVector3Array(attributes.position, count)}]
${buildPrimvars(attributes)}
		uniform token subdivisionScheme = "none"
	}
`;
	}

	static function buildMeshVertexCount(geometry:BufferGeometry):String {
		var count = geometry.index != null ? geometry.index.count : geometry.attributes.position.count;

		return Array.fill(count / 3, 3).join(', ');
	}

	static function buildMeshVertexIndices(geometry:BufferGeometry):String {
		var index = geometry.index;
		var array = [];

		if (index != null) {
			for (i in 0...index.count) {
				array.push(index.getX(i));
			}
		} else {
			var length = geometry.attributes.position.count;

			for (i in 0...length) {
				array.push(i);
			}
		}

		return array.join(', ');
	}

	static function buildVector3Array(attribute:Dynamic, count:Int):String {
		if (attribute == null) {
			console.warn('USDZExporter: Normals missing.');
			return Array.fill(count, '(0, 0, 0)').join(', ');
		}

		var array = [];

		for (i in 0...attribute.count) {
			var x = attribute.getX(i);
			var y = attribute.getY(i);
			var z = attribute.getZ(i);

			array.push(`(${x.toPrecision(PRECISION)}, ${y.toPrecision(PRECISION)}, ${z.toPrecision(PRECISION)})`);
		}

		return array.join(', ');
	}

	static function buildVector2Array(attribute:Dynamic):String {
		var array = [];

		for (i in 0...attribute.count) {
			var x = attribute.getX(i);
			var y = attribute.getY(i);

			array.push(`(${x.toPrecision(PRECISION)}, ${1 - y.toPrecision(PRECISION)})`);
		}

		return array.join(', ');
	}

	static function buildPrimvars(attributes:Dynamic):String {
		var string = '';

		for (i in 0...4) {
			var id = (i > 0 ? i : '');
			var attribute = attributes['uv' + id];

			if (attribute != null) {
				string += `
		texCoord2f[] primvars:st${id} = [${buildVector2Array(attribute)}] (
			interpolation = "vertex"
		)`;
			}
		}

		// vertex colors

		var colorAttribute = attributes.color;

		if (colorAttribute != null) {
			var count = colorAttribute.count;

			string += `
	color3f[] primvars:displayColor = [${buildVector3Array(colorAttribute, count)}] (
		interpolation = "vertex"
		)`;
		}

		return string;
	}

	// Materials

	static function buildMaterials(materials:Map<String, MeshStandardMaterial>, textures:Map<String, Texture>, quickLookCompatible:Bool = false):String {
		var array = [];

		for (material in materials.iterator()) {
			array.push(buildMaterial(material, textures, quickLookCompatible));
		}

		return `def "Materials"
{
${array.join('')}
}

`;
	}

	static function buildMaterial(material:MeshStandardMaterial, textures:Map<String, Texture>, quickLookCompatible:Bool = false):String {
		// https://graphics.pixar.com/usd/docs/UsdPreviewSurface-Proposal.html

		var pad = '			';
		var inputs = [];
		var samplers = [];

		function buildTexture(texture:Texture, mapType:String, color:Vector3 = null):String {
			var id = texture.source.id + '_' + texture.flipY;
			textures.set(id, texture);

			var uv = texture.channel > 0 ? 'st' + texture.channel : 'st';

			var WRAPPINGS = {
				1000: 'repeat', // RepeatWrapping
				1001: 'clamp', // ClampToEdgeWrapping
				1002: 'mirror' // MirroredRepeatWrapping
			};

			var repeat = texture.repeat.clone();
			var offset = texture.offset.clone();
			var rotation = texture.rotation;

			// rotation is around the wrong point. after rotation we need to shift offset again so that we're rotating around the right spot
			var xRotationOffset = Math.sin(rotation);
			var yRotationOffset = Math.cos(rotation);

			// texture coordinates start in the opposite corner, need to correct
			offset.y = 1 - offset.y - repeat.y;

			// turns out QuickLook is buggy and interprets texture repeat inverted/applies operations in a different order.
			// Apple Feedback: 	FB10036297 and FB11442287
			if (quickLookCompatible) {
				// This is NOT correct yet in QuickLook, but comes close for a range of models.
				// It becomes more incorrect the bigger the offset is

				offset.x = offset.x / repeat.x;
				offset.y = offset.y / repeat.y;

				offset.x += xRotationOffset / repeat.x;
				offset.y += yRotationOffset - 1;

			} else {
				// results match glTF results exactly. verified correct in usdview.
				offset.x += xRotationOffset * repeat.x;
				offset.y += (1 - yRotationOffset) * repeat.y;
			}

			return `
		def Shader "PrimvarReader_${mapType}"
		{
			uniform token info:id = "UsdPrimvarReader_float2"
			float2 inputs:fallback = (0.0, 0.0)
			token inputs:varname = "${uv}"
			float2 outputs:result
		}

		def Shader "Transform2d_${mapType}"
		{
			uniform token info:id = "UsdTransform2d"
			token inputs:in.connect = </Materials/Material_${material.id}/PrimvarReader_${mapType}.outputs:result>
			float inputs:rotation = ${((rotation * (180 / Math.PI)).toFixed(PRECISION))}
			float2 inputs:scale = ${buildVector2(repeat)}
			float2 inputs:translation = ${buildVector2(offset)}
			float2 outputs:result
		}

		def Shader "Texture_${texture.id}_${mapType}"
		{
			uniform token info:id = "UsdUVTexture"
			asset inputs:file = @textures/Texture_${id}.png@
			float2 inputs:st.connect = </Materials/Material_${material.id}/Transform2d_${mapType}.outputs:result>
			${color != null ? 'float4 inputs:scale = ' + buildColor4(color) : ''}
			token inputs:sourceColorSpace = "${texture.colorSpace == 0 ? 'raw' : 'sRGB'}"
			token inputs:wrapS = "${WRAPPINGS[texture.wrapS]}"
			token inputs:wrapT = "${WRAPPINGS[texture.wrapT]}"
			float outputs:r
			float outputs:g
			float outputs:b
			float3 outputs:rgb
			${material.transparent || material.alphaTest > 0.0 ? 'float outputs:a' : ''}
		}`;
		}

		if (material.side == 2) {
			console.warn('THREE.USDZExporter: USDZ does not support double sided materials', material);
		}

		if (material.map != null) {
			inputs.push(`${pad}color3f inputs:diffuseColor.connect = </Materials/Material_${material.id}/Texture_${material.map.id}_diffuse.outputs:rgb>`);

			if (material.transparent) {
				inputs.push(`${pad}float inputs:opacity.connect = </Materials/Material_${material.id}/Texture_${material.map.id}_diffuse.outputs:a>`);
			} else if (material.alphaTest > 0.0) {
				inputs.push(`${pad}float inputs:opacity.connect = </Materials/Material_${material.id}/Texture_${material.map.id}_diffuse.outputs:a>`);
				inputs.push(`${pad}float inputs:opacityThreshold = ${material.alphaTest}`);
			}

			samplers.push(buildTexture(material.map, 'diffuse', material.color));
		} else {
			inputs.push(`${pad}color3f inputs:diffuseColor = ${buildColor(material.color)}`);
		}

		if (material.emissiveMap != null) {
			inputs.push(`${pad}color3f inputs:emissiveColor.connect = </Materials/Material_${material.id}/Texture_${material.emissiveMap.id}_emissive.outputs:rgb>`);

			samplers.push(buildTexture(material.emissiveMap, 'emissive'));
		} else if (material.emissive.getHex() > 0) {
			inputs.push(`${pad}color3f inputs:emissiveColor = ${buildColor(material.emissive)}`);
		}

		if (material.normalMap != null) {
			inputs.push(`${pad}normal3f inputs:normal.connect = </Materials/Material_${material.id}/Texture_${material.normalMap.id}_normal.outputs:rgb>`);

			samplers.push(buildTexture(material.normalMap, 'normal'));
		}

		if (material.aoMap != null) {
			inputs.push(`${pad}float inputs:occlusion.connect = </Materials/Material_${material.id}/Texture_${material.aoMap.id}_occlusion.outputs:r>`);

			samplers.push(buildTexture(material.aoMap, 'occlusion'));
		}

		if (material.roughnessMap != null && material.roughness == 1) {
			inputs.push(`${pad}float inputs:roughness.connect = </Materials/Material_${material.id}/Texture_${material.roughnessMap.id}_roughness.outputs:g>`);

			samplers.push(buildTexture(material.roughnessMap, 'roughness'));
		} else {
			inputs.push(`${pad}float inputs:roughness = ${material.roughness}`);
		}

		if (material.metalnessMap != null && material.metalness == 1) {
			inputs.push(`${pad}float inputs:metallic.connect = </Materials/Material_${material.id}/Texture_${material.metalnessMap.id}_metallic.outputs:b>`);

			samplers.push(buildTexture(material.metalnessMap, 'metallic'));
		} else {
			inputs.push(`${pad}float inputs:metallic = ${material.metalness}`);
		}

		if (material.alphaMap != null) {
			inputs.push(`${pad}float inputs:opacity.connect = </Materials/Material_${material.id}/Texture_${material.alphaMap.id}_opacity.outputs:r>`);
			inputs.push(`${pad}float inputs:opacityThreshold = 0.0001`);

			samplers.push(buildTexture(material.alphaMap, 'opacity'));
		} else {
			inputs.push(`${pad}float inputs:opacity = ${material.opacity}`);
		}

		if (material.isMeshPhysicalMaterial) {
			inputs.push(`${pad}float inputs:clearcoat = ${material.clearcoat}`);
			inputs.push(`${pad}float inputs:clearcoatRoughness = ${material.clearcoatRoughness}`);
			inputs.push(`${pad}float inputs:ior = ${material.ior}`);
		}

		return `
	def Material "Material_${material.id}"
	{
		def Shader "PreviewSurface"
		{
			uniform token info:id = "UsdPreviewSurface"
${inputs.join('\n')}
			int inputs:useSpecularWorkflow = 0
			token outputs:surface
		}

		token outputs:surface.connect = </Materials/Material_${material.id}/PreviewSurface.outputs:surface>

${samplers.join('\n')}

	}
`;
	}

	static function buildColor(color:Vector3):String {
		return `(${color.x}, ${color.y}, ${color.z})`;
	}

	static function buildColor4(color:Vector3):String {
		return `(${color.x}, ${color.y}, ${color.z}, 1.0)`;
	}

	static function buildVector2(vector:Vector2):String {
		return `(${vector.x}, ${vector.y})`;
	}

	static function buildCamera(camera:Camera):String {
		var name = camera.name != null ? camera.name : 'Camera_' + camera.id;

		var transform = buildMatrix(camera.matrixWorld);

		if (camera.matrixWorld.determinant() < 0) {
			console.warn('THREE.USDZExporter: USDZ does not support negative scales', camera);
		}

		if (camera.isOrthographicCamera) {
			return `def Camera "${name}"
		{
			matrix4d xformOp:transform = ${transform}
			uniform token[] xformOpOrder = ["xformOp:transform"]

			float2 clippingRange = (${camera.near.toPrecision(PRECISION)}, ${camera.far.toPrecision(PRECISION)})
			float horizontalAperture = ${((Math.abs(camera.left) + Math.abs(camera.right)) * 10).toPrecision(PRECISION)}
			float verticalAperture = ${((Math.abs(camera.top) + Math.abs(camera.bottom)) * 10).toPrecision(PRECISION)}
			token projection = "orthographic"
		}
	
	`;
		} else {
			return `def Camera "${name}"
		{
			matrix4d xformOp:transform = ${transform}
			uniform token[] xformOpOrder = ["xformOp:transform"]

			float2 clippingRange = (${camera.near.toPrecision(PRECISION)}, ${camera.far.toPrecision(PRECISION)})
			float focalLength = ${camera.getFocalLength().toPrecision(PRECISION)}
			float focusDistance = ${camera.focus.toPrecision(PRECISION)}
			float horizontalAperture = ${camera.getFilmWidth().toPrecision(PRECISION)}
			token projection = "perspective"
			float verticalAperture = ${camera.getFilmHeight().toPrecision(PRECISION)}
		}
	
	`;
		}
	}

}