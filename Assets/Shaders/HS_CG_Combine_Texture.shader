﻿Shader "Custom/HS/HS_CG_Combine_Texture"
{
	Properties
	{
		_Tint("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_DetailTex ("Detail Texture", 2D) = "gray" {}
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
				float2 uvDetail : TEXCOORD1;
			};

			struct VertexData 
			{
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};
			
			float4 _Tint;
			sampler2D _MainTex, _DetailTex;
			float4 _MainTex_ST, _DetailTex_ST;

			Interpolators MyVetexProgram(VertexData v)
			{
				Interpolators i;
				i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				i.uvDetail = TRANSFORM_TEX(v.uv, _DetailTex);
				i.position = mul(UNITY_MATRIX_MVP, v.position);
				return i;
			}
			
			float4 MyFragmentProgram(Interpolators i) : SV_TARGET
			{
				float4 color = tex2D(_MainTex, i.uv) * _Tint;
				color *= tex2D(_DetailTex, i.uvDetail) * 2;
				return color;
			}

			ENDCG
		}
	}
}