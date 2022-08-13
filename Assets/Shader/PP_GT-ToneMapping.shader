Shader "Genshin/PostProcess/GT-ToneMapping"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    CGINCLUDE

    static const float e = 2.71828;

    float Func_W (float x, float e0, float e1) {
        if (x <= e0) {
            return 0;
        }
        if (x >= e1) {
            return 1;
        }
        float a = (x - e0) / (e1 - e0);
        return a * a * (3 - 2 * a);
    }

    float Func_H (float x, float e0, float e1) {
        if (x <= e0) {
            return 0;
        }
        if (x >= e1) {
            return 1;
        }
        return (x - e0) / max(0.0000001, (e1 - e0));
    }

    float GT_ToneMapping (float x) {
        float P = 1;
        float a = 1;
        float m = 0.22;
        float l = 0.4;
        float c = 1.33;
        float b = 0;
        float l0 = (P - m)*l / a;
        float L0 = m - m / a;
        float L1 = m + (1 - m) / a;
        float L_x = m + a * (x - m);
        float T_x = m * pow(x / m, c) + b;
        float S0 = m + l0;
        float S1 = m + a * l0;
        float C2 = a * P / (P - S1);
        float S_x = P - (P - S1)*pow(e,-(C2*(x-S0)/P));
        float w0_x = 1 - Func_W(x, 0, m);
        float w2_x = Func_H(x, m + l0, m + l0);
        float w1_x = 1 - w0_x - w2_x;
        float f_x = T_x * w0_x + L_x * w1_x + S_x * w2_x;
        return f_x;
    }

    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            ZTest Always Cull Off ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;

            struct VertexOutput {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            VertexOutput vert (appdata_img v) {
                VertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag (VertexOutput i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float4 finalRGB = float4(GT_ToneMapping(col.r), GT_ToneMapping(col.g), GT_ToneMapping(col.b), col.a);
                return finalRGB;
            }
            ENDCG
        }
    }
}
