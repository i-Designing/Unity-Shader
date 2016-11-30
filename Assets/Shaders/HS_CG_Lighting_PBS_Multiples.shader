Shader "Custom/HS/HS_CG_Lighting_PBS_Multiples"
{
	Properties
	{
		_Tint ("Tint", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.5
	}

	SubShader
	{
		Pass
		{
			Tags{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM

			#pragma target 3.0
			#pragma vertex MyVetexProgram
			#pragma fragment MyFragmentProgram

			#include "HS_CG_Lighting_Include.cginc"

			ENDCG
		}

		Pass
		{
			Tags{
				"LightMode" = "ForwardAdd"
			}

			/*
			The default mode is no blending, which is equivalent to One Zero. 
			The result of such a pass replaced anything that was previously in the frame buffer. 
			To add to the frame buffer, we'll have to instruct it to use the One One blend mode. 
			This is known as additive blending.
			*/
			Blend One One

			/*
			we end up at the exact same depth as the previous pass, because it's for the same object. 
			So we end up recording the exact same depth value
			Because writing to the depth buffer twice is not necessary, let's disable it. 
			This is done with the ZWrite Off shader statement.
			*/
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0
			#pragma vertex MyVetexProgram
			#pragma fragment MyFragmentProgram

			#include "HS_CG_Lighting_Include.cginc"

			ENDCG
		}
	}
}
