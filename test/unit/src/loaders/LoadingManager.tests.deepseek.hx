package;

import three.src.loaders.LoadingManager;
import three.src.loaders.Loader;
import js.Lib;

class LoadingManagerTest {
    static function main() {
        var loadingManager = new LoadingManager();
        var loader = new Loader();

        var regex1 = /\.jpg$/i;
        var regex2 = /\.jpg$/gi;

        loadingManager.addHandler(regex1, loader);

        Lib.assert(loadingManager.getHandler('foo.jpg') == loader, 'Returns the expected loader.');
        Lib.assert(loadingManager.getHandler('foo.jpg.png') == null, 'Returns null since the correct file extension is not at the end of the file name.');
        Lib.assert(loadingManager.getHandler('foo.jpeg') == null, 'Returns null since file extension is wrong.');

        loadingManager.removeHandler(regex1);
        loadingManager.addHandler(regex2, loader);

        Lib.assert(loadingManager.getHandler('foo.jpg') == loader, 'Returns the expected loader when using a regex with "g" flag.');
        Lib.assert(loadingManager.getHandler('foo.jpg') == loader, 'Returns the expected loader when using a regex with "g" flag. Test twice, see #17920.');
    }
}