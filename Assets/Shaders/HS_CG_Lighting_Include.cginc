#if !defined(HS_CG_LIGHTING_INCLUDED)
#define HS_CG_LIGHTING_INCLUDED

#include "UnityPBSLighting.cginc"

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
float _Metallic;
float _Smoothness;

UnityLight CreateLight (Interpolators i) {
	UnityLight light;
	/*
	The _WorldSpaceLightPos0 variable contains the current light's position. But in case of a directional light, it actually holds the direction towards the light. 
	it's right only for directional light, So we have to compute the light direction ourselves. This is done by subtracting the fragment's world position and normalizing the result
	*/
	light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
	light.color = _LightColor0.rgb;
	light.ndotl = DotClamped(i.normal, light.dir);
	return light;
}

Interpolators MyVetexProgram(VertexData v)
{
	Interpolators i;
	i.worldPos = mul(unity_ObjectToWorld, v.position);
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
	i.normal = mul(unity_WorldToObject, v.normal);
	i.normal = normalize(i.normal);

	i.position = mul(UNITY_MATRIX_MVP, v.position);
	return i;
}

float4 MyFragmentProgram(Interpolators i) : SV_TARGET
{
	i.normal = normalize(i.normal);
	//get view direction
	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
	float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

	float3 specularTint;
	float oneMinusReflectivity;
	albedo = DiffuseAndSpecularFromMetallic(
		albedo, _Metallic, specularTint, oneMinusReflectivity
	);

	UnityLight light = CreateLight(i);
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	return UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, _Smoothness,
		i.normal, viewDir,
		light, indirectLight
	);
}

#endif