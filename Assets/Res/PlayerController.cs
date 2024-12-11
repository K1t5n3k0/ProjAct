using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    [Header("基础设置")]
    public float moveSpeed = 5f;
    public float runSpeed = 8f;
    public float jumpForce = 5f;
    public float rollSpeed = 8f;
    public float gravity = -9.81f;

    public float rotationSpeed = 10f;
    
    [Header("组件引用")]
    private CharacterController controller;
    private Animator animator;
    private Camera mainCamera;
    
    [Header("状态")]
    private Vector3 moveDirection;
    private Vector3 velocity;
    private bool isGrounded;
    private bool isRolling;
    
    void Start()
    {
        controller = GetComponent<CharacterController>();
        animator = GetComponent<Animator>();
        mainCamera = Camera.main;
        
        // 锁定鼠标
        Cursor.lockState = CursorLockMode.Locked;
    }

    void Update()
    {
        // 地面检测
        isGrounded = controller.isGrounded;
        if (isGrounded && velocity.y < 0)
        {
            velocity.y = -2f;
        }
        
        // 移动输入
        float horizontal = Input.GetAxisRaw("Horizontal");
        float vertical = Input.GetAxisRaw("Vertical");
        
        // 根据相机方向计算移动方向
        Vector3 move = new Vector3(horizontal, 0f, vertical).normalized;
        if (move != Vector3.zero)
        {
            // 获取相机的前向和右向量，但忽略Y轴分量
            Vector3 cameraForward = mainCamera.transform.forward;
            Vector3 cameraRight = mainCamera.transform.right;
            cameraForward.y = 0;
            cameraRight.y = 0;
            cameraForward.Normalize();
            cameraRight.Normalize();
        
            // 根据输入计算移动方向
            moveDirection = (cameraForward * vertical + cameraRight * horizontal).normalized;

            float targetAngle = Mathf.Atan2(moveDirection.x, moveDirection.z) * Mathf.Rad2Deg;
            float angle = Mathf.LerpAngle(transform.eulerAngles.y, targetAngle, Time.deltaTime * rotationSpeed);
            transform.rotation = Quaternion.Euler(0f, angle, 0f);
            
            
            // 奔跑
            float currentSpeed = Input.GetKey(KeyCode.LeftShift) ? runSpeed : moveSpeed;
            controller.Move(moveDirection.normalized * currentSpeed * Time.deltaTime);
            
            // 动画
            animator?.SetFloat("Speed", currentSpeed);
        }
        else
        {
            animator?.SetFloat("Speed", 0);
        }
        
        // 跳跃
        if (Input.GetButtonDown("Jump") && isGrounded)
        {
            velocity.y = Mathf.Sqrt(jumpForce * -2f * gravity);
            animator?.SetTrigger("Jump");
        }
        
        // 翻滚
        if (Input.GetKeyDown(KeyCode.Space) && !isRolling && isGrounded)
        {
            StartCoroutine(Roll());
        }
        
        // 重力
        velocity.y += gravity * Time.deltaTime;
        controller.Move(velocity * Time.deltaTime);
    }
    
    IEnumerator Roll()
    {
        isRolling = true;
        animator?.SetTrigger("Roll");
        
        // 翻滚过程中的移动
        float rollTime = 0.5f; // 翻滚持续时间
        float startTime = Time.time;
        
        while (Time.time < startTime + rollTime)
        {
            controller.Move(transform.forward * rollSpeed * Time.deltaTime);
            yield return null;
        }
        
        isRolling = false;
    }
}