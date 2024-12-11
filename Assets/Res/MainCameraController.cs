using UnityEngine;

public class MainCameraController : MonoBehaviour
{
    [Header("目标设置")]
    public Transform target;            
    public float baseDistance = 5f;     // 基础距离
    public Vector3 targetOffset = new Vector3(0, 1.5f, 0); // 目标点偏移
    
    [Header("旋转设置")]
    public float mouseSensitivity = 100f;
    public float minVerticalAngle = -30f;
    public float maxVerticalAngle = 60f;
    
    [Header("跟随设置")]
    public float followSmoothTime = 0.25f; // 只用于角色移动的跟随平滑
    public float maxDistanceIncrease = 1f;
    
    private float rotationX;
    private float rotationY;
    private Vector3 currentVelocity;
    private Vector3 smoothedTargetPosition;
    
    private void Start()
    {
        Vector3 angles = transform.eulerAngles;
        rotationX = angles.x;
        rotationY = angles.y;
        smoothedTargetPosition = target.position;
    }
    
    private void LateUpdate()
    {
        if (target == null) return;
        
        // 平滑处理目标位置（只针对角色移动）
        smoothedTargetPosition = Vector3.SmoothDamp(
            smoothedTargetPosition, 
            target.position, 
            ref currentVelocity, 
            followSmoothTime
        );
        
        // 鼠标输入和旋转计算（保持即时响应）
        float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity * Time.deltaTime;
        float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity * Time.deltaTime;
        
        rotationY += mouseX;
        rotationX -= mouseY;
        rotationX = Mathf.Clamp(rotationX, minVerticalAngle, maxVerticalAngle);
        
        // 计算旋转中心点（使用平滑后的目标位置）
        Vector3 centerPoint = smoothedTargetPosition + targetOffset;
        
        // 计算相机旋转和位置（即时响应）
        Quaternion rotation = Quaternion.Euler(rotationX, rotationY, 0);
        Vector3 negDistance = new Vector3(0, 0, -baseDistance);
        Vector3 position = centerPoint + (rotation * negDistance);
        
        // 直接设置相机的位置和旋转
        transform.rotation = rotation;
        transform.position = position;
    }
} 