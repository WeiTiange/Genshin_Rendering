Shader "Genshin/GenshinCharacterScene_Floor"
{
    Properties
    {
        _BaseColor     ("Base Color", Color) = (0,0,0,0)
        _BaseColor2    ("Base Color 2", Color) = (1,1,1,1)
        _ReflectionTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }


        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _ReflectionTex;
            float4 _BaseColor;
            float4 _BaseColor2;

            struct VertexOutput
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD1;
                float3 posWS : TEXCOORD2;
                float3 nDirWS : TEXCOORD3;
                float4 vColor : TEXCOORD4;
            };


            VertexOutput vert (appdata_full v)
            {
                VertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.screenPos = ComputeScreenPos(o.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.vColor = v.color;
                return o;
            }

            float4 frag (VertexOutput i) : SV_Target
            {
                float3 nDirWS = normalize(i.nDirWS);
                float3 vDirWS = normalize(-mul((float3x3)unity_CameraToWorld, float3(0,0,1)));
                float NdotV = max(0, dot(nDirWS, vDirWS));
                NdotV = smoothstep(-0.2, 1.2, NdotV);
                // return NdotV;
                float3 baseCol = lerp(_BaseColor2.rgb, _BaseColor.rgb, NdotV);
                float4 scrpos = i.screenPos;
                float2 scruv = scrpos.xy / max(scrpos.w, 0.001);
                float4 refl = tex2D(_ReflectionTex, scruv);
                return float4(lerp(refl.rgb, lerp(refl.rgb, baseCol, NdotV), i.vColor.r), i.vColor.g);
                // return float4(lerp(refl.rgb, baseCol, NdotV), i.vColor.g);
            }
            ENDCG
        }
    }
}
