class WebGLConstants {
    public static var GLFeatureName:Map<String, String> = new Map<String, String>([
        ('WEBGL_compressed_texture_astc', 'texture-compression-astc'),
        ('WEBGL_compressed_texture_etc', 'texture-compression-etc2'),
        ('WEBGL_compressed_texture_etc1', 'texture-compression-etc1'),
        ('WEBGL_compressed_texture_pvrtc', 'texture-compression-pvrtc'),
        ('WEBKIT_WEBGL_compressed_texture_pvrtc', 'texture-compression-pvrtc'),
        ('WEBGL_compressed_texture_s3tc', 'texture-compression-bc'),
        ('EXT_texture_compression_bptc', 'texture-compression-bptc'),
        ('EXT_disjoint_timer_query_webgl2', 'timestamp-query'),
    ]);
}