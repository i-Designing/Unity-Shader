Shader "Custom/HS/HS_CG_Texture_Splatting"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		[NoScaleOffset] _Texture1 ("Texture 1", 2D) = "white" {}
		[NoScaleOffset] _Texture2 ("Texture 2", 2D) = "white" {}
		[NoScaleOffset] _Texture3 ("Texture 3", 2D) = "white" {}
		[NoScaleOffset] _Texture4 ("Texture 4", 2D) = "white" {}
	}

	SubShader
	{
		Pass
		{
			CGPROGRAM

			#pragma vertex MyVetexProgram
			#pragma fragment MyFragmentProgram

			#include "UnityCG.cginc"
			
			struct Interpolators
			{
				float4 position: SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uvSplat : TEXCOORD1;
			};

			struct VertexData 
			{
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Texture1, _Texture2, _Texture3, _Texture4;

			Interpolators MyVetexProgram(VertexData v)
			{
				Interpolators i;
				i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				i.uvSplat = v.uv;
				i.position = mul(UNITY_MATRIX_MVP, v.position);
				return i;
			}
			
			float4 MyFragmentProgram(Interpolators i) : SV_TARGET
			{
				//We can then sample the splat map before sampling the other textures
				float4 splat = tex2D(_MainTex, i.uvSplat);

				//MonoChrome splat map
				//We decided that a value of 1 represents the first texture. 
				//As our splat map is monochrome, we can use any of the RGB channels to retrieve this value. 
				//Let's use the R channel and multiply it with the texture.
				//float4 color = tex2D(_Texture1, i.uv) * splat.r + tex2D(_Texture2, i.uv) * (1 - splat.r);

				//RGB Splat Map
				//The first sample use R channel,
				//The second sample now uses the G channel and the third uses the B channel. 
				//The final sample is modulated with (1 - R - G - B)
				float4 color = 
					tex2D(_Texture1, i.uv) * splat.r +
					tex2D(_Texture2, i.uv) * splat.g +
					tex2D(_Texture3, i.uv) * splat.b +
					tex2D(_Texture4, i.uv) * (1 - splat.r - splat.g - splat.b);

				return color;
			}

			ENDCG
		}
	}
}
