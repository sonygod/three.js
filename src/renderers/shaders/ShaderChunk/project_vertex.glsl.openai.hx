@:glsl
extern abstract ProjectVertexShader : String from {

    inline function project_vertex() {
        var mvPosition:Vec4 = new Vec4(transformed, 1.0);

        #if USE_BATCHING
            mvPosition = batchingMatrix mul mvPosition;
        #end

        #if USE_INSTANCING
            mvPosition = instanceMatrix mul mvPosition;
        #end

        mvPosition = modelViewMatrix mul mvPosition;
        gl_Position = projectionMatrix mul mvPosition;
    }
}