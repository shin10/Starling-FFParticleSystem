package 
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Michael Trenkler
	 */
	[SWF(width="1024", height="576", frameRate="60", backgroundColor="#222222")]
	public class Main extends Sprite 
	{
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			//new Startup(stage);
			stage.color = 0xFF000000;
			new FFParticleDemo(stage);
		}
		
	}
	
}