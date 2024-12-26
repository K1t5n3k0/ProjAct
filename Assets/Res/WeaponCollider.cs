using UnityEngine;
using System.Collections.Generic;

public class WeaponCollider : MonoBehaviour
{
    [Header("武器设置")]
    public Transform weaponBone; // 武器骨骼引用
    
    [Header("碰撞时间设置")]
    public float colliderStartDelay = 0.1f; // 攻击开始后多久启用碰撞体
    public float colliderDuration = 0.2f; // 碰撞体持续时间
    
    [Header("碰撞体设置")]
    public Vector3 colliderSize = new Vector3(0.3f, 0.3f, 0.8f); // 碰撞体大小
    public Vector3 colliderOffset = Vector3.zero; // 碰撞体偏移
    
    private Vector3 originalLocalPosition;
    private Quaternion originalLocalRotation;
    private BoxCollider weaponCollider;
    private AttackManager attackManager;
    private CharacterStats characterStats;
    private HashSet<Enemy> hitEnemies = new HashSet<Enemy>();
    
    private Vector3 previousPosition;
    private Vector3 currentPosition;
    
    void Start()
    {
        weaponCollider = GetComponent<BoxCollider>();
        if (weaponCollider == null)
        {
            weaponCollider = gameObject.AddComponent<BoxCollider>();
        }
        
        attackManager = GetComponentInParent<AttackManager>();
        characterStats = GetComponentInParent<CharacterStats>();
        
        // 设置碰撞体属性
        weaponCollider.size = colliderSize;
        weaponCollider.center = colliderOffset;
        weaponCollider.isTrigger = true;
        
        // 保存初始变换信息
        if (weaponBone != null)
        {
            transform.SetParent(weaponBone);
            originalLocalPosition = transform.localPosition;
            originalLocalRotation = transform.localRotation;
        }
        else
        {
            Debug.LogError("Weapon bone reference is missing! Please assign the weapon bone in the inspector.");
        }
        
        DisableCollider();
        previousPosition = transform.position;
        currentPosition = transform.position;
    }
    
    void FixedUpdate()
    {
        if (weaponBone != null && weaponCollider.enabled)
        {
            previousPosition = currentPosition;
            currentPosition = weaponBone.position;
            
            // 更新碰撞体位置和旋转
            transform.position = currentPosition;
            transform.rotation = weaponBone.rotation;
            
            // 绘制碰撞体的移动轨迹
            Debug.DrawLine(previousPosition, currentPosition, Color.red, Time.fixedDeltaTime);
        }
    }
    
    public void EnableCollider()
    {
        Debug.Log($"Enabling weapon collider on {gameObject.name} at time: {Time.time}");
        if (weaponCollider != null)
        {
            weaponCollider.enabled = true;
            hitEnemies.Clear();
            previousPosition = weaponBone.position;
            currentPosition = weaponBone.position;
            
            // 打印碰撞体的当前位置和状态
            Debug.Log($"Collider position: {transform.position}, Rotation: {transform.rotation.eulerAngles}");
            Debug.DrawLine(transform.position, transform.position + transform.forward * 2f, Color.red, 1f);
        }
        else
        {
            Debug.LogError("WeaponCollider component is null!");
        }
    }
    
    public void DisableCollider()
    {
        Debug.Log($"Disabling weapon collider on {gameObject.name}");
        if (weaponCollider != null)
        {
            weaponCollider.enabled = false;
        }
        else
        {
            Debug.LogError("WeaponCollider component is null!");
        }
    }
    
    void OnTriggerEnter(Collider other)
    {
        Debug.Log($"Trigger entered with: {other.gameObject.name}, Layer: {other.gameObject.layer} ({LayerMask.LayerToName(other.gameObject.layer)})");
        
        // 确保碰撞的是Enemy层的对象
        if (other.gameObject.layer == LayerMask.NameToLayer("Enemy"))
        {
            Enemy enemy = other.GetComponent<Enemy>();
            if (enemy != null && !hitEnemies.Contains(enemy))
            {
                Debug.Log($"Hit enemy at position: {other.transform.position}");
                hitEnemies.Add(enemy);
                
                // 检查是否击中弱点
                bool hitWeakSpot = enemy.IsWeakSpotHit(transform.position);
                Debug.Log($"Hit weak spot: {hitWeakSpot}");
                
                // 触发相机摇晃
                float shakeIntensity = hitWeakSpot ? 0.2f : 0.1f; // 击中弱点时摇晃更强烈
                float shakeDuration = hitWeakSpot ? 0.3f : 0.2f;
                
                // 确保CameraShake实例存在
                if (CameraShake.Instance != null)
                {
                    Debug.Log($"Triggering camera shake with intensity: {shakeIntensity}, duration: {shakeDuration}");
                    CameraShake.Instance.StartShake(shakeIntensity, shakeDuration);
                }
                else
                {
                    Debug.LogError("CameraShake instance not found!");
                }
                
                // 造成伤害
                enemy.TakeDamage(characterStats.atk, hitWeakSpot);
                
                // 生成攻击特效
                if (attackManager.normalAttackEffect != null)
                {
                    Vector3 hitPoint = other.ClosestPoint(transform.position);
                    Instantiate(attackManager.normalAttackEffect, hitPoint, Quaternion.identity);
                }
            }
        }
    }
    
    void OnDrawGizmos()
    {
        if (weaponCollider != null && weaponCollider.enabled)
        {
            // 绘制碰撞体
            Gizmos.color = new Color(1, 0, 0, 0.5f);
            Matrix4x4 rotationMatrix = Matrix4x4.TRS(transform.position, transform.rotation, transform.lossyScale);
            Gizmos.matrix = rotationMatrix;
            Gizmos.DrawWireCube(colliderOffset, colliderSize);
            
            // 绘制移动轨迹
            if (Application.isPlaying)
            {
                Gizmos.color = Color.yellow;
                Gizmos.DrawLine(previousPosition, currentPosition);
            }
        }
    }
} 