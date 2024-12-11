using UnityEngine;

public class MainCameraController : MonoBehaviour
{
    [Header("目标设置")]
    public Transform target;            // 跟随的目标（玩家）
    public Vector3 offset = new Vector3(0, 2, -5); // 相对于目标的偏移
    
    [Header("旋转设置")]
    public float mouseSensitivity = 2f; // 鼠标灵敏度
    public float gamepadSensitivity = 100f; // 手柄灵敏度
    public float minVerticalAngle = -30f;   // 垂直旋转最小角度
    public float maxVerticalAngle = 60f;    // 垂直旋转最大角度
    
    [Header("平滑设置")]
    public float rotationSmoothTime = 0.12f;
    public float positionSmoothTime = 0.12f;
    
    // 私有变量
    private float rotationX;
    private float rotationY;
    private Vector3 currentRotation;
    private Vector3 rotationSmoothVelocity;
    private Vector3 currentPosition;
    private Vector3 positionSmoothVelocity;
    
    private void Start()
    {
        // 初始化旋转角度
        rotationX = transform.eulerAngles.x;
        rotationY = transform.eulerAngles.y;
        currentRotation = transform.eulerAngles;
        currentPosition = transform.position;
    }
    
    private void LateUpdate()
{
    if (target == null) return;
    
    // 获取鼠标输入
    float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity;
    float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity;
    
    // 注释掉手柄右摇杆输入
    // float gamepadX = Input.GetAxis("RightStickHorizontal") * gamepadSensitivity * Time.deltaTime;
    // float gamepadY = Input.GetAxis("RightStickVertical") * gamepadSensitivity * Time.deltaTime;
    
    // 仅使用鼠标输入
    float totalX = mouseX; // + gamepadX;
    float totalY = mouseY; // + gamepadY;
    
    // 更新旋转角度
    rotationY += totalX;
    rotationX -= totalY; // 注意这里是减法，因为我们想要上推摇杆时相机向上看
    rotationX = Mathf.Clamp(rotationX, minVerticalAngle, maxVerticalAngle);
    
    // 计算目标旋转
    Vector3 targetRotation = new Vector3(rotationX, rotationY, 0f);
    
    // 平滑插值旋转
    currentRotation = Vector3.SmoothDamp(
        currentRotation,
        targetRotation,
        ref rotationSmoothVelocity,
        rotationSmoothTime
    );
    
    // 应用旋转
    transform.eulerAngles = currentRotation;
    
    // 计算目标位置
    Vector3 targetPosition = target.position + Quaternion.Euler(currentRotation) * offset;
    
    // 平滑插值位置
    currentPosition = Vector3.SmoothDamp(
        currentPosition,
        targetPosition,
        ref positionSmoothVelocity,
        positionSmoothTime
    );
    
    // 应用位置
    transform.position = currentPosition;
}
} 