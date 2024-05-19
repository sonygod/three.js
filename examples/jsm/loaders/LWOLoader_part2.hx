Here is the converted Haxe code:
```
package three.js.examples.jm.loaders;

import three.js.loaders.MaterialParser;
import three.js.loaders.GeometryParser;
import three.js.core.Material;
import three.js.core.Points;
import three.js.core.LineSegments;
import three.js.core.Mesh;
import three.js.core.PointsMaterial;
import three.js.core.LineBasicMaterial;

class LWOTreeParser {
    private var textureLoader:TextureLoader;
    private var materials:Array<Material>;
    private var meshes:Array<Mesh>;
    private var defaultLayerName:String;

    public function new(textureLoader:TextureLoader) {
        this.textureLoader = textureLoader;
    }

    public function parse(modelName:String):{ materials:Array<Material>, meshes:Array<Mesh> } {
        this.materials = new MaterialParser(this.textureLoader).parse();
        this.defaultLayerName = modelName;

        this.meshes = this.parseLayers();

        return { materials: this.materials, meshes: this.meshes };
    }

    private function parseLayers():Array<Mesh> {
        var meshes:Array<Mesh> = [];
        var finalMeshes:Array<Mesh> = [];
        var geometryParser:GeometryParser = new GeometryParser();

        for (layer in _lwoTree.layers) {
            var geometry = geometryParser.parse(layer.geometry, layer);
            var mesh = this.parseMesh(geometry, layer);
            meshes[layer.number] = mesh;

            if (layer.parent == -1) {
                finalMeshes.push(mesh);
            } else {
                meshes[layer.parent].add(mesh);
            }
        }

        this.applyPivots(finalMeshes);

        return finalMeshes;
    }

    private function parseMesh(geometry:Any, layer:Any):Mesh {
        var mesh:Mesh;
        var materials:Array<Material> = this.getMaterials(geometry.userData.matNames, layer.geometry.type);

        if (layer.geometry.type == 'points') {
            mesh = new Points(geometry, materials);
        } else if (layer.geometry.type == 'lines') {
            mesh = new LineSegments(geometry, materials);
        } else {
            mesh = new Mesh(geometry, materials);
        }

        if (layer.name != null) {
            mesh.name = layer.name;
        } else {
            mesh.name = this.defaultLayerName + '_layer_' + layer.number;
        }

        mesh.userData.pivot = layer.pivot;

        return mesh;
    }

    private function applyPivots(meshes:Array<Mesh>):Void {
        for (mesh in meshes) {
            mesh.traverse(function(child:Any) {
                var pivot:Array<Float> = child.userData.pivot;

                child.position.x += pivot[0];
                child.position.y += pivot[1];
                child.position.z += pivot[2];

                if (child.parent != null) {
                    var parentPivot:Array<Float> = child.parent.userData.pivot;
                    child.position.x -= parentPivot[0];
                    child.position.y -= parentPivot[1];
                    child.position.z -= parentPivot[2];
                }
            });
        }
    }

    private function getMaterials(namesArray:Array<String>, type:String):Array<Material> {
        var materials:Array<Material> = [];

        for (i in 0...namesArray.length) {
            materials[i] = this.getMaterialByName(namesArray[i]);
        }

        if (type == 'points' || type == 'lines') {
            for (i in 0...materials.length) {
                var spec:Any = {
                    color: materials[i].color
                };

                if (type == 'points') {
                    spec.size = 0.1;
                    spec.map = materials[i].map;
                    materials[i] = new PointsMaterial(spec);
                } else if (type == 'lines') {
                    materials[i] = new LineBasicMaterial(spec);
                }
            }
        }

        if (materials.length == 1) {
            return materials[0];
        }

        return materials;
    }

    private function getMaterialByName(name:String):Material {
        for (material in this.materials) {
            if (material.name == name) {
                return material;
            }
        }

        return null;
    }
}
```
Note that I had to make some assumptions about the types and structures of the `TextureLoader`, `MaterialParser`, `GeometryParser`, `Points`, `LineSegments`, `Mesh`, `PointsMaterial`, and `LineBasicMaterial` classes, as they are not defined in the provided code. You may need to adjust the types and imports accordingly.