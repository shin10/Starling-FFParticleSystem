// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package de.flintfabrik.starling.extensions
{
	import de.flintfabrik.starling.extensions.FFParticleSystem.Frame;
	import de.flintfabrik.starling.extensions.FFParticleSystem.Particle;
	import de.flintfabrik.starling.extensions.FFParticleSystem.SystemOptions;
	import de.flintfabrik.starling.extensions.FFParticleSystem.core.ffparticlesystem_internal;
	import de.flintfabrik.starling.extensions.FFParticleSystem.rendering.FFParticleEffect;
	import de.flintfabrik.starling.extensions.FFParticleSystem.styles.*;
	import de.flintfabrik.starling.extensions.FFParticleSystem.utils.ColorArgb;
	import de.flintfabrik.starling.extensions.FFParticleSystem.utils.FFPS_LUT;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import starling.animation.IAnimatable;
	import starling.animation.Juggler;
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.errors.MissingContextError;
	import starling.events.Event;
	import starling.filters.FragmentFilter;
	import starling.rendering.Painter;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.MatrixUtil;
	
	use namespace ffparticlesystem_internal;
	
	/**
	 * <p>The FFParticleSystem is an extension for the <a target="_top" href="http://starling-framework.org">Starling Framework v2</a>.
	 * It's basically an optimized version of the original ParticleSystem.
	 *
	 * <p>In addition it comes with a few new features:
	 * <ul>
	 *   <li>particle pooling</li>
	 *   <li>multi buffering</li>
	 *   <li>batching (of particle systems)</li>
	 *   <li>animated Texture loops</li>
	 *   <li>random start frame</li>
	 *   <li>ATF support</li>
	 *   <li>filter support</li>
	 *   <li>optional custom sorting, code and variables</li>
	 *   <li>calculating exact bounds (optional)</li>
	 *   <li>spawnTime</li>
	 *   <li>fadeInTime</li>
	 *   <li>fadeOutTime</li>
	 *   <li>emit angle aligned particle rotation</li>
	 * </ul>
	 * </p>
	 *
	 * <p>This extension has been kindly sponsored by the fabulous <a target="_top" href="http://colinnorthway.com/">Colin Northway</a>. :)</p>
	 *
	 * <a target="_top" href="http://www.flintfabrik.de/blog/">Live Demo</a>
	 *
	 * @author Michael Trenkler
	 * @see http://flintfabrik.de
	 * @see #FFParticleSystem()
	 * @see #initPool() FFParticleSystem.initPool()
	 */
	public class FFParticleSystem extends DisplayObject implements IAnimatable
	{
		public static const EMITTER_TYPE_GRAVITY:int = 0;
		public static const EMITTER_TYPE_RADIAL:int = 1;
		
		/**
		 * If the systems duration exceeds as well as all particle lifespans, a complete event is fired and
		 * the system will be stopped. If this value is set to true, the particles will be returned to the pool.
		 * This does not affect any manual calls of stop.
		 * @see #start()
		 * @see #stop()
		 */
		public static var autoClearOnComplete:Boolean = true;
		/**
		 * If the systems duration exceeds as well as all particle lifespans, a complete event is fired and
		 * the system will be stopped. If this value is set to true, the particles will be returned to the pool.
		 * This does not affect any manual calls of stop.
		 * @see #start()
		 * @see #stop()
		 */
		public var autoClearOnComplete:Boolean = FFParticleSystem.autoClearOnComplete;
		/**
		 * Forces the the sort flag for custom sorting on every frame instead of setting it when particles are removed.
		 */
		public var forceSortFlag:Boolean = false;
		
		/**
		 * Set this Boolean to automatically add/remove the system to/from juggler, on calls of start()/stop().
		 * @see #start()
		 * @see #stop()
		 * @see #defaultJuggler
		 * @see #juggler()
		 */
		public static var automaticJugglerManagement:Boolean = true;
		
		/**
		 * Default juggler to use when <a href="#automaticJugglerManagement">automaticJugglerManagement</a>
		 * is active (by default this value is the Starling's juggler).
		 * Setting this value will affect only new particle system instances.
		 * Juggler to use can be also manually set by particle system instance.
		 * @see #automaticJugglerManagement
		 * @see #juggler()
		 */
		public static var defaultJuggler:Juggler = Starling.juggler;
		private var __juggler:Juggler = FFParticleSystem.defaultJuggler;
		
		private var __batched:Boolean = false;
		private var __bounds:Rectangle;
		private var __disposed:Boolean = false;
		private var __numParticles:int = 0;
		private var __numBatchedParticles:int = 0;
		private var __playing:Boolean = false;
		
		private var __batching:Boolean = true;
		private var __completed:Boolean;
		private var __customFunction:Function = undefined;
		private var __fadeInTime:Number = 0;
		private var __fadeOutTime:Number = 0;
		private var __filter:FragmentFilter = null;
		private var __randomStartFrames:Boolean = false;
		private var __smoothing:String = TextureSmoothing.BILINEAR;
		private var __sortFunction:Function = undefined;
		private var __spawnTime:Number = 0;
		private var __alpha:Number = 1;
		private var __texture:Texture;
		private var __tinted:Boolean = false;
		private var __premultipliedAlpha:Boolean = false;
		private var __exactBounds:Boolean = false;
		private var __effect:FFParticleEffect;
		private var __style:FFParticleStyle;
		
		private static var $defaultEffect:Class;
		private static var $defaultStyle:Class;
		
		/**
		 * Default styles to test against for fallback initialization.
		 */
		public static var styles:Vector.<Class> = Vector.<Class>([FFInstancedParticleStyle, FFParticleStyle]);
		
		ffparticlesystem_internal static var registeredEffects:Vector.<Class> = new Vector.<Class>(0, false);
		
		ffparticlesystem_internal static function registerEffect(effectClass:Class):void
		{
			if (registeredEffects.indexOf(effectClass) == -1)
				registeredEffects.push(effectClass);
		}
		
		ffparticlesystem_internal static function unregisterEffect(effectClass:Class):void
		{
			var idx:int = registeredEffects.indexOf(effectClass);
			if (idx != -1)
				registeredEffects.splice(idx, 1);
		}
		
		public static function get defaultStyle():Class
		{
			if ($defaultStyle)
			{
				return $defaultStyle;
			}
			
			for each (var c:Class in styles)
			{
				if (c && c.effectType && c.effectType.isSupported)
				{
					trace('[FFParticleSystem] defaultStyle set to', c);
					$defaultStyle = c as Class;
					$defaultEffect = $defaultStyle.effectType;
					return $defaultStyle;
				}
			}
			trace('[FFParticleSystem] no supported style found')
			$defaultStyle = FFParticleStyle as Class;
			$defaultEffect = $defaultStyle.effectType;
			return $defaultStyle;
		}
		
		public static function set defaultStyle(styleClass:Class):void
		{
			if (styleClass == null)
			{
				$defaultStyle = null;
				$defaultEffect = null;
			}
			else if (styleClass.effectType.isSupported)
			{
				trace('[FFParticleSystem] defaultStyle set to', styleClass);
				$defaultStyle = styleClass;
				$defaultEffect = styleClass.effectType;
			}
		}
		
		// particles / data / buffers
		
		private static var $particlePool:Vector.<Particle>;
		private static var $poolSize:uint = 0;
		private var __particles:Vector.<Particle>;
		
		// emitter configuration
		private var __emitterType:int; // emitterType
		private var __emitterXVariance:Number; // sourcePositionVariance x
		private var __emitterYVariance:Number; // sourcePositionVariance y
		
		// particle configuration
		private var __maxNumParticles:int; // maxParticles
		private var __lifespan:Number; // particleLifeSpan
		private var __lifespanVariance:Number; // particleLifeSpanVariance
		private var __startSize:Number; // startParticleSize
		private var __startSizeVariance:Number; // startParticleSizeVariance
		private var __endSize:Number; // finishParticleSize
		private var __endSizeVariance:Number; // finishParticleSizeVariance
		private var __emitAngle:Number; // angle
		private var __emitAngleVariance:Number; // angleVariance
		private var __emitAngleAlignedRotation:Boolean = false;
		private var __startRotation:Number; // rotationStart
		private var __startRotationVariance:Number; // rotationStartVariance
		private var __endRotation:Number; // rotationEnd
		private var __endRotationVariance:Number; // rotationEndVariance
		
		// gravity configuration
		private var __speed:Number; // speed
		private var __speedVariance:Number; // speedVariance
		private var __gravityX:Number; // gravity x
		private var __gravityY:Number; // gravity y
		private var __radialAcceleration:Number; // radialAcceleration
		private var __radialAccelerationVariance:Number; // radialAccelerationVariance
		private var __tangentialAcceleration:Number; // tangentialAcceleration
		private var __tangentialAccelerationVariance:Number; // tangentialAccelerationVariance
		
		// radial configuration 
		private var __maxRadius:Number; // maxRadius
		private var __maxRadiusVariance:Number; // maxRadiusVariance
		private var __minRadius:Number; // minRadius
		private var __minRadiusVariance:Number; // minRadiusVariance
		private var __rotatePerSecond:Number; // rotatePerSecond
		private var __rotatePerSecondVariance:Number; // rotatePerSecondVariance
		
		// color configuration
		private var __startColor:ColorArgb = new ColorArgb(1, 1, 1, 1); // startColor
		private var __startColorVariance:ColorArgb = new ColorArgb(0, 0, 0, 0); // startColorVariance
		private var __endColor:ColorArgb = new ColorArgb(1, 1, 1, 1); // finishColor
		private var __endColorVariance:ColorArgb = new ColorArgb(0, 0, 0, 0); // finishColorVariance
		
		// texture animation
		private var __animationLoops:Number = 1.0;
		private var __animationLoopLength:int = 1;
		private var __firstFrame:uint = 0;
		private var __frameLUT:Vector.<Frame>;
		private var __frameLUTLength:uint;
		private var __frameTime:Number;
		private var __lastFrame:uint = uint.MAX_VALUE;
		private var __numberOfFrames:int = 1;
		private var __textureAnimation:Boolean = false;
		
		private var __blendFuncSource:String;
		private var __blendFuncDestination:String;
		private var __emissionRate:Number; // emitted particles per second
		private var __emissionTime:Number = -1;
		private var __emissionTimePredefined:Number = -1;
		private var __emitterX:Number = 0.0;
		private var __emitterY:Number = 0.0;
		
		/**
		 * A point to set your emitter position.
		 * @see #emitterX
		 * @see #emitterY
		 */
		public var emitter:Point = new Point();
		public var ignoreSystemAlpha:Boolean = true;
		
		private var __emitterObject:Object;
		
		/** Helper objects. */
		
		private static var $helperMatrix:Matrix = new Matrix();
		private static var $helperPoint:Point = new Point();
		private static var $renderAlpha:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
		private static var $instances:Vector.<FFParticleSystem> = new <FFParticleSystem>[];
		private static var $fixedPool:Boolean = false;
		private static var $randomSeed:uint = 1;
		
		/*
		   Too bad, [Inline] doesn't work in inlined functions?!
		   This has been inlined by hand in initParticle() a lot
		   [Inline]
		   private static function random():Number
		   {
		   return ((sRandomSeed = (sRandomSeed * 16807) & 0x7FFFFFFF) / 0x80000000);
		   }
		 */
		
		/**
		 * Creates a FFParticleSystem instance.
		 *
		 * <p><strong>Note:  </strong>For best performance setup the system buffers by calling
		 * <a href="#FFParticleSystem.initPool()">FFParticleSystem.initPool()</a> <strong>before</strong> you create any instances!</p>
		 *
		 * <p>The config file has to be a XML in the following format, known as .pex file</p>
		 *
		 * <p><strong>Note:  </strong>It's strongly recommended to use textures with mipmaps.</p>
		 *
		 * <p><strong>Note:  </strong>You shouldn't create any instance before Starling created the context. Just wait some
		 * frames. Otherwise this might slow down Starling's creation process, since every FFParticleSystem instance is listening
		 * for onContextCreated events, which are necessary to handle a context loss properly.</p>
		 *
		 * @example The following example shows a complete .pex file, starting with the newly introduced properties of this version:
		   <listing version="3.0">
		   &lt;?xml version="1.0"?&gt;
		   &lt;particleEmitterConfig&gt;
		
		   &lt;animation&gt;
		   &lt;isAnimated value="1"/&gt;
		   &lt;loops value="10"/&gt;
		   &lt;firstFrame value="0"/&gt;
		   &lt;lastFrame value="-1"/&gt;
		   &lt;/animation&gt;
		
		   &lt;spawnTime value="0.02"/&gt;
		   &lt;fadeInTime value="0.1"/&gt;
		   &lt;fadeOutTime value="0.1"/&gt;
		   &lt;tinted value="1"/&gt;
		   &lt;emitAngleAlignedRotation value="1"/&gt;
		
		   &lt;texture name="texture.png"/&gt;
		   &lt;sourcePosition x="300.00" y="300.00"/&gt;
		   &lt;sourcePositionVariance x="0.00" y="200"/&gt;
		   &lt;speed value="150.00"/&gt;
		   &lt;speedVariance value="75"/&gt;
		   &lt;particleLifeSpan value="10"/&gt;
		   &lt;particleLifespanVariance value="2"/&gt;
		   &lt;angle value="345"/&gt;
		   &lt;angleVariance value="25.00"/&gt;
		   &lt;gravity x="0.00" y="0.00"/&gt;
		   &lt;radialAcceleration value="0.00"/&gt;
		   &lt;tangentialAcceleration value="0.00"/&gt;
		   &lt;radialAccelVariance value="0.00"/&gt;
		   &lt;tangentialAccelVariance value="0.00"/&gt;
		   &lt;startColor red="1" green="1" blue="1" alpha="1"/&gt;
		   &lt;startColorVariance red="1" green="1" blue="1" alpha="0"/&gt;
		   &lt;finishColor red="1" green="1" blue="1" alpha="1"/&gt;
		   &lt;finishColorVariance red="0" green="0" blue="0" alpha="0"/&gt;
		   &lt;maxParticles value="500"/&gt;
		   &lt;startParticleSize value="50"/&gt;
		   &lt;startParticleSizeVariance value="25"/&gt;
		   &lt;finishParticleSize value="25"/&gt;
		   &lt;FinishParticleSizeVariance value="25"/&gt;
		   &lt;duration value="-1.00"/&gt;
		   &lt;emitterType value="0"/&gt;
		   &lt;maxRadius value="100.00"/&gt;
		   &lt;maxRadiusVariance value="0.00"/&gt;
		   &lt;minRadius value="0.00"/&gt;
		   &lt;rotatePerSecond value="0.00"/&gt;
		   &lt;rotatePerSecondVariance value="0.00"/&gt;
		   &lt;blendFuncSource value="770"/&gt;
		   &lt;blendFuncDestination value="771"/&gt;
		   &lt;rotationStart value="0.00"/&gt;
		   &lt;rotationStartVariance value="0.00"/&gt;
		   &lt;rotationEnd value="0.00"/&gt;
		   &lt;rotationEndVariance value="0.00"/&gt;
		   &lt;emitAngleAlignedRotation value="0"/&gt;
		   &lt;/particleEmitterConfig&gt;
		   </listing>
		 *
		 * @param	config A SystemOptions instance
		 * @param	style The style setting the rendering effect of this instance
		 *
		 * @see #initPool() FFParticleSystem.initPool()
		 */
		public function FFParticleSystem(config:SystemOptions, style:FFParticleStyle = null)
		{
			if (config == null)
				throw new ArgumentError("config must not be null");
			
			$instances.push(this);
			parseSystemOptions(config);
			if (style && !style.effectType.isSupported)
				throw new Error('[FFParticleSystem] style not supported!');
			setStyle(style, false);
			initInstance();
		}
		
		private function addedToStageHandler(e:starling.events.Event):void
		{
			__effect.maxCapacity = __maxNumParticles;
			
			if (e)
			{
				getParticlesFromPool();
				if (__playing)
					start(__emissionTime);
			}
		}
		
		/**
		 * Calculating property changes of a particle.
		 * @param	aParticle
		 * @param	passedTime
		 */
		
		[Inline]
		
		final private function advanceParticle(aParticle:Particle, passedTime:Number):void
		{
			var particle:Particle = aParticle;
			
			var restTime:Number = particle.totalTime - particle.currentTime;
			passedTime = restTime > passedTime ? passedTime : restTime;
			particle.currentTime += passedTime;
			
			if (__emitterType == EMITTER_TYPE_RADIAL)
			{
				particle.emitRotation += particle.emitRotationDelta * passedTime;
				particle.emitRadius += particle.emitRadiusDelta * passedTime;
				var angle:uint = (particle.emitRotation * 325.94932345220164765467394738691) & 2047;
				particle.x = __emitterX - FFPS_LUT.cos[angle] * particle.emitRadius;
				particle.y = __emitterY - FFPS_LUT.sin[angle] * particle.emitRadius;
			}
			else if (particle.radialAcceleration || particle.tangentialAcceleration)
			{
				var distanceX:Number = particle.x - particle.startX;
				var distanceY:Number = particle.y - particle.startY;
				var distanceScalar:Number = Math.sqrt(distanceX * distanceX + distanceY * distanceY);
				if (distanceScalar < 0.01)
					distanceScalar = 0.01;
				
				var radialX:Number = distanceX / distanceScalar;
				var radialY:Number = distanceY / distanceScalar;
				var tangentialX:Number = radialX;
				var tangentialY:Number = radialY;
				
				radialX *= particle.radialAcceleration;
				radialY *= particle.radialAcceleration;
				
				var newY:Number = tangentialX;
				tangentialX = -tangentialY * particle.tangentialAcceleration;
				tangentialY = newY * particle.tangentialAcceleration;
				
				particle.velocityX += passedTime * (__gravityX + radialX + tangentialX);
				particle.velocityY += passedTime * (__gravityY + radialY + tangentialY);
				particle.x += particle.velocityX * passedTime;
				particle.y += particle.velocityY * passedTime;
			}
			else
			{
				particle.velocityX += passedTime * __gravityX;
				particle.velocityY += passedTime * __gravityY;
				particle.x += particle.velocityX * passedTime;
				particle.y += particle.velocityY * passedTime;
			}
			
			particle.scale += particle.scaleDelta * passedTime;
			particle.rotation += particle.rotationDelta * passedTime;
			
			if (__textureAnimation)
			{
				particle.frame = particle.frame + particle.frameDelta * passedTime;
				particle.frameIdx = particle.frame;
				if (particle.frameIdx > __frameLUTLength)
					particle.frameIdx = __frameLUTLength;
			}
			
			if (__tinted)
			{
				particle.colorRed += particle.colorDeltaRed * passedTime;
				particle.colorGreen += particle.colorDeltaGreen * passedTime;
				particle.colorBlue += particle.colorDeltaBlue * passedTime;
				particle.colorAlpha += particle.colorDeltaAlpha * passedTime;
			}
		}
		
		/**
		 * Loops over all particles and adds/removes/advances them according to the current time;
		 * writes the data directly to the raw vertex data.
		 *
		 * <p>Note: This function is called by Starling's Juggler, so there will most likely be no reason for
		 * you to call it yourself, unless you want to implement slow/quick motion effects.</p>
		 *
		 * @param	passedTime
		 */
		
		public function advanceTime(passedTime:Number):void
		{
			setRequiresRedraw();
			var sortFlag:Boolean = forceSortFlag;
			
			__frameTime += passedTime;
			if (!__particles)
			{
				if (__emissionTime)
				{
					__emissionTime -= passedTime;
					if (__emissionTime != Number.MAX_VALUE)
						__emissionTime = Math.max(0.0, __emissionTime - passedTime);
				}
				else
				{
					stop(autoClearOnComplete);
					complete();
					return;
				}
				return;
			}
			
			var particleIndex:int = 0;
			var particle:Particle;
			if (__emitterObject != null)
			{
				__emitterX = emitter.x = __emitterObject.x;
				__emitterY = emitter.y = __emitterObject.y;
			}
			else
			{
				__emitterX = emitter.x;
				__emitterY = emitter.y;
			}
			
			// advance existing particles
			while (particleIndex < __numParticles)
			{
				particle = __particles[particleIndex];
				
				if (particle.currentTime < particle.totalTime)
				{
					advanceParticle(particle, passedTime);
					++particleIndex;
				}
				else
				{
					particle.active = false;
					
					if (particleIndex != --__numParticles)
					{
						var nextParticle:Particle = __particles[__numParticles];
						__particles[__numParticles] = particle; // put dead p at end
						__particles[particleIndex] = nextParticle;
						sortFlag = true;
					}
					
					if (__numParticles == 0 && __emissionTime < 0)
					{
						stop(autoClearOnComplete);
						complete();
						return;
					}
				}
			}
			
			// create and advance new particles
			
			if (__emissionTime > 0)
			{
				const timeBetweenParticles:Number = 1.0 / __emissionRate;
				
				while (__frameTime > 0 && __numParticles < __effect.maxCapacity)
				{
					if (__numParticles == __effect.capacity)
						__effect.raiseCapacity(__effect.capacity);
					
					particle = __particles[__numParticles];
					initParticle(particle);
					advanceParticle(particle, __frameTime);
					
					++__numParticles;
					
					__frameTime -= timeBetweenParticles;
				}
				
				if (__emissionTime != Number.MAX_VALUE)
					__emissionTime = Math.max(0.0, __emissionTime - passedTime);
			}
			else if (!__completed && __numParticles == 0)
			{
				stop(autoClearOnComplete);
				complete();
				return;
			}
			
			// update vertex data
			
			if (!__particles)
				return;
			
			if (__customFunction !== null)
			{
				__customFunction(__particles, __numParticles);
			}
			
			if (sortFlag && __sortFunction !== null)
			{
				__particles = __particles.sort(__sortFunction);
			}
			
			// upadate particle fading factors
			
			if (__spawnTime || __fadeInTime || __fadeOutTime)
			{
				var deltaTime:Number;
				for (var i:int = 0; i < __numParticles; ++i)
				{
					particle = __particles[i];
					deltaTime = particle.currentTime / particle.totalTime;
					
					if (__spawnTime)
						particle.spawnFactor = deltaTime < __spawnTime ? deltaTime / __spawnTime : 1;
					
					if (__fadeInTime)
						particle.fadeInFactor = deltaTime < __fadeInTime ? deltaTime / __fadeInTime : 1;
					
					if (__fadeOutTime)
					{
						deltaTime = 1 - deltaTime;
						particle.fadeOutFactor = deltaTime < __fadeOutTime ? deltaTime / __fadeOutTime : 1;
					}
				}
			}
		
		}
		
		/**
		 * Remaining initiation of the current instance (for JIT optimization).
		 * @param	config
		 */
		private function initInstance():void
		{
			
			__emissionRate = __maxNumParticles / __lifespan;
			__emissionTime = 0.0;
			__frameTime = 0.0;
			
			__effect.maxCapacity = __maxNumParticles;
			if (!FFParticleSystem.poolCreated)
				initPool();
			
			if (defaultJuggler == null)
				defaultJuggler = Starling.juggler;
			
			addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStageHandler);
			addedToStageHandler(null);
		
		}
		
		/**
		 * Initiation of anything shared between all systems. Call this function <strong>before</strong> you create any instance
		 * to set a custom size of your pool and Stage3D buffers.
		 *
		 * <p>If you don't call this method explicitly before createing an instance, the first constructor will
		 * create a default pool and buffers; which is OK but might slow down especially mobile devices.</p>
		 *
		 * <p>Set the <em>poolSize</em> to the absolute maximum of particles created by all particle systems together. Creating the pool
		 * will only hit you once (unless you dispose/recreate it/context loss). It will not harm runtime, but a number way to big will waste
		 * memory and take a longer creation process.</p>
		 *
		 * <p>If you're satisfied with the number of particles and want to avoid any accidental enhancement of the pool, set <em>fixed</em>
		 * to true. If you're not sure how much particles you will need, and fear particle systems might not show up more than the consumption
		 * of memory and a little slowdown for newly created particles, set <em>fixed</em> to false.</p>
		 *
		 * <p>The <em>bufferSize</em> determins how many particles can be rendered by one particle system. The <strong>minimum</strong>
		 * should be the maxParticles value set number in your pex file.</p>
		 * <p><strong>Note:   </strong>The bufferSize is always fixed!</p>
		 * <p><strong>Note:   </strong>If you want to profit from batching, take a higher value, e. g. enough for 5 systems. But avoid
		 * choosing an unrealistic high value, since the complete buffer will have to be uploaded each time a particle system (batch) is drawn.</p>
		 *
		 * <p>The <em>numberOfBuffers</em> sets the amount of vertex buffers in use by the particle systems. Multi buffering can avoid stalling of
		 * the GPU but will also increases it's memory consumption.</p>
		 *
		 * @param	poolSize Length of the particle pool.
		 * @param	fixed Whether the poolSize has a fixed length.
		 *
		 * @see #FFParticleSystem()
		 * @see #dispose() FFParticleSystem.dispose()
		 * @see #disposePool() FFParticleSystem.disposePool()
		 */
		public static function initPool(poolSize:uint = 16383, fixed:Boolean = false):void
		{
			FFPS_LUT.init();
			initParticlePool(poolSize, fixed);
			
			if (defaultJuggler == null)
				defaultJuggler = Starling.juggler;
			
			// handle a lost device context
			Starling.current.stage3D.addEventListener(flash.events.Event.CONTEXT3D_CREATE, onContextCreated, false, 0, true);
		}
		
		public static function get poolCreated():Boolean
		{
			return ($particlePool && $particlePool.length);
		}
		
		private static function initParticlePool(poolSize:uint = 16383, fixed:Boolean = false):void
		{
			if (!$particlePool)
			{
				$fixedPool = fixed;
				$particlePool = new Vector.<Particle>();
				$poolSize = poolSize;
				var i:int = -1;
				while (++i < $poolSize)
					$particlePool[i] = new Particle();
			}
		}
		
		/**
		 * Sets the start values for a newly created particle, according to your system settings.
		 *
		 * <p>Note:
		 * 		The following snippet ...
		 *
		 * 			(((sRandomSeed = (sRandomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
		 *
		 * 		... is a pseudo random number generator; directly inlined; to reduce function calls.
		 * 		Unfortunatelly it seems impossible to inline within inline functions.</p>
		 *
		 * @param	aParticle
		 */
		[Inline]
		
		final private function initParticle(aParticle:Particle):void
		{
			var particle:Particle = aParticle;
			
			// for performance reasons, the random variances are calculated inline instead
			// of calling a function
			
			var lifespan:Number = __lifespan + __lifespanVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			if (lifespan <= 0.0)
				return;
			
			particle.active = true;
			particle.currentTime = 0.0;
			particle.totalTime = lifespan;
			
			particle.x = __emitterX + __emitterXVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			particle.y = __emitterY + __emitterYVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			particle.startX = __emitterX;
			particle.startY = __emitterY;
			
			var angleDeg:Number = (__emitAngle + __emitAngleVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0));
			var angle:uint = (angleDeg * 325.94932345220164765467394738691) & 2047;
			var speed:Number = __speed + __speedVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			particle.velocityX = speed * FFPS_LUT.cos[angle];
			particle.velocityY = speed * FFPS_LUT.sin[angle];
			
			particle.emitRadius = __maxRadius + __maxRadiusVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			particle.emitRadiusDelta = __maxRadius / lifespan;
			particle.emitRadius = __maxRadius + __maxRadiusVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			particle.emitRadiusDelta = (__minRadius + __minRadiusVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0) - particle.emitRadius) / lifespan;
			particle.emitRotation = __emitAngle + __emitAngleVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			particle.emitRotationDelta = __rotatePerSecond + __rotatePerSecondVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			particle.radialAcceleration = __radialAcceleration + __radialAccelerationVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			particle.tangentialAcceleration = __tangentialAcceleration + __tangentialAccelerationVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			
			var startSize:Number = __startSize + __startSizeVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			var endSize:Number = __endSize + __endSizeVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			if (startSize < 0.1)
				startSize = 0.1;
			if (endSize < 0.1)
				endSize = 0.1;
			
			var firstFrameWidth:Number = __frameLUT[0].particleHalfWidth << 1;
			particle.scale = startSize / firstFrameWidth;
			particle.scaleDelta = ((endSize - startSize) / lifespan) / firstFrameWidth;
			particle.frameIdx = particle.frame = __randomStartFrames ? __animationLoopLength * (($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x80000000) : 0;
			particle.frameDelta = __numberOfFrames / lifespan;
			
			// colors
			var startColorRed:Number = __startColor.red;
			var startColorGreen:Number = __startColor.green;
			var startColorBlue:Number = __startColor.blue;
			var startColorAlpha:Number = __startColor.alpha;
			
			if (__startColorVariance.red != 0)
				startColorRed += __startColorVariance.red * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			if (__startColorVariance.green != 0)
				startColorGreen += __startColorVariance.green * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			if (__startColorVariance.blue != 0)
				startColorBlue += __startColorVariance.blue * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			if (__startColorVariance.alpha != 0)
				startColorAlpha += __startColorVariance.alpha * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			
			var endColorRed:Number = __endColor.red;
			var endColorGreen:Number = __endColor.green;
			var endColorBlue:Number = __endColor.blue;
			var endColorAlpha:Number = __endColor.alpha;
			
			if (__endColorVariance.red != 0)
				endColorRed += __endColorVariance.red * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			if (__endColorVariance.green != 0)
				endColorGreen += __endColorVariance.green * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			if (__endColorVariance.blue != 0)
				endColorBlue += __endColorVariance.blue * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			if (__endColorVariance.alpha != 0)
				endColorAlpha += __endColorVariance.alpha * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			
			particle.colorRed = startColorRed;
			particle.colorGreen = startColorGreen;
			particle.colorBlue = startColorBlue;
			particle.colorAlpha = startColorAlpha;
			
			particle.colorDeltaRed = (endColorRed - startColorRed) / lifespan;
			particle.colorDeltaGreen = (endColorGreen - startColorGreen) / lifespan;
			particle.colorDeltaBlue = (endColorBlue - startColorBlue) / lifespan;
			particle.colorDeltaAlpha = (endColorAlpha - startColorAlpha) / lifespan;
			
			// rotation
			if (__emitAngleAlignedRotation)
			{
				var startRotation:Number = angleDeg + __startRotation + __startRotationVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
				var endRotation:Number = angleDeg + __endRotation + __endRotationVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			}
			else
			{
				startRotation = __startRotation + __startRotationVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
				endRotation = __endRotation + __endRotationVariance * ((($randomSeed = ($randomSeed * 16807) & 0x7FFFFFFF) / 0x40000000) - 1.0);
			}
			
			particle.rotation = startRotation;
			particle.rotationDelta = (endRotation - startRotation) / lifespan;
			
			particle.spawnFactor = 1;
			particle.fadeInFactor = 1;
			particle.fadeOutFactor = 1;
		}
		
		/**
		 * Setting the complete state and throwing the event.
		 */
		private function complete():void
		{
			if (!__completed)
			{
				__completed = true;
				dispatchEventWith(starling.events.Event.COMPLETE);
			}
		}
		
		/**
		 * Disposes the system instance and frees it's resources
		 */
		public override function dispose():void
		{
			style.setTarget(null);
			$instances.splice($instances.indexOf(this), 1);
			removeEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStageHandler);
			stop(true);
			__batched = false;
			super.filter = __filter = null;
			removeFromParent();
			
			super.dispose();
			__disposed = true;
		}
		
		/**
		 *  Whether the system has been disposed earlier
		 */
		public function get disposed():Boolean
		{
			return __disposed;
		}
		
		/**
		 * Disposes the created particle pool and Stage3D buffers, shared by all instances.
		 * Warning: Therefore all instances will get disposed as well!
		 */
		public static function dispose():void
		{
			Starling.current.stage3D.removeEventListener(flash.events.Event.CONTEXT3D_CREATE, onContextCreated);
			
			for (var i:int = registeredEffects.length - 1; i >= 0; --i)
			{
				var effectClass:Class = registeredEffects[i];
				effectClass['disposeBuffers']();
			}
			disposePool();
		}
		
		/**
		 * Disposes all system instances
		 */
		public static function disposeInstances():void
		{
			for (var i:int = $instances.length - 1; i >= 0; --i)
			{
				$instances[i].dispose();
			}
		}
		
		/**
		 * Clears the current particle pool.
		 * Warning: Also disposes all system instances!
		 */
		public static function disposePool():void
		{
			disposeInstances();
			$particlePool = null;
		}
		
		/** @inheritDoc */
		public override function set filter(value:FragmentFilter):void
		{
			if (!__batched)
				__filter = value;
			super.filter = value;
		}
		
		/**
		 * Returns a rectangle in stage dimensions (to support filters) if possible, or an empty rectangle
		 * at the particle system's position. Calculating the actual bounds might be too expensive.
		 */
		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			if (resultRect == null)
				resultRect = new Rectangle();
			
			if (targetSpace == this || targetSpace == null) // optimization
			{
				if (__bounds)
					resultRect = __bounds;
				else if (stage)
				{
					// return full stage size to support filters ... may be expensive, but we have no other options, do we?
					resultRect.x = 0;
					resultRect.y = 0;
					resultRect.width = stage.stageWidth;
					resultRect.height = stage.stageHeight;
				}
				else
				{
					getTransformationMatrix(targetSpace, $helperMatrix);
					MatrixUtil.transformCoords($helperMatrix, 0, 0, $helperPoint);
					resultRect.x = $helperPoint.x;
					resultRect.y = $helperPoint.y;
					resultRect.width = resultRect.height = 0;
				}
				return resultRect;
			}
			else if (targetSpace)
			{
				if (__bounds)
				{
					getTransformationMatrix(targetSpace, $helperMatrix);
					MatrixUtil.transformCoords($helperMatrix, __bounds.x, __bounds.y, $helperPoint);
					resultRect.x = $helperPoint.x;
					resultRect.y = $helperPoint.y;
					MatrixUtil.transformCoords($helperMatrix, __bounds.width, __bounds.height, $helperPoint);
					resultRect.width = $helperPoint.x
					resultRect.height = $helperPoint.y;
				}
				else if (stage)
				{
					// return full stage size to support filters ... may be pretty expensive
					resultRect.x = 0;
					resultRect.y = 0;
					resultRect.width = stage.stageWidth;
					resultRect.height = stage.stageHeight;
				}
				else
				{
					getTransformationMatrix(targetSpace, $helperMatrix);
					MatrixUtil.transformCoords($helperMatrix, 0, 0, $helperPoint);
					resultRect.x = $helperPoint.x;
					resultRect.y = $helperPoint.y;
					resultRect.width = resultRect.height = 0;
				}
				
				return resultRect;
			}
			return resultRect = __bounds;
		
		}
		
		/**
		 * Takes particles from the pool and assigns them to the system instance.
		 * If the particle pool doesn't have enough unused particles left, it will
		 * - either create new particles, if the pool size is expandable
		 * - or return false, if the pool size has been fixed
		 *
		 * Returns a Boolean for success
		 *
		 * @return
		 */
		private function getParticlesFromPool():Boolean
		{
			if (__particles)
				return true;
			
			if (__disposed)
				return false;
			
			if ($particlePool.length >= __maxNumParticles)
			{
				__particles = new Vector.<Particle>(__maxNumParticles, true);
				var particleIdx:int = __maxNumParticles;
				var poolIdx:int = $particlePool.length;
				
				$particlePool.fixed = false;
				while (particleIdx)
				{
					__particles[--particleIdx] = $particlePool[--poolIdx];
					__particles[particleIdx].active = false;
					$particlePool[poolIdx] = null;
				}
				$particlePool.length = poolIdx;
				$particlePool.fixed = true;
				
				__numParticles = 0;
				__effect.raiseCapacity(__maxNumParticles - __particles.length);
				return true;
			}
			
			if ($fixedPool)
				return false;
			
			var i:int = $particlePool.length - 1;
			var len:int = __maxNumParticles;
			$particlePool.fixed = false;
			while (++i < len)
				$particlePool[i] = new Particle();
			$particlePool.fixed = true;
			return getParticlesFromPool();
		}
		
		/**
		 * (Re)Inits the system (after context loss)
		 * @param	event
		 */
		private static function onContextCreated(event:flash.events.Event):void
		{
			for each (var effectClass:Class in registeredEffects)
			{
				effectClass['createBuffers']();
			}
		}
		
		private function parseSystemOptions(systemOptions:SystemOptions):void
		{
			if (!systemOptions)
				return;
			
			const DEG2RAD:Number = 1 / 180 * Math.PI;
			
			__textureAnimation = Boolean(systemOptions.isAnimated);
			__animationLoops = int(systemOptions.loops);
			__firstFrame = int(systemOptions.firstFrame);
			__lastFrame = int(systemOptions.lastFrame);
			__randomStartFrames = Boolean(systemOptions.randomStartFrames);
			__tinted = Boolean(systemOptions.tinted);
			__spawnTime = Number(systemOptions.spawnTime);
			__fadeInTime = Number(systemOptions.fadeInTime);
			__fadeOutTime = Number(systemOptions.fadeOutTime);
			__emitterType = int(systemOptions.emitterType);
			__maxNumParticles = int(systemOptions.maxParticles);
			emitter.x = __emitterX = Number(systemOptions.sourceX);
			emitter.y = __emitterY = Number(systemOptions.sourceY);
			__emitterXVariance = Number(systemOptions.sourceVarianceX);
			__emitterYVariance = Number(systemOptions.sourceVarianceY);
			__lifespan = Number(systemOptions.lifespan);
			lifespanVariance = Number(systemOptions.lifespanVariance);
			__emitAngle = Number(systemOptions.angle) * DEG2RAD;
			__emitAngleVariance = Number(systemOptions.angleVariance) * DEG2RAD;
			__startSize = Number(systemOptions.startParticleSize);
			__startSizeVariance = Number(systemOptions.startParticleSizeVariance);
			__endSize = Number(systemOptions.finishParticleSize);
			__endSizeVariance = Number(systemOptions.finishParticleSizeVariance);
			__startRotation = Number(systemOptions.rotationStart) * DEG2RAD;
			__startRotationVariance = Number(systemOptions.rotationStartVariance) * DEG2RAD;
			__endRotation = Number(systemOptions.rotationEnd) * DEG2RAD;
			__endRotationVariance = Number(systemOptions.rotationEndVariance) * DEG2RAD;
			__emissionTimePredefined = Number(systemOptions.duration);
			__emissionTimePredefined = __emissionTimePredefined < 0 ? Number.MAX_VALUE : __emissionTimePredefined;
			
			__gravityX = Number(systemOptions.gravityX);
			__gravityY = Number(systemOptions.gravityY);
			__speed = Number(systemOptions.speed);
			__speedVariance = Number(systemOptions.speedVariance);
			__radialAcceleration = Number(systemOptions.radialAcceleration);
			__radialAccelerationVariance = Number(systemOptions.radialAccelerationVariance);
			__tangentialAcceleration = Number(systemOptions.tangentialAcceleration);
			__tangentialAccelerationVariance = Number(systemOptions.tangentialAccelerationVariance);
			
			__maxRadius = Number(systemOptions.maxRadius);
			__maxRadiusVariance = Number(systemOptions.maxRadiusVariance);
			__minRadius = Number(systemOptions.minRadius);
			__minRadiusVariance = Number(systemOptions.minRadiusVariance);
			__rotatePerSecond = Number(systemOptions.rotatePerSecond) * DEG2RAD;
			__rotatePerSecondVariance = Number(systemOptions.rotatePerSecondVariance) * DEG2RAD;
			
			__startColor.red = Number(systemOptions.startColor.red);
			__startColor.green = Number(systemOptions.startColor.green);
			__startColor.blue = Number(systemOptions.startColor.blue);
			__startColor.alpha = Number(systemOptions.startColor.alpha);
			
			__startColorVariance.red = Number(systemOptions.startColorVariance.red);
			__startColorVariance.green = Number(systemOptions.startColorVariance.green);
			__startColorVariance.blue = Number(systemOptions.startColorVariance.blue);
			__startColorVariance.alpha = Number(systemOptions.startColorVariance.alpha);
			
			__endColor.red = Number(systemOptions.finishColor.red);
			__endColor.green = Number(systemOptions.finishColor.green);
			__endColor.blue = Number(systemOptions.finishColor.blue);
			__endColor.alpha = Number(systemOptions.finishColor.alpha);
			
			__endColorVariance.red = Number(systemOptions.finishColorVariance.red);
			__endColorVariance.green = Number(systemOptions.finishColorVariance.green);
			__endColorVariance.blue = Number(systemOptions.finishColorVariance.blue);
			__endColorVariance.alpha = Number(systemOptions.finishColorVariance.alpha);
			
			__blendFuncSource = String(systemOptions.blendFuncSource);
			__blendFuncDestination = String(systemOptions.blendFuncDestination);
			updateBlendMode();
			__emitAngleAlignedRotation = Boolean(systemOptions.emitAngleAlignedRotation);
			
			exactBounds = Boolean(systemOptions.excactBounds);
			__texture = systemOptions.texture;
			__premultipliedAlpha = Boolean(systemOptions.premultipliedAlpha);
			
			__filter = systemOptions.filter;
			__customFunction = systemOptions.customFunction;
			__sortFunction = systemOptions.sortFunction;
			forceSortFlag = systemOptions.forceSortFlag;
			
			__frameLUT = systemOptions.mFrameLUT;
			
			__animationLoopLength = __lastFrame - __firstFrame + 1;
			__numberOfFrames = __frameLUT.length - 1 - (__randomStartFrames && __textureAnimation ? __animationLoopLength : 0);
			__frameLUTLength = __frameLUT.length - 1;
		}
		
		/**
		 * Returns current properties to SystemOptions Object
		 * @param	target A SystemOptions instance
		 */
		public function exportSystemOptions(target:SystemOptions = null):SystemOptions
		{
			if (!target)
				target = new SystemOptions(__texture);
			
			const RAD2DEG:Number = 180 / Math.PI;
			
			target.isAnimated = __textureAnimation;
			target.loops = __animationLoops;
			target.firstFrame = __firstFrame;
			target.lastFrame = __lastFrame;
			target.randomStartFrames = __randomStartFrames;
			target.tinted = __tinted;
			target.premultipliedAlpha = __premultipliedAlpha;
			target.spawnTime = __spawnTime;
			target.fadeInTime = __fadeInTime;
			target.fadeOutTime = __fadeOutTime;
			target.emitterType = __emitterType;
			target.maxParticles = __maxNumParticles;
			target.sourceX = __emitterX;
			target.sourceY = __emitterY;
			target.sourceVarianceX = __emitterXVariance;
			target.sourceVarianceY = __emitterYVariance;
			target.lifespan = __lifespan;
			target.lifespanVariance = __lifespanVariance;
			target.angle = __emitAngle * RAD2DEG;
			target.angleVariance = __emitAngleVariance * RAD2DEG;
			target.startParticleSize = __startSize;
			target.startParticleSizeVariance = __startSizeVariance;
			target.finishParticleSize = __endSize;
			target.finishParticleSizeVariance = __endSizeVariance;
			target.rotationStart = __startRotation * RAD2DEG;
			target.rotationStartVariance = __startRotationVariance * RAD2DEG;
			target.rotationEnd = __endRotation * RAD2DEG;
			target.rotationEndVariance = __endRotationVariance * RAD2DEG;
			target.duration = __emissionTimePredefined == Number.MAX_VALUE ? -1 : __emissionTimePredefined;
			
			target.gravityX = __gravityX;
			target.gravityY = __gravityY;
			target.speed = __speed;
			target.speedVariance = __speedVariance;
			target.radialAcceleration = __radialAcceleration;
			target.radialAccelerationVariance = __radialAccelerationVariance;
			target.tangentialAcceleration = __tangentialAcceleration;
			target.tangentialAccelerationVariance = __tangentialAccelerationVariance;
			
			target.maxRadius = __maxRadius;
			target.maxRadiusVariance = __maxRadiusVariance;
			target.minRadius = __minRadius;
			target.minRadiusVariance = __minRadiusVariance;
			target.rotatePerSecond = __rotatePerSecond * RAD2DEG;
			target.rotatePerSecondVariance = __rotatePerSecondVariance * RAD2DEG;
			
			target.startColor = __startColor;
			target.startColorVariance = __startColorVariance;
			target.finishColor = __endColor;
			target.finishColorVariance = __endColorVariance;
			
			target.blendFuncSource = __blendFuncSource;
			target.blendFuncDestination = __blendFuncDestination;
			target.emitAngleAlignedRotation = __emitAngleAlignedRotation;
			
			target.excactBounds = __exactBounds;
			target.texture = __texture;
			
			target.filter = __filter;
			target.customFunction = __customFunction;
			target.sortFunction = __sortFunction;
			target.forceSortFlag = forceSortFlag;
			
			target.mFrameLUT = __frameLUT;
			
			target.firstFrame = __firstFrame;
			target.lastFrame = __lastFrame;
			
			return target;
		}
		
		/**
		 * Removes the system from the juggler and stops animation.
		 */
		public function pause():void
		{
			if (automaticJugglerManagement)
				__juggler.remove(this);
			__playing = false;
		}
		
		/** @inheritDoc */
		private static var sHelperRect:Rectangle = new Rectangle();
		private var batchBounds:Rectangle = new Rectangle();
		
		/*
		   [Inline]
		
		   final private function updateExactBounds(start:int, end:int):void
		   {
		   if (!mExactBounds)
		   return;
		
		   if (!mBounds)
		   mBounds = new Rectangle();
		
		   var posX:int = 0;
		   var posY:int = 1;
		   var tX:Number = 0;
		   var tY:Number = 0;
		   var minX:Number = Number.MAX_VALUE;
		   var maxX:Number = Number.MIN_VALUE;
		   var minY:Number = Number.MAX_VALUE;
		   var maxY:Number = Number.MIN_VALUE;
		
		   for (var i:int = start; i < end; ++i)
		   {
		   tX = rawData[posX];
		   tY = rawData[posY];
		   if (minX > tX)
		   minX = tX;
		   if (maxX < tX)
		   maxX = tX;
		   if (minY > tY)
		   minY = tY;
		   if (maxY < tY)
		   maxY = tY;
		   posX += ELEMENTS_PER_VERTEX;
		   posY += ELEMENTS_PER_VERTEX;
		   }
		   mBounds.x = minX;
		   mBounds.y = minY;
		   mBounds.width = maxX - minX;
		   mBounds.height = maxY - minY;
		   }
		 */
		
		/** @inheritDoc */
		public override function render(painter:Painter):void
		{
			
			painter.excludeFromCache(this);
			__numBatchedParticles = 0;
			getBounds(stage, batchBounds);
			
			if (!ignoreSystemAlpha && !__alpha)
				return;
			
			if (__numParticles)
			{
				if (__batching)
				{
					if (!__batched)
					{
						var first:int = parent.getChildIndex(this);
						var last:int = first;
						var numChildren:int = parent.numChildren;
						
						__numBatchedParticles += __effect.writeParticleDataToBuffers(__particles, __frameLUT, 0, numParticles, __alpha);
						//updateExactBounds(offset, offset + mNumParticles);
						
						while (++last < numChildren)
						{
							var next:DisplayObject = parent.getChildAt(last);
							if (next is FFParticleSystem)
							{
								var nextps:FFParticleSystem = FFParticleSystem(next);
								
								// filters don't seam to be "batchable" anymore?
								if (!__filter && blendMode == nextps.blendMode && __filter == nextps.filter && style.canBatchWith(nextps.style))
								{
									
									var newcapacity:int = __numParticles + __numBatchedParticles + nextps.__numParticles;
									if (newcapacity > __style.effectType.bufferSize)
										break;
									
									__numBatchedParticles += __effect.writeParticleDataToBuffers(nextps.__particles, nextps.__frameLUT, __numBatchedParticles, nextps.numParticles, nextps.__alpha);
									//updateExactBounds(offset, offset + mNumParticles);
									
									nextps.__batched = true;
									
									//disable filter of batched system temporarily
									nextps.filter = null;
									
									nextps.getBounds(stage, sHelperRect);
									if (batchBounds.intersects(sHelperRect))
										batchBounds = batchBounds.union(sHelperRect);
								}
								else
								{
									break;
								}
							}
							else
							{
								break;
							}
						}
						renderCustom(painter);
					}
				}
				else
				{
					__numBatchedParticles += __effect.writeParticleDataToBuffers(__particles, __frameLUT, 0, numParticles, __alpha);
					//updateExactBounds(offset, offset + mNumParticles);
					renderCustom(painter);
				}
			}
			// reset filter
			super.filter = __filter;
			__batched = false;
		}
		
		[Inline]
		
		final private function renderCustom(painter:Painter):void
		{
			if (__numBatchedParticles == 0)
				return;
			
			// always call this method when you write custom rendering code!
			// it causes all previously batched quads/images to render.
			painter.finishMeshBatch();
			++painter.drawCount;
			
			var clipRect:Rectangle = painter.state.clipRect;
			if (clipRect)
			{
				batchBounds = batchBounds.intersection(clipRect);
			}
			painter.state.clipRect = batchBounds;
			painter.prepareToDraw();
			
			style.updateEffect(__effect, painter.state);
			
			var context:Context3D = Starling.context;
			
			if (context == null)
				throw new MissingContextError();
			
			__effect.render(0, __numBatchedParticles);
		}
		
		private function updateBlendMode():void
		{
			
			var pma:Boolean = texture ? texture.premultipliedAlpha : true;
			
			// Particle Designer uses special logic for a certain blend factor combination
			if (__blendFuncSource == Context3DBlendFactor.ONE && __blendFuncDestination == Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA)
			{
				//_vertexData.premultipliedAlpha = pma;
				if (!pma) __blendFuncSource = Context3DBlendFactor.SOURCE_ALPHA;
			}
			else
			{
				//_vertexData.premultipliedAlpha = false;
			}
			
			blendMode = __blendFuncSource + ", " + __blendFuncDestination;
			BlendMode.register(blendMode, __blendFuncSource, __blendFuncDestination);
		}
		
		public function setStyle(particleStyle:FFParticleStyle = null, mergeWithPredecessor:Boolean = true):void
		{
			if (particleStyle == null) particleStyle = new $defaultStyle() as FFParticleStyle;
			else if (particleStyle == __style || !particleStyle.effectType.isSupported) return;
			else if (particleStyle.target) particleStyle.target.setStyle();
			
			if (__style)
			{
				if (mergeWithPredecessor) particleStyle.copyFrom(__style);
				__style.setTarget(null);
			}
			
			__style = particleStyle;
			__style.setTarget(this);
			
			if (__effect)
				__effect.dispose();
			
			__effect = style.createEffect();
			__effect.texture = __texture;
		}
		
		public function get style():FFParticleStyle  { return __style; }
		
		public function set style(value:FFParticleStyle):void
		{
			setStyle(value);
		}
		
		/**
		 * Adds the system to the juggler and resumes animation.
		 */
		public function resume():void
		{
			if (automaticJugglerManagement)
				__juggler.add(this);
			__playing = true;
		}
		
		/**
		 * Starts the system to emit particles and adds it to the defaultJuggler if automaticJugglerManagement is enabled.
		 * @param	duration Emitting time in seconds.
		 */
		public function start(duration:Number = 0):void
		{
			if (__completed)
				reset();
			
			if (__emissionRate != 0 && !__completed)
			{
				if (duration == 0)
				{
					duration = __emissionTimePredefined;
				}
				else if (duration < 0)
				{
					duration = Number.MAX_VALUE;
				}
				__playing = true;
				__emissionTime = duration;
				__frameTime = 0;
				if (automaticJugglerManagement)
					__juggler.add(this);
			}
		}
		
		/**
		 * Stopping the emitter creating particles.
		 * @param	clear Unlinks the particles returns them back to the pool and stops the animation.
		 */
		public function stop(clear:Boolean = false):void
		{
			__emissionTime = 0.0;
			
			if (clear)
			{
				if (automaticJugglerManagement)
					__juggler.remove(this);
				
				__playing = false;
				returnParticlesToPool();
				dispatchEventWith(starling.events.Event.CANCEL);
			}
		}
		
		/**
		 * Resets complete state and enables the system to play again if it has not been disposed.
		 * @return
		 */
		public function reset():Boolean
		{
			if (!__disposed)
			{
				__emissionRate = __maxNumParticles / __lifespan;
				__frameTime = 0.0;
				__playing = false;
				while (__numParticles)
				{
					__particles[--__numParticles].active = false;
				}
				__effect.maxCapacity = __maxNumParticles;
				__completed = false;
				if (!__particles)
					getParticlesFromPool();
				return __particles != null;
			}
			return false;
		}
		
		private function returnParticlesToPool():void
		{
			__numParticles = 0;
			
			if (__particles)
			{
				// handwritten concat to avoid gc
				var particleIdx:int = __particles.length;
				var poolIdx:int = $particlePool.length - 1;
				$particlePool.fixed = false;
				while (particleIdx)
					$particlePool[++poolIdx] = __particles[--particleIdx];
				$particlePool.fixed = true;
				__particles = null;
			}
			__effect.clearData();
			
			// link cache to next waiting system
			if ($fixedPool)
			{
				for (var i:int = 0; i < $instances.length; ++i)
				{
					var instance:FFParticleSystem = $instances[i];
					if (instance != this && !instance.__completed && instance.__playing && instance.parent && instance.__particles == null)
					{
						if (instance.getParticlesFromPool())
							break;
					}
				}
			}
		}
		
		private function updateEmissionRate():void
		{
			emissionRate = __maxNumParticles / __lifespan;
		}
		
		/** @inheritDoc */
		override public function get alpha():Number
		{
			return __alpha;
		}
		
		override public function set alpha(value:Number):void
		{
			__alpha = value;
		}
		
		/**
		 * Enables/Disables System internal batching.
		 *
		 * Only FFParticleSystems which share the same parent and are siblings next to each other, can be batched.
		 * Of course the rules of "stateChanges" also apply.
		 * @see #isStateChange()
		 */
		public function get batching():Boolean
		{
			return __batching;
		}
		
		public function set batching(value:Boolean):void
		{
			__batching = value;
		}
		
		/**
		 * Source blend factor of the particles.
		 *
		 * @see #blendFactorDestination
		 * @see flash.display3D.Context3DBlendFactor
		 */
		public function get blendFuncSource():String
		{
			return __blendFuncSource;
		}
		
		public function set blendFuncSource(value:String):void
		{
			__blendFuncSource = value;
			updateBlendMode();
		}
		
		/**
		 * Destination blend factor of the particles.
		 * @see #blendFactorSource
		 * @see flash.display3D.Context3DBlendFactor;
		 */
		public function get blendFuncDestination():String
		{
			return __blendFuncDestination;
		}
		
		public function set blendFuncDestination(value:String):void
		{
			__blendFuncDestination = value;
			updateBlendMode();
		}
		
		/**
		 * Returns complete state of the system. The value is true if the system is done or has been
		 * stopped with the parameter clear.
		 */
		
		public function get completed():Boolean
		{
			return __completed;
		}
		
		/**
		 * A custom function that can be applied to run code after every particle
		 * has been advanced, (sorted) and before it will be written to buffers/uploaded to the GPU.
		 *
		 * @default undefined
		 */
		public function set customFunction(customFunction:Function):void
		{
			__customFunction = customFunction;
		}
		
		public function get customFunction():Function
		{
			return __customFunction;
		}
		
		/**
		 * The number of particles, currently used by the system. (Not necessaryly all of them are visible).
		 */
		public function get numParticles():int
		{
			return __numParticles;
		}
		
		/**
		 * The duration of one animation cycle.
		 */
		public function get cycleDuration():Number
		{
			return __maxNumParticles / __emissionRate;
		}
		
		/**
		 * Number of emitted particles/second.
		 */
		public function get emissionRate():Number
		{
			return __emissionRate;
		}
		
		public function set emissionRate(value:Number):void
		{
			__emissionRate = value;
		}
		
		/**
		 * Angle of the emitter in degrees.
		 */
		public function get emitAngle():Number
		{
			return __emitAngle;
		}
		
		public function set emitAngle(value:Number):void
		{
			__emitAngle = value;
		}
		
		/**
		 * Wheather the particles rotation should respect the emit angle at birth or not.
		 */
		public function set emitAngleAlignedRotation(value:Boolean):void
		{
			__emitAngleAlignedRotation = value;
		}
		
		public function get emitAngleAlignedRotation():Boolean
		{
			return __emitAngleAlignedRotation;
		}
		
		/**
		 * Variance of the emit angle in degrees.
		 */
		public function get emitAngleVariance():Number
		{
			return __emitAngleVariance;
		}
		
		public function set emitAngleVariance(value:Number):void
		{
			__emitAngleVariance = value;
		}
		
		/**
		 * The type of the emitter.
		 *
		 * @see #EMITTER_TYPE_GRAVITY
		 * @see #EMITTER_TYPE_RADIAL
		 */
		public function get emitterType():int
		{
			return __emitterType;
		}
		
		public function set emitterType(value:int):void
		{
			__emitterType = value;
		}
		
		/**
		 * An Object setting the emitter position automatically.
		 *
		 * @see #emitter
		 * @see #emitterX
		 * @see #emitterY
		 */
		public function get emitterObject():Object
		{
			return __emitterObject;
		}
		
		public function set emitterObject(obj:Object):void
		{
			__emitterObject = obj;
		}
		
		/**
		 * Emitter x position.
		 *
		 * @see #emitter
		 * @see #emitterObject
		 * @see #emitterY
		 */
		public function get emitterX():Number
		{
			return emitter.x;
		}
		
		public function set emitterX(value:Number):void
		{
			emitter.x = value;
		}
		
		/**
		 * Variance of the emitters x position.
		 *
		 * @see #emitter
		 * @see #emitterObject
		 * @see #emitterX
		 */
		public function get emitterXVariance():Number
		{
			return __emitterXVariance;
		}
		
		public function set emitterXVariance(value:Number):void
		{
			__emitterXVariance = value;
		}
		
		/**
		 * Emitter y position.
		 *
		 * @see #emitterX
		 * @see #emitterObject
		 * @see #emitter
		 */
		public function get emitterY():Number
		{
			return emitter.y;
		}
		
		public function set emitterY(value:Number):void
		{
			emitter.y = value;
		}
		
		/**
		 * Variance of the emitters position.
		 *
		 * @see #emitter
		 * @see #emitterObject
		 * @see #emitterY
		 */
		public function get emitterYVariance():Number
		{
			return __emitterYVariance;
		}
		
		public function set emitterYVariance(value:Number):void
		{
			__emitterYVariance = value;
		}
		
		/**
		 * Returns true if the system is currently emitting particles.
		 * @see playing
		 * @see start()
		 * @see stop()
		 */
		public function get emitting():Boolean
		{
			return Boolean(__emissionTime);
		}
		
		/**
		 * Final particle color.
		 * @see #endColor
		 * @see #startColor
		 * @see #startColorVariance
		 * @see #tinted
		 */
		public function get endColor():ColorArgb
		{
			return __endColor;
		}
		
		public function set endColor(value:ColorArgb):void
		{
			if (value)
				__endColor = value;
		}
		
		/**
		 * Variance of final particle color
		 * @see #endColorVariance
		 * @see #startColor
		 * @see #startColorVariance
		 * @see #tinted
		 */
		public function get endColorVariance():ColorArgb
		{
			return __endColorVariance;
		}
		
		public function set endColorVariance(value:ColorArgb):void
		{
			if (value)
				__endColorVariance = value;
		}
		
		/**
		 * Final particle rotation in degrees.
		 * @see #endRotationVariance
		 * @see #startRotation
		 * @see #startRotationVariance
		 */
		public function get endRotation():Number
		{
			return __endRotation;
		}
		
		public function set endRotation(value:Number):void
		{
			__endRotation = value;
		}
		
		/**
		 * Variation of final particle rotation in degrees.
		 * @see #endRotation
		 * @see #startRotation
		 * @see #startRotationVariance
		 */
		public function get endRotationVariance():Number
		{
			return __endRotationVariance;
		}
		
		public function set endRotationVariance(value:Number):void
		{
			__endRotationVariance = value;
		}
		
		/**
		 * Final particle size in pixels.
		 *
		 * The size is calculated according to the width of the texture.
		 * If the particle is animated and SubTextures have differnt dimensions, the size is
		 * based on the width of the first frame.
		 *
		 * @see #endSizeVariance
		 * @see #startSize
		 * @see #startSizeVariance
		 */
		public function get endSize():Number
		{
			return __endSize;
		}
		
		public function set endSize(value:Number):void
		{
			__endSize = value;
		}
		
		/**
		 * Variance of the final particle size in pixels.
		 * @see #endSize
		 * @see #startSize
		 * @see #startSizeVariance
		 */
		public function get endSizeVariance():Number
		{
			return __endSizeVariance;
		}
		
		public function set endSizeVariance(value:Number):void
		{
			__endSizeVariance = value;
		}
		
		/**
		 * Whether the bounds of the particle system will be calculated or set to screen size.
		 * The bounds will be used for clipping while rendering, therefore depending on the size;
		 * the number of particles; applied filters etc. this setting might in-/decrease performance.
		 *
		 * Keep in mind:
		 * - that the bounds of batches will be united.
		 * - filters may have to change the texture size (performance impact)
		 *
		 * @see #getBounds()
		 */
		public function get exactBounds():Boolean
		{
			return __exactBounds;
		}
		
		public function set exactBounds(value:Boolean):void
		{
			__bounds = value ? new Rectangle() : null;
			__exactBounds = value;
		}
		
		/**
		 * The time to fade in spawning particles; set as percentage according to it's livespan.
		 */
		public function get fadeInTime():Number
		{
			return __fadeInTime;
		}
		
		public function set fadeInTime(value:Number):void
		{
			__fadeInTime = Math.max(0, Math.min(value, 1));
		}
		
		/**
		 * The time to fade out dying particles; set as percentage according to it's livespan.
		 */
		public function get fadeOutTime():Number
		{
			return __fadeOutTime;
		}
		
		public function set fadeOutTime(value:Number):void
		{
			__fadeOutTime = Math.max(0, Math.min(value, 1));
		}
		
		/**
		 * The horizontal gravity value.
		 * @see #EMITTER_TYPE_GRAVITY
		 */
		public function get gravityX():Number
		{
			return __gravityX;
		}
		
		public function set gravityX(value:Number):void
		{
			__gravityX = value;
		}
		
		/**
		 * The vertical gravity value.
		 * @see #EMITTER_TYPE_GRAVITY
		 */
		public function get gravityY():Number
		{
			return __gravityY;
		}
		
		public function set gravityY(value:Number):void
		{
			__gravityY = value;
		}
		
		/**
		 * Lifespan of each particle in seconds.
		 * Setting this value also affects the emissionRate which is calculated in the following way
		 *
		 * 		emissionRate = maxNumParticles / mLifespan
		 *
		 * @see #emissionRate
		 * @see #maxNumParticles
		 * @see #lifespanVariance
		 */
		public function get lifespan():Number
		{
			return __lifespan;
		}
		
		public function set lifespan(value:Number):void
		{
			__lifespan = Math.max(0.01, value);
			__lifespanVariance = Math.min(__lifespan, __lifespanVariance);
			updateEmissionRate();
		}
		
		/**
		 * Variance of the particles lifespan.
		 * Setting this value does NOT affect the emissionRate.
		 * @see #lifespan
		 */
		public function get lifespanVariance():Number
		{
			return __lifespanVariance;
		}
		
		public function set lifespanVariance(value:Number):void
		{
			__lifespanVariance = Math.min(__lifespan, value);
		}
		
		/**
		 * The maximum number of particles taken from the particle pool between 1 and 16383
		 * Changeing this value while the system is running may impact performance.
		 *
		 * @see #maxCapacity
		 */
		public function get maxNumParticles():uint
		{
			return __maxNumParticles;
		}
		
		public function set maxNumParticles(value:uint):void
		{
			returnParticlesToPool();
			__effect.maxCapacity = value;
			__maxNumParticles = __effect.maxCapacity;
			var success:Boolean = getParticlesFromPool();
			if (!success)
				stop();
			
			updateEmissionRate();
		}
		
		/**
		 * The maximum emitter radius.
		 * @see #maxRadiusVariance
		 * @see #EMITTER_TYPE_RADIAL
		 */
		public function get maxRadius():Number
		{
			return __maxRadius;
		}
		
		public function set maxRadius(value:Number):void
		{
			__maxRadius = value;
		}
		
		/**
		 * Variance of the emitter's maximum radius.
		 * @see #maxRadius
		 * @see #EMITTER_TYPE_RADIAL
		 */
		public function get maxRadiusVariance():Number
		{
			return __maxRadiusVariance;
		}
		
		public function set maxRadiusVariance(value:Number):void
		{
			__maxRadiusVariance = value;
		}
		
		/**
		 * The minimal emitter radius.
		 * @see #EMITTER_TYPE_RADIAL
		 */
		public function get minRadius():Number
		{
			return __minRadius;
		}
		
		public function set minRadius(value:Number):void
		{
			__minRadius = value;
		}
		
		/**
		 * The minimal emitter radius variance.
		 * @see #EMITTER_TYPE_RADIAL
		 */
		public function get minRadiusVariance():Number
		{
			return __minRadiusVariance;
		}
		
		public function set minRadiusVariance(value:Number):void
		{
			__minRadiusVariance = value;
		}
		
		/**
		 * The number of unused particles remaining in the particle pool.
		 */
		public static function get particlesInPool():uint
		{
			return $particlePool.length;
		}
		
		/**
		 * Whether the system is playing or paused.
		 *
		 * <p><strong>Note:</strong> If you're not using automaticJugglermanagement the returned value may be wrong.</p>
		 * @see emitting
		 */
		public function get playing():Boolean
		{
			return __playing;
		}
		
		/**
		 * The number of all particles created for the particle pool.
		 */
		public static function get poolSize():uint
		{
			return $poolSize;
		}
		
		/**
		 * Overrides the standard premultiplied alpha value set by the system.
		 */
		public function get premultipliedAlpha():Boolean
		{
			return __premultipliedAlpha;
		}
		
		public function set premultipliedAlpha(value:Boolean):void
		{
			__premultipliedAlpha = value;
		}
		
		/**
		 * Radial acceleration of particles.
		 * @see #radialAccelerationVariance
		 * @see #EMITTER_TYPE_GRAVITY
		 */
		public function get radialAcceleration():Number
		{
			return __radialAcceleration;
		}
		
		public function set radialAcceleration(value:Number):void
		{
			__radialAcceleration = value;
		}
		
		/**
		 * Variation of the particles radial acceleration.
		 * @see #radialAcceleration
		 * @see #EMITTER_TYPE_GRAVITY
		 */
		public function get radialAccelerationVariance():Number
		{
			return __radialAccelerationVariance;
		}
		
		public function set radialAccelerationVariance(value:Number):void
		{
			__radialAccelerationVariance = value;
		}
		
		/**
		 * If this property is set to a number, new initiated particles will start at a random frame.
		 * This can be done even though isAnimated is false.
		 */
		public function get randomStartFrames():Boolean
		{
			return __randomStartFrames;
		}
		
		public function set randomStartFrames(value:Boolean):void
		{
			__randomStartFrames = value;
		}
		
		/**
		 * Particles rotation per second in degerees.
		 * @see #rotatePerSecondVariance
		 */
		public function get rotatePerSecond():Number
		{
			return __rotatePerSecond;
		}
		
		public function set rotatePerSecond(value:Number):void
		{
			__rotatePerSecond = value;
		}
		
		/**
		 * Variance of the particles rotation per second in degerees.
		 * @see #rotatePerSecond
		 */
		public function get rotatePerSecondVariance():Number
		{
			return __rotatePerSecondVariance;
		}
		
		public function set rotatePerSecondVariance(value:Number):void
		{
			__rotatePerSecondVariance = value;
		}
		
		/**
		 *  Sets the smoothing of the texture.
		 *  It's not recommended to change this value.
		 *  @default TextureSmoothing.BILINEAR
		 */
		public function get smoothing():String
		{
			return __smoothing;
		}
		
		public function set smoothing(value:String):void
		{
			if (TextureSmoothing.isValid(value))
				__smoothing = value;
		}
		
		/**
		 * A custom function that can be set to sort the Vector of particles.
		 * It will only be called if particles get added/removed.
		 * Anyway it should only be applied if absolutely necessary.
		 * Keep in mind, that it sorts the complete Vector.<Particle> and not just the active particles!
		 *
		 * @default undefined
		 * @see Vector#sort()
		 */
		public function set sortFunction(sortFunction:Function):void
		{
			__sortFunction = sortFunction;
		}
		
		public function get sortFunction():Function
		{
			return __sortFunction;
		}
		
		/**
		 * The particles start color.
		 * @see #startColorVariance
		 * @see #endColor
		 * @see #endColorVariance
		 * @see #tinted
		 */
		public function get startColor():ColorArgb
		{
			return __startColor;
		}
		
		public function set startColor(value:ColorArgb):void
		{
			if (value)
				__startColor = value;
		}
		
		/**
		 * Variance of the particles start color.
		 * @see #startColor
		 * @see #endColor
		 * @see #endColorVariance
		 * @see #tinted
		 */
		public function get startColorVariance():ColorArgb
		{
			return __startColorVariance;
		}
		
		public function set startColorVariance(value:ColorArgb):void
		{
			if (value)
				__startColorVariance = value;
		}
		
		/**
		 * The particles start size.
		 *
		 * The size is calculated according to the width of the texture.
		 * If the particle is animated and SubTextures have differnt dimensions, the size is
		 * based on the width of the first frame.
		 *
		 * @see #startSizeVariance
		 * @see #endSize
		 * @see #endSizeVariance
		 */
		public function get startSize():Number
		{
			return __startSize;
		}
		
		public function set startSize(value:Number):void
		{
			__startSize = value;
		}
		
		/**
		 * Variance of the particles start size.
		 * @see #startSize
		 * @see #endSize
		 * @see #endSizeVariance
		 */
		public function get startSizeVariance():Number
		{
			return __startSizeVariance;
		}
		
		public function set startSizeVariance(value:Number):void
		{
			__startSizeVariance = value;
		}
		
		/**
		 * Start rotation of the particle in degrees.
		 * @see #startRotationVariance
		 * @see #endRotation
		 * @see #endRotationVariance
		 */
		public function get startRotation():Number
		{
			return __startRotation;
		}
		
		public function set startRotation(value:Number):void
		{
			__startRotation = value;
		}
		
		/**
		 * Variation of the particles start rotation in degrees.
		 * @see #startRotation
		 * @see #endRotation
		 * @see #endRotationVariance
		 */
		public function get startRotationVariance():Number
		{
			return __startRotationVariance;
		}
		
		public function set startRotationVariance(value:Number):void
		{
			__startRotationVariance = value;
		}
		
		/**
		 * The time to scale new born particles from 0 to it's actual size; set as percentage according to it's livespan.
		 */
		public function get spawnTime():Number
		{
			return __spawnTime;
		}
		
		public function set spawnTime(value:Number):void
		{
			__spawnTime = Math.max(0, Math.min(value, 1));
		}
		
		/**
		 * The particles velocity in pixels.
		 * @see #speedVariance
		 */
		public function get speed():Number
		{
			return __speed;
		}
		
		public function set speed(value:Number):void
		{
			__speed = value;
		}
		
		/**
		 * Variation of the particles velocity in pixels.
		 * @see #speed
		 */
		public function get speedVariance():Number
		{
			return __speedVariance;
		}
		
		public function set speedVariance(value:Number):void
		{
			__speedVariance = value;
		}
		
		/**
		 * Tangential acceleration of particles.
		 * @see #EMITTER_TYPE_GRAVITY
		 */
		public function get tangentialAcceleration():Number
		{
			return __tangentialAcceleration;
		}
		
		public function set tangentialAcceleration(value:Number):void
		{
			__tangentialAcceleration = value;
		}
		
		/**
		 * Variation of the particles tangential acceleration.
		 * @see #EMITTER_TYPE_GRAVITY
		 */
		public function get tangentialAccelerationVariance():Number
		{
			return __tangentialAccelerationVariance;
		}
		
		public function set tangentialAccelerationVariance(value:Number):void
		{
			__tangentialAccelerationVariance = value;
		}
		
		/**
		 * The Texture/SubTexture which has been passed to the constructor.
		 */
		public function get texture():Texture
		{
			return __texture;
		}
		
		/**
		 * Enables/Disables particle coloring
		 * @see #startColor
		 * @see #startColorVariance
		 * @see #endColor
		 * @see #endColorVariance
		 */
		public function get tinted():Boolean
		{
			return __tinted;
		}
		
		public function set tinted(value:Boolean):void
		{
			__tinted = value;
		}
		
		/**
		 * Juggler to use when <a href="#automaticJugglerManagement">automaticJugglerManagement</a>
		 * is active.
		 * @see #automaticJugglerManagement
		 */
		public function get juggler():Juggler
		{
			return __juggler;
		}
		
		public function set juggler(value:Juggler):void
		{
			// Not null and different required
			if (value == null || value == __juggler)
				return;
			
			// Remove from current and add to new if needed
			if (__juggler.contains(this))
			{
				__juggler.remove(this);
				value.add(this);
			}
			
			__juggler = value;
		}
		
		override public function set x(value:Number):void  { throw new Error('Not supported by FFParticleSystem - use emitterX instead'); }
		
		override public function set y(value:Number):void  { throw new Error('Not supported by FFParticleSystem - use emitterY instead'); }
		
		override public function set rotation(value:Number):void  { throw new Error('Not supported by FFParticleSystem'); }
		
		override public function set scale(value:Number):void  { throw new Error('Not supported by FFParticleSystem'); }
		
		override public function set scaleX(value:Number):void  { throw new Error('Not supported by FFParticleSystem'); }
		
		override public function set scaleY(value:Number):void  { throw new Error('Not supported by FFParticleSystem'); }
		
		override public function set skewX(value:Number):void  { throw new Error('Not supported by FFParticleSystem'); }
		
		override public function set skewY(value:Number):void  { throw new Error('Not supported by FFParticleSystem'); }
		
		override public function set pivotX(value:Number):void  { throw new Error('Not supported by FFParticleSystem'); }
		
		override public function set pivotY(value:Number):void  { throw new Error('Not supported by FFParticleSystem'); }
		
		override public function set transformationMatrix(value:Matrix):void  { throw new Error('Not supported by FFParticleSystem'); }
	
	}
}
