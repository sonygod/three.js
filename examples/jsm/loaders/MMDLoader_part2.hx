package three.js.examples.jsm.loaders;

class MeshBuilder {
    public var crossOrigin:String;
    public var geometryBuilder:GeometryBuilder;
    public var materialBuilder:MaterialBuilder;

    public function new(manager:Dynamic) {
        this.crossOrigin = 'anonymous';
        this.geometryBuilder = new GeometryBuilder();
        this.materialBuilder = new MaterialBuilder(manager);
    }

    public function setCrossOrigin(crossOrigin:String):MeshBuilder {
        this.crossOrigin = crossOrigin;
        return this;
    }

    public function build(data:Dynamic, resourcePath:String, onProgress:Void->Void, onError:Void->Void):SkinnedMesh {
        var geometry = this.geometryBuilder.build(data);
        var material = this.materialBuilder
            .setCrossOrigin(this.crossOrigin)
            .setResourcePath(resourcePath)
            .build(data, geometry, onProgress, onError);

        var mesh = new SkinnedMesh(geometry, material);

        var skeleton = new Skeleton(initBones(mesh));
        mesh.bind(skeleton);

        // trace(mesh); // for console debug

        return mesh;
    }
}