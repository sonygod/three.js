package openfl._internal.renderer.opengl;

class SpecularMapFragment {
    public static var code:String =
        "#ifdef USE_SPECULARMAP \n" +
        "	uniform sampler2D specularMap; \n" +
        "#endif";
}