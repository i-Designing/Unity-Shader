Shader "Custom/HS/HS_CG_Lighting"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

	SubShader
	{
		Pass
		{
			CGPROGRAM

			#pragma vertex MyVetexProgram
			#pragma fragment MyFragmentProgram

			#include "UnityCG.cginc"
			
			// vertex shader outputs("vertex to fragment")
			struct Interpolators
			{
				float4 position: SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
			};

			// vertex shader inputs
			struct VertexData 
			{
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			Interpolators MyVetexProgram(VertexData v)
			{
				Interpolators i;
				i.uv = TRANSFORM_TEX(v.uv, _MainTex);

				//all our normals are in object space,But we have to know the surface orientation in world space,
				//So we have to transform the normals from object to world space.
				//because it's a direction, repositioning should be ignored, so the fourth component must be 0
				//i.normal = mul(_Object2World, float4(v.normal, 0));
				//i.normal = normalize(i.normal);
				
				//When the scale is not uniform, it should be inverted for the normals. 
				//That way the normals will match the shape of the deformed surface, after they've been normalized again.
				//So we have to invert the scale, but the rotation should remain the same.
				//O = Ts * Tr * Tp, because each Transformation combines scale, rotate, and position
				//because we don't care position, so O = Ts * Tr => 0~ = Tr~ * Ts~
				//this is Unity's _World2Object Matrix's reason
				i.normal = mul(_World2Object, v.normal);
				i.normal = normalize(i.normal);

				i.position = mul(UNITY_MATRIX_MVP, v.position);
				return i;
			}
			
			float4 MyFragmentProgram(Interpolators i) : SV_TARGET
			{
				return float4(i.normal * 0.5 + 0.5, 1);
			}

			ENDCG
		}
	}
}
