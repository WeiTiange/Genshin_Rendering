Shader "Realtime Planar Reflections/Blur" {
	Properties {
		_MainTex ("", 2D) = "white" {}
	}
	CGINCLUDE
	#include "UnityCG.cginc"

	sampler2D _MainTex;
	float4 _MainTex_ST;
	float2 _MainTex_TexelSize;
	float _Radius;
	struct v2f
	{
		float4 vertex : SV_POSITION;
		float2 uv : TEXCOORD0;
		float4 bluruv[3] : TEXCOORD1;
	};
	v2f vertHorizontal (appdata_base v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);

		float2 offset1 = float2(_MainTex_TexelSize.x * _Radius * 1.41176470, 0.0); 
		float2 offset2 = float2(_MainTex_TexelSize.x * _Radius * 3.29411764, 0.0);
		float2 offset3 = float2(_MainTex_TexelSize.x * _Radius * 5.17647058, 0.0);

#if UNITY_VERSION >= 540
		float2 uv = UnityStereoScreenSpaceUVAdjust(v.texcoord, _MainTex_ST);
#else
		float2 uv = v.texcoord;
#endif
		o.uv = uv;
		o.bluruv[0].xy = uv + offset1;
		o.bluruv[0].zw = uv - offset1;
		o.bluruv[1].xy = uv + offset2;
		o.bluruv[1].zw = uv - offset2;
		o.bluruv[2].xy = uv + offset3;
		o.bluruv[2].zw = uv - offset3;
		return o;
	}
	v2f vertVertical (appdata_base v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);

		float2 offset1 = float2(0.0, _MainTex_TexelSize.y * _Radius * 1.41176470); 
		float2 offset2 = float2(0.0, _MainTex_TexelSize.y * _Radius * 3.29411764);
		float2 offset3 = float2(0.0, _MainTex_TexelSize.y * _Radius * 5.17647058);

#if UNITY_VERSION >= 540
		float2 uv = UnityStereoScreenSpaceUVAdjust(v.texcoord, _MainTex_ST);
#else
		float2 uv = v.texcoord;
#endif
		o.uv = uv;
		o.bluruv[0].xy = uv + offset1;
		o.bluruv[0].zw = uv - offset1;
		o.bluruv[1].xy = uv + offset2;
		o.bluruv[1].zw = uv - offset2;
		o.bluruv[2].xy = uv + offset3;
		o.bluruv[2].zw = uv - offset3;
		return o;
	}
	fixed4 frag13Blur (v2f i) : SV_Target
	{
		fixed3 sum = tex2D(_MainTex, i.uv).xyz * 0.19648255;
		sum += tex2D(_MainTex, i.bluruv[0].xy).xyz * 0.29690696;
		sum += tex2D(_MainTex, i.bluruv[0].zw).xyz * 0.29690696;
		sum += tex2D(_MainTex, i.bluruv[1].xy).xyz * 0.09447039;
		sum += tex2D(_MainTex, i.bluruv[1].zw).xyz * 0.09447039;
		sum += tex2D(_MainTex, i.bluruv[2].xy).xyz * 0.01038136;
		sum += tex2D(_MainTex, i.bluruv[2].zw).xyz * 0.01038136;
		return fixed4(sum, 1.0);
	}
	ENDCG
	SubShader {
		ZTest Always Cull Off ZWrite Off
		Pass {
			CGPROGRAM
			#pragma vertex vertHorizontal
			#pragma fragment frag13Blur
			ENDCG
		}
		Pass {
			CGPROGRAM
			#pragma vertex vertVertical
			#pragma fragment frag13Blur
			ENDCG
		}
	}
	FallBack Off
}