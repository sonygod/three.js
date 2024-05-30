class LightsParsBeginGLSL {
  public static inline var shader: String = '
    uniform bool receiveShadow;
    uniform vec3 ambientLightColor;

    #if defined( USE_LIGHT_PROBES )
      uniform vec3 lightProbe[ 9 ];
    #endif

    vec3 shGetIrradianceAt( in vec3 normal, in vec3 shCoefficients[ 9 ] ) {
      float x = normal.x, y = normal.y, z = normal.z;

      vec3 result = shCoefficients[ 0 ] * 0.886227;
      result += shCoefficients[ 1 ] * 2.0 * 0.511664 * y;
      result += shCoefficients[ 2 ] * 2.0 * 0.511664 * z;
      result += shCoefficients[ 3 ] * 2.0 * 0.511664 * x;
      result += shCoefficients[ 4 ] * 2.0 * 0.429043 * x * y;
      result += shCoefficients[ 5 ] * 2.0 * 0.429043 * y * z;
      result += shCoefficients[ 6 ] * ( 0.743125 * z * z - 0.247708 );
      result += shCoefficients[ 7 ] * 2.0 * 0.429043 * x * z;
      result += shCoefficients[ 8 ] * 0.429043 * ( x * x - y * y );

      return result;
    }

    vec3 getLightProbeIrradiance( const in vec3 lightProbe[ 9 ], const in vec3 normal ) {
      vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
      vec3 irradiance = shGetIrradianceAt( worldNormal, lightProbe );
      return irradiance;
    }

    vec3 getAmbientLightIrradiance( const in vec3 ambientLightColor ) {
      vec3 irradiance = ambientLightColor;
      return irradiance;
    }

    float getDistanceAttenuation( const in float lightDistance, const in float cutoffDistance, const in float decayExponent ) {
      #if defined ( LEGACY_LIGHTS )
        if ( cutoffDistance > 0.0 && decayExponent > 0.0 ) {
          return pow( saturate( - lightDistance / cutoffDistance + 1.0 ), decayExponent );
        }
        return 1.0;
      #else
        float distanceFalloff = 1.0 / max( pow( lightDistance, decayExponent ), 0.01 );
        if ( cutoffDistance > 0.0 ) {
          distanceFalloff *= pow2( saturate( 1.0 - pow4( lightDistance / cutoffDistance ) ) );
        }
        return distanceFalloff;
      #endif
    }

    float getSpotAttenuation( const in float coneCosine, const in float penumbraCosine, const in float angleCosine ) {
      return smoothstep( coneCosine, penumbraCosine, angleCosine );
    }

    #if NUM_DIR_LIGHTS > 0
      struct DirectionalLight {
        vec3 direction;
        vec3 color;
      };

      uniform DirectionalLight directionalLights[ NUM_DIR_LIGHTS ];

      void getDirectionalLightInfo( const in DirectionalLight directionalLight, out IncidentLight light ) {
        light.color = directionalLight.color;
        light.direction = directionalLight.direction;
        light.visible = true;
      }
    #endif

    #if NUM_POINT_LIGHTS > 0
      struct PointLight {
        vec3 position;
        vec3 color;
        float distance;
        float decay;
      };

      uniform PointLight pointLights[ NUM_POINT_LIGHTS ];

      void getPointLightInfo( const in PointLight pointLight, const in vec3 geometryPosition, out IncidentLight light ) {
        vec3 lVector = pointLight.position - geometryPosition;
        light.direction = normalize( lVector );
        float lightDistance = length( lVector );
        light.color = pointLight.color;
        light.color *= getDistanceAttenuation( lightDistance, pointLight.distance, pointLight.decay );
        light.visible = ( light.color != vec3( 0.0 ) );
      }
    #endif

    #if NUM_SPOT_LIGHTS > 0
      struct SpotLight {
        vec3 position;
        vec3 direction;
        vec3 color;
        float distance;
        float decay;
        float coneCos;
        float penumbraCos;
      };

      uniform SpotLight spotLights[ NUM_SPOT_LIGHTS ];

      void getSpotLightInfo( const in SpotLight spotLight, const in vec3 geometryPosition, out IncidentLight light ) {
        vec3 lVector = spotLight.position - geometryPosition;
        light.direction = normalize( lVector );
        float angleCos = dot( light.direction, spotLight.direction );
        float spotAttenuation = getSpotAttenuation( spotLight.coneCos, spotLight.penumbraCos, angleCos );
        if ( spotAttenuation > 0.0 ) {
          float lightDistance = length( lVector );
          light.color = spotLight.color * spotAttenuation;
          light.color *= getDistanceAttenuation( lightDistance, spotLight.distance, spotLight.decay );
          light.visible = ( light.color != vec3( 0.0 ) );
        } else {
          light.color = vec3( 0.0 );
          light.visible = false;
        }
      }
    #endif

    #if NUM_RECT_AREA_LIGHTS > 0
      struct RectAreaLight {
        vec3 color;
        vec3 position;
        vec3 halfWidth;
        vec3 halfHeight;
      };

      uniform sampler2D ltc_1;
      uniform sampler2D ltc_2;

      uniform RectAreaLight rectAreaLights[ NUM_RECT_AREA_LIGHTS ];
    #endif

    #if NUM_HEMI_LIGHTS > 0
      struct HemisphereLight {
        vec3 direction;
        vec3 skyColor;
        vec3 groundColor;
      };

      uniform HemisphereLight hemisphereLights[ NUM_HEMI_LIGHTS ];

      vec3 getHemisphereLightIrradiance( const in HemisphereLight hemiLight, const in vec3 normal ) {
        float dotNL = dot( normal, hemiLight.direction );
        float hemiDiffuseWeight = 0.5 * dotNL + 0.5;
        vec3 irradiance = mix( hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight );
        return irradiance;
      }
    #endif
  ';
}