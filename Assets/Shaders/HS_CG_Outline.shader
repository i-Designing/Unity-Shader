﻿// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
Shader "Custom/HS/Cartoon/HS_CG_Outline"
{
	//属性  
	Properties{
		_Diffuse("Diffuse", Color) = (1,1,1,1)
		_OutlineCol("OutlineCol", Color) = (1,0,0,1)
		_Outline("Thick of Outline",range(0,0.1)) = 0.02 //挤出描边的粗细
		_Factor("Factor",range(0,0.5)) = 0.25 //挤出多远
		_MainTex("Base 2D", 2D) = "white"{}
	}

	//子着色器    
	SubShader
	{
		//挤出操作在第一个pass中进行
		pass
		{
			// Always 不应用光照
			Tags{ "LightMode" = "Always" }
			//裁剪了物体的前面（对着相机的），把背面挤出
			Cull Front
			//像素的深度写入深度缓冲，如果关闭的话，物体与物体交叠处将不会被描边，因为此处无z值后渲染的物体会把此处挤出的描边“盖住”
			ZWrite On

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			float4 _OutlineCol;
			float _Outline;
			float _Factor;
			struct v2f
			{
				float4 pos:SV_POSITION;
			};

			v2f vert(appdata_full v)
			{
				v2f o;
				//计算该点位置朝向
				float3 dir = normalize(v.vertex.xyz);
				//计算法线方向
				//float3 dir2 = v.normal;
				float3 dir2 = v.tangent.xyz;
				//计算该点位置朝向和法线方向的点积，通过正负值可以确定是指向还是背离几何中心的，正为背离，负为指向
				float D = dot(dir,dir2);
				//乘上正负值，真正的方向值
				dir = dir*sign(D);
				//把该点位置朝向与法线方向按外部变量_Factor的比重混合，来控制挤出多远
				dir = dir*_Factor + dir2*(1 - _Factor);
				//把物体背面的点向外挤出
				v.vertex.xyz += dir*_Outline;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				return o;
			}

			float4 frag(v2f i) : COLOR
			{
				float4 c = _OutlineCol / 5;
				return c;
			}
			ENDCG
		}

		//正常着色的Pass  
		Pass
		{
			CGPROGRAM

			//引入头文件  
			#include "Lighting.cginc"  
			//定义Properties中的变量  
			fixed4 _Diffuse;
			sampler2D _MainTex;
			//使用了TRANSFROM_TEX宏就需要定义XXX_ST  
			float4 _MainTex_ST;

			//定义结构体：vertex shader阶段输出的内容  
			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float2 uv : TEXCOORD1;
			};

			//定义顶点shader,参数直接使用appdata_base（包含position, noramal, texcoord）  
			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				//通过TRANSFORM_TEX宏转化纹理坐标，主要处理了Offset和Tiling的改变,默认时等同于o.uv = v.texcoord.xy;  
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				return o;
			}

			//定义片元shader  
			fixed4 frag(v2f i) : SV_Target
			{
				//unity自身的diffuse也是带了环境光，这里我们也增加一下环境光  
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Diffuse.xyz;
				//归一化法线，即使在vert归一化也不行，从vert到frag阶段有差值处理，传入的法线方向并不是vertex shader直接传出的  
				fixed3 worldNormal = normalize(i.worldNormal);
				//把光照方向归一化  
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//根据半兰伯特模型计算像素的光照信息  
				fixed3 lambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
				//最终输出颜色为lambert光强*材质diffuse颜色*光颜色  
				fixed3 diffuse = lambert * _Diffuse.xyz * _LightColor0.xyz + ambient;
				//进行纹理采样  
				fixed4 color = tex2D(_MainTex, i.uv);
				color.rgb = color.rgb* diffuse;
				return fixed4(color);
			}

			//使用vert函数和frag函数  
			#pragma vertex vert  
			#pragma fragment frag     

			ENDCG
		}
	}

	//前面的Shader失效的话，使用默认的Diffuse  
	FallBack "Diffuse"
}

