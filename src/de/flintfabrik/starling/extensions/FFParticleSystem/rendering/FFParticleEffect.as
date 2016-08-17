// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package de.flintfabrik.starling.extensions.FFParticleSystem.rendering
{
	import de.flintfabrik.starling.extensions.FFParticleSystem;
	import de.flintfabrik.starling.extensions.FFParticleSystem.*;
	import de.flintfabrik.starling.extensions.FFParticleSystem.Frame;
	import de.flintfabrik.starling.extensions.FFParticleSystem.Particle;
	import de.flintfabrik.starling.extensions.FFParticleSystem.core.ffparticlesystem_internal;
	import de.flintfabrik.starling.extensions.FFParticleSystem.utils.FFPS_LUT;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import starling.core.Starling;
	import starling.errors.MissingContextError;
	import starling.rendering.FilterEffect;
	import starling.rendering.Program;
	import starling.utils.RenderUtil;
	
	use namespace ffparticlesystem_internal;
	
	/**
	 *  FFParticleEffect
	 *
	 *  <p>For more information about the usage and creation of effects, please have a look at
	 *  the documentation of the root class, "Effect".</p>
	 *
	 *  @see Effect
	 *  @see FilterEffect
	 *  @see starling.styles.MeshStyle
	 *  @see de.flintfabrik.starling.styles.FFParticleStyle
	 */
	public class FFParticleEffect extends FilterEffect
	{
		public static const VERTICES_PER_PARTICLE:int = 4;
		public static const ELEMENTS_PER_VERTEX:int = 2 + 2 + 4;
		public static const ELEMENTS_PER_PARTICLE:int = VERTICES_PER_PARTICLE * ELEMENTS_PER_VERTEX;
		public static const MAX_CAPACITY:int = 16383;
		
		public static function get isSupported():Boolean
		{
			return true;
		}
		
		ffparticlesystem_internal static var _instances:Vector.<FFParticleSystem> = new Vector.<FFParticleSystem>(0, false);
		private static var $bufferSize:uint = 0;
		private static var $indices:Vector.<uint>;
		private static var $indexBuffer:IndexBuffer3D;
		private static var $vertexBufferIdx:int = -1;
		private static var $vertexBuffers:Vector.<VertexBuffer3D>;
		private static var $numberOfVertexBuffers:uint = 1;
		private static var $renderAlpha:Vector.<Number> = new Vector.<Number>(4, true);
		private static var $instances:Vector.<FFParticleSystem> = new Vector.<FFParticleSystem>(0, false);
		
		public var testParticleAlpha:Boolean = true;
		protected var _alpha:Number;
		private var __maxCapacity:int;
		private var __rawData:Vector.<Number> = new Vector.<Number>(0, true);
		
		/** Creates a new FFParticleEffect instance. */
		public function FFParticleEffect()
		{
			_alpha = 1.0;
		}
		
		/** @private */
		override protected function createProgram():Program
		{
			var vertexShader:String, fragmentShader:String;
			
			vertexShader = "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output clip-space
			"mov v0, va1      \n" + // pass texture coordinates to fragment program
			"mul v1, va2, vc4 \n";  // multiply alpha (vc4) with color (va2), pass to fp
			
			fragmentShader = tex("ft0", "v0", 0, texture) + // read texel color
			"mul oc, ft0, v1         \n"; // multiply texel color with color
			
			return Program.fromSource(vertexShader, fragmentShader);
		}
		
		override public function render(firstIndex:int = 0, numParticles:int = -1):void
		{
			if (!$vertexBuffers)
				return;
			
			if (numParticles < 0) numParticles = 0;
			if (numParticles == 0) return;
			
			var numTriangles:int = numParticles * 2;
			
			var context:Context3D = Starling.context;
			if (context == null) throw new MissingContextError();
			
			$vertexBufferIdx = ++$vertexBufferIdx % $numberOfVertexBuffers;
			var vertexBuffer:VertexBuffer3D = $vertexBuffers[$vertexBufferIdx];
			vertexBuffer.uploadFromVector(__rawData, 0, Math.min($bufferSize, numParticles) * 4);
			context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(2, vertexBuffer, 4, Context3DVertexBufferFormat.FLOAT_4);
			
			beforeDraw(context);
			context.drawTriangles($indexBuffer, firstIndex, numTriangles);
			afterDraw(context);
		
		}
		
		override protected function beforeDraw(context:Context3D):void
		{
			program.activate(context);
			$renderAlpha[0] = $renderAlpha[1] = $renderAlpha[2] = 1;
			$renderAlpha[3] = _alpha;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, $renderAlpha);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mvpMatrix3D, true);
			
			context.setTextureAt(0, texture.base);
			RenderUtil.setSamplerStateAt(0, texture.mipMapping, textureSmoothing, super.textureRepeat);
		}
		
		override protected function afterDraw(context:Context3D):void
		{
			context.setVertexBufferAt(2, null);
			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(0, null);
			context.setTextureAt(0, null);
		}
		
		/** The alpha value of the object rendered by the effect. Must be taken into account
		 *  by all subclasses. */
		public function get alpha():Number  { return _alpha; }
		
		public function set alpha(value:Number):void  { _alpha = value; }
		
		public function writeParticleDataToBuffers(particles:Vector.<Particle>, frameLUT:Vector.<Frame>, offset:int, numParticles:int, systemAlpha:Number = 1):uint
		{
			const DEG90RAD:Number = Math.PI * 0.5;
			
			var vertexID:int = 0;
			var particle:Particle;
			
			var red:Number;
			var green:Number;
			var blue:Number;
			var particleAlpha:Number;
			
			var rotation:Number;
			var x:Number, y:Number;
			var xOffset:Number, yOffset:Number;
			var frameDimensions:Frame;
			
			var angle:uint;
			var cos:Number;
			var sin:Number;
			var cosX:Number;
			var cosY:Number;
			var sinX:Number;
			var sinY:Number;
			var position:uint;
			var particlesWritten:int = -1;
			__rawData.fixed = false;
			
			for (var i:int = 0; i < numParticles; ++i)
			{
				particle = particles[i];
				
				particleAlpha = particle.colorAlpha * particle.fadeInFactor * particle.fadeOutFactor;
				
				if ((testParticleAlpha && particleAlpha <= 0) || particle.scale <= 0)
					continue;
				
				vertexID = (offset + ++particlesWritten) << 2;
				
				frameDimensions = frameLUT[particle.frameIdx];
				
				red = particle.colorRed;
				green = particle.colorGreen;
				blue = particle.colorBlue;
				particleAlpha *= systemAlpha;
				
				rotation = particle.rotation;
				if (frameDimensions.rotated)
				{
					rotation -= DEG90RAD;
				}
				
				x = particle.x;
				y = particle.y;
				
				xOffset = frameDimensions.particleHalfWidth * particle.scale * particle.spawnFactor;
				yOffset = frameDimensions.particleHalfHeight * particle.scale * particle.spawnFactor;
				
				if (rotation)
				{
					angle = (rotation * 325.94932345220164765467394738691) & 2047;
					cos = FFPS_LUT.cos[angle];
					sin = FFPS_LUT.sin[angle];
					cosX = cos * xOffset;
					cosY = cos * yOffset;
					sinX = sin * xOffset;
					sinY = sin * yOffset;
					
					position = vertexID << 3; // * ELEMENTS_PER_VERTEX
					__rawData[position] = x - cosX + sinY;
					__rawData[++position] = y - sinX - cosY;
					__rawData[++position] = frameDimensions.textureX;
					__rawData[++position] = frameDimensions.textureY;
					__rawData[++position] = red;
					__rawData[++position] = green;
					__rawData[++position] = blue;
					__rawData[++position] = particleAlpha;
					
					__rawData[++position] = x + cosX + sinY;
					__rawData[++position] = y + sinX - cosY;
					__rawData[++position] = frameDimensions.textureWidth;
					__rawData[++position] = frameDimensions.textureY;
					__rawData[++position] = red;
					__rawData[++position] = green;
					__rawData[++position] = blue;
					__rawData[++position] = particleAlpha;
					
					__rawData[++position] = x - cosX - sinY;
					__rawData[++position] = y - sinX + cosY;
					__rawData[++position] = frameDimensions.textureX;
					__rawData[++position] = frameDimensions.textureHeight;
					__rawData[++position] = red;
					__rawData[++position] = green;
					__rawData[++position] = blue;
					__rawData[++position] = particleAlpha;
					
					__rawData[++position] = x + cosX - sinY;
					__rawData[++position] = y + sinX + cosY;
					__rawData[++position] = frameDimensions.textureWidth;
					__rawData[++position] = frameDimensions.textureHeight;
					__rawData[++position] = red;
					__rawData[++position] = green;
					__rawData[++position] = blue;
					__rawData[++position] = particleAlpha;
				}
				else
				{
					position = vertexID << 3; // * ELEMENTS_PER_VERTEX
					__rawData[position] = x - xOffset;
					__rawData[++position] = y - yOffset;
					__rawData[++position] = frameDimensions.textureX;
					__rawData[++position] = frameDimensions.textureY;
					__rawData[++position] = red;
					__rawData[++position] = green;
					__rawData[++position] = blue;
					__rawData[++position] = particleAlpha;
					
					__rawData[++position] = x + xOffset;
					__rawData[++position] = y - yOffset;
					__rawData[++position] = frameDimensions.textureWidth;
					__rawData[++position] = frameDimensions.textureY;
					__rawData[++position] = red;
					__rawData[++position] = green;
					__rawData[++position] = blue;
					__rawData[++position] = particleAlpha;
					
					__rawData[++position] = x - xOffset;
					__rawData[++position] = y + yOffset;
					__rawData[++position] = frameDimensions.textureX;
					__rawData[++position] = frameDimensions.textureHeight;
					__rawData[++position] = red;
					__rawData[++position] = green;
					__rawData[++position] = blue;
					__rawData[++position] = particleAlpha;
					
					__rawData[++position] = x + xOffset;
					__rawData[++position] = y + yOffset;
					__rawData[++position] = frameDimensions.textureWidth;
					__rawData[++position] = frameDimensions.textureHeight;
					__rawData[++position] = red;
					__rawData[++position] = green;
					__rawData[++position] = blue;
					__rawData[++position] = particleAlpha;
				}
			}
			
			__rawData.fixed = true;
			return ++particlesWritten;
		}
		
		public static function get buffersCreated():Boolean
		{
			return $vertexBuffers && $vertexBuffers[0];
		}
		
		public function get buffersCreated():Boolean
		{
			return FFParticleEffect.buffersCreated;
		}
		
		/**
		 * creating vertex and index buffers for the number of particles.
		 * @param	numParticles a value between 1 and 16383
		 */
		public static function createBuffers(bufferSize:uint = 0, numberOfBuffers:uint = 0):void
		{
			if (!bufferSize && $bufferSize)
				bufferSize = $bufferSize;
				
			if (bufferSize > MAX_CAPACITY)
			{
				bufferSize = MAX_CAPACITY;
				trace("Warning: bufferSize exceeds the limit and is set to it's maximum value (16383)");
			}
			else if (bufferSize <= 0)
			{
				bufferSize = MAX_CAPACITY;
				trace("Warning: bufferSize can't be lower than 1 and is set to it's maximum value (16383)");
			}
			$bufferSize = bufferSize;
			
			if (numberOfBuffers)
				$numberOfVertexBuffers = numberOfBuffers;
			
			if ($instances)
				for (var i:int = 0; i < $instances.length; ++i)
					$instances[i].dispose();
			
			if ($vertexBuffers)
				for (i = 0; i < $vertexBuffers.length; ++i)
					$vertexBuffers[i].dispose();
			
			if ($indexBuffer)
				$indexBuffer.dispose();
			
			var context:Context3D = Starling.context;
			if (context == null)
				throw new MissingContextError();
			if (context.driverInfo == "Disposed")
				return;
			
			$vertexBuffers = new Vector.<VertexBuffer3D>();
			$vertexBufferIdx = -1;
			
			if (ApplicationDomain.currentDomain.hasDefinition("flash.display3D.Context3DBufferUsage"))
			{
				for (i = 0; i < $numberOfVertexBuffers; ++i)
				{
					$vertexBuffers[i] = context.createVertexBuffer.call(context, $bufferSize * 4, ELEMENTS_PER_VERTEX, "dynamicDraw"); // Context3DBufferUsage.DYNAMIC_DRAW; hardcoded for backward compatibility
				}
			}
			else
			{
				for (i = 0; i < $numberOfVertexBuffers; ++i)
				{
					$vertexBuffers[i] = context.createVertexBuffer($bufferSize * 4, ELEMENTS_PER_VERTEX);
				}
			}
			
			var zeroBytes:ByteArray = new ByteArray();
			zeroBytes.length = $bufferSize * VERTICES_PER_PARTICLE * ELEMENTS_PER_PARTICLE; // numParticle * verticesPerParticle * ELEMENTS_PER_VERTEX
			for (i = 0; i < $numberOfVertexBuffers; ++i)
			{
				$vertexBuffers[i].uploadFromByteArray(zeroBytes, 0, 0, $bufferSize * VERTICES_PER_PARTICLE);
			}
			zeroBytes.length = 0;
			
			if (!$indices)
			{
				$indices = new Vector.<uint>();
				var numVertices:int = 0;
				var indexPosition:int = -1;
				for (i = 0; i < MAX_CAPACITY; ++i)
				{
					$indices[++indexPosition] = numVertices;
					$indices[++indexPosition] = numVertices + 1;
					$indices[++indexPosition] = numVertices + 2;
					
					$indices[++indexPosition] = numVertices + 1;
					$indices[++indexPosition] = numVertices + 3;
					$indices[++indexPosition] = numVertices + 2;
					numVertices += 4;
				}
			}
			$indexBuffer = context.createIndexBuffer($bufferSize * 6);
			$indexBuffer.uploadFromVector($indices, 0, $bufferSize * 6);
			
			FFParticleSystem.registerEffect(FFParticleEffect);
		}
		
		/**
		 * Disposes the Stage3D buffers and therefore disposes all system instances!
		 * Call this function to free the GPU resources or if you have to set
		 * the buffers to another size.
		 */
		public static function disposeBuffers():void
		{
			for (var i:int = _instances.length - 1; i >= 0; --i)
			{
				_instances[i].dispose();
			}
			
			if ($vertexBuffers)
			{
				for (i = 0; i < $numberOfVertexBuffers; ++i)
				{
					$vertexBuffers[i].dispose();
					$vertexBuffers[i] = null;
				}
				$vertexBuffers = null;
				$numberOfVertexBuffers = 0;
			}
			if ($indexBuffer)
			{
				$indexBuffer.dispose();
				$indexBuffer = null;
			}
			$bufferSize = 0;
			FFParticleSystem.unregisterEffect(FFParticleEffect);
		}
		
		public static function get bufferSize():int
		{
			return $bufferSize;
		}
		
		public function raiseCapacity(byAmount:int):void
		{
			var oldCapacity:int = capacity;
			var newCapacity:int = Math.min(__maxCapacity, capacity + byAmount);
			
			if (oldCapacity < newCapacity)
			{
				__rawData.fixed = false;
				__rawData.length = newCapacity * ELEMENTS_PER_PARTICLE;
				__rawData.fixed = true;
			}
		}
		
		public function clearData():void
		{
			__rawData.fixed = false;
			__rawData.length = 0;
			__rawData.fixed = true;
		}
		
		/**
		 * The number of particles, currently fitting into the vertexData instance of the system. (Not necessaryly all of them are visible)
		 */
		
		public function get capacity():int
		{
			return __rawData ? (__rawData.length / ELEMENTS_PER_PARTICLE) : 0;
		}
		
		/**
		 * The maximum number of particles processed by the system.
		 * It has to be a value between 1 and 16383.
		 */
		public function get maxCapacity():uint
		{
			return __maxCapacity;
		}
		
		public function set maxCapacity(value:uint):void
		{
			__maxCapacity = Math.min(MAX_CAPACITY, value);
		}
	
	}
}
