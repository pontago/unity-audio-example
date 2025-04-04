using System.Collections;
using UnityEngine;
using System.Runtime.InteropServices;


public class ButtonScript : MonoBehaviour
{
    [DllImport("__Internal", EntryPoint = "audioStart")]
    static extern void iOSAudioStart();
    [DllImport("__Internal", EntryPoint = "audioStop")]
    static extern void iOSAudioStop();
    [DllImport("__Internal", EntryPoint = "setupAudioSession")]
    static extern void iOSSetupAudioSession();

    IEnumerator Start()
    {
        Debug.Log("Microphone check");
#if UNITY_IOS && UNITY_2018_1_OR_NEWER
        // マイクパーミッションが許可されているか調べる
        yield return Application.RequestUserAuthorization(UserAuthorization.Microphone);
        if (Application.HasUserAuthorization(UserAuthorization.Microphone))
        {
            Debug.Log("Microphone found");
        }
        else
        {
            Debug.Log("Microphone not found");
        }
#endif
        return null;
    }

    // Update is called once per frame
    void Update()
    {

    }

    public void OnStart()
    {
        Debug.Log("Button START Clicked");

#if !UNITY_EDITOR && UNITY_IOS
        // オーディオ出力設定変更
        iOSSetupAudioSession();

        iOSAudioStart();
#endif
    }

    public void OnStop()
    {
        Debug.Log("Button STOP Clicked");

#if !UNITY_EDITOR && UNITY_IOS
        iOSAudioStop();
#endif
    }
}
