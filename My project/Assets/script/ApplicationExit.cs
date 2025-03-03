using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Microsoft.AppCenter.Unity.Analytics;

public class ApplicationExit : MonoBehaviour
{
    // Start is called before the first frame update
    public void OnExitButtonClick()
    {
#if UNITY_EDITOR
        UnityEditor.EditorApplication.isPlaying = false;
        Debug.Log("Exit");
#else
         Application.Quit();
         Debug.Log("Exit from android");
#endif
    }
}