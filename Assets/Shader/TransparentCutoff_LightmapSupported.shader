// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "GHB/TransparentCutout(LightmapSupported)" {
	Properties{
		_MainTex("MainTex", 2D) = "white" {}
		_diff_power("diff_power", Range(0, 1)) = 0.65
		_fresnel_color("fresnel_color", Color) = (0,0,0,1)
		_fresnel_area("fresnel_area", Range(0, 3)) = 3

		_Cutoff("Alpha cutoff", Range(0,1)) = .5
		 
	}

	SubShader{
		Tags{ "Queue" = "AlphaTest" "IgnoreProjector" = "False" "RenderType" = "TransparentCutout" }
		LOD 100
		Cull Back

		Pass{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM 
			#pragma fragmentoption ARB_precision_hint_fastest  
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON  //LightMap 相关
			#include "UnityCG.cginc"
			//#include "AutoLight.cginc"
			struct appdata
			{
				fixed4 vertex : POSITION;
				fixed2 uv : TEXCOORD0;
				fixed3 normal : NORMAL;
				//fixed4 tangent: TANGENT; 
				#ifndef LIGHTMAP_OFF
				fixed2 uv2 : texcoord1;
				#endif
			};
		struct V2f {
			fixed4 pos : SV_POSITION;
			fixed2 uv0 : TEXCOORD0;
			fixed4 posWorld : TEXCOORD1;
			fixed3 N : TEXCOORD2;
			fixed3 fres : TEXCOORD3;
			#ifndef LIGHTMAP_OFF
			fixed2 uv2 : texcoord4;
			#endif
			fixed3 col : COLOR;
		};

			uniform fixed4 _LightColor0;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;

			fixed _diff_power;
			fixed4 _fresnel_color;
			fixed _fresnel_area;
			 

			V2f vert(appdata v)
			{
				V2f  o;

				o.uv0 = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;//v.uv.xy;
#ifndef LIGHTMAP_OFF
				o.uv2 = v.uv2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
				o.N = UnityObjectToWorldNormal(v.normal);

				o.posWorld = mul(unity_ObjectToWorld, v.vertex);

				o.pos = UnityObjectToClipPos(v.vertex);

				fixed3 L = _WorldSpaceLightPos0.xyz;

				fixed3 V = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);

				fixed NV = max(0,dot(V, o.N));
				fixed NL = max(0,dot(L, o.N));

				o.fres = pow(1.0 - NV, _fresnel_area)* _fresnel_color.rgb;
				o.col = lerp( NL*_LightColor0.rgb, UNITY_LIGHTMODEL_AMBIENT.rgb * NL , .2 );

				return o;
			}

			fixed4 frag(V2f i) : SV_Target
			{
				fixed4 diff = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
				clip(diff.a - _Cutoff);
				fixed3 cbmcolor = (diff * _diff_power + diff * i.col) + i.fres;

				fixed3 texcolor = (fixed3)0;
				texcolor = cbmcolor;
				 #ifndef LIGHTMAP_OFF
				fixed3 lm = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv2.xy));
				texcolor  *=  lm;
				 #endif
				return fixed4(texcolor, 1);
			}
			ENDCG
	   }
    }
}
