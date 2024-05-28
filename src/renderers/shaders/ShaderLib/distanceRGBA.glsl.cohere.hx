import haxe.io.Bytes;

class Shader {
    static public function getVertex():Bytes {
        return Bytes.ofString("#version 120\n#define DISTANCE\nvarying vec3 vWorldPosition;\n\nvoid main() {\n\tvWorldPosition = vec3(modelMatrix * vec4(position, 1.0));\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);\n}");
    }

    static public function getFragment():Bytes {
        return Bytes.ofString("#version 120\n#define DISTANCE\nuniform vec3 referencePosition;\nuniform float nearDistance;\nuniform float farDistance;\nvarying vec3 vWorldPosition;\n\nvoid main() {\n\tvec4 diffuseColor = vec4(1.0);\n\tfloat dist = length(vWorldPosition - referencePosition);\n\tdist = (dist - nearDistance) / (farDistance - nearDistance);\n\tdist = clamp(dist, 0.0, 1.0);\n\tgl_FragColor = packDepthToRGBA(dist);\n}");
    }
}