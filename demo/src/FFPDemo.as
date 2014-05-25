package
{
	import de.flintfabrik.starling.display.FFParticleSystem;
	import de.flintfabrik.starling.display.FFParticleSystem.Particle;
	import de.flintfabrik.starling.display.FFParticleSystem.SystemOptions;
	import de.flintfabrik.starling.utils.ColorArgb;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.ResizeEvent;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	public class FFPDemo extends Sprite
	{
		private var firstRun:Boolean = true;
		private var bgr:Image;
		private var systems:Object;
		
		// texture atlas
		[Embed(source="../media/taA.xml",mimeType="application/octet-stream")]
		private static const AtlasXML:Class;
		[Embed(source="../media/taA.png")]
		private static const AtlasTexture:Class;
		private var atlasTexture:Texture = Texture.fromBitmap(new AtlasTexture());
		private var atlasXML:XML = XML(new AtlasXML());
		private var textureAtlas:TextureAtlas = new TextureAtlas(atlasTexture, atlasXML);
		private var texUFO:Texture = textureAtlas.getTexture("ufo");
		
		[Embed(source="../media/starling_bird.xml",mimeType="application/octet-stream")]
		private static const StarlingAtlasXML:Class;
		[Embed(source="../media/starling_bird.png")]
		private static const StarlingAtlasTexture:Class;
		
		// pex config xml files
		
		[Embed(source="../media/starling_bird.pex",mimeType="application/octet-stream")]
		private static const StarlingConfig:Class;
		private var starlingConfig:XML = XML(new StarlingConfig());
		
		[Embed(source="../media/burning.pex",mimeType="application/octet-stream")]
		private static const BurningConfig:Class;
		private var burningConfig:XML = XML(new BurningConfig());
		
		[Embed(source="../media/burningHouseLeft.pex",mimeType="application/octet-stream")]
		private static const BurningHouseLeftConfig:Class;
		private var burningHouseLeftConfig:XML = XML(new BurningHouseLeftConfig());
		
		[Embed(source="../media/burningHouseRight.pex",mimeType="application/octet-stream")]
		private static const BurningHouseRightConfig:Class;
		private var burningHouseRightConfig:XML = XML(new BurningHouseRightConfig());
		
		[Embed(source="../media/smokeScreen.pex",mimeType="application/octet-stream")]
		private static const SmokeScreenConfig:Class;
		private var smokeScreenConfig:XML = XML(new SmokeScreenConfig());
		
		[Embed(source="../media/ufo.pex",mimeType="application/octet-stream")]
		private static const UFOConfig:Class;
		private var ufoConfig:XML = XML(new UFOConfig());
		
		[Embed(source="../media/jets.pex",mimeType="application/octet-stream")]
		private static const JetsConfig:Class;
		private var jetsConfig:XML = XML(new JetsConfig());
		
		[Embed(source="../media/laserChaos.pex",mimeType="application/octet-stream")]
		private static const LaserChaosConfig:Class;
		private var laserChaosConfig:XML = XML(new LaserChaosConfig());
		
		[Embed(source="../media/ash.pex",mimeType="application/octet-stream")]
		private static const AshConfig:Class;
		private var ashConfig:XML = XML(new AshConfig());
		
		[Embed(source="../media/dust.pex",mimeType="application/octet-stream")]
		private static const DustConfig:Class;
		private var dustConfig:XML = XML(new DustConfig());
		
		[Embed(source="../media/sparks.pex",mimeType="application/octet-stream")]
		private static const SparksConfig:Class;
		private var sparksConfig:XML = XML(new SparksConfig());
		
		// particle systems
		
		private var psBuildingLeft:FFParticleSystem;
		private var psBuildingRight:FFParticleSystem;
		private var psSmokeScreen:FFParticleSystem;
		private var psJets:FFParticleSystem;
		private var psUFOs:FFParticleSystem;
		private var psBurningCarFireSmoke:FFParticleSystem;
		private var psLaserChaos:FFParticleSystem;
		private var psBurningCarSparks:FFParticleSystem;
		private var psAshFar:FFParticleSystem;
		private var psAshClose:FFParticleSystem;
		private var psUFOBurningFX:FFParticleSystem;
		private var psDust:FFParticleSystem;
		private var psStarling:FFParticleSystem;
		
		// particle system options
		
		private var soBuildingLeft:SystemOptions = SystemOptions.fromXML(burningHouseLeftConfig, atlasTexture, atlasXML);
		private var soBuildingRight:SystemOptions = SystemOptions.fromXML(burningHouseRightConfig, atlasTexture, atlasXML);
		private var soSmokeScreen:SystemOptions = SystemOptions.fromXML(smokeScreenConfig, atlasTexture, atlasXML).appendFromObject({sortFunction: ageSortDesc});
		private var soJets:SystemOptions = SystemOptions.fromXML(jetsConfig, atlasTexture, atlasXML);
		private var soBurningCarFireSmoke:SystemOptions = SystemOptions.fromXML(burningConfig, atlasTexture, atlasXML).appendFromObject({isAnimated: false, randomStartFrames: true, sourceX: 750, sourceY: 500});
		private var soLaserChaos:SystemOptions = SystemOptions.fromXML(laserChaosConfig, atlasTexture, atlasXML);
		private var soBurningCarSparks:SystemOptions = SystemOptions.fromXML(sparksConfig, atlasTexture, atlasXML);
		private var soAshFar:SystemOptions = SystemOptions.fromXML(ashConfig, atlasTexture, atlasXML);
		private var soAshClose:SystemOptions = (soAshFar.clone()).appendFromObject({maxParticles: 100, gravityY: 75, lifespan: 3, lifespanVariance: 0.1, startParticleSize: 2, startParticleSizeVariance: 1, finishParticleSize: 2, finishParticleSizeVariance: 1});
		private var soUFOBurningFX:SystemOptions = SystemOptions.fromXML(burningConfig, atlasTexture, atlasXML).appendFromObject({sourceX: -100, sourceY: -100});
		private var soUFOs:SystemOptions = SystemOptions.fromXML(ufoConfig, texUFO).appendFromObject({customFunction: customFunctionUFO});
		private var soDust:SystemOptions = SystemOptions.fromXML(dustConfig, atlasTexture, atlasXML);
		private var soStarling:SystemOptions = SystemOptions.fromXML(starlingConfig, Texture.fromBitmap(new StarlingAtlasTexture()), XML(new StarlingAtlasXML())).appendFromObject({customFunction: customFunctionBirds, sortFunction: sizeSort, forceSortFlag: true});
		private var soUFOHit:SystemOptions = soLaserChaos.clone();
		
		public function FFPDemo()
		{
			//trace("create particle systems")
			
			FFParticleSystem.init(4096, false, 4096, 16);
			
			// add event handlers for touch and keyboard
			
			soUFOHit.duration = 0.25;
			soUFOHit.fadeOutTime = 0.1;
			soUFOHit.finishColor = new ColorArgb(1, 1, 1, 1);
			soUFOHit.finishColorVariance = new ColorArgb(1, 1, 1, 0);
			soUFOHit.finishParticleSize = 3;
			soUFOHit.finishParticleSizeVariance = 2;
			soUFOHit.lastFrameName = "ash_8";
			soUFOHit.maxParticles = 300;
			soUFOHit.lifespan = .5;
			soUFOHit.lifespanVariance = .25;
			soUFOHit.startColor = new ColorArgb(1, 1, 1.5, 1);
			soUFOHit.startColorVariance = new ColorArgb(0, 0, .5, 0);
			soUFOHit.sourceVarianceX = 0;
			soUFOHit.sourceVarianceY = 0;
			soUFOHit.updateFrameLUT();
			
			systems = [{'name': 'psBuildingLeft', 'keys': 'Q', 'active': true}, {'name': 'psSmokeScreen', 'keys': 'W', 'active': true}, {'name': 'psJets', 'keys': 'E', 'active': true}, {'name': 'psUFOs', 'keys': 'R', 'active': true}, {'name': 'psUFOBurningFX', 'keys': 'ZY', 'active': true}, {'name': 'psBuildingRight', 'keys': 'T', 'active': true}, {'name': 'psStarling', 'keys': 'U', 'active': false}, {'name': 'psBurningCarFireSmoke', 'keys': 'I', 'active': true}, {'name': 'psAshFar', 'keys': 'O', 'active': true}, {'name': 'psAshClose', 'keys': 'P', 'active': true}, {'name': 'psBurningCarSparks', 'keys': 'A', 'active': true}, {'name': 'psLaserChaos', 'keys': 'S', 'active': true}, {'name': 'psDust', 'keys': 'D', 'active': true}];
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			//addEventListener(Event.ENTER_FRAME, efh);
		}
		
		private function efh(e:Event):void
		{
			var i:int = 3000000;
			while (i)
				--i;
		}
		
		private function stageResize(e:ResizeEvent):void
		{
			var viewPortRectangle:Rectangle = new Rectangle();
			this.scaleX = e.width / bgr.width;
			this.scaleY = e.height / bgr.height;
			this.scaleX = this.scaleY = Math.min(this.scaleX, this.scaleY);
			this.x = (e.width - this.width) / 2;
			this.y = (e.height - this.height) / 2;
			this.clipRect = new Rectangle(bgr.x, bgr.y, bgr.width, bgr.height);
			
			viewPortRectangle.width = e.width;
			viewPortRectangle.height = e.height
			
			// resize the viewport:
			Starling.current.viewPort = viewPortRectangle;
			
			// assign the new stage width and height:
			stage.stageWidth = e.width;
			stage.stageHeight = e.height;
		}
		
		private function onAddedToStage(event:Event):void
		{
			//trace(Starling.context);
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
			bgr = new Image(textureAtlas.getTexture("timesSquare"));
			addChild(bgr);
			
			stage.addEventListener(ResizeEvent.RESIZE, stageResize);
			this.clipRect = new Rectangle(bgr.x, bgr.y, bgr.width, bgr.height);
			Starling.current.viewPort = clipRect;
			stage.stageWidth = clipRect.width;
			stage.stageHeight = clipRect.height;
			
			var t:Timer = new Timer(1000, 1);
			t.addEventListener(TimerEvent.TIMER_COMPLETE, autoStartTimerComplete);
			t.start();
		}
		
		private function autoStartTimerComplete(e:TimerEvent):void
		{
			updateScene(true);
			var fadeTime:Number = 2;
			var delay:Number = .5;
			for (var i:int = this.numChildren - 1; i > 0; --i)
			{
				var s:DisplayObject = getChildAt(i);
				s.alpha = 0;
				var tw:Tween = new Tween(s, fadeTime, Transitions.EASE_IN);
				tw.delay = delay * i;
				tw.animate("alpha", 1);
				Starling.juggler.add(tw);
			}
		}
		
		private function updateScene(advanceTime:Boolean = false):void
		{
			firstRun = false;
			
			for (var i:int = 0; i < systems.length; ++i)
			{
				
				var s:FFParticleSystem = this[systems[i].name];
				if (!s && systems[i].active)
				{
					this[systems[i].name] = s = new FFParticleSystem(this[systems[i].name.replace(/^ps/, 'so')]);
				}
				
				if (systems[i].active)
				{
					addChild(s);
					if (!systems[i].paused)
					{
						s.start();
					}
					if (advanceTime)
						s.advanceTime(s.cycleDuration);
				}
			}
		}
		
		public function customFunctionBirds(birds:Vector.<Particle>, activeBirdsNum:int):void
		{
			var bird:Particle;
			var val:Number;
			
			for (var i:int = 0; i < activeBirdsNum; ++i)
			{
				bird = birds[i];
				
				bird.colorRed = bird.colorGreen = bird.colorBlue = bird.scale * 10 - .4;
			}
			
			var len:int = birds.length;
			for (i = activeBirdsNum; i < len; ++i)
			{
				birds[i].scale = Number.MAX_VALUE;
			}
		}
		
		public function customFunctionUFO(ufos:Vector.<Particle>, activeUfoNum:int):void
		{
			var ufo:Particle;
			var val:Number;
			
			for (var i:int = 0; i < activeUfoNum; ++i)
			{
				ufo = ufos[i];
				
				if (ufo.currentTime > 0.8 * ufo.totalTime)
				{
					ufo.colorRed = 0.2;
					ufo.colorGreen = 0.2;
					ufo.colorBlue = 0.2;
					ufo.radialAcceleration = 0;
					
					var ps:FFParticleSystem;
					if (!ufo.customValues)
					{
						ufo.customValues = {};
						ufo.customValues.rd = Math.random() - 0.5;
						
						soUFOHit.duration = 0.25;
						soUFOHit.angle = Math.random() * 360;
						soUFOHit.angleVariance = Math.random() * 180;
						soUFOHit.speed = 1000 * ufo.scale;
						soUFOHit.speedVariance = 500 * ufo.scale;
						soUFOHit.maxParticles = 400 * ufo.scale;
						soUFOHit.startParticleSize = 200 * ufo.scale;
						soUFOHit.finishParticleSize = 200 * ufo.scale;
						
						ps = new FFParticleSystem(soUFOHit);
						ufo.customValues.psHit = ps;
						ps.addEventListener(Event.COMPLETE, function(e:Event):void
							{
								var ps:FFParticleSystem = e.currentTarget as FFParticleSystem;
								ps.stop();
								ps.dispose();
								if (ufo.customValues)
									ufo.customValues.psHit = null;
							});
						addChild(ps);
						ps.start();
						
						ufo.x += Math.random() * 10 - 5;
						ufo.y += Math.random() * 10;
						ufo.customValues.ea = Math.atan2(-ufo.y, -ufo.x);
						
						ufo.velocityX = (Math.random() < 0.5 ? -1 : 1) * ufo.scale * (Math.random() * 100 + 50);
						ufo.velocityY = Math.random() * ufo.scale * 100 + 25;
						ufo.customValues.rotType = Boolean(Math.random() < 0.5);
						
						/*
						   var intensity:Number = ufo.x>0 && ufo.x < 1024 && ufo.y > 0&& ufo.y <600 ? ufo.scale * 3 : 0;
						   intensity *= intensity;
						   this.x =
						   this.y = 20 * intensity;
						
						   var twX:Tween = new Tween(this, .3+ Math.random(), Transitions.EASE_OUT_ELASTIC);
						   var twY:Tween = new Tween(this, .3+ Math.random(), Transitions.EASE_OUT_ELASTIC);
						   twX.animate('x', 0);
						   twY.animate('y', 0);
						   Starling.juggler.add(twX);
						   Starling.juggler.add(twY);
						 */
					}
					
					ps = ufo.customValues.psHit;
					if (ps && ufo.x > 0 && ufo.x < 1024 && ufo.y > 0 && ufo.y < 600)
					{
						ps.emitterX = ufo.x;
						ps.emitterY = ufo.y;
					}
					
					ufo.velocityY *= 1.01;
					
					if (psUFOBurningFX)
					{
						psUFOBurningFX.emitterX = ufo.x;
						psUFOBurningFX.emitterY = ufo.y;
						psUFOBurningFX.startSize = ufo.scale * 125;
						psUFOBurningFX.endSize = psUFOBurningFX.startSize * 2;
						psUFOBurningFX.emitterXVariance = ufo.scale * 100;
						psUFOBurningFX.speed = 20 * ufo.scale;
						psUFOBurningFX.speedVariance = psUFOBurningFX.speed * .75;
						psUFOBurningFX.lifespanVariance = psUFOBurningFX.lifespan * .5;
						psUFOBurningFX.gravityY = -100 * ufo.scale;
						psUFOBurningFX.gravityX = -50 * ufo.scale;
						psUFOBurningFX.emitAngle = ufo.customValues.ea;
					}
					if (ufo.customValues.rotType)
					{
						ufo.rotation = Math.sin(ufo.currentTime * ufo.currentTime) * 0.03 * ufo.currentTime;
					}
					else
					{
						ufo.rotationDelta += ufo.customValues.rd;
					}
					
					if (ufo.currentTime >= ufo.totalTime && ufo.customValues)
					{
						ufo.customValues = null;
						if (psUFOBurningFX)
						{
							psUFOBurningFX.emitterX = -100;
							psUFOBurningFX.emitterY = -100;
						}
					}
				}
				else
				{
					//ufo.rotation = Math.sin(ufo.currentTime * ufo.currentTime) * 0.07 * ufo.currentTime;
				}
				if (ufo.y > 450)
					ufo.velocityY *= -0.3;
			}
		}
		
		private function onCompleteHandler(e:starling.events.Event):void
		{
			var ps:FFParticleSystem = e.target as FFParticleSystem;
			ps.removeEventListener(Event.COMPLETE, onCompleteHandler);
			ps.removeFromParent();
		}
		
		private function onRemovedFromStage(event:Event):void
		{
			stage.removeEventListener(ResizeEvent.RESIZE, stageResize);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
		}
		
		private function ageSort(a:Particle, b:Particle):Number
		{
			if (a.active && b.active)
			{
				if (a.currentTime < b.currentTime)
					return -1;
				if (a.currentTime > b.currentTime)
					return 1;
			}
			else if (!a.active && !b.active)
			{
				return 0;
			}
			else if (a.active > !b.active)
			{
				return -1;
			}
			else if (a.active > !b.active)
			{
				return -1;
			}
			return 0;
		}
		
		private function ageSortDesc(a:Particle, b:Particle):Number
		{
			if (a.active && b.active)
			{
				if (a.currentTime < b.currentTime)
					return 1;
				if (a.currentTime > b.currentTime)
					return -1;
			}
			else if (a.active && !b.active)
			{
				return -1;
			}
			else if (!a.active && b.active)
			{
				return 1;
			}
			return 0;
		}
		
		private function sizeSort(a:Particle, b:Particle):Number
		{
			if (a.scale > b.scale)
				return 1;
			if (a.scale < b.scale)
				return -1;
			return 0;
		}
		
		private function onKey(event:KeyboardEvent):void
		{
			var s:FFParticleSystem;
			
			if (event.shiftKey)
			{
				if (event.keyCode != 16 && event.keyCode != 17)
				{
					if (event.keyCode == 32)
					{
						if (numChildren > 1)
						{
							//trace("clear all");
							for (var i:int = numChildren - 1; i > 0; --i)
							{
								var obj:DisplayObject = getChildAt(i);
								if (obj is FFParticleSystem)
								{
									sys = FFParticleSystem(obj);
									sys.stop(true);
									sys.dispose();
								}
							}
							for (i = 0; i < systems.length; ++i)
							{
								systems[i].active = false;
								this[systems[i].name] = null;
							}
						}
						else
						{
							//trace("reset all");
							for (i = 0; i < systems.length; ++i)
							{
								if (systems[i].name != "psStarling")
								{
									systems[i].active = true;
									systems[i].paused = false;
								}
							}
						}
					}
					else
					{
						for (i = 0; i < systems.length; ++i)
						{
							if (String(systems[i].keys).indexOf(String.fromCharCode(event.keyCode)) != -1)
							{
								//trace(event.keyCode)
								systems[i].active = !systems[i].active;
								systems[i].paused = false;
								if (!systems[i].active)
								{
									//trace("dispose", systems[i].name)
									// dispose
									obj = FFParticleSystem(this[systems[i].name]);
									if (obj)
									{
										obj.dispose();
										this[systems[i].name] = null;
										systems[i].paused = false;
									}
								}
								else
								{
									//trace("create", systems[i].name);
								}
							}
						}
					}
					updateScene(event.ctrlKey);
				}
			}
			else
			{
				if (event.keyCode == 32)
				{
					var play:Boolean = !sceneHasRunningTweens();
					//trace("toggle all", play)
					for (i = numChildren - 1; i > 0; --i)
					{
						obj = getChildAt(i);
						if (obj is FFParticleSystem)
						{
							play ? FFParticleSystem(obj).resume() : FFParticleSystem(obj).pause();
						}
					}
					for (i = 0; i < systems.length; ++i)
						systems[i].paused = !play;
				}
				else
				{
					for (i = 0; i < systems.length; ++i)
					{
						if (String(systems[i].keys).indexOf(String.fromCharCode(event.keyCode)) != -1)
						{
							var sys:FFParticleSystem = this[systems[i].name];
							if (sys)
							{
								play = !Starling.juggler.contains(sys);
								//trace("toggle", systems[i].name, play)
								play ? sys.resume() : sys.pause();
								systems[i].paused = !play;
							}
							else
							{
								systems[i].active = true;
								systems[i].paused = false;
								updateScene();
							}
						}
					}
				}
			}
		}
		
		private function sceneHasRunningTweens():Boolean
		{
			var result:Boolean = false;
			
			for (var i:int = numChildren - 1; i > 0; --i)
			{
				var obj:DisplayObject = getChildAt(i);
				if (obj is FFParticleSystem)
				{
					if (FFParticleSystem(obj).playing)
						return true;
				}
			}
			
			return false;
		}
	
	}
}