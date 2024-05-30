#if (TONE_MAPPING)

gl_FragColor.rgb = toneMapping(gl_FragColor.rgb);

#end


要导出这段代码，可以将其包装在一个 Haxe 模块中：


class ShaderChunk {
    public static inline var tonemapping_fragment: String = "
        #if (TONE_MAPPING)
        
        gl_FragColor.rgb = toneMapping(gl_FragColor.rgb);
        
        #end
    ";
}