using System;
using System.Runtime.InteropServices;
using TMPro;
using UnityEngine;

public class InputAudioVolume : MonoBehaviour
{
    [DllImport("__Internal", EntryPoint = "latestInputAudioDbspl")]
    static extern float iOSLatestInputAudioDbspl();

    public TMP_Text tmpText;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        InvokeRepeating(nameof(updateDBText), 0.5f, 0.5f);
    }

    // Update is called once per frame
    void Update()
    {

    }

    private void updateDBText()
    {
        float dpspl = iOSLatestInputAudioDbspl();
        Debug.Log(String.Format("{0:#.##} dB", dpspl));
        tmpText.text = String.Format("{0:#.##} dB", dpspl);
    }
}
