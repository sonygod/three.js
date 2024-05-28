package three.renderers.shaders.ShaderChunk;

#if USE_LOGDEPTHBUF

@-glsl("vert", 5)
function vertexShader():Void {
    varying(vFragDepth:Float);
    varying(vIsPerspective:Float);
}

#end