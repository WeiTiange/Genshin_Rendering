Shader "Genshin/SL_Genshin_Base_Body" {
    Properties {
[KeywordEnum(Day, Night)]   _DayNight    ("Time", float)       = 0
        _MainTex                         ("Base Color", 2D)    = "white" {}
        _LightMap                        ("Light Map", 2D)     = "white" {}
        _Ramp                            ("Ramp", 2D)          = "white" {}
        _RampShadowRange                 ("Ramp Shadow Range", Range(0,1)) = 0.5
        _BaseShadowInt                   ("Shadow Intensity", float)= 0.5
        _LightThreshold                  ("Light Threshold", Range(0,1)) = 0.5
        _RampAOLerp                     ("Ramp AO Lerp", Range(0,1)) = 0.5
        _BrightIntensity                ("Bright Intensity", float) = 0.5
        _DarkIntensity                  ("Dark Intensity", float) = 0.5
        _CharacterIntensity             ("Diffuse Intensity", float) = 1
    }
    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            float _DayNight;
            sampler2D _MainTex;
            sampler2D _LightMap;
            sampler2D _Ramp;
            float _RampShadowRange;
            float _BaseShadowInt;
            float _LightThreshold;
            float _RampAOLerp;
            float _DarkIntensity;
            float _BrightIntensity;
            float _CharacterIntensity;


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
                // 向量准备
                float3 nDirWS  = normalize(i.nDirWS);
                float3 lDirWS  = normalize(UnityWorldSpaceLightDir(i.posWS));

                // 贴图采样
                float3 baseCol = tex2D(_MainTex, i.uv).rgb;
                float4 T_LightMap = tex2D(_LightMap, i.uv);

                // 通道拆分
                float SpecularLayer = T_LightMap.r;
                float SpecularIntMask = T_LightMap.g;
                float ShadowAOMask = T_LightMap.b;
                float RampRange = T_LightMap.a;

                ShadowAOMask = 1 - smoothstep(saturate(ShadowAOMask), 0.2, 0.6);

                float halfLambert =  dot(nDirWS, lDirWS) * 0.5 + 0.5;
                
                float rampV = 0.0;
                float rampU = halfLambert * lerp(0.5, 1.0, ShadowAOMask) * (1.0 / _RampShadowRange - 0.003);

                if (_DayNight == 0) {
                    rampV = 0.5;
                } else {
                    rampV = 0;
                }

                float3 ShadowRamp1 = tex2D(_Ramp, float2(rampU, 0.45 + rampV)).rgb;
                float3 ShadowRamp2 = tex2D(_Ramp, float2(rampU, 0.35 + rampV)).rgb;
                float3 ShadowRamp3 = tex2D(_Ramp, float2(rampU, 0.25 + rampV)).rgb;
                float3 ShadowRamp4 = tex2D(_Ramp, float2(rampU, 0.15 + rampV)).rgb;
                float3 ShadowRamp5 = tex2D(_Ramp, float2(rampU, 0.05 + rampV)).rgb;

                float3 skinRamp = step(abs(RampRange - 1), 0.05) * ShadowRamp1;
                float3 tightRamp = step(abs(RampRange - 0.7), 0.05) * ShadowRamp2;
                float3 softCommonRamp = step(abs(RampRange - 0.5), 0.05) * ShadowRamp3;
                float3 hardSilkRamp = step(abs(RampRange - 0.3), 0.05) * ShadowRamp4;
                float3 metalRamp = step(abs(RampRange - 0), 0.05) * ShadowRamp5;

                float3 finalRamp = skinRamp + tightRamp + softCommonRamp + hardSilkRamp + metalRamp;


                float3 BaseMapShadowed = lerp(baseCol * finalRamp, baseCol, ShadowAOMask);
                BaseMapShadowed = lerp(baseCol, BaseMapShadowed, _BaseShadowInt);

                float IsBrightSide = ShadowAOMask * step(_LightThreshold, halfLambert);

                float3 BrightCol = BaseMapShadowed * _BrightIntensity;
                float3 DarkCol = lerp(BaseMapShadowed, baseCol * finalRamp, _RampAOLerp) * _DarkIntensity;
                float3 Diffuse = lerp(DarkCol, BrightCol, IsBrightSide) * _CharacterIntensity * _LightColor0.rgb;

                // return float4(BaseMapShadowed, 1);
                return float4(Diffuse, 1);


                

             
                return float4(1,1,1, 1.0);
            }
            ENDCG
        }
    }
}
