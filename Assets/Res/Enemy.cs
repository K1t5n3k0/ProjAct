using UnityEngine;
using TMPro;
using System.Collections;

[RequireComponent(typeof(CapsuleCollider))]
public class Enemy : CharacterStats
{
    [Header("碰撞设置")]
    private CapsuleCollider enemyCollider;
    public float colliderHeight = 2f;
    public float colliderRadius = 0.5f;
    
    [Header("弱点系统")]
    public Transform weakSpotPosition;
    public float weakSpotDamageMultiplier = 2f;
    public Sprite weakSpotSprite;
    public Vector3 weakSpotScale = new Vector3(1f, 1f, 1f);
    private GameObject weakSpotIndicator;
    
    [Header("伤害显示")]
    public GameObject damageTextPrefab;
    public float damageTextOffsetY = 1f;
    
    [Header("状态")]
    private bool isDead = false;
    public bool IsDead => isDead;
    private EnemyAnimator enemyAnimator;
    
    [Header("受击效果")]
    private Material[] originalMaterials; // 存储所有原始材质
    private SkinnedMeshRenderer meshRenderer;
    public float hitFlashDuration = 0.2f; // 发红持续时间
    public Color hitColor = Color.red; // 受击颜色
    private bool isFlashing = false;
    
    [Header("眩晕设置")]
    public int hitCountToStun = 4; // 被击打多少次后眩晕
    public float stunDuration = 3f; // 眩晕持续时间
    private int currentHitCount = 0; // 当前被击打次数
    private bool isStunned = false; // 是否处于眩晕状态
    private Coroutine stunCoroutine; // 眩晕协程引用

    protected override void Start()
    {
        base.Start();
        enemyAnimator = GetComponent<EnemyAnimator>();
        
        // 获取模型渲染器和材质
        meshRenderer = GetComponentInChildren<SkinnedMeshRenderer>();
        if (meshRenderer != null)
        {
            // 保存原始材质
            originalMaterials = meshRenderer.materials;
        }
        
        // 初始化碰撞体
        InitializeCollider();
        InitializeWeakSpot();
    }

    void InitializeCollider()
    {
        // 获取或添加CapsuleCollider
        enemyCollider = GetComponent<CapsuleCollider>();
        
        // 设置碰撞体属性
        enemyCollider.height = colliderHeight;
        enemyCollider.radius = colliderRadius;
        enemyCollider.center = new Vector3(0, colliderHeight/2, 0);
        enemyCollider.isTrigger = false;
        
        // 设置层级为Enemy并打印确认
        int enemyLayer = LayerMask.NameToLayer("Enemy");
        Debug.Log($"Setting enemy layer to: {enemyLayer}");
        gameObject.layer = enemyLayer;
    }

    public bool IsWeakSpotHit(Vector3 attackerPosition)
    {
        if (weakSpotPosition == null) return false;
        
        // 计算攻击者到弱点的方向
        Vector3 toWeakSpot = weakSpotPosition.position - attackerPosition;
        // 获取弱点相对于敌人中心的方向
        Vector3 enemyToWeakSpot = weakSpotPosition.position - transform.position;
        
        // 如果攻击方向与弱点方向的夹角小于30度，则视为击中弱点
        return Vector3.Angle(toWeakSpot, enemyToWeakSpot) < 30f;
    }

    public override void TakeDamage(float damage, bool isWeakSpotHit = false, bool isHeavyHit = false)
    {
        if (isDead) return;

        float finalDamage = isWeakSpotHit ? damage * weakSpotDamageMultiplier : damage;
        base.TakeDamage(finalDamage);
        
        // 增加被击打计数
        currentHitCount++;
        
        // 检查是否达到眩晕条件
        if (currentHitCount >= hitCountToStun && !isStunned)
        {
            StartStun();
        }
        
        // 根据攻击类型触发不同强度的相机摇晃
        float shakeIntensity = 0.1f;
        float shakeDuration = 0.2f;
        
        if (isHeavyHit)
        {
            shakeIntensity = 0.3f;
            shakeDuration = 0.4f;
        }
        if (isWeakSpotHit)
        {
            shakeIntensity *= 1.5f;
            shakeDuration *= 1.2f;
        }
        
        CameraShake.Instance.StartShake(shakeIntensity, shakeDuration);
        
        // 播放受击动画，传入是否重击
        enemyAnimator?.PlayGetHit(isHeavyHit);
        
        // 显示伤害数字
        ShowDamageText(finalDamage, isWeakSpotHit);
        
        // 播放受击闪烁效果
        StartCoroutine(HitFlashEffect());
    }

    void ShowDamageText(float damage, bool isCritical)
    {
        if (damageTextPrefab != null)
        {
            // 在敌人头顶生成伤害数字
            Vector3 spawnPosition = transform.position + Vector3.up * damageTextOffsetY;
            GameObject damageTextObj = Instantiate(damageTextPrefab, spawnPosition, Quaternion.identity);
            TextMeshPro damageText = damageTextObj.GetComponent<TextMeshPro>();
            
            if (damageText != null)
            {
                // 设置伤害数字的文本和颜色
                damageText.text = damage.ToString("F0");
                damageText.color = isCritical ? Color.red : Color.white;
                damageText.fontSize = isCritical ? 8 : 6;
                
                // 添加上浮和淡出效果
                StartCoroutine(AnimateDamageText(damageTextObj));
            }
        }
    }

    IEnumerator AnimateDamageText(GameObject damageText)
    {
        float duration = 1f;
        float elapsedTime = 0f;
        Vector3 startPos = damageText.transform.position;
        TextMeshPro tmp = damageText.GetComponent<TextMeshPro>();
        
        while (elapsedTime < duration)
        {
            elapsedTime += Time.deltaTime;
            float t = elapsedTime / duration;
            
            // 上浮效果
            damageText.transform.position = startPos + Vector3.up * (t * 1.5f);
            
            // 淡出效果
            Color textColor = tmp.color;
            textColor.a = 1 - t;
            tmp.color = textColor;
            
            yield return null;
        }
        
        Destroy(damageText);
    }

    IEnumerator HitFlashEffect()
    {
        if (meshRenderer != null && !isFlashing)
        {
            isFlashing = true;
            
            // 创建新的材质数组
            Material[] hitMaterials = new Material[meshRenderer.materials.Length];
            for (int i = 0; i < meshRenderer.materials.Length; i++)
            {
                // 创建材质副本
                hitMaterials[i] = new Material(meshRenderer.materials[i]);
                // 设置发光颜色
                hitMaterials[i].SetColor("_EmissionColor", hitColor);
                hitMaterials[i].EnableKeyword("_EMISSION");
            }
            
            // 应用发光材��
            meshRenderer.materials = hitMaterials;
            
            // 等待指定时间
            yield return new WaitForSeconds(hitFlashDuration);
            
            // 恢复原始材质
            meshRenderer.materials = originalMaterials;
            
            // 清理临时材质
            foreach (Material mat in hitMaterials)
            {
                Destroy(mat);
            }
            
            isFlashing = false;
        }
    }

    protected override void Die()
    {
        if (isDead) return;
        isDead = true;
        
        // 播放死亡动画
        enemyAnimator?.PlayDie();
        
        GetComponent<Collider>().enabled = false;
        
        // 可以在这里添加死亡效果，掉落物品等
    }

    void InitializeWeakSpot()
    {
        // 如果没有指定弱点位置，在头顶创建一个
        if (weakSpotPosition == null)
        {
            weakSpotPosition = new GameObject("WeakSpotPosition").transform;
            weakSpotPosition.SetParent(transform);
            weakSpotPosition.localPosition = new Vector3(0, 2f, 0); // 根据角色大小调整高度
        }

        // 创建弱点显示器
        weakSpotIndicator = new GameObject("WeakSpotIndicator");
        weakSpotIndicator.transform.SetParent(weakSpotPosition);
        weakSpotIndicator.transform.localPosition = Vector3.zero;
        
        // 添加并设置 SpriteRenderer
        SpriteRenderer spriteRenderer = weakSpotIndicator.AddComponent<SpriteRenderer>();
        if (weakSpotSprite != null)
        {
            spriteRenderer.sprite = weakSpotSprite;
        }
        else
        {
            // 如果没有指定弱点图片，加载默认图片
            spriteRenderer.sprite = Resources.Load<Sprite>("DefaultWeakSpotSprite");
            spriteRenderer.color = Color.red;
        }

        // 确保在设置完 SpriteRenderer 后再设置缩放
        weakSpotIndicator.transform.localScale = weakSpotScale;
    }

    void StartStun()
    {
        if (stunCoroutine != null)
        {
            StopCoroutine(stunCoroutine);
        }
        stunCoroutine = StartCoroutine(StunCoroutine());
    }
    
    IEnumerator StunCoroutine()
    {
        isStunned = true;
        currentHitCount = 0; // 重置击打计数
        
        // 播放眩晕动画
        enemyAnimator?.PlayStun();
        
        // 等待眩晕时间
        yield return new WaitForSeconds(stunDuration);
        
        // 结束眩晕状态
        isStunned = false;
        enemyAnimator?.PlayIdle();
        
        stunCoroutine = null;
    }
} 