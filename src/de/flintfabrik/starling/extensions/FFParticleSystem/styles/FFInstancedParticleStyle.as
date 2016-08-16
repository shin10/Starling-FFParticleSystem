// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package de.flintfabrik.starling.extensions.FFParticleSystem.styles
{
	import de.flintfabrik.starling.extensions.FFParticleSystem.rendering.FFInstancedParticleEffect;
	import de.flintfabrik.starling.extensions.FFParticleSystem.rendering.FFParticleEffect;
	import starling.textures.TextureSmoothing;
	
	public class FFInstancedParticleStyle extends FFParticleStyle
	{
		public static function get effectType():Class
		{
			return FFInstancedParticleEffect;
		}
		
		override public function get effectType():Class
		{
			return _type.effectType;
		}
		
		public function FFInstancedParticleStyle()
		{
			_textureSmoothing = TextureSmoothing.BILINEAR;
			_type = Object(this).constructor as Class;
		}
		
		override public function createEffect():FFParticleEffect
		{
			return new FFInstancedParticleEffect();
		}
	
	}
}
