using UnityEngine;
using System.Collections;

public class TimeManager : MonoBehaviour
{
    private static TimeManager instance;
    public static TimeManager Instance
    {
        get
        {
            if (instance == null)
            {
                GameObject go = new GameObject("TimeManager");
                instance = go.AddComponent<TimeManager>();
                DontDestroyOnLoad(go);
            }
            return instance;
        }
    }

    private void Awake()
    {
        if (instance == null)
        {
            instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }

    public void DoHitStop(float duration)
    {
        StartCoroutine(HitStopCoroutine(duration));
    }

    private IEnumerator HitStopCoroutine(float duration)
    {
        // 保存当前所有动画器的速度
        Animator[] animators = FindObjectsOfType<Animator>();
        float[] originalSpeeds = new float[animators.Length];
        for (int i = 0; i < animators.Length; i++)
        {
            originalSpeeds[i] = animators[i].speed;
            // 设置动画器速度为原来的速度除以timeScale，这样动画会继续播放
            animators[i].speed = originalSpeeds[i] / Time.timeScale;
        }

        // 暂停游戏时间
        Time.timeScale = 0f;
        
        yield return new WaitForSecondsRealtime(duration);
        
        // 恢复游戏时间
        Time.timeScale = 1f;

        // 恢复所有动画器的速度
        for (int i = 0; i < animators.Length; i++)
        {
            if (animators[i] != null) // 检查动画器是否还存在
            {
                animators[i].speed = originalSpeeds[i];
            }
        }
    }
} 