var glsl = #if js // Cross-compiling to JavaScript
'#ifdef USE_LOGDEPTHBUF

	varying float vFragDepth;
	varying float vIsPerspective;

#endif
';
#else
'';
#end;

class MyClass {
	public static function main() {
		trace(glsl);
	}
}