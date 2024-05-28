var shader = {
    glsl: function() {
        return 'void main() { \n' +
            'gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 ); \n' +
            '}';
    }
};