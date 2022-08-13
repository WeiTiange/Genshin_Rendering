// 参考文章：
// SDF计算部分：
// https://blog.csdn.net/A13155283231/article/details/109705794
// 阴影颜色：
// https://zhuanlan.zhihu.com/p/468209534

Shader "Genshin/SL_Genshin_Base_Face" {
    Properties {
[KeywordEnum(Day, Night)]   _DayNight                               ("Time", float)       = 0
                            _MainTex                                ("Base Color", 2D)    = "white" {}
                            _SDF                                    ("SDF", 2D)           = "white" {}
                            _Ramp                                   ("Ramp", 2D)          = "white" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _DayNight;
            sampler2D _MainTex;
            sampler2D _SDF;
            sampler2D _Ramp;


            struct VertexOutput {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 posWS : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
            };

            VertexOutput vert (appdata_full v) {
                VertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.nDirWS = normalize(UnityObjectToWorldNormal(v.normal));
                return o;
            }

            inline float3 ProjectOnPlane (float3 vec, float3 normal) {
                return vec - normal * dot(vec, normal);
            }

            float4 frag (VertexOutput i) : SV_Target {
                float3 baseCol = tex2D(_MainTex, i.uv).rgb;

                float3 nDirWS  = normalize(i.nDirWS);
                float3 lDirWS  = normalize(UnityWorldSpaceLightDir(i.posWS));
                
                float3 forwardWS  = normalize(UnityObjectToWorldNormal(float3(0, 0, 1)));
                float halfLambert = dot(forwardWS, normalize(ProjectOnPlane(lDirWS, float3(0, 1, 0)))) * 0.5 + 0.5;
                float LR          = cross(forwardWS, lDirWS).y;

                // 翻转UV
                float2 uv        = i.uv;
                float2 flipUV    = float2(1 - uv.x, uv.y);
                float4 lightMap  = float4(0, 0, 0, 0);
                float4 lightMapL =  1 - tex2D(_SDF, uv);
                float4 lightMapR =  1 - tex2D(_SDF, flipUV);

                if (LR > 0) {
                    lightMap = lightMapR;
                } else {
                    lightMap = lightMapL;
                }

                if (lightMap.a > halfLambert) {
                    lightMap = 0;
                } else {
                    lightMap = 1;
                }

                float2 faceShadowUV;
                if (_DayNight == 0) {
                    faceShadowUV = float2(0.35, 0.95);
                } else {
                    faceShadowUV = float2(0.35, 0.95);
                }
                float3 faceShadowCol = tex2D(_Ramp, faceShadowUV).rgb;
                faceShadowCol *= baseCol;
                
                float3 finalRGB = lerp(faceShadowCol, baseCol, lightMap.rgb);

                return float4(finalRGB, 1.0);

                // float3 faceLightMap = tex2D(_SDF, i.uv);

                // float3 Up = normalize(UnityObjectToWorldDir(float3(0,1,0)));
                // float3 Front = normalize(UnityObjectToWorldDir(float3(0,0,1)));
                // float3 Left = normalize(cross(Up, Front));
                // float3 Right = -Left;

                // float




                // return float4(faceLightMap, 1);

            }
            ENDCG
        }
    }
}
