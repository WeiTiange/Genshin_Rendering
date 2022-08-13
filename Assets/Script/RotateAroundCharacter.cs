using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateAroundCharacter : MonoBehaviour
{
    public Transform Character;
    public Transform CharacterHead;
    public Transform InnerWall;
    public float RotateSpeed;
    public float ZoomSpeed;
    private Vector3 CharacterPos;
    private Vector3 CharacterHeadPos;
    private Camera Cam;
    private int CamMinFOV = 30;
    private int CamMaxFOV = 75;
    private bool ConstanlyRotate = false;

    // Start is called before the first frame update
    void Start()
    {
        CharacterPos = Character.transform.position;
        CharacterHeadPos = CharacterHead.transform.position;
        Cam = GetComponent<Camera>();

    }

    // Update is called once per frame
    void Update()
    {
        // transform.eulerAngles = new Vector3(Mathf.Clamp(transform.eulerAngles.x, 0f, 13f), transform.eulerAngles.y, transform.eulerAngles.z);
        // Rotation
        if (!Input.GetMouseButton(0) && ConstanlyRotate) {
            transform.RotateAround(CharacterHeadPos, new Vector3(0, 1, 0), -0.2f);
            InnerWall.transform.RotateAround(CharacterHeadPos, new Vector3(0, 1, 0), -0.2f);

        }

        if (Input.GetMouseButton(0)) {
            float RotateSpeedY = Input.GetAxis("Mouse Y") * 359.0f * RotateSpeed;
            float RotateSpeedX = Input.GetAxis("Mouse X") * 359.0f * RotateSpeed;
            transform.RotateAround(CharacterHeadPos, new Vector3(0,1,0), RotateSpeedX);
            transform.RotateAround(CharacterHeadPos, -transform.right, RotateSpeedY);

            InnerWall.transform.RotateAround(CharacterHeadPos, new Vector3(0, 1, 0), RotateSpeedX);
        }
        
        // Zoom In/Out
        
            if (Input.mouseScrollDelta.y > 0) {
                Cam.fieldOfView = Mathf.Lerp(Cam.fieldOfView, CamMinFOV, ZoomSpeed);
            } else if (Input.mouseScrollDelta.y < 0) {
                Cam.fieldOfView = Mathf.Lerp(Cam.fieldOfView, CamMaxFOV, ZoomSpeed);
            }

        if (Input.GetKeyDown(KeyCode.Space)) {
            ConstanlyRotate = !ConstanlyRotate;
        }
    }
}
