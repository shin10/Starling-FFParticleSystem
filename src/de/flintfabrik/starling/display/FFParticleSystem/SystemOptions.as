// =================================================================================================
//
//	Starling Framework - Particle System Extension
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package de.flintfabrik.starling.display.FFParticleSystem
{
	import de.flintfabrik.starling.display.FFParticleSystem.Frame;
	import de.flintfabrik.starling.utils.ColorArgb;
	import flash.display3D.Context3DBlendFactor;
	import flash.geom.Rectangle;
	import starling.textures.*;
	
	/**
	 * The SystemOption object is ment to interprete given PEX and TextureAtlas xml files
	 * cache and modify the values for instanciation of a particle system, since XML parsing
	 * is extremly expensive.
	 */
	public class SystemOptions
	{
		private var mFirstFrameName:String = "";
		private var mLastFrameName:String = "";
		
		/**
		 * The number of frames to animate, alternatively to setting the index with lastFrame.
		 */
		public var animationLength:Number = 1;
		/**
		 * A Boolean setting whether the texture should be animated or not.
		 */
		public var isAnimated:Boolean = false;
		/**
		 * A int to set the first frames index in the texture atlas.
		 */
		public var firstFrame:uint = 0;
		/**
		 * A int to set the last frames index in the texture atlas.
		 * -1 will be set the last frame to the highest value possible.
		 */
		public var lastFrame:int = -1;
		/**
		 * A uint (1 or higher) setting the number of animation loops if the texture is animated.
		 */
		public var loops:uint = 1;
		/**
		 * A Boolean setting whether the initial frame should be chosen randomly.
		 */
		public var randomStartFrames:Boolean = false;
		
		/**
		 * A Boolean setting whether particles shall be tinted.
		 */
		public var tinted:Boolean = true;
		
		/**
		 * A Number between 0 and 1 setting the timespan to fade in particles.
		 */
		public var spawnTime:Number = 0;
		
		/**
		 * A Number between 0 and 1 setting the timespan to fade in particles.
		 */
		public var fadeInTime:Number = 0;
		
		/**
		 * A Number between 0 and 1 setting the timespan to fade out particles.
		 */
		public var fadeOutTime:Number = 0;
		
		/**
		 * A uint setting the emitter type to EMITTER_TYPE_GRAVITY:int = 0; or
		 * EMITTER_TYPE_RADIAL:int = 1;
		 */
		public var emitterType:Number = 0;
		/**
		 * A uint setting the maximum number of particles used by this FFParticleSystem
		 */
		public var maxParticles:uint = 10;
		/**
		 * The horizontal emitter position
		 */
		public var sourceX:Number = 0;
		/**
		 * The vertical emitter position
		 */
		public var sourceY:Number = 0;
		
		public var sourceVarianceX:Number = 0;
		public var sourceVarianceY:Number = 0;
		public var particleLifeSpan:Number = 1;
		public var particleLifespanVariance:Number = 0;
		public var angle:Number = 0;
		public var angleVariance:Number = 0;
		/**
		 * Aligns the particles to their emit angle at birth.
		 * 
		 * @see angle
		 */
		public var emitAngleAlignedRotation:Boolean = false;
		public var startParticleSize:Number = 20;
		public var startParticleSizeVariance:Number = 0;
		public var finishParticleSize:Number = 20;
		public var finishParticleSizeVariance:Number = 0;
		public var rotationStart:Number = 0;
		public var rotationStartVariance:Number = 0;
		public var rotationEnd:Number = 0;
		public var rotationEndVariance:Number = 0;
		/**
		 * The emission time span. Pass to -1 set the emission time to infinite.
		 */
		public var duration:Number = 2;
		
		public var gravityX:Number = 0;
		public var gravityY:Number = 0;
		/**
		 * The speed of a particle in pixel per seconds.
		 */
		public var speed:Number = 50;
		public var speedVariance:Number = 0;
		
		public var radialAcceleration:Number = 0;
		public var radialAccelerationVariance:Number = 0;
		public var tangentialAcceleration:Number = 0;
		public var tangentialAccelerationVariance:Number = 0;
		
		public var maxRadius:Number = 100;
		public var maxRadiusVariance:Number = 0;
		public var minRadius:Number = 0;
		public var rotatePerSecond:Number = 0;
		public var rotatePerSecondVariance:Number = 0;
		
		public var startColor:ColorArgb;
		public var startColorVariance:ColorArgb;
		public var finishColor:ColorArgb;
		public var finishColorVariance:ColorArgb;
		
		public var customFunction:Function;
		public var sortFunction:Function;
		public var forceSortFlag:Boolean = false;
		
		/**
		 * Sets the blend function for rendering the source.
		 * @see #blendFactorDestination
		 * @see flash.display3D.Context3DBlendFactor
		 */
		public var blendFuncSource:String = Context3DBlendFactor.ONE;
		/**
		 * Sets the blend function for rendering the destination.
		 * @see #blendFactorSource
		 * @see flash.display3D.Context3DBlendFactor
		 */
		public var blendFuncDestination:String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
		
		/**
		 * A Boolean that determines whether the FFParticleSystem should calculate it's exact bounds or return stage dimensions
		 */
		public var excactBounds:Boolean = false;
		
		/**
		 * The look up table containing information about all frames within the animation
		 */
		public var mFrameLUT:Vector.<Frame>;
		
		public function get frameLUT():Vector.<Frame>
		{
			if (!mFrameLUT)
				updateFrameLUT();
			return mFrameLUT;
		}
		/**
		 * The texture used by the particle system.
		 */
		public var texture:Texture;
		/**
		 * The atlas xml file for the used texture
		 */
		public var atlasXML:XML;
		
		/**
		 * Creates a new SystemOptions instance.
		 * 
		 * @see fromXML()
		 * @see clone()
		 */
		public function SystemOptions(texture:Texture, atlasXML:XML = null, config:XML = null)
		{
			if (!texture)
				throw new Error("texture must not be null");
			
			this.texture = texture;
			this.atlasXML = atlasXML;
			
			if (config)
				SystemOptions.fromXML(config, texture, atlasXML, this);
		}
		
		/**
		 * Modifies given properties of a SystemOptions instance.
		 * @param	object
		 * @return	A new SystemOptions instance with given parameters
		 */
		public function appendFromObject(object:Object):SystemOptions
		{
			if (texture)
				this.texture = texture;
			if (atlasXML)
				this.atlasXML = atlasXML;
			
			for (var p:String in object)
			{
				try
				{
					this[p] = object[p];
				}
				catch (err:*)
				{
					trace(err.toString());
				}
			}
			
			updateFrameLUT();
			
			return this;
		}
		
		/**
		 * Returns a copy of the SystemOptions instance.
		 * @param	systemOptions A SystemOptions instance
		 * @return	A new SystemOptions instance with given parameters
		 */
		public function clone(target:SystemOptions = null):SystemOptions
		{
			if (!target)
				target = new SystemOptions(this.texture, this.atlasXML);
			
			target.texture = texture;
			target.atlasXML = atlasXML;
			
			target.sourceX = this.sourceX;
			target.sourceY = this.sourceY;
			target.sourceVarianceX = this.sourceVarianceX;
			target.sourceVarianceY = this.sourceVarianceY;
			target.gravityX = this.gravityX;
			target.gravityY = this.gravityY;
			target.emitterType = this.emitterType;
			target.maxParticles = this.maxParticles;
			target.particleLifeSpan = this.particleLifeSpan;
			target.particleLifespanVariance = this.particleLifespanVariance;
			target.startParticleSize = this.startParticleSize;
			target.startParticleSizeVariance = this.startParticleSizeVariance;
			target.finishParticleSize = this.finishParticleSize;
			target.finishParticleSizeVariance = this.finishParticleSizeVariance;
			target.angle = this.angle;
			target.angleVariance = this.angleVariance;
			target.rotationStart = this.rotationStart;
			target.rotationStartVariance = this.rotationStartVariance;
			target.rotationEnd = this.rotationEnd;
			target.rotationEndVariance = this.rotationEndVariance;
			target.emitAngleAlignedRotation = this.emitAngleAlignedRotation;
			target.speed = this.speed;
			target.speedVariance = this.speedVariance;
			target.radialAcceleration = this.radialAcceleration;
			target.radialAccelerationVariance = this.radialAccelerationVariance;
			target.tangentialAcceleration = this.tangentialAcceleration;
			target.tangentialAccelerationVariance = this.tangentialAccelerationVariance;
			target.maxRadius = this.maxRadius;
			target.maxRadiusVariance = this.maxRadiusVariance;
			target.minRadius = this.minRadius;
			target.rotatePerSecond = this.rotatePerSecond;
			target.rotatePerSecondVariance = this.rotatePerSecondVariance;
			target.startColor = this.startColor;
			target.startColorVariance = this.startColorVariance;
			target.finishColor = this.finishColor;
			target.finishColorVariance = this.finishColorVariance;
			target.blendFuncSource = this.blendFuncSource;
			target.blendFuncDestination = this.blendFuncDestination;
			target.duration = this.duration;
			
			target.isAnimated = this.isAnimated;
			target.firstFrameName = this.firstFrameName;
			target.firstFrame = this.firstFrame;
			target.lastFrameName = this.lastFrameName;
			target.lastFrame = this.lastFrame;
			target.lastFrame = this.lastFrame;
			target.loops = this.loops;
			target.randomStartFrames = this.randomStartFrames;
			target.tinted = this.tinted;
			target.spawnTime = this.spawnTime;
			target.fadeInTime = this.fadeInTime;
			target.fadeOutTime = this.fadeOutTime;
			target.excactBounds = this.excactBounds;
			
			target.customFunction = this.customFunction;
			target.sortFunction = this.sortFunction;
			target.forceSortFlag = this.forceSortFlag;
			
			target.mFrameLUT = this.mFrameLUT;
			
			return target;
		}
		
		/**
		 * Interpretation of the .pex config XML
		 * @param	config
		 */
		public static function fromXML(config:XML, texture:Texture, atlasXML:XML = null, target:SystemOptions = null):SystemOptions
		{
			if (!target)
				target = new SystemOptions(texture, atlasXML);
			
			target.texture = texture;
			target.atlasXML = atlasXML;
			
			target.sourceX = parseFloat(config.sourcePosition.attribute("x"));
			target.sourceY = parseFloat(config.sourcePosition.attribute("y"));
			target.sourceVarianceX = parseFloat(config.sourcePositionVariance.attribute("x"));
			target.sourceVarianceY = parseFloat(config.sourcePositionVariance.attribute("y"));
			target.gravityX = parseFloat(config.gravity.attribute("x"));
			target.gravityY = parseFloat(config.gravity.attribute("y"));
			target.emitterType = getIntValue(config.emitterType);
			target.maxParticles = getIntValue(config.maxParticles);
			target.particleLifeSpan = Math.max(0.01, getFloatValue(config.particleLifeSpan));
			target.particleLifespanVariance = getFloatValue(config.particleLifespanVariance);
			target.startParticleSize = getFloatValue(config.startParticleSize);
			target.startParticleSizeVariance = getFloatValue(config.startParticleSizeVariance);
			target.finishParticleSize = getFloatValue(config.finishParticleSize);
			target.finishParticleSizeVariance = getFloatValue(config.FinishParticleSizeVariance);
			target.angle = getFloatValue(config.angle);
			target.angleVariance = getFloatValue(config.angleVariance);
			target.rotationStart = getFloatValue(config.rotationStart);
			target.rotationStartVariance = getFloatValue(config.rotationStartVariance);
			target.rotationEnd = getFloatValue(config.rotationEnd);
			target.rotationEndVariance = getFloatValue(config.rotationEndVariance);
			target.emitAngleAlignedRotation = getIntValue(config.emitAngleAlignedRotation);
			target.speed = getFloatValue(config.speed);
			target.speedVariance = getFloatValue(config.speedVariance);
			target.radialAcceleration = getFloatValue(config.radialAcceleration);
			target.radialAccelerationVariance = getFloatValue(config.radialAccelVariance);
			target.tangentialAcceleration = getFloatValue(config.tangentialAcceleration);
			target.tangentialAccelerationVariance = getFloatValue(config.tangentialAccelVariance);
			target.maxRadius = getFloatValue(config.maxRadius);
			target.maxRadiusVariance = getFloatValue(config.maxRadiusVariance);
			target.minRadius = getFloatValue(config.minRadius);
			target.rotatePerSecond = getFloatValue(config.rotatePerSecond);
			target.rotatePerSecondVariance = getFloatValue(config.rotatePerSecondVariance);
			target.startColor = getColor(config.startColor);
			target.startColorVariance = getColor(config.startColorVariance);
			target.finishColor = getColor(config.finishColor);
			target.finishColorVariance = getColor(config.finishColorVariance);
			target.blendFuncSource = getBlendFunc(config.blendFuncSource);
			target.blendFuncDestination = getBlendFunc(config.blendFuncDestination);
			target.duration = getFloatValue(config.duration);
			
			// new introduced properties //
			if (config.animation.length())
			{
				//var atlasName:String = config.animation.atlas.@name // not used ... just some info to identify the actual textureAtlas.xml file name, and debugging
				
				var node:XMLList = config.animation.isAnimated;
				
				if (node.length())
					target.isAnimated = getBooleanValue(node) && atlasXML;
				
				node = config.animation.firstFrame;
				if (node.length())
				{
					target.firstFrameName = node.attribute("value");
					if (target.firstFrameName == "")
						target.firstFrame = getIntValue(node);
				}
				
				node = config.animation.lastFrame;
				if (node.length())
				{
					target.lastFrameName = node.attribute("value");
					if (target.lastFrameName == "")
						target.lastFrame = getIntValue(node);
				}
				
				node = config.animation.numberOfAnimatedFrames;
				if (node.length())
					target.lastFrame = (node.length() ? int(target.firstFrame) + (target.animationLength = getIntValue(node)) : target.lastFrame).toString();
				
				node = config.animation.loops;
				if (node.length())
					target.loops = getFloatValue(node);
				
				node = config.animation.randomStartFrames;
				if (node.length())
					target.randomStartFrames = getIntValue(node);
			}
			node = config.tinted;
			if (node.length())
				target.tinted = getIntValue(node);
			node = config.spawnTime;
			if (node.length())
				target.spawnTime = getFloatValue(node);
			node = config.fadeInTime;
			if (node.length())
				target.fadeInTime = getFloatValue(node);
			node = config.fadeOutTime;
			if (node.length())
				target.fadeOutTime = getFloatValue(node);
			node = config.excactBounds;
			if (node.length())
				target.excactBounds = getBooleanValue(node);
			// end of new properties // 
			
			target.updateFrameLUT();
			
			return target;
		}
		
		private static function getFrameIdx(value:String, atlasXML:XML):int
		{
			if (atlasXML && isNaN(Number(value)))
			{
				var idx:int = atlasXML.SubTexture.(@name == value).childIndex();
				if (idx == -1)
					trace('frame "' + value + '" not found in atlas!');
				return idx;
			}
			else
			{
				return int(value);
			}
		}
		
		private static function getBooleanValue(element:XMLList):Boolean
		{
			var valueStr:String = element.attribute("value").toLowerCase();
			var valueInt:int = parseInt(element.attribute("value"));
			var result:Boolean = valueStr == "true" || valueInt > 0;
			return result;
		}
		
		private static function getIntValue(element:XMLList):int
		{
			return parseInt(element.attribute("value"));
		}
		
		private static function getFloatValue(element:XMLList):Number
		{
			return parseFloat(element.attribute("value"));
		}
		
		private static function getColor(element:XMLList):ColorArgb
		{
			var color:ColorArgb = new ColorArgb();
			color.red = parseFloat(element.attribute("red"));
			color.green = parseFloat(element.attribute("green"));
			color.blue = parseFloat(element.attribute("blue"));
			color.alpha = parseFloat(element.attribute("alpha"));
			return color;
		}
		
		private static function getBlendFunc(element:XMLList):String
		{
			var str:String = element.attribute("value");
			if (isNaN(Number(str)) && Context3DBlendFactor[str] !== undefined)
			{
				return Context3DBlendFactor[str];
			}
			var value:int = getIntValue(element);
			switch (value)
			{
				case 0: 
					return Context3DBlendFactor.ZERO;
					break;
				case 1: 
					return Context3DBlendFactor.ONE;
					break;
				case 0x300: 
					return Context3DBlendFactor.SOURCE_COLOR;
					break;
				case 0x301: 
					return Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR;
					break;
				case 0x302: 
					return Context3DBlendFactor.SOURCE_ALPHA;
					break;
				case 0x303: 
					return Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
					break;
				case 0x304: 
					return Context3DBlendFactor.DESTINATION_ALPHA;
					break;
				case 0x305: 
					return Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA;
					break;
				case 0x306: 
					return Context3DBlendFactor.DESTINATION_COLOR;
					break;
				case 0x307: 
					return Context3DBlendFactor.ONE_MINUS_DESTINATION_COLOR;
					break;
				default: 
					throw new ArgumentError("unsupported blending function: " + value);
			}
		}
		
		/**
		 * Parsies the texture atlas xml and stores subtexture positions/dimensions in a look up table.
		 * If the texture is a SubTexture, it will also look for this frame in the texture atlas, to set this SubTexture as first frame.
		 *
		 * <p>Note: each frame will be stored once <i>per loop</i> in frameLUT since the modulo operator is expensive.</p>
		 * @param	atlasXml
		 * @param	texture
		 */
		public function updateFrameLUT():void
		{
			mFrameLUT = new <Frame>[];
			
			if (atlasXML)
			{
				var scale:Number = texture.scale;
				var w:int = texture.root.nativeWidth;
				var h:int = texture.root.nativeHeight;
				
				firstFrame = Math.min(firstFrame, atlasXML.SubTexture.length() - 1)
				lastFrame = lastFrame == -1 ? atlasXML.SubTexture.length() : lastFrame;
				
				if (texture && texture is SubTexture)
				{
					// look for subtexture with same properties as the subtexture, on success we'll use it as firstFrame
					var st:SubTexture = (texture as SubTexture);
					var rect:Rectangle = st.clipping;
					
					rect.x *= st.root.nativeWidth;
					rect.y *= st.root.nativeHeight;
					rect.width *= st.root.nativeWidth;
					rect.height *= st.root.nativeHeight;
					
					var matches:XMLList = atlasXml.SubTexture.(@x == rect.x).(@y == rect.y).(@width == rect.width).(@height == rect.height);
					
					if (matches.length() >= 1 && firstFrame==0)
					{
						var idx:int = matches[0].childIndex();
						if (idx >= 0)
						{
							firstFrame = idx;
						}
					}
				}
				
				lastFrame = Math.max(firstFrame, Math.min(lastFrame, atlasXML.SubTexture.length() - 1));
				
				var animationLoopLength:int = lastFrame - firstFrame + 1;
				isAnimated = isAnimated && animationLoopLength > 1;
				loops = isAnimated ? loops + (randomStartFrames ? 1 : 0) : 1;
				animationLoopLength = isAnimated || randomStartFrames ? animationLoopLength : 1;
				for (var l:int = 0; l < loops; ++l)
				{
					for (var i:int = 0; i < animationLoopLength; ++i)
					{
						var subTexture:XML = atlasXML.SubTexture[i + firstFrame];
						var x:Number = parseFloat(subTexture.attribute("x")) / scale;
						var y:Number = parseFloat(subTexture.attribute("y")) / scale;
						var width:Number = parseFloat(subTexture.attribute("width")) / scale;
						var height:Number = parseFloat(subTexture.attribute("height")) / scale;
						mFrameLUT[i + l * animationLoopLength] = new Frame(w, h, x, y, width, height);
					}
				}
				
				var mNumberOfFrames:int = mFrameLUT.length - 1 - (randomStartFrames && isAnimated ? animationLoopLength : 0);
				var mFrameLUTLength:int = mFrameLUT.length - 1;
				isAnimated = isAnimated && mFrameLUT.length > 1;
				randomStartFrames = randomStartFrames && mFrameLUT.length > 1;
			}
			else
			{
				if (texture is SubTexture)
				{
					//subtexture
					var stex:SubTexture = texture as SubTexture;
					mFrameLUT[0] = new Frame(stex.root.nativeWidth, stex.root.nativeHeight, stex.clipping.x * stex.root.nativeWidth, stex.clipping.y * stex.root.nativeHeight, stex.clipping.width * stex.root.nativeWidth, stex.clipping.height * stex.root.nativeHeight);
				}
				else
				{
					//rootTexture
					mFrameLUT[0] = new Frame(texture.width, texture.height, 0, 0, texture.width, texture.height);
				}
			}
			
			mFrameLUT.fixed = true;
		}
		
		public function get firstFrameName():String
		{
			return mFirstFrameName;
		}
		
		public function set firstFrameName(value:String):void
		{
			var idx:int = getFrameIdx(value, atlasXML);
			if (idx != -1)
			{
				firstFrame = idx;
				mFirstFrameName = value;
			}
			else
			{
				mFirstFrameName = "";
			}
		}
		
		public function get lastFrameName():String
		{
			return mLastFrameName;
		}
		
		public function set lastFrameName(value:String):void
		{
			var idx:int = getFrameIdx(value, atlasXML);
			if (idx != -1)
			{
				lastFrame = getFrameIdx(value, atlasXML);
				mLastFrameName = value;
			}
			else
			{
				mLastFrameName = "";
			}
		}
	
	}
}