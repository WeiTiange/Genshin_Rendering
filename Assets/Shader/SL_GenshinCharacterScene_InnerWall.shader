Shader "Genshin/GenshinCharacterScene_InnerWall"
{
    Properties
    {
        _BaseColor      ("Base Color", Color) = (1,1,1,1)
        [HDR]_HighlightColor ("Highlight Color", Color) = (1,1,1,1)
        _OpacityMask    ("Opacity", 2D) = "white" {}

    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
            
        Pass
        {
            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _BaseColor;
            float4 _HighlightColor;
            sampler2D _OpacityMask;
            sampler2D _CameraDepthTexture;

            struct VertexOutput
            {
                float4 vertex : SV_POSITION;
                float3 posOS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                float3 nDirWS : TEXCOORD3;
            };


            VertexOutput vert (appdata_base v)
            {
                VertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posOS = v.vertex.xyz;
                o.uv = v.texcoord;
                o.screenPos = ComputeScreenPos(o.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag (VertexOutput i) : SV_Target
            {
                float3 nDirWS = normalize(i.nDirWS);
                float3 vDirWS = normalize(-mul((float3x3)unity_CameraToWorld, float3(0,0,1)));
                float NdotV = max(0, dot(nDirWS, vDirWS));

                float2 opcacityMask = pow(tex2D(_OpacityMask, float2(i.uv.x, i.uv.y)).rg, 0.9);
                float highlightColorOpacity = opcacityMask.g * NdotV;

                float baseColorOpacity = opcacityMask.r * smoothstep(-1.5, 1.0, NdotV);
                // return baseColorOpacity;
                float3 highlightCol = _HighlightColor.rgb *  highlightColorOpacity;

                float4 baseCol = float4(_BaseColor.rgb + highlightCol, baseColorOpacity);

                return baseCol ;
                // return float4(opacity, opacity, opacity, 1);
                // return float4(_BaseColor.rgb, opacity);
            }
            ENDCG
        }
    }
}
