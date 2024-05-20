class ProjectVertexShader {
    static var glsl:String = `
        attribute vec3 transformed;

        uniform mat4 batchingMatrix;
        uniform mat4 instanceMatrix;
        uniform mat4 modelViewMatrix;
        uniform mat4 projectionMatrix;

        void main() {
            vec4 mvPosition = vec4(transformed, 1.0);

            #ifdef USE_BATCHING
                mvPosition = batchingMatrix * mvPosition;
            #endif

            #ifdef USE_INSTANCING
                mvPosition = instanceMatrix * mvPosition;
            #endif

            mvPosition = modelViewMatrix * mvPosition;

            gl_Position = projectionMatrix * mvPosition;
        }
    `;
}