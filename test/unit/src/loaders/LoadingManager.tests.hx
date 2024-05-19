package three.test.unit.src.loaders;

import haxe.unit.TestCase;
import three.loaders.LoadingManager;
import three.loaders.Loader;

class LoadingManagerTests extends TestCase {
    
    public function new() {
        super();
    }

    public function testInstancing() {
        var object = new LoadingManager();
        assertTrue(object != null, 'Can instantiate a LoadingManager.');
    }

    public function testOnStart() {
        // Refer to #5689 for the reason why we don't set .onStart
        // in the constructor
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testOnLoad() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testOnProgress() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testOnError() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testItemStart() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testItemEnd() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testItemError() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testResolveURL() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testSetURLModifier() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testAddHandler() {
        // addHandler( regex, loader )
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testRemoveHandler() {
        // removeHandler( regex )
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testGetHandler() {
        // getHandler( file )
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testAddHandlerGetHandlerRemoveHandler() {
        var loadingManager = new LoadingManager();
        var loader = new Loader();

        var regex1 = ~/\.jpg$/i;
        var regex2 = ~/\.jpg$/gi;

        loadingManager.addHandler(regex1, loader);

        assertEquals(loader, loadingManager.getHandler('foo.jpg'), 'Returns the expected loader.');
        assertNull(loadingManager.getHandler('foo.jpg.png'), 'Returns null since the correct file extension is not at the end of the file name.');
        assertNull(loadingManager.getHandler('foo.jpeg'), 'Returns null since file extension is wrong.');

        loadingManager.removeHandler(regex1);
        loadingManager.addHandler(regex2, loader);

        assertEquals(loader, loadingManager.getHandler('foo.jpg'), 'Returns the expected loader when using a regex with "g" flag.');
        assertEquals(loader, loadingManager.getHandler('foo.jpg'), 'Returns the expected loader when using a regex with "g" flag. Test twice, see #17920.');
    }
}