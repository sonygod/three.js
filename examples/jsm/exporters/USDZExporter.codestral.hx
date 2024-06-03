import js.Browser.document;
import js.html.CanvasElement;
import js.html.ImageElement;
import js.html.HTMLCanvasElement;
import js.html.HTMLImageElement;
import js.html.OffscreenCanvas;
import js.html.ImageBitmap;
import js.html.Blob;
import js.html.CanvasRenderingContext2D;
import js.html.CanvasRenderingContext2D.ImageSmoothingQuality;
import js.html.CanvasRenderingContext2D.LineCap;
import js.html.CanvasRenderingContext2D.LineJoin;
import js.ArrayBuffer;

import three.NoColorSpace;
import three.DoubleSide;
import three.MeshStandardMaterial;
import three.Mesh;
import three.Camera;
import three.OrthographicCamera;
import three.PerspectiveCamera;
import three.Geometry;
import three.Vector3;
import three.Vector2;
import three.Color;
import three.Texture;
import three.CompressedTexture;
import three.MeshPhysicalMaterial;
import three.Object3D;
import three.Scene;
import three.Material;
import three.Texture;
import three.Vector2;
import three.Vector3;
import three.Matrix4;

import fflate.strToU8;
import fflate.zipSync;

import TextureUtils.decompress;

class USDZExporter {

    public function new() {}

    public function parse(scene:Scene, onDone:Dynamic, onError:Dynamic, options:Dynamic) {
        this.parseAsync(scene, options).then(onDone).catch(onError);
    }

    public async function parseAsync(scene:Scene, options:Dynamic = null) {
        if (options == null) options = {
            ar: {
                anchoring: { type: 'plane' },
                planeAnchoring: { alignment: 'horizontal' }
            },
            includeAnchoringProperties: true,
            quickLookCompatible: false,
            maxTextureSize: 1024,
        };

        var files:haxe.ds.StringMap<Dynamic> = new haxe.ds.StringMap();
        var modelFileName:String = 'model.usda';
        files.set(modelFileName, null);

        var output:String = buildHeader();
        output += buildSceneStart(options);

        var materials:haxe.ds.StringMap<Material> = new haxe.ds.StringMap();
        var textures:haxe.ds.StringMap<Texture> = new haxe.ds.StringMap();

        scene.traverseVisible(function(object:Object3D) {
            if (Std.is(object, Mesh)) {
                var geometry:Geometry = object.geometry;
                var material:Material = object.material;

                if (Std.is(material, MeshStandardMaterial)) {
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
                    trace('THREE.USDZExporter: Unsupported material type (USDZ only supports MeshStandardMaterial)', object);
                }
            } else if (Std.is(object, Camera)) {
                output += buildCamera(object);
            }
        });

        output += buildSceneEnd();
        output += buildMaterials(materials, textures, options.quickLookCompatible);

        files.set(modelFileName, strToU8(output));
        output = null;

        for (id in textures.keys()) {
            var texture:Texture = textures.get(id);

            if (texture.isCompressedTexture === true) {
                texture = decompress(texture);
            }

            var canvas:CanvasElement = imageToCanvas(texture.image, texture.flipY, options.maxTextureSize);
            var blob:Blob = await new Promise(function(resolve) {
                canvas.toBlob(resolve, 'image/png', 1);
            });

            files.set('textures/Texture_' + id + '.png', new Uint8Array(await blob.arrayBuffer()));
        }

        var offset:Int = 0;

        for (filename in files.keys()) {
            var file:Dynamic = files.get(filename);
            var headerSize:Int = 34 + filename.length;

            offset += headerSize;

            var offsetMod64:Int = offset & 63;

            if (offsetMod64 !== 4) {
                var padLength:Int = 64 - offsetMod64;
                var padding:Uint8Array = new Uint8Array(padLength);

                files.set(filename, [file, { extra: { 12345: padding } }]);
            }

            offset = file.length;
        }

        return zipSync(files, { level: 0 });
    }
}

static function imageToCanvas(image:Dynamic, flipY:Bool, maxTextureSize:Int):CanvasElement {
    if (Std.is(image, HTMLImageElement) || Std.is(image, HTMLCanvasElement) || Std.is(image, OffscreenCanvas) || Std.is(image, ImageBitmap)) {
        var scale:Float = maxTextureSize / Math.max(image.width, image.height);

        var canvas:CanvasElement = document.createElement('canvas');
        canvas.width = image.width * Math.min(1, scale);
        canvas.height = image.height * Math.min(1, scale);

        var context:CanvasRenderingContext2D = canvas.getContext('2d');

        if (flipY === true) {
            context.translate(0, canvas.height);
            context.scale(1, -1);
        }

        context.drawImage(image, 0, 0, canvas.width, canvas.height);

        return canvas;
    } else {
        throw new js.Error('THREE.USDZExporter: No valid image data found. Unable to process texture.');
    }
}

// Rest of the functions...