// Source: https://forum.unity.com/threads/fly-cam-simple-cam-script.67042/

using UnityEngine;
public class FlyCamScript : MonoBehaviour
{
    private Vector3 _angles;
    public float speed = 0.15f;
    public float fastSpeed = 0.5f;
    public float mouseSpeed = 2.5f;

    private void OnEnable()
    {
        //Debug.Log(speed);
        speed = 0.15f;
        _angles = transform.eulerAngles;
        Cursor.lockState = CursorLockMode.Locked;
    }

    private void OnDisable() { Cursor.lockState = CursorLockMode.None; }

    private void Update()
    {
        _angles.x -= Input.GetAxis("Mouse Y") * mouseSpeed;
        _angles.y += Input.GetAxis("Mouse X") * mouseSpeed;
        transform.eulerAngles = _angles;
        float moveSpeed = Input.GetKey(KeyCode.LeftShift) ? fastSpeed : speed;
        transform.position +=
            Input.GetAxis("Horizontal") * moveSpeed * transform.right +
            Input.GetAxis("Vertical") * moveSpeed * transform.forward;


        if (Input.GetAxis("Mouse ScrollWheel") > 0f) // forward
        {
            speed += 0.05f;
            if (speed > 0.5f)
                speed = 0.5f;
        }
        else if (Input.GetAxis("Mouse ScrollWheel") < 0f) // backwards
        {
            speed -= 0.05f;
            if (speed < 0.05f)
                speed = 0.05f;
            //Debug.Log(speed);
        }

        float upDownMultiplier = 0.5f;
        if (Input.GetKey(KeyCode.E))
        { transform.position += moveSpeed * transform.up * upDownMultiplier; }

        if (Input.GetKey(KeyCode.Q))
        { transform.position -= moveSpeed * transform.up * upDownMultiplier; }
    }
}