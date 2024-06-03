import three.extras.core.AnimationAction;
import three.extras.core.AnimationClip;
import three.extras.core.AnimationMixer;
import three.extras.core.PropertyBinding;
import three.geometries.BoxGeometry;
import three.geometries.BufferGeometry;
import three.geometries.CircleGeometry;
import three.geometries.ConeGeometry;
import three.geometries.CylinderGeometry;
import three.geometries.DodecahedronGeometry;
import three.geometries.EdgesGeometry;
import three.geometries.ExtrudeGeometry;
import three.geometries.IcosahedronGeometry;
import three.geometries.LatheGeometry;
import three.geometries.OctahedronGeometry;
import three.geometries.PlaneGeometry;
import three.geometries.PolyhedronGeometry;
import three.geometries.RingGeometry;
import three.geometries.ShapeGeometry;
import three.geometries.SphereGeometry;
import three.geometries.TetrahedronGeometry;
import three.geometries.TorusGeometry;
import three.geometries.TorusKnotGeometry;
import three.geometries.TubeGeometry;
import three.materials.MeshBasicMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshStandardMaterial;
import three.math.Color;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.objects.Camera;
import three.objects.Mesh;
import three.objects.Object3D;
import three.objects.OrthographicCamera;
import three.objects.PerspectiveCamera;
import three.objects.SkinnedMesh;
import three.scenes.Scene;
import three.textures.CompressedTexture;
import three.textures.Texture;
import fflate.FFlate;
import fflate.Zip;
import haxe.io.Bytes;
import haxe.io.Output;

class USDZExporter {

	public function new() {}

	public function parse(scene:Scene, onDone:Dynamic->Void, onError:Dynamic->Void, options:Dynamic = null):Void {
		parseAsync(scene, options).then(onDone).catch(onError);
	}

	public function parseAsync(scene:Scene, options:Dynamic = null):Dynamic {
		options = if (options == null) {
			{
				ar: {
					anchoring: { type: 'plane' },
					planeAnchoring: { alignment: 'horizontal' }
				},
				includeAnchoringProperties: true,
				quickLookCompatible: false,
				maxTextureSize: 1024
			}
		} else {
			{
				ar: if (options.ar == null) {
					{
						anchoring: { type: 'plane' },
						planeAnchoring: { alignment: 'horizontal' }
					}
				} else {
					options.ar
				},
				includeAnchoringProperties: if (options.includeAnchoringProperties == null) true else options.includeAnchoringProperties,
				quickLookCompatible: if (options.quickLookCompatible == null) false else options.quickLookCompatible,
				maxTextureSize: if (options.maxTextureSize == null) 1024 else options.maxTextureSize
			}
		};

		var files:Map<String, Dynamic> = new Map();
		var modelFileName:String = 'model.usda';

		// model file should be first in USDZ archive so we init it here
		files.set(modelFileName, null);

		var output:String = buildHeader();

		output += buildSceneStart(options);

		var materials:Map<String, MeshStandardMaterial> = new Map();
		var textures:Map<String, Texture> = new Map();

		scene.traverseVisible((object:Object3D) -> {
			if (object.isMesh) {
				var geometry:BufferGeometry = object.geometry;
				var material:MeshStandardMaterial = cast(object.material, MeshStandardMaterial);

				if (material != null) {
					var geometryFileName:String = 'geometries/Geometry_' + geometry.id + '.usda';

					if (!files.exists(geometryFileName)) {
						var meshObject:String = buildMeshObject(geometry);
						files.set(geometryFileName, buildUSDFileAsString(meshObject));
					}

					if (!materials.exists(material.uuid)) {
						materials.set(material.uuid, material);
					}

					output += buildXform(object, geometry, material);
				} else {
					console.warn('THREE.USDZExporter: Unsupported material type (USDZ only supports MeshStandardMaterial)', object);
				}
			} else if (object.isCamera) {
				output += buildCamera(object);
			}
		});


		output += buildSceneEnd();

		output += buildMaterials(materials, textures, options.quickLookCompatible);

		files.set(modelFileName, strToU8(output));
		output = null;

		for (id in textures.keys()) {
			var texture:Texture = textures.get(id);

			if (Std.is(texture, CompressedTexture)) {
				texture = decompress(texture);
			}

			var canvas:html.Canvas = imageToCanvas(texture.image, texture.flipY, options.maxTextureSize);
			var blob:html.Blob = await new Promise(function(resolve:html.Blob->Void) {
				canvas.toBlob(resolve, 'image/png', 1);
			});

			files.set(`textures/Texture_${id}.png`, new Uint8Array(await blob.arrayBuffer()));
		}

		// 64 byte alignment
		// https://github.com/101arrowz/fflate/issues/39#issuecomment-777263109

		var offset:Int = 0;

		for (filename in files.keys()) {
			var file:Dynamic = files.get(filename);
			var headerSize:Int = 34 + filename.length;

			offset += headerSize;

			var offsetMod64:Int = offset & 63;

			if (offsetMod64 != 4) {
				var padLength:Int = 64 - offsetMod64;
				var padding:Uint8Array = new Uint8Array(padLength);

				files.set(filename, [file, { extra: { 12345: padding } }]);
			}

			offset = file.length;
		}

		return zipSync(files, { level: 0 });
	}

	private static function decompress(texture:CompressedTexture):Texture {
		return texture; // TODO: Implement decompress function.
	}

	private static function imageToCanvas(image:Dynamic, flipY:Bool, maxTextureSize:Int):html.Canvas {
		if (Std.is(image, html.Image) || Std.is(image, html.Canvas) || Std.is(image, html.OffscreenCanvas) || Std.is(image, html.ImageBitmap)) {
			var scale:Float = maxTextureSize / Math.max(image.width, image.height);

			var canvas:html.Canvas = document.createElement('canvas');
			canvas.width = image.width * Math.min(1, scale);
			canvas.height = image.height * Math.min(1, scale);

			var context:html.CanvasRenderingContext2D = canvas.getContext('2d');

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

	private static var PRECISION:Int = 7;

	private static function buildHeader():String {
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

	private static function buildSceneStart(options:Dynamic):String {
		var alignment:String = if (options.includeAnchoringProperties) {
			`
		token preliminary:anchoring:type = "${options.ar.anchoring.type}"
		token preliminary:planeAnchoring:alignment = "${options.ar.planeAnchoring.alignment}"
	`
		} else {
			''
		};
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

	private static function buildSceneEnd():String {
		return `
		}
	}
}

`;
	}

	private static function buildUSDFileAsString(dataToInsert:String):Bytes {
		var output:String = buildHeader();
		output += dataToInsert;
		return strToU8(output);
	}

	// Xform

	private static function buildXform(object:Object3D, geometry:BufferGeometry, material:MeshStandardMaterial):String {
		var name:String = 'Object_' + object.id;
		var transform:String = buildMatrix(object.matrixWorld);

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

	private static function buildMatrix(matrix:Matrix4):String {
		var array:Array<Float> = matrix.elements;

		return `( ${buildMatrixRow(array, 0)}, ${buildMatrixRow(array, 4)}, ${buildMatrixRow(array, 8)}, ${buildMatrixRow(array, 12)} )`;
	}

	private static function buildMatrixRow(array:Array<Float>, offset:Int):String {
		return `(${array[offset + 0]}, ${array[offset + 1]}, ${array[offset + 2]}, ${array[offset + 3]})`;
	}

	// Mesh

	private static function buildMeshObject(geometry:BufferGeometry):String {
		var mesh:String = buildMesh(geometry);
		return `
def "Geometry"
{
${mesh}
}
`;
	}

	private static function buildMesh(geometry:BufferGeometry):String {
		var name:String = 'Geometry';
		var attributes:Map<String, Dynamic> = geometry.attributes;
		var count:Int = attributes.get('position').count;

		return `
	def Mesh "${name}"
	{
		int[] faceVertexCounts = [${buildMeshVertexCount(geometry)}]
		int[] faceVertexIndices = [${buildMeshVertexIndices(geometry)}]
		normal3f[] normals = [${buildVector3Array(attributes.get('normal'), count)}] (
			interpolation = "vertex"
		)
		point3f[] points = [${buildVector3Array(attributes.get('position'), count)}]
${buildPrimvars(attributes)}
		uniform token subdivisionScheme = "none"
	}
`;
	}

	private static function buildMeshVertexCount(geometry:BufferGeometry):String {
		var count:Int = if (geometry.index != null) geometry.index.count else geometry.attributes.get('position').count;

		return Array.fill(count / 3, 3).join(', ');
	}

	private static function buildMeshVertexIndices(geometry:BufferGeometry):String {
		var index:Dynamic = geometry.index;
		var array:Array<Int> = [];

		if (index != null) {
			for (i in 0...index.count) {
				array.push(index.getX(i));
			}
		} else {
			var length:Int = geometry.attributes.get('position').count;

			for (i in 0...length) {
				array.push(i);
			}
		}

		return array.join(', ');
	}

	private static function buildVector3Array(attribute:Dynamic, count:Int):String {
		if (attribute == null) {
			console.warn('USDZExporter: Normals missing.');
			return Array.fill(count, '(0, 0, 0)').join(', ');
		}

		var array:Array<String> = [];

		for (i in 0...attribute.count) {
			var x:Float = attribute.getX(i);
			var y:Float = attribute.getY(i);
			var z:Float = attribute.getZ(i);

			array.push(`(${x.toPrecision(PRECISION)}, ${y.toPrecision(PRECISION)}, ${z.toPrecision(PRECISION)})`);
		}

		return array.join(', ');
	}

	private static function buildVector2Array(attribute:Dynamic):String {
		var array:Array<String> = [];

		for (i in 0...attribute.count) {
			var x:Float = attribute.getX(i);
			var y:Float = attribute.getY(i);

			array.push(`(${x.toPrecision(PRECISION)}, ${1 - y.toPrecision(PRECISION)})`);
		}

		return array.join(', ');
	}

	private static function buildPrimvars(attributes:Map<String, Dynamic>):String {
		var string:String = '';

		for (i in 0...4) {
			var id:String = if (i > 0) i.toString() else '';
			var attribute:Dynamic = attributes.get('uv' + id);

			if (attribute != null) {
				string += `
		texCoord2f[] primvars:st${id} = [${buildVector2Array(attribute)}] (
			interpolation = "vertex"
		)`;
			}
		}

		// vertex colors

		var colorAttribute:Dynamic = attributes.get('color');

		if (colorAttribute != null) {
			var count:Int = colorAttribute.count;

			string += `
	color3f[] primvars:displayColor = [${buildVector3Array(colorAttribute, count)}] (
		interpolation = "vertex"
		)`;
		}

		return string;
	}

	// Materials

	private static function buildMaterials(materials:Map<String, MeshStandardMaterial>, textures:Map<String, Texture>, quickLookCompatible:Bool = false):String {
		var array:Array<String> = [];

		for (uuid in materials.keys()) {
			var material:MeshStandardMaterial = materials.get(uuid);

			array.push(buildMaterial(material, textures, quickLookCompatible));
		}

		return `def "Materials"
{
${array.join('')}
}

`;
	}

	private static function buildMaterial(material:MeshStandardMaterial, textures:Map<String, Texture>, quickLookCompatible:Bool = false):String {
		// https://graphics.pixar.com/usd/docs/UsdPreviewSurface-Proposal.html

		var pad:String = '			';
		var inputs:Array<String> = [];
		var samplers:Array<String> = [];

		function buildTexture(texture:Texture, mapType:String, color:Color = null):String {
			var id:String = texture.source.id + '_' + texture.flipY;

			textures.set(id, texture);

			var uv:String = if (texture.channel > 0) 'st' + texture.channel else 'st';

			var WRAPPINGS:Map<Int, String> = new Map([
				[1000, 'repeat'], // RepeatWrapping
				[1001, 'clamp'], // ClampToEdgeWrapping
				[1002, 'mirror'] // MirroredRepeatWrapping
			]);

			var repeat:Vector2 = texture.repeat.clone();
			var offset:Vector2 = texture.offset.clone();
			var rotation:Float = texture.rotation;

			// rotation is around the wrong point. after rotation we need to shift offset again so that we're rotating around the right spot
			var xRotationOffset:Float = Math.sin(rotation);
			var yRotationOffset:Float = Math.cos(rotation);

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
			${if (color != null) 'float4 inputs:scale = ' + buildColor4(color) else ''}
			token inputs:sourceColorSpace = "${if (texture.colorSpace == 0) 'raw' else 'sRGB'}"
			token inputs:wrapS = "${WRAPPINGS.get(texture.wrapS)}"
			token inputs:wrapT = "${WRAPPINGS.get(texture.wrapT)}"
			float outputs:r
			float outputs:g
			float outputs:b
			float3 outputs:rgb
			${if (material.transparent || material.alphaTest > 0.0) 'float outputs:a' else ''}
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

		if (Std.is(material, MeshPhysicalMaterial)) {
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

	private static function buildColor(color:Color):String {
		return `(${color.r}, ${color.g}, ${color.b})`;
	}

	private static function buildColor4(color:Color):String {
		return `(${color.r}, ${color.g}, ${color.b}, 1.0)`;
	}

	private static function buildVector2(vector:Vector2):String {
		return `(${vector.x}, ${vector.y})`;
	}


	private static function buildCamera(camera:Camera):String {
		var name:String = if (camera.name != null) camera.name else 'Camera_' + camera.id;

		var transform:String = buildMatrix(camera.matrixWorld);

		if (camera.matrixWorld.determinant() < 0) {
			console.warn('THREE.USDZExporter: USDZ does not support negative scales', camera);
		}

		if (Std.is(camera, OrthographicCamera)) {
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

	private static function strToU8(str:String):Bytes {
		return Bytes.ofString(str);
	}

	private static function zipSync(files:Map<String, Dynamic>, options:Dynamic = null):Bytes {
		var zip:Zip = new Zip(options);

		for (filename in files.keys()) {
			var file:Dynamic = files.get(filename);
			zip.addFile(filename, file);
		}

		var bytes:Bytes = new Bytes();
		var output:Output = new Output(bytes);
		zip.save(output);
		return bytes;
	}

}