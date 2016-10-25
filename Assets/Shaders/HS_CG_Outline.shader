Shader "Custom/HS/Cartoon/HS_CG_Outline" {
	Properties {
		_Color("Main Color",color)=(1,1,1,1)
		_Outline("Thick of Outline",range(0,0.1))=0.02 //挤出描边的粗细
		_Factor("Factor",range(0,1))=0.5 //挤出多远
	}

	SubShader {
		//挤出操作在第一个pass中进行
		pass
		{
			// Always 不应用光照
			Tags{"LightMode"="Always"}
			//裁剪了物体的前面（对着相机的），把背面挤出
			Cull Front
			//像素的深度写入深度缓冲，如果关闭的话，物体与物体交叠处将不会被描边，因为此处无z值后渲染的物体会把此处挤出的描边“盖住”
			ZWrite On

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			float _Outline;
			float _Factor;
			float4 _Color;
			struct v2f 
			{
				float4 pos:SV_POSITION;
			};

			v2f vert (appdata_full v) 
			{
				v2f o;
				//计算该点位置朝向
				float3 dir=normalize(v.vertex.xyz);
				//计算法线方向
				float3 dir2=v.normal;

				//计算该点位置朝向和法线方向的点积，通过正负值可以确定是指向还是背离几何中心的，正为背离，负为指向
				float D=dot(dir,dir2);
				//乘上正负值，真正的方向值
				dir=dir*sign(D);
				//把该点位置朝向与法线方向按外部变量_Factor的比重混合，来控制挤出多远
				dir=dir*_Factor+dir2*(1-_Factor);
				//把物体背面的点向外挤出
				v.vertex.xyz+=dir*_Outline;
				o.pos=mul(UNITY_MATRIX_MVP,v.vertex);
				return o;
			}

			float4 frag(v2f i):COLOR
			{
				float4 c = _Color / 5;
				return c;
			}
			ENDCG
		}

		pass
		{
			Tags{"LightMode"="ForwardBase"}
			Cull Back

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float4 _LightColor0;
			float4 _Color;
			float _Steps;
			float _ToonEffect;

			struct v2f 
			{
				float4 pos:SV_POSITION;
				float3 lightDir:TEXCOORD0;
				float3 viewDir:TEXCOORD1;
				float3 normal:TEXCOORD2;
			};

			v2f vert (appdata_full v) {
				v2f o;
				o.pos=mul(UNITY_MATRIX_MVP,v.vertex);
				o.normal=v.normal;
				o.lightDir=ObjSpaceLightDir(v.vertex);
				o.viewDir=ObjSpaceViewDir(v.vertex);

				return o;
			}

			float4 frag(v2f i):COLOR
			{
				float4 c=1;
				float3 N=normalize(i.normal);
				float3 viewDir=normalize(i.viewDir);
				float3 lightDir=normalize(i.lightDir);
				float diff=max(0,dot(N,i.lightDir));
				diff=(diff+1)/2;
				diff=smoothstep(0,1,diff);
				c=_Color*_LightColor0*(diff);
				return c;
			}
			ENDCG
		}
	}

	FallBack "Diffuse"
}
