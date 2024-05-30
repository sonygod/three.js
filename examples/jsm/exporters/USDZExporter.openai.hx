package three.js.exporters.usdz;

import haxe.io.Bytes;
import haxe.zip.Compress;
import js.html.CanvasElement;
import js.html.ImageElement;
import js.html.OffscreenCanvas;
import js.html.ImageBitmap;
import js.html.Dom;
import js.lib.Uint8Array;

class USDZExporter {
    public function new() {}

    public function parse(scene:Dynamic, onDone:Void->Void, onError:Void->Void, options:Dynamic = null) {
        parseAsync(scene, options).then(onDone).catchError(onError);
    }

    public function parseAsync(scene:Dynamic, options:Dynamic = {}):Promise<Void> {
        options = Object.assign({
            ar: {
                anchoring: { type: 'plane' },
                planeAnchoring: { alignment: 'horizontal' }
            },
            includeAnchoringProperties: true,
            quickLookCompatible: false,
            maxTextureSize: 1024,
        }, options);

        var files = {};
        var modelFileName = 'model.usda';
        files[modelFileName] = null;

        var output = buildHeader();
        output += buildSceneStart(options);

        var materials = {};
        var textures = {};

        scene.traverseVisible(function(object:Dynamic) {
            if (object.isMesh) {
                var geometry = object.geometry;
                var material = object.material;

                if (material.isMeshStandardMaterial) {
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
                    Console.warn('THREE.USDZExporter: Unsupported material type (USDZ only supports MeshStandardMaterial)', object);
                }
            } else if (object.isCamera) {
                output += buildCamera(object);
            }
        });

        output += buildSceneEnd();
        output += buildMaterials(materials, textures, options.quickLookCompatible);

        files[modelFileName] = strToU8(output);
        output = null;

        for (id in textures.keys()) {
            var texture = textures[id];

            if (texture.isCompressedTexture) {
                texture = decompress(texture);
            }

            var canvas = imageToCanvas(texture.image, texture.flipY, options.maxTextureSize);
            var blob = canvas.toBlob();
            files['textures/Texture_' + id + '.png'] = new Uint8Array(blob);
        }

        // 64 byte alignment
        var offset = 0;
        for (filename in files.keys()) {
            var file = files[filename];
            var headerSize = 34 + filename.length;
            offset += headerSize;

            var offsetMod64 = offset & 63;
            if (offsetMod64 != 4) {
                var padLength = 64 - offsetMod64;
                var padding = new Uint8Array(padLength);
                files[filename] = [file, { extra: { 12345: padding } }];
            }

            offset += file.length;
        }

        return zipSync(files, { level: 0 });
    }
}

function imageToCanvas(image:Dynamic, flipY:Bool, maxTextureSize:Int):CanvasElement {
    if (Type.typeof(image) == TObject || Type.typeof(image) == TClass(CanvasElement) || Type.typeof(image) == TClass(OffscreenCanvas) || Type.typeof(image) == TClass(ImageBitmap)) {
        var scale = maxTextureSize / Math.max(image.width, image.height);

        var canvas = js.Browser.document.createCanvasElement();
        canvas.width = Std.int(image.width * Math.min(1, scale));
        canvas.height = Std.int(image.height * Math.min(1, scale));

        var context = canvas.getContext('2d');

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

// ...

function buildHeader():String {
    return '#usda 1.0\n(\n    customLayerData = {\n        string creator = "Three.js USDZExporter"\n    }\n    defaultPrim = "Root"\n    metersPerUnit = 1\n    upAxis = "Y"\n)\n';
}

function buildSceneStart(options:Dynamic):String {
    var alignment = options.includeAnchoringProperties ? '\n        token preliminary:anchoring:type = "' + options.ar.anchoring.type + '"\n        token preliminary:planeAnchoring:alignment = "' + options.ar.planeAnchoring.alignment + '"' : '';
    return 'def Xform "Root"\n{\n    def Scope "Scenes" (\n        kind = "sceneLibrary"\n    )\n    {\n        def Xform "Scene" (\n            customData = {\n                bool preliminary_collidesWithEnvironment = 0\n                string sceneName = "Scene"\n            }\n            sceneName = "Scene"\n        ){' + alignment + '\n';
}

// ...