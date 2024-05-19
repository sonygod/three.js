import js.Promise;

class ObjectLoader {

    public function new(resourcePath:String, manager:Loader, crossOrigin:String) {
        // ...
    }

    public function parseImagesAsync(json:Dynamic):Promise<Dynamic> {
        // ...
    }

    public function parseTextures(json:Dynamic, images:Dynamic):Dynamic {
        // ...
    }

    public function parseObject(data:Dynamic, geometries:Dynamic, materials:Dynamic, textures:Dynamic, animations:Dynamic):Dynamic {
        // ...
    }

    public function bindSkeletons(object:Dynamic, skeletons:Dynamic):Void {
        // ...
    }
}

enum TEXTURE_MAPPING {
    UVMapping;
    CubeReflectionMapping;
    CubeRefractionMapping;
    EquirectangularReflectionMapping;
    EquirectangularRefractionMapping;
    CubeUVReflectionMapping;
}

enum TEXTURE_WRAPPING {
    RepeatWrapping;
    ClampToEdgeWrapping;
    MirroredRepeatWrapping;
}

enum TEXTURE_FILTER {
    NearestFilter;
    NearestMipmapNearestFilter;
    NearestMipmapLinearFilter;
    LinearFilter;
    LinearMipmapNearestFilter;
    LinearMipmapLinearFilter;
}