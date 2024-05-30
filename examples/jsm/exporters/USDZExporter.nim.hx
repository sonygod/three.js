import three.js.examples.jsm.exporters.USDZExporter;

class Main {
    static function main() {
        var scene = new three.js.Scene();
        var exporter = new USDZExporter();
        exporter.parse(scene, function(result) trace(result), function(error) trace(error), {});
    }
}

// File path: three.js/examples/jsm/exporters/USDZExporter.hx
package three.js.examples.jsm.exporters;

import three.js.core.Object3D;
import three.js.core.Scene;
import three.js.materials.Material;
import three.js.math.Matrix4;
import three.js.math.Vector3;
import three.js.objects.Mesh;
import three.js.utils.TextureUtils;

class USDZExporter {

    public function new() {}

    public function parse(scene:Scene, onDone:Dynamic, onError:Dynamic, options:Dynamic) {
        this.parseAsync(scene, options).then(onDone).catch(onError);
    }

    public function parseAsync(scene:Scene, options:Dynamic = {}) {
        options = {
            ar: {
                anchoring: { type: 'plane' },
                planeAnchoring: { alignment: 'horizontal' }
            },
            includeAnchoringProperties: true,
            quickLookCompatible: false,
            maxTextureSize: 1024,
        };

        var files = {};
        var modelFileName = 'model.usda';

        // model file should be first in USDZ archive so we init it here
        files[modelFileName] = null;

        var output = buildHeader();

        output += buildSceneStart(options);

        var materials = {};
        var textures = {};

        scene.traverseVisible(function(object) {
            if (object.isMesh) {
                var geometry = object.geometry;
                var material = object.material;

                if (material.isMeshStandardMaterial) {
                    var geometryFileName = 'geometries/Geometry_' + geometry.id + '.usda';

                    if (!(geometryFileName in files)) {
                        var meshObject = buildMeshObject(geometry);
                        files[geometryFileName] = buildUSDFileAsString(meshObject);
                    }

                    if (!(material.uuid in materials)) {
                        materials[material.uuid] = material;
                    }

                    output += buildXform(object, geometry, material);
                } else {
                    trace('THREE.USDZExporter: Unsupported material type (USDZ only supports MeshStandardMaterial)', object);
                }
            } else if (object.isCamera) {
                output += buildCamera(object);
            }
        });

        output += buildSceneEnd();

        output += buildMaterials(materials, textures, options.quickLookCompatible);

        files[modelFileName] = strToU8(output);
        output = null;

        for (id in textures) {
            var texture = textures[id];

            if (texture.isCompressedTexture === true) {
                texture = TextureUtils.decompress(texture);
            }

            var canvas = imageToCanvas(texture.image, texture.flipY, options.maxTextureSize);
            var blob = new Promise(function(resolve) canvas.toBlob(resolve, 'image/png', 1));

            files['textures/Texture_' + id + '.png'] = new Uint8Array(await blob.arrayBuffer());
        }

        // 64 byte alignment
        // https://github.com/101arrowz/fflate/issues/39#issuecomment-777263109

        var offset = 0;

        for (filename in files) {
            var file = files[filename];
            var headerSize = 34 + filename.length;

            offset += headerSize;

            var offsetMod64 = offset & 63;

            if (offsetMod64 !== 4) {
                var padLength = 64 - offsetMod64;
                var padding = new Uint8Array(padLength);

                files[filename] = [file, {extra: {12345: padding}}];
            }

            offset = file.length;
        }

        return zipSync(files, {level: 0});
    }

    private function buildHeader() {
        return '#usda 1.0\n(\n\tcustomLayerData = {\n\t\tstring creator = "Three.js USDZExporter"\n\t}\n\tdefaultPrim = "Root"\n\tmetersPerUnit = 1\n\tupAxis = "Y"\n)\n\n';
    }

    private function buildSceneStart(options) {
        var alignment = options.includeAnchoringProperties === true ? '\n\t\ttoken preliminary:anchoring:type = "' + options.ar.anchoring.type + '"\n\t\ttoken preliminary:planeAnchoring:alignment = "' + options.ar.planeAnchoring.alignment + '"\n' : '';
        return 'def Xform "Root"\n{\n\tdef Scope "Scenes" (