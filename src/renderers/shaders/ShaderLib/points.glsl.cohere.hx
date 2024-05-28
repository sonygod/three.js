package;

import js.WebGL.WebGLProgram;

class Shader {
    static public var vertex:String = "
        uniform float size;
        uniform float scale;

        attribute vec3 position;
        attribute vec3 normal;
        attribute vec2 uv;

        #ifdef USE_COLOR
            attribute vec3 color;
        #endif

        #ifdef USE_MORPHTARGETS
            attribute vec3 morphTarget0;
            attribute vec3 morphTarget1;
            attribute vec3 morphTarget2;
            attribute vec3 morphTarget3;
            attribute vec3 morphTarget4;
            attribute vec3 morphTarget5;
            attribute vec3 morphTarget6;
            attribute vec3 morphTarget7;
        #endif

        #ifdef USE_MORPHNORMALS
            attribute vec3 morphNormal0;
            attribute vec3 morphNormal1;
            attribute vec3 morphNormal2;
            attribute vec3 morphNormal3;
        #endif

        #ifdef USE_SKINNING
            attribute vec4 skinIndex;
            attribute vec4 skinWeight;
        #endif

        #ifdef USE_INSTANCE_COLOR
            attribute vec3 instanceColor;
        #endif

        #ifdef USE_POINTS_UV
            attribute vec2 uv2;
        #endif

        varying vec2 vUv;

        #ifdef USE_COLOR
            varying vec3 vColor;
        #endif

        #ifdef USE_MORPHTARGETS
            varying vec3 vMorphTarget0;
            varying vec3 vMorphTarget1;
            varying vec3 vMorphTarget2;
            varying vec3 vMorphTarget3;
            varying vec3 vMorphTarget4;
            varying vec3 vMorphTarget5;
            varying vec3 vMorphTarget6;
            varying vec3 vMorphTarget7;
        #endif

        #ifdef USE_MORPHNORMALS
            varying vec3 vMorphNormal0;
            varying vec3 vMorphNormal1;
            varying vec3 vMorphNormal2;
            varying vec3 vMorphNormal3;
        #endif

        #ifdef USE_SKINNING
            uniform mat4 bindMatrix;
            uniform mat4 bindMatrixInverse;
        #endif

        #ifdef BONE_TEXTURE
            uniform sampler2D boneTexture;
            uniform int boneTextureSize;
            mat4 getBoneMatrix(const in float i) {
                float j = i * 4.0;
                float x = mod(j, float(boneTextureSize));
                float y = floor(j / float(boneTextureSize));
                float dx = 1.0 / float(boneTextureSize);
                float dy = 1.0 / float(boneTextureSize);
                y = dy * (y + 0.5);
                vec4 v1 = texture2D(boneTexture, vec2(dx * (x + 0.5), y));
                vec4 v2 = texture2D(boneTexture, vec2(dx * (x + 1.5), y));
                vec4 v3 = texture2D(boneTexture, vec2(dx * (x + 2.5), y));
                vec4 v4 = texture2D(boneTexture, vec2(dx * (x + 3.5), y));
                mat4 bone = mat4(v1, v2, v3, v4);
                return bone;
            }
        #endif

        #ifdef USE_SKINNING
            mat4 getBoneMatrix(const in int i) {
                mat4 bone = mat4(
                    2.0, 0.0, 0.0, 0.0,
                    0.0, 2.0, 0.0, 0.0,
                    0.0, 0.0, 2.0, 0.0,
                    0.0, 0.0, 0.0, 1.0
                );
                bone = bone * bindMatrix;
                return bone * bindMatrixInverse;
            }
        #endif

        #ifdef USE_SKINNING
            void rotateVec3(inout vec3 v, const in mat4 boneMat) {
                v = (boneMat * vec4(v, 0.0)).xyz;
            }
        #endif

        void main() {
            #ifdef USE_SKINNING
                mat4 boneMatX = getBoneMatrix(skinIndex.x);
                mat4 boneMatY = getBoneMatrix(skinIndex.y);
                mat4 boneMatZ = getBoneMatrix(skinIndex.z);
                mat4 boneMatW = getBoneMatrix(skinIndex.w);
                float sx = skinWeight.x;
                float sy = skinWeight.y;
                float sz = skinWeight.z;
                float sw = skinWeight.w;
                mat4 boneMat = mat4(
                    sx, sy, sz, sw,
                    sx, sy, sz, sw,
                    sx, sy, sz, sw,
                    sx, sy, sz, sw
                );
                boneMat = boneMatX * boneMat;
                boneMat = boneMatY * boneMat;
                boneMat = boneMatZ * boneMat;
                boneMat = boneMatW * boneMat;
                vec4 localPosition = boneMat * vec4(position, 1.0);
                #ifdef USE_MORPHNORMALS
                    rotateVec3(morphNormal0, boneMat);
                    rotateVec3(morphNormal1, boneMat);
                    rotateVec3(morphNormal2, boneMat);
                    rotate normMorphNormal = vec3(morphNormal0 + morphNormal1 + morphNormal2 + morphNormal3);
                    vMorphNormal0 = normMorphNormal * morphTargetInfluences[0];
                    vMorphNormal1 = normMorphNormal * morphTargetInfluences[1];
                    vMorphNormal2 = normMorphNormal * morphTargetInfluences[2];
                    vMorphNormal3 = normMorphNormal * morphTargetInfluences[3];
                #endif
                #ifdef USE_MORPHTARGETS
                    rotateVec3(morphTarget0, boneMat);
                    rotateVec3(morphTarget1, boneMat);
                    rotateVec3(morphTarget2, boneMat);
                    rotateVec3(morphTarget3, boneMat);
                    rotateVec3(morphTarget4, boneMat);
                    rotateVec3(morphTarget5, boneMat);
                    rotateVec3(morphTarget6, boneMat);
                    rotateVec3(morphTarget7, boneMat);
                    vMorphTarget0 = morphTarget0 * morphTargetInfluences[0];
                    vMorphTarget1 = morphTarget1 * morphTargetInfluences[1];
                    vMorphTarget2 = morphTarget2 * morphTargetInfluences[2];
                    vMorphTarget3 = morphTarget3 * morphTargetInfluences[3];
                    vMorphTarget4 = morphTarget4 * morphTargetInfluences[4];
                    vMorphTarget5 = morphTarget5 * morphTargetInfluences[5];
                    vMorphTarget6 = morphTarget6 * morphTargetInfluences[6];
                    vMorphTarget7 = morphTarget7 * morphTargetInfluences[7];
                #endif
                localPosition = localPosition * morphTargetInfluences[0];
                localPosition = localPosition + (morphTarget0 * morphTargetInfluences[1]);
                localPosition = localPosition + (morphTarget1 * morphTargetInfluences[2]);
                localPosition = localPosition + (morphTarget2 * morphTargetInfluences[3]);
                localPosition = localPosition + (morphTarget3 * morphTargetInfluences[4]);
                localPosition = localPosition + (morphTarget4 * morphTargetInfluences[5]);
                localPosition = localPosition + (morphTarget5 * morphTargetInfluences[6]);
                localPosition = localPosition + (morphTarget6 * morphTargetInfluences[7]);
                gl_Position = projectionMatrix * modelViewMatrix * localPosition;
            #else
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            #endif
            #ifdef USE_COLOR
                vColor = color;
            #endif
            #ifdef USE_MORPHTARGETS
                vMorphTarget0 = morphTarget0;
                vMorphTarget1 = morphTarget1;
                vMorphTarget2 = morphTarget2;
                vMorphTarget3 = morphTarget3;
                vMorphTarget4 = morphTarget4;
                vMorphTarget5 = morphTarget5;
                vMorphTarget6 = morphTarget6;
                vMorphTarget7 = morphTarget7;
            #endif
            #ifdef USE_MORPHNORMALS
                vMorphNormal0 = morphNormal0;
                vMorphNormal1 = morphNormal1;
                vMorphNormal2 = morphNormal2;
                vMorphNormal3 = morphNormal3;
            #endif
            #ifdef USE_INSTANCE_COLOR
                vColor = instanceColor;
            #endif
            #ifdef USE_POINTS_UV
                vUv = uv2;
            #else
                vUv = uv;
            #endif
            gl_PointSize = size;
            #ifdef USE_SIZEATTENUATION
                bool isPerspective = isPerspectiveMatrix(projectionMatrix);
                if (isPerspective) gl_PointSize *= (scale / -mvPosition.z);
            #endif
        }
    ";

    static public var fragment:String = "
        uniform vec3 diffuse;
        uniform float opacity;

        #ifdef USE_MAP
            uniform sampler2D map;
        #endif

        #ifdef USE_ALPHAMAP
            uniform sampler2D alphaMap;
        #endif

        #ifdef USE_AOMAP
            uniform sampler2D aoMap;
        #endif

        #ifdef USE_SPECULARMAP
            uniform sampler2D specularMap;
        #endif

        #ifdef USE_EMISSIVEMAP
            uniform sampler2D emissiveMap;
        #endif

        #ifdef USE_LIGHTMAP
            uniform sampler2D lightMap;
            uniform float lightMapIntensity;
        #endif

        #ifdef USE_COLOR
            varying vec3 vColor;
        #endif

        #ifdef USE_MORPHTARGETS
            varying vec3 vMorphTarget0;
            varying vec3 vMorphTarget1;
            varying vec3 vMorphTarget2;
            varying vec3 vMorphTarget3;
            varying vec3 vMorphTarget4;
            varying vec3 vMorphTarget5;
            varying vec3 vMorphTarget6;
            varying vec3 vMorphTarget7;
        #endif

        #ifdef USE_MORPHNORMALS
            varying vec3 vMorphNormal0;
            varying vec3 vMorphNormal1;
            varying vec3 vMorphNormal2;
            varying vec3 vMorphNormal3;
        #endif

        #ifdef USE_POINTS_UV
            varying vec2 vUv;
        #endif

        #ifdef USE_MAP
            vec4 texelColor;
        #endif

        #ifdef USE_ALPHAMAP
            vec4 alphaMapColor;
        #endif

        #ifdef USE_AOMAP
            vec4 aoMapColor;
        #endif

        #ifdef USE_SPECULARMAP
            vec4 specularMapColor;
        #endif

        #ifdef USE_EMISSIVEMAP
            vec4 emissiveMapColor;
        #endif

        #ifdef USE_LIGHTMAP
            vec4 lightMapColor;
        #endif

        #ifdef USE_COLOR
            vec3 outgoingLight = vColor;
        #else
            vec3 outgoingLight = vec3(1.0);
        #endif

        void main() {
            #ifdef USE_MAP
                texelColor = texture2D(map, vUv);
                texelColor = mapTexelToLinear(texelColor);
                outgoingLight = outgoingLight * texelColor.xyz;
            #endif
            #ifdef USE_ALPHAMAP
                alphaMapColor = texture2D(alphaMap, vUv);
                outgoingLight = mix(outgoingLight, outgoingLight * alphaMapColor.xyz, alphaMapColor.w);
            #endif
            #ifdef USE_AOMAP
                aoMapColor = texture2D(aoMap, vUv);
                outgoingLight = mix(outgoingLight, outgoingLight * aoMapColor.xxx, aoMapColor.w);
            #endif
            #ifdef USE_SPECULARMAP
                specularMapColor = texture2D(specularMap, vUv);
                specular = specularMapColor.r;
            #endif
            #ifdef USE_EMISSIVEMAP
                emissiveMapColor = texture2D(emissiveMap, vUv);
                emissive = emissiveMapColor.rgb;
            #endif
            #ifdef USE_LIGHTMAP
                lightMapColor = texture2D(lightMap, vUv);
                outgoingLight = mix(outgoingLight, lightMapColor.rgb * lightMapIntensity, lightMapColor.a);
            #endif
            #ifdef USE_COLOR
                outgoingLight = diffuse * vec3(0.5) + outgoingLight * vec3(0.5);
            #else
                outgoingLight = diffuse;
            #endif
            #ifdef FLAT_SHADED
                vec3 fdx = dFdx(vViewPosition);
                vec3 fdy = dFdy(vViewPosition);
                vec3 normal = normalize(cross(fdx, fdy));
            #else
                vec3 normal = normalize(vNormal);
                #ifdef DOUBLE_SIDED
                    normal = normal * (float(-1.0 + 2.0 * float(gl_FrontFacing)));
                #endif
            #endif
            #ifdef USE_MORPHTARGETS
                normal += vMorphNormal0;
                normal += vMorphNormal1;
                normal += vMorphNormal2;
                normal += vMorphNormal3;
                normal = normalize(normal);
            #endif
            #ifdef USE_MORPHNORMALS
                normal += vMorphNormal0;
                normal += vMorphNormal1;
                normal += vMorphNormal2;
                normal += vMorphNormal3;
                normal = normalize(normal);
            #endif
            #ifdef USE_POINTS_UV
                float pointCoord = distance(vUv, vec2(0.5));
                if (pointCoord > 0.4) discard;
            #endif
            gl_FragColor = vec4(outgoingLight, opacity);
        }
    ";
}