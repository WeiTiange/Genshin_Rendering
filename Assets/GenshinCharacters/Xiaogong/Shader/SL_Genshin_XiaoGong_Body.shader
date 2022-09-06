Shader "Genshin/XiaoGong_Body" {
    Properties {
[KeywordEnum(Day, Night)]   _DayNight    ("Time", float)       = 0
        [Header(Diffuse)]
        _MainTex                         ("Base Color", 2D)    = "white" {}
        _LightMap                        ("Light Map", 2D)     = "white" {}
        _Ramp                            ("Ramp", 2D)          = "white" {}
        _MetalMap                        ("Metal Map", 2D) = "white" {}
        _RampOffset                      ("RampOffset", float) = 1 
        _ShadowSmooth       ("Shadow Smooth", float) = 0.5
        _LightThreshold ("Light Threshold", Range(0,1)) = 0.5
        _AOIntensity ("AO Intensity", Range(0,1)) = 1
        _RampLerp ("Ramp Lerp", Range(0,1)) = 1
        _DarkIntensity ("Dark Intensity", float) = 1
        _BrightIntentsy ("Bright Intensity", float) = 1
        _DiffuseIntensity ("Diffuse Intensity", float) = 1

        [Header(Specular)]
        _MetalMapRange ("Metal Map Range", Range(0, 0.5)) = 0.2
        _MetalMapIntensity ("Metal Map Intensity", float) = 1
        _StepSpecularWidth ("Step Specular Width", float) = 0.2
        _StepSpecularIntensity ("Step Specular Intensity", float) = 0.8
        _SpecularExp ("Specular Exponent", float) = 2
        _SpecularIntensity ("Specular Intensity", float) = 1 

        [Header(Rim)]
        _OffsetAmount ("Offset Amount", float) = 1
        _RimThreshold ("Rim Threshold", float) = 0.5
        _RimColor ("Rim Color", Color) = (1,1,1,1)


        [Header(Outline)]
        _OutlineWidth ("Outline Width", float) = 1
        _ColorBase    ("Normal Outline Color", Color) = (0,0,0,0)
        _ColorCloth   ("Cloth Outline Color", Color) = (1,1,1,1)
        _ColorSkin    ("Skin Outline Color", Color) = (1,1,1,1)

        [Header(Emission)]
        _EmissionIntensity ("Emission Intensity", float) = 2
    }
    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"


            float _DayNight;
            float4 _Tint;
            sampler2D _MainTex;
            sampler2D _LightMap;
            sampler2D _Ramp;
            sampler2D _MetalMap;
            float _RampOffset;
            float _ShadowSmooth;
            float _LightThreshold;
            float _AOIntensity;
            float _RampLerp;
            float _DarkIntensity;
            float _BrightIntentsy;
            float _DiffuseIntensity;

            float _MetalMapRange;
            float _MetalMapIntensity;
            float _StepSpecularWidth;
            float _StepSpecularIntensity;
            float _SpecularExp;
            float _SpecularIntensity;


            sampler2D _CameraDepthTexture;
            float _OffsetAmount;
            float _RimThreshold;
            float4 _RimColor;

            float  _EmissionIntensity;
            
            float _test;


            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 posWS : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
                float4 vColor : Color;
            };

            VertexOutput vert (appdata_full v) {
                VertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.nDirWS = normalize(UnityObjectToWorldNormal(v.normal));
                o.vColor = v.color;
                return o;
            }

            inline float3 ProjectOnPlane (float3 vec, float3 normal) {
                return vec - normal * dot(vec, normal);
            }

            float4 frag (VertexOutput i) : SV_Target {
                // 向量准备
                float3 nDirWS = normalize(i.nDirWS);
                float3 nDirVS = normalize(mul((float3x3)UNITY_MATRIX_V, nDirWS));
                float3 lDirWS = normalize(UnityWorldSpaceLightDir(i.posWS));
                float3 vDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
                float3 hDirWS = normalize(vDirWS + lDirWS);
                float3 Front  = normalize(UnityObjectToWorldDir(float3(0,-1,0)));

                // 向量计算
                float NdotL = dot(nDirWS, lDirWS);
                float NdotV = dot(nDirWS, vDirWS);
                float NdotH = dot(nDirVS, hDirWS);
                float FdotV = dot(Front.yz, vDirWS.yz);

                // 贴图采样
                float4 T_MainTex = tex2D(_MainTex, i.uv);
                float4 T_LightMap = tex2D(_LightMap, i.uv);

                // 通道拆分
                float3 baseCol = T_MainTex.rgb;
                float EmissiveMask = T_MainTex.a;
                float SpecularLayer = T_LightMap.r;
                float ShadowAOMask = T_LightMap.g;
                float SpecularIntMask = T_LightMap.b;
                float RampRange = T_LightMap.a;
                float4 RampOffsetMask = 1;

                // Diffuse: 叠加阴影区域，分层采样Ramp
                float RampPixelX = 0.00390625; // 1/256
                float RampPixelY = 0.05;    // 1/20;

                // 半兰伯特
                float halfLambert1 = (NdotL * 0.5 + 0.5 + RampOffsetMask - 1) / _RampOffset;
                float halfLambert2 = halfLambert1 * _RampOffset / (_RampOffset + 0.22);

                // 半兰伯特软硬
                halfLambert1 = smoothstep(0, _ShadowSmooth, halfLambert1);
                halfLambert2 = smoothstep(0, _ShadowSmooth, halfLambert2);

                // 去掉最左最右，避免采到边界上(待改进=>把ramp图设为Clamp?)
                // halfLambert1 = clamp(halfLambert1, RampPixelX, 1 - RampPixelX);
                // halfLambert2 = clamp (halfLambert2, RampPixelX, 1 - RampPixelX);

                float RampIndex = 1;
                if (RampRange >= 0 && RampRange <= 0.3) {
                    RampIndex = 1;
                    halfLambert1 = step(_LightThreshold, halfLambert1);
                    halfLambert2 = step(_LightThreshold, halfLambert2);
                }
                if (RampRange >= 0.31 && RampRange <= 0.6) {
                    RampIndex = 3; 
                }
                if (RampRange >= 0.61 && RampRange <= 1.0) {
                    RampIndex = 4;
                }


                // 构建Ramp采样UV
                ShadowAOMask = 1 - smoothstep(saturate(ShadowAOMask), 0.06 , 0.6);
                float rampU = halfLambert1 * ShadowAOMask;
                float rampV = RampPixelY * (2 * RampIndex - 1) + 0.5;
                float3 rampColor = tex2D(_Ramp, float2(rampU, rampV));

                // BaseColor叠加常暗AO
                float3 BaseColorShadowed = lerp(baseCol * rampColor, baseCol, ShadowAOMask);

                // 控制常暗AO的强度并叠加第二层兰伯特
                float SecondHalfLambert = halfLambert1 * ShadowAOMask - halfLambert2 * ShadowAOMask;
                BaseColorShadowed = lerp(baseCol, BaseColorShadowed, _AOIntensity) - 0.3 * baseCol * SecondHalfLambert;

                // 明暗叠加
                float IsBrightSide = ShadowAOMask * step(_LightThreshold, halfLambert1 * ShadowAOMask);

                float3 DarkColor = lerp(BaseColorShadowed, baseCol * rampColor, _RampLerp) * _DarkIntensity;
                float3 BrightColor = BaseColorShadowed * _BrightIntentsy;

                float3 Diffuse = lerp(DarkColor, BrightColor, IsBrightSide) * _DiffuseIntensity;

                

                // Specular
                float3 FinalSpecular = 0;
                float3 Specular = 0;
                float3 StepSpecular = 0;
                float SpecularLayer255 = SpecularLayer * 255;

                float MetalMap = saturate(tex2D(_MetalMap, nDirVS.xy * 0.5 + 0.5).r);
                MetalMap = step(_MetalMapRange, MetalMap) * _MetalMapIntensity;

                // 裁边高光层1
                // 甘雨的铃铛，绳子
                if (SpecularLayer255 > 120 && SpecularLayer255 < 254) {
                    StepSpecular = step(1 - _StepSpecularWidth, saturate(NdotV)) * _StepSpecularIntensity;
                }
                // 基础高光
                // BlinPhong高光 + 金属高光
                if (SpecularLayer255 >= 200) {
                    Specular = pow(saturate(NdotH), _SpecularExp) * SpecularIntMask * _SpecularIntensity;
                    Specular = max(0, Specular);
                    Specular += MetalMap;
                }

                Specular *= baseCol;
                Specular = lerp(StepSpecular, Specular, SpecularLayer);
                Specular = lerp(0, Specular, SpecularLayer);
                Specular *= IsBrightSide;


                // 边缘光
                float2 posSS = float2(i.pos.x / _ScreenParams.x, i.pos.y / _ScreenParams.y);
                float2 offsetPosSS_L = posSS - float2(_OffsetAmount / i.pos.w / _ScreenParams.x, 0);
                float2 offsetPosSS_R = posSS + float2(_OffsetAmount / i.pos.w / _ScreenParams.x, 0);
                float offsetDepth_L = Linear01Depth(tex2D(_CameraDepthTexture, offsetPosSS_L));
                float offsetDepth_R = Linear01Depth(tex2D(_CameraDepthTexture, offsetPosSS_R));
                float offsetDepth = max(offsetDepth_L, offsetDepth_R);
                float trueDepth = Linear01Depth(tex2D(_CameraDepthTexture, posSS));
                float depthDiffer = offsetDepth - trueDepth;
                float rimMask = step(_RimThreshold, depthDiffer);
                // float3 rimCol = lerp(0, rimMask * _RimColor * _RimColor.a, clamp(pow(1-saturate(dot(vDirWS, lDirWS)), 5), 0, 0.25)); 
                float3 objFront = float3(0,0,1);
                float3 objBack = -objFront;
                float oFdotV = clamp(smoothstep(1 - saturate(dot(objFront.xz, vDirWS.xz)), 0.0, 0.1), 0.2, 1.0);
                float oBdotV = clamp(smoothstep(1 - saturate(dot(objBack.xz, vDirWS.xz)), 0.0, 0.1), 0.2, 1.0);
                float3 rimCol = rimMask * _RimColor * _RimColor.a * min(oBdotV, oFdotV);


                // 自发光
                float emissionInt = smoothstep(0.1, 0.9, sin(_Time.y) * 0.5 + 0.5);
                float3 Emission = lerp(Diffuse * EmissiveMask, EmissiveMask * baseCol * _EmissionIntensity,  emissionInt);



                float3 finalRGB = (Diffuse + Specular + rimCol) * (1 - EmissiveMask) + Emission;
                return float4(finalRGB, 1);
             
            }
            ENDCG
        }

        Pass {
            Tags {
                "LightMode" = "ForwardBase"
            }

            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _LightMap;
            float _OutlineWidth;
            float4 _ColorBase;
            float4 _ColorCloth;
            float4 _ColorSkin;


            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            VertexOutput vert (appdata_full v) {
                VertexOutput o;
                float4 vertex = float4(v.vertex.xyz + v.tangent.xyz * _OutlineWidth * 0.0001, 1);
                o.uv = v.texcoord;
                o.pos = UnityObjectToClipPos(vertex);
                return o;
            }

            float4 frag (VertexOutput i) : SV_TARGET {
                float3 baseCol = tex2D(_MainTex, i.uv);
                float4 T_LightMap = tex2D(_LightMap, i.uv);

                float LayerMask = T_LightMap.a;
                float3 finalRGB = 1;

                if (LayerMask >= 0 && LayerMask <= 0.3)
                {
                    finalRGB.rgb = _ColorBase * baseCol;
                }

                if (LayerMask >= 0.31 && LayerMask <= 0.61)
                {
                    finalRGB.rgb = _ColorCloth * baseCol;
                }

                if (LayerMask >= 0.61 && LayerMask <= 1.0)
                {
                    finalRGB.rgb = _ColorSkin;
                }

                return float4(finalRGB, 1);
            }

            ENDCG

        }
    }
        Fallback "Diffuse"
}
