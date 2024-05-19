package three.test.unit.src.loaders;

import haxe.unit.TestCase;
import three.loaders.ObjectLoader;
import three.loaders.Loader;

class ObjectLoaderTest {

	public function new() {}

	@Test
	public function testExtending() {
		var object = new ObjectLoader();
		assertTrue(object instanceof Loader, 'ObjectLoader extends from Loader');
	}

	@Test
	public function testInstancing() {
		var object = new ObjectLoader();
		assertTrue(object != null, 'Can instantiate an ObjectLoader.');
	}

	@Test
	public function testLoad() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testLoadAsync() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testParse() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testParseAsync() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testParseShapes() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testParseSkeletons() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testParseGeometries() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testParseMaterials() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testParseAnimations() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testParseImages() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testParseImagesAsync() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testParseTextures() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testParseObject() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

	@Test
	public function testBindSkeletons() {
		assertTrue(false, 'everything\'s gonna be alright');
	}

}