class DracoEncoderModule {

	static function isVersionSupported(versionString:String):Bool {
		if (typeof versionString != "string") return false;
		var version = versionString.split(".");
		if (version.length < 2 || version.length > 3) return false;
		if (version[0] == "1" && version[1] >= "0" && version[1] <= "3") return true;
		if (version[0] != "0" || version[1] > "10") return false;
		return true;
	}

	// ... rest of the Haxe code ... 
}