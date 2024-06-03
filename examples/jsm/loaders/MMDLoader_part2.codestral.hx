import js.html.CanvasElement;
import js.html.ImageElement;
import js.html.WebGLRenderingContext;

class MeshBuilder {
    var crossOrigin:String = 'anonymous';
    var geometryBuilder:GeometryBuilder;
    var materialBuilder:MaterialBuilder;

    public function new(manager:Dynamic) {
        this.geometryBuilder = new GeometryBuilder();
        this.materialBuilder = new MaterialBuilder(manager);
    }

    public function setCrossOrigin(crossOrigin:String):MeshBuilder {
        this.crossOrigin = crossOrigin;
        return this;
    }

    public function build(data:Dynamic, resourcePath:String, onProgress:Dynamic, onError:Dynamic):SkinnedMesh {
        var geometry = this.geometryBuilder.build(data);
        var material = this.materialBuilder.setCrossOrigin(this.crossOrigin).setResourcePath(resourcePath).build(data, geometry, onProgress, onError);

        var mesh = new SkinnedMesh(geometry, material);

        var skeleton = new Skeleton(initBones(mesh));
        mesh.bind(skeleton);

        // trace(mesh); // for console debug

        return mesh;
    }
}