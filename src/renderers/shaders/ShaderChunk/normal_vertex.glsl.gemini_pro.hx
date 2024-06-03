class Glsl {
  static function get(code:String):String {
    return code;
  }
}

class Main {
  static function main() {
    var code = Glsl.get(`
      #ifndef FLAT_SHADED // normal is computed with derivatives when FLAT_SHADED

        vNormal = normalize( transformedNormal );

        #ifdef USE_TANGENT

          vTangent = normalize( transformedTangent );
          vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );

        #endif

      #endif
    `);
    trace(code);
  }
}