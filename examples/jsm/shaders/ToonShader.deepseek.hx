import three.Color;
import three.Vector3;

class ToonShader1 {
    static var uniforms = {
        'uDirLightPos': { value: new Vector3() },
        'uDirLightColor': { value: new Color( 0xeeeeee ) },
        'uAmbientLightColor': { value: new Color( 0x050505 ) },
        'uBaseColor': { value: new Color( 0xffffff ) }
    };

    static var vertexShader = /* glsl */`
        varying vec3 vNormal;
        varying vec3 vRefract;

        void main() {
            vec4 worldPosition = modelMatrix * vec4( position, 1.0 );
            vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );
            vec3 worldNormal = normalize ( mat3( modelMatrix[0].xyz, modelMatrix[1].xyz, modelMatrix[2].xyz ) * normal );

            vNormal = normalize( normalMatrix * normal );

            vec3 I = worldPosition.xyz - cameraPosition;
            vRefract = refract( normalize( I ), worldNormal, 1.02 );

            gl_Position = projectionMatrix * mvPosition;
        }`;

    static var fragmentShader = /* glsl */`
        uniform vec3 uBaseColor;
        uniform vec3 uDirLightPos;
        uniform vec3 uDirLightColor;
        uniform vec3 uAmbientLightColor;
        varying vec3 vNormal;
        varying vec3 vRefract;

        void main() {
            float directionalLightWeighting = max( dot( normalize( vNormal ), uDirLightPos ), 0.0);
            vec3 lightWeighting = uAmbientLightColor + uDirLightColor * directionalLightWeighting;

            float intensity = smoothstep( - 0.5, 1.0, pow( length(lightWeighting), 20.0 ) );
            intensity += length(lightWeighting) * 0.2;

            float cameraWeighting = dot( normalize( vNormal ), vRefract );
            intensity += pow( 1.0 - length( cameraWeighting ), 6.0 );
            intensity = intensity * 0.2 + 0.3;

            if ( intensity < 0.50 ) {
                gl_FragColor = vec4( 2.0 * intensity * uBaseColor, 1.0 );
            } else {
                gl_FragColor = vec4( 1.0 - 2.0 * ( 1.0 - intensity ) * ( 1.0 - uBaseColor ), 1.0 );
            }

            #include <colorspace_fragment>
        }`;
}

// 其他的ToonShader类可以以类似的方式定义