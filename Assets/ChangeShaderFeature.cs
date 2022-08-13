using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ChangeShaderFeature : MonoBehaviour
{
    public GameObject MainCam;
    private Material[] Mats;
    private Material M_Hair;
    private Material M_Face;
    private Material M_Body;
    
    private void Start() {
        Mats = gameObject.GetComponent<MeshRenderer>().materials;
        M_Face = Mats[0];
        M_Hair = Mats[1];
        M_Body = Mats[2];
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Alpha1)) {
            M_Face.SetFloat("_ShowFeature", 1.0f);
            M_Hair.SetFloat("_ShowFeature", 1.0f);
            M_Body.SetFloat("_ShowFeature", 1.0f);
        }

        if (Input.GetKeyDown(KeyCode.Alpha2))
        {
            M_Face.SetFloat("_ShowFeature", 2.0f);
            M_Hair.SetFloat("_ShowFeature", 2.0f);
            M_Body.SetFloat("_ShowFeature", 2.0f);
        }

        if (Input.GetKeyDown(KeyCode.Alpha3))
        {
            M_Face.SetFloat("_ShowFeature", 3.0f);
            M_Hair.SetFloat("_ShowFeature", 3.0f);
            M_Body.SetFloat("_ShowFeature", 3.0f);
        }

        if (Input.GetKeyDown(KeyCode.Alpha4))
        {
            bool GT_ToneMappingEnable = MainCam.GetComponent<PP_GT_ToneMapping>().isActiveAndEnabled;
            MainCam.GetComponent<PP_GT_ToneMapping>().enabled = !GT_ToneMappingEnable;
        }

        if (Input.GetKeyDown(KeyCode.Alpha5))
        {
            bool BriSatConEnable = MainCam.GetComponent<PP_BriSatCon>().isActiveAndEnabled;
            MainCam.GetComponent<PP_BriSatCon>().enabled = !BriSatConEnable;
        }
        
    }
}
