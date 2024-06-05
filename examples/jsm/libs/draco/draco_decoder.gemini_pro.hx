import draco_decoder.draco_decoder;

class DracoDecoderModule {

	static var ready:Promise<draco_decoder.DracoDecoder> = new Promise((resolve, reject) => {
		draco_decoder.DracoDecoder.ready.then(resolve).catch(reject);
	});

	static function isVersionSupported(versionString:String):Bool {
		if(versionString.indexOf(".") == -1) return false;
		var version = versionString.split(".");
		if(version.length < 2 || version.length > 3) return false;
		if(version[0] == "1" && version[1] >= "0" && version[1] <= "5") return true;
		if(version[0] != "0" || version[1] > "10") return false;
		return true;
	}
}

if(typeof(exports) != 'undefined') exports.DracoDecoderModule = DracoDecoderModule;