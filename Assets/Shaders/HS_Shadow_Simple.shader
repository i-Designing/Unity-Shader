// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/HS/HS_CG_SimpleShadow"
{
	//物体本身  
    Properties{  
        _MainTex("Base (RGB)", 2D) = "white" {}  
		_Instensity("Shininess", Range(2, 4)) = 2.1  
    }
	  
    SubShader{  
        
		Pass{  
			Tags{ "LightMode" = "ForwardBase" }  
			Material{  
				Ambient(1,0,1,1)  
				Specular(1,1,1,1)  
			}  
			Lighting On  
		}  
  
        //物体投影  
        Pass{  
			Tags{ "LightMode" = "ForwardBase" }  
			Blend DstColor SrcColor  
			Offset -1, -1//深度偏移 Z缩放的最大斜率的值 表示可分辨的最小深度缓冲区的值  
  
			CGPROGRAM  
			#pragma vertex vert  
			#pragma fragment frag  
			#include "UnityCG.cginc"  
			float4x4 _World2Local;  
			float4x4 _Local2World;   
  
			float _Instensity;  
			sampler2D _MainTex;  
			float4 _MainTex_ST;  
  
			struct v2f {  
				float atten : TEXCOORD0;
				float2 uv : TEXCOORD1;
				float4 pos : SV_POSITION;
			};  
  
			struct appdata  
			{  
				float2 uv : TEXCOORD0;  
				float4 vertex:POSITION;  
			}; 
			 
			//http://blog.csdn.net/shenmifangke  
			v2f vert(appdata v)  
			{
				float4 pos;
				float3 litDir;  
				litDir = WorldSpaceLightDir(v.vertex);//世界空间主光照相对于当前物体的方向  
				litDir = mul(_World2Local, float4(litDir, 0)).xyz;//光源方向转换到接受阴影的平面空间  
				//litDir = normalize(litDir);//归一

				float4 vt;  
				vt = mul(unity_ObjectToWorld, v.vertex);//将当前物体转换到世界空间  
				vt = mul(_World2Local, vt);//将物体在世界空间的矩阵转换到地面空间  
				//vt.xz = vt.xz - (vt.y / litDir.y)*litDir.xz;//用三角形相似计算沿光源方向投射后的XZ  
				vt.x = vt.x - (vt.y / litDir.y)*litDir.x;  
				vt.z = vt.z - (vt.y / litDir.y)*litDir.z;  
				//vt.x = vt.x - (vt.y / litDir.y)*litDir.x;  
				//vt.xz=vt.xz * float2(1, 1);  
				vt.y = 0;  
  
				//vt=mul(vt,_World2Ground);//back to world  
				vt = mul(_Local2World, vt);// 阴影顶点矩阵返回到世界空间  
				vt = mul(unity_WorldToObject, vt);// 返回到物体的坐标  
  
				v2f o; //_World2Object _Object2World _Local2World _World2Local  
				//pos = mul(UNITY_MATRIX_MVP, v.vertex);//_Local2World  
				//pos = mul(_Local2World, v.vertex);//_Local2World  
				//pos = mul(_Object2World * UNITY_MATRIX_V * UNITY_MATRIX_P, v.vertex);  
  
				pos = mul(UNITY_MATRIX_MVP, v.vertex);//_Local2World  
				//pos = mul(_Object2World*UNITY_MATRIX_MVP, v.vertex);//_Local2World  
				//pos = mul(UNITY_MATRIX_MVP*_Local2World, v.vertex);//_Local2World  
				//pos = mul(_World2Local,v.vertex);//_Local2World  
  
				pos = mul(UNITY_MATRIX_MVP, vt);
				o.pos = pos;

				return o;  
			}  
  
			float4 frag(v2f i) :COLOR  
			{  
				return float4(1,0,0,1);		//可以看到透明的方块 透明是受blend影响  
			}  
			ENDCG  
		}  
  
    }
}
