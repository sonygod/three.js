class ShaderLib {
    static var vertex:String = /* glsl */`
        #define PHONG

        varying vec3 vViewPosition;

        // ... 其他的 include 文件内容 ...

        void main() {

            // ... 其他的 include 文件内容 ...

            vViewPosition = - mvPosition.xyz;

            // ... 其他的 include 文件内容 ...

        }
    `;

    static var fragment:String = /* glsl */`
        #define PHONG

        uniform vec3 diffuse;
        uniform vec3 emissive;
        uniform vec3 specular;
        uniform float shininess;
        uniform float opacity;

        // ... 其他的 include 文件内容 ...

        void main() {

            vec4 diffuseColor = vec4( diffuse, opacity );
            // ... 其他的 include 文件内容 ...

            ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
            vec3 totalEmissiveRadiance = emissive;

            // ... 其他的 include 文件内容 ...

            // accumulation
            // ... 其他的 include 文件内容 ...

            // modulation
            // ... 其他的 include 文件内容 ...

            vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;

            // ... 其他的 include 文件内容 ...

        }
    `;
}