import three.Group;
import three.Loaders.FileLoader;
import three.Loaders.Loader;
import three.Loaders.LoadingManager;
import three.Loaders.ColladaLoader;
import js.lib.fflate.Inflate;

class KMZLoader extends Loader {
	
	public function new(manager:LoadingManager) {
		super(manager);
	}
	
	override public function load(url:String, onLoad:Dynamic->Void, ?onProgress:Int->Void, ?onError:Dynamic->Void):Void {
		
		final loader = new FileLoader(manager);
		loader.setPath(path);
		loader.setResponseType("arraybuffer");
		loader.setRequestHeader(requestHeader);
		loader.setWithCredentials(withCredentials);
		loader.load(url, 
			function(data:js.lib.ArrayBuffer) {
				try {
					onLoad(parse(data));
				} catch(e:Dynamic) {
					if (onError != null) {
						onError(e);
					} else {
						trace('Error: $e');
					}
					manager.itemError(url);
				}
			},
			onProgress,
			onError
		);
		
	}
	
	function parse(data:js.lib.ArrayBuffer):Group {
		
		final zip = Inflate.unzip(new haxe.io.Bytes(new haxe.io.BytesInput(new js.lib.Uint8Array(data))));
		
		function findFile(url:String):Null<haxe.io.Bytes> {
			for (path in zip.keys()) {
				if (path.lastIndexOf(url) == path.length - url.length) {
					return zip.get(path);
				}
			}
			return null;
		}
		
		final manager = new LoadingManager();
		manager.setURLModifier(function(url:String) {
			final image = findFile(url);
			if (image != null) {
				final bytes = new haxe.io.Bytes(image.length, image);
				final base64 = bytes.toBase64();
				return 'data:image/png;base64,$base64';
			} else {
				return url;
			}
		});
		
		if (zip.exists('doc.kml')) {
			
			final xmlString = zip.get('doc.kml').toString();
			final xml = new haxe.xml.Parser().parse(xmlString);
			final model = xml.firstElement().elementsNamed('Placemark')
				.flatMap(function(placemark) return placemark.elementsNamed('Model'))
				.flatMap(function(model) return model.elementsNamed('Link'))
				.flatMap(function(link) return link.elementsNamed('href'))
				.first();
				
			if (model != null) {
				final loader = new ColladaLoader(manager);
				return loader.parse(zip.get(model.innerData).toString());
			}
			
		} else {
			
			trace('KMZLoader: Missing doc.kml file.');
			
			for (path in zip.keys()) {
				if (path.split('.').pop().toLowerCase() == 'dae') {
					final loader = new ColladaLoader(manager);
					return loader.parse(zip.get(path).toString());
				}
			}
			
		}
		
		trace('KMZLoader: Couldn\'t find .dae file.');
		return new Group();
		
	}
	
}