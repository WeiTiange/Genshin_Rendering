using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PP_SSR : PostEffectsBase
{
    private Camera cam;
    public Shader SSRShader;
    private Material SSRMaterial;
    private Material material {
        get {
            SSRMaterial = CheckShaderAndCreateMaterial(SSRShader, SSRMaterial);
            return SSRMaterial;
        }
    }

    void OnEnable() {
        cam = GetComponent<Camera>();
        cam.depthTextureMode = DepthTextureMode.DepthNormals;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if (material != null) {
            Graphics.Blit(src, dest, material);
            Matrix4x4 viewTorWorld = cam.cameraToWorldMatrix;
            SSRMaterial.SetMatrix("_ViewToWorld", viewTorWorld);
        } else {
            Graphics.Blit(src, dest);
        }
    }

}
