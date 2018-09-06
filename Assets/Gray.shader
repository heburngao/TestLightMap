Shader "Unlit/Gray"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Slider("Slider",range(0,1)) = 1
		//[Enum(NO,0,YES,1)]_UseLightmap("UseLightmap",float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase"}
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma fragmentoption ARB_precision_hint_fastest  
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			fixed _Slider;
			struct appdata
			{
				fixed4 vertex : POSITION;
				fixed2 uv : TEXCOORD0;
				fixed3 normal : NORMAL;
				fixed4 tangent: TANGENT;
				fixed2 uv2 : texcoord1;
			};

			struct v2f
			{
				fixed2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				fixed4 vertex : SV_POSITION;
				fixed2 uv2: texcoord1;
				fixed3 V : texcoord2;
				fixed3 L : texcoord3;
				fixed3 N : texcoord4;

			};

			sampler2D _MainTex;
			fixed4 _MainTex_ST;
			//fixed _UseLightmap;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv =  v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;                 //TRANSFORM_TEX(v.uv, _MainTex);  //
				o.uv2 = v.uv2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				
				

				UNITY_TRANSFER_FOG(o,o.vertex);

				o.V = normalize(_WorldSpaceCameraPos.xyz - mul(UNITY_MATRIX_M,v.vertex).xyz );
				o.L = normalize(_WorldSpaceLightPos0.xyz);
				o.N = normalize(mul(UNITY_MATRIX_M,v.normal).xyz); 
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex));
				// apply fog

				UNITY_APPLY_FOG(i.fogCoord, col);
				//return pow(col,_Slider);//fixed4(col.g,col.g,col.g,1);//col;
				
				fixed NL = saturate(dot(i.N,i.L));
				fixed NV = saturate(dot(i.N,i.V));

				// gray effect 
				//fixed dt = dot(col.rgb,(fixed3)_Slider);
				//return fixed4(dt,dt,dt,1);

				
				//lightmap bake supported
				fixed3 lm = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv2.xy));

				fixed4 texcolor = (fixed4)0;
				//if(_UseLightmap == 1){
					
				//	texcolor.rgb = col.rgb * lm.rgb ;//* lerp(1,NL, .8) ;// + (1- NV * NV * NV)*.3;
				//}else{
					texcolor.rgb = col.rgb + col.rgb *  NL;//lerp(1,NL, .8) ;// + (1- NV * NV * NV)*.3;
					texcolor.rgb = texcolor.rgb * lm.rgb ;
				//}
				 
				return texcolor;
			}
			ENDCG
		}
	}
}
