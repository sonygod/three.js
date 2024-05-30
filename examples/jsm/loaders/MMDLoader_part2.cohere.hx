class MeshBuilder {
    var crossOrigin:String = 'anonymous';
    var geometryBuilder:GeometryBuilder;
    var materialBuilder:MaterialBuilder;

    public function new(manager:Manager) {
        geometryBuilder = GeometryBuilder();
        materialBuilder = MaterialBuilder(manager);
    }

    public function setCrossOrigin(crossOrigin:String):MeshBuilder {
        this.crossOrigin = crossOrigin;
        return this;
    }

    public function build(data:Dynamic, resourcePath:String, onProgress:Dynamic -> Void, onError:Dynamic -> Void):SkinnedMesh {
        var geometry = geometryBuilder.build(data);
        var material = materialBuilder
            .setCrossOrigin(crossOrigin)
            .setResourcePath(resourcePath)
            .build(data, geometry, onProgress, onError);

        var mesh = SkinnedMesh(geometry, material);
        var skeleton = Skeleton(initBones(mesh));
        mesh.bind(skeleton);

        return mesh;
    }
}