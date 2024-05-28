import js.three.*;
import js.fflate.*;
import js.Image;

class USDZExporter {
    public function parse(scene:Object3D, onDone:Void->Void, onError:Dynamic->Void, ?options:Map<Dynamic>) {
        this.parseAsync(scene, options).then(onDone).catch(onError);
    }

    public async function parseAsync(scene:Object3D, ?options:Map<Dynamic>):Async<Void> {
        options = options ?? {
            ar: {
                anchoring: { type: 'plane' },
                planeAnchoring: { alignment: 'horizontal' }
            },
            includeAnchoringProperties: true,
            quickLookCompatible: false,
            maxTextureSize: 1024,
        };

        var files = new Map<String, Bytes>();
        var modelFileName = 'model.usda';

        // model file should be first in USDZ archive so we init it here
        files[modelFileName] = null;

        var output = buildHeader();

        output += buildSceneStart(options);

        var materials = new Map<String, Material>();
        var textures = new Map<String, Texture>();

        scene.traverseVisible(function (object:Object3D) {
            if (Std.is(object, Mesh)) {
                var geometry = cast(object.geometry);
                var material = cast(object.material);

                if (Std.is(material, MeshStandardMaterial)) {
                    var geometryFileName = 'geometries/Geometry_' + geometry.id + '.usda';

                    if (!files.exists(geometryFileName)) {
                        var meshObject = buildMeshObject(geometry);
                        files[geometryFileName] = buildUSDFileAsString(meshObject);
                    }

                    if (!materials.exists(material.uuid)) {
                        materials[material.uuid] = material;
                    }

                    output += buildXform(object, geometry, material);
                } else {
                    trace('USDZExporter: Unsupported material type (USDZ only supports MeshStandardMaterial)', object);
                }
            } else if (Std.is(object, Camera)) {
                output += buildCamera(cast(object));
            }
        });

        output += buildSceneEnd();

        output += buildMaterials(materials, textures, options.quickLookCompatible);

        files[modelFileName] = strToU8(output);
        output = null;

        for (key in textures) {
            var texture = textures[key];

            if (texture.isCompressedTexture) {
                texture = decompress(texture);
            }

            var canvas = imageToCanvas(cast(texture.image), texture.flipY, options.maxTextureSize);
            var blob = await new Promise<Bytes>(function (resolve) {
                canvas.toBlob(resolve, 'image/png', 1);
            });

            files['textures/Texture_' + key + '.png'] = blob;
        }

        // 64 byte alignment
        // https://github.com/101arrowz/fflate/issues/39#issuecomment-777263109

        var offset:Int = 0;

        for (key in files) {
            var file = files[key];
            var headerSize = 34 + key.length;

            offset += headerSize;

            var offsetMod64 = offset % 64;

            if (offsetMod64 != 4) {
                var padLength = 64 - offsetMod64;
                var padding = new Uint8Array(padLength);

                files[key] = [file, { extra: { 12345: padding } }];
            }

            offset = file.length;
        }

        return zipSync(files, { level: 0 });
    }

    function imageToCanvas(image:Image, flipY:Bool, maxTextureSize:Int) {
        if (Std.is(image, HTMLImageElement) ||
            Std.is(image, HTMLCanvasElement) ||
            Std.is(image, OffscreenCanvas) ||
            Std.is(image, ImageBitmap)) {

            var scale = maxTextureSize / Math.max(image.width, image.height);

            var canvas = dom.createElement('canvas');
            canvas.width = image.width * Math.min(1, scale);
            canvas.height = image.height * Math.min(1, scale);

            var context = cast(canvas.getContext2d());

            // TODO: We should be able to do this in the UsdTransform2d?

            if (flipY) {
                context.translate(0, canvas.height);
                context.scale(1, -1);
            }

            context.drawImage(image, 0, 0, canvas.width, canvas.height);

            return canvas;
        } else {
            throw new Error('USDZExporter: No valid image data found. Unable to process texture.');
        }
    }

    static var PRECISION:Float = 7;

    static function buildHeader() {
        return '#usda 1.0\n' +
            '( \n' +
            '	customLayerData = {\n' +
            '		string creator = "Three.js USDZExporter"\n' +
            '	} \n' +
            '	defaultPrim = "Root" \n' +
            '	metersPerUnit = 1 \n' +
            '	upAxis = "Y" \n' +
            ') \n' +
            '\n';
    }

    static function buildSceneStart(options:Map<Dynamic>) {
        var alignment = '';
        if (options.includeAnchoringProperties) {
            alignment =
                'token preliminary:anchoring:type = "' + options.ar.anchoring.type + '" \n' +
                'token preliminary:planeAnchoring:alignment = "' + options.ar.planeAnchoring.alignment + '" \n';
        }
        return 'def Xform "Root" \n' +
            '{ \n' +
            '	def Scope "Scenes" ( \n' +
            '		kind = "sceneLibrary" \n' +
            '	) \n' +
            '	{ \n' +
            '		def Xform "Scene" ( \n' +
            '			customData = { \n' +
            '				bool preliminary_collidesWithEnvironment = 0 \n' +
            '				string sceneName = "Scene" \n' +
            '			} \n' +
            '			sceneName = "Scene" \n' +
            '		) \n' +
            '{' + alignment + '\n';
    }

    static function buildSceneEnd() {
        return '		} \n' +
            '	} \n' +
            '} \n' +
            '\n';
    }

    static function buildUSDFileAsString(dataToInsert:String) {
        var output = buildHeader();
        output += dataToInsert;
        return strToU8(output);
    }

    // Xform

    static function buildXform(object:Object3D, geometry:Geometry, material:Material) {
        var name = 'Object_' + object.id;
        var transform = buildMatrix(object.matrixWorld);

        if (object.matrixWorld.determinant() < 0) {
            trace('USDZExporter: USDZ does not support negative scales', object);
        }

        return 'def Xform "' + name + '" (\n' +
            '	prepend references = @./geometries/Geometry_' + geometry.id + '.usda@</Geometry> \n' +
            '	prepend apiSchemas = ["MaterialBindingAPI"] \n' +
            ') \n' +
            '{ \n' +
            '	matrix4d xformOp:transform = ' + transform + ' \n' +
            '	uniform token[] xformOpOrder = ["xformOp:transform"] \n' +
            '\n' +
            '	rel material:binding = </Materials/Material_' + material.id + '> \n' +
            '} \n' +
            '\n';
    }

    static function buildMatrix(matrix:Matrix4) {
        var array = matrix.elements;

        return '( ' + buildMatrixRow(array, 0) + ', ' + buildMatrixRow(array, 4) + ', ' + buildMatrixRow(array, 8) + ', ' + buildMatrixRow(array, 12) + ' )';
    }

    static function buildMatrixRow(array:FloatArray, offset:Int) {
        return '(' + array[offset] + ', ' + array[offset + 1] + ', ' + array[offset + 2] + ', ' + array[offset + 3] + ')';
    }

    // Mesh

    static function buildMeshObject(geometry:Geometry) {
        var mesh = buildMesh(geometry);
        return ' \n' +
            'def "Geometry" \n' +
            '{ \n' +
            mesh +
            '} \n';
    }

    static function buildMesh(geometry:Geometry) {
        var name = 'Geometry';
        var attributes = geometry.attributes;
        var count = attributes.position.count;

        return ' \n' +
            '	def Mesh "' + name + '" \n' +
            '	{ \n' +
            '		int[] faceVertexCounts = [' + buildMeshVertexCount(geometry) + '] \n' +
            '		int[] faceVertexIndices = [' + buildMeshVertexIndices(geometry) + '] \n' +
            '		normal3f[] normals = [' + buildVector3Array(attributes.normal, count) + '] ( \n' +
            '			interpolation = "vertex" \n' +
            '		) \n' +
            '		point3f[] points = [' + buildVector3Array(attributes.position, count) + '] \n' +
            buildPrimvars(attributes) +
            '		uniform token subdivisionScheme = "none" \n' +
            '	} \n';
    }

    static function buildMeshVertexCount(geometry:Geometry) {
        var count = geometry.index != null ? geometry.index.count : geometry.attributes.position.count;

        return Array.make(count / 3, 3).join(', ');
    }

    static function buildMeshVertexIndices(geometry:Geometry) {
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

    static function buildVector3Array(attribute:BufferAttribute, count:Int) {
        if (attribute == null) {
            trace('USDZExporter: Normals missing.');
            return Array.make(count, '(0, 0, 0)').join(', ');
        }

        var array = [];

        for (i in 0...attribute.count) {
            var x = attribute.getX(i);
            var y = attribute.getY(i);
            var z = attribute.getZ(i);

            array.push('(' + x.toPrecision(PRECISION) + ', ' + y.toPrecision(PRECISION) + ', ' + z.toPrecision(PRECISION) + ')');
        }

        return array.join(', ');
    }

    static function buildVector2Array(attribute:BufferAttribute) {
        var array = [];

        for (i in 0...attribute.count) {
            var x = attribute.getX(i);
            var y = attribute.getY(i);

            array.push('(' + x.toPrecision(PRECISION) + ', ' + (1 - y.toPrecision(PRECISION)) + ')');
        }

        return array.join(', ');
    }

    static function buildPrimvars(attributes:Map<String, BufferAttribute>) {
        var string = '';

        for (i in 0...4) {
            var id = i > 0 ? i : '';
            var attribute = attributes.get('uv' + id);

            if (attribute != null) {
                string += ' \n' +
                    '		texCoord2f[] primvars:st' + id + ' = [' + buildVector2Array(attribute) + '] ( \n' +
                    '			interpolation = "vertex" \n' +
                    '		)';
            }
        }

        // vertex colors

        var colorAttribute = attributes.get('color');

        if (colorAttribute != null) {
            var count = colorAttribute.count;

            string += ' \n' +
                '	color3f[] primvars:displayColor = [' + buildVector3Array(colorAttribute, count) + '] ( \n' +
                '		interpolation = "vertex" \n' +
                '	)';
        }

        return string;
    }

    // Materials

    static function buildMaterials(materials:Map<String, Material>, textures:Map<String, Texture>, quickLookCompatible:Bool = false) {
        var array = [];

        for (key in materials) {
            var material = materials[key];

            array.push(buildMaterial(material, textures, quickLookCompatible));
        }

        return 'def "Materials" \n' +
            '{ \n' +
            array.join('') +
            '} \n' +
            '\n';
    }

    static function buildMaterial(material:Material, textures:Map<String, Texture>, quickLookCompatible:Bool = false) {
        // https://graphics.pixar.com/usd/docs/UsdPreviewSurface-Proposal.html

        var pad = '			';
        var inputs = [];
        var samplers = [];

        function buildTexture(texture:Texture, mapType:String, ?color:Color) {
            var id = texture.source.id + '_' + texture.flipY;

            textures[id] = texture;

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

            return ' \n' +
                '	def Shader "PrimvarReader_' + mapType + '" \n' +
                '	{ \n' +
                '		uniform token info:id = "UsdPrimvarReader_float2" \n' +
                '		float2 inputs:fallback = (0.0, 0.0) \n' +
                '		token inputs:varname = "' + uv + '" \n' +
                '		float2 outputs:result \n' +
                '	} \n' +
                '\n' +
                '	def Shader "Transform2d_' + mapType + '" \n' +
                '	{ \n' +
                '		uniform token info:id = "UsdTransform2d" \n' +
                '		token inputs:in.connect = </Materials/Material_' + material.id + '/PrimvarReader_' + mapType + '.outputs:result> \n' +
                '		float inputs:rotation = ' + (rotation * (180 / Math.PI)).toFixed(PRECISION) + ' \n' +
                '		float2 inputs:scale = ' + buildVector2(repeat) + ' \n' +
                '		float2 inputs:translation = ' + buildVector2(offset) + ' \n' +
                '		float2 outputs:result \n' +
                '	} \n' +
                '\n' +
                '	def Shader "Texture_' + texture.id + '_' + mapType + '" \n' +
                '	{ \n' +
                '		uniform token info:id = "UsdUVTexture" \n' +
                '		asset inputs:file = @textures/Texture_' + id + '.png@ \n' +
                '		float2 inputs:st.connect = </Materials/Material_' + material.id + '/Transform2d_' + mapType + '.outputs:result> \n' +
                (color != null ? '		float4 inputs:scale = ' + buildColor4(color) : '') + ' \n' +
                '		token inputs:sourceColorSpace = "' + (texture.colorSpace == NoColorSpace ? 'raw' : 'sRGB') + '" \n' +
                '		token inputs:wrapS = "' + WRAPPINGS[texture.wrapS] + '" \n' +
                '		token inputs:wrapT = "' + WRAPPINGS[texture.wrapT] + '" \n' +
                '		float outputs:r \n
'		float outputs:g \n' +
            '		float outputs:b \n' +
            '		float3 outputs:rgb \n' +
            (material.transparent || material.alphaTest > 0 ? '		float outputs:a' : '') + ' \n' +
            '	} \n';
        }

        if (material.side == DoubleSide) {
            trace('USDZExporter: USDZ does not support double sided materials', material);
        }

        if (material.map != null) {
            inputs.push(pad + 'color3f inputs:diffuseColor.connect = </Materials/Material_' + material.id + '/Texture_' + material.map.id + '_diffuse.outputs:rgb>');

            if (material.transparent) {
                inputs.push(pad + 'float inputs:opacity.connect = </Materials/Material_' + material.id + '/Texture_' + material.map.id + '_diffuse.outputs:a>');
            } else if (material.alphaTest > 0) {
                inputs.push(pad + 'float inputs:opacity.connect = </Materials/Material_' + material.id + '/Texture_' + material.map.id + '_diffuse.outputs:a>');
                inputs.push(pad + 'float inputs:opacityThreshold = ' + material.alphaTest);
            }

            samplers.push(buildTexture(material.map, 'diffuse', material.color));
        } else {
            inputs.push(pad + 'color3f inputs:diffuseColor = ' + buildColor(material.color));
        }

        if (material.emissiveMap != null) {
            inputs.push(pad + 'color3f inputs:emissiveColor.connect = </Materials/Material_' + material.id + '/Texture_' + material.emissiveMap.id + '_emissive.outputs:rgb>');

            samplers.push(buildTexture(material.emissiveMap, 'emissive'));
        } else if (material.emissive.getHex() > 0) {
            inputs.push(pad + 'color3f inputs:emissiveColor = ' + buildColor(material.emissive));
        }

        if (material.normalMap != null) {
            inputs.push(pad + 'normal3f inputs:normal.connect = </Materials/Material_' + material.id + '/Texture_' + material.normalMap.id + '_normal.outputs:rgb>');

            samplers.push(buildTexture(material.normalMap, 'normal'));
        }

        if (material.aoMap != null) {
            inputs.push(pad + 'float inputs:occlusion.connect = </Materials/Material_' + material.id + '/Texture_' + material.aoMap.id + '_occlusion.outputs:r>');

            samplers.push(buildTexture(material.aoMap, 'occlusion'));
        }

        if (material.roughnessMap != null && material.roughness == 1) {
            inputs.push(pad + 'float inputs:roughness.connect = </Materials/Material_' + material.id + '/Texture_' + material.roughnessMap.id + '_roughness.outputs:g>');

            samplers.push(buildTexture(material.roughnessMap, 'roughness'));
        } else {
            inputs.push(pad + 'float inputs:roughness = ' + material.roughness);
        }

        if (material.metalnessMap != null && material.metalness == 1) {
            inputs.push(pad + 'float inputs:metallic.connect = </Materials/Material_' + material.id + '/Texture_' + material.metalnessMap.id + '_metallic.outputs:b>');

            samplers.push(buildTexture(material.metalnessMap, 'metallic'));
        } else {
            inputs.push(pad + 'float inputs:metallic = ' + material.metalness);
        }

        if (material.alphaMap != null) {
            inputs.push(pad + 'float inputs:opacity.connect = </Materials/Material_' + material.id + '/Texture_' + material.alphaMap.id + '_opacity.outputs:r>');
            inputs.push(pad + 'float inputs:opacityThreshold = 0.0001');

            samplers.push(buildTexture(material.alphaMap, 'opacity'));
        } else {
            inputs.push(pad + 'float inputs:opacity = ' + material.opacity);
        }

        if (Std.is(material, MeshPhysicalMaterial)) {
            inputs.push(pad + 'float inputs:clearcoat = ' + material.clearcoat);
            inputs.push(pad + 'float inputs:clearcoatRoughness = ' + material.clearcoatRoughness);
            inputs.push(pad + 'float inputs:ior = ' + material.ior);
        }

        return ' \n' +
            '	def Material "Material_' + material.id + '" \n' +
            '	{ \n' +
            '		def Shader "PreviewSurface" \n' +
            '		{ \n' +
            '			uniform token info:id = "UsdPreviewSurface" \n' +
            inputs.join('\n') +
            '			int inputs:useSpecularWorkflow = 0 \n' +
            '			token outputs:surface \n' +
            '		} \n' +
            '\n' +
            '		token outputs:surface.connect = </Materials/Material_' + material.id + '/PreviewSurface.outputs:surface> \n' +
            '\n' +
            samplers.join('\n') +
            ' \n' +
            '	} \n';
    }

    static function buildColor(color:Color) {
        return '(' + color.r + ', ' + color.g + ', ' + color.b + ')';
    }

    static function buildColor4(color:Color) {
        return '(' + color.r + ', ' + color.g + ', ' + color.b + ', 1.0)';
    }

    static function buildVector2(vector:Vector2) {
        return '(' + vector.x + ', ' + vector.y + ')';
    }

    static function buildCamera(camera:Camera) {
        var name = camera.name != null ? camera.name : 'Camera_' + camera.id;

        var transform = buildMatrix(camera.matrixWorld);

        if (camera.matrixWorld.determinant() < 0) {
            trace('USDZExporter: USDZ does not support negative scales', camera);
        }

        if (Std.is(camera, OrthographicCamera)) {
            return 'def Camera "' + name + '" \n' +
                '{ \n' +
                '	matrix4d xformOp:transform = ' + transform + ' \n' +
                '	uniform token[] xformOpOrder = ["xformOp:transform"] \n' +
                '\n' +
                '	float2 clippingRange = (' + camera.near.toPrecision(PRECISION) + ', ' + camera.far.toPrecision(PRECISION) + ') \n' +
                '	float horizontalAperture = ' + ((Math.abs(camera.left) + Math.abs(camera.right)) * 10).toPrecision(PRECISION) + ' \n' +
                '	float verticalAperture = ' + ((Math.abs(camera.top) + Math.abs(camera.bottom)) * 10).toPrecision(PRECISION) + ' \n' +
                '	token projection = "orthographic" \n' +
                '} \n' +
                '\n';
        } else {
            return 'def Camera "' + name + '" \n' +
                '{ \n' +
                '	matrix4d xformOp:transform = ' + transform + ' \n' +
                '	uniform token[] xformOpOrder = ["xformOp:transform"] \n' +
                '\n' +
                '	float2 clippingRange = (' + camera.near.toPrecision(PRECISION) + ', ' + camera.far.toPrecision(PRECISION) + ') \n' +
                '	float focalLength = ' + camera.getFocalLength().toPrecision(PRECISION) + ' \n' +
                '	float focusDistance = ' + camera.focus.toPrecision(PRECISION) + ' \n' +
                '	float horizontalAperture = ' + camera.getFilmWidth().toPrecision(PRECISION) + ' \n' +
                '	token projection = "perspective" \n' +
                '	float verticalAperture = ' + camera.getFilmHeight().toPrecision(PRECISION) + ' \n' +
                '} \n' +
                '\n';
        }
    }
}