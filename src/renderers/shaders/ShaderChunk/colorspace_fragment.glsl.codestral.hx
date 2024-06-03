class ShaderChunk {
    public function colorspace_fragment():String {
        return "gl_FragColor = linearToOutputTexel( gl_FragColor );";
    }
}