package
{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3DProfile;
	
	import starling.core.Starling;
	
	[SWF(width="1024",height="576",frameRate="60",backgroundColor="#222222")]
	
	public class FFParticleDemo extends Sprite
	{
		private var mStarling:Starling;
		
		public function FFParticleDemo(stage:Stage)
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			Starling.handleLostContext = true;
			
			mStarling = new Starling(FFPDemo, stage, null, null, "auto", Context3DProfile.BASELINE);
			mStarling.enableErrorChecking = isDebugBuild();
			mStarling.showStats = true;
			//mStarling.showStatsAt("right", "top", 1);
			mStarling.start();
			trace("isDebugger", isDebugBuild())
		}
		
		public static function isDebugBuild():Boolean
		{
			return new Error().getStackTrace().search(/:[0-9]+]$/m) > -1;
		}
	}
}