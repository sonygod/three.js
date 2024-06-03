class GLTFTextureTransformExtension {

    public static var name:String = EXTENSIONS.KHR_TEXTURE_TRANSFORM;

    public static function extendTexture(texture:Texture, transform:Dynamic):Texture {
        if ((js.Reflect.hasField(transform, "texCoord") == false || transform.texCoord == texture.channel)
            && js.Reflect.hasField(transform, "offset") == false
            && js.Reflect.hasField(transform, "rotation") == false
            && js.Reflect.hasField(transform, "scale") == false) {

            // See https://github.com/mrdoob/three.js/issues/21819.
            return texture;
        }

        var newTexture = texture.clone();

        if (js.Reflect.hasField(transform, "texCoord")) {
            newTexture.channel = transform.texCoord;
        }

        if (js.Reflect.hasField(transform, "offset")) {
            newTexture.offset.fromArray(transform.offset);
        }

        if (js.Reflect.hasField(transform, "rotation")) {
            newTexture.rotation = transform.rotation;
        }

        if (js.Reflect.hasField(transform, "scale")) {
            newTexture.repeat.fromArray(transform.scale);
        }

        newTexture.needsUpdate = true;

        return newTexture;
    }
}