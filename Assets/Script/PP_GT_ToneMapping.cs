using UnityEngine;
using System.Collections;


public class PP_GT_ToneMapping : PostEffectsBase
{
    public Shader GT_ToneMappingShader;
    private Material toneMapMaterial;
    public Material material {
        get {
            toneMapMaterial = CheckShaderAndCreateMaterial(GT_ToneMappingShader, toneMapMaterial);
            return toneMapMaterial;
        }
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if (material != null) {
            Graphics.Blit(src, dest, material);
        } else {
            Graphics.Blit(src, dest);
        }
    }
}
