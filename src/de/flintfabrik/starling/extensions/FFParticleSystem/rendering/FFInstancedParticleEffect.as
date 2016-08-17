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
	import flash.utils.ByteArray;
	import starling.core.Starling;
	import starling.errors.MissingContextError;
	import starling.rendering.Program;
	import starling.utils.RenderUtil;
	
	use namespace ffparticlesystem_internal;
	
	/**
	 *  FFInstancedParticleEffect
	 *
	 *  <p>For more information about the usage and creation of effects, please have a look at
	 *  the documentation of the root class, "Effect".</p>
	 *
	 *  @see Effect
	 *  @see FilterEffect
	 *  @see starling.styles.MeshStyle
	 *  @see de.flintfabrik.starling.styles.FFParticleStyle
	 */
	public class FFInstancedParticleEffect extends FFParticleEffect
	{
		public static const ELEMENTS_PER_PARTICLE:int = 3 + 3 + 4 + 4;
		public static const MAX_CAPACITY:int = 16383;
		
		ffparticlesystem_internal static var _instances:Vector.<FFParticleSystem> = new Vector.<FFParticleSystem>(0, false);
		private static var $bufferSize:uint = 0;
		private static var $indexBuffer:IndexBuffer3D;
		private static var $vertexBuffer:VertexBuffer3D;
		private static var $instanceBufferIdx:int = -1;
		private static var $instanceBuffers:Vector.<VertexBuffer3D>;
		private static var $numberOfInstanceBuffers:uint = 1;
		private static var $renderAlpha:Vector.<Number> = new Vector.<Number>(4, true);
		
		public static function get isSupported():Boolean
		{
			var result:Boolean = false;
			try
			{
				var context:Context3D = Starling.context;
				if (context == null)
					throw new MissingContextError();
				
				var testBuffer:VertexBuffer3D = context['createVertexBufferForInstances'](5, 12, 1, "dynamicDraw");
				testBuffer.dispose();
				trace('[FFInstancedParticleEffect] instance drawing supported');
				return true;
			}
			catch (err:Error)
			{
				trace('[FFInstancedParticleEffect] Feature not available on this platform.');
				return false;
			}
			return false;
		}
		
		private var __maxCapacity:int;
		private var __rawData:Vector.<Number> = new Vector.<Number>(0, true);
		
		/** Creates a new FFInstancedParticleEffect instance. */
		public function FFInstancedParticleEffect()
		{
			_alpha = 1.0;
		}
		
		/** @private */
		override protected function createProgram():Program
		{
			var vertexShader:String, fragmentShader:String;
			
			vertexShader = "mov vt0, va0    \n" + // vertex.pos
			"m33 vt0.xyz, va0, va2          \n" + // * p.matrix
			"m44 op, vt0, vc0               \n" + // * mvpMatrix
			
			"mul vt4, va1, va4              \n" + // texelCoords *= vertexFlag
			"add v4, vt4.xy, vt4.zw         \n" + // sum texelCoords
			
			"mov v5, va5                    \n"; // output color
			
			fragmentShader = tex("ft0", "v4", 0, texture) +        // read texel color
			"mul oc, ft0, v5                \n";  // texel color * color
			
			return Program.fromSource(vertexShader, fragmentShader);
		}
		
		override public function render(firstIndex:int = 0, numParticles:int = -1):void
		{
			if (!$instanceBuffers || !$vertexBuffer)
				return;
			
			if (numParticles == 0) return;
			if (numParticles < 0) numParticles = 0;
			
			var numTriangles:int = numParticles * 2;
			
			var context:Context3D = Starling.context;
			if (context == null) throw new MissingContextError();
			
			$instanceBufferIdx = ++$instanceBufferIdx % $numberOfInstanceBuffers;
			var instanceBuffer:VertexBuffer3D = $instanceBuffers[$instanceBufferIdx];
			instanceBuffer.uploadFromVector(__rawData, 0, Math.min($bufferSize, numParticles) * 4);
			context.setVertexBufferAt(2, instanceBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(3, instanceBuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
			
			context.setVertexBufferAt(4, instanceBuffer, 6, Context3DVertexBufferFormat.FLOAT_4);
			context.setVertexBufferAt(5, instanceBuffer, 10, Context3DVertexBufferFormat.FLOAT_4);
			
			beforeDraw(context);
			context['drawTrianglesInstanced']($indexBuffer, numParticles, firstIndex, 2);
			afterDraw(context);
		
		}
		
		override protected function beforeDraw(context:Context3D):void
		{
			program.activate(context);
			$renderAlpha[0] = $renderAlpha[1] = $renderAlpha[2] = 1;
			$renderAlpha[3] = super._alpha;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, $renderAlpha);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mvpMatrix3D, true);
			
			context.setVertexBufferAt(0, $vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(1, $vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_4);
			
			context.setTextureAt(0, texture.base);
			RenderUtil.setSamplerStateAt(0, texture.mipMapping, textureSmoothing, super.textureRepeat);
		}
		
		override protected function afterDraw(context:Context3D):void
		{
			context.setVertexBufferAt(5, null);
			context.setVertexBufferAt(4, null);
			context.setVertexBufferAt(3, null);
			context.setVertexBufferAt(2, null);
			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(0, null);
			context.setTextureAt(0, null);
		}
		
		override public function writeParticleDataToBuffers(particles:Vector.<Particle>, frameLUT:Vector.<Frame>, offset:int, numParticles:int, systemAlpha:Number = 1):uint
		{
			var vertexID:int = 0;
			var particle:Particle;
			var position:uint;
			var frameDimensions:Frame;
			var angle:Number;
			var scaledWidth:Number;
			var scaledHeight:Number;
			var particleAlpha:Number;
			var particlesWritten:int = -1;
			
			__rawData.fixed = false;
			
			for (var i:int = 0; i < numParticles; ++i)
			{
				particle = particles[i];
				particleAlpha = particle.colorAlpha * particle.fadeInFactor * particle.fadeOutFactor;
				
				if ((testParticleAlpha && particleAlpha <= 0) || particle.scale <= 0)
					continue;
				
				vertexID = (offset + ++particlesWritten);
				frameDimensions = frameLUT[particle.frameIdx];
				angle = (particle.rotation * 325.94932345220164765467394738691) & 2047;
				scaledWidth = frameDimensions.particleHalfWidth * particle.scale * particle.spawnFactor;
				scaledHeight = frameDimensions.particleHalfHeight * particle.scale * particle.spawnFactor;
				position = vertexID * ELEMENTS_PER_PARTICLE;
				
				__rawData[position] = scaledWidth * FFPS_LUT.cos[angle];
				__rawData[++position] = scaledHeight * -FFPS_LUT.sin[angle];
				__rawData[++position] = particle.x;
				
				__rawData[++position] = scaledWidth * FFPS_LUT.sin[angle];
				__rawData[++position] = scaledHeight * FFPS_LUT.cos[angle];
				__rawData[++position] = particle.y;
				
				__rawData[++position] = frameDimensions.textureX;
				__rawData[++position] = frameDimensions.textureY;
				__rawData[++position] = frameDimensions.textureWidth;
				__rawData[++position] = frameDimensions.textureHeight;
				
				__rawData[++position] = particle.colorRed;
				__rawData[++position] = particle.colorGreen;
				__rawData[++position] = particle.colorBlue;
				__rawData[++position] = particleAlpha * systemAlpha;
			}
			
			__rawData.fixed = true;
			return ++particlesWritten;
		}
		
		public static function get buffersCreated():Boolean
		{
			return $instanceBuffers && $instanceBuffers[0];
		}
		
		override public function get buffersCreated():Boolean
		{
			return FFInstancedParticleEffect.buffersCreated;
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
				$numberOfInstanceBuffers = numberOfBuffers;
			
			if ($instanceBuffers)
				for (var i:int = 0; i < $instanceBuffers.length; ++i)
					$instanceBuffers[i].dispose();
			if ($indexBuffer)
				$indexBuffer.dispose();
			if ($vertexBuffer)
				$vertexBuffer.dispose();
			
			var context:Context3D = Starling.context;
			if (context == null)
				throw new MissingContextError();
			if (context.driverInfo == "Disposed")
				return;
			
			$vertexBuffer = context.createVertexBuffer(VERTICES_PER_PARTICLE, 7, "staticDraw");
			$vertexBuffer.uploadFromVector(Vector.<Number>([-1.0, -1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, -1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, -1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0,]), 0, VERTICES_PER_PARTICLE);
			
			$indexBuffer = context.createIndexBuffer(6, "staticDraw");
			$indexBuffer.uploadFromVector(Vector.<uint>([0, 1, 2, 0, 2, 3]), 0, 6);
			
			var numInstances:uint = Math.max(1, $bufferSize);
			$instanceBuffers = new Vector.<VertexBuffer3D>($numberOfInstanceBuffers, true);
			for (i = 0; i < $numberOfInstanceBuffers; ++i)
			{
				$instanceBuffers[i] = context['createVertexBufferForInstances'](numInstances, ELEMENTS_PER_PARTICLE, 1, "dynamicDraw");
			}
			
			var zeroBytes:ByteArray = new ByteArray();
			zeroBytes.length = numInstances * VERTICES_PER_PARTICLE * ELEMENTS_PER_PARTICLE; // numParticle * verticesPerParticle * ELEMENTS_PER_VERTEX
			for (i = 0; i < $numberOfInstanceBuffers; ++i)
			{
				$instanceBuffers[i].uploadFromByteArray(zeroBytes, 0, 0, numInstances);
			}
			zeroBytes.length = 0;
			
			FFParticleSystem.registerEffect(FFInstancedParticleEffect);
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
			
			if ($instanceBuffers)
			{
				for (i = 0; i < $numberOfInstanceBuffers; ++i)
				{
					$instanceBuffers[i].dispose();
					$instanceBuffers[i] = null;
				}
				$instanceBuffers = null;
				$numberOfInstanceBuffers = 0;
			}
			if ($indexBuffer)
			{
				$indexBuffer.dispose();
				$indexBuffer = null;
			}
			if ($vertexBuffer)
			{
				$vertexBuffer.dispose();
				$vertexBuffer = null;
			}
			$bufferSize = 0;
			FFParticleSystem.unregisterEffect(FFInstancedParticleEffect);
		}
		
		public static function get bufferSize():int
		{
			return $bufferSize;
		}
		
		override public function raiseCapacity(byAmount:int):void
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
		
		override public function clearData():void
		{
			__rawData.fixed = false;
			__rawData.length = 0;
			__rawData.fixed = true;
		}
		
		/**
		 * The number of particles, currently fitting into the vertexData instance of the system. (Not necessaryly all of them are visible)
		 */
		
		override public function get capacity():int
		{
			return __rawData ? (__rawData.length / ELEMENTS_PER_PARTICLE) : 0;
		}
		
		/**
		 * The maximum number of particles processed by the system.
		 * It has to be a value between 1 and 16383.
		 */
		override public function get maxCapacity():uint
		{
			return __maxCapacity;
		}
		
		override public function set maxCapacity(value:uint):void
		{
			__maxCapacity = Math.min(MAX_CAPACITY, value);
		}
	
	}
}
