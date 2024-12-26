using UnityEngine;
using System.Collections;

public class CameraShake : MonoBehaviour
{
    private static CameraShake instance;
    public static CameraShake Instance
    {
        get
        {
            if (instance == null)
            {
                instance = FindObjectOfType<CameraShake>();
                
                if (instance == null)
                {
                    Debug.Log("Creating new CameraShake instance");
                    GameObject go = new GameObject("CameraShake");
                    instance = go.AddComponent<CameraShake>();
                    DontDestroyOnLoad(go);
                }
            }
            return instance;
        }
    }

    private void Awake()
    {
        Debug.Log("CameraShake Awake called");
        if (instance == null)
        {
            instance = this;
            DontDestroyOnLoad(gameObject);
            Debug.Log("CameraShake instance initialized");
        }
        else if (instance != this)
        {
            Debug.Log("Destroying duplicate CameraShake instance");
            Destroy(gameObject);
        }
        
        InitializeCamera();
    }

    [Header("摇晃设置")]
    public float shakeDecay = 0.002f; // 摇晃衰减速度
    public float shakeIntensity = 0.1f; // 摇晃强��
    
    [Header("摇晃限制")]
    public float maxShakeX = 1.0f; // X轴最大摇晃幅度
    public float maxShakeY = 0.6f; // Y轴最大摇晃幅度
    public float maxShakeZ = 0.8f; // Z轴最大摇晃幅度
    
    [Header("噪声设置")]
    public float noiseFrequency = 4.0f; // 噪声频率

    private float currentShakeIntensity = 0f;
    private bool isShaking = false;
    private Camera mainCamera;
    private Transform cameraTransform;
    private Vector3 originalLocalPos;
    private Transform cameraParent;
    private float seed;

    private void InitializeCamera()
    {
        if (mainCamera == null)
        {
            mainCamera = Camera.main;
            if (mainCamera != null)
            {
                cameraTransform = mainCamera.transform;
                cameraParent = cameraTransform.parent;
                originalLocalPos = cameraTransform.localPosition;
                seed = Random.value * 100f;
                Debug.Log($"Camera initialized: {mainCamera.name}, Parent: {(cameraParent != null ? cameraParent.name : "None")}");
            }
            else
            {
                Debug.LogError("No main camera found in the scene!");
            }
        }
    }

    public void StartShake(float intensity, float duration)
    {
        Debug.Log($"StartShake called with intensity: {intensity}, duration: {duration}");
        
        if (mainCamera == null)
        {
            InitializeCamera();
            if (mainCamera == null)
            {
                Debug.LogError("Failed to initialize camera for shake effect!");
                return;
            }
        }

        if (!isShaking)
        {
            Debug.Log("Starting new shake effect");
            seed = Random.value * 100f;
            StartCoroutine(ShakeCoroutine(intensity, duration));
        }
        else
        {
            Debug.Log($"Already shaking, increasing intensity from {currentShakeIntensity} to {Mathf.Max(currentShakeIntensity, intensity)}");
            currentShakeIntensity = Mathf.Max(currentShakeIntensity, intensity);
        }
    }

    private Vector3 GenerateShakeOffset(float time)
    {
        float x = Mathf.PerlinNoise(time * noiseFrequency + seed, 0f) * 2f - 1f;
        float y = Mathf.PerlinNoise(0f, time * noiseFrequency + seed) * 2f - 1f;
        float z = Mathf.PerlinNoise(time * noiseFrequency + seed, time * noiseFrequency + seed) * 2f - 1f;
        
        return new Vector3(
            x * maxShakeX,
            y * maxShakeY,
            z * maxShakeZ
        );
    }

    private IEnumerator ShakeCoroutine(float intensity, float duration)
    {
        isShaking = true;
        currentShakeIntensity = intensity;
        float elapsed = 0f;
        float startTime = Time.time;

        Debug.Log($"Starting shake coroutine with intensity: {intensity}, duration: {duration}");

        while (elapsed < duration && currentShakeIntensity > 0)
        {
            elapsed += Time.deltaTime;
            float normalizedTime = elapsed / duration;
            currentShakeIntensity = Mathf.Lerp(intensity, 0f, normalizedTime);

            // 使用Perlin噪声生成平滑的随机偏移
            Vector3 shakeOffset = GenerateShakeOffset(Time.time) * currentShakeIntensity;
            Vector3 targetPosition = originalLocalPos + shakeOffset;

            // 应用偏移
            cameraTransform.localPosition = targetPosition;

            Debug.Log($"Camera local position: {cameraTransform.localPosition}, Shake offset: {shakeOffset}, Intensity: {currentShakeIntensity}");
            yield return null;
        }

        Debug.Log("Shake finished, smoothly returning to original position");
        
        // 平滑地返回到原始位置
        float returnElapsed = 0f;
        float returnDuration = 0.1f;
        Vector3 currentPos = cameraTransform.localPosition;

        while (returnElapsed < returnDuration)
        {
            returnElapsed += Time.deltaTime;
            float t = returnElapsed / returnDuration;
            t = t * t * (3f - 2f * t); // 平滑插值
            
            cameraTransform.localPosition = Vector3.Lerp(currentPos, originalLocalPos, t);
            yield return null;
        }

        // 确保完全返回原始位置
        cameraTransform.localPosition = originalLocalPos;
        currentShakeIntensity = 0f;
        isShaking = false;
        Debug.Log("Shake effect completed");
    }

    public void StopShake()
    {
        if (cameraTransform != null)
        {
            Debug.Log("Stopping shake effect");
            StopAllCoroutines();
            cameraTransform.localPosition = originalLocalPos;
            currentShakeIntensity = 0f;
            isShaking = false;
        }
    }

    private void OnEnable()
    {
        Debug.Log("CameraShake enabled");
        InitializeCamera();
    }
} 