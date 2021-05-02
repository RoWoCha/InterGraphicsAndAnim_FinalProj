/// Script: AutoRotation.cs
/// Brief: Rotates attached GameObject
/// Author: Egor Fesenko
/// Date: 04/28/2021

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AutoRotation : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {

        transform.Rotate(0.1f, 0.2f, 0.0f, Space.Self);
    }
}
