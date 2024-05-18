package three.js.examples.jsm.shaders;

import three COLOR;
import three VECTOR3;

/**
 * Currently contains:
 *
 *	toon1
 *	toon2
 *	hatching
 *	dotted
 */

class ToonShader1 {
    public var uniforms: {
        uDirLightPos: { value: VECTOR3 },
        uDirLightColor: { value: COLOR },
        uAmbientLightColor: { value: COLOR },
        uBaseColor: { value: COLOR }
    };

    public var vertexShader: String = "
        varying vec3 vNormal;
        varying vec3 vRefract;

        void main() {
            vec4 worldPosition = modelMatrix * vec4(position, 1.0);
            vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
            vec3 worldNormal = normalize(mat3(modelMatrix[0].xyz, modelMatrix[1].xyz, modelMatrix[2].xyz) * normal);

            vNormal = normalize(normalMatrix * normal);

            vec3 I = worldPosition.xyz - cameraPosition;
            vRefract = refract(normalize(I), worldNormal, 1.02);

            gl_Position = projectionMatrix * mvPosition;
        }
    ";

    public var fragmentShader: String = "
        uniform vec3 uBaseColor;
        uniform vec3 uDirLightPos;
        uniform vec3 uDirLightColor;
        uniform vec3 uAmbientLightColor;

        varying vec3 vNormal;
        varying vec3 vRefract;

        void main() {
            float directionalLightWeighting = max(dot(normalize(vNormal), uDirLightPos), 0.0);
            vec3 lightWeighting = uAmbientLightColor + uDirLightColor * directionalLightWeighting;

            float intensity = smoothstep(-0.5, 1.0, pow(length(lightWeighting), 20.0));
            intensity += length(lightWeighting) * 0.2;

            float cameraWeighting = dot(normalize(vNormal), vRefract);
            intensity += pow(1.0 - length(cameraWeighting), 6.0);
            intensity = intensity * 0.2 + 0.3;

            if (intensity < 0.50) {
                gl_FragColor = vec4(2.0 * intensity * uBaseColor, 1.0);
            } else {
                gl_FragColor = vec4(1.0 - 2.0 * (1.0 - intensity) * (1.0 - uBaseColor), 1.0);
            }

            #include <colorspace_fragment>
        }
    ";
}

class ToonShader2 {
    public var uniforms: {
        uDirLightPos: { value: VECTOR3 },
        uDirLightColor: { value: COLOR },
        uAmbientLightColor: { value: COLOR },
        uBaseColor: { value: COLOR },
        uLineColor1: { value: COLOR },
        uLineColor2: { value: COLOR },
        uLineColor3: { value: COLOR },
        uLineColor4: { value: COLOR }
    };

    public var vertexShader: String = "
        varying vec3 vNormal;

        void main() {
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            vNormal = normalize(normalMatrix * normal);
        }
    ";

    public var fragmentShader: String = "
        uniform vec3 uBaseColor;
        uniform vec3 uLineColor1;
        uniform vec3 uLineColor2;
        uniform vec3 uLineColor3;
        uniform vec3 uLineColor4;

        uniform vec3 uDirLightPos;
        uniform vec3 uDirLightColor;

        uniform vec3 uAmbientLightColor;

        varying vec3 vNormal;

        void main() {
            float camera = max(dot(normalize(vNormal), vec3(0.0, 0.0, 1.0)), 0.4);
            float light = max(dot(normalize(vNormal), uDirLightPos), 0.0);

            gl_FragColor = vec4(uBaseColor, 1.0);

            if (length(uAmbientLightColor + uDirLightColor * light) < 1.00) {
                gl_FragColor *= vec4(uLineColor1, 1.0);
            }

            if (length(uAmbientLightColor + uDirLightColor * camera) < 0.50) {
                gl_FragColor *= vec4(uLineColor2, 1.0);
            }

            #include <colorspace_fragment>
        }
    ";
}

class ToonShaderHatching {
    public var uniforms: {
        uDirLightPos: { value: VECTOR3 },
        uDirLightColor: { value: COLOR },
        uAmbientLightColor: { value: COLOR },
        uBaseColor: { value: COLOR },
        uLineColor1: { value: COLOR },
        uLineColor2: { value: COLOR },
        uLineColor3: { value: COLOR },
        uLineColor4: { value: COLOR }
    };

    public var vertexShader: String = "
        varying vec3 vNormal;

        void main() {
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            vNormal = normalize(normalMatrix * normal);
        }
    ";

    public var fragmentShader: String = "
        uniform vec3 uBaseColor;
        uniform vec3 uLineColor1;
        uniform vec3 uLineColor2;
        uniform vec3 uLineColor3;
        uniform vec3 uLineColor4;

        uniform vec3 uDirLightPos;
        uniform vec3 uDirLightColor;

        uniform vec3 uAmbientLightColor;

        varying vec3 vNormal;

        void main() {
            float directionalLightWeighting = max(dot(normalize(vNormal), uDirLightPos), 0.0);
            vec3 lightWeighting = uAmbientLightColor + uDirLightColor * directionalLightWeighting;

            gl_FragColor = vec4(uBaseColor, 1.0);

            if (length(lightWeighting) < 1.00) {
                if (mod(gl_FragCoord.x + gl_FragCoord.y, 10.0) == 0.0) {
                    gl_FragColor = vec4(uLineColor1, 1.0);
                }
            }

            if (length(lightWeighting) < 0.75) {
                if (mod(gl_FragCoord.x - gl_FragCoord.y, 10.0) == 0.0) {
                    gl_FragColor = vec4(uLineColor2, 1.0);
                }
            }

            if (length(lightWeighting) < 0.50) {
                if (mod(gl_FragCoord.x + gl_FragCoord.y - 5.0, 10.0) == 0.0) {
                    gl_FragColor = vec4(uLineColor3, 1.0);
                }
            }

            if (length(lightWeighting) < 0.3465) {
                if (mod(gl_FragCoord.x - gl_FragCoord.y - 5.0, 10.0) == 0.0) {
                    gl_FragColor = vec4(uLineColor4, 1.0);
                }
            }

            #include <colorspace_fragment>
        }
    ";
}

class ToonShaderDotted {
    public var uniforms: {
        uDirLightPos: { value: VECTOR3 },
        uDirLightColor: { value: COLOR },
        uAmbientLightColor: { value: COLOR },
        uBaseColor: { value: COLOR },
        uLineColor1: { value: COLOR }
    };

    public var vertexShader: String = "
        varying vec3 vNormal;

        void main() {
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            vNormal = normalize(normalMatrix * normal);
        }
    ";

    public var fragmentShader: String = "
        uniform vec3 uBaseColor;
        uniform vec3 uLineColor1;
        uniform vec3 uLineColor2;
        uniform vec3 uLineColor3;
        uniform vec3 uLineColor4;

        uniform vec3 uDirLightPos;
        uniform vec3 uDirLightColor;

        uniform vec3 uAmbientLightColor;

        varying vec3 vNormal;

        void main() {
            float directionalLightWeighting = max(dot(normalize(vNormal), uDirLightPos), 0.0);
            vec3 lightWeighting = uAmbientLightColor + uDirLightColor * directionalLightWeighting;

            gl_FragColor = vec4(uBaseColor, 1.0);

            if (length(lightWeighting) < 1.00) {
                if ((mod(gl_FragCoord.x, 4.001) + mod(gl_FragCoord.y, 4.0)) > 6.00) {
                    gl_FragColor = vec4(uLineColor1, 1.0);
                }
            }

            if (length(lightWeighting) < 0.50) {
                if ((mod(gl_FragCoord.x + 2.0, 4.001) + mod(gl_FragCoord.y + 2.0, 4.0)) > 6.00) {
                    gl_FragColor = vec4(uLineColor1, 1.0);
                }
            }

            #include <colorspace_fragment>
        }
    ";
}

// Export the shaders
@:expose("ToonShader1")
extern class ToonShader1 {
    public function new();
}

@:expose("ToonShader2")
extern class ToonShader2 {
    public function new();
}

@:expose("ToonShaderHatching")
extern class ToonShaderHatching {
    public function new();
}

@:expose("ToonShaderDotted")
extern class ToonShaderDotted {
    public function new();
}