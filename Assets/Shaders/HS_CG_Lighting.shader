Shader "Custom/HS/HS_CG_Lighting"
{
	Properties
	{
		_Tint ("Tint", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_Specular ("Specular", Color) = (1,1,1,1)
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

			#pragma vertex MyVetexProgram
			#pragma fragment MyFragmentProgram

			//#include "UnityCG.cginc"
			#include "UnityStandardBRDF.cginc"
			
			// vertex shader outputs("vertex to fragment")
			struct Interpolators
			{
				float4 position: SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};

			// vertex shader inputs
			struct VertexData 
			{
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			float4 _Tint;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Specular;
			float _Smoothness;

			Interpolators MyVetexProgram(VertexData v)
			{
				Interpolators i;
				i.worldPos = mul(_Object2World, v.position);
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
				i.normal = normalize(i.normal);
				//get light direction
				float3 lightDir = _WorldSpaceLightPos0.xyz;
				//get view direction
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				//get reflect direction
				float3 reflectionDir = reflect(-lightDir, i.normal);

				float3 lightColor = _LightColor0.rgb;
				float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

				float3 halfVector = normalize(lightDir + i.normal);
				float3 specular = pow(DotClamped(halfVector, reflectionDir),_Smoothness * 100) * _Specular.rgb;				
				float3 diffuse = albedo * lightColor * DotClamped(lightDir, i.normal);

				//finally, add diffuse and specular together
				return float4(diffuse + specular, 1);
			}

			ENDCG
		}
	}
}
