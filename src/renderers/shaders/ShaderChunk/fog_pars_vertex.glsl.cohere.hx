var glsl = '''
#if defined(USE_FOG)

	varying float vFogDepth;

#endif
''';

class Main {
	public static function main() {
		trace(glsl);
	}
}