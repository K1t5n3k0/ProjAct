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
    private AttackManager attackManager;
    private CharacterStats characterStats;
    
    [Header("状态")]
    private Vector3 moveDirection;
    private Vector3 velocity;
    private bool isGrounded;
    private bool isRolling;
    private bool canAttack = true;
    private bool canUseSkill = true;
    private bool isAttacking = false;
    private bool isUsingSkill = false;
    
    [Header("战斗设置")]
    public float attackCooldown = 0.5f;
    public float skillCooldown = 2f;
    
    [Header("移动设置")]
    public float acceleration = 10f; // 加速度
    public float deceleration = 15f; // 减速度
    
    // 当前实际速度
    private float currentMoveSpeed = 0f;
    private float targetSpeed = 0f;
    
    void Start()
    {
        controller = GetComponent<CharacterController>();
        animator = GetComponent<Animator>();
        mainCamera = Camera.main;
        
        // 检查并获取必需组件
        attackManager = GetComponent<AttackManager>();
        if (attackManager == null)
        {
            Debug.LogError("AttackManager component is missing! Adding one...");
            attackManager = gameObject.AddComponent<AttackManager>();
        }
        
        characterStats = GetComponent<CharacterStats>();
        if (characterStats == null)
        {
            Debug.LogError("CharacterStats component is missing! Adding one...");
            characterStats = gameObject.AddComponent<CharacterStats>();
        }
        
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
        
        // 如果正在攻击或使用技能，禁止移动
        if (!isAttacking && !isUsingSkill)
        {
            HandleMovement();
        }
        
        // 重力始终生效
        velocity.y += gravity * Time.deltaTime;
        controller.Move(velocity * Time.deltaTime);
        
        // 在非攻击状态下才能处理战斗输入
        if (!isAttacking && !isUsingSkill)
        {
            HandleCombat();
        }
    }
    
    // 将原来Update中的移动逻辑抽取出来
    void HandleMovement()
    {
        float horizontal = Input.GetAxisRaw("Horizontal");
        float vertical = Input.GetAxisRaw("Vertical");
        
        Vector3 move = new Vector3(horizontal, 0f, vertical).normalized;
        if (move != Vector3.zero)
        {
            Vector3 cameraForward = mainCamera.transform.forward;
            Vector3 cameraRight = mainCamera.transform.right;
            cameraForward.y = 0;
            cameraRight.y = 0;
            cameraForward.Normalize();
            cameraRight.Normalize();
        
            moveDirection = (cameraForward * vertical + cameraRight * horizontal).normalized;

            float targetAngle = Mathf.Atan2(moveDirection.x, moveDirection.z) * Mathf.Rad2Deg;
            float angle = Mathf.LerpAngle(transform.eulerAngles.y, targetAngle, Time.deltaTime * rotationSpeed);
            transform.rotation = Quaternion.Euler(0f, angle, 0f);
            
            targetSpeed = Input.GetKey(KeyCode.LeftShift) ? runSpeed : moveSpeed;
            
            currentMoveSpeed = Mathf.MoveTowards(currentMoveSpeed, targetSpeed, acceleration * Time.deltaTime);
        }
        else
        {
            targetSpeed = 0f;
            currentMoveSpeed = Mathf.MoveTowards(currentMoveSpeed, 0, deceleration * Time.deltaTime);
        }
        
        controller.Move(moveDirection * currentMoveSpeed * Time.deltaTime);
        
        animator?.SetFloat("Speed", currentMoveSpeed);
        
        // 跳跃
        if (Input.GetButtonDown("Jump") && isGrounded)
        {
            velocity.y = Mathf.Sqrt(jumpForce * -2f * gravity);
            animator?.SetTrigger("Jump");
        }
    }
    
    void HandleCombat()
    {
        // 普通攻击
        if (Input.GetKeyDown(KeyCode.J) && canAttack && !isRolling)
        {
            StartCoroutine(Attack());
        }
        
        // 技能1
        if (Input.GetKeyDown(KeyCode.K) && canUseSkill && !isRolling)
        {
            StartCoroutine(UseSkill());
        }
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
    
    IEnumerator Attack()
    {
        canAttack = false;
        isAttacking = true;
        animator?.SetTrigger("Attack");
        
        // 执行攻击
        attackManager.PerformNormalAttack();
        
        // 等待锁定移动时间
        if (attackManager.attackHits != null && attackManager.attackHits.Length > 0)
        {
            yield return new WaitForSeconds(attackManager.attackHits[0].lockMovementTime);
            isAttacking = false; // 锁定时间结束后允许移动
        }
        
        // 等待剩余冷却时间
        yield return new WaitForSeconds(attackCooldown);
        canAttack = true;
    }
    
    IEnumerator UseSkill()
    {
        canUseSkill = false;
        isUsingSkill = true;
        animator?.SetTrigger("Skill01");
        
        yield return new WaitForSeconds(0.3f);
        attackManager.PerformSkill();
        
        yield return new WaitForSeconds(skillCooldown - 0.3f);
        
        isUsingSkill = false;
        canUseSkill = true;
    }
}